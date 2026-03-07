---
title: Claude CLI Setup
category: reference
component: claude_cli_setup
status: active
version: 3.0.0
last_updated: 2026-02-05
tags: [cli, claude, ai, native]
priority: high
---

# Claude Code CLI Setup

Minimal configuration for Claude Code CLI. The CLI is rapidly evolving - defer to official defaults where possible.

## The Separation Principle

Claude Code CLI and Claude Desktop / Cowork are **completely separate products** with non-overlapping config surfaces. The CLI is a terminal dev tool; Desktop is a knowledge-work app. Their MCP configs are isolated — servers added to one are invisible to the other. Never conflate the two. See `docs/claude-desktop-setup.md` for Desktop config.

## Overview

- **Installation**: `curl -fsSL https://claude.ai/install.sh | bash`
- **Location**: `~/.local/bin/claude` (symlink to `~/.local/share/claude/versions/<version>`)
- **Data**: `~/.local/share/claude/` (versions, updates)
- **Global config**: `~/.claude/` (managed directly, not via chezmoi)
- **Fish config**: `~/.config/fish/conf.d/10-claude.fish` (chezmoi-managed)
- **Official docs**: https://docs.anthropic.com/en/docs/claude-code/overview

## Installation

### Native Installer (Recommended)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Via Chezmoi

```bash
chezmoi apply  # runs run_once_10-install-claude.sh
```

### Migration from npm

If you have the old npm version installed:

```bash
# Remove old npm version
npm uninstall -g @anthropic-ai/claude-code

# Install native version
curl -fsSL https://claude.ai/install.sh | bash
```

## Configuration Philosophy

**Minimal customization**: Only configure what differs from CLI defaults. The CLI evolves rapidly - hardcoding settings leads to stale configs.

### What We Configure

1. **Fish shell integration** (`10-claude.fish`):
   - Binary path fallback (`~/.local/bin/claude`)
   - Abbreviations (`cc`, `ccp`, `ccc`, etc.)
   - Helper functions (`claude-init`, `claude_check_updates`)
   - Performance timeouts (adjust per machine)

2. **Global settings** (`~/.claude/settings.json`):
   - Tool permissions (allow/deny patterns)
   - Privacy settings (telemetry)
   - Notification hooks
   - Managed directly, not via chezmoi

### What We Don't Configure

- Model selection (use CLI defaults or `--model` flag)
- Agents (use built-in agents)
- Formatting hooks (use CLI's built-in formatting)

### MCP Servers

Global MCP servers are managed via `~/SystemConfig/ai-tools/sync-to-tools.sh` and land in `~/.claude.json` (user-scoped). To add a server at user scope manually:

```bash
claude mcp add --scope user <server-name> <command> [args...]
```

Project-specific servers go in each project's `.mcp.json`.

## Commands

| Command | Description |
|---------|-------------|
| `cc` | Launch Claude |
| `ccp` | Plan/headless mode |
| `ccc` | Continue conversation |
| `ccr` | Resume session |
| `ccd` | Add directory |
| `claude-init` | Initialize project structure |
| `claude-review` | Review staged changes |
| `claude_check_updates` | Check for updates |

## Updates

The native installer includes built-in update support:

```bash
# Check and update
claude update

# Or use the helper function
claude_check_updates
```

## File Locations

| Path | Purpose |
|------|---------|
| `~/.local/bin/claude` | Binary symlink |
| `~/.local/share/claude/` | Versions and data |
| `~/.claude/` | Config and settings |
| `~/.claude/settings.json` | Global settings |
| `~/.claude.json` | MCP servers config (user-scoped) |

## Project Configuration

Projects can have local `.claude/` directories:

```
project/
├── CLAUDE.md           # Project context
└── .claude/
    ├── settings.json   # Project permissions
    └── commands/       # Project-specific commands
```

Initialize with `claude-init` in any project directory.

## Troubleshooting

### Command not found

```bash
# Ensure ~/.local/bin is in PATH
fish_add_path ~/.local/bin

# Verify
which claude
```

### Authentication

Claude Code uses subscription-based auth by default. For API auth:

```bash
export ANTHROPIC_API_KEY="your-key"
# Or via gopass:
export ANTHROPIC_API_KEY="$(gopass show anthropic/api-keys/development)"
```

### Still using npm version?

Check which version is active:

```bash
which claude
# Should show: ~/.local/bin/claude

# If it shows ~/.npm-global/bin/claude, migrate:
npm uninstall -g @anthropic-ai/claude-code
curl -fsSL https://claude.ai/install.sh | bash
```

## Related

- [Official Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/overview)
- [Claude Code Settings Reference](./claude-code-cli-settings-official.md)
- [Claude Desktop / Cowork Setup](./claude-desktop-setup.md)
- [Fish config template](../06-templates/chezmoi/dot_config/fish/conf.d/10-claude.fish.tmpl)
