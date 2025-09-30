/**
 * OPA Client for Node.js
 * Contract validation and enforcement client
 */

const axios = require('axios');

class OPAClient {
  constructor(opaUrl = 'http://localhost:8181') {
    this.opaUrl = opaUrl;
    this.policyPath = '/v1/data/contracts/v1';
  }

  /**
   * Validate an observation against contracts
   */
  async validateObservation(observation) {
    const response = await axios.post(
      `${this.opaUrl}${this.policyPath}/observations/validate`,
      {
        input: observation
      }
    );
    return response.data.result;
  }

  /**
   * Map internal observer names to external names
   */
  async mapObserver(observerName) {
    const response = await axios.post(
      `${this.opaUrl}${this.policyPath}/observers/map_to_external`,
      {
        input: { observer: observerName }
      }
    );
    return response.data.result;
  }

  /**
   * Check SLO compliance
   */
  async checkSLOCompliance(metrics) {
    const response = await axios.post(
      `${this.opaUrl}${this.policyPath}/slo/check_breaches`,
      {
        input: metrics
      }
    );
    return response.data.result;
  }

  /**
   * Validate SSE event before streaming
   */
  async validateSSEEvent(event) {
    const response = await axios.post(
      `${this.opaUrl}${this.policyPath}/streaming/validate_sse_event`,
      {
        input: event
      }
    );
    return response.data.result;
  }

  /**
   * Check if migration is needed
   */
  async checkMigrationRequired(currentVersion, targetVersion) {
    const response = await axios.post(
      `${this.opaUrl}${this.policyPath}/migration/check_required`,
      {
        input: {
          current_version: currentVersion,
          target_version: targetVersion
        }
      }
    );
    return response.data.result;
  }

  /**
   * Validate schema compliance
   */
  async validateSchema(schema) {
    const response = await axios.post(
      `${this.opaUrl}${this.policyPath}/schemas/validate_version`,
      {
        input: schema
      }
    );
    return response.data.result;
  }

  /**
   * Express middleware for contract validation
   */
  middleware() {
    return async (req, res, next) => {
      try {
        // Validate observation in request body if present
        if (req.body && req.body.observation) {
          const validation = await this.validateObservation(req.body.observation);
          if (!validation.valid) {
            return res.status(400).json({
              error: 'Contract validation failed',
              violations: validation.violations
            });
          }
          // Map observer names at boundary
          if (req.body.observation.observer) {
            const mapped = await this.mapObserver(req.body.observation.observer);
            if (mapped) {
              req.body.observation.observer = mapped;
            }
          }
        }
        next();
      } catch (error) {
        console.error('OPA validation error:', error);
        res.status(500).json({ error: 'Contract validation service unavailable' });
      }
    };
  }
}

module.exports = OPAClient;