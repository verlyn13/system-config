#!/usr/bin/env bash
#
# Validates Agent D (MCP Server) Stage 1 requirements.
#
# 1. Runs endpoint smoke tests for discovery, OpenAPI, and self-status.
# 2. Runs CI alias parity tests for /api/obs/* routes against the bridge contract.

set -euo pipefail

readonly MCP_BASE_URL="http://127.0.0.1:4319"
readonly BRIDGE_OPENAPI_PATH="openapi.yaml"
EXIT_CODE=0

# Color codes
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

function header() {
  echo -e "\n${YELLOW}== $1 ==${NC}"
}

function pass() {
  echo -e "${GREEN}✔${NC} $1"
}

function fail() {
  echo -e "${RED}✖${NC} $1"
  EXIT_CODE=1
}

function check_url() {
  local url=$1
  local description=$2
  if curl -fsS --head "$url" >/dev/null; then
    pass "$description ($url)"
  else
    fail "$description ($url)"
  fi
}

# --- Smoke Tests ---
header "Running Smoke Tests"

# 1. Discovery services
echo "Checking /api/obs/discovery/services..."
if [[ "$(curl -fsS \"$MCP_BASE_URL/api/obs/discovery/services\" | jq -r '.ts|type')" == "number" ]]; then
  pass "Discovery services returns 'ts' as a number."
else
  fail "Discovery services did not return 'ts' as a number."
fi

# 2. OpenAPI spec
echo "Checking /api/obs/discovery/openapi..."
if [[ "$(curl -fsS \"$MCP_BASE_URL/api/obs/discovery/openapi\" | head -n 1)" == "openapi: 3.1.0" ]]; then
  pass "OpenAPI spec seems valid."
else
  fail "OpenAPI spec is missing or invalid."
fi

# 3. Self-status
echo "Checking /api/self-status..."
if curl -fsS \"$MCP_BASE_URL/api/self-status\" | jq -e '.schemaVersion and .nowMs' >/dev/null; then
  pass "Self-status includes schemaVersion and nowMs."
else
  fail "Self-status is missing required fields."
fi

# --- Alias Parity Tests ---
header "Running Alias Parity Tests"

if ! command -v yq &> /dev/null; then
    fail "yq is not installed. Please install it to run alias parity tests."
    exit 1
fi

if [[ ! -f "$BRIDGE_OPENAPI_PATH" ]]; then
    fail "Bridge OpenAPI spec not found at $BRIDGE_OPENAPI_PATH"
    exit 1
fi

# Extract paths from the bridge's OpenAPI spec
paths=$(yq e 'keys | .[]' "$BRIDGE_OPENAPI_PATH" | grep '^/api/')

for p in $paths; do
  # Skip parameterized paths for this simple check
  if [[ "$p" == *"{"* ]]; then
    echo -e "${YELLOW}Skipping parameterized path:${NC} $p"
    continue
  fi

  # Skip SSE and well-known
  if [[ "$p" == *"/events/stream"* || "$p" == *".well-known"* ]]; then
      echo -e "${YELLOW}Skipping special path:${NC} $p"
      continue
  fi

  alias_path="/api/obs${p#/api}"

  echo "Checking alias for $p..."
  check_url "$MCP_BASE_URL$p" "Primary path"
  check_url "$MCP_BASE_URL$alias_path" "Alias path"
done


# --- Final Status ---
header "Validation Complete"
if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo -e "${GREEN}All Agent D Stage 1 validations passed successfully!${NC}"
else
  echo -e "${RED}Some Agent D Stage 1 validations failed.${NC}"
fi

exit "$EXIT_CODE"
