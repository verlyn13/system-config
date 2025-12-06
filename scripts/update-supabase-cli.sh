#!/usr/bin/env bash
# Update Supabase CLI to latest version
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

# Check if supabase is installed
if ! command -v supabase >/dev/null 2>&1; then
    log_error "Supabase CLI not found. Installing..."
    brew install supabase/tap/supabase
    exit $?
fi

# Get current and latest versions
current_version=$(supabase --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
latest_version=$(brew info supabase/tap/supabase 2>/dev/null | grep -o 'stable [0-9]\+\.[0-9]\+\.[0-9]\+' | cut -d' ' -f2)

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
log_info "Updating Supabase CLI..."
if brew upgrade supabase/tap/supabase; then
    new_version=$(supabase --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    log_success "Updated to v${new_version}"
else
    log_error "Update failed"
    exit 1
fi
