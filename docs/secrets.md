---
title: Secrets Handling
category: reference
component: secrets_policy
status: active
version: 1.1.0
last_updated: 2026-04-17
tags: [secrets, 1password, op, direnv, mcp, security]
priority: critical
---

# Secrets Handling

This is the single authoritative live guide for how agents and humans should
handle secrets on this system.

Use this document for current behavior, policy, and operating rules.
Use [`docs/1password-migration-plan.md`](./1password-migration-plan.md) for
remaining repo-by-repo rollout work and final gopass retirement tracking.
If another current doc needs to explain system-wide secret behavior, it should
point here instead of restating policy.

## System Intent

The long-term system goal is:

1. Audit the machine and repos for loose or duplicated secrets.
2. Move active secret consumption repo by repo from gopass to 1Password.
3. Organize live secrets in 1Password using stable item and field naming.
4. Remove gopass entirely once no active consumer depends on it.

`system-config` itself has already completed and verified its baseline
rollout. What remains is downstream repo rollout and final archive
retirement work.

## Core Rules

- Use 1Password CLI (`op`) for all new repo-owned secret integrations.
- Do not introduce new gopass usage anywhere in this repo.
- Do not commit plaintext secrets, tokens, passphrases, or API keys.
- Do not persist expanded secrets into user-global config files such as
  `~/.claude.json`, `~/.codex/config.toml`, IDE MCP configs, or similar files.
- Keep project-specific secret loading in each project’s `.envrc`.
- Treat `op://` references as stable API contracts once they appear in
  repo-owned code.

## Canonical Live Setup

- 1Password account: `my.1password.com`
- Primary live vault for repo-owned developer secrets: `Dev`
- Repo-owned runtime path: env var -> `op read --account my.1password.com` -> fail
- Canonical readiness check:

```bash
op vault get Dev --account my.1password.com >/dev/null
```

`op whoami` may be useful for limited diagnostics, but it is not the
canonical readiness signal on this system under desktop-app integration.

## Repo-Owned Secret References

These references are live and verified for `system-config`:

| Consumer | Env var | op:// URI |
|----------|---------|-----------|
| `mcp-brave-search-server` | `BRAVE_API_KEY` | `op://Dev/brave-search/api-key` |
| `mcp-firecrawl-server` | `FIRECRAWL_API_KEY` | `op://Dev/firecrawl/api-key` |

GitHub MCP is host-aware (different rendering per tool) and is tracked
separately. Its current secret contract and per-host behavior live in
[`docs/github-mcp-migration-plan.md`](./github-mcp-migration-plan.md)
until a consolidated authoritative reference lands. Do not duplicate its
URI into this table — treat the GitHub MCP doc as the single source of
truth for that integration.

Do not rename vault, item, or field labels used by these references unless
every consumer is updated in the same change.

## Agent Rules

Agents may:

- read secrets via `op read` when the task requires runtime secret resolution
- use repo-owned wrappers that resolve secrets at runtime
- use limited diagnostics such as `op whoami` when explicitly needed

Agents must not, unless explicitly directed by a human:

- create, edit, or reorganize 1Password items
- inventory vault contents broadly
- materialize secrets into persistent config files
- create new gopass-backed workflows

Human-owned secret administration includes:

- creating or editing 1Password items
- deciding naming and organization for new shared secrets
- retiring the final gopass archive

## Project Pattern

Small project `.envrc` files should use `use op` plus direct `op read`:

```bash
use mise
use op
export API_KEY=$(op read "op://Dev/service/api-key")
```

This is safe to commit because `op://` URIs do not contain the secret value.

For larger env surfaces, prefer `op run` with a committed reference file
instead of copying secret values into plaintext files:

```bash
use mise
use op
eval "$(op run --env-file=.env.1p -- env)"
```

Do not move project-specific secret loading into global shell config.

## Naming Rules

- Item names: kebab-case
- Field names: kebab-case
- Name items by purpose, not by provider alone when multiple credentials may exist
- Use one item per logical credential group, with multiple fields where appropriate
- Use tags for metadata such as `scope:*`, `provider:*`, or `project:*`

Current repo-owned examples:

- `github-dev-tools` -> field `token` (general-purpose GitHub PAT; `gh` CLI and other dev tooling)
- `github-mcp` -> field `token` (dedicated fine-grained PAT for the GitHub MCP integration; see `docs/github-mcp-migration-plan.md`)
- `brave-search` -> field `api-key`
- `firecrawl` -> field `api-key`

## gopass Status

gopass is now archive-only on this system.

That means:

- existing project or external consumers may still reference it during ongoing migration
- no new repo-owned integrations should depend on it
- final removal happens only after all active consumers have been migrated

What still matters about gopass right now:

- the remaining archive is machine-local, not repo-managed
- the repo does not store any gopass unlock flow, passphrase, or recovery steps
- project secrets still being migrated should move into project `.envrc` flows based on `op`, not shell startup files or user-global config
- if a migration still needs to read an old gopass entry, treat that as an extraction step on the way to a 1Password item, not as a continuing integration

Current machine-local gopass residue to retire later:

- store: `~/.local/share/gopass/stores/root/`
- config: `~/.config/gopass/config`
- local operator notes: `~/.config/gopass/README-AGENTS.md`

If an extraction step still needs gopass access, use the approved machine-local
unlock flow and consult `~/.config/gopass/README-AGENTS.md`, not this repo.

Do not copy machine-local gopass notes, unlock procedures, or passphrase
material back into this repo.

## Retirement Path

The remaining work is outside `system-config` baseline wiring:

1. migrate active project repos from `gopass show` to `use op` + `op read`
2. consolidate duplicated secrets into the correct 1Password items
3. verify no loose plaintext secrets remain in repo or user-global config
4. remove remaining external gopass guidance and archive files
5. remove gopass entirely once no active repo or workflow depends on it

Track that work in [`docs/1password-migration-plan.md`](./1password-migration-plan.md).

## Verification

Useful checks:

```bash
op vault get Dev --account my.1password.com >/dev/null
ng-doctor tools
op read --account my.1password.com "op://Dev/brave-search/api-key" >/dev/null && echo brave ok
op read --account my.1password.com "op://Dev/firecrawl/api-key" >/dev/null && echo firecrawl ok
```

GitHub MCP verification lives in `docs/github-mcp-migration-plan.md`.

## Related

- [`AGENTS.md`](../AGENTS.md)
- [`README.md`](../README.md)
- [`docs/agentic-tooling.md`](./agentic-tooling.md)
- [`docs/1password-migration-plan.md`](./1password-migration-plan.md)
