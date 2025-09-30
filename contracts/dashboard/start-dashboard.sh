#!/bin/bash

# SYSTEM COMPLIANCE DASHBOARD STARTUP
# THIS IS THE ONLY DASHBOARD - PORT 8089 ONLY

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 SYSTEM COMPLIANCE DASHBOARD${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RED}📍 SINGLE DASHBOARD PORT: 8089${NC}"
echo -e "${GREEN}📋 Configuration: config.json${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if npm dependencies are installed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
fi

# Check for manifests
echo -e "\n${BLUE}Checking for service manifests:${NC}"
MANIFEST_COUNT=0

for manifest in ~/Development/personal/*/manifest.json; do
    if [ -f "$manifest" ]; then
        SERVICE=$(basename $(dirname "$manifest"))
        echo -e "${GREEN}  ✓${NC} Found: $SERVICE"
        ((MANIFEST_COUNT++))
    fi
done

if [ $MANIFEST_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No manifests found!${NC}"
    echo "  Services need manifest.json files to appear in the dashboard."
    echo ""
    echo "  Example manifests exist in:"
    echo "    • ~/Development/personal/ds-go/manifest.json"
    echo "    • ~/Development/personal/system-setup-update/manifest.json"
fi

echo ""
echo -e "${BLUE}Starting dashboard server...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Dashboard will be available at:${NC}"
echo -e "  ${BLUE}http://localhost:8089${NC}"
echo ""
echo -e "${YELLOW}Features:${NC}"
echo "  • Overview tab: System-wide compliance metrics"
echo "  • Services tab: Individual service status"
echo "  • Observers tab: Active observers and observations"
echo "  • Violations tab: Contract violations and SLO breaches"
echo ""
echo -e "${YELLOW}API Endpoints:${NC}"
echo "  • GET /api/services - Service list"
echo "  • GET /api/compliance - Compliance metrics"
echo "  • GET /api/observations - Recent observations"
echo "  • GET /api/violations - Current violations"
echo "  • GET /api/stream - SSE real-time updates"
echo ""
echo "Press Ctrl+C to stop the server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start the server
npm start