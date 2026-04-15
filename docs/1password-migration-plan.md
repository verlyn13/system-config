---
title: 1Password CLI Migration Plan
category: reference
component: secrets_migration
status: active
version: 2.0.0
last_updated: 2026-04-14
tags: [1password, op, secrets, gopass, migration, direnv, mcp]
priority: high
---

# 1Password CLI Migration Plan

Full audit of the system-config secret surface and the changes required to
migrate from gopass to 1Password CLI (`op`) with biometric unlock.

## Current State

### What is already in place

| Component | Status | Notes |
|-----------|--------|-------|
| `op` CLI | Installed (2.32.1) | `brew install --cask 1password-cli` already done |
| 1Password app integration | **Needs manual step** | Settings > Developer > Integrate with 1Password CLI |
| Touch ID | Likely enabled | Confirm in 1Password > Settings > Security |
| `op vault list` | **Verified** | Biometric prompt works, vaults visible |
| direnv | Installed + hooked | `03-direnv.zsh` (zsh), `dot_bashrc.tmpl` (bash) |
| direnvrc helpers | `use_mise`, `dotenv`, `dotenv_if_exists` | No 1Password helper yet |
| direnv.toml | Forces Homebrew bash | Prevents macOS Sequoia `/bin/bash` segfaults |
| `.gitignore` | Covers `.env`, `.env.*`, `.envrc.local` | `.envrc` intentionally NOT ignored (safe with `op://` URIs) |
| `.chezmoiignore` | Covers secrets, env files, `.gopass/**` | Correct |
| Global gitignore | `~/.config/git/ignore` | Contains only `.claude/settings.local.json` (repeated ~100x, likely a bug) |
| Global gitignore template | None | Not managed by chezmoi in this repo |

### The gopass surface (what we are replacing)

#### Code: MCP runtime wrappers

Three wrappers under `home/dot_local/bin/` use a fallback chain:
env var > gopass > fail.

| File | Env var | Gopass path |
|------|---------|-------------|
| `executable_mcp-github-server.tmpl` | `GITHUB_PERSONAL_ACCESS_TOKEN` | `github/dev-tools-token` |
| `executable_mcp-brave-search-server.tmpl` | `BRAVE_API_KEY` | `brave/api-key` |
| `executable_mcp-firecrawl-server.tmpl` | `FIRECRAWL_API_KEY` | `firecrawl/api-key` |

#### Code: ng-doctor

`home/dot_local/bin/executable_ng-doctor.tmpl` has:
- `check_gopass_installed()` function (line 221)
- Called in `run_tools_checks()` (line 264)
- Listed in `list_checks()` output (line 583)

#### Config: Claude Code permissions

`.claude/settings.json` allows:
```json
"Bash(gopass show:*)",
"Bash(gopass ls:*)",
"Bash(gopass insert:*)"
```

Also has two stale entries:
```json
"Bash(./scripts/doctor-path.sh:*)",
"Bash(./ai-tools/sync-to-tools.sh:*)"
```
Both scripts were deleted in Phase 3.

#### Documentation

| File | Lines | Reference |
|------|-------|-----------|
| `AGENTS.md` | 107, 149-150 | gopass paths, gopass guide pointer |
| `README.md` | 95-98 | "Secrets are managed with gopass" |
| `docs/agentic-tooling.md` | 146, 152-158, 186 | Wrapper table with gopass paths, operational rules |
| `docs/gopass-guide.md` | entire file | Gopass quick-start and usage patterns |
| `docs/claude-cli-setup.md` | 41, 66 | "gopass-at-runtime wrappers", troubleshooting |
| `docs/codex-cli-setup.md` | 41 | "gopass entry used by the runtime wrapper" |
| `docs/sentry-cli-setup.md` | 32 | `gopass show -o sentry/auth-token` |
| `policies/version-policy.md` | 53 | "gopass/age provides secure credential management" |

#### CI

`.github/workflows/repo-validation.yml` line 37 lists `docs/gopass-guide.md`
in the contract validation grep. If the file moves or is renamed, CI will need
updating.

#### External files (not in this repo)

| File | Content |
|------|---------|
| `~/.config/gopass/README-AGENTS.md` | Agent quick-reference with passphrase, paths, commands |
| `~/.config/gopass/config` | Store config |
| `~/.local/share/gopass/stores/root/` | Encrypted store (~300+ entries) |

### Gopass store inventory

The gopass store contains secrets spanning many services. The three secrets
actively used by this repo's MCP wrappers are:

- `github/dev-tools-token`
- `brave/api-key`
- `firecrawl/api-key`

The remaining ~300 entries are used by project `.envrc` files, Terraform,
infrastructure configs, and CI pipelines. These migrate opportunistically
as each project is touched.

---

## Gopass Taxonomy Audit

The gopass store (~300 entries) grew organically with at least five competing
top-level patterns. Understanding what went wrong informs the 1Password
naming standard.

### Competing patterns in gopass

| Pattern | Top-level dirs | Example |
|---------|----------------|---------|
| Provider-first | `cloudflare/`, `github/`, `anthropic/`, `openai/`, `gemini/` | `github/dev-tools-token` |
| Project-first | `budget-triage/`, `dicee/`, `ship-game/` | `budget-triage/database-url-dev` |
| Role/scope-first | `development/`, `shared/`, `services/` | `development/anthropic/api-key` |
| Infra-first | `infra/`, `terraform/` | `infra/hetzner/s3/access-key-id` |
| Tool-first | `codex/`, `llm-gateway/` | `codex/openai/api-key` |

### Resulting fragmentation

The same logical credential appears in multiple locations:

- **Anthropic API key** found in 5 places: `anthropic/api-keys/general`,
  `ai/anthropic/`, `development/anthropic/api-key`,
  `services/anthropic/synthetic-council`, `llm-gateway/anthropic-api-key`
- **OpenAI API key** found in 4 places: `openai/api-keys/budget-triage`,
  `codex/openai/api-key`, `development/openai/api-key`,
  `llm-gateway/openai-api-key`
- **Brave API key** found in 3 places: `brave/api-key`,
  `services/brave/api-key`, plus env var references
- **GitHub tokens** scattered across `github/dev-tools-token`,
  `github/mcp-servers-token`, `github/windsurf-mcp-token`,
  `shared/github/api-token`

When adding a new secret, there was no single rule for where it goes. Over
time this made the store increasingly difficult to navigate and audit.

### What the Nash Group governance says

The parent org defines clear naming and labeling principles that were never
consistently applied to the secret store:

- **GOV-010 Labeling Standard**: Every resource requires `project_id`,
  `owner`, `tier`, and `environment` labels.
- **IAM Framework**: Identities follow `{type}:{subtype}:{identifier}`
  naming.
- **Subsidiary Prefixes**: `jfr` (jefahnierocks), `hp` (happy-patterns),
  `les` (litecky-editing), `ss` (seven-springs).
- **Kebab-case**: Standard for all paths, directories, and identifiers.
- **Three Circles of Trust**: L0 (frontier), L1 (vanguard), L2 (supporting)
  for dependency tiers; applicable to secret rotation and access policy.

### Root cause

gopass stores one value per file in a flat filesystem. There is no native
concept of multi-field items, tags, or sections. Naming conventions must
carry all the structure, and without enforcement they drifted.

---

## Naming Standard

### 1Password data model vs. gopass

| Concept | gopass | 1Password |
|---------|--------|-----------|
| Namespace | Vault (single store) | Vault (multiple vaults, access-controlled) |
| Grouping | Directory path | Item (multi-field, with sections) |
| Secret value | Single file per path | Field within an item |
| Metadata | None (path is all you get) | Tags, categories, sections, notes |
| Access control | GPG/age recipient list | Vault membership + per-item sharing |
| Search | `gopass ls`, `gopass find` | 1Password GUI search, `op item list --tags` |

The key shift: **gopass forces the path to carry all meaning. 1Password
moves metadata into tags and sections, letting item names stay short and
focused.**

### Account pinning

This machine has one 1Password account:

| Field | Value |
|-------|-------|
| URL | `my.1password.com` |
| Email | `jeffrey@happy-patterns.com` |
| User ID | `SACNSLHQNZEMRGHY7SSNEPZXZU` |

Without explicit account selection, `op` runs against the most recently
signed-in account. On a single-account machine this is fine today, but
becomes ambiguous if a second account (team, subsidiary) is added later.

**Rule**: All repo-owned wrappers pass `--account my.1password.com`
explicitly. This makes the wrapper behavior deterministic regardless of
ambient shell state. Project `.envrc` files do not need `--account` because
direnv inherits the wrapper's account context and only one account exists.

If a second account is ever added, revisit whether `OP_ACCOUNT` should be
exported in the managed shell surface (`03-direnv.zsh` or `direnvrc.tmpl`)
rather than passed per-wrapper.

### Vault strategy

Use vault boundaries to separate trust domains, not organizational units.
The critical distinction is **human-interactive** vs **headless/automated**.

| Vault | Scope | Trust boundary | Auth model |
|-------|-------|----------------|------------|
| `Dev` | Local dev tooling, API keys, project secrets, MCP wrappers | Personal dev machine, system-config scope | Desktop app + Touch ID |
| `Personal` | 1Password default vault | Personal accounts, passwords, non-dev | Desktop app + Touch ID |
| Future: `Infra` | Terraform state encryption, CI tokens, Hetzner/Cloudflare IaC | Infrastructure-as-code, Citadel-level | Desktop app or service account |
| Future: `Automation` | Headless CI, remote runners, daemonized access | Machine trust domain | Service account only |
| Future: subsidiary-specific | Per-subsidiary when shared team access is needed | Team trust boundary | Per-team |

**Human laptop = app integration. Headless machine = service account.**

1Password positions service accounts as the least-privilege path for
programmatic use. They are better suited to headless environments than
desktop-app integration. This migration does not create service accounts
(the three MCP wrappers run on the interactive workstation), but the
architecture should not assume desktop-app auth is the only path.

For this migration (system-config scope), everything goes in `Dev`. The
vault boundary is the coarsest access control. Within the vault, tags carry
the organizational metadata.

### Item naming rules

Items are the primary object in 1Password. They appear in the GUI, in
`op item list` output, and as the second segment of `op://` URIs.

**Rule 1: Kebab-case, always.**

```
github-dev-tools       # correct
github_dev_tools       # wrong (snake_case)
GitHubDevTools         # wrong (PascalCase)
```

Consistent with Nash Group file and directory naming (GOV-010).

**Rule 2: Name by purpose, not by provider alone.**

A bare provider name (`github`, `cloudflare`) works only when there is
exactly one logical use of that provider. When multiple credentials exist
for the same provider, qualify the name by purpose:

```
github-dev-tools       # PAT for dev tooling (MCP wrappers, gh CLI)
github-mcp-servers     # PAT scoped to MCP server repos (if separate)
github-windsurf        # PAT for Windsurf IDE integration (if separate)
```

If you genuinely have one credential per provider, the bare name is fine:

```
brave-search           # only one Brave credential
firecrawl              # only one Firecrawl credential
```

**Rule 3: One item per logical credential group. Use fields, not items,
for the individual values.**

A project with three secrets becomes one item with three fields, not three
items:

```
Item: budget-triage
  Fields: database-url, plaid-client-id, plaid-secret

op://Dev/budget-triage/database-url
op://Dev/budget-triage/plaid-client-id
op://Dev/budget-triage/plaid-secret
```

A provider with environment-specific keys uses sections:

```
Item: anthropic
  Section: (default)
    Field: api-key              # primary dev key
  Section: project-keys
    Field: email-corpus-key
    Field: shell-budget-key

op://Dev/anthropic/api-key
op://Dev/anthropic/project-keys/email-corpus-key
```

**Rule 4: Field names use kebab-case and describe the value, not the
provider.**

```
api-key                # correct
credential             # correct (for generic tokens)
ANTHROPIC_API_KEY      # wrong (env var name, not field name)
password               # ok for actual passwords
token                  # ok for bearer/access tokens
```

**Rule 5: Use 1Password tags for metadata that gopass encoded in paths.**

Instead of `development/anthropic/api-key` vs `services/anthropic/api-key`
vs `shared/ai/anthropic-api-key`, there is one `anthropic` item tagged
appropriately:

```
Item: anthropic
  Tags: provider:anthropic, scope:global, subsidiary:jfr, tier:core
```

### Tag taxonomy

Tags carry the organizational metadata that GOV-010 requires. Keep them
structured as `category:value` pairs.

| Tag prefix | Purpose | Values | Required |
|------------|---------|--------|----------|
| `scope` | Where the secret is used | `global`, `project`, `infra`, `ci` | **Always** |
| `provider` | External service | `github`, `cloudflare`, `anthropic`, etc. | **When scope is global or infra** |
| `project` | Project identifier | `budget-triage`, `dicee`, etc. | **When scope is project** |
| `subsidiary` | Nash Group subsidiary owner | `jfr`, `hp`, `les`, `ss`, `tng` | When shared, infra, or org-scoped |
| `tier` | Criticality (Three Circles) | `core`, `platform`, `application`, `experimental` | When shared, infra, or org-scoped |

**Minimum tag set**: every item gets `scope:*` plus either `provider:*` or
`project:*`. Items that cross subsidiary boundaries or have infrastructure
scope also get `subsidiary:*` and `tier:*`. This is not optional — it is
how GOV-010 labeling applies to the secret store.

### Category selection

1Password categories help with GUI organization. Use these consistently:

| Category | When to use |
|----------|-------------|
| API Credential | API keys, tokens, service credentials |
| Login | Username + password combinations |
| Secure Note | Configuration values, connection strings, compound secrets |
| SSH Key | SSH key material (1Password can manage these natively) |

### Applied to system-config scope

The three MCP wrapper secrets and common dev credentials:

| Item name | Category | Fields | op:// URI | Tags | Replaces gopass |
|-----------|----------|--------|-----------|------|-----------------|
| `github-dev-tools` | API Credential | `token` | `op://Dev/github-dev-tools/token` | `scope:global`, `provider:github` | `github/dev-tools-token` |
| `brave-search` | API Credential | `api-key` | `op://Dev/brave-search/api-key` | `scope:global`, `provider:brave` | `brave/api-key` |
| `firecrawl` | API Credential | `api-key` | `op://Dev/firecrawl/api-key` | `scope:global`, `provider:firecrawl` | `firecrawl/api-key` |

Additional provider credentials (migrate as used):

| Item name | Fields | op:// URI | Replaces gopass |
|-----------|--------|-----------|-----------------|
| `anthropic` | `api-key` | `op://Dev/anthropic/api-key` | `development/anthropic/api-key` et al. |
| `openai` | `api-key` | `op://Dev/openai/api-key` | `development/openai/api-key` et al. |
| `gemini` | `api-key` | `op://Dev/gemini/api-key` | `gemini/api-keys/development` |
| `sentry` | `auth-token` | `op://Dev/sentry/auth-token` | `sentry/happy-patterns-llc/auth-token` |
| `elevenlabs` | `api-key` | `op://Dev/elevenlabs/api-key` | `elevenlabs/wynisbuff2-api-key` |

Project credential items (migrate as projects are worked on):

| Item name | Fields | op:// URI |
|-----------|--------|-----------|
| `budget-triage` | `database-url`, `plaid-client-id`, `plaid-secret` | `op://Dev/budget-triage/{field}` |
| `dicee` | `supabase-key`, `elevenlabs-key`, etc. | `op://Dev/dicee/{field}` |
| `kbe-website` | `vercel-cron-secret`, etc. | `op://Dev/kbe-website/{field}` |

### Why `github-dev-tools` and not `github`

The gopass store has five GitHub tokens (`dev-tools-token`,
`hubofwyn-token`, `mcp-servers-token`, `windsurf-mcp-token`,
`litecky/oauth/*`). A bare `github` item would either:

1. Become a catch-all with unrelated fields, or
2. Need renaming later when a second GitHub item is added.

`github-dev-tools` is specific to purpose, leaves room for
`github-mcp-servers` or `github-litecky-oauth` without conflict, and
follows Rule 2 (name by purpose). The field is just `token` because the
item name already carries the context.

If the other GitHub tokens turn out to be the same PAT referenced from
different gopass paths (duplication, not separate tokens), they collapse
into one item with one field. Either way, the naming holds.

### Reference stability

Once an `op://` URI appears in repo-owned runtime code (MCP wrappers,
chezmoi templates, `direnvrc`), the vault name, item title, and field
label become an API contract. Renaming any segment breaks the wrapper.

**Rule**: Do not rename vault, item, or field labels that are referenced
in repo-owned code without updating every consumer in the same commit.
Treat these references the same way you treat import paths or CLI flags —
they are part of the contract surface.

1Password also supports unique-ID-based references
(`op://vault-id/item-id/field-id`) which survive renames. For
machine-managed wrappers, switching to ID-based references after initial
creation is an option if rename resilience becomes important. For now,
human-readable names are preferred because they are self-documenting in
`.envrc` files and wrapper error messages.

### What this prevents

The old fragmentation patterns cannot recur because:

- **No scope directories**: scope is a tag, not a path prefix. There is no
  `development/` vs `services/` vs `shared/` to choose between.
- **No provider-vs-project ambiguity**: items are either named for a
  provider (`anthropic`) or a project (`budget-triage`), never both in the
  same name. Tags disambiguate.
- **No duplication incentive**: each logical credential is one item. If a
  project needs the Anthropic key, the `.envrc` references
  `op://Dev/anthropic/api-key` — the same item the MCP wrapper or any other
  consumer uses.

---

## Auth Model

Local interactive use is authenticated through the 1Password desktop app
with Touch ID. This is not "session inheritance" — the 1Password security
model explicitly ties authorization to the app/process being approved.
Each terminal window or application gets its own authorization, with a
10-minute session that refreshes on use.

**Required operational state** (not trivia — 1Password documents connection
failures when these are off):

- 1Password app > Settings > General > **Keep 1Password in the menu bar**: on
- 1Password app > Settings > General > **Allow in background**: on
- 1Password app > Settings > Developer > **Integrate with 1Password CLI**: on
- 1Password app > Settings > Security > **Touch ID**: on

## Integration Patterns

This system uses three distinct secret-access patterns, matched to the
consumer's shape. Do not collapse them into one.

### Pattern 1: Global MCP wrappers

Fallback chain: env var > `op read --account my.1password.com` > fail.

Used by the three MCP runtime wrappers in `~/.local/bin/`. These run as
subprocesses of the terminal where the agent tool (Claude Code, Codex,
Cursor) is launched. The desktop app handles auth for the parent terminal;
`op` in the subprocess is authorized through the same app integration.

If no interactive session exists (headless CI, remote runner), the env var
path must be used instead. Wrappers do not attempt to authenticate — they
either have a session or they fail with a diagnostic message.

### Pattern 2: Project `.envrc` files

Small project `.envrc` files use `use op` (for validation) plus direct
`op read` calls:

```bash
use mise
use op
export DATABASE_URL=$(op read "op://Dev/budget-triage/database-url")
export PLAID_SECRET=$(op read "op://Dev/budget-triage/plaid-secret")
```

These files are safe to commit because `op://` URIs contain no secrets.
They only resolve for authenticated users with vault access.

For provider credentials shared across projects, reference the provider
item — do not create a project-specific copy:

```bash
# correct: reference the provider item
export ANTHROPIC_API_KEY=$(op read "op://Dev/anthropic/api-key")

# wrong: do not duplicate into a project item
export ANTHROPIC_API_KEY=$(op read "op://Dev/my-project/anthropic-api-key")
```

### Pattern 3: Larger app environments

For projects with many environment variables (10+), consider `op run` with
a committed secret reference file instead of individual `op read` calls.
This retrieves all secrets in a single biometric prompt:

```bash
# .envrc
use mise
use op
eval "$(op run --env-file=.env.1p -- env)"
```

Do **not** use 1Password Environments (local `.env` file mounts) as the
`system-config` baseline. See "Design Boundaries" below.

### Committable reference files

Projects can commit `.envrc.example` or `.env.1p` with `op://` URIs:

```bash
# .envrc.example (safe to commit — no secrets, only URIs)
use mise
use op
export DATABASE_URL=$(op read "op://Dev/budget-triage/database-url")
export PLAID_CLIENT_ID=$(op read "op://Dev/budget-triage/plaid-client-id")
export PLAID_SECRET=$(op read "op://Dev/budget-triage/plaid-secret")
```

### Shell plugins

1Password Shell Plugins provide transparent credential injection for human
CLI tools like `gh`, `aws`, `sentry-cli`, `terraform`, and `wrangler`.
They are opt-in for human interactive use but are **not** part of the
managed shell surface in this repo. Reasons:

- zsh startup cost is already a known issue (AGENTS.md Known Issues)
- shell plugins add hook overhead to every command invocation
- agentic shells must not depend on interactive plugin state

If adopted, scope them to interactive-only zshrc.d modules (gated behind
`NG_MODE != agentic`) and document each plugin's startup cost.

### direnvrc helper

Add a `use_op` helper to `direnvrc.tmpl` that validates `op` is available
and provides a clear error when it is not. This keeps project `.envrc` files
clean and avoids cryptic failures.

### What NOT to change

- **`.zshrc` / zshrc.d modules**: No changes needed. direnv hook is already
  in `03-direnv.zsh`. No `op`-specific shell init is required.
- **`.envrc` global gitignore**: `.envrc` should NOT be globally ignored.
  With `op://` URIs, `.envrc` files are safe to commit. The repo `.gitignore`
  already covers `.env`, `.env.*`, and `.envrc.local` for actual secret files.
- **sync-mcp.sh**: No changes needed. It syncs structure, not secrets.
  Wrappers handle secret resolution at runtime.

## Design Boundaries

These are explicit "not yet" decisions for April 2026.

### 1Password Environments

1Password Environments (local `.env` file mounts) are promising but not
mature enough to be the repo-wide default:

- Still in beta
- Not designed for concurrent readers
- Can trigger dev server restart loops (Vite, Next.js)
- Once unlocked, no distinction between processes reading the mounted file
- Agent hook validation lists Claude Code, Cursor, Copilot, and Windsurf
  as supported; Codex is not listed
- Default discovery mode "fails open" if it cannot access the database —
  too soft for governed agentic execution

If adopted in individual project repos, use configured mode with
`.1password/environments.toml`, not default discovery. Do not make
Environments part of the `system-config` baseline.

### Service accounts

Not needed for this migration. The three MCP wrappers run on the
interactive workstation with desktop-app auth. Service accounts become
relevant when secrets are needed in headless CI, remote runners, or
daemonized processes. When that happens, create an `Automation` vault
with a dedicated service account rather than sharing the `Dev` vault.

---

## Changes

### A. Code changes (this repo)

#### A1. MCP wrapper: github

**File**: `home/dot_local/bin/executable_mcp-github-server.tmpl`

Replace gopass fallback with `op read`:

```bash
#!/usr/bin/env bash
# mcp-github-server -- runtime secret wrapper for the global GitHub MCP server

set -euo pipefail

OP_ACCOUNT="my.1password.com"

load_secret() {
  if [[ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
    return 0
  fi

  if command -v op >/dev/null 2>&1; then
    GITHUB_PERSONAL_ACCESS_TOKEN="$(op read --account "$OP_ACCOUNT" \
      'op://Dev/github-dev-tools/token' 2>/dev/null || true)"
    export GITHUB_PERSONAL_ACCESS_TOKEN
  fi

  if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
    echo "mcp-github-server: set GITHUB_PERSONAL_ACCESS_TOKEN or store in op://Dev/github-dev-tools/token" >&2
    exit 1
  fi
}

load_secret
exec npx -y @modelcontextprotocol/server-github "$@"
```

#### A2. MCP wrapper: brave-search

**File**: `home/dot_local/bin/executable_mcp-brave-search-server.tmpl`

Same pattern as A1: add `OP_ACCOUNT="my.1password.com"`, replace
`gopass show -o brave/api-key` with
`op read --account "$OP_ACCOUNT" 'op://Dev/brave-search/api-key'`.

#### A3. MCP wrapper: firecrawl

**File**: `home/dot_local/bin/executable_mcp-firecrawl-server.tmpl`

Same pattern as A1: add `OP_ACCOUNT="my.1password.com"`, replace
`gopass show -o firecrawl/api-key` with
`op read --account "$OP_ACCOUNT" 'op://Dev/firecrawl/api-key'`.

#### A4. ng-doctor: replace gopass check with op readiness checks

**File**: `home/dot_local/bin/executable_ng-doctor.tmpl`

Replace the single `check_gopass_installed` with two checks that
distinguish "CLI missing" from "CLI present but not ready":

- `check_op_installed` — `command -v op` (same pattern as other tool checks)
- `check_op_ready` — runs `op whoami --account my.1password.com` to verify
  the desktop app is running, integration is enabled, and an authenticated
  session exists. Skips if `op` is not installed. Failure diagnostics
  should distinguish: app not running, integration not enabled, no
  authenticated account, wrong account.

Update `list_checks()` output and `run_tools_checks()` to call both.
The check count increases by one (gopass was 1 check, op is 2).

#### A5. direnvrc: add `use_op` helper

**File**: `home/dot_config/direnv/direnvrc.tmpl`

Add after the existing helpers:

```bash
# Validate 1Password CLI is available for op:// secret references
use_op() {
  if ! command -v op >/dev/null 2>&1; then
    log_error "1Password CLI (op) is required but not installed"
    log_error "Install: brew install --cask 1password-cli"
    return 1
  fi
}
```

Projects that use `op read` in their `.envrc` can add `use op` at the top
for early validation.

#### A6. Claude Code permissions

**File**: `.claude/settings.json`

- Replace gopass permissions with op permissions
- Remove stale script permissions

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(op read:*)",
      "Bash(op whoami:*)",
      "Bash(brew:*)",
      "Bash(shellcheck:*)",
      "Bash(chezmoi:*)",
      "Bash(mise:*)",
      "Bash(claude:*)",
      "Bash(starship:*)",
      "Bash(zsh:*)",
      "Bash(./scripts/system-update.sh:*)",
      "mcp__firecrawl__firecrawl_search",
      "mcp__sequential-thinking__sequentialthinking"
    ],
    "deny": []
  }
}
```

Changes:
- `Bash(gopass show:*)` > `Bash(op read:*)` — read-only secret access
- `Bash(gopass ls:*)` > `Bash(op whoami:*)` — diagnostic only
- `Bash(gopass insert:*)` > removed — agents should not create/edit items
- Removed: `Bash(fish:*)`, `Bash(fish_indent:*)` (fish not managed)
- Removed: `Bash(./scripts/doctor-path.sh:*)` (deleted in Phase 3)
- Removed: `Bash(./ai-tools/sync-to-tools.sh:*)` (deleted in Phase 3)

Note: `op vault list` and `op item list` are deliberately not in the
allow list. Agents need `op read` to resolve secrets and `op whoami` for
diagnostics. Broader 1Password operations are human-initiated.

### B. Documentation updates

#### B1. AGENTS.md

**Already done.** Migration status section, MCP ownership policy, and
secrets section updated to reference 1Password CLI and this plan.

#### B2. README.md

Lines 95-98: Update secrets section.

```
- Secrets are managed with gopass and project `.envrc` files.
- See [`docs/gopass-guide.md`](docs/gopass-guide.md).
+ Secrets are managed with 1Password CLI (`op`) and project `.envrc` files.
+ See [`docs/1password-migration-plan.md`](docs/1password-migration-plan.md).
```

#### B3. docs/agentic-tooling.md

Line 146: Replace gopass reference.

```
- Auth-required servers use runtime wrapper commands under `~/.local/bin/`.
  Secrets come from env vars or gopass at launch time
+ Auth-required servers use runtime wrapper commands under `~/.local/bin/`.
  Secrets come from env vars or 1Password CLI at launch time
```

Lines 152-158: Replace wrapper table.

```
| Server | Wrapper | op:// URI | Env var |
|--------|---------|-----------|---------|
| `github` | `mcp-github-server` | `op://Dev/github-dev-tools/token` | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| `brave-search` | `mcp-brave-search-server` | `op://Dev/brave-search/api-key` | `BRAVE_API_KEY` |
| `firecrawl` | `mcp-firecrawl-server` | `op://Dev/firecrawl/api-key` | `FIRECRAWL_API_KEY` |
```

Line 186: Replace operational rule.

```
- Prefer env vars, gopass-at-runtime wrappers, or tool-native login flows.
+ Prefer env vars, 1Password CLI (`op read`) at runtime, or tool-native login flows.
```

#### B4. docs/gopass-guide.md

Archive to `docs/archive/gopass-guide.md`. Add a deprecation notice and
pointer to the new pattern:

```markdown
> **Deprecated**: This system now uses 1Password CLI (`op`) for secret
> management. See `docs/1password-migration-plan.md`. Gopass remains
> installed as a cold archive until all secrets are migrated.
```

#### B5. docs/claude-cli-setup.md

Line 41: `gopass-at-runtime wrappers` > `1Password CLI wrappers`

Line 66: `fix the env var or gopass entry` >
`fix the env var or 1Password item`

#### B6. docs/codex-cli-setup.md

Line 41: `fix the env var or gopass entry` >
`fix the env var or 1Password item`

#### B7. docs/sentry-cli-setup.md

Line 32: Replace gopass example:

```bash
export SENTRY_AUTH_TOKEN=$(op read "op://Dev/sentry/auth-token")
```

#### B8. policies/version-policy.md

Line 53: `gopass/age provides secure credential management` >
`1Password CLI provides secure credential management`

#### B9. CI workflow

**File**: `.github/workflows/repo-validation.yml`

Line 37: If `docs/gopass-guide.md` is archived (moved to `docs/archive/`),
remove it from the validation file list. The contract validation grep checks
for stale references to deleted patterns -- this file just needs to be
removed from the list since it is being archived, not deleted.

### C. .chezmoiignore cleanup (deferred)

`.gopass/**` in `home/.chezmoiignore` is harmless. Remove it after gopass
is fully decommissioned. No urgency.

---

## Manual Steps (user must do)

### M1. 1Password app operational state

Verify all four settings are enabled (see "Auth Model" section):

1. Settings > General > **Keep 1Password in the menu bar**: on
2. Settings > General > **Allow in background**: on
3. Settings > Developer > **Integrate with 1Password CLI**: on
4. Settings > Security > **Touch ID**: on

Then verify:

```bash
op whoami --account my.1password.com
```

### M2. Create items in Dev vault

Migrate the three MCP wrapper secrets. These commands are idempotent —
they check for an existing item before creating, and update if it already
exists.

```bash
ACCT="my.1password.com"

# Helper: create-or-update an item in Dev vault
_op_upsert() {
  local title="$1" tags="$2"; shift 2
  if op item get "$title" --vault Dev --account "$ACCT" &>/dev/null; then
    op item edit "$title" --vault Dev --account "$ACCT" "$@"
    echo "Updated: $title"
  else
    op item create --vault Dev --account "$ACCT" \
      --category "API Credential" --title "$title" --tags "$tags" "$@"
    echo "Created: $title"
  fi
}

# GitHub dev tools token
VALUE=$(gopass show -o github/dev-tools-token)
_op_upsert "github-dev-tools" "scope:global,provider:github" "token=$VALUE"

# Brave Search API key
VALUE=$(gopass show -o brave/api-key)
_op_upsert "brave-search" "scope:global,provider:brave" "api-key=$VALUE"

# Firecrawl API key
VALUE=$(gopass show -o firecrawl/api-key)
_op_upsert "firecrawl" "scope:global,provider:firecrawl" "api-key=$VALUE"

unset -f _op_upsert
unset VALUE ACCT
```

Verify each:

```bash
op read --account my.1password.com "op://Dev/github-dev-tools/token"
op read --account my.1password.com "op://Dev/brave-search/api-key"
op read --account my.1password.com "op://Dev/firecrawl/api-key"
```

### M3. Migrate additional secrets as needed

Move secrets to 1Password as projects are actively worked on. No bulk
migration required. Use the same get-or-create pattern:

```bash
# Create new item
VALUE=$(gopass show -o path/to/secret)
op item create --vault Dev --account my.1password.com \
  --category "API Credential" --title "item-name" \
  --tags "scope:project,project:my-project" \
  "field-name=$VALUE"

# Add field to existing item
op item edit "item-name" --vault Dev --account my.1password.com \
  "new-field=$(gopass show -o path/to/new-secret)"
```

Always check if the item exists before creating to avoid duplicates.

### M4. Update project `.envrc` files

As projects are migrated, update their `.envrc` from:

```bash
export API_KEY="$(gopass show -o service/api-key)"
```

To:

```bash
use op
export API_KEY=$(op read "op://Dev/service/api-key")
```

### M5. Fix global gitignore (separate concern)

`~/.config/git/ignore` currently has `.claude/settings.local.json` repeated
~100 times. This is a bug from the legacy dotfiles repo, not managed by
system-config. Fix manually:

```bash
printf '.claude/settings.local.json\n' > ~/.config/git/ignore
```

This is not strictly part of the 1Password migration but is a hygiene item
discovered during this audit.

### M6. Clean up external gopass agent file (deferred)

After all secrets are migrated, `~/.config/gopass/README-AGENTS.md` can be
removed. It contains the gopass passphrase in plaintext and agent usage
instructions. Not urgent while gopass is still the cold archive.

---

## Verification Checklist

After code changes are applied (`chezmoi apply`):

```bash
# 1. op readiness
op whoami --account my.1password.com

# 2. ng-doctor passes with new op checks
ng-doctor tools

# 3. MCP wrappers resolve secrets via op
op read --account my.1password.com "op://Dev/github-dev-tools/token"
op read --account my.1password.com "op://Dev/brave-search/api-key"
op read --account my.1password.com "op://Dev/firecrawl/api-key"

# 4. direnvrc helper works
cd /tmp && mkdir -p op-test && cd op-test
echo 'use op' > .envrc
direnv allow
# Should succeed silently (op is installed)

# 5. Chezmoi templates render cleanly
chezmoi apply --dry-run

# 6. shellcheck passes on modified scripts
shellcheck home/dot_local/bin/executable_mcp-*.tmpl

# 7. No gopass references remain in active code
rg 'gopass' home/dot_local/bin/executable_mcp-*.tmpl
# Should return nothing

# 8. Contract docs updated
rg 'gopass' AGENTS.md README.md docs/agentic-tooling.md
# Should return nothing (gopass-guide.md is archived)
```

---

## Session Model Reference

Authorization is per terminal window or application, granted by the
1Password desktop app via Touch ID. The security model is:

- Each terminal window/tab gets one biometric prompt on first `op` use
- The session lasts 10 minutes and auto-refreshes on each `op` call
- Authorization is tied to the specific app/process being approved, not
  to "whatever subprocess tree exists"
- direnv reloads trigger `op read` on `cd`, which refreshes the session
- MCP wrapper subprocesses are authorized through the same app integration
  as their parent terminal
- Headless environments (CI, remote runners) have no desktop app — use
  env vars or service accounts there

**Failure modes to watch for**:

- 1Password app not running or not in menu bar → connection failure
- "Allow in background" disabled → intermittent connection drops
- CLI integration not enabled → `op` falls back to manual sign-in flow
- No authenticated account → `op whoami` errors (ng-doctor catches this)

---

## Migration Timeline

| Phase | Scope | When |
|-------|-------|------|
| **Now** | Code changes in this repo: MCP wrappers, ng-doctor (replace active gopass check with op readiness checks), direnvrc, settings.json, docs. Create 3 items in Dev vault. | This session |
| **Ongoing** | Migrate project secrets as each project is actively worked on | Opportunistic |
| **Later** | Archive gopass store, remove `.gopass/**` from `.chezmoiignore`, clean up `~/.config/gopass/README-AGENTS.md` | When gopass is fully inert |

---

## Related

- [Agentic Tooling](./agentic-tooling.md)
- [Claude CLI Setup](./claude-cli-setup.md)
- [Codex CLI Setup](./codex-cli-setup.md)
- [Gopass Guide (archived)](./archive/gopass-guide.md)
