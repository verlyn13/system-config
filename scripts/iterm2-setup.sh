#!/usr/bin/env bash
# iTerm2 Dynamic Profiles Setup & Verification Script
# Manages iTerm2 profiles for local fish shell, OrbStack VMs, and production servers

set -euo pipefail

PROFILES_DIR="${HOME}/Library/Application Support/iTerm2/DynamicProfiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ${NC}  $*"
}

success() {
    echo -e "${GREEN}✓${NC}  $*"
}

warn() {
    echo -e "${YELLOW}⚠${NC}  $*"
}

error() {
    echo -e "${RED}✗${NC}  $*"
}

# Check if iTerm2 is installed
check_iterm2() {
    if [[ ! -d "/Applications/iTerm.app" ]]; then
        error "iTerm2 not found. Please install iTerm2 from https://iterm2.com/"
        exit 1
    fi
    success "iTerm2 is installed"
}

# Check if shell integration is installed
check_shell_integration() {
    local fish_integration="${HOME}/.config/fish/conf.d/iterm2_shell_integration.fish"
    local bash_integration="${HOME}/.iterm2_shell_integration.bash"
    local zsh_integration="${HOME}/.iterm2_shell_integration.zsh"

    if [[ -f "$fish_integration" ]] || [[ -f "$bash_integration" ]] || [[ -f "$zsh_integration" ]]; then
        success "Shell integration detected"
        return 0
    else
        warn "Shell integration not found"
        info "Install via: iTerm2 → Install Shell Integration"
        return 1
    fi
}

# Verify profiles directory exists
verify_profiles_dir() {
    if [[ ! -d "$PROFILES_DIR" ]]; then
        info "Creating Dynamic Profiles directory..."
        mkdir -p "$PROFILES_DIR"
    fi
    success "Dynamic Profiles directory exists: $PROFILES_DIR"
}

# List installed profiles
list_profiles() {
    info "Installed Dynamic Profiles:"
    if [[ -d "$PROFILES_DIR" ]]; then
        for profile in "$PROFILES_DIR"/*.json; do
            if [[ -f "$profile" ]]; then
                local count=$(jq '.Profiles | length' "$profile" 2>/dev/null || echo "?")
                echo "  • $(basename "$profile") ($count profile(s))"
            fi
        done
    else
        warn "No profiles directory found"
    fi
}

# Validate JSON profiles
validate_profiles() {
    local has_errors=0

    info "Validating profile JSON syntax..."
    for profile in "$PROFILES_DIR"/*.json; do
        if [[ -f "$profile" ]]; then
            if jq empty "$profile" 2>/dev/null; then
                success "$(basename "$profile") - valid JSON"
            else
                error "$(basename "$profile") - INVALID JSON"
                has_errors=1
            fi
        fi
    done

    return $has_errors
}

# Check SSH config
check_ssh_config() {
    local ssh_config="${HOME}/.ssh/config"

    if [[ ! -f "$ssh_config" ]]; then
        warn "SSH config not found at $ssh_config"
        return 1
    fi

    success "SSH config exists"

    # Check for specific hosts
    if grep -q "hetzner-secure" "$ssh_config" 2>/dev/null; then
        success "  Found: hetzner-secure"
    fi

    if grep -q "hetzner-docker" "$ssh_config" 2>/dev/null; then
        success "  Found: hetzner-docker"
    fi

    if grep -q "hetzner-hq" "$ssh_config" 2>/dev/null; then
        success "  Found: hetzner-hq (Tailscale)"
    fi

    if grep -q "Include.*orbstack" "$ssh_config" 2>/dev/null; then
        success "  Found: OrbStack SSH config inclusion"
    fi
}

# Check OrbStack
check_orbstack() {
    if command -v orb &> /dev/null; then
        success "OrbStack CLI available"

        if orb list 2>/dev/null | grep -q "ubuntu"; then
            success "  Ubuntu VM is running"
        else
            warn "  Ubuntu VM not found/running"
        fi
    else
        warn "OrbStack CLI not found (install from https://orbstack.dev/)"
    fi
}

# Test SSH connections (non-interactive)
test_ssh_connections() {
    info "Testing SSH configurations (timeout: 2s)..."

    # Test OrbStack
    if timeout 2 ssh -q -o BatchMode=yes -o ConnectTimeout=2 ubuntu@orb exit 2>/dev/null; then
        success "  ubuntu@orb - reachable"
    else
        warn "  ubuntu@orb - not reachable (VM may be stopped)"
    fi

    # Test Hetzner (if accessible)
    if timeout 2 ssh -q -o BatchMode=yes -o ConnectTimeout=2 hetzner-secure exit 2>/dev/null; then
        success "  hetzner-secure - reachable"
    else
        warn "  hetzner-secure - not reachable (network/firewall?)"
    fi
}

# Print manual setup instructions
print_manual_steps() {
    cat << 'EOF'

═══════════════════════════════════════════════════════════════════
📋 MANUAL iTerm2 CONFIGURATION STEPS
═══════════════════════════════════════════════════════════════════

1. SET DEFAULT PROFILE
   ─────────────────────
   • iTerm2 → Settings → Profiles
   • Select "Local — fish (Default)"
   • Click "Other Actions" → "Set as Default"

2. ENABLE SHELL INTEGRATION (if not already done)
   ─────────────────────────────────────────────
   • iTerm2 → Install Shell Integration
   • Follow prompts for your shell (fish/bash/zsh)

3. CONFIGURE KEY BINDINGS FOR FISH
   ──────────────────────────────
   • Settings → Profiles → Keys → Key Mappings
   • Ensure "Left Option key" = "Esc+" (for meta/alt key)
   • Ensure "Right Option key" = "Normal" (for special chars)
   • Verify paste works: ⌘V should paste clipboard

4. CONFIGURE NATURAL TEXT EDITING
   ──────────────────────────────
   • Settings → Profiles → Keys
   • Load Preset → "Natural Text Editing"

5. ENABLE CLIPBOARD ACCESS
   ─────────────────────────
   • Settings → General → Selection
   • ✓ "Applications in terminal may access clipboard"
   • ✓ "Copy to pasteboard on selection" (optional)

6. VERIFY TERMINAL SETTINGS
   ─────────────────────────
   • Settings → Profiles → Terminal
   • Report Terminal Type: xterm-256color
   • ✓ "Terminal may enable paste bracketing"

5. VERIFY PROFILES ARE LOADED
   ──────────────────────────
   • Settings → Profiles
   • You should see:
     ✓ Local — fish (Default)
     ✓ VM — Ubuntu (OrbStack)
     ✓ SSH — Hetzner (Production)
     ✓ SSH — Hetzner Docker (Root)
     ✓ SSH — Hetzner Tailscale (Mesh)

6. TEST PROFILE SWITCHING
   ──────────────────────
   • Open new window with "Local — fish"
   • SSH to ubuntu@orb → should auto-switch to VM profile
   • SSH to hetzner → should auto-switch to Production profile

═══════════════════════════════════════════════════════════════════
📚 REFERENCE
═══════════════════════════════════════════════════════════════════

Profile Features:
• Status Bar: Shows hostname, path, CPU, memory, network, time
• Badges: Visual labels (LOCAL, VM, PROD, ROOT)
• Triggers: Auto-highlight errors, dangerous commands
• Auto-switching: Profiles activate based on hostname/path
• Color coding:
  - Local: Standard black background, green badge
  - VM: Black background, blue badge
  - Prod: Dark red tint, red badge, extra warnings
  - Root: Bright red tint, aggressive warnings

Quick SSH:
• ssh ubuntu@orb          → Opens in VM profile
• ssh hetzner-secure      → Opens in Production profile (port 2222)
• ssh hetzner-docker      → Opens in Root profile (port 22)
• ssh hetzner-hq          → Opens in Tailscale profile

Profiles location:
~/Library/Application Support/iTerm2/DynamicProfiles/

═══════════════════════════════════════════════════════════════════
EOF
}

# Main execution
main() {
    echo ""
    info "iTerm2 Dynamic Profiles Setup & Verification"
    echo ""

    check_iterm2
    verify_profiles_dir
    echo ""

    list_profiles
    echo ""

    if ! validate_profiles; then
        error "Profile validation failed. Fix JSON errors and try again."
        exit 1
    fi
    echo ""

    check_shell_integration
    echo ""

    check_ssh_config
    echo ""

    check_orbstack
    echo ""

    test_ssh_connections
    echo ""

    print_manual_steps

    success "Setup verification complete!"
    echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
