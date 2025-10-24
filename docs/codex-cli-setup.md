---
title: Codex Cli Setup
category: reference
component: codex_cli_setup
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Codex CLI Setup

This document describes the single-source installation and configuration of OpenAI Codex CLI in this development environment.

## Overview

- **Installation method**: npm global (`@openai/codex`)
- **Version**: 0.46.0 (latest)
- **Location**: `~/.npm-global/bin/codex`
- **Configuration**: `~/.codex/config.toml` (managed separately, not in chezmoi)
- **Fish config**: `~/.config/fish/conf.d/12-codex.fish` (managed via chezmoi)
- **Documentation**: See `02-configuration/tools/codex-cli.md` for detailed config guide

## Installation

Codex CLI is installed via npm and managed through chezmoi templates:

```bash
npm install -g @openai/codex
```

### Automated Installation

The chezmoi template `run_once_12-install-codex.sh` handles initial installation:

```bash
chezmoi apply
```

This script:
1. Checks if `codex` command exists
2. Installs `@openai/codex` via npm if missing
3. Checks for available updates on each run
4. Provides installation location and version info

## Configuration

### Fish Shell Integration

**Template**: `06-templates/chezmoi/dot_config/fish/conf.d/12-codex.fish.tmpl`
**Active config**: `~/.config/fish/conf.d/12-codex.fish`

Apply changes with:

```bash
chezmoi apply
```

### Environment Variables

```fish
CODEX_BIN="~/.npm-global/bin/codex"          # Codex binary location
CODEX_CONFIG_DIR="~/.codex"                  # Config directory
CODEX_PROFILE="default"                      # Default profile
CODEX_SANDBOX="workspace-write"              # Sandbox mode
```

Override per-project in `.envrc`:

```bash
export CODEX_PROFILE="deep"
export CODEX_SANDBOX="workspace-write"
```

### Codex Configuration File

**Location**: `~/.codex/config.toml`

This file is **not managed by chezmoi** as it contains user-specific settings and API keys.

**Reference template**: `02-configuration/tools/codex-cli.md` (lines 56-99)

Key sections:
- Model selection (gpt-5, gpt-5-mini)
- Approval policy (on-request, never)
- Sandbox mode (workspace-write, full)
- Budget limits (session, daily)
- Profiles (speed, deep, agent, maint)
- MCP servers (context7, graphiti-memory)
- API key management (via gopass)

### Initial Setup

First-time setup:

```bash
# Option 1: Use built-in init
codex --init

# Option 2: Create from template
mkdir -p ~/.codex
cp 02-configuration/tools/codex-cli.md ~/.codex/  # Reference only
# Then manually create config.toml based on the guide
```

## Commands

### Aliases

| Command | Description | Usage |
|---------|-------------|-------|
| `codex` | Full Codex CLI | `codex -p deep` |
| `cx` | Quick alias | `cx "fix this bug"` |
| `cxp` | Profile selector | `cxp deep "explain code"` |
| `cxspeed` | Speed profile (gpt-5-mini) | `cxspeed "quick edit"` |
| `cxdeep` | Deep profile (high reasoning) | `cxdeep "complex refactor"` |
| `cxagent` | Agent profile (no approvals) | `cxagent "run tests"` |

### Helpers

| Command | Description |
|---------|-------------|
| `codex_check_updates` | Check for CLI updates |
| `codex_status` | Show status and config |
| `codex_config` | Open config in editor |

## Profiles

Codex supports multiple profiles for different use cases:

### default (Interactive)
```toml
model = "gpt-5"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```
**Use**: Safe baseline for interactive work

### speed (Fast)
```toml
model = "gpt-5-mini"
```
**Use**: Quick edits, brainstorming, low-cost tasks

### deep (Reasoning)
```toml
model = "gpt-5"
model_reasoning_effort = "high"
```
**Use**: Complex refactors, reviews, architecture

### agent (Autonomous)
```toml
model = "gpt-5-mini"
approval_policy = "never"
sandbox_mode = "workspace-write"
```
**Use**: Non-interactive CI/automation

### maint (Maintenance)
```toml
model = "gpt-5"
approval_policy = "on-request"
```
**Use**: System maintenance (can override with `--sandbox=full`)

## Security & Safety

### Sandbox Modes

- **workspace-write** (recommended): Can read/write within project directory only
- **full**: Full filesystem access (use with caution)

### Approval Policies

- **on-request** (recommended): Prompts before destructive actions
- **never**: Auto-approves (for trusted automation only)

### API Key Management

Never hardcode API keys. Use gopass:

```toml
api_key_cmd = ["gopass", "show", "-o", "openai/api_key"]
preferred_auth_method = "apikey"
```

Store the key:

```bash
gopass insert openai/api_key
```

## Update Management

### Check for Updates

```fish
codex_check_updates
```

### Update to Latest

```bash
npm update -g @openai/codex
```

### Automated Update Script

```bash
~/Development/personal/system-setup-update/scripts/update-codex-cli.sh
```

### Available Versions

Codex CLI has multiple dist-tags:

- **latest** (0.46.0): Stable release (recommended)
- **beta**: Beta builds
- **native**: Native binary builds
- **alpha**: Alpha/experimental builds

Install specific version:

```bash
npm install -g @openai/codex@beta    # Beta
npm install -g @openai/codex@native  # Native
npm install -g @openai/codex@alpha   # Alpha
```

## MCP Integration

Codex supports Model Context Protocol (MCP) servers for extended functionality.

### New in 0.46.0

- **Improved MCP server support** with better authentication
- **Experimental RMCP client**: Add `experimental_use_rmcp_client = true` for enhanced MCP functionality
- **Enabled flag**: Control MCP servers individually with `enabled` field
- **Streamable HTTP servers**: Support for `codex mcp add` command

### Configuration

```toml
# New experimental RMCP client (optional)
experimental_use_rmcp_client = true

[mcp_servers.context]
command = "context7"
args = ["--stdio"]
enabled = true  # Can be toggled per server
timeout = "30s"

[mcp_servers.graphiti_memory]
command = "graphiti-memory"
args = ["--stdio"]
enabled = true
```

### Adding MCP Servers

```bash
# Via CLI (new in 0.46.0)
codex mcp add <server-name>

# Or manually edit ~/.codex/config.toml
```

Ensure MCP server binaries are in your PATH.

## Workflow Examples

### Interactive Deep Work

```bash
codex -p deep --sandbox=workspace-write
# Inside Codex TUI:
/status    # Verify settings
/diff      # Check git workspace
/prompts   # Review instructions
```

### Quick Edit

```bash
cxspeed "refactor this function to use async/await"
```

### Automated Task

```bash
cxagent "run the test suite; if failing, propose minimal fix"
```

### Profile with Override

```bash
codex -p maint --sandbox=full  # Full access for system maintenance
```

## Troubleshooting

### Command not found

Ensure `~/.npm-global/bin` is in your PATH:

```fish
fish_add_path ~/.npm-global/bin
```

Verify installation:

```bash
which codex
codex --version
```

### Version mismatch

Clear npm cache:

```bash
npm cache clean --force
npm update -g @openai/codex
```

### Config not found

Create config:

```bash
codex --init
# Or manually create ~/.codex/config.toml
```

### Sandbox shows unexpected mode

Launch with explicit flag:

```bash
codex --sandbox=workspace-write
```

Known bug: Some builds ignore sandbox_mode in profiles.

### MCP server missing

1. Check binary is in PATH: `which context7`
2. Verify config syntax in `~/.codex/config.toml`
3. Codex silently skips servers that fail to start

### API key prompt

Verify gopass command works:

```bash
gopass show -o openai/api_key
```

### Session cost exceeded

Raise budget in config:

```toml
[budget]
session = 5.00  # Increase as needed
daily = 50.00
```

## Status Checking

### Quick Status

```fish
codex_status
```

Output:
```
Codex CLI Status
================

Version:  codex-cli 0.46.0
Location: /Users/verlyn13/.npm-global/bin/codex
Config:   /Users/verlyn13/.codex/config.toml
Profile:  default
Sandbox:  workspace-write

Config exists: ✓
```

### Full Status (in TUI)

```bash
codex -p deep
/status  # Shows model, approvals, sandbox, budget, MCP servers
```

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CODEX_BIN` | `~/.npm-global/bin/codex` | Path to Codex binary |
| `CODEX_CONFIG_DIR` | `~/.codex` | Config directory |
| `CODEX_PROFILE` | `default` | Default profile |
| `CODEX_SANDBOX` | `workspace-write` | Sandbox mode |

## Related Documentation

- [Official Codex Docs](https://developers.openai.com/codex/cli/)
- [GitHub Repository](https://github.com/openai/codex)
- [Detailed Configuration Guide](../02-configuration/tools/codex-cli.md)
- [System Setup Guide](../README.md)
- [Fish Shell Configuration](../06-templates/chezmoi/dot_config/fish/conf.d/)

## Advanced Features

### Budget Tracking

Codex tracks costs and enforces limits:

```toml
[budget]
session = 3.00  # Max per session
daily = 40.00   # Max per day
```

View current spend: `/status` in TUI

### Reasoning Effort

For complex tasks:

```toml
model_reasoning_effort = "high"  # or "medium", "low"
```

Higher effort = better quality, more cost

### Log Level

Control verbosity:

```toml
log_level = "info"  # debug, info, warn, error
```

Logs saved to `~/.codex/logs/`

### Data Retention

```toml
retain_data = false  # Don't persist conversation history
```

Set to `true` for session continuity (less private)

## Best Practices

1. **Start with defaults**: Use `default` profile first
2. **Verify sandbox**: Always check `/status` before deep work
3. **Use profiles**: Match profile to task (speed for quick, deep for complex)
4. **Gopass for secrets**: Never hardcode API keys
5. **Budget wisely**: Set appropriate limits for your usage
6. **Review diffs**: Use `/diff` before accepting large changes
7. **MCP servers**: Only enable what you need
8. **Update regularly**: Run `codex_check_updates` weekly

## Integration with This Repo

Codex is particularly useful for:

- **Documentation**: Update markdown files, check consistency
- **Scripts**: Write/refactor bash/fish scripts
- **Config**: Generate chezmoi templates
- **Testing**: Write validation scripts
- **Reports**: Generate status reports

Use with project-specific `.envrc`:

```bash
# .envrc
export CODEX_PROFILE="deep"
export CODEX_SANDBOX="workspace-write"

# Point to project-specific AGENTS.md if needed
```

## What's New in 0.46.0

### MCP Enhancements
- **Experimental RMCP client**: Better performance with `experimental_use_rmcp_client = true`
- **Per-server control**: Use `enabled` field to toggle MCP servers individually
- **CLI management**: `codex mcp add` for streamable HTTP servers
- **Auth improvements**: Better bearer token and OAuth support

### CLI Improvements
- **New tools**: `list_dir`, `featgrep_files` for better file operations
- **Better TUI**: Dynamic line numbers, breathing spinner, tree-sitter bash highlighting
- **Enhanced navigation**: UP/ENTER support in interactive mode
- **Improved completions**: Better zsh integration

### Configuration
- Optional `experimental_use_rmcp_client` flag for advanced MCP features
- `enabled` field for granular MCP server control

---

**Last Updated**: 2025-10-09
**Maintainer**: System setup team
**Related Issues**: Track at github.com/openai/codex/issues
