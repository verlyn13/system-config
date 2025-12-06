#!/usr/bin/env bash
# Update Codex CLI to latest version
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

# Prefer Homebrew installs; fall back to npm if brew is unavailable.

have_brew() { command -v brew >/dev/null 2>&1; }
have_npm() { command -v npm >/dev/null 2>&1; }
have_jq() { command -v jq >/dev/null 2>&1; }

# Check if codex is installed
if ! command -v codex >/dev/null 2>&1; then
    log_error "Codex CLI not found. Installing..."
    if have_brew; then
        brew install openai/openai/codex
    elif have_npm; then
        npm install -g @openai/codex
    else
        log_error "Neither brew nor npm is available. Install one of them first."
        exit 1
    fi
    exit $?
fi

current_version=$(codex --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
log_info "Current version: v${current_version:-unknown}"

if have_brew; then
    log_info "Using Homebrew for updates (openai/openai/codex)."
    latest_version=""
    if have_jq; then
        latest_version=$(brew info openai/openai/codex --json | jq -r '.[0].versions.stable' 2>/dev/null || echo "")
    fi
    if [[ -z "$latest_version" ]]; then
        log_warn "Could not determine latest version via brew; attempting upgrade anyway."
    elif [[ "$current_version" == "$latest_version" ]]; then
        log_success "Already up to date!"
        exit 0
    else
        log_warn "Update available: v${current_version} → v${latest_version}"
    fi
else
    if ! have_npm; then
        log_error "Neither brew nor npm available for update."
        exit 1
    fi

    latest_version=$(npm view @openai/codex version 2>/dev/null)
    if [[ -z "$current_version" || -z "$latest_version" ]]; then
        log_error "Could not determine version info"
        exit 1
    fi

    log_info "Latest version (npm):  v${latest_version}"

    if [[ "$current_version" == "$latest_version" ]]; then
        log_success "Already up to date!"

        # Ask if user wants to try beta/alpha
        if [[ "${1:-}" != "--auto" ]]; then
            echo ""
            log_info "Want to try a newer build?"
            echo "  - Beta:   npm install -g @openai/codex@beta"
            echo "  - Native: npm install -g @openai/codex@native"
            echo "  - Alpha:  npm install -g @openai/codex@alpha"
        fi
        exit 0
    fi

    log_warn "Update available: v${current_version} → v${latest_version}"
fi

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
log_info "Updating Codex CLI..."
if have_brew; then
    if brew upgrade openai/openai/codex; then
        new_version=$(codex --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        log_success "Updated to v${new_version}"
    else
        log_error "brew upgrade failed"
        exit 1
    fi
else
    if npm update -g @openai/codex; then
        new_version=$(codex --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        log_success "Updated to v${new_version}"
    else
        log_error "npm update failed"
        exit 1
    fi
fi

# Backup and verify config
if [[ -f ~/.codex/config.toml ]]; then
    log_info "Config file exists at ~/.codex/config.toml"
    log_info "Run 'codex -p dev' to verify settings"
else
    log_warn "No config file found. Create one at ~/.codex/config.toml"
fi
