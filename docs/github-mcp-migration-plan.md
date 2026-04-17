---
title: GitHub MCP Migration Plan
category: reference
component: mcp_github_migration
status: active
version: 1.1.0
last_updated: 2026-04-17
tags: [mcp, github, 1password, sync-mcp, migration]
priority: high
---

# GitHub MCP Migration Plan

This document tracks the migration of the GitHub MCP integration from a
single deprecated local stdio wrapper (`@modelcontextprotocol/server-github`)
to a host-aware model using GitHub's hosted remote MCP server.

This is the tracker for the work. The live operating rules belong in:

- [`docs/agentic-tooling.md`](./agentic-tooling.md) — per-host MCP ownership
- [`docs/secrets.md`](./secrets.md) — 1Password references and wrapper contract

When this migration is complete, the relevant sections of those documents
take precedence, and this plan becomes an archive.

## Goal

- All five synced MCP hosts (Claude Code CLI, Codex CLI, Copilot CLI,
  Cursor, Windsurf) use GitHub's hosted remote MCP server rather than the
  deprecated `@modelcontextprotocol/server-github` npm package.
- No host persists a GitHub bearer header in a user-level config file.
- Secret material is read at runtime from 1Password — never from shell
  env exports, global config files, or committed dotfiles.
- A dedicated fine-grained PAT is used, distinct from the broader
  `github-dev-tools` token.

## Non-goals

- Claude Desktop, Gemini CLI, VS Code, JetBrains: out of scope. Not sync
  targets today and will remain tool-native.
- Changes to `gh` CLI authentication or repo-owned GitHub Actions flows.
- Changes to the `op://Dev/github-dev-tools/token` entry used by other
  dev tooling.

## Decisions

All locked in during the 2026-04-17 planning session.

| Decision | Value | Source |
|---|---|---|
| Remote URL | `https://api.githubcopilot.com/mcp/x/all` | matches the full-toolset useful for dev + org work |
| Feature flags | None in the baseline | `remote_mcp_ui_apps` is VS-Code-only; not worth a header on non-VS-Code hosts |
| Canonical env var | `GITHUB_PERSONAL_ACCESS_TOKEN` | matches the rest of this repo; no rename |
| 1Password URI | `op://Dev/github-mcp/token` | new item, dedicated fine-grained PAT |
| Claude/Cursor/Windsurf rendering | stdio wrapper `~/.local/bin/mcp-github-server` | avoids persisting a bearer header in long-lived user configs; Windsurf forbids env interpolation |
| Copilot CLI rendering | Skipped from sync | built-in `github-mcp-server` ships with Copilot; a second registration would double the tools |
| Codex CLI rendering | Direct remote HTTP (`url` + `bearer_token_env_var`) | Option A: Codex's native env-based auth |
| Codex env sourcing | `op run --env-file=...` at launch time | no `codex` shell wrapper; user invokes `op run` when GitHub MCP is wanted |
| Relay tool for the wrapper | `mcp-remote@0.1.38` via `npx`, invoked with `--silent --transport http-only` | pinned for reproducibility; `--silent` prevents the bearer header from being logged to stderr; `--transport http-only` forces GitHub's Streamable HTTP and fails fast on misconfig |
| Source JSON shape | `github` dropped from `scripts/mcp-servers.json`; rendered per-host inline in `sync-mcp.sh` | minimal special-casing, no metadata scheme creep |

## Per-host end state

| Host | Config file | Shape | Secret path at runtime |
|---|---|---|---|
| Claude Code CLI | `~/.claude.json` | `{"type":"stdio","command":"~/.local/bin/mcp-github-server"}` | wrapper → `op read op://Dev/github-mcp/token` |
| Cursor | `~/.cursor/mcp.json` | same as Claude | same |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` | same as Claude | same |
| Copilot CLI | `~/.copilot/mcp-config.json` | no `github` key (built-in handles it) | Copilot-internal |
| Codex CLI | `~/.codex/config.toml` | `[mcp_servers.github] url = "…/x/all", bearer_token_env_var = "GITHUB_PERSONAL_ACCESS_TOKEN"` | `op run --env-file=~/.config/codex/env.op -- codex` |

## Fine-grained PAT scopes

Target repository permissions (for repos the MCP should see):

| Permission | Level |
|---|---|
| Metadata | Read |
| Contents | Read & write |
| Issues | Read & write |
| Pull requests | Read & write |
| Actions | Read & write |
| Workflows | Read & write |
| Commit statuses | Read |
| Deployments | Read |
| Discussions | Read & write |
| Code scanning alerts | Read & write |
| Secret scanning alerts | Read |
| Dependabot alerts | Read |
| Repository security advisories | Read & write |
| Administration | Read |

Not granted: Secrets, Dependabot secrets, Environments, Pages, Variables,
Webhooks, Single file.

Account: Profile (Read), Gists (Read & write), Starring (Read).

Organization: Metadata (Read), Members (Read), Administration (Read),
Custom properties (Read), Projects (Read & write).

**Scope filtering note**: fine-grained tokens are not filtered at server
startup the way classic PATs are (see
`github-mcp-docs/scope-filtering.md` and the Scope Filtering section of
`github-mcp-docs/server-configuration.md`). All `/x/all` tools will show
up in every host; permission-limited calls fail at invocation time with
HTTP 403.

**Rotation**: set a 90-day or 1-year expiry at creation. Record the
expiration date in the 1Password item notes. Rotation consists of
generating a new PAT, updating the item's `token` field, and verifying
`op read "op://Dev/github-mcp/token"` still resolves.

## Phase status

| Phase | Status | Notes |
|---|---|---|
| 0. Create 1Password item `github-mcp` | Complete (2026-04-17) | Verified via `op read` |
| 1. Refactor `sync-mcp.sh` for host-aware github rendering | Complete (2026-04-17) | Committed in `13c2c6e` |
| 2. Rewrite `mcp-github-server` wrapper to use `mcp-remote` | Complete (2026-04-17) | Live-verified: 89 tools returned from `/x/all`, 0 bytes stderr (no token leak). PAT was rotated after the verbose-mode smoke test exposed the token in tool-result stderr. |
| 3. Run `sync-mcp.sh` against live configs | Not started | Pre-flight: insert BEGIN/END markers into `~/.codex/config.toml` (see below) |
| 4. Document codex launch-env pattern and `~/.config/codex/env.op` chezmoi source | Not started | No wrapper; `op run --env-file` pattern |
| 5. Docs pass: `docs/agentic-tooling.md`, `docs/secrets.md`, `docs/codex-cli-setup.md`, `docs/copilot-cli-setup.md` | Not started | |
| 6. (Optional) `ng-doctor` remote-reachable probe | Not started | HTTP HEAD with bearer; classifies response without logging token |

## Pre-flight before Phase 3

The live `~/.codex/config.toml` does not yet contain the
`# BEGIN system-config managed MCP servers` / `# END system-config managed MCP servers`
markers that `sync_codex_toml` uses to safely replace its managed block.
Running the new sync against the file as-is would produce duplicate
`[mcp_servers.*]` tables, which TOML parsers reject.

Before Phase 3:

1. Manually insert the BEGIN/END markers around the current
   `[mcp_servers.*]` top-level tables in `~/.codex/config.toml`.
2. Move any hand-added `[mcp_servers.*.tools.*]` sub-tables (for example
   `[mcp_servers.github.tools.create_pull_request]`) **below** the
   `# END` line so they survive replacement.

TOML allows `[mcp_servers.github]` and `[mcp_servers.github.tools.*]` to
appear in separate parts of the file — parsers merge them into the same
logical table.

## Rollback

At any phase:

1. `git revert` the relevant commit(s) on `main`.
2. Re-run `scripts/sync-mcp.sh` — it will restore the previous per-host
   GitHub entries.
3. The 1Password item `github-mcp` can be left in place. No other
   consumer depends on it.

The deprecated npm wrapper path (`npx -y @modelcontextprotocol/server-github`)
should not be restored; if Phase 2 work needs to be abandoned, the
`github-mcp-server` binary (option 2 in the original plan) is the
fallback, not the deprecated package.

## Verification commands

```bash
# 1Password readiness
op vault get Dev --account my.1password.com >/dev/null && echo "op ok"
op read --account my.1password.com "op://Dev/github-mcp/token" >/dev/null && echo "token ok"

# Sync shape check (dry-run)
./scripts/sync-mcp.sh --dry-run

# Post-sync inspection
jq '.mcpServers | keys' ~/.claude.json ~/.cursor/mcp.json ~/.codeium/windsurf/mcp_config.json ~/.copilot/mcp-config.json
grep -A2 '\[mcp_servers.github\]' ~/.codex/config.toml

# Wrapper smoke test (must return JSON-RPC with a non-empty tools array)
printf '{"jsonrpc":"2.0","id":1,"method":"tools/list"}\n' \
  | ~/.local/bin/mcp-github-server | head -c 400
```

## Related

- [`docs/secrets.md`](./secrets.md)
- [`docs/agentic-tooling.md`](./agentic-tooling.md)
- [`docs/codex-cli-setup.md`](./codex-cli-setup.md)
- [`docs/copilot-cli-setup.md`](./copilot-cli-setup.md)
- [`docs/1password-migration-plan.md`](./1password-migration-plan.md)
- External reference (not committed): `github-mcp-docs/` at repo root
