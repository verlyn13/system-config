---
title: Claude Desktop / Cowork Setup
category: setup
component: claude_desktop_setup
status: active
version: 1.0.0
last_updated: 2026-04-08
tags: [claude, desktop, cowork, mcp]
priority: medium
---

# Claude Desktop / Cowork Setup

## Config Plane Separation

Claude Code CLI and Claude Desktop / Cowork are separate products with separate config surfaces. This repo manages the CLI MCP baseline only.

| Surface | Config File | Managed By |
|---------|-------------|------------|
| Claude Code CLI (user) | `~/.claude.json` | `scripts/sync-mcp.sh` |
| Claude Code CLI (project) | `.mcp.json` in project root | Per-project |
| Claude Code CLI settings | `~/.claude/settings.json` | Direct edit |
| Claude Desktop / Cowork | `~/Library/Application Support/Claude/claude_desktop_config.json` | UI only |

Never add servers to the Desktop JSON to make them available in the CLI. The planes are isolated.

## Policy

- Claude Desktop is not a sync target for `scripts/sync-mcp.sh`.
- Do not use Desktop JSON as a backdoor for CLI MCP config.
- Prefer tool-native extensions and connectors in Desktop instead of custom server sprawl.

## Related

- [`docs/agentic-tooling.md`](./agentic-tooling.md)
- [Claude Code CLI Setup](./claude-cli-setup.md)
- [MCP Server Management](../AGENTS.md#mcp-ownership)
