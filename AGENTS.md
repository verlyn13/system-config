# AGENTS.md

Reproducible macOS development environment. `system-config` is the active
chezmoi source for the zsh-first shell surface, global mise defaults,
direnv helpers, iTerm2 dynamic profiles, nonsecret SSH client policy,
and the user-level MCP baseline.

## Authoritative docs

Read these for current state:

- [`docs/project-conventions.md`](./docs/project-conventions.md) — compatibility guide for downstream projects (link this from a project's own `AGENTS.md`)
- [`docs/secrets.md`](./docs/secrets.md) — secret-handling policy (1Password)
- [`docs/ssh.md`](./docs/ssh.md) — SSH client policy
- [`docs/security-hardening-implementation-plan.md`](./docs/security-hardening-implementation-plan.md) — audited hardening backlog and implementation plan
- [`docs/mcp-config.md`](./docs/mcp-config.md) — MCP framework (scope model, launch patterns, sync behavior)
- [`docs/github-mcp.md`](./docs/github-mcp.md) — GitHub MCP integration
- [`docs/cloudflare-mcp.md`](./docs/cloudflare-mcp.md) — Cloudflare MCP integration (Codemode usage, token scope, conventions)
- [`docs/agentic-tooling.md`](./docs/agentic-tooling.md) — shell + tool contract
- [`docs/workspace-management.md`](./docs/workspace-management.md) — workspace POC
- [`docs/claude-cli-setup.md`](./docs/claude-cli-setup.md), [`docs/codex-cli-setup.md`](./docs/codex-cli-setup.md), [`docs/copilot-cli-setup.md`](./docs/copilot-cli-setup.md), [`docs/claude-desktop-setup.md`](./docs/claude-desktop-setup.md) — per-tool setup

## Directory layout

```text
system-config/
├── home/                       # Active chezmoi source
│   ├── .chezmoidata.yaml       # Shared template data
│   ├── .chezmoiignore
│   ├── dot_zshenv.tmpl         # XDG exports
│   ├── dot_zprofile.tmpl       # PATH bootstrap
│   ├── dot_zshrc.tmpl          # Thin loader → zshrc.d/
│   ├── dot_bash_profile.tmpl
│   ├── dot_bashrc.tmpl
│   ├── dot_config/
│   │   ├── zshrc.d/            # Modular zsh config (NG_MODE gated)
│   │   ├── direnv/             # direnvrc.tmpl + direnv.toml.tmpl
│   │   ├── mise/               # Global mise config
│   │   ├── mcp/                # op-backed MCP secrets manifest (common.env)
│   │   ├── 1Password/          # 1P SSH agent config
│   │   └── starship.toml.tmpl
│   ├── dot_ssh/                # SSH client policy (config, conf.d, allowed_signers)
│   └── dot_local/bin/          # ng-doctor, system-update, MCP wrappers
├── iterm2/
│   ├── profiles/               # Dynamic profile JSONs
│   └── themes/                 # Color-only presets
├── scripts/                    # sync-mcp.sh, system-update.sh, etc.
│   └── system-update.d/        # Drop-in update plugins
├── docs/                       # Authoritative reference docs
├── policies/                   # Version policy
├── AGENTS.md                   # This file
└── CLAUDE.md                   # Claude Code shim
```

## Shell policy

- zsh is the only managed interactive shell.
- bash is a script/runtime shell only.
- fish is not part of the managed config surface. Do not add fish
  templates, fish aliases, or fish-only agent workflows.

## Chezmoi

- Source: `system-config/home/`
- Machine data: `~/.config/chezmoi/chezmoi.toml`
- Shared data: `home/.chezmoidata.yaml`
- Template rule: always use `| default` for optional keys
  ```go
  // CORRECT
  {{ if not (.headless | default false) -}}
  // INCORRECT
  {{ if not .headless -}}
  ```
- Required machine data keys: `headless` (bool), `android` (bool)

## Common commands

```bash
chezmoi apply --dry-run
chezmoi apply

ng-doctor
ng-doctor --summary

system-update
system-update --check
system-update --list

scripts/install-iterm2-profiles.sh

scripts/sync-mcp.sh
scripts/sync-mcp.sh --dry-run
```

## Secrets

- 1Password account: `my.1password.com`; primary vault: `Dev`
- Retrieval: `op read "op://Dev/<item>/<field>"`
- Readiness check: `op vault get Dev --account my.1password.com >/dev/null`
- Live policy: [`docs/secrets.md`](./docs/secrets.md)
- Never commit tokens, passphrases, or API keys.
- Never write secret values into persistent user config files.

## MCP

Global MCP servers synced by `scripts/sync-mcp.sh` (see
[`docs/mcp-config.md`](./docs/mcp-config.md) for the full inventory):

- `context7`, `memory`, `sequential-thinking`, `brave-search`, `firecrawl`
- `runpod`, `runpod-docs`, `cloudflare`, `cloudflare-docs`
- `github` (host-aware rendering; see [`docs/github-mcp.md`](./docs/github-mcp.md))

Sync targets: Claude Code CLI (`~/.claude.json`), Claude Desktop
(`~/Library/Application Support/Claude/claude_desktop_config.json`),
Cursor (`~/.cursor/mcp.json`), Windsurf
(`~/.codeium/windsurf/mcp_config.json`), Copilot CLI
(`~/.copilot/mcp-config.json`), Codex CLI (`~/.codex/config.toml`).

Policy:

- Project-specific MCP servers belong in each project's `.mcp.json`.
- User configs must not contain expanded API keys or tokens.
- Auth-required servers use runtime wrappers in `home/dot_local/bin/`
  that read from 1Password at launch.
- Claude Desktop's `claude_desktop_config.json` is synced too, but only
  the `mcpServers` block — `globalShortcut`, `preferences`, and any
  user-added servers outside the managed set are preserved. Its file
  format is stdio-only, so HTTP remotes are wrapped via `mcp-remote`.
- Gemini CLI is currently unmanaged for MCP sync.

Full framework: [`docs/mcp-config.md`](./docs/mcp-config.md).

## System update

Core steps: Homebrew index → formulae → npm globals → pip → Claude Code →
gh extensions → mise runtimes → cleanup. Plugins in
`scripts/system-update.d/*.sh`. Logs in `~/Library/Logs/system-update/`.

## Source of truth

| Surface | Owner | Notes |
|---------|-------|-------|
| `system-config/home/` | system-config | chezmoi source for shell, direnv, mise, starship, SSH policy, MCP wrappers, MCP secrets manifest |
| `scripts/` | system-config | Operational tooling |
| `iterm2/profiles/` | system-config | Dynamic profile definitions |
| Project `.mise.toml`, `.envrc`, `.mcp.json` | project repo | Version pins, env vars, project MCP servers |

## Definition of done

- `shellcheck` clean on all `.sh` files and `home/dot_local/bin/executable_mcp-*.tmpl`
- Chezmoi templates use `| default` for optional keys
- `chezmoi apply --dry-run` completes without template errors
- Global MCP sync writes only structure, not secret material

## Boundaries

### Always
- Use conventional commits: `type(scope): description`
- Sign commits using the approved Git signing configuration
- Run `shellcheck` on shell scripts before committing

### Ask first
- Deleting or renaming files outside `scripts/` and `docs/`
- Modifying chezmoi templates that affect `~/.config/`
- Changes to `scripts/system-update.sh` core step logic

### Never
- Commit secrets, tokens, API keys, or passphrases
- Modify `~/.config/chezmoi/chezmoi.toml` directly
- Run `chezmoi apply` without `--dry-run` first in unfamiliar contexts
- Create a global `~/.envrc`
- Reintroduce a fish-managed shell surface

## Known issues

- **Template error `map has no entry for key`** — template missing
  `| default` guard or machine data missing the expected key.
- **macOS plist cache** — run `killall cfprefsd` before modifying
  plist-backed preferences on disk.
- **Agentic zsh startup time** — profile with `zsh -xlic exit 2>&1`
  before adding more shell init.
