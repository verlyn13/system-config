#!/bin/bash

# Dashboard Fragmentation Detection Script
# Identifies all dashboards and reports conflicts

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}       DASHBOARD FRAGMENTATION DETECTION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Find all dashboard directories
echo -e "${YELLOW}1. Searching for dashboard directories...${NC}"
DASHBOARD_DIRS=$(find ~/Development/personal -type d -name "*dashboard*" 2>/dev/null | grep -v node_modules | grep -v ".git" || true)

if [ -z "$DASHBOARD_DIRS" ]; then
    echo -e "${GREEN}   ✓ No dashboard directories found${NC}"
else
    echo -e "${RED}   ⚠ Found multiple dashboard locations:${NC}"
    echo "$DASHBOARD_DIRS" | while read -r dir; do
        echo -e "${YELLOW}     - $dir${NC}"
    done
fi

# Check running processes on dashboard ports
echo -e "\n${YELLOW}2. Checking active dashboard ports...${NC}"

# Check port 5173 (Vite)
if lsof -i :5173 > /dev/null 2>&1; then
    echo -e "${RED}   ✗ Port 5173 is active (system-dashboard Vite client)${NC}"
    VITE_ACTIVE=true
else
    echo -e "${GREEN}   ✓ Port 5173 is free${NC}"
    VITE_ACTIVE=false
fi

# Check port 3001 (Express)
if lsof -i :3001 > /dev/null 2>&1; then
    echo -e "${RED}   ✗ Port 3001 is active (system-dashboard Express server)${NC}"
    EXPRESS_ACTIVE=true
else
    echo -e "${GREEN}   ✓ Port 3001 is free${NC}"
    EXPRESS_ACTIVE=false
fi

# Check port 8089 (Contracts dashboard)
if lsof -i :8089 > /dev/null 2>&1; then
    echo -e "${RED}   ✗ Port 8089 is active (contracts dashboard)${NC}"
    CONTRACTS_ACTIVE=true
else
    echo -e "${GREEN}   ✓ Port 8089 is free${NC}"
    CONTRACTS_ACTIVE=false
fi

# Check configuration files
echo -e "\n${YELLOW}3. Checking dashboard configurations...${NC}"

SYSTEM_DASH_PKG="$HOME/Development/personal/system-dashboard/package.json"
CONTRACTS_DASH_CFG="$HOME/Development/personal/system-setup-update/contracts/dashboard/config.json"
UNIFIED_CONFIG="$HOME/Development/personal/DASHBOARD_CONFIG.json"

if [ -f "$SYSTEM_DASH_PKG" ]; then
    echo -e "${BLUE}   ✓ system-dashboard found (React/Vite)${NC}"
    SYSTEM_DASH=true
else
    SYSTEM_DASH=false
fi

if [ -f "$CONTRACTS_DASH_CFG" ]; then
    echo -e "${BLUE}   ✓ contracts/dashboard found (HTML/Express)${NC}"
    CONTRACTS_DASH=true
else
    CONTRACTS_DASH=false
fi

if [ -f "$UNIFIED_CONFIG" ]; then
    echo -e "${GREEN}   ✓ Unified configuration exists${NC}"
    UNIFIED=true
else
    echo -e "${RED}   ✗ No unified configuration found${NC}"
    UNIFIED=false
fi

# Analyze fragmentation
echo -e "\n${YELLOW}4. Fragmentation Analysis...${NC}"

FRAGMENTATION_LEVEL=0
ISSUES=()

if [ "$SYSTEM_DASH" = true ] && [ "$CONTRACTS_DASH" = true ]; then
    ((FRAGMENTATION_LEVEL++))
    ISSUES+=("Multiple dashboard codebases exist")
fi

if [ "$VITE_ACTIVE" = true ] && [ "$CONTRACTS_ACTIVE" = true ]; then
    ((FRAGMENTATION_LEVEL++))
    ISSUES+=("Multiple dashboards running simultaneously")
fi

if [ "$UNIFIED" = false ]; then
    ((FRAGMENTATION_LEVEL++))
    ISSUES+=("No unified configuration")
fi

# Report results
echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    REPORT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

if [ $FRAGMENTATION_LEVEL -eq 0 ]; then
    echo -e "${GREEN}✅ NO FRAGMENTATION DETECTED${NC}"
else
    echo -e "${RED}⚠️  FRAGMENTATION DETECTED (Level: $FRAGMENTATION_LEVEL)${NC}"
    echo -e "\n${YELLOW}Issues found:${NC}"
    for issue in "${ISSUES[@]}"; do
        echo -e "${RED}  • $issue${NC}"
    done
fi

echo -e "\n${BLUE}Current Status:${NC}"
echo -e "  Primary Dashboard:   ${GREEN}system-dashboard (port 5173)${NC}"
echo -e "  Secondary Dashboard: ${YELLOW}contracts/dashboard (port 8089) - DEPRECATED${NC}"

echo -e "\n${BLUE}Recommendations:${NC}"
echo -e "  1. Use ${GREEN}http://localhost:5173${NC} as the primary dashboard"
echo -e "  2. Stop contracts dashboard if running"
echo -e "  3. Refer to ${GREEN}DASHBOARD_CONFIG.json${NC} for configuration"
echo -e "  4. Check ${GREEN}CRITICAL_DASHBOARD_ALIGNMENT.md${NC} for details"

echo ""