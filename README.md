---
title: System Setup Documentation
category: reference
component: overview
status: active
version: 2.0.0
last_updated: 2025-10-23
tags: []
priority: critical
---


# macOS M3 Max Development Environment Setup
## 🚀 Holistic, Context-Aware System Configuration with Living Documentation

> Repository roles: This repo (`system-setup-update`) is the authoritative system configuration and observability source on this machine. If you also have a `system-setup` repo present locally, consider it a legacy snapshot used for reference only. All scripts, policies, registries, and dashboard wiring should point here.

[![Documentation Sync](https://github.com/verlyn13/system-setup-update/actions/workflows/documentation-sync.yml/badge.svg)](https://github.com/verlyn13/system-setup-update/actions/workflows/documentation-sync.yml)
[![System Validation](https://github.com/verlyn13/system-setup-update/actions/workflows/validation.yml/badge.svg)](https://github.com/verlyn13/system-setup-update/actions/workflows/validation.yml)

### 🎯 System Status
**Documentation Health:** 100% Coverage | 29 Documents with Metadata
**System State:** ✅ Validated | 1 Minor Discrepancy (Chezmoi)
**Automation:** Active | LaunchAgent + GitHub Actions CI/CD
**Last Sync:** September 26, 2025 08:52

### 🏗️ Repository Architecture

This repository implements a **self-aware documentation system** that:
- 🔄 **Automatically syncs** with live system configuration
- 🔍 **Validates** system state against documentation
- 📊 **Reports** discrepancies and health metrics
- 🤖 **Updates** documentation when configuration changes
- ✅ **Ensures** documentation accuracy through CI/CD

Repository Roles
- Authoritative: `system-setup-update` (this repo) — active, source of truth
- Legacy: `system-setup` — historical snapshot; do not modify or wire automation to it

### 📚 Navigation

#### 🎯 Quick Start
- **[Documentation Index](docs/INDEX.md)** - Complete documentation navigation
- **[System Status](docs/system/implementation-status.md)** - Current system state
- **[Setup Guide](01-setup/00-prerequisites.md)** - Start here for new installations

#### 📂 Documentation Structure
- **[/docs/](docs/)** - All documentation with proper metadata
  - **[/docs/system/](docs/system/)** - System status and configuration
  - **[/docs/mcp/](docs/mcp/)** - MCP server and bridge docs
  - **[/docs/guides/](docs/guides/)** - Implementation guides
  - **[/docs/reports/](docs/reports/)** - Status reports

#### 🛠️ Setup Guides (Phase-by-Phase)
1. **[Prerequisites](01-setup/00-prerequisites.md)** - System requirements ✅
2. **[Homebrew](01-setup/01-homebrew.md)** - Package manager ✅
3. **[Chezmoi](01-setup/02-chezmoi.md)** - Dotfiles management ✅
4. **[Fish Shell](01-setup/03-fish-shell.md)** - Shell configuration 📝
5. **[Mise](01-setup/04-mise.md)** - Version management 📝
6. **[Security](01-setup/05-security.md)** - Security tools 📝

#### ⚙️ Configuration
- **[iTerm2 Setup](02-configuration/terminals/iterm2-config.md)** - Terminal configuration
- **[SSH Multi-Account](02-configuration/tools/ssh-multi-account.md)** - GitHub accounts
- **[Policy Framework](04-policies/policy-as-code.yaml)** - System policies

#### 🤖 Automation
- **[Documentation Sync](DOCUMENTATION-SYNC-ARCHITECTURE.md)** - How sync works
- **[Validation Suite](03-automation/scripts/validate-system.py)** - System validation
- **[Sync Engine](03-automation/scripts/doc-sync-engine.py)** - Core sync logic
- **[LaunchAgent Setup](03-automation/scripts/install-launchagent.sh)** - Automated scheduling

#### 📊 Current Reports
- **[Implementation Status](07-reports/status/implementation-status.md)** - Phase tracking
- **[Tool Versions](07-reports/status/tool-versions.md)** - Installed versions
- **[Sync Summary](07-reports/status/sync-summary.md)** - Latest sync results
- **[System Context](07-reports/status/system-context.json)** - Full system snapshot

### 🚀 Quick Commands

```bash
# Run system validation
python3 03-automation/scripts/validate-system.py

# Sync documentation with system state
python3 03-automation/scripts/doc-sync-engine.py

# Install automated sync (LaunchAgent)
./03-automation/scripts/install-launchagent.sh install

# Check sync status
./03-automation/scripts/install-launchagent.sh status
```

### ⚠️ Shell Environment Essentials

- direnv uses Homebrew Bash to avoid Apple `/bin/bash` crashes on macOS 26+.
  - Ensure `~/.config/direnv/direnv.toml` contains: `bash_path = "/opt/homebrew/bin/bash"`
  - Our repair script sets this up for you: `bash scripts/repair-shell-env.sh`
- Fish conf.d load order: `00-homebrew.fish` → `01-mise.fish` → `02-direnv.fish` → `04-paths.fish`.
  - Homebrew/env first, mise shims, then direnv hook (fail‑safe), then starship init, then user bins appended.
- .envrc standard: embedded `use_mise()` with `direnv_load mise direnv exec`, then `use mise`, with PATH_add and dotenv.
  - Use `scripts/multirepo-align-env.sh [optional scan roots...]` to standardize across repos.

### Starship Prompt

- Config file: `~/.config/starship.toml` (managed via `06-templates/chezmoi/dot_config/starship.toml.tmpl`)
- Fish init: `~/.config/fish/conf.d/03-starship.fish` initializes starship for interactive shells.
- Git status module: uses `stashed = "$$"` for literal `$` compatibility with recent starship versions.


### 📦 Installation

#### Fresh System Setup
```bash
# View implementation progress
open implementation-status.md

# Run validation tests
open validation-checklist.md
```

#### AI CLI Tools (managed here)

**Claude Code CLI**
- Installation: npm global (`@anthropic-ai/claude-code@2.0.3+`)
- Location: `~/.npm-global/bin/claude`
- Config: `~/.config/fish/conf.d/10-claude.fish` (managed via chezmoi)
- Docs: [`docs/claude-cli-setup.md`](docs/claude-cli-setup.md)
- Update: `scripts/update-claude-cli.sh` or `claude_check_updates`
- Aliases: `cc`, `ccc`, `ccp`, `ccplan`
- Auth: subscription (default) or API key (via gopass)

**Codex CLI**
- Installation: Homebrew (`brew install openai/openai/codex`)
- Location: `/opt/homebrew/bin/codex` (via PATH)
- Config: `~/.config/fish/conf.d/12-codex.fish` (managed via chezmoi)
- Config file: `~/.codex/config.toml` (single global file; see [`02-configuration/tools/codex-cli.md`](02-configuration/tools/codex-cli.md))
- Docs: [`docs/codex-cli-setup.md`](docs/codex-cli-setup.md)
- Update: `scripts/update-codex-cli.sh` or `codex_check_updates`
- Aliases: `cx`, `cxp`, `cxfast`, `cxreview`
- Auth: API key via gopass (`openai/api-key`)

### ✅ What's Working

#### Core Development Environment (Phases 0-3)
- ✅ **Homebrew** - Package management at `/opt/homebrew`
- ✅ **Fish Shell** - Default shell with modular configuration
- ✅ **chezmoi** - Dotfile management with hardened templates
- ✅ **Claude Code CLI** - v2.0.34 accessible in PATH

#### Installed Tools
- **Languages**: Node 24.9.0, Python 3.13.7, Go 1.25.1, Bun 1.2.22, Java 17
- **CLI Tools**: bat, eza, ripgrep, fzf, gh, lazygit, neovim
- **Dev Tools**: mise, direnv, starship, tmux, zellij

### ⚠️ In Progress

#### Phase 4: Version Management - COMPLETE
- ✅ mise installed with core languages
- ✅ Rust toolchain installed (1.90.0)
- ✅ Project templates tested successfully
- ✅ uv installed (0.8.22)

### ❌ Not Started

- **Phase 5**: Security - ✅ Age key created, gopass configured
- **Phase 6**: Containerization - ✅ OrbStack running, Docker working
- **Phase 7**: Android Development - ⏸️ Skipped by choice
- **Phase 8**: Bootstrap Script - ✅ Created with Policy as Code
- **Phase 9**: Project Templates - ✅ Tested and working
- **Phase 10**: System Optimization - ❌ Not started

### 🔧 Common Operations

#### Validate System
```bash
# Quick health check
fish -c 'mise doctor && chezmoi doctor'

# Full validation
open validation-checklist.md
# Run commands for each phase
```

#### Apply Configuration Changes
```bash
# Update dotfiles
chezmoi apply

# Update packages
brew upgrade && mise upgrade
```

#### Fix Common Issues
```bash
# Claude CLI not found
fish -c 'echo $PATH | grep npm-global'
# Should show: /Users/verlyn13/.npm-global/bin

# Template errors
cat ~/.config/chezmoi/chezmoi.toml
# Ensure headless, android, shell keys exist
```

### 📊 Compliance Metrics

| Category | Score | Status |
|----------|-------|--------|
| Documentation | 95% | ✅ Excellent |
| Implementation | 65% | ✅ Good |
| Configuration | 75% | ✅ Good |
| **Overall** | **86.7%** | **B** |

### 🚨 Known Issues

#### High Priority - RESOLVED
1. ✅ **Bootstrap Script Created** - Located at `~/.local/share/chezmoi/install.sh`
2. ✅ **Secrets Management Initialized** - Age key generated, gopass configured
3. ✅ **Rust Installed** - Version 1.90.0 via mise

#### Medium Priority
1. **Project Templates Untested** - May fail on first use
2. **Container Environment Missing** - Can't test Docker apps
3. **GUI Apps Incomplete** - Some installations timed out

### 📈 Progress Tracking

```
Phase Completion:
[0] Pre-flight    ████████████████████ 100%
[1] Foundation    ████████████████████ 100%
[2] Dotfiles      ████████████████████ 100%
[3] Fish Shell    ████████████████████ 100%
[4] Version Mgmt  ████████████████████ 100%
[5] Security      ████████████████████ 100%
[6] Containers    ████████████████████ 100%
[7] Android       [SKIPPED BY CHOICE]
[8] Bootstrap     ████████████████████ 100%
[9] Templates     ████████████████████ 100%
[10] Optimization ░░░░░░░░░░░░░░░░░░░░   0%
```

### 🎯 Next Steps

1. **Complete Phase 4**
   - Install Rust: `mise use rust@stable`
   - Test project templates
   - Verify uv installation

2. **Create Bootstrap Script**
   - Write `~/.local/share/chezmoi/install.sh`
   - Make system reproducible

3. **Initialize Security**
   - Set up gopass + age
   - Configure secret management

### 🛠 Architecture Overview

```
System Structure:
├── Package Management: Homebrew
├── Shell: Fish + Starship
├── Dotfiles: chezmoi
├── Version Manager: mise
├── Project Isolation: direnv
├── Secrets: gopass + age (planned)
└── Containers: OrbStack (planned)

File Locations:
├── Dotfile Source: ~/.local/share/chezmoi/
├── Dotfile Data: ~/.config/chezmoi/chezmoi.toml
├── Fish Config: ~/.config/fish/conf.d/
├── mise Config: ~/.config/mise/config.toml
└── Project Templates: ~/.local/share/chezmoi/workspace/
```

### 📝 Contributing

This is a personal development environment setup. Key principles:
- **Thin Machine, Thick Projects** - Minimal global, rich project-specific
- **Reproducibility** - Everything in version control
- **Security** - Hardware keys, scoped secrets
- **Performance** - Native ARM64, optimized for M3 Max

### 🔗 Related Repositories

- Dotfiles: `~/.local/share/chezmoi/` (private)
- This documentation: `/Users/verlyn13/Development/personal/system-setup-update/`

### 📅 Last Updated
September 25, 2025 - Phase 4 in progress

### 🆘 Troubleshooting

For common issues and solutions, see:
- [implementation-status.md#known-issues](implementation-status.md)
- [validation-checklist.md](validation-checklist.md)
- [CLAUDE.md#known-issues-and-solutions](CLAUDE.md)
- [docs/claude-cli-setup.md](docs/claude-cli-setup.md) - Complete Claude CLI troubleshooting
