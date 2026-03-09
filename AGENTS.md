# AGENTS.md

Reproducible macOS development environment. Chezmoi-managed shell config, Homebrew packages, mise runtimes, iTerm2 dynamic profiles.

## Architecture

### Directory Layout
```
system-config/
├── home/                  # Chezmoi source (sourceDir)
│   ├── .chezmoidata.yaml  # Shared data for zsh + fish templates
│   ├── .chezmoiignore     # Ignore patterns
│   ├── dot_zshenv.tmpl    # XDG exports only
│   ├── dot_zprofile.tmpl  # PATH bootstrap (brew, mise, local/bin)
│   ├── dot_zshrc.tmpl     # Thin loader → zshrc.d/
│   ├── dot_bash_profile.tmpl
│   ├── dot_bashrc.tmpl
│   ├── dot_config/
│   │   ├── fish/          # config.fish.tmpl + 12 conf.d/ modules
│   │   ├── zshrc.d/       # 13 zsh modules (NG_MODE gated)
│   │   ├── direnv/        # direnvrc.tmpl + direnv.toml.tmpl
│   │   ├── mise/          # global config.toml.tmpl
│   │   └── starship.toml.tmpl
│   └── dot_local/bin/     # ng-doctor, system-update
├── iterm2/
│   ├── profiles/          # Dynamic profile JSONs (parent-child)
│   └── themes/            # Color-only presets (reference)
├── scripts/               # system-update.sh, install-iterm2-profiles.sh, sync-mcp.sh
│   └── system-update.d/   # Drop-in update plugins
├── policies/              # OPA policies, version policy
├── docs/                  # Setup guides, gopass, agent handoff
├── AGENTS.md              # This file — canonical project contract
├── CLAUDE.md              # Claude Code shim (imports AGENTS.md)
├── DEVMACHINE-SPEC.md     # Source of truth spec
└── IMPLEMENTATION-PLAN.md # Execution tracker
```

### Chezmoi Configuration
- **Source**: `system-config/home/` (set via `sourceDir` in chezmoi.toml)
- **Data**: `~/.config/chezmoi/chezmoi.toml` — machine-specific values
- **Shared data**: `home/.chezmoidata.yaml` — aliases, paths, coreutil mappings
- **Templates**: Go template syntax with guards like `(.headless | default false)`
- **Old dotfiles**: `~/.local/share/chezmoi/` — archived, retains SSH/GPG/git/Brewfiles

## Common Commands

```bash
# Apply chezmoi changes
chezmoi apply --dry-run    # Preview first
chezmoi apply

# Machine health
ng-doctor                  # 37-check verification harness

# System update
system-update              # All packages, tools, runtimes
system-update --check      # Dry-run

# iTerm2 profiles
scripts/install-iterm2-profiles.sh

# MCP server sync
scripts/sync-mcp.sh        # Sync to Claude Code CLI, Cursor, etc.
scripts/sync-mcp.sh --dry-run
```

## Template Syntax Rules

### Always use default guards
```go
// CORRECT
{{ if not (.headless | default false) -}}
{{ if eq (.shell | default "fish") "fish" -}}

// INCORRECT — fails if key doesn't exist
{{ if not .headless -}}
```

### Required data keys in chezmoi.toml
- `headless` (bool): Whether this is a headless server
- `shell` (string): Default shell choice (usually "fish")

## System Update

```bash
system-update              # Quiet console, full transcript in log
system-update --verbose    # Step headers and inline summaries
system-update --list       # Show available steps/plugins
system-update --only brew-index,brew-formulae
system-update --skip pip-packages
```

**Core steps** (8): Homebrew index, Homebrew formulae, npm globals, pip packages, Claude Code, gh extensions, mise runtimes, Cleanup.

**Plugins** (`scripts/system-update.d/*.sh`): Default: `rustup`, `pipx`, `uv`. Optional: `brew-casks`, `mas`, `gem`, `go-tools`, `gam`, `android-studio-canary`.

**Logging**: `~/Library/Logs/system-update/run-*.log` + NDJSON.

## Secrets

- **Gopass guide**: `docs/gopass-guide.md`
- **Quick reference**: `~/.config/gopass/README-AGENTS.md`
- **Passphrase**: `escapable diameter silk discover`

## MCP Server Management

Global MCP servers in `scripts/mcp-servers.json`, synced to tools via `scripts/sync-mcp.sh`.

**Scope**: Syncs to Claude Code CLI (`~/.claude.json`) and other terminal dev tools. Claude Desktop configured via its own UI.

**Secrets pulled from gopass at sync time**: `github/dev-tools-token`, `brave/api-key`, `firecrawl/api-key`.

Project-specific MCP servers belong in each project's `.mcp.json`.

## Source of Truth

### SSOT Table

| Repo | Manages | Does NOT manage |
|------|---------|-----------------|
| **system-config** (`home/`) | Shell config (zsh, fish, bash), zshrc.d/ modules, fish conf.d/, direnv, mise global, starship, ng-doctor, iTerm2 dynamic profiles | SSH, GPG, git configs, Brewfiles, private data |
| **dotfiles** (`~/.local/share/chezmoi/`) | SSH/GPG/git configs, Brewfiles, `.chezmoitemplates/` | Shell config (owned by system-config) |
| **Project-level** (`.mise.toml`, `.envrc`) | Tool version pins, project API keys, per-project env | Global shell behavior |

### Workflow

Edit in `system-config/home/` → `chezmoi apply`.

```bash
chezmoi apply --dry-run    # Preview
chezmoi apply              # Deploy
```

### iTerm2 Policy

iTerm2 is an adapter layer, not a system boundary. Shell/runtime policy lives in chezmoi-managed shell config. iTerm2 artifacts are limited to profile presentation and session entrypoints.

- Profiles managed via `iterm2/profiles/` → symlinked to DynamicProfiles/
- `LoadPrefsFromCustomFolder`: disabled. Standard macOS preferences.
- Never manage `com.googlecode.iterm2.plist` — machine-specific.
- OrbStack.json in DynamicProfiles is app-managed (do not modify).

### Project-Scope Guide

Push per-tool decisions to project scope — do not inflate global shell config:

| What | Where |
|------|-------|
| Tool version pins | `.mise.toml` in project root |
| Project API keys and env vars | `.envrc` via `gopass` |
| Project-specific MCP servers | `.mcp.json` in project root |
| Project Claude instructions | `CLAUDE.md` in project root |

## Definition of Done

- `shellcheck` clean on all `.sh` files
- Chezmoi templates use `| default` guards for all optional keys
- `chezmoi apply --dry-run` produces no errors
- Scripts are executable (`chmod +x`)

## Boundaries

### Always
- Use conventional commits: `type(scope): description`
- GPG-sign commits
- Run `shellcheck` on shell scripts before committing
- Use `fish_indent` for Fish scripts

### Ask first
- Deleting or renaming files outside `scripts/` and `docs/`
- Modifying chezmoi templates that affect `~/.config/`
- Changes to `system-update.sh` core step logic

### Never
- Commit secrets, tokens, or API keys
- Modify `~/.config/chezmoi/chezmoi.toml` directly (use `chezmoi init`)
- Run `chezmoi apply` without `--dry-run` first in unfamiliar contexts
- Create a global `~/.envrc` (direnv is project-scope only)

## Known Issues

### Template errors
"map has no entry for key" — add missing keys to `~/.config/chezmoi/chezmoi.toml`, update templates with `| default` guards, re-run `chezmoi apply`.

### macOS plist cache
Must `killall cfprefsd` before modifying plists on disk, or changes get overwritten.

### Agentic startup time
Currently ~537ms (target: 200ms). Shell-init cost, not iTerm2. Profile with `zsh -xlic exit 2>&1`.
