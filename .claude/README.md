---
title: Readme
category: reference
component: readme
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

# Claude Project Configuration

This directory contains project-specific configuration for Claude Code CLI and Claude Desktop.

## Files

- `config.json` - Main configuration file with tool permissions and MCP servers
- `claude-wrapper.sh` - Executable wrapper that applies project configuration
- `environment.sh` - Environment setup script with helpful aliases
- `README.md` - This documentation file

## Usage

### Quick Start

```bash
# Source the environment (adds aliases)
source .claude/environment.sh

# Run Claude with project configuration
claude-project

# Or run the wrapper directly
./.claude/claude-wrapper.sh
```

### Configuration Management

```bash
# View current configuration
claude-config

# Edit configuration
claude-edit-config

# Regenerate configuration with different template
claude-project-setup.sh . web        # Web development project
claude-project-setup.sh . restricted # Read-only access
claude-project-setup.sh . permissive # Full access
claude-project-setup.sh . default    # Balanced permissions
```

## Configuration Schema

The `config.json` file supports:

- `allowedTools`: Array of tool names or "*" for all tools
- `disallowedTools`: Array of tool names to explicitly deny
- `mcpServers`: Project-specific MCP server configurations
- `customInstructions`: Project metadata and preferences

## Integration

This configuration integrates with:
- Claude Code CLI via command-line flags
- Project-specific MCP servers
- Local development environment
