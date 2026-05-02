---
title: Claude Desktop / Cowork Setup
category: setup
component: claude_desktop_setup
status: active
version: 2.0.0
last_updated: 2026-04-23
tags: [claude, desktop, cowork, mcp]
priority: medium
---

# Claude Desktop / Cowork Setup

## Config surfaces

Claude Code CLI and Claude Desktop / Cowork are separate products.
Both are sync targets for the user-level MCP baseline; other config
surfaces remain per-product.

| Surface | Config file | Managed by |
|---------|-------------|------------|
| Claude Code CLI (user) | `~/.claude.json` | `scripts/sync-mcp.sh` |
| Claude Code CLI (project) | `.mcp.json` in project root | per-project |
| Claude Code CLI settings | `~/.claude/settings.json` | direct edit |
| Claude Desktop / Cowork | `~/Library/Application Support/Claude/claude_desktop_config.json` | `scripts/sync-mcp.sh` (`mcpServers` block only) |

## MCP baseline sync

Claude Desktop is a sync target. `scripts/sync-mcp.sh` writes the
user-level MCP baseline into the `mcpServers` block. Everything else
in the file (`globalShortcut`, `preferences`, any user-added servers
not in the managed set) is preserved on every sync.

Claude Desktop's file format historically accepts only stdio entries
(`command` + `args` + `env`; no `type` field). Remote MCP servers are
configured in the app via Settings → Connectors, stored separately.
To keep one programmatically managed surface, the sync writes every
baseline server as stdio:

- `type: "stdio"` wrappers pass through (the `type` field is stripped)
- `type: "http"` remotes are wrapped as
  `~/.local/bin/mcp-npx -y mcp-remote@<ver> <url>`

See [`mcp-config.md`](./mcp-config.md) for the full framework.

## Reload after sync

Claude Desktop reads `claude_desktop_config.json` at launch. After a
sync, fully quit and relaunch Claude Desktop (⌘Q) for new servers to
register. Changes do not hot-reload.

## Related

- [`docs/mcp-config.md`](./mcp-config.md) — MCP framework (scope, sync)
- [Claude Code CLI setup](./claude-cli-setup.md)
