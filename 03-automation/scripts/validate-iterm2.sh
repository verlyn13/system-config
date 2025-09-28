#!/bin/bash

# Comprehensive iTerm2 Configuration Validator
# Version: 2.0.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}${BLUE}🔍 iTerm2 Complete Configuration Validation${NC}"
echo "================================================"
echo ""

ISSUES=0
WARNINGS=0
SUCCESSES=0

# Function to check a setting
check_setting() {
    local setting_name="$1"
    local setting_key="$2"
    local expected_value="$3"
    local description="$4"

    actual_value=$(defaults read com.googlecode.iterm2 "$setting_key" 2>/dev/null || echo "not set")

    if [[ "$actual_value" == "$expected_value" ]]; then
        echo -e "  ${GREEN}✅ $setting_name: $description${NC}"
        ((SUCCESSES++))
    elif [[ "$actual_value" == "not set" ]]; then
        echo -e "  ${YELLOW}⚠️  $setting_name: Not configured (should be $expected_value)${NC}"
        ((WARNINGS++))
    else
        echo -e "  ${RED}❌ $setting_name: $actual_value (expected $expected_value)${NC}"
        ((ISSUES++))
    fi
}

# 1. Check Installation and Version
echo -e "${CYAN}📦 Installation & Version${NC}"
if command -v /Applications/iTerm.app/Contents/MacOS/iTerm2 &> /dev/null; then
    version=$(defaults read /Applications/iTerm.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✅ iTerm2 installed: Version $version${NC}"
    ((SUCCESSES++))
else
    echo -e "  ${RED}❌ iTerm2 not found in /Applications${NC}"
    ((ISSUES++))
fi

# 2. Check Preferences Location
echo -e "\n${CYAN}📁 Preferences Configuration${NC}"
prefs_folder=$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null || echo "not set")
load_from_custom=$(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null || echo "0")

if [[ "$prefs_folder" == "/Users/verlyn13/.config/iterm2" ]] && [[ "$load_from_custom" == "1" ]]; then
    echo -e "  ${GREEN}✅ Custom preferences: $prefs_folder${NC}"
    ((SUCCESSES++))
else
    echo -e "  ${RED}❌ Preferences not using custom folder${NC}"
    echo -e "     Current: $prefs_folder (Load: $load_from_custom)"
    ((ISSUES++))
fi

# 3. Check GPU Settings
echo -e "\n${CYAN}⚡ GPU & Performance${NC}"
check_setting "Metal Renderer" "UseMetal" "1" "GPU acceleration enabled"
check_setting "GPU Renderer" "GPURendererEnabled" "1" "GPU renderer active"
check_setting "Accelerated Drawing" "AcceleratedDrawing" "1" "Hardware acceleration"
check_setting "Disable When Unplugged" "DisableMetalWhenUnplugged" "0" "Keep GPU on battery"
check_setting "Reduce Flicker" "ReduceFlicker" "1" "Flicker reduction enabled"

# 4. Check Dynamic Profiles
echo -e "\n${CYAN}🎨 Dynamic Profiles${NC}"
profile_dir="$HOME/.config/iterm2/DynamicProfiles"
if [ -d "$profile_dir" ]; then
    profile_count=$(ls "$profile_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')
    if [ "$profile_count" -gt 0 ]; then
        echo -e "  ${GREEN}✅ Dynamic profiles: $profile_count profiles loaded${NC}"
        for profile in "$profile_dir"/*.json; do
            profile_name=$(basename "$profile" .json)
            if python3 -m json.tool "$profile" > /dev/null 2>&1; then
                echo -e "    ${GREEN}✓ $profile_name: Valid JSON${NC}"
            else
                echo -e "    ${RED}✗ $profile_name: Invalid JSON${NC}"
                ((ISSUES++))
            fi
        done
        ((SUCCESSES++))
    else
        echo -e "  ${YELLOW}⚠️  No dynamic profiles found${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "  ${RED}❌ Dynamic profiles directory not found${NC}"
    ((ISSUES++))
fi

# 5. Check Features
echo -e "\n${CYAN}✨ Features${NC}"
check_setting "Navigator (Click to Open)" "OpenFileInNavigator" "1" "Click paths to open files"
check_setting "Timestamps" "ShowTimestampsInTerminal" "1" "Show timestamps"
check_setting "API Server" "EnableAPIServer" "1" "Enable automation API"
check_setting "Semantic History" "EnableSemanticHistory" "1" "Smart text recognition"
check_setting "Profile Switching" "AutomaticProfileSwitching" "1" "Auto-switch profiles"

# 6. Check Shell Integration
echo -e "\n${CYAN}🐚 Shell Integration${NC}"
if [ -f "$HOME/.iterm2_shell_integration.fish" ]; then
    echo -e "  ${GREEN}✅ Fish shell integration: Installed${NC}"
    ((SUCCESSES++))
else
    echo -e "  ${YELLOW}⚠️  Fish shell integration: Not found${NC}"
    ((WARNINGS++))
fi

if [ -f "$HOME/.iterm2_shell_integration.zsh" ]; then
    echo -e "  ${GREEN}✅ Zsh shell integration: Installed${NC}"
    ((SUCCESSES++))
else
    echo -e "  ${BLUE}ℹ️  Zsh shell integration: Not installed (optional)${NC}"
fi

# 7. Check Window Settings
echo -e "\n${CYAN}🪟 Window Management${NC}"
check_setting "Restore Windows" "RestoreWindowContents" "1" "Restore tabs on startup"
check_setting "Quit When Closed" "QuitWhenAllWindowsClosed" "0" "Keep app running"
check_setting "Full Screen Tab Bar" "ShowFullScreenTabBar" "1" "Show tabs in fullscreen"

# 8. Check Key Bindings and Mouse
echo -e "\n${CYAN}⌨️  Input Configuration${NC}"
check_setting "Three Finger Middle" "ThreeFingerEmulatesMiddle" "1" "Three-finger paste"
check_setting "Triple Click" "TripleClickSelectsFullWrappedLines" "1" "Select wrapped lines"
check_setting "Focus Follows Mouse" "FocusFollowsMouse" "0" "Keep focus stable"

# 9. Test Profile Switching
echo -e "\n${CYAN}🔄 Profile Switching Test${NC}"
echo -e "  ${BLUE}ℹ️  To test profile switching:${NC}"
echo -e "     1. Open a new iTerm2 tab"
echo -e "     2. Run: ${BOLD}cd ~/Development/personal${NC} (should show Personal profile)"
echo -e "     3. Run: ${BOLD}cd ~/Development/work${NC} (should show Work profile)"
echo -e "     4. Run: ${BOLD}cd ~/.local/share/chezmoi${NC} (should show System Config profile)"

# 10. Summary
echo -e "\n${BOLD}${BLUE}📊 Validation Summary${NC}"
echo "================================================"
echo -e "${GREEN}✅ Successes: $SUCCESSES${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "${RED}❌ Issues: $ISSUES${NC}"

if [ $ISSUES -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "\n${GREEN}${BOLD}🎉 iTerm2 is fully configured and optimized!${NC}"
        exit_code=0
    else
        echo -e "\n${YELLOW}${BOLD}⚠️  iTerm2 is configured with minor warnings${NC}"
        echo -e "Run ${BOLD}~/.config/iterm2/apply-all-settings.sh${NC} to fix warnings"
        exit_code=0
    fi
else
    echo -e "\n${RED}${BOLD}❌ iTerm2 configuration has issues${NC}"
    echo -e "Run ${BOLD}~/.config/iterm2/apply-all-settings.sh${NC} then restart iTerm2"
    exit_code=1
fi

# Save report
report_file="$HOME/Development/personal/system-setup-update/07-reports/status/iterm2-validation.txt"
mkdir -p "$(dirname "$report_file")"
{
    echo "iTerm2 Validation Report"
    echo "Generated: $(date)"
    echo "========================"
    echo "Successes: $SUCCESSES"
    echo "Warnings: $WARNINGS"
    echo "Issues: $ISSUES"
    echo ""
    echo "Run this script again after restarting iTerm2 to verify changes."
} > "$report_file"

echo -e "\n💾 Report saved to: ${BLUE}$report_file${NC}"

exit $exit_code