---
title: Chezmoi Templates Documentation
category: template
component: chezmoi
status: active
version: 1.0.0
last_updated: 2025-09-26
tags: [dotfiles, configuration-management]
priority: medium
---

# chezmoi Dotfiles Structure
## Implementation Snapshot — September 2025

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl            # Interactive prompts for machine data
├── dot_config/
│   ├── fish/
│   │   ├── config.fish           # Minimal base config (sets trust + env)
│   │   └── conf.d/
│   │       ├── 00-homebrew.fish  # Homebrew shellenv bootstrap
│   │       ├── 01-mise.fish      # mise activation
│   │       ├── 02-direnv.fish    # direnv hook
│   │       ├── 03-starship.fish  # prompt setup
│   │       └── 04-paths.fish     # user/bin path additions (new)
│   └── mise/
│       └── config.toml           # Global toolchain + env defaults
├── run_once_01-install-packages.sh.tmpl  # Brew bundles (core/dev/gui/android)
├── run_once_02-configure-shell.sh.tmpl   # Default shell selection
├── run_once_03-install-tools.sh.tmpl     # mise install/trust sequence
└── workspace/
    ├── dotfiles/
    │   ├── Brewfile               # Orchestrates modular Brewfiles
    │   ├── Brewfile.core          # Core CLI set
    │   ├── Brewfile.dev           # Developer tooling
    │   ├── Brewfile.gui           # GUI apps (workstation only)
    │   ├── Brewfile.android       # Android SDK toolchain
    │   └── templates/
    │       ├── envrc              # Project direnv helper
    │       └── mise.toml          # Project mise template with tasks
    └── scripts/
        └── init-project.sh        # Bootstrap helper for new repos
```

> Data values collected by `.chezmoi.toml.tmpl` are stored in `~/.config/chezmoi/chezmoi.toml` after the first `chezmoi init --apply`. That file currently holds email/name/GitHub identities but is missing the newer `headless`, `android`, and `shell` keys.

---

## Core Metadata (`.chezmoi.toml.tmpl`)

```toml
{{- $email := promptStringOnce . "email" "Your email address" -}}
{{- $name := promptStringOnce . "name" "Your full name" -}}
{{- $github_user := promptStringOnce . "github_user" "Your personal GitHub username" -}}
{{- $github_user_work := promptStringOnce . "github_user_work" "Your work GitHub username" -}}
{{- $github_user_business := promptStringOnce . "github_user_business" "Your business GitHub username" -}}
{{- $hostname := .chezmoi.hostname -}}
{{- $headless := promptBoolOnce . "headless" "Is this a headless server (no GUI)?" -}}
{{- $android := promptBoolOnce . "android" "Install Android development tools?" -}}
{{- $shell := promptStringOnce . "shell" "Default shell (fish/zsh/bash)" -}}

[data]
  email = {{ $email | quote }}
  name = {{ $name | quote }}
  github_user = {{ $github_user | quote }}
  github_user_work = {{ $github_user_work | quote }}
  github_user_business = {{ $github_user_business | quote }}
  github_user_business_org = "happy-patterns-org"
  github_user_hubofwyn = "hubofwyn"
  hostname = {{ $hostname | quote }}
  headless = {{ $headless }}
  android = {{ $android }}
  shell = {{ $shell | quote }}
```

These values feed the `run_once` scripts and templates via `.headless`, `.android`, and `.shell`. Older installs that pre-date these prompts will need those keys added manually (see `~/.config/chezmoi/chezmoi.toml`).

---

## Shell Configuration (`dot_config/fish`)

### `config.fish`
```fish
# Fish shell configuration
# As per consolidated-revisions.md:141 - minimal config with MISE trust

set -gx MISE_TRUSTED_CONFIG_PATHS "~/Development/**" "~/workspace/**"
set -gx MISE_EXPERIMENTAL 1
```

The heavy lifting lives in `conf.d`:

- **00-homebrew.fish** — ensure `brew shellenv` runs with Fish-correct syntax so `/opt/homebrew/bin` and friends land on `PATH`.
- **01-mise.fish** — activates mise shims so `node`, `bun`, `python`, etc., resolve per-project.
- **02-direnv.fish** — loads direnv hook once.
- **03-starship.fish** — optional starship prompt initialization.
- **04-paths.fish** — adds user-level bins (`~/.npm-global/bin`, `~/bin`, `~/.local/bin`, `~/.bun/bin`, `~/.local/share/go/workspace/bin`) so CLIs like the Claude Code npm package are in scope even before direnv loads.

```fish
# ~/.local/share/chezmoi/dot_config/fish/conf.d/04-paths.fish
fish_add_path ~/.npm-global/bin
fish_add_path ~/bin
fish_add_path ~/.local/bin
fish_add_path ~/.bun/bin
fish_add_path ~/.local/share/go/workspace/bin
```

---

## Run-Once Scripts

1. **run_once_01-install-packages.sh.tmpl** — installs Homebrew (if missing) and executes the modular Brewfiles. The script seeds `$headless`/`$android` with `hasKey` lookups so legacy configs default to `false`; GUI bundles run only when `$headless` is false, Android bundles when `$android` is true.
2. **run_once_02-configure-shell.sh.tmpl** — appends Fish to `/etc/shells` and compares `lower $shell` to `fish` before calling `chsh`, which keeps older configs from erroring.
3. **run_once_03-install-tools.sh.tmpl** — trusts the global mise config and runs `mise install`, including a fallback to install `uv` if not already available.

Each script expects the corresponding data keys; without them, templating fails, which is why legacy configs need manual updates.

---

## Workspace Assets

- `workspace/dotfiles/Brewfile*` — the modular bundle structure called by `run_once_01`. `Brewfile.gui` only applies on non-headless hosts; `Brewfile.android` is opt-in.
- `workspace/dotfiles/templates/envrc` — direnv helper with secret-loading utilities, language-specific setup, and Android path injection.
- `workspace/dotfiles/templates/mise.toml` — project template with common tasks (`test`, `lint`, `format`, `dev`, `build`, `clean`).
- `workspace/scripts/init-project.sh` — convenience script that copies the templates into a new repo, initializes git, trusts mise, and installs toolchains.

---

## State File Location

The active machine state lives in `~/.config/chezmoi/chezmoi.toml`. Today it contains:

```toml
[data]
  email = "verlyn13@gmail.com"
  name = "Verlyn"
  github_user = "verlyn13"
  github_user_work = "jjohnson-47"
  github_user_business = "happy-patterns"
  github_user_business_org = "happy-patterns-org"
  github_user_hubofwyn = "hubofwyn"
  hostname = "verlyns-mbp"
```

Before re-running `chezmoi apply`, add the newer keys:

```toml
  headless = false
  android = false
  shell = "fish"
```

That keeps the existing scripts (“Phase 0–3”) happy while you iterate on later phases.
