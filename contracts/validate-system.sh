#!/bin/bash

# System Configuration Validation Script
# Ensures all components use correct configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}        SYSTEM CONFIGURATION VALIDATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate OPA is installed
echo -e "${YELLOW}1. Checking OPA installation...${NC}"
if command_exists opa; then
    OPA_VERSION=$(opa version | head -n1 | awk '{print $2}')
    echo -e "${GREEN}   ✓ OPA installed: version ${OPA_VERSION}${NC}"
else
    echo -e "${RED}   ✗ OPA not installed${NC}"
    echo "     Install with: brew install opa"
    exit 1
fi

# Validate dashboard configuration
echo -e "${YELLOW}2. Validating dashboard configuration...${NC}"
if [ -f "dashboard/config.json" ]; then
    RESULT=$(opa eval -d policies/dashboard-config.rego -i dashboard/config.json "data.dashboard.config.allow" 2>&1)
    if echo "$RESULT" | grep -q '"value": true'; then
        echo -e "${GREEN}   ✓ Dashboard configuration is valid${NC}"
        echo -e "${GREEN}   ✓ Dashboard port: 8089${NC}"
    else
        echo -e "${RED}   ✗ Dashboard configuration is invalid${NC}"
        echo "$RESULT"
        exit 1
    fi
else
    echo -e "${RED}   ✗ Dashboard config.json not found${NC}"
    exit 1
fi

# Check system registry
echo -e "${YELLOW}3. Checking system registry...${NC}"
if [ -f "SYSTEM_REGISTRY.json" ]; then
    # Extract dashboard port from registry
    REGISTRY_PORT=$(python3 -c "import json; print(json.load(open('SYSTEM_REGISTRY.json'))['spec']['services']['dashboard']['port'])" 2>/dev/null || echo "error")
    if [ "$REGISTRY_PORT" = "8089" ]; then
        echo -e "${GREEN}   ✓ Registry has correct dashboard port${NC}"
    else
        echo -e "${RED}   ✗ Registry has incorrect dashboard port: $REGISTRY_PORT${NC}"
        exit 1
    fi
else
    echo -e "${RED}   ✗ System registry not found${NC}"
    exit 1
fi

# Validate manifests exist
echo -e "${YELLOW}4. Checking service manifests...${NC}"
MANIFEST_COUNT=0
for manifest in ~/Development/personal/*/manifest.json; do
    if [ -f "$manifest" ]; then
        SERVICE=$(basename $(dirname "$manifest"))
        # Check if manifest is valid JSON
        if python3 -m json.tool "$manifest" > /dev/null 2>&1; then
            echo -e "${GREEN}   ✓ Valid manifest: $SERVICE${NC}"
            ((MANIFEST_COUNT++))
        else
            echo -e "${RED}   ✗ Invalid JSON in manifest: $SERVICE${NC}"
        fi
    fi
done
echo -e "${BLUE}   Total manifests: $MANIFEST_COUNT${NC}"

# Check if dashboard server file exists
echo -e "${YELLOW}5. Checking dashboard server...${NC}"
if [ -f "dashboard/dashboard-server.js" ]; then
    # Check if it imports config.json
    if grep -q "config.json" dashboard/dashboard-server.js; then
        echo -e "${GREEN}   ✓ Dashboard server reads config.json${NC}"
    else
        echo -e "${RED}   ✗ Dashboard server doesn't read config.json${NC}"
    fi

    # Check no test servers exist
    if [ ! -f "dashboard/test-server.js" ]; then
        echo -e "${GREEN}   ✓ No conflicting test servers${NC}"
    else
        echo -e "${RED}   ✗ test-server.js exists - remove to avoid confusion${NC}"
    fi
else
    echo -e "${RED}   ✗ Dashboard server not found${NC}"
    exit 1
fi

# Validate OPA policies compile
echo -e "${YELLOW}6. Validating OPA policies...${NC}"
for policy in policies/*.rego; do
    if [ -f "$policy" ]; then
        POLICY_NAME=$(basename "$policy")
        if opa fmt --diff "$policy" > /dev/null 2>&1; then
            echo -e "${GREEN}   ✓ Valid policy: $POLICY_NAME${NC}"
        else
            echo -e "${RED}   ✗ Invalid policy: $POLICY_NAME${NC}"
            opa fmt --diff "$policy"
        fi
    fi
done

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}             VALIDATION COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Key Configuration:${NC}"
echo -e "  Dashboard URL:  ${BLUE}http://localhost:8089${NC}"
echo -e "  OPA URL:        ${BLUE}http://localhost:8181${NC}"
echo -e "  Config File:    ${BLUE}dashboard/config.json${NC}"
echo -e "  Registry:       ${BLUE}SYSTEM_REGISTRY.json${NC}"
echo ""
echo -e "${YELLOW}To start the dashboard:${NC}"
echo -e "  cd dashboard && ./start-dashboard.sh"
echo ""