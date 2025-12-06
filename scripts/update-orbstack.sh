#!/usr/bin/env bash
# Update OrbStack to latest version
# Run this script manually or via cron/launchd

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[info]${NC} $*"; }
log_success() { echo -e "${GREEN}[success]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
log_error() { echo -e "${RED}[error]${NC} $*"; }

# Check if Homebrew is available
if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not found."
    exit 1
fi

# Check if OrbStack is installed
if ! command -v orb >/dev/null 2>&1; then
    log_error "OrbStack not found. Installing..."
    brew install --cask orbstack
    exit $?
fi

# Get current and latest versions
current_version=$(orb version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
latest_info=$(brew info --cask orbstack 2>/dev/null | grep -E '^orbstack:' || echo "")
latest_version=$(echo "$latest_info" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 || echo "unknown")

if [[ "$current_version" == "unknown" || "$latest_version" == "unknown" ]]; then
    log_error "Could not determine version info"
    exit 1
fi

log_info "Current version: v${current_version}"
log_info "Latest version:  v${latest_version}"

if [[ "$current_version" == "$latest_version" ]]; then
    log_success "Already up to date!"
    exit 0
fi

log_warn "Update available: v${current_version} → v${latest_version}"

# Ask for confirmation unless --auto flag is passed
if [[ "${1:-}" != "--auto" ]]; then
    read -p "Update now? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled"
        exit 0
    fi
fi

# Check if OrbStack is running
if orb status >/dev/null 2>&1; then
    log_warn "OrbStack is currently running"
    log_info "The update may require restarting OrbStack"
fi

# Perform update
log_info "Updating OrbStack..."
if brew upgrade --cask orbstack; then
    new_version=$(orb version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
    log_success "Updated to v${new_version}"
    log_info "You may need to restart OrbStack: orb restart"
else
    log_error "Update failed"
    exit 1
fi
