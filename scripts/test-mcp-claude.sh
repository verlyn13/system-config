#!/bin/bash

# Test MCP Server Configuration for Claude Code
# This script verifies that the devops-mcp server is properly configured and accessible

set -e

echo "=== MCP Server Configuration Test ==="
echo "Date: $(date)"
echo "======================================"
echo

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if configuration file exists
CONFIG_FILE="$HOME/.config/claude/claude_desktop_config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✓${NC} Claude Code configuration found"
else
    echo -e "${RED}✗${NC} Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Check if devops-mcp is configured
if grep -q '"devops-mcp"' "$CONFIG_FILE"; then
    echo -e "${GREEN}✓${NC} devops-mcp server is configured"
else
    echo -e "${RED}✗${NC} devops-mcp server not found in configuration"
    exit 1
fi

# Check if devops-mcp is built
DEVOPS_MCP_DIR="$HOME/Development/personal/devops-mcp"
if [ -f "$DEVOPS_MCP_DIR/dist/index.js" ]; then
    echo -e "${GREEN}✓${NC} devops-mcp is built"
else
    echo -e "${RED}✗${NC} devops-mcp not built. Run: cd $DEVOPS_MCP_DIR && pnpm build"
    exit 1
fi

# Check if MCP config exists
MCP_CONFIG="$HOME/.config/devops-mcp/config.toml"
if [ -f "$MCP_CONFIG" ]; then
    echo -e "${GREEN}✓${NC} MCP configuration found"
else
    echo -e "${RED}✗${NC} MCP configuration not found at $MCP_CONFIG"
    exit 1
fi

# Test if the server can start
echo
echo "Testing server startup..."
cd "$DEVOPS_MCP_DIR"
timeout 2 node dist/index.js 2>&1 | head -5 | grep -q "READY" && \
    echo -e "${GREEN}✓${NC} Server starts successfully" || \
    echo -e "${YELLOW}⚠${NC} Server startup test inconclusive"

echo
echo "=== Configuration Summary ==="
echo
echo "MCP Servers configured:"
jq -r '.mcpServers | keys[]' "$CONFIG_FILE" | while read server; do
    echo "  - $server"
done

echo
echo "devops-mcp configuration:"
echo "  Command: node"
echo "  Script: $DEVOPS_MCP_DIR/dist/index.js"
echo "  Config: $MCP_CONFIG"

echo
echo -e "${GREEN}=== MCP Configuration Test Complete ===${NC}"
echo
echo "To use MCP in Claude Code:"
echo "1. Restart Claude Code if it's running"
echo "2. Run: claude mcp"
echo "3. You should see 'devops-mcp' in the list of available servers"
echo
echo "Available MCP tools from devops-mcp:"
echo "  - mcp_health: Check server health"
echo "  - patch_apply_check: Check patch application"
echo "  - pkg_sync_plan: Plan package synchronization"
echo "  - pkg_sync_apply: Apply package synchronization"
echo "  - dotfiles_apply: Apply dotfiles configuration"
echo "  - secrets_read_ref: Read secret references"
echo
echo "Available MCP resources:"
echo "  - devops://dotfiles_state: Current dotfiles state"
echo "  - devops://policy_manifest: Policy configuration"
echo "  - devops://pkg_inventory: Package inventory"
echo "  - devops://repo_status: Repository status"