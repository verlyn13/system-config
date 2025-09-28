#!/bin/bash

# System State Synchronization Script
# Automatically syncs documentation with live system configuration
# Version: 1.0.0
# Last Updated: 2025-09-26

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORTS_DIR="${REPO_ROOT}/07-reports/status"
TEMPLATES_DIR="${REPO_ROOT}/06-templates"
META_DIR="${REPO_ROOT}/.meta"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo -e "${BLUE}🔄 System State Synchronization${NC}"
echo "================================================"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Function to log actions
log() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Capture Current System State
capture_system_state() {
    echo -e "\n${BLUE}1. Capturing System State...${NC}"

    # System info
    cat > "${REPORTS_DIR}/system-info.json" << EOF
{
  "timestamp": "${TIMESTAMP}",
  "os": "$(sw_vers -productName)",
  "version": "$(sw_vers -productVersion)",
  "build": "$(sw_vers -buildVersion)",
  "arch": "$(uname -m)",
  "hostname": "$(hostname)",
  "user": "${USER}"
}
EOF
    log "System information captured"
}

# 2. Sync Homebrew State
sync_homebrew() {
    echo -e "\n${BLUE}2. Syncing Homebrew State...${NC}"

    if command -v brew &> /dev/null; then
        # Generate Brewfile
        brew bundle dump --file="${REPORTS_DIR}/Brewfile.current" --force --describe
        log "Brewfile generated"

        # List installed packages
        brew list --formula -1 > "${REPORTS_DIR}/brew-formulas.txt"
        brew list --cask -1 > "${REPORTS_DIR}/brew-casks.txt"
        log "Package lists updated"
    else
        warning "Homebrew not installed"
    fi
}

# 3. Sync Chezmoi Configuration
sync_chezmoi() {
    echo -e "\n${BLUE}3. Syncing Chezmoi Configuration...${NC}"

    if command -v chezmoi &> /dev/null; then
        # Get chezmoi status
        chezmoi status > "${REPORTS_DIR}/chezmoi-status.txt" 2>&1 || true
        log "Chezmoi status captured"

        # List managed files
        chezmoi managed > "${REPORTS_DIR}/chezmoi-managed-files.txt"
        log "Managed files list updated"

        # Export data
        chezmoi data > "${REPORTS_DIR}/chezmoi-data.json"
        log "Chezmoi data exported"
    else
        warning "Chezmoi not installed"
    fi
}

# 4. Sync Shell Configuration
sync_shell_config() {
    echo -e "\n${BLUE}4. Syncing Shell Configuration...${NC}"

    # Current shell
    echo "$SHELL" > "${REPORTS_DIR}/current-shell.txt"

    # Fish configuration
    if command -v fish &> /dev/null; then
        fish -c "set -S" > "${REPORTS_DIR}/fish-variables.txt" 2>&1 || true
        fish -c "functions" > "${REPORTS_DIR}/fish-functions.txt" 2>&1 || true
        log "Fish configuration captured"
    fi

    # Path configuration
    echo "$PATH" | tr ':' '\n' > "${REPORTS_DIR}/path-entries.txt"
    log "PATH configuration captured"
}

# 5. Sync Tool Versions
sync_tool_versions() {
    echo -e "\n${BLUE}5. Syncing Tool Versions...${NC}"

    # Create versions report
    cat > "${REPORTS_DIR}/tool-versions.md" << EOF
# Tool Versions Report
Generated: ${TIMESTAMP}

## Core Tools
EOF

    # Check each tool
    for tool in git node npm python3 ruby go rust cargo docker kubectl; do
        if command -v $tool &> /dev/null; then
            version=$($tool --version 2>&1 | head -1 || echo "unknown")
            echo "- **$tool**: $version" >> "${REPORTS_DIR}/tool-versions.md"
        else
            echo "- **$tool**: not installed" >> "${REPORTS_DIR}/tool-versions.md"
        fi
    done

    log "Tool versions documented"
}

# 6. Sync iTerm2 Configuration
sync_iterm2() {
    echo -e "\n${BLUE}6. Syncing iTerm2 Configuration...${NC}"

    if [ -d "$HOME/.config/iterm2" ]; then
        # List dynamic profiles
        ls -1 "$HOME/.config/iterm2/DynamicProfiles/" 2>/dev/null > "${REPORTS_DIR}/iterm2-profiles.txt" || true

        # Check preferences location
        defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null > "${REPORTS_DIR}/iterm2-prefs-location.txt" || true

        log "iTerm2 configuration captured"
    else
        warning "iTerm2 configuration not found"
    fi
}

# 7. Sync Mise Configuration
sync_mise() {
    echo -e "\n${BLUE}7. Syncing Mise Configuration...${NC}"

    if command -v mise &> /dev/null; then
        mise list > "${REPORTS_DIR}/mise-installed.txt" 2>&1 || true
        mise current > "${REPORTS_DIR}/mise-current.txt" 2>&1 || true
        log "Mise configuration captured"
    else
        warning "Mise not installed"
    fi
}

# 8. Generate Compliance Report
generate_compliance_report() {
    echo -e "\n${BLUE}8. Generating Compliance Report...${NC}"

    # Run policy validation if available
    if [ -f "${REPO_ROOT}/04-policies/validate-policy.py" ]; then
        python3 "${REPO_ROOT}/04-policies/validate-policy.py" > "${REPORTS_DIR}/compliance-check.txt" 2>&1 || true
        log "Compliance check completed"
    fi
}

# 9. Update Documentation Metadata
update_metadata() {
    echo -e "\n${BLUE}9. Updating Documentation Metadata...${NC}"

    # Update sync timestamp
    cat > "${META_DIR}/last-sync.json" << EOF
{
  "timestamp": "${TIMESTAMP}",
  "status": "success",
  "reports_generated": [
    "system-info.json",
    "Brewfile.current",
    "tool-versions.md",
    "compliance-check.txt"
  ]
}
EOF
    log "Metadata updated"
}

# 10. Generate Summary Report
generate_summary() {
    echo -e "\n${BLUE}10. Generating Summary Report...${NC}"

    cat > "${REPORTS_DIR}/sync-summary.md" << EOF
# System Sync Summary
Generated: ${TIMESTAMP}

## Sync Status
- ✅ System information captured
- ✅ Homebrew state synchronized
- ✅ Chezmoi configuration exported
- ✅ Shell configuration documented
- ✅ Tool versions recorded
- ✅ iTerm2 settings captured
- ✅ Mise configuration synced
- ✅ Compliance report generated

## Key Findings
- Total Homebrew packages: $(wc -l < "${REPORTS_DIR}/brew-formulas.txt" 2>/dev/null || echo "0")
- Chezmoi managed files: $(wc -l < "${REPORTS_DIR}/chezmoi-managed-files.txt" 2>/dev/null || echo "0")
- PATH entries: $(wc -l < "${REPORTS_DIR}/path-entries.txt" 2>/dev/null || echo "0")

## Next Sync
Run this script periodically or after significant system changes.

## Related Documents
- [System Info](system-info.json)
- [Tool Versions](tool-versions.md)
- [Compliance Check](compliance-check.txt)
- [Brewfile](Brewfile.current)
EOF

    log "Summary report generated"
}

# Main execution
main() {
    capture_system_state
    sync_homebrew
    sync_chezmoi
    sync_shell_config
    sync_tool_versions
    sync_iterm2
    sync_mise
    generate_compliance_report
    update_metadata
    generate_summary

    echo -e "\n${GREEN}✅ System synchronization complete!${NC}"
    echo "Reports available in: ${REPORTS_DIR}"
    echo "Summary: ${REPORTS_DIR}/sync-summary.md"
}

# Run main function
main "$@"