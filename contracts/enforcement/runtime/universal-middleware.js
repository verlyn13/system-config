/**
 * Universal Runtime Contract Enforcement Middleware
 *
 * This middleware can be integrated into any Node.js service to enforce
 * contracts at runtime. It intercepts all HTTP requests/responses and SSE
 * streams to validate contract compliance in real-time.
 */

const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const fs = require('fs');
const path = require('path');
const { EventEmitter } = require('events');

class UniversalContractEnforcer extends EventEmitter {
  constructor(options = {}) {
    super();

    this.options = {
      mode: options.mode || 'enforce',  // 'enforce' | 'monitor' | 'disabled'
      serviceName: options.serviceName || this.detectServiceName(),
      schemaPath: options.schemaPath || path.join(__dirname, '../../schemas'),
      logViolations: options.logViolations !== false,
      blockOnViolation: options.blockOnViolation !== false,
      metricsEnabled: options.metricsEnabled !== false,
      customThresholds: options.customThresholds || {},
      webhookUrl: options.webhookUrl || process.env.CONTRACT_WEBHOOK_URL,
    };

    this.ajv = new Ajv({ allErrors: true, strict: true });
    addFormats(this.ajv);

    // Load schemas
    this.loadSchemas();

    // Initialize metrics
    this.metrics = {
      totalRequests: 0,
      violations: 0,
      blocked: 0,
      observerMappings: 0,
      sloBreaches: 0,
      lastViolation: null,
      violationsByType: {},
    };

    // Observer mappings
    this.observerMappings = {
      'repo': 'git',
      'deps': 'mise',
      'quality': null  // Blocked
    };

    this.validExternalObservers = new Set([
      'git', 'mise', 'sbom', 'build', 'manifest'
    ]);

    // Service-specific SLO thresholds
    this.sloThresholds = this.getServiceThresholds();

    // Start metrics reporting
    if (this.options.metricsEnabled) {
      this.startMetricsReporting();
    }
  }

  detectServiceName() {
    // Try to detect from package.json
    try {
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      return pkg.name || 'unknown-service';
    } catch {
      return process.env.SERVICE_NAME || 'unknown-service';
    }
  }

  loadSchemas() {
    try {
      // Load observation schema
      const obsSchemaPath = path.join(this.options.schemaPath, 'obs.line.v1.json');
      if (fs.existsSync(obsSchemaPath)) {
        const obsSchema = JSON.parse(fs.readFileSync(obsSchemaPath, 'utf8'));
        this.obsValidator = this.ajv.compile(obsSchema);
      }

      // Load SLO breach schema
      const breachSchemaPath = path.join(this.options.schemaPath, 'slobreach.v1.json');
      if (fs.existsSync(breachSchemaPath)) {
        const breachSchema = JSON.parse(fs.readFileSync(breachSchemaPath, 'utf8'));
        this.breachValidator = this.ajv.compile(breachSchema);
      }
    } catch (error) {
      console.error('Failed to load contract schemas:', error);
      // Continue without schema validation if loading fails
      this.obsValidator = () => true;
      this.breachValidator = () => true;
    }
  }

  getServiceThresholds() {
    const defaults = {
      'ds-go': {
        response_time_p95: { threshold: 200, type: 'max' },
        error_rate: { threshold: 0.05, type: 'max' },
        availability: { threshold: 99.9, type: 'min' }
      },
      'devops-mcp': {
        response_time_p95: { threshold: 300, type: 'max' },
        error_rate: { threshold: 0.01, type: 'max' },
        availability: { threshold: 99.95, type: 'min' }
      },
      'system-dashboard': {
        response_time_p95: { threshold: 750, type: 'max' },
        error_rate: { threshold: 0.2, type: 'max' },
        availability: { threshold: 99.5, type: 'min' }
      }
    };

    return {
      ...defaults[this.options.serviceName] || {
        response_time_p95: { threshold: 500, type: 'max' },
        error_rate: { threshold: 0.1, type: 'max' },
        availability: { threshold: 99.0, type: 'min' }
      },
      ...this.options.customThresholds
    };
  }

  /**
   * Express/Connect middleware
   */
  middleware() {
    return (req, res, next) => {
      if (this.options.mode === 'disabled') {
        return next();
      }

      this.metrics.totalRequests++;

      // Intercept response methods
      this.interceptResponse(res);

      // Check request body for observations
      if (req.body && typeof req.body === 'object') {
        this.validateRequestBody(req, res);
      }

      // Track response time for SLO
      const startTime = Date.now();
      res.on('finish', () => {
        const duration = Date.now() - startTime;
        this.checkResponseSLO(duration, res.statusCode);
      });

      next();
    };
  }

  interceptResponse(res) {
    const originalJson = res.json?.bind(res);
    const originalWrite = res.write?.bind(res);
    const originalEnd = res.end?.bind(res);

    // Intercept JSON responses
    if (originalJson) {
      res.json = (body) => {
        const validation = this.validateResponseBody(body, res);
        if (validation.blocked) {
          return res.status(400).json({
            error: 'Contract violation',
            violations: validation.errors
          });
        }
        return originalJson(body);
      };
    }

    // Intercept SSE streams
    if (originalWrite) {
      res.write = (chunk, encoding) => {
        if (res.getHeader('Content-Type')?.includes('text/event-stream')) {
          chunk = this.validateSSEChunk(chunk, res);
        }
        return originalWrite(chunk, encoding);
      };
    }

    // Intercept end for final validation
    if (originalEnd) {
      res.end = (chunk, encoding) => {
        if (chunk) {
          const validation = this.validateResponseBody(chunk, res);
          if (validation.blocked) {
            return originalEnd(JSON.stringify({
              error: 'Contract violation',
              violations: validation.errors
            }), 'utf8');
          }
        }
        return originalEnd(chunk, encoding);
      };
    }
  }

  validateRequestBody(req, res) {
    if (req.body.apiVersion === 'obs.v1' || this.looksLikeObservation(req.body)) {
      const validation = this.validateObservation(req.body);

      if (!validation.valid) {
        this.recordViolation('request', validation.errors, req);

        if (this.shouldBlock()) {
          res.status(400).json({
            error: 'Contract violation in request',
            violations: validation.errors
          });
          return false;
        }
      }
    }
    return true;
  }

  validateResponseBody(body, res) {
    if (!body || typeof body !== 'object') {
      return { valid: true, blocked: false };
    }

    const data = typeof body === 'string' ? this.tryParseJSON(body) : body;
    if (!data) return { valid: true, blocked: false };

    if (data.apiVersion === 'obs.v1' || this.looksLikeObservation(data)) {
      const validation = this.validateObservation(data);

      if (!validation.valid) {
        this.recordViolation('response', validation.errors, { body: data });

        if (this.shouldBlock()) {
          return {
            valid: false,
            blocked: true,
            errors: validation.errors
          };
        }
      }
    }

    return { valid: true, blocked: false };
  }

  validateSSEChunk(chunk, res) {
    const str = chunk.toString();
    const lines = str.split('\n');

    for (let i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('data: ')) {
        const jsonStr = lines[i].substring(6);
        const data = this.tryParseJSON(jsonStr);

        if (data && (data.apiVersion === 'obs.v1' || this.looksLikeObservation(data))) {
          const validation = this.validateObservation(data);

          if (!validation.valid) {
            this.recordViolation('sse', validation.errors, { data });

            if (this.shouldBlock()) {
              // Replace with error event
              lines[i] = `data: ${JSON.stringify({
                error: 'Contract violation',
                violations: validation.errors
              })}`;
            }
          } else if (validation.mapped) {
            // Update with mapped observer
            lines[i] = `data: ${JSON.stringify(validation.mapped)}`;
          }
        }
      }
    }

    return lines.join('\n');
  }

  validateObservation(obs) {
    const result = {
      valid: true,
      errors: [],
      mapped: null
    };

    // Create a copy for mapping
    const mapped = { ...obs };

    // 1. Map observer name
    if (obs.observer) {
      const mappedObserver = this.mapObserver(obs.observer);
      if (mappedObserver === null) {
        result.valid = false;
        result.errors.push(`Observer '${obs.observer}' is blocked at boundary`);
        return result;
      }
      if (mappedObserver !== obs.observer) {
        mapped.observer = mappedObserver;
        this.metrics.observerMappings++;
      }
    }

    // 2. Validate schema
    if (this.obsValidator && !this.obsValidator(mapped)) {
      result.valid = false;
      result.errors = this.obsValidator.errors.map(e =>
        `${e.instancePath}: ${e.message}`
      );
      return result;
    }

    // 3. Additional validations
    if (!this.validateProjectId(mapped.project_id)) {
      result.valid = false;
      result.errors.push(`Invalid project_id format: ${mapped.project_id}`);
    }

    if (mapped.apiVersion && mapped.apiVersion !== 'obs.v1') {
      result.valid = false;
      result.errors.push(`Invalid apiVersion: ${mapped.apiVersion} (must be 'obs.v1')`);
    }

    result.mapped = result.valid ? mapped : null;
    return result;
  }

  mapObserver(observer) {
    if (observer in this.observerMappings) {
      return this.observerMappings[observer];
    }
    if (this.validExternalObservers.has(observer)) {
      return observer;
    }
    return null;  // Block unknown
  }

  validateProjectId(projectId) {
    if (!projectId) return false;
    // Format: service:org/repo (all lowercase)
    return /^[a-z-]+:[a-z0-9-]+\/[a-z0-9-]+$/.test(projectId);
  }

  looksLikeObservation(obj) {
    return obj && typeof obj === 'object' &&
           ('observer' in obj || 'run_id' in obj ||
            'project_id' in obj || 'metrics' in obj);
  }

  tryParseJSON(str) {
    try {
      return JSON.parse(str);
    } catch {
      return null;
    }
  }

  shouldBlock() {
    return this.options.mode === 'enforce' && this.options.blockOnViolation;
  }

  recordViolation(type, errors, context) {
    this.metrics.violations++;
    this.metrics.violationsByType[type] = (this.metrics.violationsByType[type] || 0) + 1;
    this.metrics.lastViolation = {
      type,
      errors,
      timestamp: new Date().toISOString(),
      service: this.options.serviceName
    };

    if (this.options.logViolations) {
      console.error(`[CONTRACT VIOLATION] ${type}:`, errors);
    }

    this.emit('violation', {
      type,
      errors,
      context,
      service: this.options.serviceName,
      timestamp: new Date().toISOString()
    });

    if (this.shouldBlock()) {
      this.metrics.blocked++;
    }

    // Send webhook notification
    if (this.options.webhookUrl) {
      this.sendWebhook({
        event: 'contract_violation',
        service: this.options.serviceName,
        type,
        errors,
        timestamp: new Date().toISOString()
      });
    }
  }

  checkResponseSLO(duration, statusCode) {
    const isError = statusCode >= 500;
    const breaches = [];

    // Check response time
    if (duration > this.sloThresholds.response_time_p95?.threshold) {
      breaches.push({
        metric: 'response_time_p95',
        threshold: this.sloThresholds.response_time_p95.threshold,
        actual: duration
      });
    }

    // Track for error rate calculation
    if (isError) {
      // Would need to track over time window for accurate error rate
      this.emit('error', { statusCode, duration });
    }

    if (breaches.length > 0) {
      this.metrics.sloBreaches++;
      this.emit('slo_breach', {
        service: this.options.serviceName,
        breaches,
        timestamp: new Date().toISOString()
      });

      if (this.options.webhookUrl) {
        this.sendWebhook({
          event: 'slo_breach',
          service: this.options.serviceName,
          breaches,
          timestamp: new Date().toISOString()
        });
      }
    }
  }

  async sendWebhook(data) {
    try {
      const response = await fetch(this.options.webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        console.error('Webhook failed:', response.statusText);
      }
    } catch (error) {
      console.error('Webhook error:', error);
    }
  }

  startMetricsReporting() {
    // Report metrics every minute
    setInterval(() => {
      const report = this.getMetricsReport();
      this.emit('metrics', report);

      if (this.options.logViolations) {
        console.log('[CONTRACT METRICS]', report);
      }
    }, 60000);
  }

  getMetricsReport() {
    return {
      service: this.options.serviceName,
      timestamp: new Date().toISOString(),
      mode: this.options.mode,
      metrics: {
        totalRequests: this.metrics.totalRequests,
        violations: this.metrics.violations,
        blocked: this.metrics.blocked,
        observerMappings: this.metrics.observerMappings,
        sloBreaches: this.metrics.sloBreaches,
        violationRate: this.metrics.totalRequests > 0
          ? (this.metrics.violations / this.metrics.totalRequests).toFixed(4)
          : 0,
        violationsByType: this.metrics.violationsByType,
        lastViolation: this.metrics.lastViolation
      }
    };
  }

  /**
   * Fastify plugin
   */
  fastifyPlugin(fastify, options, done) {
    fastify.addHook('onRequest', async (request, reply) => {
      if (this.options.mode === 'disabled') return;

      this.metrics.totalRequests++;
    });

    fastify.addHook('preSerialization', async (request, reply, payload) => {
      if (payload && typeof payload === 'object') {
        const validation = this.validateResponseBody(payload, reply);
        if (validation.blocked) {
          throw new Error('Contract violation: ' + validation.errors.join(', '));
        }
      }
      return payload;
    });

    done();
  }

  /**
   * Koa middleware
   */
  koaMiddleware() {
    return async (ctx, next) => {
      if (this.options.mode === 'disabled') {
        return next();
      }

      this.metrics.totalRequests++;
      const startTime = Date.now();

      try {
        await next();

        // Validate response body
        if (ctx.body && typeof ctx.body === 'object') {
          const validation = this.validateResponseBody(ctx.body, ctx);
          if (validation.blocked) {
            ctx.status = 400;
            ctx.body = {
              error: 'Contract violation',
              violations: validation.errors
            };
          }
        }
      } finally {
        const duration = Date.now() - startTime;
        this.checkResponseSLO(duration, ctx.status);
      }
    };
  }

  /**
   * Hapi plugin
   */
  hapiPlugin = {
    name: 'contract-enforcement',
    version: '1.0.0',
    register: async (server, options) => {
      server.ext('onPreResponse', (request, h) => {
        if (this.options.mode === 'disabled') {
          return h.continue;
        }

        const response = request.response;
        if (response.source && typeof response.source === 'object') {
          const validation = this.validateResponseBody(response.source, response);
          if (validation.blocked) {
            return h.response({
              error: 'Contract violation',
              violations: validation.errors
            }).code(400);
          }
        }

        return h.continue;
      });
    }
  };
}

// Export factory function for easy integration
module.exports = {
  UniversalContractEnforcer,

  // Quick setup for Express
  express: (options) => {
    const enforcer = new UniversalContractEnforcer(options);
    return enforcer.middleware();
  },

  // Quick setup for Fastify
  fastify: (options) => {
    const enforcer = new UniversalContractEnforcer(options);
    return enforcer.fastifyPlugin.bind(enforcer);
  },

  // Quick setup for Koa
  koa: (options) => {
    const enforcer = new UniversalContractEnforcer(options);
    return enforcer.koaMiddleware();
  },

  // Quick setup for Hapi
  hapi: (options) => {
    const enforcer = new UniversalContractEnforcer(options);
    return enforcer.hapiPlugin;
  }
};