---
title: Homebrew Installation and Configuration
category: setup
component: homebrew
status: active
version: 2.0.0
last_updated: 2025-09-26
dependencies:
  - doc: 01-setup/00-prerequisites.md
    type: required
tags: [installation, setup, package-manager, core]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: critical
---

# Homebrew Installation and Configuration

> **The missing package manager for macOS**
>
> Homebrew is the foundation for all development tools on macOS. This guide ensures proper installation and optimization for Apple Silicon.

## 🎯 Quick Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 📋 Prerequisites

- ✅ macOS 14.0 or later
- ✅ Xcode Command Line Tools installed
- ✅ Admin access (for `/opt/homebrew` on Apple Silicon)
- ✅ Internet connection

## 🚀 Installation Steps

### Step 1: Install Homebrew

```bash
# Install Homebrew (Apple Silicon optimized)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Configure Shell (Apple Silicon)

For Apple Silicon Macs, Homebrew installs to `/opt/homebrew` instead of `/usr/local`:

#### Fish Shell
```fish
# Add to ~/.config/fish/config.fish
fish_add_path /opt/homebrew/bin
set -gx HOMEBREW_PREFIX /opt/homebrew
```

#### Zsh
```bash
# Add to ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"
```

#### Bash
```bash
# Add to ~/.bash_profile or ~/.bashrc
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Step 3: Verify Installation

```bash
# Check Homebrew installation
brew --version

# Run diagnostics
brew doctor

# Update Homebrew
brew update
```

## 📦 Essential Packages

### Core Development Tools

```bash
# Version control
brew install git gh

# Shell and terminal
brew install fish starship zellij

# Modern CLI tools (replacements)
brew install eza bat ripgrep fd fzf

# Development utilities
brew install direnv jq yq watchman

# Language version management
brew install mise

# Security
brew install gnupg pinentry-mac
```

### GUI Applications (Casks)

```bash
# Terminals
brew install --cask iterm2

# Editors and IDEs
brew install --cask visual-studio-code sublime-text

# Development tools
brew install --cask docker orbstack

# Browsers
brew install --cask arc firefox google-chrome

# Productivity
brew install --cask raycast 1password notion
```

## ⚙️ Configuration

### Global Settings

```bash
# Disable analytics (privacy)
brew analytics off

# Enable auto-update (optional)
brew autoupdate start --upgrade --cleanup --enable-notification

# Set cleanup preferences
export HOMEBREW_NO_INSTALL_CLEANUP=1  # Keep old versions
```

### Brewfile Management

Create a `Brewfile` to track all packages:

```bash
# Generate Brewfile from current installation
brew bundle dump --file=~/workspace/dotfiles/Brewfile --describe

# Install from Brewfile
brew bundle --file=~/workspace/dotfiles/Brewfile
```

Example Brewfile structure:
```ruby
# Taps
tap "homebrew/bundle"
tap "homebrew/services"

# CLI tools
brew "git"
brew "fish"
brew "mise"

# GUI applications
cask "iterm2"
cask "visual-studio-code"

# Mac App Store apps (requires mas)
brew "mas"
mas "Xcode", id: 497799835
```

## 🔧 Troubleshooting

### Common Issues

#### Issue: "brew: command not found" on Apple Silicon
```bash
# Add Homebrew to PATH manually
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

#### Issue: Permission errors
```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) $(brew --prefix)/*
```

#### Issue: Outdated packages
```bash
# Update everything
brew update && brew upgrade && brew cleanup
```

#### Issue: "Homebrew is not installed" in scripts
```bash
# Ensure Homebrew is in PATH for scripts
export PATH="/opt/homebrew/bin:$PATH"
```

## 🚄 Performance Optimization

### For Apple Silicon (M1/M2/M3)

```bash
# Enable parallel downloads
export HOMEBREW_PARALLEL_DOWNLOAD=1

# Use faster mirrors (China example)
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles

# Disable quarantine for casks (faster installs)
export HOMEBREW_CASK_OPTS="--no-quarantine"
```

### Maintenance Commands

```bash
# Weekly maintenance
brew update && brew upgrade && brew cleanup && brew doctor

# Check for problems
brew doctor

# Remove old versions
brew cleanup --prune=30  # Remove items older than 30 days

# List installed packages by size
brew list --formula | xargs -n1 -P8 -I {} sh -c "brew info {} | awk '/^==> Caveats/,/^[[:space:]]*$/' | grep -v '^==>' | grep -v '^$' | wc -c | xargs printf '%s\t' && echo {}" | sort -rn
```

## 🔐 Security Considerations

1. **Verify Downloads**: Homebrew verifies SHA256 checksums
2. **Review Formulas**: Check formula source before installing
3. **Regular Updates**: Keep Homebrew and packages updated
4. **Audit Packages**: `brew audit --strict` for security checks

## 📊 Validation

Run validation to ensure proper setup:

```bash
# Quick validation
brew doctor && echo "✅ Homebrew is healthy"

# Full validation
python3 ~/Development/personal/system-setup-update/03-automation/scripts/validate-system.py
```

## 🔗 Related Documentation

- [Prerequisites](00-prerequisites.md) - System requirements
- [Chezmoi Setup](02-chezmoi.md) - Dotfiles management
- [Shell Configuration](03-fish-shell.md) - Fish shell setup
- [Mise Setup](04-mise.md) - Version management

## 📚 References

- [Official Homebrew Documentation](https://docs.brew.sh)
- [Homebrew on Apple Silicon](https://docs.brew.sh/Installation#macos-requirements)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [Formulae Browser](https://formulae.brew.sh)