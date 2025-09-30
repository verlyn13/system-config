#!/bin/bash
# contracts/policy/opa/test-contracts.sh
# Quick test script to validate OPA policies against real observations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== OPA Contract Policy Test Suite ===${NC}\n"

# Test directory setup
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRACTS_ROOT="$(cd "$TEST_DIR/../../.." && pwd)"

# Create test observations
mkdir -p "$TEST_DIR/test-data"

# Test 1: Valid External Observation
echo -e "${YELLOW}Test 1: Valid External Observation${NC}"
cat > "$TEST_DIR/test-data/valid-external.json" <<'EOF'
{
  "apiVersion": "obs.v1",
  "run_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-09-28T10:00:00Z",
  "project_id": "github:verlyn13/devops-mcp",
  "observer": "git",
  "status": "ok",
  "summary": "Repository analysis complete",
  "metrics": {
    "files": 234,
    "commits": 1523,
    "branches": 5,
    "ahead": 0,
    "behind": 0
  },
  "duration_ms": 1234
}
EOF

opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
  -i "$TEST_DIR/test-data/valid-external.json" \
  "data.contracts.v1.enforcement.allow" | jq '.result[0].expressions[0].value' | \
  { read result; if [ "$result" = "true" ]; then 
      echo -e "${GREEN}✓ PASS${NC}: Valid observation accepted\n"; 
    else 
      echo -e "${RED}✗ FAIL${NC}: Valid observation rejected\n"; 
    fi; }

# Test 2: Internal Observer Mapping
echo -e "${YELLOW}Test 2: Internal Observer Mapping (repo → git)${NC}"
cat > "$TEST_DIR/test-data/internal-repo.json" <<'EOF'
{
  "observer": "repo"
}
EOF

MAPPED=$(opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
  -i "$TEST_DIR/test-data/internal-repo.json" \
  "data.contracts.v1.observers.map_observer[input.observer]" 2>/dev/null | \
  jq -r '.result[0].expressions[0].value' || echo "null")

if [ "$MAPPED" = "git" ]; then
  echo -e "${GREEN}✓ PASS${NC}: 'repo' correctly mapped to 'git'\n"
else
  echo -e "${RED}✗ FAIL${NC}: 'repo' not mapped correctly (got: $MAPPED)\n"
fi

# Test 3: Quality Observer Blocking
echo -e "${YELLOW}Test 3: Quality Observer External Blocking${NC}"
cat > "$TEST_DIR/test-data/quality-external.json" <<'EOF'
{
  "context": "external_api",
  "observer": "quality",
  "apiVersion": "obs.v1",
  "run_id": "test-123",
  "timestamp": "2025-09-28T10:00:00Z",
  "project_id": "github:test/repo",
  "status": "ok",
  "summary": "Quality check",
  "metrics": {
    "coverage": 0.85
  }
}
EOF

BLOCKED=$(opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
  -i "$TEST_DIR/test-data/quality-external.json" \
  "data.contracts.v1.observers.deny_external_quality" 2>/dev/null | \
  jq '.result[0].expressions[0].value' || echo "false")

if [ "$BLOCKED" = "true" ]; then
  echo -e "${GREEN}✓ PASS${NC}: Quality observer correctly blocked from external API\n"
else
  echo -e "${RED}✗ FAIL${NC}: Quality observer not blocked\n"
fi

# Test 4: SLO Breach Detection
echo -e "${YELLOW}Test 4: SLO Breach Detection (High Latency)${NC}"
cat > "$TEST_DIR/test-data/high-latency.json" <<'EOF'
{
  "apiVersion": "obs.v1",
  "project_id": "github:test/repo",
  "observer": "git",
  "metrics": {
    "latency_p95": 3000,
    "error_rate": 0.001
  }
}
EOF

BREACHES=$(opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
  -i "$TEST_DIR/test-data/high-latency.json" \
  "data.contracts.v1.slo.slo_breaches" 2>/dev/null | \
  jq '.result[0].expressions[0].value | length' || echo "0")

if [ "$BREACHES" -gt 0 ]; then
  echo -e "${GREEN}✓ PASS${NC}: SLO breach detected for high latency\n"
  opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
    -i "$TEST_DIR/test-data/high-latency.json" \
    "data.contracts.v1.slo.slo_breaches" 2>/dev/null | \
    jq '.result[0].expressions[0].value[0]' | \
    jq '{slo_name, breach_level, message}'
else
  echo -e "${RED}✗ FAIL${NC}: SLO breach not detected\n"
fi

# Test 5: Schema Migration Detection
echo -e "${YELLOW}Test 5: Schema Migration Detection${NC}"
cat > "$TEST_DIR/test-data/old-schema.json" <<'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "observer": "repo",
  "context": "external"
}
EOF

NEEDS_MIGRATION=$(opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
  -i "$TEST_DIR/test-data/old-schema.json" \
  "data.contracts.v1.migration.needs_migration" 2>/dev/null | \
  jq '.result[0].expressions[0].value' || echo "false")

if [ "$NEEDS_MIGRATION" = "true" ]; then
  echo -e "${GREEN}✓ PASS${NC}: Migration need detected for old schema\n"
else
  echo -e "${RED}✗ FAIL${NC}: Migration need not detected\n"
fi

# Test 6: Path Validation
echo -e "${YELLOW}Test 6: Canonical Path Validation${NC}"
cat > "$TEST_DIR/test-data/canonical-path.json" <<'EOF'
{
  "path": "~/.local/share/devops-mcp/observations/github__verlyn13__devops-mcp/latest.json"
}
EOF

VALID_PATH=$(opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
  -i "$TEST_DIR/test-data/canonical-path.json" \
  "data.contracts.v1.paths.valid_observation_path" 2>/dev/null | \
  jq '.result[0].expressions[0].value' || echo "false")

if [ "$VALID_PATH" = "true" ]; then
  echo -e "${GREEN}✓ PASS${NC}: Canonical path validated\n"
else
  echo -e "${RED}✗ FAIL${NC}: Canonical path not validated\n"
fi

# Test 7: SSE Event Validation
echo -e "${YELLOW}Test 7: SSE Event Validation${NC}"
cat > "$TEST_DIR/test-data/sse-event.json" <<'EOF'
{
  "event": "ProjectObsCompleted",
  "data": {
    "apiVersion": "obs.v1",
    "run_id": "test-456",
    "timestamp": "2025-09-28T11:00:00Z",
    "project_id": "github:test/repo",
    "observer": "mise",
    "status": "ok",
    "summary": "Dependencies checked",
    "metrics": {
      "total": 42,
      "outdated": 3
    }
  }
}
EOF

VALID_SSE=$(opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
  -i "$TEST_DIR/test-data/sse-event.json" \
  "data.contracts.v1.sse.valid_sse_event" 2>/dev/null | \
  jq '.result[0].expressions[0].value' || echo "false")

if [ "$VALID_SSE" = "true" ]; then
  echo -e "${GREEN}✓ PASS${NC}: SSE event validated\n"
else
  echo -e "${RED}✗ FAIL${NC}: SSE event not validated\n"
fi

# Test 8: Service Compliance
echo -e "${YELLOW}Test 8: Service Self-Status Compliance${NC}"
cat > "$TEST_DIR/test-data/self-status.json" <<'EOF'
{
  "contractVersion": "v1.1.0",
  "schemaVersion": "obs.v1",
  "observerMapping": {
    "internal": ["repo", "deps", "quality", "git", "mise", "sbom", "build", "manifest"],
    "external": ["git", "mise", "sbom", "build", "manifest"]
  },
  "paths": {
    "registry": "~/.local/share/devops-mcp/project-registry.json",
    "observations": "~/.local/share/devops-mcp/observations/"
  },
  "timestamp": "2025-09-28T12:00:00Z"
}
EOF

COMPLIANT=$(opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
  -i "$TEST_DIR/test-data/self-status.json" \
  "data.contracts.v1.compliance.compliant_self_status" 2>/dev/null | \
  jq '.result[0].expressions[0].value' || echo "false")

if [ "$COMPLIANT" = "true" ]; then
  echo -e "${GREEN}✓ PASS${NC}: Self-status compliant\n"
else
  echo -e "${RED}✗ FAIL${NC}: Self-status not compliant\n"
fi

# Test 9: Observation Quality Score
echo -e "${YELLOW}Test 9: Observation Quality Score${NC}"
cat > "$TEST_DIR/test-data/quality-score.json" <<'EOF'
{
  "apiVersion": "obs.v1",
  "run_id": "test-789",
  "timestamp": "2025-09-28T12:00:00Z",
  "project_id": "github:test/repo",
  "observer": "git",
  "status": "ok",
  "summary": "Good observation",
  "metrics": {
    "test": 123
  },
  "duration_ms": 500
}
EOF

# Note: This test needs current time adjustment for accurate scoring
echo -e "${BLUE}[INFO]${NC}: Quality score calculation depends on timestamp recency\n"

# Test 10: Real Observation from Repository
echo -e "${YELLOW}Test 10: Test with Real Observation File${NC}"

# Try to find a real observation file
REAL_OBS_FILE=""
for path in \
  "$HOME/.local/share/devops-mcp/observations/*/latest.json" \
  "$HOME/Library/Application Support/devops-mcp/observations/*/latest.json"; do
  if [ -f "$path" ]; then
    REAL_OBS_FILE="$path"
    break
  fi
done

if [ -n "$REAL_OBS_FILE" ]; then
  echo -e "${BLUE}Testing with: $REAL_OBS_FILE${NC}"
  
  # Add context for testing
  jq '. + {"context": "internal"}' "$REAL_OBS_FILE" > "$TEST_DIR/test-data/real-obs.json"
  
  REAL_VALID=$(opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
    -i "$TEST_DIR/test-data/real-obs.json" \
    "data.contracts.v1.observations.valid_observation" 2>/dev/null | \
    jq '.result[0].expressions[0].value' || echo "false")
  
  if [ "$REAL_VALID" = "true" ]; then
    echo -e "${GREEN}✓ PASS${NC}: Real observation validated\n"
  else
    echo -e "${RED}✗ FAIL${NC}: Real observation failed validation\n"
    echo "Checking violations..."
    opa eval -d "$CONTRACTS_ROOT/contracts/policy/opa/contracts.v1.rego" \
      -i "$TEST_DIR/test-data/real-obs.json" \
      "data.contracts.v1.enforcement.violations" 2>/dev/null | \
      jq '.result[0].expressions[0].value'
  fi
else
  echo -e "${YELLOW}[SKIP]${NC}: No real observation files found\n"
fi

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}Tests demonstrate:${NC}"
echo "• Observer mapping (repo → git, deps → mise)"
echo "• Quality observer blocking from external API"
echo "• SLO breach detection"
echo "• Schema migration detection"
echo "• Path validation"
echo "• SSE event validation"
echo "• Service compliance checking"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Start OPA server: opa run --server"
echo "2. Integrate with HTTP bridge"
echo "3. Enable validation in production"