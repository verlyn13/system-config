#!/usr/bin/env bash
# Apply macOS optimizations without sudo (where possible)
set -euo pipefail

echo "🚀 Applying System Optimizations (non-sudo parts)..."

# macOS Settings that don't require sudo
echo "⚙️ Configuring user-level macOS settings..."

# Disable press-and-hold for keys (enable key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Finder optimizations
defaults write com.apple.finder DisableAllAnimations -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Terminal optimizations
defaults write com.apple.terminal StringEncodings -array 4

# Safari developer mode
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# Screenshots location
mkdir -p ~/Screenshots
defaults write com.apple.screencapture location ~/Screenshots

# Disable screenshot shadows
defaults write com.apple.screencapture disable-shadow -bool true

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

# Restart affected apps
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "✅ User-level optimizations complete!"
echo ""
echo "📋 Optimizations requiring sudo (run manually if needed):"
echo ""
echo "# Spotlight exclusions:"
echo "sudo mdutil -i off ~/Development"
echo "sudo mdutil -i off ~/.gradle"
echo "sudo mdutil -i off ~/Library/Android"
echo ""
echo "# Time Machine exclusions:"
echo "sudo tmutil addexclusion -p ~/Development"
echo "sudo tmutil addexclusion -p ~/.gradle"
echo "sudo tmutil addexclusion -p ~/Library/Android/sdk"
echo ""
echo "# Enable Touch ID for sudo:"
echo "sudo bash -c 'echo \"auth sufficient pam_tid.so\" > /etc/pam.d/sudo_local'"
echo ""
echo "# High Power Mode (M3 Max):"
echo "sudo pmset -a highpowermode 1"
echo ""
echo "✅ Phase 10 partially complete - run sudo commands above to finish"