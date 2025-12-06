---
title: GitHub Copilot CLI Setup
category: reference
component: copilot_cli_setup
status: active
version: 1.0.0
last_updated: 2025-11-09
tags: []
priority: medium
---

# GitHub Copilot CLI Setup

This document describes the installation and configuration of GitHub Copilot CLI in this development environment.

## Overview

- **Installation method**: npm global (`@github/copilot`)
- **Version**: 0.0.354 (latest)
- **Location**: `~/.npm-global/bin/copilot`
- **Configuration**: `~/.copilot/` (managed automatically)
- **Fish config**: `~/.config/fish/conf.d/18-copilot.fish`
- **Documentation**: https://docs.github.com/copilot/concepts/agents/about-copilot-cli

## Features

GitHub Copilot CLI brings AI-powered coding assistance directly to your command line:

- **Terminal-native development**: Work with Copilot coding agent directly in your command line
- **GitHub integration**: Access repositories, issues, and pull requests using natural language
- **Agentic capabilities**: Build, edit, debug, and refactor code with AI assistance
- **MCP-powered extensibility**: Ships with GitHub's MCP server by default, supports custom MCP servers
- **Full control**: Preview every action before execution

## Requirements

- **Node.js**: v22 or higher (we have Node 24, ✓)
- **npm**: v10 or higher (we have npm 11, ✓)
- **Active Copilot subscription**: See [Copilot plans](https://github.com/features/copilot/plans)

## Installation

### Manual Installation

```bash
npm install -g @github/copilot
```

### Verify Installation

```bash
copilot --version
# Output: 0.0.354
```

## Configuration

### Fish Shell Integration

**Active config**: `~/.config/fish/conf.d/18-copilot.fish`

### Environment Variables

```fish
COPILOT_BIN="~/.npm-global/bin/copilot"      # Copilot binary location
COPILOT_CONFIG_DIR="~/.copilot"              # Config directory
COPILOT_DEFAULT_MODEL="claude-sonnet-4-5"    # Default model
```

Override per-project in `.envrc`:

```bash
export COPILOT_DEFAULT_MODEL="gpt-5"
```

### Available Models

- `claude-sonnet-4-5` (default) - Latest Claude model
- `claude-sonnet-4` - Previous Claude model
- `gpt-5` - OpenAI's latest model

Use the `/model` slash command within copilot to switch models.

## Usage

### Launching Copilot

```bash
# Launch with default settings
copilot

# Launch with banner
ghcpb

# Quick alias
ghcp
```

On first launch, you'll see an animated banner. To see it again, use `copilot --banner`.

### Authentication

If not already logged in:

1. Launch copilot: `copilot`
2. Enter `/login` command
3. Follow on-screen instructions to authenticate

### Authentication with Personal Access Token (PAT)

You can also authenticate using a fine-grained PAT with "Copilot Requests" permission:

1. Visit https://github.com/settings/personal-access-tokens/new
2. Under "Permissions," click "add permissions" and select "Copilot Requests"
3. Generate your token
4. Set environment variable: `export GH_TOKEN="your-token"` or `export GITHUB_TOKEN="your-token"`

### Basic Commands

```bash
# Launch Copilot in current directory
copilot

# Within Copilot, use slash commands:
/help         # Get help
/login        # Authenticate with GitHub
/model        # Select a different model (Claude Sonnet 4.5, Claude Sonnet 4, GPT-5)
/feedback     # Submit confidential feedback survey
```

### Monthly Quota

Each prompt you submit reduces your monthly quota of premium requests by one. See [About premium requests](https://docs.github.com/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests).

## Fish Shell Aliases

### Primary Commands

- `copilot` - Launch GitHub Copilot CLI
- `ghcp` - Quick alias for copilot
- `ghcpb` - Launch with banner

### Helper Functions

- `copilot_check_updates` - Check for CLI updates
- `copilot_status` - Show installation status and configuration
- `copilot_model [model]` - View or set default model (session-only)

## Updating

### Check for Updates

```bash
copilot_check_updates
```

### Manual Update

```bash
npm update -g @github/copilot
```

### Automated Update Script

```bash
~/Development/personal/system-setup-update/scripts/update-copilot-cli.sh
```

## Troubleshooting

### CLI Not Found

If copilot command is not found after installation:

```fish
# Check if npm global bin is in PATH
echo $PATH | tr " " "\n" | grep npm-global
# Should show: /Users/verlyn13/.npm-global/bin

# Reload Fish configuration
source ~/.config/fish/conf.d/18-copilot.fish
```

### Authentication Issues

If you're having trouble authenticating:

1. Ensure you have an active Copilot subscription
2. Check if your organization allows Copilot CLI (see organization settings)
3. Try authenticating with a PAT instead of device flow

### Model Selection Not Working

Model selection via environment variables is session-only. For persistent changes, use the `/model` command within copilot.

## Integration with Other Tools

### Use with direnv

Set per-project model in `.envrc`:

```bash
export COPILOT_DEFAULT_MODEL="gpt-5"
```

### Use with mise

Copilot works seamlessly with mise-managed Node.js installations.

## Best Practices

1. **Keep updated**: GitHub Copilot CLI is in public preview and updates frequently
2. **Use appropriate models**: Claude Sonnet 4.5 for balanced performance, GPT-5 for specific tasks
3. **Preview actions**: Always review proposed changes before execution
4. **Save conversations**: Use meaningful names for conversation history
5. **Manage quota**: Be mindful of your monthly premium request quota

## Additional Resources

- [Official Documentation](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
- [GitHub Copilot Plans](https://github.com/features/copilot/plans)
- [Report Issues](https://github.com/github/copilot-cli/issues)

## Status

✓ **Installed**: 0.0.354
✓ **Configured**: Fish shell integration
✓ **Available**: `copilot`, `ghcp`, `ghcpb` commands
⚠ **Authentication**: Required on first use (use `/login` command)
