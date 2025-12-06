---
title: 03 Iterm2
category: setup
component: 03_iterm2
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: [installation, setup]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: medium
---


# iTerm2 Complete Setup Guide

> **The macOS terminal emulator for the modern developer**
>
> iTerm2 3.6.2 with GPU acceleration, dynamic profiles, and intelligent features configured for maximum productivity on Apple Silicon.

## 🎯 Quick Setup

```bash
# Install iTerm2
brew install --cask iterm2

# Apply all configurations
~/.config/iterm2/apply-all-settings.sh

# Validate setup
./03-automation/scripts/validate-iterm2.sh
```

## ✅ Current Configuration Status

Based on latest validation (September 26, 2025):

| Category | Status | Details |
|----------|--------|---------|
| **Installation** | ✅ Complete | Version 3.6.2 |
| **GPU Acceleration** | ✅ Enabled | Metal renderer active |
| **Dynamic Profiles** | ✅ Active | 2 profiles loaded |
| **Features** | ✅ Configured | Navigator, timestamps, API |
| **Shell Integration** | ✅ Installed | Fish integrated |
| **Performance** | ✅ Optimized | All optimizations applied |

## 📋 Prerequisites

- ✅ macOS 14.0 or later
- ✅ Homebrew installed
- ✅ Admin access for preferences
- ✅ Fish or Zsh shell installed

## 🚀 Installation Steps

### Step 1: Install iTerm2

```bash
# Install via Homebrew
brew install --cask iterm2

# Or download directly
curl -L https://iterm2.com/downloads/stable/latest -o iTerm2.zip
unzip iTerm2.zip
mv iTerm.app /Applications/
```

### Step 2: Configure Preferences Location

```bash
# Create config directory
mkdir -p ~/.config/iterm2

# Set custom preferences folder
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2"
```

### Step 3: Apply Optimizations

```bash
# Run the complete configuration script
~/.config/iterm2/apply-all-settings.sh

# Or apply manually
defaults write com.googlecode.iterm2 UseMetal -bool true
defaults write com.googlecode.iterm2 OpenFileInNavigator -bool true
defaults write com.googlecode.iterm2 ShowTimestampsInTerminal -bool true
```

### Step 4: Install Shell Integration

```bash
# For Fish shell
curl -L https://iterm2.com/shell_integration/fish \
  -o ~/.iterm2_shell_integration.fish

# For Zsh
curl -L https://iterm2.com/shell_integration/zsh \
  -o ~/.iterm2_shell_integration.zsh

# For Bash
curl -L https://iterm2.com/shell_integration/bash \
  -o ~/.iterm2_shell_integration.bash
```

### Step 5: Set Up Dynamic Profiles

Dynamic profiles enable automatic context switching:

```bash
# Create profiles directory
mkdir -p ~/.config/iterm2/DynamicProfiles

# Profiles are automatically loaded from this directory
# See existing profiles:
ls ~/.config/iterm2/DynamicProfiles/
# - base.json: Foundation profile
# - development.json: Context-aware dev profiles
```

## 🎨 Dynamic Profile Configuration

### Profile Structure

Each profile can trigger based on:
- **Directory paths** - Auto-switch when entering specific directories
- **Hostnames** - Different profiles for SSH sessions
- **Custom rules** - Advanced pattern matching

### Current Profiles

| Profile | Trigger | Badge Color | Purpose |
|---------|---------|-------------|---------|
| **Base** | Default | None | Foundation settings |
| **Personal Dev** | `~/Development/personal/*` | Yellow | Personal projects |
| **Work Dev** | `~/Development/work/*` | Blue | Work projects |
| **Business Dev** | `~/Development/business/*` | Green | Business projects |
| **System Config** | `~/.local/share/chezmoi` | Purple | System management |

### Testing Profile Switching

```bash
# Test personal profile
cd ~/Development/personal
# Badge should turn yellow

# Test work profile
cd ~/Development/work
# Badge should turn blue

# Test system config profile
cd ~/.local/share/chezmoi
# Badge should turn purple
```

## ⚡ Performance Optimizations

### GPU Acceleration (M3 Max Optimized)

```bash
# Enable Metal rendering
defaults write com.googlecode.iterm2 UseMetal -bool true
defaults write com.googlecode.iterm2 GPURendererEnabled -bool true
defaults write com.googlecode.iterm2 AcceleratedDrawing -bool true

# Keep GPU active on battery
defaults write com.googlecode.iterm2 DisableMetalWhenUnplugged -bool false
```

### Memory and Scrollback

```bash
# Optimize scrollback
defaults write com.googlecode.iterm2 ScrollbackLines -int 10000
defaults write com.googlecode.iterm2 ScrollbackWithStatusBar -bool true

# Reduce memory usage
defaults write com.googlecode.iterm2 ReduceFlicker -bool true
```

## ✨ Power Features

### 1. Navigator (Click to Open)

Click any file path to open in your editor:
```bash
# Enable Navigator
defaults write com.googlecode.iterm2 OpenFileInNavigator -bool true

# Test: Click this path
# ~/Development/personal/project/file.js:42
```

### 2. Timestamps

Show when commands were executed:
```bash
# Enable timestamps
defaults write com.googlecode.iterm2 ShowTimestampsInTerminal -bool true

# Toggle with: View → Show Timestamps
```

### 3. API Server

Enable automation and scripting:
```bash
# Enable API
defaults write com.googlecode.iterm2 EnableAPIServer -bool true

# Python API example
import iterm2
async with iterm2.Connection():
    app = await iterm2.async_get_app()
```

### 4. Semantic History

Smart recognition of paths, URLs, and commands:
```bash
# Enable semantic history
defaults write com.googlecode.iterm2 EnableSemanticHistory -bool true

# Cmd+Click recognizes:
# - File paths
# - URLs
# - Git commits
# - IP addresses
```

## 🎨 Visual Customization

### Themes

```bash
# Popular themes to install
# Dracula
curl -o ~/Downloads/Dracula.itermcolors \
  https://raw.githubusercontent.com/dracula/iterm/master/Dracula.itermcolors

# One Dark
curl -o ~/Downloads/OneDark.itermcolors \
  https://raw.githubusercontent.com/one-dark/iterm-one-dark-theme/master/One%20Dark.itermcolors
```

### Fonts

```bash
# Install programming fonts
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font
brew install --cask font-cascadia-code-nerd-font
```

## 🔧 Troubleshooting

### Issue: Settings not persisting
```bash
# Fix preferences location
~/.config/iterm2/fix-iterm-prefs.sh
```

### Issue: GPU rendering not working
```bash
# Re-enable GPU settings
defaults write com.googlecode.iterm2 UseMetal -bool true
# Restart iTerm2
```

### Issue: Profile switching not working
```bash
# Reload dynamic profiles
defaults write com.googlecode.iterm2 LoadDynamicProfiles -bool true
# Check profile syntax
python3 -m json.tool ~/.config/iterm2/DynamicProfiles/*.json
```

### Issue: Slow startup
```bash
# Reduce startup items
defaults write com.googlecode.iterm2 OpenNoWindowsAtStartup -bool true
# Clear preferences cache
rm ~/Library/Preferences/com.googlecode.iterm2.plist.lockfile
```

## 📊 Validation

### Quick Check
```bash
# Run validation script
./03-automation/scripts/validate-iterm2.sh
```

### Manual Verification
```bash
# Check all settings
~/.config/iterm2/verify-config.sh

# Test specific features
~/.config/iterm2/test-profiles.sh
```

### Expected Results
- ✅ 20+ successful checks
- ✅ GPU acceleration active
- ✅ Dynamic profiles loaded
- ✅ All features enabled

## 🔗 Configuration Files

All iTerm2 configuration files are located in:

```
~/.config/iterm2/
├── com.googlecode.iterm2.plist    # Main preferences
├── DynamicProfiles/                # Profile definitions
│   ├── base.json                   # Base profile
│   └── development.json            # Dev profiles
├── apply-all-settings.sh           # Apply all settings
├── verify-config.sh                # Verify configuration
├── fix-iterm-prefs.sh             # Fix preference issues
└── test-profiles.sh               # Test profile switching
```

## 📚 Additional Resources

### Documentation
- [iTerm2 Documentation](https://iterm2.com/documentation.html)
- [iTerm2 Shell Integration](https://iterm2.com/documentation-shell-integration.html)
- [iTerm2 Python API](https://iterm2.com/python-api/)
- [Dynamic Profiles](https://iterm2.com/documentation-dynamic-profiles.html)

### Related Guides
- [Fish Shell Setup](03-fish-shell.md)
- [Terminal Productivity Guide](~/00_inbox/iterm2-dx-guide.md)
- [Manual GUI Settings](~/00_inbox/iterm2-manual-settings.md)

## 🎯 Final Checklist

- [ ] iTerm2 installed via Homebrew
- [ ] Custom preferences folder configured
- [ ] All settings applied via script
- [ ] Shell integration installed
- [ ] Dynamic profiles loaded
- [ ] GPU acceleration enabled
- [ ] Features configured (Navigator, timestamps, etc.)
- [ ] Validation passes all checks
- [ ] Profile switching tested
- [ ] Restart completed

Once all items are checked, your iTerm2 is fully configured and optimized for development on Apple Silicon!