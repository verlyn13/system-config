#!/usr/bin/env node

import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs/promises';
import { glob } from 'glob';
import fetch from 'node-fetch';
import { EventEmitter } from 'events';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

class DashboardServer extends EventEmitter {
  constructor() {
    super();

    // Load configuration from config.json
    const configPath = join(__dirname, 'config.json');
    try {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      this.port = config.spec.server.port;
      console.log(`✅ Loaded configuration from ${configPath}`);
      console.log(`📌 Dashboard ALWAYS runs on port ${this.port}`);
    } catch (err) {
      console.error('❌ Failed to load config.json, using default port 8089');
      this.port = 8089;
    }

    this.app = express();
    this.baseDir = process.env.HOME + '/Development/personal';

    // Cache for manifests and metrics
    this.cache = {
      manifests: new Map(),
      metrics: new Map(),
      compliance: null,
      lastUpdate: null,
    };

    this.setupMiddleware();
    this.setupRoutes();
    this.startBackgroundTasks();
  }

  setupMiddleware() {
    this.app.use(express.json());
    this.app.use(express.static(__dirname));

    // CORS for development
    this.app.use((req, res, next) => {
      res.header('Access-Control-Allow-Origin', '*');
      res.header('Access-Control-Allow-Headers', 'Content-Type');
      res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      next();
    });
  }

  setupRoutes() {
    // Serve the dashboard HTML - ONLY index.html, no fallbacks
    this.app.get('/', async (req, res) => {
      try {
        // Serve ONLY index.html - this is the single dashboard
        const html = await fs.readFile(join(__dirname, 'index.html'), 'utf8');
        res.send(html);
      } catch (err) {
        console.error('❌ index.html not found:', err);
        res.status(500).send(`
          <h1>Dashboard Error</h1>
          <p>index.html not found in dashboard directory.</p>
          <p>This is the ONLY dashboard file. No fallbacks.</p>
          <p>Port: 8089</p>
        `);
      }
    });

    // API endpoints
    this.app.get('/api/services', async (req, res) => {
      const services = await this.getServices();
      res.json(services);
    });

    this.app.get('/api/compliance', async (req, res) => {
      const compliance = await this.getCompliance();
      res.json(compliance);
    });

    this.app.get('/api/metrics/:service', async (req, res) => {
      const metrics = await this.getServiceMetrics(req.params.service);
      res.json(metrics);
    });

    this.app.get('/api/observations', async (req, res) => {
      const observations = await this.getRecentObservations();
      res.json(observations);
    });

    this.app.get('/api/violations', async (req, res) => {
      const violations = await this.getViolations();
      res.json(violations);
    });

    // SSE endpoint for real-time updates
    this.app.get('/api/stream', (req, res) => {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      // Send initial data
      this.sendSSEUpdate(res, 'connected', { timestamp: new Date().toISOString() });

      // Set up event listeners
      const updateHandler = (data) => this.sendSSEUpdate(res, 'update', data);
      const violationHandler = (data) => this.sendSSEUpdate(res, 'violation', data);

      this.on('update', updateHandler);
      this.on('violation', violationHandler);

      // Clean up on disconnect
      req.on('close', () => {
        this.removeListener('update', updateHandler);
        this.removeListener('violation', violationHandler);
      });
    });

    // Health check
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        cache: {
          manifests: this.cache.manifests.size,
          lastUpdate: this.cache.lastUpdate,
        },
      });
    });
  }

  sendSSEUpdate(res, event, data) {
    res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  }

  async getServices() {
    try {
      // Find all manifest.json files
      const pattern = join(this.baseDir, '*/manifest.json');
      const files = await glob(pattern);

      const services = [];
      for (const file of files) {
        const serviceName = file.split('/').slice(-2, -1)[0];

        try {
          // Check cache first
          let manifest;
          if (this.cache.manifests.has(serviceName)) {
            manifest = this.cache.manifests.get(serviceName);
          } else {
            const content = await fs.readFile(file, 'utf8');
            manifest = JSON.parse(content);
            this.cache.manifests.set(serviceName, manifest);
          }

          services.push({
            name: serviceName,
            type: manifest.spec.type,
            language: manifest.spec.language,
            status: manifest.status.phase,
            contractsEnabled: manifest.spec.contracts.enabled,
            mode: manifest.spec.contracts.mode,
            slo: manifest.spec.contracts.slo,
            metrics: manifest.status.metrics,
            conditions: manifest.status.conditions,
            lastObservation: manifest.status.lastObservation,
          });
        } catch (err) {
          console.error(`Error reading manifest for ${serviceName}:`, err);
          services.push({
            name: serviceName,
            status: 'error',
            error: err.message,
          });
        }
      }

      return services;
    } catch (error) {
      console.error('Error getting services:', error);
      return [];
    }
  }

  async getCompliance() {
    const services = await this.getServices();

    const compliance = {
      timestamp: new Date().toISOString(),
      totalServices: services.length,
      compliant: 0,
      partial: 0,
      nonCompliant: 0,
      services: [],
    };

    for (const service of services) {
      if (service.error) {
        compliance.nonCompliant++;
        compliance.services.push({
          name: service.name,
          status: 'non-compliant',
          reason: 'Error loading manifest',
        });
        continue;
      }

      // Check SLO compliance
      const breaches = this.checkSLOBreaches(service.slo, service.metrics);

      // Check contract mode
      if (!service.contractsEnabled || service.mode === 'disabled') {
        compliance.nonCompliant++;
        compliance.services.push({
          name: service.name,
          status: 'non-compliant',
          reason: 'Contracts disabled',
        });
      } else if (breaches.length === 0 && service.status === 'running') {
        compliance.compliant++;
        compliance.services.push({
          name: service.name,
          status: 'compliant',
        });
      } else {
        compliance.partial++;
        compliance.services.push({
          name: service.name,
          status: 'partial',
          breaches,
        });
      }
    }

    compliance.overallRate = services.length > 0
      ? ((compliance.compliant / services.length) * 100).toFixed(1)
      : 0;

    this.cache.compliance = compliance;
    return compliance;
  }

  checkSLOBreaches(slo, metrics) {
    if (!slo || !metrics) return [];

    const breaches = [];

    if (metrics.response_time_p95 > slo.response_time_p95) {
      breaches.push({
        metric: 'response_time_p95',
        threshold: slo.response_time_p95,
        actual: metrics.response_time_p95,
        severity: metrics.response_time_p95 > slo.response_time_p95 * 1.5 ? 'critical' : 'warning',
      });
    }

    if (metrics.error_rate > slo.error_rate) {
      breaches.push({
        metric: 'error_rate',
        threshold: slo.error_rate,
        actual: metrics.error_rate,
        severity: metrics.error_rate > slo.error_rate * 2 ? 'critical' : 'warning',
      });
    }

    if (metrics.availability < slo.availability) {
      breaches.push({
        metric: 'availability',
        threshold: slo.availability,
        actual: metrics.availability,
        severity: metrics.availability < slo.availability * 0.99 ? 'critical' : 'warning',
      });
    }

    return breaches;
  }

  async getServiceMetrics(serviceName) {
    const services = await this.getServices();
    const service = services.find(s => s.name === serviceName);

    if (!service) {
      return { error: 'Service not found' };
    }

    return {
      service: serviceName,
      metrics: service.metrics || {},
      slo: service.slo || {},
      breaches: this.checkSLOBreaches(service.slo, service.metrics),
      lastUpdate: service.lastObservation,
    };
  }

  async getRecentObservations() {
    // In a real system, this would query a time-series database
    // For now, we'll generate mock observations based on manifests
    const services = await this.getServices();
    const observations = [];

    for (const service of services) {
      if (service.status === 'running' && service.metrics) {
        observations.push({
          apiVersion: 'obs.v1',
          run_id: this.generateUUID(),
          timestamp: new Date().toISOString(),
          project_id: `${service.name}:verlyn13/${service.name}`,
          observer: 'manifest',
          summary: `Service health update for ${service.name}`,
          metrics: service.metrics,
          status: 'completed',
        });
      }
    }

    return observations;
  }

  async getViolations() {
    const compliance = await this.getCompliance();
    const violations = [];

    for (const service of compliance.services) {
      if (service.breaches && service.breaches.length > 0) {
        for (const breach of service.breaches) {
          violations.push({
            service: service.name,
            type: 'slo_breach',
            metric: breach.metric,
            message: `${breach.metric} exceeded threshold: ${breach.actual} > ${breach.threshold}`,
            severity: breach.severity,
            timestamp: new Date().toISOString(),
          });
        }
      }

      if (service.reason) {
        violations.push({
          service: service.name,
          type: 'compliance',
          message: service.reason,
          severity: 'error',
          timestamp: new Date().toISOString(),
        });
      }
    }

    return violations;
  }

  startBackgroundTasks() {
    // Refresh cache every 30 seconds
    setInterval(async () => {
      try {
        const services = await this.getServices();
        const compliance = await this.getCompliance();

        this.cache.lastUpdate = new Date().toISOString();

        // Emit update event
        this.emit('update', {
          services: services.length,
          compliance: compliance.overallRate,
          timestamp: this.cache.lastUpdate,
        });

        // Check for new violations
        const violations = await this.getViolations();
        if (violations.length > 0) {
          this.emit('violation', {
            count: violations.length,
            violations: violations.slice(0, 5), // Send only recent 5
          });
        }
      } catch (error) {
        console.error('Background task error:', error);
      }
    }, 30000);
  }

  generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  start() {
    this.app.listen(this.port, () => {
      console.log(`\n╔════════════════════════════════════════════════╗`);
      console.log(`║     SYSTEM DASHBOARD SERVER RUNNING           ║`);
      console.log(`╚════════════════════════════════════════════════╝`);
      console.log(`\n🌐 URL: http://localhost:${this.port}`);
      console.log(`📍 THIS IS THE ONLY DASHBOARD PORT: ${this.port}`);
      console.log(`📋 Configuration: ./config.json`);
      console.log(`\n✅ All systems should use this URL`);
      console.log(`Press Ctrl+C to stop\n`);
    });
  }
}

// Start the server - NO PORT ARGUMENTS ALLOWED
// Dashboard ALWAYS uses the port from config.json (8089)
const server = new DashboardServer();
server.start();