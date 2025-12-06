#!/usr/bin/env bash
# Unified tool updater for all CLI tools
# Usage: ./update-all.sh [--check|--auto]
#   --check: Only show status, don't update
#   --auto:  Update without prompts

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_header() { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}"; }
log_info() { echo -e "${BLUE}[info]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }
log_update() { echo -e "${YELLOW}[↑]${NC} $*"; }

MODE="${1:-interactive}"
UPDATES_AVAILABLE=0

check_tool() {
    local name="$1"
    local cmd="$2"
    local current="$3"
    local latest="$4"

    if [[ -z "$current" ]]; then
        log_error "$name: NOT INSTALLED"
        return 1
    elif [[ -z "$latest" || "$latest" == "unknown" ]]; then
        log_info "$name: v$current (latest unknown)"
    elif [[ "$current" == "$latest" ]]; then
        log_success "$name: v$current (up to date)"
    else
        log_update "$name: v$current → v$latest"
        UPDATES_AVAILABLE=$((UPDATES_AVAILABLE + 1))
        return 2
    fi
    return 0
}

update_npm_tool() {
    local name="$1"
    local package="$2"

    log_info "Updating $name..."
    if npm update -g "$package" 2>/dev/null; then
        log_success "$name updated"
    else
        log_error "$name update failed"
        return 1
    fi
}

update_brew_tool() {
    local name="$1"
    local formula="$2"

    log_info "Updating $name..."
    if brew upgrade "$formula" 2>/dev/null; then
        log_success "$name updated"
    else
        # May already be up to date
        log_info "$name: no update needed or already latest"
    fi
}

# ============================================
log_header "CLI Tool Status"
# ============================================

# Claude Code (npm)
CLAUDE_CURRENT=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
CLAUDE_LATEST=$(npm view @anthropic-ai/claude-code version 2>/dev/null || echo "unknown")
check_tool "Claude Code" "claude" "$CLAUDE_CURRENT" "$CLAUDE_LATEST" || CLAUDE_NEEDS_UPDATE=$?

# Codex (brew)
CODEX_CURRENT=$(codex --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
CODEX_LATEST=$(brew info openai/openai/codex --json 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null || echo "unknown")
check_tool "Codex" "codex" "$CODEX_CURRENT" "$CODEX_LATEST" || CODEX_NEEDS_UPDATE=$?

# Sentry (npm)
SENTRY_CURRENT=$(sentry-cli --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
SENTRY_LATEST=$(npm view @sentry/cli version 2>/dev/null || echo "unknown")
check_tool "Sentry CLI" "sentry-cli" "$SENTRY_CURRENT" "$SENTRY_LATEST" || SENTRY_NEEDS_UPDATE=$?

# Vercel (npm)
VERCEL_CURRENT=$(vercel --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
VERCEL_LATEST=$(npm view vercel version 2>/dev/null || echo "unknown")
check_tool "Vercel" "vercel" "$VERCEL_CURRENT" "$VERCEL_LATEST" || VERCEL_NEEDS_UPDATE=$?

# Supabase (brew)
SUPABASE_CURRENT=$(supabase --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
SUPABASE_LATEST=$(brew info supabase/tap/supabase --json 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null || echo "unknown")
check_tool "Supabase" "supabase" "$SUPABASE_CURRENT" "$SUPABASE_LATEST" || SUPABASE_NEEDS_UPDATE=$?

# Terraform (brew)
TERRAFORM_CURRENT=$(terraform --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
TERRAFORM_LATEST=$(brew info hashicorp/tap/terraform --json 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null || echo "unknown")
check_tool "Terraform" "terraform" "$TERRAFORM_CURRENT" "$TERRAFORM_LATEST" || TERRAFORM_NEEDS_UPDATE=$?

# Infisical (brew)
INFISICAL_CURRENT=$(infisical --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
INFISICAL_LATEST=$(brew info infisical/get-cli/infisical --json 2>/dev/null | jq -r '.[0].versions.stable' 2>/dev/null || echo "unknown")
check_tool "Infisical" "infisical" "$INFISICAL_CURRENT" "$INFISICAL_LATEST" || INFISICAL_NEEDS_UPDATE=$?

# OrbStack (cask - check differently)
ORBSTACK_CURRENT=$(orb version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
log_info "OrbStack: v$ORBSTACK_CURRENT (update via app or: brew upgrade --cask orbstack)"

# GitHub Copilot (gh extension)
COPILOT_CURRENT=$(gh copilot --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
log_info "GH Copilot: v$COPILOT_CURRENT (update via: gh extension upgrade gh-copilot)"

# ============================================
# Summary and update prompt
# ============================================

echo ""
if [[ $UPDATES_AVAILABLE -eq 0 ]]; then
    log_success "All tools are up to date!"
    exit 0
fi

log_warn "$UPDATES_AVAILABLE update(s) available"

if [[ "$MODE" == "--check" ]]; then
    exit 0
fi

if [[ "$MODE" != "--auto" ]]; then
    echo ""
    read -p "Apply updates? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled"
        exit 0
    fi
fi

# ============================================
log_header "Applying Updates"
# ============================================

# npm tools
[[ "${CLAUDE_NEEDS_UPDATE:-0}" == "2" ]] && update_npm_tool "Claude Code" "@anthropic-ai/claude-code"
[[ "${SENTRY_NEEDS_UPDATE:-0}" == "2" ]] && update_npm_tool "Sentry CLI" "@sentry/cli"
[[ "${VERCEL_NEEDS_UPDATE:-0}" == "2" ]] && update_npm_tool "Vercel" "vercel"

# brew tools
[[ "${CODEX_NEEDS_UPDATE:-0}" == "2" ]] && update_brew_tool "Codex" "openai/openai/codex"
[[ "${SUPABASE_NEEDS_UPDATE:-0}" == "2" ]] && update_brew_tool "Supabase" "supabase/tap/supabase"
[[ "${TERRAFORM_NEEDS_UPDATE:-0}" == "2" ]] && update_brew_tool "Terraform" "hashicorp/tap/terraform"
[[ "${INFISICAL_NEEDS_UPDATE:-0}" == "2" ]] && update_brew_tool "Infisical" "infisical/get-cli/infisical"

# ============================================
log_header "Update Complete"
# ============================================

# Show new versions
echo ""
claude --version 2>/dev/null | head -1 || true
codex --version 2>/dev/null || true
sentry-cli --version 2>/dev/null || true
vercel --version 2>/dev/null || true
supabase --version 2>/dev/null || true
terraform --version 2>/dev/null | head -1 || true
infisical --version 2>/dev/null || true
