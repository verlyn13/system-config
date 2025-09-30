#!/bin/bash
# contracts/policy/opa/scripts/setup-opa.sh
# Setup OPA for contract validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRACTS_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OPA_VERSION="0.68.0"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install OPA if not present
install_opa() {
    if command -v opa &> /dev/null; then
        log_info "OPA is already installed: $(opa version)"
        return 0
    fi
    
    log_info "Installing OPA version ${OPA_VERSION}..."
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    URL="https://openpolicyagent.org/downloads/v${OPA_VERSION}/opa_${OS}_${ARCH}"
    
    curl -L -o /tmp/opa "$URL"
    chmod 755 /tmp/opa
    sudo mv /tmp/opa /usr/local/bin/opa
    
    log_info "OPA installed successfully"
}

# Bundle policies for distribution
bundle_policies() {
    log_info "Creating OPA bundle..."
    
    cd "$CONTRACTS_ROOT/contracts/policy/opa"
    
    # Create bundle manifest
    cat > .manifest <<EOF
{
    "revision": "$(git rev-parse HEAD 2>/dev/null || echo 'dev')",
    "roots": ["contracts/v1"]
}
EOF
    
    # Bundle the policies
    opa build \
        -b contracts.v1.rego \
        -b data/ \
        -o bundle.tar.gz
    
    log_info "Bundle created: bundle.tar.gz"
}

# Validate policies
validate_policies() {
    log_info "Validating OPA policies..."
    
    cd "$CONTRACTS_ROOT/contracts/policy/opa"
    
    # Check policy syntax
    opa fmt --list contracts.v1.rego
    
    # Test the policies
    opa test contracts.v1.rego tests/
    
    log_info "Policy validation complete"
}

# Setup OPA server configuration
setup_server_config() {
    log_info "Creating OPA server configuration..."
    
    cat > "$CONTRACTS_ROOT/contracts/policy/opa/server-config.yaml" <<'EOF'
services:
  authz:
    url: http://localhost:8181/v1
    
bundles:
  authz:
    resource: "/contracts/v1/bundle.tar.gz"
    persist: true
    polling:
      min_delay_seconds: 10
      max_delay_seconds: 60

decision_logs:
  console: true
  reporting:
    min_delay_seconds: 5
    max_delay_seconds: 10

server:
  addr: ":8181"
  diagnostic_addr: ":8282"
  
plugins:
  envoy_ext_authz_grpc:
    addr: ":9191"
    enable_reflection: true
EOF
    
    log_info "Server configuration created"
}

# Create systemd service (optional)
create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat > /tmp/opa-contracts.service <<EOF
[Unit]
Description=OPA Contract Validation Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$CONTRACTS_ROOT/contracts/policy/opa
ExecStart=/usr/local/bin/opa run --server --config-file=server-config.yaml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    if [[ $EUID -eq 0 ]]; then
        mv /tmp/opa-contracts.service /etc/systemd/system/
        systemctl daemon-reload
        log_info "Systemd service created"
    else
        log_warn "Run as root to install systemd service"
        log_info "Service file saved to: /tmp/opa-contracts.service"
    fi
}

# Main setup
main() {
    log_info "Setting up OPA for contract validation..."
    
    # Create directory structure
    mkdir -p "$CONTRACTS_ROOT/contracts/policy/opa/{data,tests,bundles}"
    
    # Install OPA
    install_opa
    
    # Validate policies
    validate_policies
    
    # Bundle policies
    bundle_policies
    
    # Setup server config
    setup_server_config
    
    # Optionally create service
    if [[ "${1:-}" == "--with-service" ]]; then
        create_systemd_service
    fi
    
    log_info "OPA setup complete!"
    log_info "Run 'opa run --server --config-file=server-config.yaml' to start the server"
}

main "$@"

---
#!/usr/bin/env node
// contracts/policy/opa/scripts/validate-observation.js
// Node.js script to validate observations against OPA policies

const http = require('http');
const fs = require('fs');
const path = require('path');

const OPA_HOST = process.env.OPA_HOST || 'localhost';
const OPA_PORT = process.env.OPA_PORT || '8181';

/**
 * Validate an observation against OPA policies
 * @param {Object} observation - The observation to validate
 * @param {string} context - The context (internal/external_api/dashboard)
 * @returns {Promise<Object>} Validation result
 */
async function validateObservation(observation, context = 'external_api') {
    const input = {
        ...observation,
        context
    };
    
    const data = JSON.stringify({ input });
    
    const options = {
        hostname: OPA_HOST,
        port: OPA_PORT,
        path: '/v1/data/contracts/v1/enforcement/enforcement_response',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    };
    
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let responseData = '';
            
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            
            res.on('end', () => {
                try {
                    const result = JSON.parse(responseData);
                    resolve(result.result);
                } catch (e) {
                    reject(new Error(`Failed to parse OPA response: ${e.message}`));
                }
            });
        });
        
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

/**
 * Map internal observer names to external
 * @param {string} observer - Observer name
 * @returns {Promise<string>} Mapped observer name
 */
async function mapObserver(observer) {
    const input = { observer };
    const data = JSON.stringify({ input });
    
    const options = {
        hostname: OPA_HOST,
        port: OPA_PORT,
        path: '/v1/data/contracts/v1/observers/map_observer',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    };
    
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let responseData = '';
            
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            
            res.on('end', () => {
                try {
                    const result = JSON.parse(responseData);
                    resolve(result.result);
                } catch (e) {
                    reject(new Error(`Failed to parse OPA response: ${e.message}`));
                }
            });
        });
        
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

/**
 * Check for SLO breaches
 * @param {Object} observation - The observation to check
 * @returns {Promise<Array>} Array of SLO breaches
 */
async function checkSLOBreaches(observation) {
    const data = JSON.stringify({ input: observation });
    
    const options = {
        hostname: OPA_HOST,
        port: OPA_PORT,
        path: '/v1/data/contracts/v1/slo/slo_breaches',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    };
    
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let responseData = '';
            
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            
            res.on('end', () => {
                try {
                    const result = JSON.parse(responseData);
                    resolve(result.result || []);
                } catch (e) {
                    reject(new Error(`Failed to parse OPA response: ${e.message}`));
                }
            });
        });
        
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

// CLI interface
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length < 1) {
        console.error('Usage: validate-observation.js <file> [context]');
        console.error('  file: Path to JSON observation file');
        console.error('  context: internal|external_api|dashboard (default: external_api)');
        process.exit(1);
    }
    
    const file = args[0];
    const context = args[1] || 'external_api';
    
    try {
        const observation = JSON.parse(fs.readFileSync(file, 'utf8'));
        
        Promise.all([
            validateObservation(observation, context),
            checkSLOBreaches(observation)
        ]).then(([validation, breaches]) => {
            console.log('Validation Result:');
            console.log(JSON.stringify(validation, null, 2));
            
            if (breaches && breaches.length > 0) {
                console.log('\nSLO Breaches Detected:');
                console.log(JSON.stringify(breaches, null, 2));
            }
            
            process.exit(validation.allow ? 0 : 1);
        }).catch(error => {
            console.error('Validation error:', error.message);
            process.exit(1);
        });
    } catch (e) {
        console.error('Failed to read observation file:', e.message);
        process.exit(1);
    }
}

module.exports = {
    validateObservation,
    mapObserver,
    checkSLOBreaches
};

---
#!/usr/bin/env python3
# contracts/policy/opa/scripts/opa-client.py
# Python client for OPA policy evaluation

import json
import sys
import argparse
import requests
from typing import Dict, Any, Optional, List
from datetime import datetime
from pathlib import Path

class OPAClient:
    """Client for interacting with OPA policy server"""
    
    def __init__(self, host: str = "localhost", port: int = 8181):
        self.base_url = f"http://{host}:{port}"
        self.session = requests.Session()
        self.session.headers.update({"Content-Type": "application/json"})
    
    def evaluate(self, path: str, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Evaluate a policy at the given path"""
        url = f"{self.base_url}/v1/data/{path}"
        response = self.session.post(url, json={"input": input_data})
        response.raise_for_status()
        return response.json().get("result", {})
    
    def validate_observation(self, observation: Dict[str, Any], 
                           context: str = "external_api") -> Dict[str, Any]:
        """Validate an observation"""
        input_data = {**observation, "context": context}
        return self.evaluate("contracts/v1/enforcement/enforcement_response", input_data)
    
    def map_observer(self, observer: str) -> Optional[str]:
        """Map internal observer name to external"""
        result = self.evaluate("contracts/v1/observers/map_observer", {"observer": observer})
        return result
    
    def check_slo_breaches(self, observation: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Check for SLO breaches in observation"""
        result = self.evaluate("contracts/v1/slo/slo_breaches", observation)
        return result if isinstance(result, list) else []
    
    def check_migration_needed(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Check if data needs migration"""
        return self.evaluate("contracts/v1/migration/migration_report", data)
    
    def validate_path(self, path: str) -> bool:
        """Validate an observation path"""
        result = self.evaluate("contracts/v1/paths/valid_observation_path", {"path": path})
        return bool(result)
    
    def validate_sse_event(self, event: str, data: Dict[str, Any]) -> bool:
        """Validate an SSE event"""
        input_data = {"event": event, "data": data}
        result = self.evaluate("contracts/v1/sse/valid_sse_event", input_data)
        return bool(result)
    
    def get_contract_metadata(self) -> Dict[str, Any]:
        """Get contract metadata"""
        return self.evaluate("contracts/v1/contract_metadata", {})

def validate_file(client: OPAClient, file_path: Path, context: str) -> None:
    """Validate an observation file"""
    try:
        with open(file_path, 'r') as f:
            # Handle both JSON and NDJSON
            content = f.read().strip()
            
            if file_path.suffix == '.ndjson':
                # Process each line
                for line_num, line in enumerate(content.split('\n'), 1):
                    if not line.strip():
                        continue
                    
                    try:
                        observation = json.loads(line)
                        result = client.validate_observation(observation, context)
                        
                        if result.get('allow'):
                            print(f"✓ Line {line_num}: Valid")
                        else:
                            print(f"✗ Line {line_num}: Invalid")
                            for violation in result.get('violations', []):
                                print(f"  - {violation['type']}: {violation['message']}")
                    
                    except json.JSONDecodeError as e:
                        print(f"✗ Line {line_num}: Invalid JSON - {e}")
            else:
                # Single JSON file
                observation = json.loads(content)
                
                # Validate observation
                result = client.validate_observation(observation, context)
                
                print(f"\n{'='*60}")
                print(f"Validation Result for: {file_path}")
                print(f"{'='*60}")
                
                if result.get('allow'):
                    print("✓ VALID")
                    if 'quality_score' in result:
                        print(f"Quality Score: {result['quality_score']}/100")
                else:
                    print("✗ INVALID")
                    print("\nViolations:")
                    for violation in result.get('violations', []):
                        print(f"  [{violation['severity']}] {violation['type']}")
                        print(f"    {violation['message']}")
                
                # Check for SLO breaches
                breaches = client.check_slo_breaches(observation)
                if breaches:
                    print("\nSLO Breaches Detected:")
                    for breach in breaches:
                        print(f"  - {breach['slo_name']}: {breach['breach_level']}")
                        print(f"    {breach['message']}")
                
                # Check if migration needed
                migration = client.check_migration_needed(observation)
                if migration.get('needs_migration'):
                    print("\nMigration Required:")
                    print(f"  Severity: {migration['severity']}")
                    print(f"  Issues: {', '.join(migration['issues'])}")
    
    except FileNotFoundError:
        print(f"Error: File not found: {file_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in file: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='OPA Contract Validation Client')
    parser.add_argument('--host', default='localhost', help='OPA server host')
    parser.add_argument('--port', type=int, default=8181, help='OPA server port')
    
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Validate command
    validate_parser = subparsers.add_parser('validate', help='Validate observation file')
    validate_parser.add_argument('file', type=Path, help='Observation file to validate')
    validate_parser.add_argument('--context', default='external_api',
                                choices=['internal', 'external_api', 'dashboard'],
                                help='Validation context')
    
    # Map observer command
    map_parser = subparsers.add_parser('map', help='Map observer name')
    map_parser.add_argument('observer', help='Observer name to map')
    
    # Check path command
    path_parser = subparsers.add_parser('check-path', help='Validate observation path')
    path_parser.add_argument('path', help='Path to validate')
    
    # Metadata command
    subparsers.add_parser('metadata', help='Get contract metadata')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    # Create client
    client = OPAClient(args.host, args.port)
    
    try:
        if args.command == 'validate':
            validate_file(client, args.file, args.context)
        
        elif args.command == 'map':
            result = client.map_observer(args.observer)
            if result:
                print(f"{args.observer} → {result}")
            else:
                print(f"{args.observer} has no mapping (blocked)")
        
        elif args.command == 'check-path':
            if client.validate_path(args.path):
                print(f"✓ Valid path: {args.path}")
            else:
                print(f"✗ Invalid path: {args.path}")
        
        elif args.command == 'metadata':
            metadata = client.get_contract_metadata()
            print(json.dumps(metadata, indent=2))
    
    except requests.exceptions.ConnectionError:
        print(f"Error: Cannot connect to OPA server at {client.base_url}")
        print("Make sure OPA is running: opa run --server")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()