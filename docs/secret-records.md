---
title: Secret Records
category: reference
component: secrets_records
status: transitional
version: 0.3.0
last_updated: 2026-05-08
tags: [secrets, 1password, github, cloudflare, credential-records]
priority: high
---

# Secret Records

Non-secret credential records for material credentials referenced by
`system-config`. This file tracks logical ownership, storage aliases, runtime
consumers, rotation cadence, status, evidence, and stop rules. It must never
contain secret values, full token bodies, private keys, recovery codes, or
screenshots containing sensitive material.

The Jefahnierocks and Happy Patterns project secrets standards are proposed
and not yet enforced by policy-as-code. `system-config` follows their shape
where practical: provider credentials use logical paths like
`github/jefahnierocks/<purpose>` and `github/happy-patterns/<purpose>`, while
1Password storage aliases remain stable until every consumer is patched.

## Status Values

Allowed statuses: `planned`, `issued`, `active`, `transitional`, `retired`,
`out-of-spec`.

## Records

| Logical path | Storage alias | Runtime env / secret name | Runtime consumer | Semantic owner | Provider steward | Rotation cadence | Status | Evidence location | Stop rules |
|---|---|---|---|---|---|---|---|---|---|
| `github/jefahnierocks/macpro-mcp` | wired alias: `op://Dev/github-mcp/token`; replacement staging alias: `op://Dev/github-jefahnierocks-macpro-mcp/credential` | `GITHUB_PAT` | `~/.local/bin/mcp-github-server`; `~/.config/mcp/common.env`; Claude Code, Cursor, Codex GitHub MCP entries | Jefahnierocks | `jefahnierocks` GitHub organization | 90 days during PAT-based transitional MCP; revisit when host substrate or GitHub App path replaces PAT | `out-of-spec` | `docs/incident-2026-05-08-mcp-bearer-argv-exposure.md`; `docs/github-mcp.md` | Stop if token appears in argv/logs, scope spans unrelated repos, provider owner changes, or wrapper architecture still passes bearer material via argv. Do not paste replacement token into the wired alias until the bridge no longer passes bearer material through argv. |
| `github/happy-patterns/macpro-mcp` | `op://Dev/github-happy-patterns/token` | `GITHUB_PAT`, `GH_TOKEN`, `GITHUB_TOKEN`, `GITHUB_PERSONAL_ACCESS_TOKEN` | `~/Organizations/happy-patterns/.envrc`; Happy Patterns tree GitHub CLI and MCP override | Happy Patterns | `happy-patterns` GitHub account, resource owner `happy-patterns-org` | 90 days during PAT-based transitional MCP/local tooling | `transitional` | `docs/secrets.md`; `~/Organizations/happy-patterns/.envrc` | Stop if token reaches non-Happy-Patterns repos, is reused for another business/entity, or is described as Jefahnierocks-owned. |
| `github/happy-patterns/macpro-ssh-key` | `op://Dev/ssh-github-happy-patterns` | SSH key item | 1Password SSH agent; Git authentication and SSH signing for the `happy-patterns` identity; public key rendered by `home/dot_ssh/id_ed25519_happy_patterns.1password.pub.tmpl` | Happy Patterns | `happy-patterns` GitHub account | Event-driven rotation on compromise, custody change, or identity boundary change | `active` | `docs/ssh.md`; `docs/secrets.md` | Stop if reused as an unattended machine identity, if provider account ownership changes, or if project automation depends on this human-interactive key. |
| `github/jefahnierocks/macpro-dev-tools` | `op://Dev/github-dev-tools/token` | `GITHUB_PERSONAL_ACCESS_TOKEN` | `use_user_mcp_secrets` in `home/dot_config/direnv/direnvrc.tmpl`; selected host-local dev scripts | Jefahnierocks local bootstrap | `jefahnierocks` GitHub organization | 90 days while fine-grained PAT remains broad/local-bootstrap | `transitional` | `docs/secrets.md`; `docs/project-conventions.md` | Stop if used as a project deployment credential, if it spans unrelated authority without a written exception, or if a narrower project token can replace it. |
| `cloudflare/jefahnierocks/mcp-readonly` | wired alias: `op://Dev/cloudflare-mcp-jefahnierocks/token`; replacement staging alias: `op://Dev/cloudflare-jefahnierocks-mcp-readonly/credential` | `CLOUDFLARE_API_TOKEN` | `~/.local/bin/mcp-cloudflare-server`; Cloudflare MCP entry | Jefahnierocks | Cloudflare user/API token dashboard for account `13eb584192d9cefb730fde0cfd271328` | 180 days by proposed Jefahnierocks standard, or shorter during incident response | `issued` | `docs/cloudflare-mcp.md`; `docs/incident-2026-05-08-mcp-bearer-argv-exposure.md` | Stop if token is active through `mcp-remote --header`, scope exceeds `User Details Read` plus `Zone Read`/`DNS Read` for `jefahnierocks.com`, write permissions are granted, the value appears in local logs/tool output, or Cloudflare API mutation is attempted outside a bounded control-plane task. Do not wire the replacement until the bridge no longer passes bearer material through argv. |

## Known Cross-Boundary Tokens

`TF_VAR_github_token` observed in the Happy Patterns GitHub UI is a separate
Happy Patterns to The-Nash-Group provider credential. It is not a
`system-config` MCP token and should not be stored under the `github-mcp`,
`github-happy-patterns`, or `github-dev-tools` aliases. Treat it as
cross-entity and transitional until the owning project records its logical
path, storage alias, scope, runtime consumer, and exception basis.

## Audit Log

| Date | Credential | Principal change | Action | Verification |
|---|---|---|---|---|
| 2026-05-08 | `github/jefahnierocks/macpro-mcp` | current provider UI name `mcp-servers-macpro`; target provider UI name `github/jefahnierocks/macpro-mcp`; 1Password value pending replacement | old provider token rolled after argv exposure; non-secret 1Password metadata updated | GitHub UI human report; local old `op://Dev/github-mcp/token` returns `401`; live argv matches cleared; `op item get github-mcp` metadata section verified |
| 2026-05-08 | `github/happy-patterns/macpro-mcp` | current provider UI name `macpro-mcp-happy`; target provider UI name `github/happy-patterns/macpro-mcp`; 1Password value pending replacement | old provider token rolled after related GitHub PAT review; non-secret 1Password metadata updated | GitHub UI human report; local old `op://Dev/github-happy-patterns/token` returns `401`; no live argv matches; `op item get github-happy-patterns` metadata section verified |
| 2026-05-08 | `github/jefahnierocks/macpro-dev-tools` | current provider UI name `mcp-servers-token`; target provider UI name `github/jefahnierocks/macpro-dev-tools`; 1Password value pending replacement | old provider token rolled during adjacent GitHub PAT cleanup; non-secret 1Password metadata updated | GitHub UI human report; local old `op://Dev/github-dev-tools/token` returns `401`; no live argv matches; `op item get github-dev-tools` metadata section verified |
| 2026-05-08 | `cloudflare/jefahnierocks/mcp-readonly` | current provider UI name `cloudflare-mcp-jefahnierocks`; target provider UI name `cloudflare/jefahnierocks/mcp-readonly`; replacement staged separately from wired alias | non-secret 1Password metadata updated | `op item get cloudflare-mcp-jefahnierocks` metadata section verified |
| 2026-05-08 | `github/happy-patterns/macpro-ssh-key` | 1Password SSH key item metadata desired | CLI metadata update attempted and blocked | `op item edit ssh-github-happy-patterns` returned `SSH Key item editing in the CLI is not yet supported`; use 1Password UI for item metadata |
| 2026-05-08 | `github/jefahnierocks/macpro-mcp` | replacement staging alias `op://Dev/github-jefahnierocks-macpro-mcp/credential`; wired alias `op://Dev/github-mcp/token` cleared and blocked | created staging 1Password API Credential item for human GUI credential entry; did not wire runtime alias | `op item get github-jefahnierocks-macpro-mcp` metadata verified; no secret value passed through CLI |
| 2026-05-08 | `github/jefahnierocks/macpro-mcp` | staging alias normalized from custom `token` field to built-in API Credential `credential` field | moved secret from `token` to `credential` through piped `op item edit` JSON; removed empty custom `token` field | `op://Dev/github-jefahnierocks-macpro-mcp/credential` non-empty; `op://Dev/github-jefahnierocks-macpro-mcp/token` empty or absent |
| 2026-05-08 | `cloudflare/jefahnierocks/mcp-readonly` | replacement staging alias `op://Dev/cloudflare-jefahnierocks-mcp-readonly/credential`; wired alias `op://Dev/cloudflare-mcp-jefahnierocks/token` cleared and blocked | created staging 1Password API Credential item for human GUI credential entry; did not wire runtime alias | `op item get cloudflare-jefahnierocks-mcp-readonly` metadata verified; no secret value passed through CLI |
| 2026-05-08 | `cloudflare/jefahnierocks/mcp-readonly` | replacement credential entered; valid from 2026-05-08; expires 2026-11-04; status `issued`; runtime still staging | updated 1Password item metadata and verified replacement token without printing the value | Cloudflare `/user/tokens/verify` returned active; `jefahnierocks.com` zone read and DNS read succeeded; wired alias remains empty |
| 2026-05-08 | `cloudflare/jefahnierocks/mcp-readonly` | replacement credential value exposed to local Codex tool output during item inspection; runtime still not wired | marked 1Password item `out-of-spec` and blocked pending another rotation | 1Password item tags/status now `out-of-spec`; next action records revoke/recreate with same narrow scope and local log/session cleanup |
| 2026-05-08 | `cloudflare/jefahnierocks/mcp-readonly` | old `cloudflare-mcp-jefahnierocks` token and prior replacement deleted in Cloudflare UI; fresh replacement created under the same provider name and scope; valid from 2026-05-08; expires 2026-11-04 | updated 1Password item back to `issued`, kept runtime staged, and cleared the old wired alias | Cloudflare `/user/tokens/verify` returned active; `jefahnierocks.com` zone read and DNS read succeeded; `op://Dev/cloudflare-mcp-jefahnierocks/token` empty; no live Cloudflare MCP process |
