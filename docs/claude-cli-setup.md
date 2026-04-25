---
title: Claude CLI Setup
category: reference
component: claude_cli_setup
status: active
version: 3.2.0
last_updated: 2026-04-25
tags: [cli, claude, ai, native, mcp, zsh]
priority: high
---

# Claude Code CLI Setup

Keep the repo-managed surface small and let Claude Code own the rest.

## Config Planes

Claude Code CLI and Claude Desktop are separate products with their own
config files. Both are sync targets for the user-level MCP baseline;
other surfaces remain per-product.

- Claude Code CLI user MCP config: `~/.claude.json`
- Claude Code project MCP config: `.mcp.json`
- Claude Code settings: `~/.claude/settings.json`
- Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`

Only `~/.claude.json` is touched by `scripts/sync-mcp.sh`, and only for the approved global MCP baseline.

As of Claude Code `2.1.119` (April 23, 2026), `/config` settings such as
`theme`, `editor mode`, and `verbose` persist to `~/.claude/settings.json` and
participate in project/local/policy precedence. This machine currently runs
Claude Code `2.1.120`; verify future location changes against `claude --version`
and the matching release notes before moving keys between config files.

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
- Claude Desktop is also a sync target; see
  [`docs/claude-desktop-setup.md`](./claude-desktop-setup.md)

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
| `~/.claude/settings.json` | User settings, permissions, and current `/config`-persisted preferences |
| `~/.claude.json` | User MCP baseline and tool-native local state |
| `.mcp.json` | Project MCP servers |

## Troubleshooting

- `which claude` should resolve to `~/.local/bin/claude` or the native install path.
- If a project server is missing, check the project’s `.mcp.json` before touching `~/.claude.json`.
- If a global auth-required server fails, fix the env var or 1Password item rather than editing `~/.claude.json`.
- If Claude reports `Expected boolean, but received string` for `~/.claude/settings.json`, fix the value to a real JSON boolean. `verbose` is a known offender on upgraded installs.

## Related

- [`docs/secrets.md`](./secrets.md)
- [`docs/agentic-tooling.md`](./agentic-tooling.md)
- [Official Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/overview)
- [Claude Code Settings Reference](./claude-code-cli-settings-official.md)
- [Claude Desktop / Cowork Setup](./claude-desktop-setup.md)
