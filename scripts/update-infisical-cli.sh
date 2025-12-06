#!/usr/bin/env bash
# Update Infisical CLI to latest version
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

# Check if Infisical CLI is installed
if ! command -v infisical >/dev/null 2>&1; then
    log_error "Infisical CLI not found. Installing..."
    brew install infisical
    exit $?
fi

# Get current and latest versions
current_version=$(infisical --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 || echo "unknown")
latest_version=$(brew info infisical --json 2>/dev/null | jq -r '.[0].versions.stable' || echo "unknown")

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

# Perform update
log_info "Updating Infisical CLI..."
if brew upgrade infisical; then
    new_version=$(infisical --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    log_success "Updated to v${new_version}"
    log_info "Your configuration at ~/.config/fish/conf.d/19-infisical.fish is unchanged"
    log_info "Self-hosted instance: https://infisical.jefahnierocks.com"
else
    log_error "Update failed"
    exit 1
fi
