---
title: Secrets Handling
category: reference
component: secrets_policy
status: active
version: 2.0.0
last_updated: 2026-04-17
tags: [secrets, 1password, op, direnv, mcp, security]
priority: critical
---

# Secrets Handling

Single authoritative guide for how agents and humans handle secrets on
this system. Other docs should point here for secret policy, not restate
it.

## Core rules

- Use 1Password CLI (`op`) for every repo-owned secret integration.
- Never commit secrets, tokens, passphrases, or API keys.
- Never persist resolved secrets into user-global config files like
  `~/.claude.json`, `~/.codex/config.toml`, or IDE MCP configs.
- Keep project-specific secret loading in each project's `.envrc`.
- Treat `op://` references as stable API contracts once they appear in
  repo-owned code — renames require every consumer to be updated in the
  same change.

## Canonical setup

- Account: `my.1password.com`
- Primary vault: `Dev`
- Runtime resolution path: env var → `op read --account my.1password.com` → fail
- Readiness check:

  ```bash
  op vault get Dev --account my.1password.com >/dev/null
  ```

  `op whoami` is not the canonical signal under desktop-app integration;
  prefer the vault-get check above.

## Repo-owned secret references

These URIs are live, verified, and synced into runtime wrappers or
chezmoi-managed config:

| Consumer | Env var | op:// URI |
|----------|---------|-----------|
| `mcp-brave-search-server` | `BRAVE_API_KEY` | `op://Dev/brave-search/api-key` |
| `mcp-firecrawl-server` | `FIRECRAWL_API_KEY` | `op://Dev/firecrawl/api-key` |
| `~/.config/mcp/common.env` (shared manifest) | `GITHUB_PAT`, `BRAVE_API_KEY`, `FIRECRAWL_API_KEY` | (resolves all three above and `op://Dev/github-mcp/token`) |

GitHub MCP is host-aware and is tracked in
[`docs/github-mcp.md`](./github-mcp.md) — the single source of truth for
that integration. The broader MCP framework (scope model, launch
patterns, sync behavior) lives in [`docs/mcp-config.md`](./mcp-config.md).

## Agent rules

Agents may:

- Read secrets via `op read` when the task requires runtime secret resolution.
- Use repo-owned wrappers that resolve secrets at launch.
- Run limited diagnostics such as `op whoami` when explicitly needed.

Agents must not, unless explicitly directed by a human:

- Create, edit, or reorganize 1Password items.
- Inventory vault contents broadly.
- Materialize secrets into persistent config files.

Human-owned tasks:

- Creating or editing 1Password items.
- Deciding naming and organization for new shared secrets.
- Scope and expiry changes on fine-grained PATs.

## Project pattern

Small project `.envrc` files use `use op` plus direct `op read`:

```bash
use mise
use op
export API_KEY=$(op read "op://Dev/service/api-key")
```

Safe to commit because `op://` URIs carry no secret value.

For larger env surfaces, prefer `op run` with a committed reference file:

```bash
use mise
use op
eval "$(op run --env-file=.env.1p -- env)"
```

Do not move project-specific secret loading into global shell config.

## Naming rules

- Item names: kebab-case.
- Field names: kebab-case.
- Name items by purpose, not by provider alone when multiple credentials
  may exist for one provider.
- One item per logical credential group; use multiple fields when a group
  needs several values.
- Use tags for metadata: `scope:*`, `provider:*`, `project:*`.

Current repo-owned examples:

- `github-dev-tools` → field `token` — general GitHub PAT (`gh` CLI, misc dev tooling)
- `github-mcp` → field `token` — fine-grained PAT scoped to the GitHub MCP integration ([`docs/github-mcp.md`](./github-mcp.md))
- `brave-search` → field `api-key`
- `firecrawl` → field `api-key`

## Verification

```bash
op vault get Dev --account my.1password.com >/dev/null && echo "op ok"
op read --account my.1password.com "op://Dev/brave-search/api-key" >/dev/null && echo brave ok
op read --account my.1password.com "op://Dev/firecrawl/api-key" >/dev/null && echo firecrawl ok

# The shared MCP manifest resolves everything at once
op run --account my.1password.com --env-file=$HOME/.config/mcp/common.env -- \
  bash -c 'for v in GITHUB_PAT BRAVE_API_KEY FIRECRAWL_API_KEY; do
    [[ -n "${!v:-}" ]] && echo "$v resolved" || echo "$v MISSING"; done'

ng-doctor tools
```

GitHub MCP–specific verification lives in
[`docs/github-mcp.md`](./github-mcp.md).

## Related

- [`AGENTS.md`](../AGENTS.md)
- [`README.md`](../README.md)
- [`docs/mcp-config.md`](./mcp-config.md) — MCP framework
- [`docs/github-mcp.md`](./github-mcp.md) — GitHub MCP integration
- [`docs/ssh.md`](./ssh.md) — SSH client policy
- [`docs/agentic-tooling.md`](./agentic-tooling.md) — shell + tool contract
