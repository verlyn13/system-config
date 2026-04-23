---
title: Secrets Handling
category: reference
component: secrets_policy
status: active
version: 2.2.0
last_updated: 2026-04-23
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
| `mcp-runpod-server` | `RUNPOD_API_KEY` | `op://Dev/runpod-api/api-key` |
| `mcp-cloudflare-server` | `CLOUDFLARE_API_TOKEN` | `op://Dev/cloudflare-mcp-jefahnierocks/token` |
| `~/.config/mcp/common.env` (shared manifest) | `GITHUB_PAT`, `BRAVE_API_KEY`, `FIRECRAWL_API_KEY`, `RUNPOD_API_KEY`, `CLOUDFLARE_API_TOKEN` | resolves all wrappers above and `op://Dev/github-mcp/token` |
| `~/Organizations/happy-patterns/.envrc` (tree-local override) | `GITHUB_PAT`, `GH_TOKEN`, `GITHUB_TOKEN`, `GITHUB_PERSONAL_ACCESS_TOKEN` | `op://Dev/github-happy-patterns/token` |

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

- `github-dev-tools` → field `token` — general GitHub PAT (`gh` CLI, misc dev tooling) for the `verlyn13` identity
- `github-mcp` → field `token` — fine-grained PAT scoped to the GitHub MCP integration ([`docs/github-mcp.md`](./github-mcp.md)) for the `verlyn13` identity
- `github-happy-patterns` → field `token` — fine-grained PAT for the `happy-patterns` identity (resource owner: `happy-patterns-org`); serves both `gh` CLI and the GitHub MCP when launched from `~/Organizations/happy-patterns/`
- `ssh-github-happy-patterns` → SSH key item; 1Password-managed ed25519 key for the `happy-patterns` GitHub identity (authentication + signing; public key rendered to `~/.ssh/id_ed25519_happy_patterns.1password.pub`)
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

## Infisical

Self-hosted Infisical (`https://infisical.jefahnierocks.com`) is used by
project repos for runtime application secrets. `system-config` does not
own that platform and does not duplicate its standards.

**Scope split:**

| Surface | Owner | Notes |
|---------|-------|-------|
| Self-hosted Infisical server, org, policies, HPUSS-SEC standard, terraform, machine identities, project templates | `~/Repos/verlyn13/infisical` | Server-side management repo |
| Dev-machine surface: shell, direnv, `op`/1Password policy, mise, user-level MCP wrappers | `system-config` (this repo) | Macos developer environment |
| Per-project `.envrc`, `.infisical.json`, runtime loader, CI flow | the project repo | Consumer |

**Binding consultant rules on this machine (apply in every Infisical
session, regardless of which repo you're in):**

- Validate every `infisical` CLI flag against the currently installed
  CLI. Training-data habits are not authoritative.
- Rejected on the current CLI (0.43.76): `--project-slug`,
  `--format shell`. Do not use, do not recommend.
- Valid `infisical export --format` values on the current CLI:
  `dotenv`, `dotenv-export`, `csv`, `json`, `yaml`. Prefer
  `dotenv-export` for shell sourcing.
- Prefer repo-local `.infisical.json` for dev flows; explicit
  `--projectId` only for machine-identity / CI paths.
- An availability gate must check the *exact non-empty secrets* the
  consuming workflow requires. "Path returns something" is not
  equivalent to "required vars are importable and non-empty".
- Never hide stderr (`2>/dev/null`) during first-pass validation — run
  raw commands visibly before wrapping in `eval`.
- Validate the full chain on every setup: `infisical --version` → scope
  resolution → auth → secret retrieval → raw export output → shell
  import → final env vars visible to the consuming tool. A green on one
  step does not imply the next.
- `.infisical.json` is configuration, not a secret. Check it in.
- Treat fallback paths as requirement-driven, not outage-driven: if
  Infisical does not yield the full required non-empty set, fall back
  intentionally to the alternate source (for example,
  `op read` from the canonical 1Password bootstrap item).

## Related

- [`AGENTS.md`](../AGENTS.md)
- [`README.md`](../README.md)
- [`docs/mcp-config.md`](./mcp-config.md) — MCP framework
- [`docs/github-mcp.md`](./github-mcp.md) — GitHub MCP integration
- [`docs/ssh.md`](./ssh.md) — SSH client policy
- [`docs/agentic-tooling.md`](./agentic-tooling.md) — shell + tool contract
- `~/Repos/verlyn13/infisical` — self-hosted Infisical management repo (HPUSS-SEC, server-side)
