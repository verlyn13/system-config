/**
 * Contract Validation Module
 * Provides schema validation and observer mapping for contract enforcement
 * Compatible with Node.js 24 LTS
 */

const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const fs = require('fs');
const path = require('path');

class ContractValidator {
  constructor() {
    // Initialize AJV with strict mode for 2020-12 schemas
    this.ajv = new Ajv({
      strict: true,
      allErrors: true,
      validateSchema: true,
      validateFormats: true,
      $data: true
    });

    // Add format validators
    addFormats(this.ajv);

    // Load schemas
    this.loadSchemas();

    // Observer mappings (internal -> external)
    this.observerMappings = {
      'repo': 'git',
      'deps': 'mise',
      'quality': null  // Never expose
    };

    // Valid external observers
    this.validExternalObservers = new Set([
      'git', 'mise', 'sbom', 'build', 'manifest'
    ]);

    // SLO thresholds by service
    this.sloThresholds = {
      'ds-go': {
        response_time_p50: 50,
        response_time_p95: 200,
        response_time_p99: 500,
        error_rate: 0.05
      },
      'system-setup-update': {
        response_time_p50: 200,
        response_time_p95: 1000,
        response_time_p99: 2000,
        validation_time: 100
      },
      'devops-mcp': {
        response_time_p95: 300,
        response_time_p99: 1000,
        availability: 99.95
      },
      'system-dashboard': {
        response_time_p50: 150,
        response_time_p95: 750,
        response_time_p99: 1500,
        error_rate: 0.2
      }
    };
  }

  /**
   * Load JSON schemas from the schemas directory
   */
  loadSchemas() {
    const schemasDir = path.join(__dirname, '../schemas');

    // Load observation schema
    const obsSchemaPath = path.join(schemasDir, 'obs.line.v1.json');
    if (fs.existsSync(obsSchemaPath)) {
      const obsSchema = JSON.parse(fs.readFileSync(obsSchemaPath, 'utf8'));
      this.obsValidator = this.ajv.compile(obsSchema);
    }

    // Load SLO breach schema
    const sloSchemaPath = path.join(schemasDir, 'slobreach.v1.json');
    if (fs.existsSync(sloSchemaPath)) {
      const sloSchema = JSON.parse(fs.readFileSync(sloSchemaPath, 'utf8'));
      this.sloValidator = this.ajv.compile(sloSchema);
    }
  }

  /**
   * Map internal observer name to external
   * @param {string} observer - Internal observer name
   * @returns {string|null} External observer name or null if blocked
   */
  mapObserver(observer) {
    // Check if it's an internal observer that needs mapping
    if (observer in this.observerMappings) {
      return this.observerMappings[observer];
    }

    // If it's already a valid external observer, return as-is
    if (this.validExternalObservers.has(observer)) {
      return observer;
    }

    // Unknown observer - block it
    return null;
  }

  /**
   * Encode project ID from components
   * @param {string} service - Service name
   * @param {string} org - Organization name
   * @param {string} repo - Repository name
   * @returns {string} Encoded project ID
   */
  encodeProjectId(service, org, repo) {
    // Validate components
    if (!service || !org || !repo) {
      throw new Error('All project ID components required');
    }

    // Ensure lowercase and valid characters
    service = service.toLowerCase().replace(/[^a-z0-9-]/g, '');
    org = org.toLowerCase().replace(/[^a-z0-9-]/g, '');
    repo = repo.toLowerCase().replace(/[^a-z0-9-]/g, '');

    return `${service}:${org}/${repo}`;
  }

  /**
   * Decode project ID into components
   * @param {string} projectId - Encoded project ID
   * @returns {Object} Decoded components
   */
  decodeProjectId(projectId) {
    const match = projectId.match(/^([a-z]+):([a-z0-9-]+)\/([a-z0-9-]+)$/);
    if (!match) {
      throw new Error('Invalid project ID format');
    }

    return {
      service: match[1],
      org: match[2],
      repo: match[3]
    };
  }

  /**
   * Validate observation against schema
   * @param {Object} observation - Observation to validate
   * @returns {Object} Validation result
   */
  validateObservation(observation) {
    if (!this.obsValidator) {
      return { valid: false, errors: ['Schema not loaded'] };
    }

    // Map observer before validation
    if (observation.observer) {
      const mapped = this.mapObserver(observation.observer);
      if (mapped === null) {
        return {
          valid: false,
          errors: [`Observer '${observation.observer}' is blocked at boundaries`]
        };
      }
      observation.observer = mapped;
    }

    // Validate against schema
    const valid = this.obsValidator(observation);

    return {
      valid,
      errors: valid ? [] : this.obsValidator.errors.map(e => e.message),
      data: observation
    };
  }

  /**
   * Validate SLO breach event
   * @param {Object} breach - SLO breach event
   * @returns {Object} Validation result
   */
  validateSLOBreach(breach) {
    if (!this.sloValidator) {
      return { valid: false, errors: ['Schema not loaded'] };
    }

    const valid = this.sloValidator(breach);

    return {
      valid,
      errors: valid ? [] : this.sloValidator.errors.map(e => e.message)
    };
  }

  /**
   * Check if metrics breach SLOs
   * @param {string} service - Service name
   * @param {Object} metrics - Metrics to check
   * @returns {Array} Array of breaches
   */
  checkSLOBreaches(service, metrics) {
    const thresholds = this.sloThresholds[service];
    if (!thresholds) {
      return [];
    }

    const breaches = [];

    for (const [metric, threshold] of Object.entries(thresholds)) {
      if (metrics[metric] !== undefined) {
        let breached = false;
        let severity = 'info';

        // Check if metric exceeds threshold
        if (metric === 'availability') {
          // Availability should be above threshold
          breached = metrics[metric] < threshold;
          if (breached) {
            severity = metrics[metric] < threshold * 0.99 ? 'critical' : 'warning';
          }
        } else {
          // Other metrics should be below threshold
          breached = metrics[metric] > threshold;
          if (breached) {
            severity = metrics[metric] > threshold * 2 ? 'critical' : 'warning';
          }
        }

        if (breached) {
          breaches.push({
            metric,
            threshold,
            actual: metrics[metric],
            severity,
            service
          });
        }
      }
    }

    return breaches;
  }

  /**
   * Validate SSE event before streaming
   * @param {Object} event - SSE event
   * @returns {Object} Validation result
   */
  validateSSEEvent(event) {
    // Check event structure
    if (!event || typeof event !== 'object') {
      return { valid: false, errors: ['Invalid SSE event structure'] };
    }

    // Required SSE fields
    if (!event.event || !event.data) {
      return { valid: false, errors: ['SSE event must have event and data fields'] };
    }

    // Parse and validate data if it's an observation
    let data;
    try {
      data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
    } catch (e) {
      return { valid: false, errors: ['Invalid JSON in SSE data'] };
    }

    // If it's an observation, validate it
    if (data.apiVersion === 'obs.v1') {
      return this.validateObservation(data);
    }

    // If it's an SLO breach, validate it
    if (data.apiVersion === 'slobreach.v1') {
      return this.validateSLOBreach(data);
    }

    return { valid: true, errors: [] };
  }

  /**
   * Express middleware for contract validation
   */
  middleware() {
    return (req, res, next) => {
      // Store original write method
      const originalWrite = res.write;

      // Override write for SSE validation
      res.write = (chunk, encoding) => {
        // Only validate SSE events
        if (res.getHeader('Content-Type') === 'text/event-stream') {
          try {
            // Parse SSE event from chunk
            const lines = chunk.toString().split('\n');
            const event = {};

            for (const line of lines) {
              if (line.startsWith('event:')) {
                event.event = line.substring(6).trim();
              } else if (line.startsWith('data:')) {
                event.data = line.substring(5).trim();
              }
            }

            // Validate if we have an event
            if (event.event && event.data) {
              const validation = this.validateSSEEvent(event);
              if (!validation.valid) {
                console.error('SSE validation failed:', validation.errors);
                return false; // Block invalid events
              }

              // Update chunk with validated data if transformed
              if (validation.data) {
                const newChunk = `event: ${event.event}\ndata: ${JSON.stringify(validation.data)}\n\n`;
                return originalWrite.call(res, newChunk, encoding);
              }
            }
          } catch (e) {
            console.error('SSE validation error:', e);
          }
        }

        // Call original write
        return originalWrite.call(res, chunk, encoding);
      };

      next();
    };
  }
}

// Export singleton instance and functions
const validator = new ContractValidator();

module.exports = {
  validator,
  mapObserver: (obs) => validator.mapObserver(obs),
  encodeProjectId: (service, org, repo) => validator.encodeProjectId(service, org, repo),
  decodeProjectId: (id) => validator.decodeProjectId(id),
  validateObservation: (obs) => validator.validateObservation(obs),
  validateSLOBreach: (breach) => validator.validateSLOBreach(breach),
  checkSLOBreaches: (service, metrics) => validator.checkSLOBreaches(service, metrics),
  validateSSEEvent: (event) => validator.validateSSEEvent(event),
  middleware: () => validator.middleware()
};