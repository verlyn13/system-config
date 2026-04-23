---
title: MCP Configuration Framework
category: reference
component: mcp_config
status: active
version: 1.2.0
last_updated: 2026-04-23
tags: [mcp, chezmoi, sync-mcp, 1password, scopes]
priority: high
---

# MCP Configuration Framework

How MCP is configured, synced, scoped, and secured on this system. This is
the cross-host framework; integration-specific details (e.g. GitHub) live
in their own focused docs and link back here.

Related live docs:

- [`docs/github-mcp.md`](./github-mcp.md) — GitHub MCP integration (single source of truth)
- [`docs/cloudflare-mcp.md`](./cloudflare-mcp.md) — Cloudflare MCP integration (Codemode, token scope, usage conventions)
- [`docs/secrets.md`](./secrets.md) — 1Password + op policy
- [`docs/agentic-tooling.md`](./agentic-tooling.md) — shell and tool contract

## Architecture in one paragraph

`system-config` owns the user-level MCP baseline across six hosts
(Claude Code CLI, Claude Desktop, Codex CLI, Cursor, Windsurf, Copilot
CLI). A single canonical source file (`scripts/mcp-servers.json`) lists
the shared servers; a sync script (`scripts/sync-mcp.sh`) renders each
host's config file in its native shape. Secrets live in 1Password; `~/.config/mcp/common.env` is a
committable manifest of `op://` URIs resolved at launch via
`op run --env-file=`. Project-specific MCP servers stay inside their
project as committed `.mcp.json` files with `${VAR}` placeholders, never
in user-global config.

## Scope matrix

What goes where.

| What you're configuring | Scope | Where it goes |
|---|---|---|
| Baseline servers shared by every repo (github, brave-search, firecrawl, context7, memory, sequential-thinking) | User | Rendered per-host by `sync-mcp.sh` into each tool's user config |
| Servers every collaborator on a repo should have (repo-local Postgres reader, service-specific Sentry, internal API MCP) | Project | Committed `.mcp.json` (Claude Code), `.cursor/mcp.json` (Cursor), `.codex/config.toml` (Codex, trust opt-in), `.copilot/mcp-config.json` (Copilot). See asymmetries below. |
| Private-to-user experiments on one repo (evaluating a new MCP, a local DB with dev creds) | Local | Claude Code local scope (feature unique to Claude Code); other tools use a `.gitignore`d side file or a personal user-scope entry |
| Any secret referenced by any of the above | Never in config | 1Password; referenced via `${VAR}` at launch or `bearer_token_env_var = "NAME"` |

### Host scope-support asymmetries

| Tool | User | Project | Local | Notes |
|---|---|---|---|---|
| Claude Code CLI | `~/.claude.json` (user scope) | `.mcp.json` at repo root | `~/.claude.json` (local scope) | Only host with a true three-scope model. Local > Project > User precedence. |
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` | — | — | **No project scope.** File format is stdio-only; HTTP remotes wrapped via `mcp-remote`. |
| Codex CLI | `~/.codex/config.toml` | `.codex/config.toml` | — | Project config loaded **only for trusted projects** (opt-in via `projects."/path".trust_level = "trusted"` in user config). |
| Cursor | `~/.cursor/mcp.json` | `.cursor/mcp.json` | — | Project wins on name collision. |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` | — | — | **No project scope.** Repo-shared MCP servers don't reach Windsurf users via a repo file. Documented asymmetry. |
| Copilot CLI | `~/.copilot/mcp-config.json` | `.copilot/mcp-config.json` | — | Ships a built-in GitHub MCP server; our sync does not write a second one. |

## Baseline server inventory

Synced by `scripts/sync-mcp.sh` to all six hosts (with per-host variations where the host's config format or auth model demands):

| Server | Source | Auth | Wrapper required? |
|---|---|---|---|
| `context7` | remote HTTP | none (public) | no |
| `memory` | npm stdio | none | no |
| `sequential-thinking` | npm stdio | none | no |
| `brave-search` | npm stdio | `BRAVE_API_KEY` via `op://Dev/brave-search/api-key` | yes (`~/.local/bin/mcp-brave-search-server`) |
| `firecrawl` | stdio | `FIRECRAWL_API_KEY` via `op://Dev/firecrawl/api-key` | yes (`~/.local/bin/mcp-firecrawl-server`) |
| `github` | remote HTTP (GitHub-hosted) | per-host — see `docs/github-mcp.md` | Cursor only |
| `runpod` | npm stdio (`@runpod/mcp-server`) | `RUNPOD_API_KEY` via `op://Dev/runpod-api/api-key` | yes (`~/.local/bin/mcp-runpod-server`) |
| `runpod-docs` | remote HTTP | none (public) | no |
| `cloudflare` | remote HTTP (Codemode) via `mcp-remote` stdio relay | account-scoped token — see `docs/cloudflare-mcp.md` | yes (`~/.local/bin/mcp-cloudflare-server`) |
| `cloudflare-docs` | remote HTTP | none (public) | no |

## Secret handling

### The common env-file

Chezmoi source: `home/dot_config/mcp/private_common.env` → `~/.config/mcp/common.env` (0600).

Contents are `op://` URIs only, never values. Safe to commit.

```
GITHUB_PAT=op://Dev/github-mcp/token
BRAVE_API_KEY=op://Dev/brave-search/api-key
FIRECRAWL_API_KEY=op://Dev/firecrawl/api-key
RUNPOD_API_KEY=op://Dev/runpod-api/api-key
CLOUDFLARE_API_TOKEN=op://Dev/cloudflare-mcp-jefahnierocks/token
```

### Launch pattern for CLI hosts

```bash
op run --account my.1password.com --env-file=$HOME/.config/mcp/common.env -- claude
op run --account my.1password.com --env-file=$HOME/.config/mcp/common.env -- codex
```

`op run` resolves all `op://` URIs once and injects the three env vars
into the tool's process. Native configs (Claude Code `${GITHUB_PAT}` in
headers, Codex `bearer_token_env_var = "GITHUB_PAT"`, stdio wrappers
reading from env) all pick up the resolved values.

Bare launches (`claude` without `op run`) still work — the stdio wrappers
fall back to `op read` themselves; but Claude Code and Codex native
configs that rely on `${GITHUB_PAT}` will send unresolved placeholders
and get 401s until the user re-launches via `op run`.

### Launch pattern for GUI hosts (Cursor, Windsurf)

GUI apps are launched from Finder/Spotlight/app launchers, not from a
shell that can be wrapped with `op run`. Two approaches:

- **Cursor**: uses the `mcp-github-server` stdio wrapper. The wrapper
  invokes `op read` in its own subprocess at each launch, independent of
  how Cursor itself was started. No shell wrapping needed.
- **Windsurf**: uses native OAuth 2.1 + PKCE for GitHub remote MCP (since
  1.12.41, Dec 2025). No PAT involvement at all. One-time in-app consent
  on first MCP connect; Windsurf manages refresh tokens thereafter.

### Why not export secrets globally?

Two durable rules in this repo:

- Never write a secret value into a persistent user-level config file.
- Never export a secret globally in the shell (zshrc, zshenv).

`op run --env-file` satisfies both: the env vars live only in the launched
tool's process memory for the duration of that process. The source file
contains `op://` URIs, not values.

## Sync responsibilities

`scripts/sync-mcp.sh` manages these surfaces:

- Claude Code CLI: `~/.claude.json` (user scope)
- Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`
  (only the `mcpServers` block; `globalShortcut`, `preferences`, and any
  user-added servers outside the managed set are preserved)
- Cursor: `~/.cursor/mcp.json`
- Windsurf: `~/.codeium/windsurf/mcp_config.json`
- Copilot CLI: `~/.copilot/mcp-config.json`
- Codex CLI: `~/.codex/config.toml` (managed block bracketed by
  `# BEGIN system-config managed MCP servers` / `# END …`)

It does **not**:

- write any secret value into any file
- touch project-level MCP configs
- manage Gemini CLI (currently unmanaged)

### Claude Desktop shape note

Claude Desktop's `claude_desktop_config.json` historically accepts only
stdio entries (`command` + `args` + `env`; no `type` field). Remote MCP
servers are configured in the app via Settings → Connectors, stored
separately. To keep one programmatically managed surface, `sync-mcp.sh`
writes every baseline server in Claude Desktop as stdio:

- Our `type: "stdio"` wrappers pass through (the `type` field is stripped)
- Our `type: "http"` remotes are wrapped via `npx -y mcp-remote@<ver> <url>`

The `mcp-remote` version is pinned in `sync-mcp.sh` as `MCP_REMOTE_VERSION`
and matches the version used by the auth-required wrappers. Claude
Desktop's Electron enriches PATH before spawning MCP children so
`~/.local/bin` wrappers and `op` resolve correctly.

## Project-level MCP servers

When a repo needs team-shared MCP servers, commit them in the per-tool
project file with `${VAR}` placeholders for any secret. Example
`.mcp.json` for Claude Code:

```json
{
  "mcpServers": {
    "sentry": { "type": "http", "url": "https://mcp.sentry.dev/mcp" },
    "postgres-dev": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub", "--dsn", "${DEV_DB_URL:-postgresql://localhost/dev}"]
    }
  }
}
```

Add a project `.envrc` that loads `DEV_DB_URL` from 1Password via
`op read`, or extend the project to use `op run` at launch. Do not put
secret values in `.mcp.json` under any circumstances.

Project `.gitignore` should include:

```
.claude/settings.local.json
.cursor/mcp.local.json
.codex/auth.json
```

## Verification

```bash
# Resolved env from the common manifest (no values printed)
op run --account my.1password.com --env-file=$HOME/.config/mcp/common.env -- \
  bash -c 'for v in GITHUB_PAT BRAVE_API_KEY FIRECRAWL_API_KEY RUNPOD_API_KEY CLOUDFLARE_API_TOKEN; do
    if [[ -n "${!v:-}" ]]; then echo "$v resolved"; else echo "$v MISSING"; fi; done'

# Dry-run sync
./scripts/sync-mcp.sh --dry-run

# Per-host github shape check
jq '.mcpServers.github // "absent"' \
  ~/.claude.json ~/.cursor/mcp.json ~/.codeium/windsurf/mcp_config.json \
  ~/.copilot/mcp-config.json
python3 -c "import tomllib,json; print(json.dumps(tomllib.load(open('/Users/verlyn13/.codex/config.toml','rb'))['mcp_servers']['github'], indent=2))"
```

## What's intentionally not in this doc

- GitHub-specific PAT scopes, toolset list, URL, rotation policy →
  [`docs/github-mcp.md`](./github-mcp.md)
- 1Password account / vault policy → [`docs/secrets.md`](./secrets.md)
- Shell and tool-runtime contract → [`docs/agentic-tooling.md`](./agentic-tooling.md)
