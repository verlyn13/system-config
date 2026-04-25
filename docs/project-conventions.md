---
title: Project Conventions
category: reference
component: project_conventions
status: active
version: 1.2.0
last_updated: 2026-04-24
tags: [project, conventions, 1password, mcp, mise, ssh, compatibility, rate-limit]
priority: high
---

# Project Conventions

Compatibility guide for any repo that runs on this workstation. Downstream
projects can link to this doc from their own `AGENTS.md`, `CLAUDE.md`, or
`README.md` to declare which system-config conventions they follow.

Authoritative sources are cross-linked throughout. This doc consolidates
the consumer-facing slices; it does not override the authoritative
documents.

## TL;DR compliance checklist

A project is "system-config compatible" when it:

- Pins its own runtimes in `.mise.toml` (does not depend on the global baseline)
- Uses `.envrc` for project-scoped env and secret loading only
- Never commits secret values; references 1Password via `op://` URIs
- Commits `.mcp.json` (and peers) for team-shared MCP servers, if any
- Nominates one broker for shared control-plane MCP mutations during releases
- Uses Conventional Commits, signed via SSH signing
- Assumes OpenSSH-compatible remotes; no hard dependency on private key filenames
- Uses zsh/POSIX semantics in hook scripts and subshells

## Files to commit

| File | Purpose | Required |
|------|---------|----------|
| `.mise.toml` | Tool/runtime versions + local task surface | yes |
| `.envrc` | Project-scoped env, secret loading (`use mise`, `use op`) | if project needs env/secrets |
| `AGENTS.md` | Canonical cross-tool project contract | yes |
| `CLAUDE.md` | Claude-specific project guidance (can alias `AGENTS.md`) | if used |
| `.mcp.json` | Claude Code project MCP servers | if used |
| `.cursor/mcp.json` | Cursor project MCP servers | if used |
| `.codex/config.toml` | Codex project MCP (requires user-side trust opt-in) | if used |
| `.copilot/mcp-config.json` | Copilot CLI project MCP | if used |
| `.workspace/workspace.toml` | Workspace identity, labels, service categories | if workspace-enrolled |
| `.infisical.json` | Infisical scope — config only, not a secret | if project uses Infisical |

## Files to gitignore

```
.env
.env.local
.claude/settings.local.json
.cursor/mcp.local.json
.codex/auth.json
```

If the project commits an op-reference file (e.g. `.env.1p`), verify
before every commit that it contains only `op://` URIs — no raw values.

## 1Password

This workstation uses 1Password as the sole secrets store. Some projects
additionally use Infisical for runtime application secrets; the scope
split lives in [`docs/secrets.md`](./secrets.md) § Infisical.

### Account and vault

- **Account**: `my.1password.com`
- **Primary vault**: `Dev`
- **Desktop-app integration**: yes (CLI ↔ desktop agent)
- **Readiness check**:

  ```bash
  op vault get Dev --account my.1password.com >/dev/null
  ```

  Do not use `op whoami` alone as a readiness signal — under desktop-app
  integration it can report ok without the `Dev` vault being reachable.

### Item and field naming

| Rule | Example |
|------|---------|
| kebab-case item names | `github-happy-patterns` |
| kebab-case field names | `api-key`, `token` |
| One item per logical credential group | `brave-search` holds only `api-key` |
| Name by purpose when a provider has multiple creds | `github-dev-tools` vs `github-mcp` vs `github-happy-patterns` |
| Use tags for metadata | `scope:*`, `provider:*`, `project:*` |

Existing repo-owned items — live `op://` contracts; renaming requires
updating every consumer in the same change:

| Item | Field | Purpose |
|------|-------|---------|
| `github-dev-tools` | `token` | General `verlyn13` GitHub PAT (`gh` CLI, misc tooling) |
| `github-mcp` | `token` | Fine-grained PAT for GitHub MCP (`verlyn13` identity) |
| `github-happy-patterns` | `token` | Fine-grained PAT for `happy-patterns` identity |
| `ssh-github-happy-patterns` | (SSH key item) | 1P-managed ed25519 for `happy-patterns` identity (auth + signing) |
| `brave-search` | `api-key` | Brave Search MCP |
| `firecrawl` | `api-key` | Firecrawl MCP |
| `runpod-api` | `api-key` | Runpod MCP (`@runpod/mcp-server`) |
| `cloudflare-mcp-jefahnierocks` | `token` | Cloudflare API MCP (account-scoped, 30-day TTL during build-out) |

### CLI commands that work

Validated patterns for everyday project use:

```bash
# Readiness
op vault get Dev --account my.1password.com >/dev/null && echo "op ok"

# Single-value read
op read --account my.1password.com "op://Dev/<item>/<field>"

# Wrap a command with resolved env from an op:// manifest
op run --account my.1password.com --env-file=.env.1p -- <command>

# Verify a manifest resolves, without printing values
op run --account my.1password.com --env-file=$HOME/.config/mcp/common.env -- \
  bash -c 'for v in GITHUB_PAT BRAVE_API_KEY FIRECRAWL_API_KEY; do
    [[ -n "${!v:-}" ]] && echo "$v ok" || echo "$v MISSING"
  done'
```

Explicit `--account my.1password.com` is preferred in repo-owned code;
bare `op read` works interactively but is less portable across machines.

Never do:

- Write resolved secrets into user-global config (`~/.claude.json`, `~/.codex/config.toml`, IDE MCP JSON)
- Export secrets globally in shell init (`.zshrc`, `.zshenv`)
- Use `op whoami` alone as a readiness probe in scripts
- Commit a `.env` with resolved values (the op-reference file is `.env.1p`-style, URIs only)

### Agent authorization

Agents MAY:

- Run `op read` when a task requires runtime secret resolution
- Use repo-owned wrappers that resolve secrets at launch
- Run limited diagnostics like `op vault get Dev --account my.1password.com`

Agents MUST NOT, without explicit human direction:

- Create, edit, or reorganize 1Password items
- Broadly inventory vault contents
- Materialize secrets into persistent config files

### Project `.envrc` patterns

Small env surface — direct `op read`:

```bash
use mise
use op
export API_KEY=$(op read "op://Dev/service/api-key")
```

Larger env surface — committed op-reference file:

```bash
use mise
use op
eval "$(op run --env-file=.env.1p -- env)"
```

`.env.1p` contains only `op://` URIs. Safe to commit, but verify before
each commit that no raw values were added.

### Infisical compatibility

For projects that use self-hosted Infisical (`https://infisical.jefahnierocks.com`):

- `.infisical.json` is configuration, not a secret — check it in
- Treat fallback paths as requirement-driven, not outage-driven: if Infisical does not yield the full non-empty required set, fall back intentionally to `op read` against the canonical 1Password bootstrap item
- Validate every `infisical` CLI flag against the installed CLI; training-data habits are not authoritative
- Current CLI rejects: `--project-slug`, `--format shell` — do not use
- Valid `infisical export --format` values: `dotenv`, `dotenv-export`, `csv`, `json`, `yaml`. Prefer `dotenv-export` for shell sourcing
- An availability gate must check the exact non-empty secrets the workflow requires; "path returns something" is not equivalent to "required vars are importable and non-empty"
- Never hide stderr (`2>/dev/null`) during first-pass validation
- Full rules: [`docs/secrets.md`](./secrets.md) § Infisical

## Runtime and environment (mise + direnv)

### Global baseline

The workstation provides a global `mise` baseline (common runtimes including
the current stable Rust toolchain with `cargo`, `rustc`, and Clippy). This
is a convenience layer, not the project contract.

### Project contract

Projects must:

- Pin their own runtime versions in `.mise.toml`
- Use `use mise` in `.envrc` (not custom PATH surgery)

Projects should not:

- Depend on the global baseline being a specific version
- Add `rustup` bootstrap logic when `mise` activation is sufficient
- Ship `.venv/bin/*` or absolute paths in their command contract

### Command surface

Prefer relocatable commands over path-bound wrappers:

- `uv run python -m pytest` over `.venv/bin/pytest`
- `bun x tsx …` over absolute paths
- `npx @scope/tool` over `./node_modules/.bin/tool`

Projects move between paths (local → workspace host). Direct venv
shebangs can go stale after a repo move.

### `.envrc` scope

Keep `.envrc` narrow. Use it for:

- project-scoped env vars
- project-scoped secret loading
- minimal activation glue (`use mise`, `use op`)

Do not use it for:

- substrate choice (OrbStack vs Podman vs something else)
- broad user-global exports
- hidden bootstrap logic required to make the repo executable

There is no global `~/.envrc` on this system; helpers live in
`~/.config/direnv/direnvrc`. Do not create a global `~/.envrc`.

## MCP in projects

Full framework: [`docs/mcp-config.md`](./mcp-config.md). Consumer-facing summary:

### What stays user-global

The workstation syncs a baseline across Claude Code, Codex, Cursor,
Windsurf, and Copilot: `github`, `brave-search`, `firecrawl`, `context7`,
`memory`, `sequential-thinking`, `runpod`, `runpod-docs`, `cloudflare`,
and `cloudflare-docs`. Projects do not need to re-declare these.

Shared control-plane servers such as `cloudflare` and `runpod` are not
serialized by the user-level baseline. During coordinated release or incident
work, one owner repo/agent should perform mutations while sibling agents stay
read-only. On HTTP 429, record `last_<plane>_mcp_429: <iso8601>` in the owner
repo's current-state doc and defer traffic for at least 5 minutes or the
longer `Retry-After` window. Cloudflare-specific details live in
[`docs/cloudflare-mcp.md`](./cloudflare-mcp.md).

### What goes in the project

Team-shared project-specific MCP servers go in committed files:

| Host | File |
|------|------|
| Claude Code | `.mcp.json` |
| Cursor | `.cursor/mcp.json` |
| Codex | `.codex/config.toml` (user must opt in with `trust_level = "trusted"`) |
| Copilot CLI | `.copilot/mcp-config.json` |
| Windsurf | no project scope — document the server in `AGENTS.md` for manual user-level addition |

Use `${VAR}` placeholders for every secret; never commit resolved values.

Example `.mcp.json`:

```json
{
  "mcpServers": {
    "sentry": { "type": "http", "url": "https://mcp.sentry.dev/mcp" },
    "postgres-dev": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub", "--dsn", "${DEV_DB_URL}"]
    }
  }
}
```

Provide `DEV_DB_URL` via `.envrc` + `op read`, or via `op run` at launch.
Never put the DSN directly in `.mcp.json`.

## SSH and Git signing

Full policy: [`docs/ssh.md`](./ssh.md). Consumer-facing summary:

- Assume OpenSSH-compatible remote URLs and hostnames
- Human interactive SSH uses the 1Password SSH agent; private keys are typically not on disk
- `ForwardAgent no` is the default — do not require forwarding unless documented
- `IdentitiesOnly yes` is the default
- **Signed commits are required.** Current implementation is SSH-based Git signing (`gpg.format=ssh`, `op-ssh-sign` via the 1Password-managed key)
- Do not reuse workstation human identities as CI/automation credentials — use deploy keys, GitHub Apps, OIDC, or explicitly scoped machine identities

Projects must NOT assume:

- A specific SSH alias exists on every workstation
- Private keys are present on disk at a given filename
- User-global shell aliases are part of the project contract

If a project needs a specific SSH flow (bastion, jump host, non-default
alias), document it in the project's `AGENTS.md` or `.workspace/workspace.toml`.

## Shell contract

- zsh is the only managed interactive shell
- bash is for scripts and subprocesses
- fish is not a supported agent shell on this system

Project hook and integration scripts should target zsh or POSIX
semantics. Do not emit fish-only helpers for agent tooling.

Project shell scripts should be:

- `shellcheck`-clean
- formatted with `shfmt` where relevant
- portable: do not use bash-only constructs under `#!/bin/sh`

## Version control

- **Conventional Commits**: `type(scope): description`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`
- **Branch names**: `type/short-description` (e.g., `feat/user-auth`, `fix/memory-leak`)
- **Signed commits**: required (SSH signing via 1Password agent)
- **Atomic commits**: one logical change per commit

## Workspace enrollment (optional)

If a project opts into workspace management, see
[`docs/workspace-management.md`](./workspace-management.md). Consumer summary:

- `.workspace/workspace.toml` owns identity, lifecycle, labels, service categories, requested limits
- `.workspace/README.md` gives a short human-readable contract summary
- `system-config` owns the substrate boundary and launcher shape
- User-level config owns exact project enrollment and host ceilings

Projects may be workspace-compatible in multiple modes: local-process,
enrolled with `driver = "none"`, or fully workspace-managed. Compatibility
does not require every project to be containerized.

## Tool-native user configs (not synced)

These live outside `scripts/sync-mcp.sh` and are not part of the managed
baseline. Projects should not assume specific content here:

| Tool | User-level config | Scope |
|------|-------------------|-------|
| Claude Code permissions | `~/.claude/settings.json` | hand-managed, not chezmoi |
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` | separate product |
| Gemini CLI | tool-native | unmanaged for MCP sync |

Do not add project-specific allow/deny rules to `~/.claude/settings.json`.
Keep those in the project's `.claude/settings.json`.

## Verification

Useful checks for a project to run on initial setup or in a doctor command:

```bash
# 1Password reachable, Dev vault accessible
op vault get Dev --account my.1password.com >/dev/null && echo "op ok"

# Project's op:// references all resolve (replace VAR with expected name)
op run --account my.1password.com --env-file=.env.1p -- \
  bash -c '[[ -n "${VAR:-}" ]] && echo "VAR ok" || echo "VAR MISSING"'

# Runtime pins active
mise current
mise doctor

# direnv activation
direnv status
direnv allow  # first time in a new checkout

# Signed commits configured
git config --get gpg.format      # expect: ssh
git config --get commit.gpgsign  # expect: true

# Shell scripts clean
shellcheck scripts/*.sh
```

## Related authoritative docs

| Concern | Doc |
|---------|-----|
| 1Password policy | [`docs/secrets.md`](./secrets.md) |
| MCP framework | [`docs/mcp-config.md`](./mcp-config.md) |
| GitHub MCP specifics | [`docs/github-mcp.md`](./github-mcp.md) |
| Cloudflare MCP specifics | [`docs/cloudflare-mcp.md`](./cloudflare-mcp.md) |
| SSH and Git signing | [`docs/ssh.md`](./ssh.md) |
| Shell and tool contract | [`docs/agentic-tooling.md`](./agentic-tooling.md) |
| Workspace management | [`docs/workspace-management.md`](./workspace-management.md) |
| System-wide agent contract | [`../AGENTS.md`](../AGENTS.md) |
