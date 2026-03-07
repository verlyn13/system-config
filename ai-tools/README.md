# AI Tools Configuration

Centralized user-level configuration for AI development tools.

## Structure

```
ai-tools/
├── mcp-servers.json    # Global MCP server definitions
├── sync-to-tools.sh    # Propagation script
└── README.md
```

## MCP Server Locations

| Tool | Config Path |
|------|-------------|
| Claude Code CLI | `~/.claude.json` (mcpServers key) |
| Cursor | `~/.cursor/mcp.json` |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` |
| Copilot CLI | `~/.copilot/mcp-config.json` |
| Codex CLI | `~/.codex/config.toml` |

## Usage

```bash
# Dry run (show what would change)
./sync-to-tools.sh --dry-run

# Sync global MCP servers to all tools
./sync-to-tools.sh
```

## Global MCP Servers

Defined in `mcp-servers.json`:

| Server | Type | Purpose |
|--------|------|---------|
| context7 | HTTP | Developer documentation lookup |
| github | STDIO | GitHub operations (PRs, issues, repos) |
| memory | STDIO | Cross-session persistent memory |
| sequential-thinking | STDIO | Complex problem decomposition |
| brave-search | STDIO | Web search (requires Brave API key) |
| firecrawl | STDIO | Web scraping/crawling (requires Firecrawl API key) |

## Secret Management

API keys are pulled from gopass at sync time:

| Placeholder | Gopass Path |
|-------------|-------------|
| `${GITHUB_TOKEN}` | `github/dev-tools-token` |
| `${BRAVE_API_KEY}` | `brave/api-key` |
| `${FIRECRAWL_API_KEY}` | `firecrawl/api-key` |

To add missing secrets:
```bash
gopass insert brave/api-key
gopass insert firecrawl/api-key
```

## Adding New Servers

1. Add to `mcp-servers.json`
2. Run `./sync-to-tools.sh`

Use `_description` prefix for metadata that should not be synced:

```json
{
  "my-server": {
    "url": "https://example.com/mcp",
    "_description": "This won't be copied to tool configs"
  }
}
```

## Project-Specific Servers

Project MCP servers belong in each tool's project config, not here:

- Claude Code: `.mcp.json` in project root
- Codex: Project-level `config.toml`

This directory only manages **global** user-level servers.
