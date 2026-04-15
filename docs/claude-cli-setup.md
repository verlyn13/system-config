---
title: Claude CLI Setup
category: reference
component: claude_cli_setup
status: active
version: 3.0.0
last_updated: 2026-04-08
tags: [cli, claude, ai, native, mcp, zsh]
priority: high
---

# Claude Code CLI Setup

Keep the repo-managed surface small and let Claude Code own the rest.

## Config Planes

Claude Code CLI and Claude Desktop are separate products with separate config planes.

- Claude Code CLI user MCP config: `~/.claude.json`
- Claude Code project MCP config: `.mcp.json`
- Claude Code settings: `~/.claude/settings.json`
- Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`

Only `~/.claude.json` is touched by `scripts/sync-mcp.sh`, and only for the approved global MCP baseline.

## Installation

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

## Shell Assumption

This repo assumes Claude Code runs under zsh. Do not add fish helpers or fish startup snippets for Claude Code here.

## MCP Policy

- Global baseline: synced by `scripts/sync-mcp.sh`
- Project-specific servers: `.mcp.json`
- Secrets: env vars or 1Password CLI wrappers only
- Desktop is not a sync target

## Updates

Use Claude’s native updater or `system-update`:

```bash
claude update
```

## File Locations

| Path | Purpose |
|------|---------|
| `~/.local/bin/claude` | Binary |
| `~/.local/share/claude/` | Versions and data |
| `~/.claude/settings.json` | User settings |
| `~/.claude.json` | User MCP baseline |
| `.mcp.json` | Project MCP servers |

## Troubleshooting

- `which claude` should resolve to `~/.local/bin/claude` or the native install path.
- If a project server is missing, check the project’s `.mcp.json` before touching `~/.claude.json`.
- If a global auth-required server fails, fix the env var or 1Password item rather than editing `~/.claude.json`.

## Related

- [`docs/agentic-tooling.md`](./agentic-tooling.md)
- [Official Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/overview)
- [Claude Code Settings Reference](./claude-code-cli-settings-official.md)
- [Claude Desktop / Cowork Setup](./claude-desktop-setup.md)
