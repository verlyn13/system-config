---
title: Claude Desktop / Cowork Setup
category: setup
component: claude_desktop_setup
status: active
version: 1.0.0
last_updated: 2026-02-27
tags: [claude, desktop, cowork, mcp]
priority: medium
---

# Claude Desktop / Cowork Setup

## Config Plane Separation

Claude Code CLI and Claude Desktop / Cowork are **completely separate products** with non-overlapping config surfaces. Agents and scripts in this repo should never cross these planes.

| Surface | Config File | Managed By |
|---------|-------------|------------|
| Claude Code CLI (user) | `~/.claude.json` | `ai-tools/sync-to-tools.sh` |
| Claude Code CLI (project) | `.mcp.json` in project root | Per-project |
| Claude Code CLI settings | `~/.claude/settings.json` | Direct edit |
| Claude Desktop / Cowork | `~/Library/Application Support/Claude/claude_desktop_config.json` | UI only |

**Never add servers to the Desktop JSON to make them available in the CLI — they are completely isolated.**

## Claude Desktop Config Location

```
~/Library/Application Support/Claude/claude_desktop_config.json
```

## Recommended Config

```json
{
  "mcpServers": {},
  "globalShortcut": "Ctrl+Space",
  "preferences": {
    "startAtLogin": true,
    "showInMenuBar": true
  }
}
```

`mcpServers` is deliberately empty. See "Why mcpServers stays empty" below.

## Three Config Layers

Claude Desktop / Cowork is configured via three UI surfaces — not via the JSON config file:

1. **Desktop Extensions** (Settings → Extensions): First-party integrations (Google Drive, Notion, etc.). Auto-update, managed by Anthropic. Add via UI.
2. **Web Connectors** (Settings → Connectors): OAuth-based connections to web services. Managed per-account in the UI.
3. **Plugins** (Cowork sidebar): Context-aware tools available within Cowork sessions. Managed in the sidebar.

## Why `mcpServers` Stays Empty

- **Extensions auto-update**: Anthropic-managed Extensions don't require manual server config or token management.
- **Avoid token overhead**: Custom MCP servers in Desktop add token cost to every Cowork session.
- **mcp-registry bug**: As of 2026-02-27, adding servers via the mcp-registry UI can trigger a race condition that corrupts the config file. Workaround: edit the JSON directly only if strictly necessary, then restart Desktop.
- **OAuth scope bug**: The OAuth connector occasionally requests broader scopes than needed on first auth. Re-authorizing with a fresh token resolves it.

## Not Managed via sync-to-tools.sh

`ai-tools/sync-to-tools.sh` syncs to Claude Code CLI and other terminal dev tools only. Claude Desktop is not a sync target. Do not add it to the sync script.

## Known Issues (as of 2026-02-27)

| Issue | Workaround |
|-------|-----------|
| mcp-registry race condition corrupts config | Edit `claude_desktop_config.json` directly; restart Desktop |
| OAuth connector requests excess scopes | Re-authorize with a fresh token |
| Extensions not appearing after install | Quit and relaunch Desktop |

## Related

- [Claude Code CLI Setup](./claude-cli-setup.md)
- [MCP Server Management](../AGENTS.md#mcp-server-management)
