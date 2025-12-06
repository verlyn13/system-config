#!/usr/bin/env bash
# Update Sentry CLI to latest version
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

# Check if npm is available
if ! command -v npm >/dev/null 2>&1; then
    log_error "npm not found. Install Node.js/npm first."
    exit 1
fi

# Check if sentry-cli is installed
if ! command -v sentry-cli >/dev/null 2>&1; then
    log_error "Sentry CLI not found. Installing..."
    npm install -g @sentry/cli
    exit $?
fi

# Get current and latest versions
current_version=$(sentry-cli --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
latest_version=$(npm view @sentry/cli version 2>/dev/null)

if [[ -z "$current_version" || -z "$latest_version" ]]; then
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

# Perform update
log_info "Updating Sentry CLI..."
if npm update -g @sentry/cli; then
    new_version=$(sentry-cli --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    log_success "Updated to v${new_version}"
else
    log_error "Update failed"
    exit 1
fi
