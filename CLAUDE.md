---
title: AI Assistant Context
category: reference
component: ai-context
status: active
version: 1.0.0
last_updated: 2025-09-26
tags: []
priority: medium
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains configuration documentation and templates for setting up a reproducible macOS development environment using chezmoi, Homebrew, Fish shell, and mise. It implements a phased approach to system configuration with emphasis on modularity and machine-specific customization.

## Key Architecture

### Documentation Structure
- **mac-dev-env-setup.md**: Main setup guide with 10 implementation phases
- **implementation-status.md**: Current state tracking (Phases 0-3 complete, 4 partial, 5-10 pending)
- **chezmoi-templates.md**: Template structure and examples for dotfiles management

### Chezmoi Configuration Architecture
The system uses chezmoi for dotfile management with this critical structure:
- **Source**: `~/.local/share/chezmoi/` - Template files and run_once scripts
- **Data**: `~/.config/chezmoi/chezmoi.toml` - Machine-specific values (NOT `.chezmoidata.toml`)
- **Templates**: Use Go template syntax with guards like `(.headless | default false)`

### Critical File Locations
```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl          # Prompts for machine-specific data
├── run_once_*.sh.tmpl          # One-time setup scripts
├── dot_config/                 # Fish, mise configs
└── workspace/
    ├── dotfiles/               # Brewfiles and templates
    └── scripts/                # Helper scripts
```

## Common Commands

### Apply Configuration Changes
```bash
# Apply chezmoi changes (use after modifying templates)
chezmoi apply

# Dry run to preview changes
chezmoi apply --dry-run

# Regenerate config to eliminate template warnings
chezmoi init --apply
```

### Fix Common Issues
```bash
# If Claude CLI not found after setup
fish -c 'echo $PATH | tr " " "\n" | grep npm'  # Check if npm-global is in PATH

# Complete GUI app installation if timed out
cd ~/.local/share/chezmoi/workspace/dotfiles
brew bundle --file=Brewfile.gui

# Install mise-managed language tools
mise install
```

### Testing Configuration
```bash
# Test Fish shell configuration
fish -c 'claude --version'  # Should return version if PATH is correct

# Check chezmoi status
chezmoi status

# Verify mise configuration
mise doctor
```

## Template Syntax Requirements

### Chezmoi Templates Must Use Proper Guards
When accessing data values that might not exist:
```go
// CORRECT - Use defaults to prevent "map has no entry" errors
{{ if not (.headless | default false) -}}
{{ if eq (.shell | default "fish") "fish" -}}

// INCORRECT - Will fail if key doesn't exist
{{ if not .headless -}}
{{ if eq .shell "fish" -}}
```

### Required Data Keys in chezmoi.toml
The following keys must exist in `~/.config/chezmoi/chezmoi.toml`:
- `headless` (bool): Whether this is a headless server
- `android` (bool): Whether to install Android development tools
- `shell` (string): Default shell choice (usually "fish")

## Phase Implementation Status

Currently tracking 10 phases of setup:
- **Phase 0-3**: ✅ Complete (Foundation, Homebrew, Dotfiles, Fish)
- **Phase 4**: ⏸️ Partial (mise version management)
- **Phase 5-10**: ❌ Not started (Security, Containers, Android, Bootstrap, Templates, Optimization)

## Known Issues and Solutions

### PATH Configuration
If tools aren't accessible after setup, ensure `~/.config/fish/conf.d/04-paths.fish` exists with:
```fish
fish_add_path ~/.npm-global/bin
fish_add_path ~/bin
fish_add_path ~/.local/bin
```

### Template Errors
If you see "map has no entry for key" errors:
1. Add missing keys to `~/.config/chezmoi/chezmoi.toml`
2. Update templates to use `| default` guards
3. Run `chezmoi apply` again

### Homebrew Bundle Timeouts
GUI applications can timeout during installation. Continue with:
```bash
cd ~/.local/share/chezmoi/workspace/dotfiles
brew bundle --file=Brewfile.gui
```

## Project Initialization

Use the provided script to bootstrap new projects:
```bash
~/.local/share/chezmoi/workspace/scripts/init-project.sh [project-path]
```

This creates:
- `.mise.toml` with common tasks (test, lint, format, dev, build, clean)
- `.envrc` for direnv integration
- Git initialization if not present