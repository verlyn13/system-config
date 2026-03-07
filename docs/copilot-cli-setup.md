---
title: GitHub Copilot CLI Setup
category: reference
component: copilot_cli_setup
status: active
version: 2.0.0
last_updated: 2026-02-05
tags: [cli, copilot, ai, npm]
priority: medium
---

# GitHub Copilot CLI Setup

Minimal configuration for GitHub Copilot CLI.

## Overview

- **Installation**: `npm install -g @github/copilot`
- **Location**: `~/.npm-global/bin/copilot`
- **Configuration**: `~/.copilot/` (managed automatically by CLI)
- **Fish config**: `~/.config/fish/conf.d/18-copilot.fish`
- **Official docs**: https://docs.github.com/copilot/concepts/agents/about-copilot-cli

## Requirements

- Node.js v22+
- Active GitHub Copilot subscription

## Installation

```bash
npm install -g @github/copilot
```

Verify:

```bash
copilot --version
```

## Configuration Philosophy

**Minimal customization**: Copilot CLI manages its own configuration. We only provide shell aliases.

### What We Configure

- Fish shell aliases (`ghcp`, `ghcpb`)
- Helper functions (`copilot_check_updates`, `copilot_status`)

### What We Don't Configure

- Model selection (use `/model` command within CLI)
- Authentication (use `/login` command)
- Settings (managed by Copilot CLI itself)

## Commands

| Command | Description |
|---------|-------------|
| `copilot` | Launch Copilot CLI |
| `ghcp` | Quick alias |
| `ghcpb` | Launch with banner |
| `copilot_check_updates` | Check for updates |
| `copilot_status` | Show status |

## Authentication

On first launch:

```bash
copilot
/login  # Follow on-screen instructions
```

Or use a Personal Access Token with "Copilot Requests" permission:

```bash
export GH_TOKEN="your-token"
# or
export GITHUB_TOKEN="your-token"
```

## Updates

```bash
# Check for updates
copilot_check_updates

# Update
npm update -g @github/copilot
```

## Troubleshooting

### CLI Not Found

```bash
# Ensure npm-global is in PATH
fish_add_path ~/.npm-global/bin

# Reload config
source ~/.config/fish/conf.d/18-copilot.fish
```

### Authentication Issues

1. Verify active Copilot subscription
2. Check organization permissions
3. Try PAT authentication instead of device flow

## Related

- [Official Copilot CLI Docs](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
- [Copilot Plans](https://github.com/features/copilot/plans)
