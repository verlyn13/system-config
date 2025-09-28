#!/usr/bin/env bash
# iTerm2 3.6.2 Setup and Configuration
set -euo pipefail

echo "🖥️ iTerm2 3.6.2 Configuration Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check current version
echo -e "\n${YELLOW}Step 1: Checking current iTerm2 version...${NC}"
CURRENT_VERSION=$(plutil -extract CFBundleShortVersionString raw /Applications/iTerm.app/Contents/Info.plist 2>/dev/null || echo "Not installed")
echo "Current version: $CURRENT_VERSION"

# 2. Update iTerm2 if needed
if [[ "$CURRENT_VERSION" != "3.6.2" ]]; then
    echo -e "\n${YELLOW}Step 2: Updating iTerm2 to 3.6.2...${NC}"
    echo "Run: brew upgrade --cask iterm2"
    echo -e "${RED}Note: Please close iTerm2 before upgrading${NC}"
    read -p "Press Enter when ready to continue..."
    brew upgrade --cask iterm2
else
    echo -e "${GREEN}✓ iTerm2 3.6.2 already installed${NC}"
fi

# 3. Create preferences directory
echo -e "\n${YELLOW}Step 3: Setting up preferences directory...${NC}"
mkdir -p ~/.config/iterm2

# 4. Configure iTerm2 to use custom preferences folder
echo -e "\n${YELLOW}Step 4: Configuring preferences location...${NC}"
echo "Manual steps required in iTerm2:"
echo "1. Open iTerm2 > Settings (⌘,)"
echo "2. Go to General > Preferences"
echo "3. Check 'Load preferences from a custom folder'"
echo "4. Set path to: ~/.config/iterm2"
echo "5. Check 'Save changes automatically'"
echo ""
read -p "Press Enter after completing these steps..."

# 5. Create chezmoi template for iTerm2 preferences
echo -e "\n${YELLOW}Step 5: Creating chezmoi template...${NC}"
cat > ~/.local/share/chezmoi/dot_config/iterm2/.gitignore << 'EOF'
# iTerm2 generated files
AppSupport
sockets/
*.plist.bak
EOF

# 6. Export current profile
echo -e "\n${YELLOW}Step 6: Exporting current profile...${NC}"
echo "Manual steps:"
echo "1. Open iTerm2 > Settings > Profiles"
echo "2. Select your profile and click 'Other Actions' (gear icon)"
echo "3. Export > Export JSON"
echo "4. Save as: ~/.config/iterm2/profiles.json"
echo ""
read -p "Press Enter after exporting profile..."

# 7. Apply recommended settings
echo -e "\n${YELLOW}Step 7: Recommended iTerm2 3.6.2 Settings${NC}"
echo ""
echo "Apply these settings in iTerm2 > Settings:"
echo ""
echo -e "${GREEN}Navigation & Paths:${NC}"
echo "  ✓ Profiles > Terminal > 'Click on a path' → Open Navigator"
echo ""
echo -e "${GREEN}Visual Enhancements:${NC}"
echo "  ✓ Profiles > Text > Hide cursor when focus is lost"
echo "  ✓ Appearance > General > Show timestamps → Relative"
echo ""
echo -e "${GREEN}Key Bindings:${NC}"
echo "  ✓ Profiles > Keys > Disable 'Perform remapping globally'"
echo "  ✓ Profiles > Keys > Enable 'Respect system shortcuts'"
echo "  ✓ Add: ⌘⇧[ → Copy Mode"
echo "  ✓ Add: ⌘⌥⇧N → Move Tab to New Window"
echo ""
echo -e "${GREEN}AI Assistant (if using):${NC}"
echo "  ✓ Settings > AI > Model → Recommended Model"
echo "  ✓ Settings > AI > Require confirmation before shell execution"
echo ""
echo -e "${GREEN}Performance & Media:${NC}"
echo "  ✓ Advanced > Images > Allow Kitty shared memory"
echo ""
read -p "Press Enter after applying settings..."

# 8. Create validation script
echo -e "\n${YELLOW}Step 8: Creating validation script...${NC}"
cat > ~/.config/iterm2/validate.sh << 'EOF'
#!/usr/bin/env bash
# iTerm2 3.6.2 Validation

echo "iTerm2 3.6.2 Validation Checklist"
echo "=================================="

# Check version
VERSION=$(plutil -extract CFBundleShortVersionString raw /Applications/iTerm.app/Contents/Info.plist 2>/dev/null)
if [[ "$VERSION" == "3.6.2" ]]; then
    echo "✅ Version: $VERSION"
else
    echo "❌ Version: $VERSION (expected 3.6.2)"
fi

# Check preferences location
if [[ -f ~/.config/iterm2/com.googlecode.iterm2.plist ]]; then
    echo "✅ Custom preferences folder configured"
else
    echo "⚠️  Preferences not in custom folder"
fi

# Check profile export
if [[ -f ~/.config/iterm2/profiles.json ]]; then
    echo "✅ Profile exported"
else
    echo "❌ Profile not exported"
fi

echo ""
echo "Manual Verification:"
echo "1. Open Settings search and try 'baseline' or 'kitty'"
echo "2. Run Shell > Log > Start (should default to ~/Library/Logs)"
echo "3. Save an arrangement (name should include date)"
echo "4. Test Navigator: click on a file path in terminal"
EOF
chmod +x ~/.config/iterm2/validate.sh

# 9. Add to chezmoi
echo -e "\n${YELLOW}Step 9: Adding to chezmoi...${NC}"
if [[ -f ~/.config/iterm2/profiles.json ]]; then
    cp ~/.config/iterm2/profiles.json ~/.local/share/chezmoi/dot_config/iterm2/
    echo "Profile copied to chezmoi"
fi

# 10. Run validation
echo -e "\n${YELLOW}Step 10: Running validation...${NC}"
~/.config/iterm2/validate.sh

echo -e "\n${GREEN}✅ iTerm2 3.6.2 setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Test the new Navigator feature by clicking on paths"
echo "2. Try the AI assistant if you have an API key configured"
echo "3. Verify relative timestamps are working"
echo "4. Save a window arrangement to test date inclusion"
echo ""
echo "Documentation: ~/Development/personal/system-setup-update/iterm2-config.md"