# AGENTS.md

Configuration documentation and templates for a reproducible macOS development environment using chezmoi, Homebrew, Fish shell, and mise. Phased approach with modularity and machine-specific customization.

## Architecture

### Directory Layout
```
SystemConfig/
├── 01-setup/              # Installation guides (prerequisites, Homebrew, chezmoi, iTerm2)
├── 02-configuration/      # Tool configuration docs (terminals, SSH, MCP, Codex)
├── 03-automation/         # Automation guides
├── 04-policies/           # Version and update policies
├── 05-reference/          # Reference documentation
├── 06-templates/chezmoi/  # Production chezmoi templates (Fish, mise, direnv, installers)
├── ai-tools/              # Centralized MCP server config + sync script
├── docs/                  # CLI setup guides, maintenance guides, policies
├── scripts/               # system-update.sh, doctor-path.sh, iterm2-setup.sh
│   └── system-update.d/   # Drop-in update plugins
├── AGENTS.md              # This file — canonical project contract
├── CLAUDE.md              # Claude Code shim (imports AGENTS.md)
└── REPO-STRUCTURE.md      # Detailed layout reference
```

### Chezmoi Configuration
- **Source**: `~/.local/share/chezmoi/` — template files and run_once scripts
- **Data**: `~/.config/chezmoi/chezmoi.toml` — machine-specific values (NOT `.chezmoidata.toml`)
- **Templates**: Go template syntax with guards like `(.headless | default false)`

### Critical File Locations
```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl          # Prompts for machine-specific data
├── run_once_*.sh.tmpl          # One-time setup scripts
├── dot_config/                 # Fish, mise configs
└── workspace/
    ├── dotfiles/               # Brewfiles and templates
    └── scripts/                # Helper scripts
```

## Common Commands

```bash
# Apply chezmoi changes
chezmoi apply
chezmoi apply --dry-run          # Preview first
chezmoi init --apply             # Regenerate config (clears template warnings)

# Diagnostics
chezmoi status
mise doctor

# Fix PATH issues
fish -c 'echo $PATH | tr " " "\n" | grep local'

# Complete GUI app install if timed out
cd ~/.local/share/chezmoi/workspace/dotfiles && brew bundle --file=Brewfile.gui

# Install mise-managed tools
mise install

# Bootstrap a new project
~/.local/share/chezmoi/workspace/scripts/init-project.sh [project-path]
```

## Template Syntax Rules

### Always use default guards
```go
// CORRECT
{{ if not (.headless | default false) -}}
{{ if eq (.shell | default "fish") "fish" -}}

// INCORRECT — fails if key doesn't exist
{{ if not .headless -}}
{{ if eq .shell "fish" -}}
```

### Required data keys in chezmoi.toml
- `headless` (bool): Whether this is a headless server
- `android` (bool): Whether to install Android development tools
- `shell` (string): Default shell choice (usually "fish")

## System Update

All packages, tools, and runtimes updated via one command:

```bash
system-update              # Quiet console, full transcript in log
system-update --check      # Dry-run: show what's outdated
system-update --strict     # Fail-fast on first error
system-update --verbose    # Step headers and inline summaries
system-update --debug      # Full diagnostic output
system-update --list       # Show available steps/plugins
system-update --only brew-index,brew-formulae
system-update --skip pip-packages
system-update --notify     # macOS notification on completion
system-update --json       # JSON summary at end
system-update --no-plugins # Skip system-update.d plugins
system-update --no-cleanup # Skip brew cleanup and mise prune
```

**Core steps** (8 total): Homebrew index, Homebrew formulae (`--formula` only), npm globals, pip packages (via `mise exec python`), Claude Code, gh extensions, mise runtimes, Cleanup.

**Plugins** (`scripts/system-update.d/*.sh`): Sourced after step 7, before cleanup. Default: `rustup`, `pipx`, `uv`. Optional: `brew-casks`, `mas`, `gem`, `go-tools`, `android-studio-canary`.

**Status model**: `ok` (rc=0), `warn` (rc!=0 but upgrades detected), `fail` (rc!=0, no useful work).

**Logging**: Console (stdout) is curated. FD 3 writes full transcript to `~/Library/Logs/system-update/run-*.log`. NDJSON events to `run-*.ndjson`. `latest.log`/`latest.ndjson` symlinked.

**Config file**: `~/.config/system-update/config` (or `SYSTEM_UPDATE_CONFIG`). Supports: `SYSTEM_UPDATE_ENABLE`, `SYSTEM_UPDATE_DISABLE`, `SYSTEM_UPDATE_ONLY`, `SYSTEM_UPDATE_SKIP`, `SYSTEM_UPDATE_STEP_ORDER`, `SYSTEM_UPDATE_PIP_PACKAGES`, `SYSTEM_UPDATE_GO_TOOLS`, `SYSTEM_UPDATE_NOTIFY`, `SYSTEM_UPDATE_JSON`, `SYSTEM_UPDATE_ENABLE_PLUGINS`.

**Known quirks**: `npm outdated -g` exits 1 when packages are outdated (tolerated). `claude update` exits nonzero when current (soft failure). `mise upgrade` may exit 1 on partial success (classified as `warn`). pip runs via `mise exec python` to avoid user-site ambiguity.

**Shell integration**: Available as `system-update` in Fish and Zsh. Old `update-tools` is deprecated.

## Secrets

- **Gopass guide**: `docs/guides/GOPASS-DEFINITIVE-GUIDE.md`
- **Quick reference**: `~/.config/gopass/README-AGENTS.md`
- **Passphrase**: `escapable diameter silk discover`

## MCP Server Management

Global MCP servers defined in `ai-tools/mcp-servers.json`, synced to all tools:

```bash
~/SystemConfig/ai-tools/sync-to-tools.sh           # Sync to all tools
~/SystemConfig/ai-tools/sync-to-tools.sh --dry-run  # Preview
```

**Scope**: This syncs to Claude Code CLI (`~/.claude.json`) and other terminal dev tools only. Claude Desktop / Cowork is configured via its UI (Extensions, Connectors, Plugins) and is not a sync target. See `docs/claude-desktop-setup.md`.

**Secrets pulled from gopass at sync time**: `github/dev-tools-token`, `brave/api-key`, `firecrawl/api-key`.

Project-specific MCP servers belong in each project's `.mcp.json`, not in global config.

## Definition of Done

- `shellcheck` clean on all `.sh` files
- Chezmoi templates use `| default` guards for all optional keys
- `chezmoi apply --dry-run` produces no errors
- Scripts are executable (`chmod +x`)

## Source of Truth

### SSOT Table

| Repo | Manages | Does NOT manage |
|------|---------|-----------------|
| **SystemConfig** (`~/SystemConfig/06-templates/chezmoi/`) | Shell integration (Fish conf.d, zshrc, bashrc), global mise settings, starship, direnv global, run_once installers | SSH, GPG, git configs, Brewfiles, iTerm2 DynamicProfiles, private data |
| **dotfiles** (`~/.local/share/chezmoi/`) | SSH/GPG/git configs, Brewfiles, iTerm2 DynamicProfiles, `.chezmoitemplates/`, everything NOT in SystemConfig | Duplicates of what SystemConfig owns |
| **Project-level** (`.mise.toml`, `.envrc`) | Tool version pins, project API keys, per-project env | Global shell behavior |

### Workflow

Always edit in SystemConfig → run `sync-chezmoi-templates.sh` → `chezmoi apply`.

```bash
# Sync SystemConfig templates into dotfiles source
~/SystemConfig/scripts/sync-chezmoi-templates.sh

# Check for divergence without making changes (suitable for pre-commit hook)
~/SystemConfig/scripts/sync-chezmoi-templates.sh --check

# Apply to live system
chezmoi apply --dry-run    # Preview first
chezmoi apply
```

### iTerm2 Policy

Chezmoi manages only `DynamicProfiles/*.json` and color preset files. **Never manage `com.googlecode.iterm2.plist`** — it is large, machine-specific, and conflicts with iTerm2's own preference sync. Configure keybindings, appearance, and profiles directly in iTerm2 or via `scripts/iterm2-setup.sh`.

### Project-Scope Guide

Push per-tool decisions to project scope — do not inflate global shell config:

| What | Where |
|------|-------|
| Tool version pins | `.mise.toml` in project root |
| Project API keys and env vars | `.envrc` via `gopass` |
| Project-specific MCP servers | `.mcp.json` in project root |
| Project Claude instructions | `CLAUDE.md` in project root |

Global shell config (`Fish conf.d/`, `.zshrc`) should only contain settings that apply to every interactive session on this machine.

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

## Known Issues

### PATH configuration
Ensure `~/.config/fish/conf.d/04-paths.fish` includes:
```fish
fish_add_path ~/.npm-global/bin
fish_add_path ~/bin
fish_add_path ~/.local/bin
```

### Template errors
"map has no entry for key" — add missing keys to `~/.config/chezmoi/chezmoi.toml`, update templates with `| default` guards, re-run `chezmoi apply`.

### Homebrew bundle timeouts
GUI apps can timeout. Continue with: `cd ~/.local/share/chezmoi/workspace/dotfiles && brew bundle --file=Brewfile.gui`

### Terminal key bindings
Fish keybindings in `~/.config/fish/conf.d/05-keybindings.fish`. iTerm2 requires: Left Option = "Esc+", clipboard access enabled, xterm-256color, paste bracketing on. Run `scripts/iterm2-setup.sh`.

## Phase Status

- **Phase 0**: Complete (Pre-flight / Prerequisites)
- **Phase 1**: Complete (Foundation / Homebrew)
- **Phase 2**: Complete (Dotfiles / chezmoi)
- **Phase 3**: Complete (Fish shell)
- **Phase 4**: Complete (mise version management)
- **Phase 5**: Complete (Security — gopass, age key)
- **Phase 6**: Complete (Containers — OrbStack, Docker)
- **Phase 7**: Skipped by choice (Android development)
- **Phase 8**: Complete (Bootstrap script)
- **Phase 9**: Complete (Project templates)
- **Phase 10**: Not started (System optimization)
