---
title: Documentation Index
category: reference
component: navigation
status: active
version: 2.0.0
last_updated: 2025-09-26
tags: []
priority: critical
---

# System Setup Documentation Index

> **Complete navigation and registry for macOS development environment setup**
>
> Version: 2.0.0 | Last Updated: 2025-09-26 | Status: Active Development

## 🎯 System Status

**[📊 MASTER STATUS](MASTER-STATUS.md)** - Single source of truth for system configuration (96.7% compliant)

## 🎯 Quick Start Paths

### For New System Setup
1. [Prerequisites & System Requirements](01-setup/00-prerequisites.md) ⚡ Critical
2. [Homebrew Installation](01-setup/01-homebrew.md) ⚡ Critical
3. [Chezmoi Setup](01-setup/02-chezmoi.md) ⚡ Critical
4. [Fish Shell Configuration](01-setup/03-fish-shell.md)
5. [Development Tools](01-setup/04-mise.md)

### For Specific Tools
- **Terminal**: [iTerm2 Setup](02-configuration/terminals/iterm2-config.md) | [Manual Settings](~/00_inbox/iterm2-manual-settings.md) | [DX Guide](~/00_inbox/iterm2-dx-guide.md)
- **Shell**: [Fish Configuration](02-configuration/shells/fish.md)
- **Editor**: [VS Code](02-configuration/editors/vscode.md) | [Neovim](02-configuration/editors/neovim.md)
- **Version Management**: [Mise Setup](01-setup/04-mise.md)

### For System Management
- [Current Status Report](07-reports/status/implementation-status.md) 📊
- [Policy Compliance](04-policies/policy-as-code.yaml) 📋
- [Automation Scripts](03-automation/scripts/) 🤖
- [System Dashboard](~/Development/personal/system-dashboard/) 🎛️ - Real-time monitoring with telemetry
- [MCP Server](02-configuration/tools/mcp-server.md) 🤖 - AI-assisted DevOps automation

---

## 📁 Complete Document Registry

### 01 - Setup Documentation
Essential setup guides in execution order.

| Document | Status | Priority | Description |
|----------|--------|----------|-------------|
| [Prerequisites](01-setup/00-prerequisites.md) | 🟢 Active | ⚡ Critical | System requirements and preparation |
| [Homebrew](01-setup/01-homebrew.md) | 🔵 Draft | ⚡ Critical | Package manager installation |
| [Chezmoi](01-setup/02-chezmoi.md) | 🔵 Draft | ⚡ Critical | Dotfiles management setup |
| [Fish Shell](01-setup/03-fish-shell.md) | 🔵 Draft | 🔥 High | Shell configuration |
| [Mise](01-setup/04-mise.md) | 🔵 Draft | 🔥 High | Version management tool |
| [Security](01-setup/05-security.md) | 🔵 Draft | 🔥 High | Security tools and settings |
| [MCP Usage](01-setup/06-mcp-usage.md) | 🟢 Active | ⚡ Critical | **How to ACTUALLY use MCP for system management** |

### 02 - Configuration Guides
Detailed configuration for each component.

#### Terminals
| Document | Status | Component | Description |
|----------|--------|-----------|-------------|
| [iTerm2 Config](02-configuration/terminals/iterm2-config.md) | 🟢 Active | iTerm2 | Complete iTerm2 setup |
| [iTerm2 Status](02-configuration/terminals/ITERM2-SETUP-STATUS.md) | 🟢 Active | iTerm2 | Current setup status |
| [iTerm2 Integration](02-configuration/terminals/ITERM2-CHEZMOI-INTEGRATION.md) | 🟢 Active | iTerm2 | Chezmoi integration details |
| [Warp](02-configuration/terminals/warp.md) | 🔵 Draft | Warp | AI-powered terminal |
| [Alacritty](02-configuration/terminals/alacritty.md) | 🔵 Draft | Alacritty | GPU-accelerated terminal |

#### Shells
| Document | Status | Component | Description |
|----------|--------|-----------|-------------|
| [Fish](02-configuration/shells/fish.md) | 🔵 Draft | Fish | Fish shell configuration |
| [Zsh](02-configuration/shells/zsh.md) | 🔵 Draft | Zsh | Zsh configuration |
| [Bash](02-configuration/shells/bash.md) | 🔵 Draft | Bash | Bash compatibility |

#### Development Tools
| Document | Status | Component | Description |
|----------|--------|-----------|-------------|
| [SSH Multi-Account](02-configuration/tools/ssh-multi-account.md) | 🟢 Active | SSH | Multiple GitHub accounts |
| [Codex CLI](02-configuration/tools/codex-cli.md) | 🟢 Active | Codex | GPT-5 assistant configuration |
| [MCP Server](02-configuration/tools/mcp-server.md) | 🟢 Active | MCP | DevOps automation via AI agents |
| [MCP Telemetry](02-configuration/tools/mcp-telemetry.md) | 🟢 Active | Telemetry | OpenTelemetry observability |
| [Git](02-configuration/tools/git.md) | 🔵 Draft | Git | Git configuration |
| [Docker](02-configuration/tools/docker.md) | 🔵 Draft | Docker | Container setup |

### 03 - Automation & Scripts
Executable automation tools and integration guides.

| Document/Script | Type | Purpose |
|--------|------|---------|
| [MCP-Dashboard Integration](03-automation/mcp-dashboard-integration.md) | Guide | 🔗 Integration architecture |
| [setup-iterm2.sh](03-automation/scripts/setup-iterm2.sh) | Setup | Automated iTerm2 configuration |
| [apply-optimizations.sh](03-automation/scripts/apply-optimizations.sh) | Optimize | System optimizations |
| [validate.sh](03-automation/scripts/validate.sh) | Validate | Configuration validation |
| [export-config.sh](03-automation/scripts/export-config.sh) | Export | Export current configs |

### 04 - Policies & Compliance
System policies and validation.

| Document | Type | Purpose |
|----------|------|---------|
| [Policy as Code](04-policies/policy-as-code.yaml) | Policy | Machine-readable policies |
| [Version Policy](04-policies/version-policy.md) | Policy | Version management rules |
| [Validation Script](04-policies/validate-policy.py) | Script | Policy compliance checker |
| [Security Policy](04-policies/security-policy.md) | Policy | Security requirements |

### 05 - Reference Documentation
Supporting information and guides.

| Document | Type | Description |
|----------|------|-------------|
| [MCP Examples](05-reference/mcp-examples.md) | Guide | **Real-world MCP usage examples** |
| [Troubleshooting](05-reference/troubleshooting.md) | Guide | Common issues and solutions |
| [Migration Guide](05-reference/migration.md) | Guide | Migrating from other setups |
| [Rollback Procedures](05-reference/rollback.md) | Guide | How to rollback changes |
| [FAQ](05-reference/faq.md) | Reference | Frequently asked questions |
| [Project Manifests](docs/projects.md) | Reference | Manifest spec + examples |
| [Observability Platform](docs/observability.md) | Reference | Observers, contracts, endpoints |
| [MCP Integration](docs/mcp-integration.md) | Reference | Server resources/tools wiring |
| [Repository Roles](docs/repositories.md) | Reference | Authoritative vs. legacy usage |

### 06 - Templates
Reusable configuration templates.

| Category | Location | Description |
|----------|----------|-------------|
| [Chezmoi Templates](06-templates/chezmoi/) | Templates | Chezmoi configuration templates |
| [Dotfile Templates](06-templates/dotfiles/) | Templates | Standard dotfile templates |
| [Project Templates](06-templates/projects/) | Templates | Project scaffolding templates |

### 07 - Reports & Status
Current system state and progress tracking.

#### Current Status
| Report | Last Updated | Purpose |
|--------|--------------|---------|
| [Implementation Status](07-reports/status/implementation-status.md) | 2025-09-28 | Phase tracking |
| [Progress Report](07-reports/status/PROGRESS-REPORT.md) | 2025-09-26 | Detailed progress |
| [Setup Completion](07-reports/status/SETUP-COMPLETION-REPORT.md) | 2025-09-26 | Completion status |
| [Compliance Report](07-reports/status/compliance-report.md) | 2025-09-26 | Policy compliance |

#### Observability
- [Observability Platform Delivery (2025-09-28)](07-reports/observability-platform-implementation-2025-09-28.md) — Components delivered, usage, and next steps
 - [HTTP Bridge (Read-only)](scripts/http-bridge.js) — Local dashboard API
 - [Grafana Dashboard (example JSON)](examples/grafana/observability-dashboard.json)

---

## 🏷️ Document Organization

### By Status
- **🟢 Active**: Currently maintained and accurate
- **🔵 Draft**: In development
- **🟠 Deprecated**: Scheduled for update/removal
- **⚫ Archived**: Historical reference only

### By Priority
- **⚡ Critical**: Must complete first
- **🔥 High**: Important for functionality
- **💎 Medium**: Enhances productivity
- **☁️ Low**: Nice to have

### By Category
- **Setup**: Installation and initialization
- **Configuration**: Detailed tool configuration
- **Automation**: Scripts and workflows
- **Policy**: Rules and compliance
- **Reference**: Supporting documentation
- **Template**: Reusable configurations
- **Report**: Status and metrics

---

## 🔍 Search by Topic

### Terminal & Shell
- [iTerm2 Configuration](02-configuration/terminals/iterm2-config.md)
- [Fish Shell Setup](02-configuration/shells/fish.md)
- [Terminal Optimizations](03-automation/scripts/apply-optimizations.sh)

### Development Tools
- [Mise Version Management](01-setup/04-mise.md)
- [Git Configuration](02-configuration/tools/git.md)
- [SSH Multi-Account](02-configuration/tools/ssh-multi-account.md)

### System Management
- [Chezmoi Dotfiles](01-setup/02-chezmoi.md)
- [Policy Compliance](04-policies/policy-as-code.yaml)
- [System Validation](03-automation/scripts/validate.sh)

### Troubleshooting
- [Common Issues](05-reference/troubleshooting.md)
- [FAQ](05-reference/faq.md)
- [Rollback Guide](05-reference/rollback.md)

---

## 📈 Implementation Progress

```
Phase 0: Prerequisites     ████████████ 100% Complete
Phase 1: Homebrew         ████████████ 100% Complete
Phase 2: Chezmoi          ████████████ 100% Complete
Phase 3: Fish Shell       ████████████ 100% Complete
Phase 4: Mise             ████████░░░░  70% In Progress
Phase 5: Security         ░░░░░░░░░░░░   0% Not Started
Phase 6: Containers       ░░░░░░░░░░░░   0% Not Started
Phase 7: Development      ░░░░░░░░░░░░   0% Not Started
Phase 8: Automation       ████░░░░░░░░  30% Partial
Phase 9: Optimization     ████████░░░░  70% Partial
```

---

## 🚀 Quick Commands

```bash
# Check system status
./03-automation/scripts/validate.sh

# Apply optimizations
./03-automation/scripts/apply-optimizations.sh

# Generate reports
./03-automation/scripts/generate-report.sh

# Check policy compliance
python 04-policies/validate-policy.py
```

---

## 📚 Related Resources

- [Repository Structure](REPO-STRUCTURE.md)
- [AI Assistant Context](CLAUDE.md)
- [Main README](README.md)
- [Active Dotfiles](~/.local/share/chezmoi/)
- [System Configuration](~/workspace/dotfiles/)

---

*This index is automatically generated and updated. Last sync: 2025-09-26*
