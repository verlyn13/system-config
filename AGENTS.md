# AGENTS.md

Reproducible macOS development environment. `system-config` is the active chezmoi source for the zsh-first shell surface, global mise defaults, direnv helpers, iTerm2 dynamic profiles, and the user-level MCP baseline.

## Secrets Status

- `system-config` baseline secret migration to 1Password CLI (`op`) was completed and verified on 2026-04-15.
- Repo-owned secret lookups are pinned to `my.1password.com` and the `Dev` vault.
- Live source of truth for everyday secret handling on this system: `docs/secrets.md`
- Rollout and gopass retirement tracker: `docs/1password-migration-plan.md`
- gopass is retained only as a cold archive for external or project secrets that have not yet been migrated.

## Architecture

### Directory Layout
```text
system-config/
├── home/                  # Active chezmoi source (sourceDir)
│   ├── .chezmoidata.yaml  # Shared data for shell templates
│   ├── .chezmoiignore
│   ├── dot_zshenv.tmpl    # XDG exports only
│   ├── dot_zprofile.tmpl  # PATH bootstrap
│   ├── dot_zshrc.tmpl     # Thin loader -> zshrc.d/
│   ├── dot_bash_profile.tmpl
│   ├── dot_bashrc.tmpl
│   ├── dot_config/
│   │   ├── zshrc.d/       # Modular zsh config (NG_MODE gated)
│   │   ├── direnv/        # direnvrc.tmpl + direnv.toml.tmpl
│   │   ├── mise/          # global config.toml.tmpl
│   │   └── starship.toml.tmpl
│   ├── dot_ssh/           # Managed nonsecret SSH client policy
│   └── dot_local/bin/     # ng-doctor, system-update, MCP wrappers
├── iterm2/
│   ├── profiles/          # Dynamic profile JSONs
│   └── themes/            # Color-only presets
├── scripts/               # sync-mcp.sh, system-update.sh, install-iterm2-profiles.sh
│   └── system-update.d/   # Drop-in update plugins
├── docs/                  # Current guides + archived historical notes
├── AGENTS.md              # Canonical project contract
├── CLAUDE.md              # Claude Code shim (imports AGENTS.md)
├── DEVMACHINE-SPEC.md     # Historical archive, not the live contract
└── IMPLEMENTATION-PLAN.md # Historical archive, not the live contract
```

### Shell Policy
- zsh is the only managed interactive shell.
- bash is a script/runtime shell only.
- fish is not part of the managed config surface. Do not add fish templates, fish aliases, or fish-only agent workflows back into this repo.

### Chezmoi Configuration
- Source: `system-config/home/`
- Machine data: `~/.config/chezmoi/chezmoi.toml`
- Shared data: `home/.chezmoidata.yaml`
- Old dotfiles repo: `~/.local/share/chezmoi/` is legacy archival state for remaining unmanaged SSH/GPG/git/Brewfiles data. It is not the active shell, MCP, or SSH policy control plane.

## Common Commands

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

## Template Rules

Always use `| default` for optional keys.

```go
// CORRECT
{{ if not (.headless | default false) -}}
{{ if (.android | default false) -}}

// INCORRECT
{{ if not .headless -}}
{{ if .android -}}
```

Required machine data keys:
- `headless` (bool)
- `android` (bool)

## MCP Ownership

Global MCP servers live in `scripts/mcp-servers.json` and are synced by `scripts/sync-mcp.sh`.

Approved global baseline:
- `context7`
- `github`
- `memory`
- `sequential-thinking`
- `brave-search`
- `firecrawl`

User-level sync targets:
- Claude Code CLI: `~/.claude.json`
- Cursor: `~/.cursor/mcp.json`
- Windsurf: `~/.codeium/windsurf/mcp_config.json`
- GitHub Copilot CLI: `~/.copilot/mcp-config.json`
- Codex CLI: `~/.codex/config.toml`

Policy:
- Project-specific MCP servers belong in each project’s `.mcp.json`.
- `scripts/sync-mcp.sh` manages only the global baseline.
- User configs must not contain expanded API keys or tokens.
- Auth-required global servers use runtime wrapper commands in `home/dot_local/bin/` and load secrets from env vars or 1Password CLI (`op read`) at launch time. Do not add new gopass dependencies. Use `docs/secrets.md` for the live secret-loading contract and `docs/agentic-tooling.md` for MCP ownership and wrapper behavior.
- Claude Desktop is a separate config plane and is not a sync target.
- Gemini CLI is currently unmanaged for MCP sync; keep it tool-native and project-local where possible.

## System Update

Core steps:
- Homebrew index
- Homebrew formulae
- npm globals
- pip packages
- Claude Code
- gh extensions
- mise runtimes
- Cleanup

Plugins live in `scripts/system-update.d/*.sh`.

Logging:
- Preferred: `~/Library/Logs/system-update/`
- Fallback: `${TMPDIR:-/tmp}/system-update-$USER/`
- Example user config: `scripts/system-update.config.example`

## Source Of Truth

| Surface | Owner | Notes |
|---------|-------|-------|
| `system-config/home/` | system-config | Active chezmoi source for shell, direnv, mise global, starship, nonsecret SSH client policy, MCP wrappers |
| `scripts/` | system-config | Operational tooling: system update, MCP sync, iTerm2 profile install |
| `iterm2/profiles/` | system-config | Dynamic profile definitions only |
| `~/.local/share/chezmoi/` | legacy dotfiles repo | Legacy archive for remaining unmanaged SSH/GPG/git/Brewfiles data, not shell/MCP/SSH SSOT |
| `.mise.toml`, `.envrc`, `.mcp.json` in a project | project repo | Version pins, env vars, project MCP servers |

Workflow:

```bash
chezmoi apply --dry-run
chezmoi apply
```

## Secrets

- Live secrets policy: `docs/secrets.md`
- Live SSH policy: `docs/ssh.md`
- Rollout and retirement tracker: `docs/1password-migration-plan.md`
- Preferred retrieval pattern: `op read "op://Dev/<item>/<field>"`
- Canonical readiness check: `op vault get Dev --account my.1password.com >/dev/null`
- Gopass remains archive-only during remaining project rollout work; do not introduce new gopass usage in this repo
- Never commit passphrases, tokens, or API keys.
- Never design sync tooling that materializes secrets into persistent user config files.

## Definition Of Done

- `shellcheck` clean on all `.sh` files
- Chezmoi templates use `| default` for optional keys
- `chezmoi apply --dry-run` completes without template errors
- Scripts are executable
- Global MCP sync writes only structure, not secret material

## Boundaries

### Always
- Use conventional commits: `type(scope): description`
- Sign commits using the approved Git signing configuration
- Run `shellcheck` on shell scripts before committing

### Ask first
- Deleting or renaming files outside `scripts/` and `docs/`
- Modifying chezmoi templates that affect `~/.config/`
- Changes to `system-update.sh` core step logic

### Never
- Commit secrets, tokens, API keys, or passphrases
- Modify `~/.config/chezmoi/chezmoi.toml` directly
- Run `chezmoi apply` without `--dry-run` first in unfamiliar contexts
- Create a global `~/.envrc`
- Reintroduce a fish-managed shell surface

## Known Issues

### Template errors
`map has no entry for key` means a template is missing a `| default` guard or the local chezmoi data needs the expected key.

### macOS plist cache
Run `killall cfprefsd` before modifying cached plist-backed preferences on disk.

### Agentic startup time
zsh startup is still above target. Profile with `zsh -xlic exit 2>&1` before adding more shell init.
