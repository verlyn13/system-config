#!/bin/bash

# Install and manage LaunchAgent for documentation synchronization
# Version: 1.0.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLIST_SOURCE="$REPO_ROOT/03-automation/launchd/com.system.docsync.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.system.docsync.plist"
LABEL="com.system.docsync"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [install|uninstall|status|start|stop|restart]"
    echo ""
    echo "Commands:"
    echo "  install   - Install the LaunchAgent"
    echo "  uninstall - Remove the LaunchAgent"
    echo "  status    - Check if the agent is running"
    echo "  start     - Start the agent immediately"
    echo "  stop      - Stop the agent"
    echo "  restart   - Restart the agent"
}

install_agent() {
    echo -e "${GREEN}📦 Installing Documentation Sync LaunchAgent...${NC}"

    # Create LaunchAgents directory if it doesn't exist
    mkdir -p "$HOME/Library/LaunchAgents"

    # Check if already installed
    if [ -f "$PLIST_DEST" ]; then
        echo -e "${YELLOW}⚠️  LaunchAgent already exists. Updating...${NC}"
        launchctl unload "$PLIST_DEST" 2>/dev/null || true
    fi

    # Copy plist file
    cp "$PLIST_SOURCE" "$PLIST_DEST"

    # Set correct permissions
    chmod 644 "$PLIST_DEST"

    # Load the agent
    launchctl load "$PLIST_DEST"

    echo -e "${GREEN}✅ LaunchAgent installed and loaded!${NC}"
    echo ""
    echo "The documentation sync will run:"
    echo "  • Every 4 hours automatically"
    echo "  • When chezmoi, config, or Homebrew directories change"
    echo "  • On system startup"
    echo ""
    echo "Logs are available at:"
    echo "  • ~/Library/Logs/docsync.log"
    echo "  • ~/Library/Logs/docsync-error.log"
}

uninstall_agent() {
    echo -e "${YELLOW}🗑  Uninstalling Documentation Sync LaunchAgent...${NC}"

    if [ -f "$PLIST_DEST" ]; then
        # Unload the agent
        launchctl unload "$PLIST_DEST" 2>/dev/null || true

        # Remove the plist file
        rm "$PLIST_DEST"

        echo -e "${GREEN}✅ LaunchAgent uninstalled!${NC}"
    else
        echo -e "${YELLOW}⚠️  LaunchAgent not installed.${NC}"
    fi
}

check_status() {
    echo -e "${GREEN}📊 Checking Documentation Sync status...${NC}"
    echo ""

    # Check if plist exists
    if [ ! -f "$PLIST_DEST" ]; then
        echo -e "${RED}❌ LaunchAgent not installed${NC}"
        echo "Run '$0 install' to install it."
        return 1
    fi

    # Check if loaded
    if launchctl list | grep -q "$LABEL"; then
        echo -e "${GREEN}✅ LaunchAgent is loaded${NC}"

        # Get detailed status
        launchctl list "$LABEL" | tail -n +2

        # Check last run from log
        if [ -f "$HOME/Library/Logs/docsync.log" ]; then
            echo ""
            echo "Last sync attempt:"
            tail -n 5 "$HOME/Library/Logs/docsync.log" | head -n 1
        fi
    else
        echo -e "${YELLOW}⚠️  LaunchAgent is installed but not loaded${NC}"
        echo "Run '$0 start' to load it."
    fi

    # Check if sync script exists and is executable
    echo ""
    if [ -x "$REPO_ROOT/03-automation/scripts/doc-sync-engine.py" ]; then
        echo -e "${GREEN}✅ Sync script is executable${NC}"
    else
        echo -e "${RED}❌ Sync script is missing or not executable${NC}"
    fi
}

start_agent() {
    echo -e "${GREEN}▶️  Starting Documentation Sync...${NC}"

    if [ ! -f "$PLIST_DEST" ]; then
        echo -e "${RED}❌ LaunchAgent not installed. Run '$0 install' first.${NC}"
        return 1
    fi

    launchctl load "$PLIST_DEST" 2>/dev/null || echo "Already loaded"
    launchctl start "$LABEL"

    echo -e "${GREEN}✅ Documentation sync started!${NC}"
}

stop_agent() {
    echo -e "${YELLOW}⏹  Stopping Documentation Sync...${NC}"

    launchctl stop "$LABEL" 2>/dev/null || true
    launchctl unload "$PLIST_DEST" 2>/dev/null || true

    echo -e "${GREEN}✅ Documentation sync stopped!${NC}"
}

restart_agent() {
    echo -e "${YELLOW}🔄 Restarting Documentation Sync...${NC}"
    stop_agent
    sleep 2
    start_agent
}

# Main script logic
case "${1:-}" in
    install)
        install_agent
        ;;
    uninstall)
        uninstall_agent
        ;;
    status)
        check_status
        ;;
    start)
        start_agent
        ;;
    stop)
        stop_agent
        ;;
    restart)
        restart_agent
        ;;
    *)
        print_usage
        exit 1
        ;;
esac