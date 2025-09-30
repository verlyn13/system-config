// contracts/policy/opa/src/opa-client.ts
// TypeScript client for OPA policy evaluation

import * as http from 'http';
import * as https from 'https';

/**
 * OPA policy evaluation client configuration
 */
export interface OPAClientConfig {
  host?: string;
  port?: number;
  protocol?: 'http' | 'https';
  timeout?: number;
}

/**
 * Observer mapping configuration
 */
export const OBSERVER_MAPPINGS = {
  internal_to_external: {
    'repo': 'git',
    'deps': 'mise',
    'quality': null,  // Never exposed
    'git': 'git',
    'mise': 'mise',
    'sbom': 'sbom',
    'build': 'build',
    'manifest': 'manifest'
  },
  external_observers: ['git', 'mise', 'sbom', 'build', 'manifest'] as const,
  internal_observers: ['repo', 'deps', 'quality', 'git', 'mise', 'sbom', 'build', 'manifest'] as const
} as const;

export type ExternalObserver = typeof OBSERVER_MAPPINGS.external_observers[number];
export type InternalObserver = typeof OBSERVER_MAPPINGS.internal_observers[number];

/**
 * Observation validation result
 */
export interface ValidationResult {
  allow: boolean;
  violations: Violation[];
  contract_version: string;
  timestamp: string;
  quality_score?: number;
}

/**
 * Policy violation
 */
export interface Violation {
  type: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
}

/**
 * SLO breach detection
 */
export interface SLOBreach {
  apiVersion: 'obs.v1';
  timestamp: string;
  project_id: string;
  slo_name: string;
  breach_level: 'warning' | 'critical';
  actual_value: number;
  threshold_value: number;
  message: string;
}

/**
 * Migration report
 */
export interface MigrationReport {
  needs_migration: boolean;
  issues: string[];
  severity: 'low' | 'medium' | 'high' | 'critical';
}

/**
 * Observation data structure
 */
export interface ObservationLine {
  apiVersion: 'obs.v1';
  run_id: string;
  timestamp: string;
  project_id: string;
  observer: ExternalObserver;
  status: 'ok' | 'warn' | 'fail';
  summary: string;
  metrics: Record<string, number | string | boolean>;
  duration_ms?: number;
}

/**
 * Contract metadata
 */
export interface ContractMetadata {
  version: string;
  schema: string;
  api_version: string;
  policy_version: string;
}

/**
 * OPA Policy Client
 */
export class OPAClient {
  private readonly config: Required<OPAClientConfig>;
  private readonly baseUrl: string;

  constructor(config: OPAClientConfig = {}) {
    this.config = {
      host: config.host || process.env.OPA_HOST || 'localhost',
      port: config.port || parseInt(process.env.OPA_PORT || '8181'),
      protocol: config.protocol || 'http',
      timeout: config.timeout || 5000
    };
    
    this.baseUrl = `${this.config.protocol}://${this.config.host}:${this.config.port}`;
  }

  /**
   * Evaluate a policy at the given path
   */
  private async evaluate<T = any>(path: string, input: any): Promise<T> {
    const data = JSON.stringify({ input });
    const options = {
      hostname: this.config.host,
      port: this.config.port,
      path: `/v1/data/${path}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      },
      timeout: this.config.timeout
    };

    return new Promise((resolve, reject) => {
      const protocol = this.config.protocol === 'https' ? https : http;
      
      const req = protocol.request(options, (res) => {
        let responseData = '';
        
        res.on('data', (chunk) => {
          responseData += chunk;
        });
        
        res.on('end', () => {
          try {
            const result = JSON.parse(responseData);
            if (result.result !== undefined) {
              resolve(result.result);
            } else {
              reject(new Error('No result in OPA response'));
            }
          } catch (error) {
            reject(new Error(`Failed to parse OPA response: ${error}`));
          }
        });
      });
      
      req.on('error', reject);
      req.on('timeout', () => {
        req.destroy();
        reject(new Error('OPA request timeout'));
      });
      
      req.write(data);
      req.end();
    });
  }

  /**
   * Validate an observation against policies
   */
  async validateObservation(
    observation: Partial<ObservationLine>, 
    context: 'internal' | 'external_api' | 'dashboard' = 'external_api'
  ): Promise<ValidationResult> {
    const input = { ...observation, context };
    return this.evaluate<ValidationResult>(
      'contracts/v1/enforcement/enforcement_response',
      input
    );
  }

  /**
   * Map internal observer name to external
   */
  async mapObserver(observer: string): Promise<string | null> {
    const result = await this.evaluate<string | null>(
      'contracts/v1/observers/map_observer',
      { observer }
    );
    return result;
  }

  /**
   * Check for SLO breaches in observation
   */
  async checkSLOBreaches(observation: Partial<ObservationLine>): Promise<SLOBreach[]> {
    const result = await this.evaluate<SLOBreach[]>(
      'contracts/v1/slo/slo_breaches',
      observation
    );
    return Array.isArray(result) ? result : [];
  }

  /**
   * Check if data needs migration
   */
  async checkMigrationNeeded(data: any): Promise<MigrationReport> {
    return this.evaluate<MigrationReport>(
      'contracts/v1/migration/migration_report',
      data
    );
  }

  /**
   * Validate an observation file path
   */
  async validatePath(path: string): Promise<boolean> {
    const result = await this.evaluate<boolean>(
      'contracts/v1/paths/valid_observation_path',
      { path }
    );
    return Boolean(result);
  }

  /**
   * Validate an SSE event
   */
  async validateSSEEvent(event: string, data: any): Promise<boolean> {
    const result = await this.evaluate<boolean>(
      'contracts/v1/sse/valid_sse_event',
      { event, data }
    );
    return Boolean(result);
  }

  /**
   * Get contract metadata
   */
  async getContractMetadata(): Promise<ContractMetadata> {
    return this.evaluate<ContractMetadata>(
      'contracts/v1/contract_metadata',
      {}
    );
  }

  /**
   * Batch validate multiple observations
   */
  async batchValidate(
    observations: Partial<ObservationLine>[], 
    context: 'internal' | 'external_api' | 'dashboard' = 'external_api'
  ): Promise<ValidationResult[]> {
    return Promise.all(
      observations.map(obs => this.validateObservation(obs, context))
    );
  }
}

/**
 * Express middleware for contract validation
 */
export function createValidationMiddleware(client?: OPAClient) {
  const opaClient = client || new OPAClient();
  
  return async (req: any, res: any, next: any) => {
    // Add contract headers
    res.setHeader('X-Contract-Version', 'v1.1.0');
    res.setHeader('X-Schema-Version', 'obs.v1');
    
    // Determine context from request
    const context = req.headers['x-validation-context'] || 'external_api';
    
    // Store OPA client in request for use in handlers
    req.opa = opaClient;
    req.validationContext = context;
    
    // Helper function to validate observation
    req.validateObservation = async (observation: any) => {
      return opaClient.validateObservation(observation, context);
    };
    
    // Helper function to map observer
    req.mapObserver = async (observer: string) => {
      return opaClient.mapObserver(observer);
    };
    
    next();
  };
}

/**
 * Helper to transform observations at boundaries
 */
export class ObservationTransformer {
  constructor(private opaClient: OPAClient) {}

  /**
   * Transform observation for external API
   */
  async transformForExternal(observation: any): Promise<ObservationLine | null> {
    // Map observer if needed
    if (observation.observer) {
      const mapped = await this.opaClient.mapObserver(observation.observer);
      if (!mapped) {
        console.warn(`Observer ${observation.observer} cannot be exposed externally`);
        return null;
      }
      observation.observer = mapped;
    }
    
    // Ensure apiVersion
    observation.apiVersion = 'obs.v1';
    
    // Validate
    const validation = await this.opaClient.validateObservation(observation, 'external_api');
    if (!validation.allow) {
      console.error('Observation validation failed:', validation.violations);
      return null;
    }
    
    return observation as ObservationLine;
  }

  /**
   * Process a stream of observations
   */
  async *transformStream(
    observations: AsyncIterable<any> | Iterable<any>
  ): AsyncGenerator<ObservationLine> {
    for await (const obs of observations) {
      const transformed = await this.transformForExternal(obs);
      if (transformed) {
        yield transformed;
      }
    }
  }
}

/**
 * SSE event validator for streaming
 */
export class SSEValidator {
  constructor(private opaClient: OPAClient) {}

  /**
   * Validate and transform SSE event before streaming
   */
  async validateBeforeStream(event: string, data: any): Promise<boolean> {
    if (event === 'ProjectObsCompleted') {
      const validation = await this.opaClient.validateObservation(data, 'external_api');
      return validation.allow;
    }
    
    if (event === 'SLOBreach') {
      return this.opaClient.validateSSEEvent(event, data);
    }
    
    console.warn(`Unknown SSE event type: ${event}`);
    return false;
  }
}

/**
 * Static helper functions for immediate use without instantiation
 */
export const ContractHelpers = {
  /**
   * Map observer name without OPA server
   */
  mapObserverStatic(observer: string): string | null {
    const mapping = OBSERVER_MAPPINGS.internal_to_external[observer as keyof typeof OBSERVER_MAPPINGS.internal_to_external];
    return mapping !== undefined ? mapping : observer;
  },

  /**
   * Check if observer is valid for external API
   */
  isValidExternalObserver(observer: string): boolean {
    return OBSERVER_MAPPINGS.external_observers.includes(observer as ExternalObserver);
  },

  /**
   * Check if observer is internal only
   */
  isInternalOnlyObserver(observer: string): boolean {
    return observer === 'quality';
  },

  /**
   * Encode project ID for filesystem
   */
  encodeProjectId(projectId: string): string {
    return projectId.replace(/[:\/]/g, '__');
  },

  /**
   * Decode project ID from filesystem
   */
  decodeProjectId(encoded: string): string {
    return encoded.replace(/__/g, (match, offset, string) => {
      // Determine if this should be : or /
      const beforeUnderscore = string.lastIndexOf('__', offset - 1);
      const afterUnderscore = string.indexOf('__', offset + 2);
      
      if (beforeUnderscore === -1) {
        return ':';  // First separator is always :
      } else {
        return '/';  // Subsequent separators are /
      }
    });
  }
};

// Export everything for use in other modules
export default OPAClient;