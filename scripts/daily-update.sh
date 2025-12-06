#!/usr/bin/env bash
# Daily update for AI CLI tools and package managers
# Run: ./scripts/daily-update.sh
#
# Updates (in order):
#   1. Homebrew (package manager)
#   2. npm global packages
#   3. AI CLI tools (Claude, Codex, Gemini, Copilot)
#   4. Other CLI tools that frequently need updates

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${BLUE}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
header() { echo -e "\n${BOLD}${CYAN}$*${NC}"; }

# ============================================
header "📦 Package Managers"
# ============================================

log "Updating Homebrew..."
brew update --quiet
OUTDATED=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
if [[ "$OUTDATED" -gt 0 ]]; then
    warn "$OUTDATED outdated formulae (run: brew upgrade)"
else
    success "Homebrew up to date"
fi

log "Checking npm..."
NPM_OUTDATED=$(npm outdated -g --depth=0 2>/dev/null | tail -n +2 | wc -l | xargs || echo "0")
if [[ "$NPM_OUTDATED" =~ ^[0-9]+$ ]] && [[ "$NPM_OUTDATED" -gt 0 ]]; then
    warn "$NPM_OUTDATED outdated npm packages (run: npm update -g)"
else
    success "npm globals up to date"
fi

# ============================================
header "🤖 AI CLI Tools"
# ============================================

# Claude Code (npm - always latest)
log "Claude Code..."
CLAUDE_CURRENT=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
CLAUDE_LATEST=$(npm view @anthropic-ai/claude-code version 2>/dev/null || echo "")
if [[ -z "$CLAUDE_CURRENT" ]]; then
    warn "Claude not installed (npm i -g @anthropic-ai/claude-code)"
elif [[ "$CLAUDE_CURRENT" != "$CLAUDE_LATEST" ]]; then
    log "Updating Claude $CLAUDE_CURRENT → $CLAUDE_LATEST"
    npm update -g @anthropic-ai/claude-code >/dev/null 2>&1
    success "Claude updated to $CLAUDE_LATEST"
else
    success "Claude $CLAUDE_CURRENT (latest)"
fi

# Codex (brew tap)
log "Codex..."
CODEX_CURRENT=$(codex --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
if [[ -z "$CODEX_CURRENT" ]]; then
    warn "Codex not installed (brew install openai/openai/codex)"
else
    brew upgrade openai/openai/codex 2>/dev/null || true
    CODEX_NEW=$(codex --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ "$CODEX_CURRENT" != "$CODEX_NEW" ]]; then
        success "Codex updated $CODEX_CURRENT → $CODEX_NEW"
    else
        success "Codex $CODEX_CURRENT (latest)"
    fi
fi

# Gemini (npm)
log "Gemini..."
GEMINI_CURRENT=$(gemini --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
if [[ -z "$GEMINI_CURRENT" ]]; then
    warn "Gemini not installed (npm i -g @google/gemini-cli)"
else
    GEMINI_LATEST=$(npm view @google/gemini-cli version 2>/dev/null || echo "unknown")
    if [[ "$GEMINI_LATEST" != "unknown" && "$GEMINI_CURRENT" != "$GEMINI_LATEST" ]]; then
        log "Updating Gemini $GEMINI_CURRENT → $GEMINI_LATEST"
        npm update -g @google/gemini-cli >/dev/null 2>&1 || true
        success "Gemini updated to $GEMINI_LATEST"
    else
        success "Gemini $GEMINI_CURRENT (latest)"
    fi
fi

# GitHub Copilot (gh extension)
log "GitHub Copilot..."
COPILOT_CURRENT=$(gh copilot --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
if [[ -z "$COPILOT_CURRENT" ]]; then
    warn "Copilot not installed (gh extension install github/gh-copilot)"
else
    gh extension upgrade gh-copilot 2>/dev/null || true
    COPILOT_NEW=$(gh copilot --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ "$COPILOT_CURRENT" != "$COPILOT_NEW" ]]; then
        success "Copilot updated $COPILOT_CURRENT → $COPILOT_NEW"
    else
        success "Copilot $COPILOT_CURRENT (latest)"
    fi
fi

# ============================================
header "🔧 Other CLI Tools"
# ============================================

# Supabase (brew tap)
if command -v supabase >/dev/null 2>&1; then
    log "Supabase..."
    brew upgrade supabase/tap/supabase 2>/dev/null || true
    success "Supabase $(supabase --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
fi

# Infisical (brew tap)
if command -v infisical >/dev/null 2>&1; then
    log "Infisical..."
    brew upgrade infisical/get-cli/infisical 2>/dev/null || true
    success "Infisical $(infisical --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
fi

# Terraform (brew tap)
if command -v terraform >/dev/null 2>&1; then
    log "Terraform..."
    brew upgrade hashicorp/tap/terraform 2>/dev/null || true
    success "Terraform $(terraform --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
fi

# Sentry (npm)
if command -v sentry-cli >/dev/null 2>&1; then
    log "Sentry..."
    npm update -g @sentry/cli >/dev/null 2>&1 || true
    success "Sentry $(sentry-cli --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
fi

# Vercel (npm)
if command -v vercel >/dev/null 2>&1; then
    log "Vercel..."
    npm update -g vercel >/dev/null 2>&1 || true
    success "Vercel $(vercel --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
fi

# ============================================
header "✅ Done"
# ============================================

echo ""
echo "AI Tools:"
echo "  Claude:  $(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo 'n/a')"
echo "  Codex:   $(codex --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo 'n/a')"
echo "  Gemini:  $(gemini --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo 'n/a')"
echo "  Copilot: $(gh copilot --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo 'n/a')"
echo ""
