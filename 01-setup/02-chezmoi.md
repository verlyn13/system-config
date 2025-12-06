---
title: 02 Chezmoi
category: setup
component: 02_chezmoi
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


# Chezmoi Dotfiles Management

> **Manage your dotfiles across multiple diverse machines, securely**
>
> Chezmoi provides a single source of truth for system configuration with templating, machine-specific customization, and security features.

## 🎯 Quick Setup

```bash
# Install chezmoi
brew install chezmoi

# Initialize with your dotfiles repo
chezmoi init --apply verlyn13/dotfiles
```

## 📋 Prerequisites

- ✅ Homebrew installed (`brew --version`)
- ✅ Git configured with GitHub access
- ✅ SSH keys set up for GitHub

## 🚀 Installation Steps

### Step 1: Install Chezmoi

```bash
# Install via Homebrew
brew install chezmoi

# Verify installation
chezmoi --version
```

### Step 2: Initialize Dotfiles

#### Option A: From Existing Repository
```bash
# Initialize and apply in one step
chezmoi init --apply git@github.com:verlyn13/dotfiles.git

# Or step by step
chezmoi init git@github.com:verlyn13/dotfiles.git
chezmoi diff  # Review changes
chezmoi apply # Apply changes
```

#### Option B: Start Fresh
```bash
# Create new dotfiles repo
chezmoi init

# Add your first dotfile
chezmoi add ~/.gitconfig

# Commit and push
chezmoi cd
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:USERNAME/dotfiles.git
git push -u origin main
```

### Step 3: Configure Machine-Specific Data

Edit `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    # User information
    name = "Your Name"
    email = "your.email@example.com"

    # Machine configuration
    hostname = "your-machine"
    is_personal = true
    is_work = false

    # Development setup
    shell = "fish"  # or "zsh", "bash"
    editor = "code" # or "nvim", "subl"

    # Features
    android = false
    docker = true
    kubernetes = false

    # Server configuration (optional)
    has_hetzner = false
    hetzner_hosts = []
```

## 📁 Directory Structure

```
~/.local/share/chezmoi/         # Source directory (git repo)
├── .chezmoi.toml.tmpl          # Machine-specific prompts
├── .chezmoidata.toml           # Shared data/variables
├── .chezmoitemplates/          # Reusable templates
├── dot_config/                 # ~/.config files
│   ├── fish/
│   ├── iterm2/
│   └── mise/
├── dot_ssh/                    # SSH configuration
├── run_once_*.sh.tmpl          # One-time setup scripts
└── workspace/                  # ~/workspace files
    └── dotfiles/
        ├── Brewfile            # Homebrew packages
        └── Brewfile.gui        # GUI applications
```

## 🎨 Templating

### Basic Templates

Use Go templates for machine-specific configuration:

```bash
# ~/.gitconfig template (dot_gitconfig.tmpl)
[user]
    name = {{ .name | quote }}
    email = {{ .email | quote }}

{{ if .is_work -}}
[http]
    proxy = http://proxy.company.com:8080
{{- end }}
```

### Conditional Files

Control file presence based on machine:

```bash
# Only on personal machines
{{- if .is_personal }}
[alias]
    personal = "!git config user.email personal@email.com"
{{- end }}
```

### File Permissions

Set executable permissions:
```bash
# run_once_install-tools.sh.tmpl
# chezmoi will make this executable

#!/bin/bash
echo "Installing development tools..."
```

## 🔧 Common Operations

### Adding Files

```bash
# Add a single file
chezmoi add ~/.vimrc

# Add a directory
chezmoi add ~/.config/fish

# Add with templating
chezmoi add --template ~/.gitconfig
```

### Updating Files

```bash
# Edit source file directly
chezmoi edit ~/.gitconfig

# Edit and apply
chezmoi edit --apply ~/.gitconfig

# Pull latest from repo and apply
chezmoi update
```

### Comparing Changes

```bash
# See what would change
chezmoi diff

# See diff for specific file
chezmoi diff ~/.gitconfig

# Verbose diff with colors
chezmoi diff --color=true --pager="less -R"
```

### Managing Secrets

```bash
# Use 1Password integration
{{ onepasswordRead "op://Personal/GitHub Token/token" }}

# Use encrypted files
chezmoi add --encrypt ~/.ssh/config

# Configure encryption
chezmoi config encryption "age"
```

## ⚙️ Advanced Configuration

### Run-Once Scripts

Create `run_once_` scripts for initial setup:

```bash
# run_once_01-install-packages.sh.tmpl
#!/bin/bash
set -euo pipefail

echo "📦 Installing Homebrew packages..."
brew bundle --file={{ .chezmoi.sourceDir }}/workspace/dotfiles/Brewfile
```

### External Files

Fetch files from URLs:

```toml
# .chezmoiexternal.toml
[".config/starship.toml"]
    type = "file"
    url = "https://raw.githubusercontent.com/starship/starship/master/docs/.vuepress/public/presets/toml/nerd-font.toml"
    refreshPeriod = "168h"
```

### Git Hooks

Set up automation:

```bash
# .git/hooks/pre-push
#!/bin/bash
chezmoi verify
```

## 🔐 Security Best Practices

1. **Never commit secrets directly**
   ```bash
   # Bad
   API_KEY=secret123

   # Good
   API_KEY={{ onepasswordRead "op://vault/item/field" }}
   ```

2. **Use `.chezmoiignore` for sensitive paths**
   ```
   .ssh/id_*
   .aws/credentials
   .env
   ```

3. **Encrypt sensitive files**
   ```bash
   chezmoi add --encrypt ~/.ssh/config
   ```

4. **Verify templates before applying**
   ```bash
   chezmoi diff
   chezmoi apply --dry-run
   ```

## 🚄 Performance Tips

1. **Use `run_once_` scripts** - Avoid re-running expensive operations
2. **Leverage `.chezmoiignore`** - Skip unnecessary files
3. **External files with caching** - Set appropriate `refreshPeriod`
4. **Batch operations** - Use `chezmoi apply` instead of individual files

## 📊 Validation

```bash
# Check chezmoi health
chezmoi doctor

# Verify configuration
chezmoi verify

# Check managed files
chezmoi managed

# Full system validation
python3 ~/Development/personal/system-setup-update/03-automation/scripts/validate-system.py
```

## 🔧 Troubleshooting

### Issue: "chezmoi: command not found"
```bash
# Reinstall via Homebrew
brew reinstall chezmoi
```

### Issue: Template parsing errors
```bash
# Debug template
chezmoi execute-template < ~/.local/share/chezmoi/dot_gitconfig.tmpl
```

### Issue: Merge conflicts
```bash
# Resolve in source directory
chezmoi cd
git status
# Fix conflicts
git add .
git commit
chezmoi apply
```

### Issue: Wrong file permissions
```bash
# Fix permissions in source
chezmoi edit ~/.ssh/config
# Add at top of file:
# {{- /* vim: set filetype=sshconfig: */ -}}
# {{ if (eq .chezmoi.os "darwin") -}}
# <!-- File permission will be 600 -->
# {{- end }}
```

## 🔗 Related Documentation

- [Template Examples](../06-templates/chezmoi/README.md)
- [Fish Shell Setup](03-fish-shell.md)
- [SSH Configuration](../02-configuration/tools/ssh-multi-account.md)

## 📚 References

- [Chezmoi Documentation](https://www.chezmoi.io)
- [Template Guide](https://www.chezmoi.io/user-guide/templating/)
- [Best Practices](https://www.chezmoi.io/user-guide/best-practices/)
- [FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/)