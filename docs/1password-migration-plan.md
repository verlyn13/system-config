---
title: 1Password Rollout And Retirement Plan
category: reference
component: secrets_rollout
status: active
version: 3.2.0
last_updated: 2026-04-15
tags: [1password, op, secrets, rollout, retirement, direnv, mcp]
priority: high
---

# 1Password Rollout And Retirement Plan

This document tracks the remaining repo-by-repo rollout work to move active
secret usage on this system from gopass to 1Password, then remove gopass
completely once it is no longer needed.

This is not the live secrets policy. Use [`docs/secrets.md`](./secrets.md)
for everyday operating rules and agent behavior. Other current docs should
point there for live secret policy.

## Goal

The target end state is:

1. all active repo-owned secret consumption uses 1Password CLI (`op`)
2. live secrets are organized in stable 1Password items and fields
3. no new gopass usage is introduced anywhere
4. gopass is removed once no active repo or external workflow depends on it

## Verified `system-config` Baseline

Verified on 2026-04-15:

- `system-config` itself has completed its baseline rollout.
- Repo-owned auth-required integrations use:
  env var -> `op read --account my.1password.com` -> fail
- Repo-owned readiness is validated by:

```bash
op vault get Dev --account my.1password.com >/dev/null
```

- `ng-doctor tools` verifies both `op_installed` and `op_ready`.
- The three required `system-config` secret references resolve successfully:
  - `op://Dev/github-dev-tools/token`
  - `op://Dev/brave-search/api-key`
  - `op://Dev/firecrawl/api-key`
- gopass is archive-only for `system-config`.

## Verified Downstream Progress

Verified in repo-local migration sessions on 2026-04-15:

- `budget-triage-11-5-2025`
- `flux`
- `llm-gateway`
- `aider`
- `email-corpus`
- `the-nash-group` authority layer and active child repos:
  `the-covenant`, `the-citadel`, `the-nexus`, `the-shield`, and `the-tartan`

These repos are no longer part of the active rollout queue unless a new live
gopass regression is discovered.

## Locked Decisions

These decisions are already made for this system. Do not re-derive them.

### Account and Vault

- 1Password account: `my.1password.com`
- Primary live vault for repo-owned developer secrets: `Dev`

### Repo-Owned Wrapper Items

| Consumer | Item | Field | op:// URI |
|----------|------|-------|-----------|
| `mcp-github-server` | `github-dev-tools` | `token` | `op://Dev/github-dev-tools/token` |
| `mcp-brave-search-server` | `brave-search` | `api-key` | `op://Dev/brave-search/api-key` |
| `mcp-firecrawl-server` | `firecrawl` | `api-key` | `op://Dev/firecrawl/api-key` |

### Naming Rules

- Item names: kebab-case
- Field names: kebab-case
- Name items by purpose, not by provider alone when multiple credentials may exist
- Use one item per logical credential group, with multiple fields where appropriate
- Use tags such as `scope:*`, `provider:*`, or `project:*` for metadata

Current provider-level conventions that should be reused when migrating active
repos:

| Item | Field |
|------|-------|
| `anthropic` | `api-key` |
| `openai` | `api-key` |
| `gemini` | `api-key` |
| `sentry` | `auth-token` |
| `elevenlabs` | `api-key` |

Project-level items should group related fields under one item, for example:

| Item | Fields |
|------|--------|
| `budget-triage` | `database-url`, `plaid-client-id`, `plaid-secret` |
| `dicee` | project-specific fields such as `supabase-key`, `elevenlabs-key` |
| `kbe-website` | project-specific fields such as `vercel-cron-secret` |

### Boundaries

- Do not make 1Password Environments the default `system-config` baseline.
- Do not use service accounts for local interactive workstation flows.
- Do not treat `op whoami` as the canonical readiness signal under desktop-app integration.

## Repo Rollout Workflow

Apply this process repo by repo as work naturally touches each project.

## Current Active Rollout Queue

Validated on 2026-04-15 by scanning likely local repo roots under
`/Users/verlyn13/Organizations`, `/Users/verlyn13/Repos`, and `/Users/verlyn13/ai`.

This queue now reflects the real remaining live gopass consumers after the
verified completions above. It intentionally excludes archive trees, historical
reports, and superseded plans unless they still drive live operator behavior.

### Priority 0: next active migrations

| Repo | Live gopass surface | Immediate next step |
|------|---------------------|---------------------|
| `scopecam-engine` | `scripts/load-keystore-config.sh`, `scripts/sync-secrets.sh`, `project.manifest.yaml`, `secrets-management/secrets-management.md`, `docs/FIREBASE_QUICK_REFERENCE.md` | Keep Infisical as primary, replace Android signing gopass fallback and manifest namespace with a 1Password-backed or no-fallback local bootstrap contract |
| `hetzner` | `CLAUDE.md`, `README.md`, `scripts/seed-proxy-secrets.sh`, `scripts/deploy-postal.sh`, `scripts/deploy-glitchtip.sh`, `scripts/deploy-metabase.sh`, `services/metabase/README.md`, `docs/operations/IAC_RUNNER.md` | Keep Infisical and env as runtime authority, replace active gopass-based local bootstrap and operator guidance for S3, Cloudflare, and Infisical machine identities |
| `cloudflare-management` | `cloudflare-helper.sh`, `scripts/sync-secrets.sh`, `scripts/setup-workspace.sh`, `Makefile`, active docs and AGENT guidance | Replace runtime helper and setup scripts first, then remove repo guidance that still treats gopass as the primary local secret store |

### Priority 1: opportunistic follow-up

- Re-scan the completed repos only if a downstream follow-up reveals a new live
  gopass surface that was missed during repo-local verification.
- Clean up any remaining helper or policy repos after Priority 0 is complete so
  the machine-wide retirement audit has fewer moving parts.

### Defer for now

- archive trees such as `_archive/`, `history/`, and old research reports
- old planning docs that mention gopass only as historical context
- any repo where current hits are clearly superseded by archive-only material

The objective is to eliminate live gopass dependencies first, then clean up
history and archives last.

## Backend Strategy By Repo

1Password replaces gopass on this system. It does not automatically replace
other runtime backends that are already canonical inside a project.

Use these rules when migrating a repo:

- If the repo is already Infisical-first, keep Infisical as the runtime
  authority and replace only the local gopass bootstrap or fallback path with
  1Password.
- If the repo is keychain-first, keep that runtime design and replace only the
  local gopass bridge used for shell or CLI tooling.
- If the repo uses gopass directly as a runtime secret backend, move that live
  backend to 1Password and update the code contract accordingly.
- Do not preserve gopass as a secondary backend once the replacement path is
  verified.

## Repo Instruction Packs

Use these packs with the local project agent only for the remaining repos in
the active queue.

### scopecam-engine

Read first:

- `AGENTS.md`
- `.envrc`
- `scripts/load-keystore-config.sh`
- `scripts/sync-secrets.sh`
- `project.manifest.yaml`
- `secrets-management/secrets-management.md`
- `docs/FIREBASE_QUICK_REFERENCE.md`

Migration intent:

- Keep Infisical as the primary secrets backend for CI and runtime flows.
- Replace the Android signing gopass fallback with a 1Password-backed local
  bootstrap path or remove the fallback entirely if Infisical is sufficient.
- Remove gopass-specific manifest metadata and operator guidance from active
  repo surfaces.

Live surfaces to change:

- `.envrc`
- `scripts/load-keystore-config.sh`
- `scripts/sync-secrets.sh`
- `project.manifest.yaml`
- `secrets-management/secrets-management.md`
- `docs/FIREBASE_QUICK_REFERENCE.md`
- `app/build.gradle.kts` comments or any active loader notes that still encode
  gopass as part of the supported flow

Suggested 1Password shape:

- one item for Android signing material, for example `scopecam-android-signing`
- fields such as `keystore-password`, `key-password`, `key-alias`, and
  `keystore-b64` only if the repo still truly needs to move the keystore
  through secret storage
- avoid storing machine-specific local path values in 1Password unless a path
  indirection is truly required

Strict audit:

- active `.envrc`, scripts, and manifest files no longer refer to gopass
- `project.manifest.yaml` no longer encodes a `gopass_namespace`
- Android signing or local build bootstrap still works through Infisical or the
  new 1Password-backed local path
- sync tooling no longer writes secrets into gopass as part of the normal flow

### hetzner

Read first:

- `CLAUDE.md`
- `README.md`
- `.envrc`
- `scripts/seed-proxy-secrets.sh`
- `scripts/deploy-postal.sh`
- `scripts/deploy-glitchtip.sh`
- `scripts/deploy-metabase.sh`
- `services/metabase/README.md`
- `docs/operations/IAC_RUNNER.md`

Migration intent:

- Keep Infisical and env injection as the runtime/service authority.
- Replace active gopass-based local bootstrap and operator guidance for Hetzner
  S3, Cloudflare, and Infisical machine identities with 1Password-backed local
  reads or explicit env-based flows.
- Remove active documentation that still treats gopass as the normal operator
  path for this repo.

Live surfaces to change:

- `CLAUDE.md`
- `README.md`
- `scripts/seed-proxy-secrets.sh`
- `scripts/deploy-postal.sh`
- `scripts/deploy-glitchtip.sh`
- `scripts/deploy-metabase.sh`
- `services/metabase/README.md`
- `docs/operations/IAC_RUNNER.md`
- `docs/network/NETWORK_MAP.md`
- `docker/glitchtip/README.md`
- `docker/metabase/README.md`
- any active service or operations doc that still instructs operators to use
  gopass as the current secret source

Suggested 1Password shape:

- reuse the verified Hetzner and Citadel credential naming where shared
  credentials already exist, instead of creating parallel item names
- one item per Infisical machine identity only when local bootstrap still needs
  it, with fields such as `identity-id`, `client-id`, and `client-secret`
- one item for locally bootstrapped Cloudflare automation credentials if they
  are still needed outside Infisical or GitHub-managed runtime paths

Strict audit:

- active scripts no longer run `gopass show`, `gopass edit`, or `gopass insert`
- active docs no longer describe gopass as the current local operator path
- local bootstrap works through env vars, `op read`, or Infisical-backed flows,
  not gopass
- no new user-global secret-file guidance is introduced

### cloudflare-management

Read first:

- `AGENTS.md`
- `README.md`
- `docs/SECRETS-MANAGEMENT.md`

Migration intent:

- Replace gopass as the primary local secret store used by helpers, setup
  scripts, and operator docs.
- Keep any existing Infisical integration only if it is still actively used by
  this repo, but do not retain gopass as the long-term local authority.

Live surfaces to change first:

- `cloudflare-helper.sh`
- `scripts/create-api-tokens.sh`
- `scripts/update-hetzner-ip.sh`
- `scripts/test-token.sh`
- `scripts/setup-workspace.sh`
- `scripts/sync-secrets.sh`
- `scripts/setup-infisical.sh`
- `scripts/setup-tokens.sh`
- `Makefile`
- `AGENTS.md`
- `README.md`
- `AGENT_GUIDE.md`
- `docs/SECRETS-MANAGEMENT.md`

Migration notes:

- start with runtime helper scripts before documentation cleanup
- remove any command that teaches `gopass insert`, `gopass ls`, or `gopass show`
  as the normal operator path
- update preflight checks so local readiness means env or `op` access, not
  `gopass` availability

Strict audit:

- helper scripts work with env vars or 1Password and do not shell out to gopass
- repo docs no longer describe gopass as the normal local workflow
- repo preflight paths no longer depend on gopass-specific checks

### 1. Inventory Current Usage

Find current secret usage patterns:

```bash
rg -n 'gopass|GOPASS|op read|use op|op run' .
```

Identify:

- direct `gopass show` calls
- project `.envrc` secret loading
- shell wrappers or helper scripts
- duplicated provider secrets that should collapse into one shared item

### 2. Choose the Target 1Password Shape

For each live secret, decide whether it belongs in:

- an existing provider item such as `anthropic`, `openai`, or `sentry`
- an existing project item
- a new project item with multiple fields

Do not create duplicate per-project copies of shared provider credentials unless
there is a real isolation requirement.

### 3. Create or Update the 1Password Item

Create or update the target item in the `Dev` vault and use stable field names.

Example pattern:

```bash
VALUE=$(gopass show -o path/to/secret)
op item create --vault Dev --account my.1password.com \
  --category "API Credential" --title "item-name" \
  --tags "scope:project,project:my-project" \
  "field-name=$VALUE"
```

For an existing item:

```bash
op item edit "item-name" --vault Dev --account my.1password.com \
  "new-field=$(gopass show -o path/to/new-secret)"
```

Always check for an existing item first so you do not create duplicates.

### 4. Update the Repo to Use `op`

Small project `.envrc` pattern:

```bash
use mise
use op
export API_KEY=$(op read "op://Dev/service/api-key")
```

For larger environments:

```bash
use mise
use op
eval "$(op run --env-file=.env.1p -- env)"
```

### 5. Verify the Repo

Check the new path works without exposing secret values unnecessarily:

```bash
op read --account my.1password.com "op://Dev/service/api-key" >/dev/null && echo ok
```

Also verify:

- project `direnv` load succeeds
- tests or smoke checks still pass
- no plaintext secrets were introduced
- no user-global config file now contains expanded tokens

### 6. Remove Live gopass Usage

After verification, remove the repo’s live gopass references:

```bash
rg -n 'gopass' .
```

Archived or intentionally historical references are acceptable only when they
are clearly marked as archive material.

## Remaining System Work

The remaining work after `system-config` baseline completion is:

1. migrate `scopecam-engine` and `hetzner`, the two highest-value remaining
   live consumers
2. clear remaining helper and tooling repos such as `cloudflare-management`
   and any late-discovered live gopass surfaces
3. consolidate duplicated secrets into the correct shared or project
   1Password items, especially shared Hetzner, Cloudflare, and Infisical
   credentials
4. keep [`docs/secrets.md`](./secrets.md) current if the live operating rules
   change
5. remove remaining external gopass guidance once there are no active consumers
6. remove gopass entirely when the retirement criteria are met

## gopass Retirement Criteria

gopass can be removed only when all of the following are true:

- no active repo `.envrc`, script, wrapper, or automation path uses `gopass`
- no active external machine-level workflow depends on gopass
- active repos have migrated their live secrets to 1Password
- no loose plaintext secrets remain in repo files or user-global config
- `system-config` and active repos verify successfully through `op`

When those conditions are met:

1. remove final external gopass guidance such as `~/.config/gopass/README-AGENTS.md`
2. remove `.gopass/**` handling from `home/.chezmoiignore` if no longer needed
3. delete any remaining repo docs that only describe archived gopass operation
4. uninstall or otherwise retire gopass from the machine

## Current gopass Residue

The remaining useful context about gopass is operational, not historical:

- archive store location: `~/.local/share/gopass/stores/root/`
- config location: `~/.config/gopass/config`
- local machine notes: `~/.config/gopass/README-AGENTS.md`
- unlock and recovery handling remains machine-local and must not be copied into repo docs

That residue exists only to support repo-by-repo extraction into 1Password
until all active consumers are migrated. It is not part of the live
`system-config` contract.

## Useful Checks

```bash
op vault get Dev --account my.1password.com >/dev/null
ng-doctor tools
op read --account my.1password.com "op://Dev/github-dev-tools/token" >/dev/null && echo github ok
op read --account my.1password.com "op://Dev/brave-search/api-key" >/dev/null && echo brave ok
op read --account my.1password.com "op://Dev/firecrawl/api-key" >/dev/null && echo firecrawl ok
```

## Related

- [Secrets Handling](./secrets.md)
- [Agentic Tooling](./agentic-tooling.md)
