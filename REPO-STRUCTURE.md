---
title: Repository Structure
category: reference
component: organization
status: active
version: 3.0.0
last_updated: 2025-12-06
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
├── .gemini/                    # Gemini CLI project config
├── .github/                    # GitHub workflows and templates
├── .meta/                      # Repository metadata
│
├── 01-setup/                   # Installation guides
│   ├── 00-prerequisites.md    # System requirements
│   ├── 01-homebrew.md         # Homebrew setup
│   ├── 02-chezmoi.md          # Chezmoi initialization
│   ├── 03-iterm2.md           # iTerm2 configuration
│   ├── 06-mcp-usage.md        # MCP server usage
│   └── 07-infisical.md        # Infisical secrets
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
│   │   ├── dot_claude/        # ~/.claude/ templates
│   │   ├── dot_config/        # ~/.config/ templates
│   │   │   ├── fish/conf.d/   # Fish shell config files
│   │   │   ├── direnv/        # direnv config
│   │   │   ├── mise/          # mise config
│   │   │   └── starship.toml.tmpl
│   │   ├── run_once_*.sh.tmpl # One-time setup scripts
│   │   └── dot_*.tmpl         # Other dotfile templates
│   ├── dotfiles/              # Static dotfile examples
│   └── projects/              # Project template utilities
│
├── docs/                       # Documentation
│   ├── guides/                # Setup and maintenance guides
│   ├── policies/              # Policy documentation
│   └── *.md                   # CLI tool setup guides
│
├── scripts/                    # Shell scripts
│   ├── update-*.sh            # CLI update scripts
│   ├── doctor-*.sh            # Diagnostic scripts
│   ├── iterm2-setup.sh        # iTerm2 configuration
│   └── verify-*.sh            # Verification scripts
│
├── CLAUDE.md                   # AI CLI tools reference
├── README.md                   # Repository overview
├── INDEX.md                    # Quick navigation
└── CHANGELOG.md                # Version history
```

## Key Directories

### `06-templates/chezmoi/`
Production chezmoi templates for dotfile management:
- **Fish shell configs**: `dot_config/fish/conf.d/*.fish.tmpl`
- **CLI installers**: `run_once_*-install-*.sh.tmpl`
- **Tool configs**: `dot_claude/`, `dot_config/mise/`, etc.

### `scripts/`
System management scripts:
- **Update scripts**: Keep CLI tools current (`update-claude-cli.sh`, etc.)
- **Diagnostics**: Check system health (`doctor-env.sh`, `doctor-path.sh`)
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

## Related Locations

| Location | Purpose |
|----------|---------|
| `~/.local/share/chezmoi/` | Active chezmoi source |
| `~/.config/chezmoi/chezmoi.toml` | Chezmoi data/config |
| `~/.claude/` | Claude Code configuration |
| `~/.config/fish/` | Fish shell configuration |
