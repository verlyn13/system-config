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
- **Version**: 2.0.34 (latest)
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

### Configuration Architecture

Claude Code CLI configuration is managed at two levels:

#### 1. Global Configuration (Direct Management)

**Fish Shell Environment** (managed via chezmoi):
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/10-claude.fish.tmpl`
- **Active config**: `~/.config/fish/conf.d/10-claude.fish`
- **Update**: Via `chezmoi apply`

**Global Claude Settings** (direct management - NOT chezmoi):
- **Location**: `~/.claude/`
- **Management**: Direct editing (not managed by chezmoi)
- **Templates**: `06-templates/chezmoi/dot_claude/` (reference only, for future migration)
- Includes:
  - `settings.json` - Tool permissions, environment variables
  - `CLAUDE.md` - Global development context
  - `commands/` - Slash commands (dev, ops, research)
  - `agents/` - Agent definitions (architect, security, tester, etc.)
  - `README.md` - Configuration documentation

**Why not chezmoi?** Claude Code CLI is rapidly evolving. Direct management provides flexibility during active development. See [Migration Guide](./CLAUDE-CONFIG-CHEZMOI-MIGRATION.md) for future chezmoi migration.

#### 2. Project-Specific Configuration

Projects can override global settings with local `.claude/` directories:
- `.claude/config.json` - Project tool permissions
- `.claude/CLAUDE.md` - Project-specific context
- `.claude/settings.json` - Project settings overrides

Apply Fish shell changes with:

```bash
chezmoi apply ~/.config/fish/conf.d/10-claude.fish
```

Edit Claude configuration directly:

```bash
nano ~/.claude/settings.json
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
| `ccm` | Multi-directory support | `ccm ~/backend ~/frontend` |
| `cco` | Use Opus model | `cco "complex analysis"` |
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

### Model & Auth Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_BIN` | `~/.npm-global/bin/claude` | Path to Claude binary |
| `CLAUDE_DEFAULT_MODEL` | `claude-sonnet-4-5-20250929` | Default model for `cc` |
| `CLAUDE_PLAN_MODEL` | `claude-opus-4-20250514` | Model for `ccplan` |
| `CLAUDE_AUTH` | `subscription` | Auth mode (subscription/api) |
| `CLAUDE_API_KEY_CMD` | `gopass show anthropic/api-keys/opus` | Command to fetch API key |

### Performance & Behavior

| Variable | Default | Description |
|----------|---------|-------------|
| `BASH_DEFAULT_TIMEOUT_MS` | `600000` | Default Bash timeout (10 minutes) |
| `BASH_MAX_TIMEOUT_MS` | `1800000` | Maximum Bash timeout (30 minutes) |
| `MCP_TIMEOUT` | `30000` | MCP server timeout (30 seconds) |
| `MCP_TOOL_TIMEOUT` | `120000` | MCP tool timeout (2 minutes) |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | `true` | Stay in project directory |
| `CLAUDE_BASH_NO_LOGIN` | `1` | Skip login shell for speed |
| `USE_BUILTIN_RIPGREP` | `1` | Use built-in ripgrep |
| `DISABLE_INTERLEAVED_THINKING` | `false` | Enable thinking mode |
| `CLAUDE_CODE_EXIT_AFTER_STOP_DELAY` | `5000` | SDK mode auto-exit delay |
| `CLAUDE_CODE_AUTO_CONNECT_IDE` | `true` | Auto-connect to IDE |

### Privacy & Telemetry

| Variable | Default | Description |
|----------|---------|-------------|
| `DISABLE_AUTOUPDATER` | `1` | Disable auto-updater |
| `DISABLE_TELEMETRY` | `true` | Disable telemetry |
| `DISABLE_ERROR_REPORTING` | `false` | Allow error reports |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `true` | Minimize network traffic |

## Global Configuration Features

### Hooks

Hooks automatically run commands at specific points in Claude's workflow:

- **SessionStart**: Run `mise current` to show runtime versions
- **PostToolUse**: Auto-format files with Biome (JS/TS), ruff/black (Python), rustfmt (Rust), gofmt (Go)
- **PreCompact**: Show git diff before conversation compaction
- **SessionEnd**: Show final git status

### Agents

Pre-configured agents for specialized tasks:

- **@architect**: System design and architecture (Opus)
- **@security**: Security analysis and vulnerability scanning
- **@tester**: Test generation and coverage
- **@docs**: Technical documentation writing
- **@reviewer**: Code review and quality analysis
- **@explorer**: Fast codebase exploration (Haiku)

Usage: `claude "@security review this endpoint"`

### Slash Commands

Autonomous workflow templates:

- **/dev:feature** - Feature development workflow
- **/dev:pr-review** - Pull request review
- **/dev:refactor** - Safe incremental refactoring
- **/dev:test-driven** - TDD workflow
- **/ops:debug** - Systematic debugging
- **/ops:deploy** - Deployment workflow
- **/research:investigate** - Deep technical investigation

Usage: `claude /dev:feature "Add user authentication"`

### Formatting Standards

- **JavaScript/TypeScript**: Biome v2.3+ (NOT Prettier)
- **Python**: ruff (preferred) or black
- **Rust**: rustfmt
- **Go**: gofmt
- **Fish**: fish_indent
- **Markdown**: Biome

All formatting happens automatically via PostToolUse hooks.

### MCP Servers

Global MCP servers configured:

- **filesystem**: Access to home directory and repos
- **github**: GitHub integration (requires GITHUB_TOKEN)
- **git**: Git operations
- **brave-search**: Web search (requires BRAVE_API_KEY)
- **postgres**: Database access (requires connection string)
- **docker**: Container management

## Related Documentation

- [Official Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/overview)
- [System Setup Guide](../README.md)
- [Chezmoi Templates](./chezmoi-templates.md)
- [Fish Shell Configuration](../06-templates/chezmoi/dot_config/fish/conf.d/)
- [Global Claude Context](../06-templates/chezmoi/dot_claude/CLAUDE.md)
