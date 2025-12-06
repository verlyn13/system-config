---
title: Codex Cli Setup
category: reference
component: codex_cli_setup
status: active
version: 2.0.0
last_updated: 2025-12-05
tags: []
priority: medium
---


# Codex CLI Setup

This document captures how we install Codex CLI and point it at the global config file that Codex
expects. Codex uses a single TOML config shared by the CLI and IDE.

## Overview

- **Installation**: Homebrew (`brew install openai/openai/codex`)
- **Binary location**: Usually `/opt/homebrew/bin/codex` (or in PATH via brew)
- **Config**: Single file at `~/.codex/config.toml` (not managed by chezmoi)
- **Env hook**: `CODEX_CONFIG=$HOME/.codex/config.toml` (for global default)
- **Fish config**: `~/.config/fish/conf.d/12-codex.fish` (chezmoi-managed)
- **Reference config**: `02-configuration/tools/codex-cli.md` (authoritative baseline)

## Installation

Install via Homebrew (preferred for 2025 builds):

```bash
brew install openai/openai/codex
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
CODEX_BIN="/opt/homebrew/bin/codex"              # Brew location (fallbacks to PATH)
CODEX_CONFIG="$HOME/.codex/config.toml"          # Single config file Codex reads
CODEX_PROFILE="dev"                              # Default profile inside config
CODEX_SANDBOX="workspace-write"                  # Sandbox mode
```

Override per-project with `CODEX_CONFIG` so Codex reads a local file:

```bash
export CODEX_CONFIG="$PWD/.codex/config.toml"
```

### Codex Configuration File

**Location**: `~/.codex/config.toml`

This file is **not managed by chezmoi**. Use the baseline in
`02-configuration/tools/codex-cli.md` and edit locally as needed.

### Initial Setup

First-time setup:

```bash
mkdir -p ~/.codex
touch ~/.codex/config.toml
# Populate using the recommended block from 02-configuration/tools/codex-cli.md
```

## Commands

### Aliases

| Command | Description | Usage |
|---------|-------------|-------|
| `codex` | Full Codex CLI | `codex -p dev` |
| `cx` | Quick alias | `cx "fix this bug"` |
| `cxp` | Profile selector | `cxp dev "explain code"` |
| `cxfast` | Fast profile (lightweight) | `cxfast "quick edit"` |
| `cxreview` | Review profile (high scrutiny) | `cxreview "code review"` |

### Helpers

| Command | Description |
|---------|-------------|
| `codex_check_updates` | Check for CLI updates |
| `codex_status` | Show status and config |
| `codex_config` | Open config in editor |

## Profiles (recommended set)

Profiles live inside the single config file. Suggested pattern (from the global baseline):

- `dev`: High-effort reasoning, approvals on-request.
- `fast`: Cheaper model, untrusted approval policy for quick edits.
- `review`: High-end model with `approval_policy=never` for deterministic reviews.

## Security & Safety

### Sandbox Modes

- **workspace-write** (recommended): Can read/write within project directory only
- **full**: Full filesystem access (use with caution)

### Approval Policies

- **on-request** (recommended): Prompts before destructive actions.
- **never**: Auto-approves; only for trusted automation or review profiles.

### API Key Management

Never hardcode API keys. Use env vars or gopass:

```toml
[model_providers.openai]
env_key = "OPENAI_API_KEY"
```

In `.envrc`:

```bash
export OPENAI_API_KEY="$(gopass show openai/api-key)"
```

## Update Management

### Check for Updates

```fish
codex_check_updates
```

### Automated Update Script

```bash
~/Development/personal/system-setup-update/scripts/update-codex-cli.sh
```

## MCP Integration

Codex supports Model Context Protocol (MCP) servers for extended functionality.

### Configuration

```toml
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
```

### Adding MCP Servers

```bash
codex mcp add <server-name>

# Or manually edit CODEX_CONFIG / ~/.codex/config.toml
```

Ensure MCP server binaries are in your PATH.

## Workflow Examples

### Interactive Deep Work

```bash
codex -p dev --sandbox=workspace-write
# Inside Codex TUI:
/status    # Verify settings
/diff      # Check git workspace
/prompts   # Review instructions
```

### Quick Edit

```bash
cxfast "refactor this function to use async/await"
```

### Automated Task

```bash
codex -p review exec "run the test suite; if failing, propose minimal fix"
```

### Profile with Override

```bash
codex -p dev --sandbox=full  # Full access for system maintenance (trusted only)
```

## Troubleshooting

### Command not found

Ensure your brew prefix is in PATH:

```fish
fish_add_path /opt/homebrew/bin
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
mkdir -p ~/.codex
touch ~/.codex/config.toml
```

### Sandbox shows unexpected mode

Launch with explicit flag:

```bash
codex --sandbox=workspace-write
```

Known bug: Some builds ignore sandbox_mode in profiles.

### MCP server missing

1. Check binary is in PATH: `which context7`
2. Verify config syntax in `CODEX_CONFIG`
3. Codex silently skips servers that fail to start

### API key prompt

Verify gopass command works:

```bash
gopass show openai/api-key
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

Version:  codex-cli 0.63.0
Location: /opt/homebrew/bin/codex
Config:   /Users/verlyn13/.codex/config.toml
Profile:  dev
Sandbox:  workspace-write

Config exists: ✓
```

### Full Status (in TUI)

```bash
codex -p dev
/status  # Shows model, approvals, sandbox, MCP servers
```

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CODEX_BIN` | `/opt/homebrew/bin/codex` | Path to Codex binary |
| `CODEX_CONFIG` | `~/.codex/config.toml` | Config file (single source) |
| `CODEX_PROFILE` | `dev` | Default profile |
| `CODEX_SANDBOX` | `workspace-write` | Sandbox mode |

## Related Documentation

- [Official Codex Docs](https://developers.openai.com/codex/cli/)
- [GitHub Repository](https://github.com/openai/codex)
- [Detailed Configuration Guide](../02-configuration/tools/codex-cli.md)
- [System Setup Guide](../README.md)
- [Fish Shell Configuration](../06-templates/chezmoi/dot_config/fish/conf.d/)

## Best Practices

1. Export `CODEX_CONFIG` globally in your shell startup so Codex always finds the right file.
2. Override `CODEX_CONFIG` per project via `.envrc` or wrapper scripts.
3. Keep `sandbox_mode=workspace-write` unless doing trusted system maintenance.
4. Forward only the env vars you need via `[shell_environment_policy]`.
5. Verify `/status` at the start of long sessions and after changing profiles.

---

**Last Updated**: 2025-12-05
**Maintainer**: System setup team
