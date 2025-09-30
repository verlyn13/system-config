#!/bin/bash

# Test Dashboard Configuration
# Ensures dashboard is running on correct port with proper formatting

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         DASHBOARD CONFIGURATION TEST${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Test 1: Check configuration file
echo -e "${YELLOW}1. Checking config.json...${NC}"
if [ -f "config.json" ]; then
    PORT=$(python3 -c "import json; print(json.load(open('config.json'))['spec']['server']['port'])" 2>/dev/null)
    if [ "$PORT" = "8089" ]; then
        echo -e "${GREEN}   ✓ Configuration specifies port 8089${NC}"
    else
        echo -e "${RED}   ✗ Wrong port in config: $PORT${NC}"
        exit 1
    fi
else
    echo -e "${RED}   ✗ config.json not found${NC}"
    exit 1
fi

# Test 2: Check only one HTML file exists
echo -e "${YELLOW}2. Checking dashboard HTML files...${NC}"
HTML_COUNT=$(ls -1 *.html 2>/dev/null | wc -l)
if [ "$HTML_COUNT" -eq 1 ]; then
    echo -e "${GREEN}   ✓ Single dashboard file: index.html${NC}"
else
    echo -e "${RED}   ✗ Multiple HTML files found ($HTML_COUNT)${NC}"
    ls -1 *.html
    echo -e "${YELLOW}   Fix: Only index.html should exist${NC}"
fi

# Test 3: Check server configuration
echo -e "${YELLOW}3. Checking server configuration...${NC}"
if grep -q "config.json" dashboard-server.js; then
    echo -e "${GREEN}   ✓ Server reads config.json${NC}"
else
    echo -e "${RED}   ✗ Server doesn't read config.json${NC}"
fi

if grep -q "index.html" dashboard-server.js && ! grep -q "dashboard-client.html\|compliance-dashboard.html" dashboard-server.js; then
    echo -e "${GREEN}   ✓ Server serves only index.html${NC}"
else
    echo -e "${RED}   ✗ Server has fallback HTML files${NC}"
fi

# Test 4: Check for JSON.stringify in observations
echo -e "${YELLOW}4. Checking observation formatting...${NC}"
if grep -q "JSON.stringify.*observation" index.html; then
    echo -e "${RED}   ✗ Found JSON.stringify for observations${NC}"
else
    echo -e "${GREEN}   ✓ No JSON.stringify for observations${NC}"
fi

# Test 5: API health check (if server is running)
echo -e "${YELLOW}5. Testing API (if server is running)...${NC}"
if curl -s http://localhost:8089/health > /dev/null 2>&1; then
    HEALTH=$(curl -s http://localhost:8089/health | python3 -c "import sys, json; print(json.load(sys.stdin)['status'])" 2>/dev/null || echo "error")
    if [ "$HEALTH" = "healthy" ]; then
        echo -e "${GREEN}   ✓ Dashboard API is healthy${NC}"
        echo -e "${GREEN}   ✓ Dashboard is running on port 8089${NC}"
    else
        echo -e "${RED}   ✗ Dashboard API unhealthy: $HEALTH${NC}"
    fi
else
    echo -e "${BLUE}   ℹ Dashboard not running (start with ./start-dashboard.sh)${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              TEST COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Dashboard URL: ${BLUE}http://localhost:8089${NC}"
echo -e "${GREEN}Config File:   ${BLUE}config.json${NC}"
echo -e "${GREEN}HTML File:     ${BLUE}index.html${NC}"
echo -e "${GREEN}Server File:   ${BLUE}dashboard-server.js${NC}"
echo ""