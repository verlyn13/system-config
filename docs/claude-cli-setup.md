---
title: Claude Cli Setup
category: reference
component: claude_cli_setup
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Claude Code CLI Setup

This document describes the single-source installation and configuration of Claude Code CLI in this development environment.

## Overview

- **Installation method**: npm global (`@anthropic-ai/claude-code`)
- **Version**: 2.0.13 (latest)
- **Location**: `~/.npm-global/bin/claude`
- **Configuration**: Single Fish config managed via chezmoi
- **Documentation repo**: `~/Development/personal/claude-code` (examples/hooks only)

## Installation

Claude Code CLI is installed via npm and managed through chezmoi templates:

```bash
npm install -g @anthropic-ai/claude-code
```

### Automated Installation

The chezmoi template `run_once_10-install-claude.sh` handles initial installation:

```bash
chezmoi apply
```

This script:
1. Checks if `claude` command exists
2. Installs `@anthropic-ai/claude-code` via npm if missing
3. Checks for available updates on each run
4. Provides installation location and version info

## Configuration

### Single Source of Truth

All Claude CLI configuration is managed through:

**Template**: `06-templates/chezmoi/dot_config/fish/conf.d/10-claude.fish.tmpl`
**Active config**: `~/.config/fish/conf.d/10-claude.fish`

Apply changes with:

```bash
chezmoi apply
```

### Model Configuration

Default models are configured in the Fish config:

```fish
CLAUDE_DEFAULT_MODEL="claude-sonnet-4-5-20250929"  # Sonnet 4.5 (latest)
CLAUDE_PLAN_MODEL="claude-opus-4-20250514"         # Opus 4 for planning
```

Override per-project in `.envrc`:

```bash
export CLAUDE_DEFAULT_MODEL="claude-opus-4-20250514"
```

### Authentication

Two auth modes are supported:

1. **Subscription** (default): Uses Claude subscription login
2. **API**: Uses API key from gopass

Switch modes:

```fish
set -gx CLAUDE_AUTH api          # Use API auth
set -gx CLAUDE_AUTH subscription # Use subscription (default)
```

API key is fetched via:

```fish
gopass show anthropic/api-keys/opus
```

## Commands

### Aliases

| Command | Description | Usage |
|---------|-------------|-------|
| `cc` | Claude with default model | `cc "fix this bug"` |
| `ccc` | Continue conversation | `ccc "and add tests"` |
| `ccp` | Plan/headless mode | `ccp "plan implementation"` |
| `ccplan` | Force Opus model with API auth | `ccplan "complex refactor"` |
| `claude` | Full CLI access | `claude --help` |

### Update Management

Check for updates:

```fish
claude_check_updates
```

Update to latest:

```bash
npm update -g @anthropic-ai/claude-code
```

Automated update script:

```bash
~/Development/personal/system-setup-update/scripts/update-claude-cli.sh
```

## Documentation Repository

The `~/Development/personal/claude-code` repository contains:

- **Official examples**: Hook implementations, slash commands
- **Changelog**: Latest features and bug fixes
- **GitHub issues**: Community support and bug reports

Keep it updated:

```bash
cd ~/Development/personal/claude-code
git pull origin main
```

The update script automatically pulls latest docs after CLI updates.

## Troubleshooting

### Command not found

Ensure `~/.npm-global/bin` is in your PATH:

```fish
fish_add_path ~/.npm-global/bin
```

Verify installation:

```bash
which claude
claude --version
```

### Version mismatch

If `claude_check_updates` shows wrong version, clear npm cache:

```bash
npm cache clean --force
npm update -g @anthropic-ai/claude-code
```

### mise warnings

If you see `mise WARN missing: npm:@anthropic-ai/claude-code@2.0.1`, this is safe to ignore. It's from an old mise configuration that's no longer used.

To clean up:

```bash
mise uninstall npm:@anthropic-ai/claude-code@2.0.1
```

## Modern Features (v2.0+)

Claude Code 2.0+ includes:

- **Native VS Code extension**: Built-in editor integration
- **`/rewind`**: Undo code changes in conversations
- **`/usage`**: Check plan limits
- **Tab to toggle thinking**: Sticky across sessions
- **Ctrl-R history search**: Like bash/zsh
- **`/context`**: Manage conversation context
- **Hooks SDK**: Now "Claude Agent SDK"
- **`--agents` flag**: Dynamically add subagents

See `~/Development/personal/claude-code/CHANGELOG.md` for full details.

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_BIN` | `~/.npm-global/bin/claude` | Path to Claude binary |
| `CLAUDE_DEFAULT_MODEL` | `claude-sonnet-4-5-20250929` | Default model for `cc` |
| `CLAUDE_PLAN_MODEL` | `claude-opus-4-20250514` | Model for `ccplan` |
| `CLAUDE_AUTH` | `subscription` | Auth mode (subscription/api) |
| `CLAUDE_API_KEY_CMD` | `gopass show anthropic/api-keys/opus` | Command to fetch API key |

## Related Documentation

- [Official Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/overview)
- [System Setup Guide](../README.md)
- [Chezmoi Templates](./chezmoi-templates.md)
- [Fish Shell Configuration](../06-templates/chezmoi/dot_config/fish/conf.d/)
