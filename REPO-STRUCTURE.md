---
title: Repository Structure
category: reference
component: organization
status: active
version: 4.0.0
last_updated: 2026-02-09
tags: [structure, organization]
priority: high
---

# SystemConfig Repository Structure

> **Purpose**: macOS development environment configuration, templates, and documentation
> **Focus**: Chezmoi dotfile templates, CLI tool setup, shell configuration

## Directory Layout

```
SystemConfig/
├── .claude/                    # Claude Code project config
│   ├── settings.json          # Project permissions (committed)
│   └── README.md              # Directory documentation
├── .gemini/                    # Gemini CLI project config
├── .github/                    # GitHub workflows and templates
├── .meta/                      # Repository metadata
│
├── 01-setup/                   # Installation guides
│   ├── 00-prerequisites.md    # System requirements
│   ├── 01-homebrew.md         # Homebrew setup
│   ├── 02-chezmoi.md          # Chezmoi initialization
│   └── 03-iterm2.md           # iTerm2 configuration
│
├── 02-configuration/           # Tool configuration docs
│   ├── terminals/             # Terminal setup (iTerm2)
│   └── tools/                 # Tool configs (SSH, MCP, Codex)
│
├── 03-automation/              # Automation guides
│
├── 04-policies/                # Version and update policies
│
├── 05-reference/               # Reference documentation
│
├── 06-templates/               # Chezmoi and dotfile templates
│   ├── chezmoi/               # Chezmoi source templates
│   │   ├── dot_config/        # ~/.config/ templates
│   │   │   ├── fish/conf.d/   # Fish shell config files
│   │   │   ├── direnv/        # direnv config
│   │   │   ├── mise/          # mise config
│   │   │   ├── system-update/ # system-update config template
│   │   │   └── starship.toml.tmpl
│   │   ├── run_once_*.sh.tmpl # One-time setup scripts
│   │   └── dot_*.tmpl         # Other dotfile templates
│   ├── dotfiles/              # Static dotfile examples
│   └── projects/              # Project template utilities
│
├── ai-tools/                   # Centralized AI tool MCP config
│   ├── mcp-servers.json       # Global MCP server definitions
│   ├── sync-to-tools.sh       # Propagation script
│   └── README.md              # Usage documentation
│
├── docs/                       # Documentation
│   ├── guides/                # Setup and maintenance guides
│   ├── policies/              # Policy documentation
│   └── *.md                   # CLI tool setup guides
│
├── scripts/                    # Shell scripts
│   ├── system-update.sh       # Unified system update command
│   ├── system-update.d/       # Drop-in update plugins
│   ├── sync-chezmoi-templates.sh  # Sync SystemConfig → dotfiles source (SSOT)
│   ├── doctor-path.sh         # PATH diagnostic script
│   └── iterm2-setup.sh        # iTerm2 configuration
│
├── AGENTS.md                   # Canonical project contract (tool-agnostic)
├── CLAUDE.md                   # Claude Code shim (imports AGENTS.md)
├── README.md                   # Repository overview
├── INDEX.md                    # Quick navigation
└── CHANGELOG.md                # Version history
```

## Key Directories

### `ai-tools/`
Centralized user-level AI tool configuration:
- **MCP servers**: Global definitions synced to all AI tools
- **Sync script**: Propagates config to Claude, Cursor, Windsurf, Copilot, Codex

### `06-templates/chezmoi/`
Production chezmoi templates for dotfile management:
- **Fish shell configs**: `dot_config/fish/conf.d/*.fish.tmpl`
- **CLI installers**: `run_once_*-install-*.sh.tmpl`
- **Tool configs**: `dot_config/mise/`, `dot_config/direnv/`, etc.

### `scripts/`
System management scripts:
- **system-update.sh**: Unified update for all packages, tools, and runtimes
- **system-update.d/**: Drop-in plugin directory (rustup, pipx, uv, etc.)
- **sync-chezmoi-templates.sh**: Propagates `06-templates/chezmoi/` → `~/.local/share/chezmoi/` (SSOT workflow; supports `--check` and `--force`)
- **Diagnostics**: Check system health (`doctor-path.sh`)
- **Setup**: Configure terminal (`iterm2-setup.sh`)

### `docs/`
CLI tool setup guides and configuration references.

## Configuration Files

| File | Purpose |
|------|---------|
| `.mise.toml` | Runtime version management |
| `.envrc` | direnv environment variables |
| `.gitignore` | Git exclusions |
| `.node-version` | Node.js version pin |
| `AGENTS.md` | Project contract for all AI tools |
| `CLAUDE.md` | Claude Code context (shim to AGENTS.md) |

## Related Locations

| Location | Purpose |
|----------|---------|
| `~/.local/share/chezmoi/` | Active chezmoi source |
| `~/.config/chezmoi/chezmoi.toml` | Chezmoi data/config |
| `~/.config/fish/` | Fish shell configuration |
| `~/.config/system-update/config` | system-update user config |

### AI Tool Config Locations (managed by `ai-tools/sync-to-tools.sh`)

| Tool | MCP Config |
|------|------------|
| Claude Code CLI | `~/.claude/.claude.json` (mcpServers key) |
| Claude Desktop | `~/.claude.json` (mcpServers key) |
| Cursor | `~/.cursor/mcp.json` |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` |
| Copilot CLI | `~/.copilot/mcp-config.json` |
| Codex CLI | `~/.codex/config.toml` |
