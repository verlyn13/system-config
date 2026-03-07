# Nash Group Development Machine Configuration Spec

```yaml
meta:
  spec_version: "1.0.0"
  target_agent: "claude-opus-4-6 via claude-code-cli"
  platform: "macOS Tahoe 26.3 / Darwin 25.3.0 / Apple Silicon (M3 Max)"
  filesystem: "APFS (case-insensitive default)"
  repo: "system-config"
  owner: "Jeffrey / The Nash Group"
  governance: "the-covenant principles apply"
  governance_level: "Stronghold (1 Mentor)"
  subsidiary: "parent-org (the-nash-group, no prefix)"
  last_updated: "2026-03-03"
```

## 0. Agent Contract

This spec is the single source of truth for implementing the Nash Group dev machine
configuration. It is designed to be consumed by an agentic coding tool (Claude Code CLI)
operating inside the `system-config` repository.

### Execution Rules

1. **Investigation before implementation.** Before writing any file, grep/find/read
   the current state. Show evidence of what exists before proposing changes.
2. **Atomic phases.** Complete each phase fully (including verification) before
   starting the next. Do not interleave phases.
3. **Idempotency required.** Every script, config file, and shell init must be safe
   to run/source multiple times without side effects.
4. **No `--no-verify`.** All git commits pass hooks.
5. **chezmoi is the delivery mechanism.** Config files are authored as chezmoi
   templates in the repo. They are applied to the live system via `chezmoi apply`.
   Never write directly to `~/.config/` or `~/.local/` — write to the chezmoi
   source directory.
6. **Test the doctor first.** Phase 0 builds the verification harness. All
   subsequent phases are validated by the doctor.

### Naming Conventions (enforced)

```yaml
directories: kebab-case
files_general: kebab-case.ext
special_docs: UPPERCASE.md  # README.md, CLAUDE.md, CHANGELOG.md, AGENTS.md
python_files: snake_case.py
go_files: snake_case.go
chezmoi_templates: chezmoi naming (dot_config/, run_once_*, .tmpl suffix)
macos_system: as-is  # ~/Library, /opt/homebrew — never rename
```

---

## 1. Architecture Decisions (Non-Negotiable)

These are resolved. Do not revisit or propose alternatives.

### AD-01: System Login Shell

```yaml
decision: "zsh is the macOS login shell"
rationale: |
  Agentic tools (Claude Code CLI, Cursor, Windsurf/Cascade, Codex CLI,
  Copilot CLI, Gemini CLI) probe $SHELL and spawn subshells assuming
  POSIX-ish semantics. Fish breaks this contract structurally.
implementation: "chsh -s /bin/zsh"
verification: "dscl . -read /Users/$USER UserShell | grep /bin/zsh"
```

### AD-02: Fish Is Human-Only

```yaml
decision: "Fish is an iTerm2 profile choice, not a system identity"
rationale: |
  Fish's non-POSIX syntax causes silent failures in agent subshells.
  Keeping it as an iTerm2 profile preserves the human UX without
  polluting the agentic contract.
implementation: "iTerm2 profile with command /opt/homebrew/bin/fish -l"
constraint: "$SHELL must never be set to fish system-wide"
```

### AD-03: Bash Is a Runtime

```yaml
decision: "Modern bash (Homebrew) for scripts; never the login shell"
rationale: |
  macOS ships ancient bash 3.2 (GPLv2). Scripts need bash 5.x features.
  Install via Homebrew, reference via #!/usr/bin/env bash, never #!/bin/bash.
implementation: "brew install bash"
constraint: "Never set login shell to Homebrew bash"
```

### AD-04: mise Is the Single Version Manager

```yaml
decision: "mise is the sole version/tool manager at user and project level"
rationale: |
  Eliminates nvm/fnm/pyenv/rbenv. Projects override via local mise.toml.
  Global mise config provides conservative defaults for CLI tools only.
constraints:
  - "Remove .nvmrc and .node-version from system-config repo"
  - "Global mise config pins only: node (LTS), python (stable)"
  - "Projects own their own mise.toml — global never constrains"
```

### AD-05: Three-Zone Filesystem

```yaml
decision: "Zones 0/1/2 as defined in the Nash Group filesystem spec"
zone_0: "Sealed volume — never modify, SIP enforced"
zone_1: "Platform layer — Homebrew, ~/Library, /Applications — respect conventions"
zone_2: "Workspace — ~/.config, ~/.local, ~/Organizations, ~/Development — Nash Group governed"
```

### AD-06: XDG Base Directory Compliance

```yaml
decision: "All CLI tool config follows XDG layout"
exports:
  XDG_CONFIG_HOME: "$HOME/.config"
  XDG_DATA_HOME: "$HOME/.local/share"
  XDG_STATE_HOME: "$HOME/.local/state"
  XDG_CACHE_HOME: "$HOME/.cache"
constraint: "These exports must appear in both zsh and fish init"
```

---

## 2. Target Repo Structure

The `system-config` repo is restructured to eliminate numbered-directory overlap,
remove dead stubs, and make chezmoi the obvious core.

### Target Layout

```
system-config/
├── AGENTS.md                    # Agent contract (canonical)
├── CLAUDE.md                    # Claude Code shim → imports AGENTS.md
├── README.md                    # Human readme
├── CHANGELOG.md                 # Change log
├── DEVMACHINE-SPEC.md           # THIS FILE — implementation spec
│
├── home/                        # chezmoi source directory
│   ├── .chezmoi.toml.tmpl       # chezmoi config template
│   ├── .chezmoidata.yaml        # SHARED DATA: paths, tool lists, XDG values
│   │                            #   rendered into both zsh and fish templates
│   ├── dot_zshenv.tmpl          # → ~/.zshenv
│   ├── dot_zprofile.tmpl        # → ~/.zprofile
│   ├── dot_zshrc.tmpl           # → ~/.zshrc (loads zshrc.d/ modules)
│   ├── dot_bash_profile.tmpl    # → ~/.bash_profile
│   ├── dot_bashrc.tmpl          # → ~/.bashrc
│   │
│   ├── dot_config/
│   │   ├── fish/
│   │   │   ├── config.fish.tmpl
│   │   │   └── conf.d/
│   │   │       ├── 00-xdg.fish.tmpl
│   │   │       ├── 01-path.fish.tmpl
│   │   │       ├── 02-mise.fish.tmpl
│   │   │       ├── 03-direnv.fish.tmpl
│   │   │       ├── 10-aliases.fish.tmpl
│   │   │       ├── 15-coreutil-aliases.fish.tmpl  # human-only, not sourced in agentic
│   │   │       ├── 20-prompt.fish.tmpl
│   │   │       └── 99-local.fish.tmpl
│   │   │
│   │   ├── zshrc.d/              # modular zsh config
│   │   │   ├── 00-xdg.zsh.tmpl
│   │   │   ├── 01-path.zsh.tmpl
│   │   │   ├── 02-mise.zsh.tmpl
│   │   │   ├── 03-direnv.zsh.tmpl
│   │   │   ├── 10-aliases.zsh.tmpl
│   │   │   ├── 15-coreutil-aliases.zsh.tmpl  # GATED: skipped when NG_MODE=agentic
│   │   │   ├── 20-interactive.zsh.tmpl   # GATED: skipped when NG_MODE=agentic
│   │   │   ├── 21-completion.zsh.tmpl    # GATED: skipped when NG_MODE=agentic
│   │   │   ├── 22-prompt.zsh.tmpl        # GATED: skipped when NG_MODE=agentic
│   │   │   ├── 30-agentic.zsh.tmpl       # ONLY when NG_MODE=agentic
│   │   │   └── 99-local.zsh.tmpl
│   │   │
│   │   ├── mise/
│   │   │   └── config.toml.tmpl  # global mise config
│   │   ├── git/
│   │   │   ├── config.tmpl       # global gitconfig
│   │   │   └── ignore.tmpl       # global gitignore
│   │   ├── starship.toml.tmpl
│   │   └── direnv/
│   │       └── direnvrc.tmpl
│   │
│   ├── dot_local/
│   │   └── bin/                  # user scripts on PATH
│   │       └── ng-doctor.tmpl    # → ~/.local/bin/ng-doctor
│   │
│   └── run_once_before/
│       ├── 01-homebrew.sh.tmpl
│       ├── 02-brew-packages.sh.tmpl
│       └── 03-mise-global.sh.tmpl
│
├── iterm2/
│   ├── profiles/
│   │   ├── dev-zsh.json          # Profile 1: Dev (zsh)
│   │   ├── agentic-zsh.json      # Profile 2: Agentic (zsh minimal)
│   │   └── human-fish.json       # Profile 3: Human (fish)
│   ├── themes/
│   │   ├── tokyonight-moon.json
│   │   ├── tokyonight-storm.json
│   │   └── wild-cherry.json
│   └── README.md                 # iTerm2 setup: dynamic profiles path
│
├── scripts/
│   ├── system-update.sh          # main update orchestrator
│   ├── system-update.d/          # drop-in update plugins
│   └── install-iterm2-profiles.sh
│
├── policies/
│   └── opa/
│       └── version-policy.rego
│
├── docs/
│   ├── setup.md                  # single setup walkthrough
│   ├── shells.md                 # shell architecture explained
│   ├── terminals.md              # iTerm2 profile system
│   ├── tools.md                  # Homebrew, mise, direnv, etc.
│   ├── secrets.md                # gopass, keychain, infisical
│   ├── maintenance.md            # system-update, doctor, OS upgrades
│   └── agent-handoff.md          # how agents should use this config
│
├── .claude/                      # Claude Code settings
├── .github/
│   └── workflows/
├── .gitignore
└── .mise.toml                    # repo-local mise (for scripts in this repo only)
```

### Migration Map (current → target)

```yaml
moves:
  "06-templates/chezmoi/*": "home/"
  "Default.json": "iterm2/profiles/dev-zsh.json"
  "tokyonight*.json": "iterm2/themes/"
  "wild-cherry-profile.json": "iterm2/themes/"
  "iTerm2State.itermexport": "iterm2/"
  "scripts/": "scripts/"
  "04-policies/opa/": "policies/opa/"

deletes:
  - "01-setup/"           # content merged into docs/setup.md
  - "02-configuration/"   # content split into docs/shells.md, docs/terminals.md, docs/tools.md
  - "03-automation/"      # scripts moved to scripts/, launchd plist to home/ if chezmoi-managed
  - "05-reference/"       # content merged into docs/
  - "06-templates/"       # moved to home/
  - ".nvmrc"              # mise is source of truth
  - ".node-version"       # mise is source of truth
  - "package-lock.json"   # orphaned — no package.json
  - ".gemini/tmp/"        # temp file, should never have been committed
  - "iterm2-profile.json" # replaced by structured profiles in iterm2/profiles/

populate_or_delete:
  - "02-configuration/editors/"    # was empty stub — delete
  - "02-configuration/shells/"     # was empty stub — delete
  - "03-automation/hooks/"         # was empty stub — delete
  - "03-automation/workflows/"     # was empty stub — delete
```

---

## 3. Shell File Specifications

### 3.1 ~/.zshenv (dot_zshenv.tmpl)

**Purpose:** Universal exports. Sourced by ALL zsh invocations (interactive,
non-interactive, login, script). Must be tiny and fast.

```yaml
must_contain:
  - XDG_CONFIG_HOME export
  - XDG_DATA_HOME export
  - XDG_STATE_HOME export
  - XDG_CACHE_HOME export
must_not_contain:
  - PATH modifications
  - brew shellenv
  - any command that produces stdout
  - any conditional logic beyond OS detection
  - any calls to external binaries
max_lines: 15
idempotent: true
```

**Template content:**

```zsh
# ~/.zshenv — Universal exports. Sourced by ALL zsh invocations.
# RULE: No PATH. No brew. No stdout. No external binaries.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Point tools at XDG locations
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
```

### 3.2 ~/.zprofile (dot_zprofile.tmpl)

**Purpose:** Login shell init. Runs once per login session. Homebrew env goes here.

```yaml
must_contain:
  - Homebrew shellenv (idempotent)
  - PATH: ~/.local/bin
  - PATH: mise shims
must_not_contain:
  - interactive features (prompt, completion, keybinds)
  - anything that assumes a TTY
idempotent: true
```

**Template content:**

```zsh
# ~/.zprofile — Login shell init. Runs once per session.
# RULE: PATH setup only. No interactive features.

# Homebrew (Apple Silicon)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# User binaries
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# mise shims (global tool versions)
[[ -d "$XDG_DATA_HOME/mise/shims" ]] && export PATH="$XDG_DATA_HOME/mise/shims:$PATH"
```

### 3.3 ~/.zshrc (dot_zshrc.tmpl)

**Purpose:** Interactive shell config. Loads modular fragments from `zshrc.d/`.

```yaml
must_contain:
  - deterministic sourcing of ~/.config/zshrc.d/*.zsh (sorted)
must_not_contain:
  - inline configuration (everything delegates to zshrc.d/)
  - hardcoded paths that bypass the module system
max_lines: 20
```

**Template content:**

```zsh
# ~/.zshrc — Interactive zsh. Delegates to modular fragments.
# RULE: No inline config. Everything lives in zshrc.d/.

# Ensure XDG is set (defensive — zshenv should have done this)
: "${XDG_CONFIG_HOME:=$HOME/.config}"

# Source modules in deterministic order
if [[ -d "$XDG_CONFIG_HOME/zshrc.d" ]]; then
  for _rc in "$XDG_CONFIG_HOME/zshrc.d"/*.zsh(N); do
    source "$_rc"
  done
  unset _rc
fi
```

### 3.4 zshrc.d/ Module Specifications

Each module has an explicit contract. The `NG_MODE` environment variable gates
interactive-only modules.

```yaml
module_schema:
  filename_pattern: "NN-name.zsh"  # NN = 2-digit sort order
  header_required: |
    # NN-name.zsh — One-line purpose
    # GATE: always | interactive-only | agentic-only
  idempotent: true
  no_stdout: true  # modules must not produce output on source
```

#### 00-xdg.zsh

```yaml
gate: always
purpose: "Ensure XDG vars are set (backup for zshenv)"
content: "Re-export XDG vars with defaults"
```

#### 01-path.zsh

```yaml
gate: always
purpose: "PATH construction — idempotent, deterministic"
path_order:
  - "$HOME/.local/bin"
  - "$XDG_DATA_HOME/mise/shims"
  - "/opt/homebrew/bin"   # already set by zprofile, but defensive
  - system defaults
implementation_note: |
  Use a helper function that checks before prepending:
    path_prepend() { [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }
```

#### 02-mise.zsh

```yaml
gate: always
purpose: "Activate mise (not just shims — full hook for direnv integration)"
content: 'eval "$(mise activate zsh)"'
```

#### 03-direnv.zsh

```yaml
gate: always
purpose: "Hook direnv into zsh"
content: 'eval "$(direnv hook zsh)"'
```

#### 10-aliases.zsh

```yaml
gate: always
purpose: "Shell aliases that do NOT shadow POSIX commands"
examples:
  - "alias ll='ls -lah'"
  - "alias g='git'"
  - "alias dc='docker compose'"
source: "chezmoidata.aliases (safe aliases only)"
note: |
  This module MUST NOT contain aliases that replace coreutil commands.
  Agents expect grep, find, cat to behave per POSIX specification.
  Shadowing coreutils here would violate Principle 8 (Fail Fast) —
  an agent issuing `grep -P` would silently get `rg -P` which has
  different semantics, causing wrong decisions without obvious failure.
```

#### 15-coreutil-aliases.zsh — GATED

```yaml
gate: interactive-only  # skipped when NG_MODE=agentic
purpose: "Modern replacements for coreutils — human shell only"
guard: '[[ "$NG_MODE" == "agentic" ]] && return 0'
source: "chezmoidata.coreutil_aliases"
content:
  - "alias cat='bat --paging=never'"
  - "alias find='fd'"
  - "alias grep='rg'"
rationale: |
  These aliases change command SEMANTICS, not just cosmetics:
  - grep → rg: different flag names, different output format for multi-file
  - find → fd: entirely different flag syntax, no -exec
  - cat → bat: adds formatting, different exit behavior on binary files
  Gating these as interactive-only is consistent with the NG_MODE design:
  prompt and completion are gated because agents need predictable stdout.
  Coreutil aliases must also be gated because agents need predictable
  command behavior. Cosmetic gating without semantic gating is backwards.
```

#### 20-interactive.zsh — GATED

```yaml
gate: interactive-only  # skipped when NG_MODE=agentic
purpose: "Human-friendly shell enhancements"
guard: '[[ "$NG_MODE" == "agentic" ]] && return 0'
loads:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - key bindings
  - terminal title hooks
```

#### 21-completion.zsh — GATED

```yaml
gate: interactive-only
purpose: "Completion system — heavy, not needed by agents"
guard: '[[ "$NG_MODE" == "agentic" ]] && return 0'
loads:
  - compinit (cached via zcompdump)
  - fzf-tab (if installed)
  - mise completions
  - gh completions
```

#### 22-prompt.zsh — GATED

```yaml
gate: interactive-only
purpose: "Prompt configuration (starship or pure)"
guard: '[[ "$NG_MODE" == "agentic" ]] && return 0'
content: 'eval "$(starship init zsh)"'
```

#### 30-agentic.zsh — AGENTIC ONLY

```yaml
gate: agentic-only  # only loads when NG_MODE=agentic
purpose: "Minimal, predictable environment for AI tool sessions"
guard: '[[ "$NG_MODE" != "agentic" ]] && return 0'
content:
  - "PROMPT='%~ %# '"  # static, single-line, no escapes
  - "unsetopt BEEP"
  - "export TERM_PROGRAM_AGENTIC=1"  # signal to tools
  - "# No RPROMPT, no precmd hooks, no title-setting"
design_rationale: |
  Agentic tools need:
  1. Predictable stdout (no decorations, no async prompt updates)
  2. Fast startup (no completion init, no plugin loading)
  3. Correct PATH and env (mise, direnv still active)
  4. Stable cursor position (static prompt)
```

#### 99-local.zsh

```yaml
gate: always
purpose: "Machine-local overrides, not managed by chezmoi"
implementation: |
  Source ~/.zshrc.local if it exists. This file is gitignored.
  Used for machine-specific secrets, temp aliases, experiments.
content: '[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"'
```

### 3.5 Fish Shell Config

Fish config follows the same data-driven pattern but uses fish syntax.
The key architectural requirement: **shared values come from `.chezmoidata.yaml`**.

```yaml
chezmoidata_shared_values:
  xdg:
    config_home: "$HOME/.config"
    data_home: "$HOME/.local/share"
    state_home: "$HOME/.local/state"
    cache_home: "$HOME/.cache"
  path_prepends:
    - "$HOME/.local/bin"
    - "$HOME/.local/share/mise/shims"
  aliases:               # gate: always — safe, no POSIX shadows
    ll: "ls -lah"
    g: "git"
    dc: "docker compose"
  coreutil_aliases:       # gate: interactive-only — shadow POSIX commands
    cat: "bat --paging=never"
    find: "fd"
    grep: "rg"
```

Fish conf.d modules mirror the zsh structure:

```yaml
fish_modules:
  00-xdg.fish: "XDG exports — rendered from chezmoidata"
  01-path.fish: "PATH — rendered from chezmoidata.path_prepends"
  02-mise.fish: "mise activate fish"
  03-direnv.fish: "direnv hook fish"
  10-aliases.fish: "safe aliases — rendered from chezmoidata.aliases (no POSIX shadows)"
  15-coreutil-aliases.fish: "coreutil replacements — rendered from chezmoidata.coreutil_aliases (human only, not sourced in agentic)"
  20-prompt.fish: "starship init fish"
  99-local.fish: "source ~/.config/fish/local.fish if exists"
```

### 3.6 Bash Config (Minimal)

```yaml
purpose: "Clean runtime for scripts and tools that spawn bash"
dot_bash_profile: |
  # Source bashrc for interactive login shells
  [[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
dot_bashrc: |
  # ~/.bashrc — Minimal. For tools that spawn bash subshells.
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

  # Homebrew
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

  # mise
  command -v mise &>/dev/null && eval "$(mise activate bash)"

  # direnv
  command -v direnv &>/dev/null && eval "$(direnv hook bash)"
```

---

## 4. iTerm2 Profile Specifications

### Delivery Mechanism

iTerm2 supports **Dynamic Profiles**: JSON files placed in
`~/Library/Application Support/iTerm2/DynamicProfiles/` are auto-loaded.

The `scripts/install-iterm2-profiles.sh` script symlinks or copies from the repo.

### Profile 1: Dev (zsh)

```json
{
  "Profiles": [{
    "Name": "Dev (zsh)",
    "Guid": "ng-dev-zsh",
    "Custom Command": "Yes",
    "Command": "/bin/zsh -l",
    "Tags": ["nash-group", "dev"],
    "Badge Text": "",
    "Title Components": 2,
    "Working Directory": "~/Organizations",
    "Use Custom Working Directory": "Yes"
  }]
}
```

```yaml
behavior:
  shell: "/bin/zsh -l"
  env_vars: []
  loads: "full interactive zshrc.d/ stack"
  prompt: "starship"
  working_dir: "~/Organizations"
  use_case: "day-to-day development, git, code review"
```

### Profile 2: Agentic (zsh minimal)

```json
{
  "Profiles": [{
    "Name": "Agentic (zsh)",
    "Guid": "ng-agentic-zsh",
    "Custom Command": "Yes",
    "Command": "/bin/zsh -l",
    "Tags": ["nash-group", "agentic"],
    "Initial Text": "",
    "Custom Directory": "Yes",
    "Working Directory": "~/Organizations",
    "Set Environment Variables": {
      "NG_MODE": "agentic"
    }
  }]
}
```

```yaml
behavior:
  shell: "/bin/zsh -l"
  env_vars:
    NG_MODE: "agentic"
  loads: "00-xdg, 01-path, 02-mise, 03-direnv, 10-aliases, 30-agentic"
  skips: "15-coreutil-aliases, 20-interactive, 21-completion, 22-prompt"
  prompt: "static '%~ %# '"
  working_dir: "~/Organizations"
  use_case: "claude code, codex cli, gemini cli, copilot cli, cursor terminal"
  design_goals:
    - "fast startup (< 200ms)"
    - "predictable stdout (no async prompt, no decorations)"
    - "correct env (mise + direnv active)"
    - "no completion overhead"
```

### Profile 3: Human (fish)

```json
{
  "Profiles": [{
    "Name": "Human (fish)",
    "Guid": "ng-human-fish",
    "Custom Command": "Yes",
    "Command": "/opt/homebrew/bin/fish -l",
    "Tags": ["nash-group", "human"],
    "Working Directory": "~/Organizations",
    "Use Custom Working Directory": "Yes"
  }]
}
```

```yaml
behavior:
  shell: "/opt/homebrew/bin/fish -l"
  env_vars: []
  loads: "full fish conf.d/ stack"
  prompt: "starship"
  working_dir: "~/Organizations"
  default_profile: true  # this is the default iTerm2 tab
  use_case: "human interactive development, exploration"
  note: "$SHELL remains /bin/zsh — this is an iTerm2 override only"
```

---

## 5. Homebrew Package Manifest

### User-Level Foundation (single install via Homebrew)

```yaml
taps:
  - "homebrew/bundle"

formulae:
  # Shells
  - bash           # modern bash 5.x for scripts
  - fish           # human interactive shell
  - zsh-completions

  # Version/env management
  - mise           # single version manager
  - direnv         # per-directory env

  # Core CLI
  - git
  - gh             # GitHub CLI
  - gnupg          # GPG commit signing
  - openssh

  # Modern coreutils
  - coreutils
  - gnu-sed
  - grep
  - findutils

  # Search/view
  - ripgrep        # rg
  - fd             # find replacement
  - bat            # cat replacement
  - fzf            # fuzzy finder
  - jq
  - yq

  # Shell quality
  - shellcheck
  - shfmt
  - starship       # cross-shell prompt

  # Chezmoi
  - chezmoi

  # Secrets
  - gopass

casks:
  - iterm2
  - orbstack       # container runtime (Docker alternative)
  # Other casks are project-specific or user-preference — not managed here

not_installed_globally:
  # These are EXPLICITLY project-level. Do not install via Homebrew.
  - node           # managed by mise per-project
  - python         # managed by mise per-project
  - go             # managed by mise per-project
  - rust           # managed by rustup per-project
  - deno           # managed by mise per-project
  - bun            # managed by mise per-project
  - terraform      # managed by mise per-project
  - pnpm           # installed via corepack per-project
```

### Global mise Config (~/.config/mise/config.toml)

```toml
[tools]
# Conservative defaults — only for global CLI tools, not project builds
node = "lts"       # for global CLIs: claude, codex, etc.
python = "latest"  # for global CLIs: pipx tools, scripts

[settings]
experimental = true
always_keep_download = false
```

```yaml
constraint: |
  Global mise versions exist ONLY to provide a runtime for globally-installed
  CLI tools (e.g., npm -g packages). Projects MUST override with local mise.toml.
  The global config should never be so specific that it constrains project builds.
```

---

## 6. chezmoi Data Architecture

### .chezmoidata.yaml (shared values rendered into both zsh and fish)

```yaml
# .chezmoidata.yaml — single source of truth for cross-shell values
# chezmoi templates reference these as .xdg.config_home, .paths, etc.

xdg:
  config_home: "{{ .chezmoi.homeDir }}/.config"
  data_home: "{{ .chezmoi.homeDir }}/.local/share"
  state_home: "{{ .chezmoi.homeDir }}/.local/state"
  cache_home: "{{ .chezmoi.homeDir }}/.cache"

paths:
  prepend:
    - "{{ .chezmoi.homeDir }}/.local/bin"
    - "{{ .chezmoi.homeDir }}/.local/share/mise/shims"

homebrew:
  prefix: "/opt/homebrew"

aliases:
  # Safe aliases — don't shadow POSIX commands. Loaded in all modes.
  ll: "ls -lah"
  g: "git"
  dc: "docker compose"

coreutil_aliases:
  # Coreutil replacements — shadow POSIX commands with modern tools.
  # Loaded in interactive mode ONLY. Agents get vanilla coreutils.
  # Rationale: Principle 8 (Fail Fast). Agents expect POSIX semantics.
  # Shadowing grep→rg changes flag behavior and output format silently.
  cat: "bat --paging=never"
  find: "fd"
  grep: "rg"

git:
  user_name: "Jeffrey Nash"
  user_email: "{{ .git_email }}"  # from chezmoi.toml config prompt
  signing_key: "{{ .gpg_key_id }}"
  default_branch: "main"
  ignore_case: false
```

### Template Usage Pattern

The same data renders into shell-specific syntax:

**zsh template example (01-path.zsh.tmpl):**
```
# 01-path.zsh — PATH construction
# GATE: always

path_prepend() { [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }

{{- range .paths.prepend }}
path_prepend "{{ . }}"
{{- end }}

export PATH
```

**fish template example (01-path.fish.tmpl):**
```
# 01-path.fish — PATH construction

{{- range .paths.prepend }}
fish_add_path --prepend "{{ . }}"
{{- end }}
```

This ensures PATH ordering, aliases, and env values are defined once and rendered
correctly for each shell.

---

## 7. ng-doctor Specification

The doctor command is the verification harness for all phases.

### Location

`~/.local/bin/ng-doctor` (delivered via chezmoi from `home/dot_local/bin/ng-doctor.tmpl`)

### Check Categories and Exit Codes

```yaml
exit_codes:
  0: "all checks passed"
  1: "one or more checks failed"

output_format: |
  ✓ check-name: description
  ✗ check-name: description — EXPECTED: x, GOT: y
  ⊘ check-name: skipped (reason)

categories:
  shell:
    - login_shell_is_zsh
    - homebrew_bash_installed
    - fish_installed
    - zshenv_is_minimal
    - zshrc_loads_modules
    - zshrc_d_modules_present

  path:
    - homebrew_on_path
    - local_bin_on_path
    - mise_shims_on_path
    - no_duplicate_path_entries

  tools:
    - mise_installed
    - mise_activated
    - direnv_installed
    - direnv_hooked
    - chezmoi_installed
    - starship_installed
    - gopass_installed

  iterm2:
    - dynamic_profiles_dir_exists
    - dev_profile_installed
    - agentic_profile_installed
    - human_fish_profile_installed

  agentic:
    - agentic_mode_loads_minimal
    - agentic_prompt_is_static
    - agentic_startup_under_200ms

  filesystem:
    - xdg_dirs_exist
    - organizations_dir_exists
    - development_dir_exists
    - spotlight_exclusions_set
    - git_ignorecase_false

  hygiene:
    - no_orphan_lockfiles
    - no_nvmrc_in_systemconfig
    - no_node_version_in_systemconfig
    - chezmoi_source_clean
```

### Check Implementation Pattern

```bash
check_login_shell_is_zsh() {
  local actual
  actual=$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}')
  if [[ "$actual" == "/bin/zsh" ]]; then
    pass "login_shell_is_zsh" "Login shell is /bin/zsh"
  else
    fail "login_shell_is_zsh" "Login shell" "/bin/zsh" "$actual"
  fi
}

check_agentic_startup_under_200ms() {
  local ms
  ms=$(NG_MODE=agentic zsh -ic 'exit' 2>/dev/null |& tail -1)
  # Use zsh's TIMEFMT or /usr/bin/time
  ms=$( { time NG_MODE=agentic zsh -lic 'exit'; } 2>&1 | grep real | awk '{print $2}' )
  # parse and compare to 200ms threshold
  # ...
}
```

---

## 8. Implementation Phases

### Phase 0: Doctor Harness (do this first)

```yaml
goal: "Build the verification tool so all subsequent work is testable"
tasks:
  - id: "P0-1"
    action: "Create home/dot_local/bin/ng-doctor.tmpl"
    spec: "Section 7 of this document"
    output: "ng-doctor script with all check stubs (pass/fail/skip framework)"
    note: "Checks can return 'skip' if prereqs aren't met yet"

  - id: "P0-2"
    action: "Apply via chezmoi and verify ng-doctor runs"
    verify: "ng-doctor exits 1 with clear list of failures"

deliverable: "ng-doctor runs, reports current state, most checks fail (expected)"
```

### Phase 1: Shell Stabilization

```yaml
goal: "Fix post-OS-update breakage, establish stable shell init"
depends_on: "Phase 0"
tasks:
  - id: "P1-1"
    action: "Set login shell to /bin/zsh"
    command: "sudo chsh -s /bin/zsh $USER"
    verify: "ng-doctor: login_shell_is_zsh passes"

  - id: "P1-2"
    action: "Create .chezmoidata.yaml with shared values"
    spec: "Section 6"
    verify: "chezmoi data | yq '.xdg' shows correct values"

  - id: "P1-3"
    action: "Create dot_zshenv.tmpl"
    spec: "Section 3.1"
    verify: "chezmoi apply; source ~/.zshenv; echo $XDG_CONFIG_HOME"

  - id: "P1-4"
    action: "Create dot_zprofile.tmpl"
    spec: "Section 3.2"
    verify: "ng-doctor: homebrew_on_path passes"

  - id: "P1-5"
    action: "Create dot_zshrc.tmpl"
    spec: "Section 3.3"

  - id: "P1-6"
    action: "Create all zshrc.d/ modules"
    spec: "Section 3.4 (all modules)"
    verify: |
      ng-doctor: zshrc_d_modules_present passes
      Interactive: zsh -lic 'echo ok' works
      Agentic: NG_MODE=agentic zsh -lic 'echo ok' works

  - id: "P1-7"
    action: "Create/update fish conf.d/ modules from chezmoidata"
    spec: "Section 3.5"
    verify: "fish -lic 'echo ok' works"

  - id: "P1-8"
    action: "Create minimal bash config"
    spec: "Section 3.6"

  - id: "P1-9"
    action: "Run ng-doctor — all shell checks pass"
    verify: "ng-doctor shell category: all green"

deliverable: "Stable shells. zsh interactive works. zsh agentic works. fish works. bash clean."
```

### Phase 2: iTerm2 Profiles

```yaml
goal: "Three-profile system with dynamic profiles"
depends_on: "Phase 1"
tasks:
  - id: "P2-1"
    action: "Create iterm2/profiles/ JSON files"
    spec: "Section 4"

  - id: "P2-2"
    action: "Create scripts/install-iterm2-profiles.sh"
    behavior: |
      Creates ~/Library/Application Support/iTerm2/DynamicProfiles/ if needed.
      Symlinks profile JSONs from repo into DynamicProfiles/.
      Idempotent — safe to re-run.

  - id: "P2-3"
    action: "Move iTerm2 themes from repo root to iterm2/themes/"
    spec: "Section 2 migration map"

  - id: "P2-4"
    action: "Verify agentic profile startup time"
    verify: |
      ng-doctor: agentic_startup_under_200ms passes
      NG_MODE=agentic zsh -lic 'echo $PROMPT' shows '%~ %# '

deliverable: "Three iTerm2 profiles. Fish is default tab. Agentic mode < 200ms."
```

### Phase 3: Repo Structure Cleanup

```yaml
goal: "Restructure system-config repo to target layout"
depends_on: "Phase 2"
tasks:
  - id: "P3-1"
    action: "Execute migration map (moves, deletes)"
    spec: "Section 2 migration map"
    method: "git mv for moves, git rm for deletes"

  - id: "P3-2"
    action: "Delete orphaned files"
    targets:
      - "package-lock.json"
      - ".nvmrc"
      - ".node-version"
      - ".gemini/tmp/audit_script.sh"

  - id: "P3-3"
    action: "Delete empty stub directories"
    targets:
      - "02-configuration/editors/"
      - "02-configuration/shells/"
      - "03-automation/hooks/"
      - "03-automation/workflows/"

  - id: "P3-4"
    action: "Consolidate docs/ from numbered dirs"
    method: |
      Merge content from 01-setup/, 02-configuration/, 05-reference/
      into docs/setup.md, docs/shells.md, docs/terminals.md, docs/tools.md.
      Preserve useful content, discard redundancy.

  - id: "P3-5"
    action: "Update chezmoi source path if needed"
    verify: "chezmoi source-path points to home/ in repo"

  - id: "P3-6"
    action: "Update AGENTS.md and CLAUDE.md to reflect new structure"

  - id: "P3-7"
    action: "Run ng-doctor — all hygiene checks pass"
    verify: "ng-doctor hygiene category: all green"

deliverable: "Clean repo. No dead files. No structural overlap. chezmoi works from home/."
```

### Phase 4: Homebrew and mise Stabilization

```yaml
goal: "Reproducible tool foundation"
depends_on: "Phase 3"
tasks:
  - id: "P4-1"
    action: "Create/update Brewfile from manifest"
    spec: "Section 5"
    location: "home/run_once_before/02-brew-packages.sh.tmpl"

  - id: "P4-2"
    action: "Create global mise config"
    spec: "Section 5 (global mise config)"
    location: "home/dot_config/mise/config.toml.tmpl"

  - id: "P4-3"
    action: "Create repo-local .mise.toml"
    purpose: "Pin tools needed by system-config scripts only"
    content: |
      [tools]
      shellcheck = "latest"
      shfmt = "latest"

  - id: "P4-4"
    action: "Verify tool chain"
    verify: |
      ng-doctor: mise_installed, mise_activated, direnv_installed,
      direnv_hooked, chezmoi_installed, starship_installed all pass

deliverable: "All foundation tools installed. mise is sole version authority."
```

### Phase 5: macOS Integration

```yaml
goal: "Spotlight, Time Machine, iCloud exclusions configured"
depends_on: "Phase 4"
tasks:
  - id: "P5-1"
    action: "Document Spotlight exclusions"
    targets:
      - ~/Organizations
      - ~/Development
      - ~/.local/share/mise
    method: "System Settings UI or mdutil CLI"
    note: "Some exclusions require GUI — document the manual steps"

  - id: "P5-2"
    action: "Document Time Machine exclusions"
    targets:
      - ~/.local/share/mise/installs
      - ~/.cache
      - ~/Library/Group Containers/HUAQ24HBR6.dev.orbstack
      - ~/Library/Caches
    method: "tmutil addexclusion or System Settings"

  - id: "P5-3"
    action: "Verify git ignorecase"
    command: "git config --global core.ignorecase false"
    verify: "ng-doctor: git_ignorecase_false passes"

  - id: "P5-4"
    action: "Run full ng-doctor"
    verify: "All categories green"

deliverable: "macOS exclusions documented/applied. Full ng-doctor pass."
```

---

## 9. Verification Matrix

Every deliverable must be testable. This matrix maps specs to doctor checks.

```
┌─────────────────────┬──────────────────────────────┬─────────────────────────┐
│ Spec Section        │ Doctor Check                 │ Phase                   │
├─────────────────────┼──────────────────────────────┼─────────────────────────┤
│ AD-01               │ login_shell_is_zsh           │ 1                       │
│ AD-03               │ homebrew_bash_installed       │ 4                       │
│ AD-04               │ no_nvmrc_in_systemconfig     │ 3                       │
│ AD-06               │ xdg_dirs_exist               │ 1                       │
│ 3.1 zshenv          │ zshenv_is_minimal            │ 1                       │
│ 3.3 zshrc           │ zshrc_loads_modules          │ 1                       │
│ 3.4 zshrc.d         │ zshrc_d_modules_present      │ 1                       │
│ 3.4 30-agentic      │ agentic_mode_loads_minimal   │ 1                       │
│ 3.4 30-agentic      │ agentic_prompt_is_static     │ 1                       │
│ 3.4 30-agentic      │ agentic_startup_under_200ms  │ 2                       │
│ 4 profiles          │ dev_profile_installed         │ 2                       │
│ 4 profiles          │ agentic_profile_installed     │ 2                       │
│ 4 profiles          │ human_fish_profile_installed  │ 2                       │
│ 5 homebrew          │ homebrew_on_path             │ 1                       │
│ 5 mise              │ mise_installed               │ 4                       │
│ 5 mise              │ mise_activated               │ 4                       │
│ 5 direnv            │ direnv_hooked                │ 4                       │
│ 6 chezmoi           │ chezmoi_source_clean         │ 3                       │
│ macOS integration   │ spotlight_exclusions_set      │ 5                       │
│ macOS integration   │ git_ignorecase_false         │ 5                       │
└─────────────────────┴──────────────────────────────┴─────────────────────────┘
```

---

## 10. Anti-Patterns (Explicit Prohibitions)

```yaml
never:
  - "Modify anything in Zone 0 (/, /System, /usr, /bin, /sbin)"
  - "Set $SHELL to fish system-wide"
  - "Use #!/bin/bash (use #!/usr/bin/env bash)"
  - "Install language runtimes via Homebrew (use mise)"
  - "Hand-maintain .nvmrc or .node-version alongside mise.toml"
  - "Generate .nvmrc or .node-version from mise (SSoT violation — Principle 15)"
  - "Shadow POSIX coreutils (grep, find, cat) in agentic mode (Principle 8)"
  - "Put dev code in ~/Desktop or ~/Documents (iCloud sync)"
  - "Store secrets in plaintext on disk"
  - "Use cron (use launchd)"
  - "Add PATH entries without idempotency guards"
  - "Load interactive features in non-interactive shells"
  - "Put stdout-producing code in .zshenv"
  - "Commit temp files to AI tool config directories"
  - "Create numbered top-level directories in the repo (01-setup, etc.)"
  - "Maintain empty placeholder directories"
  - "Write config directly to ~/.config — always go through chezmoi"
```

---

## Appendix A: Agentic Tool Compatibility Notes

```yaml
claude_code_cli:
  shell_requirement: "zsh or bash"
  spawns_subshells: true
  reads_SHELL_var: true
  needs: "mise shims on PATH, direnv active"

codex_cli:
  shell_requirement: "bash-compatible"
  spawns_subshells: true
  needs: "clean stdout, fast startup"

cursor_ide:
  integrated_terminal: "inherits $SHELL"
  needs: "zsh with full PATH, mise active"

windsurf_cascade:
  terminal: "spawns $SHELL"
  needs: "POSIX-compatible shell"

gemini_cli:
  shell_requirement: "bash or zsh"
  needs: "standard env, no fish syntax"

copilot_cli:
  shell_requirement: "bash or zsh"
  integration: "shell alias/function injection"
```

---

## Appendix B: Quick Reference — What Goes Where

```
┌──────────────────────────────┬──────────────────────────────────────┐
│ If you need to...            │ Put it in...                         │
├──────────────────────────────┼──────────────────────────────────────┤
│ Set XDG vars                 │ .zshenv + fish/conf.d/00-xdg.fish   │
│ Configure PATH               │ .zprofile + zshrc.d/01-path.zsh     │
│ Add an alias                 │ zshrc.d/10-aliases.zsh              │
│ Add a human-only feature     │ zshrc.d/20-interactive.zsh (gated)  │
│ Tune agentic mode            │ zshrc.d/30-agentic.zsh              │
│ Add a machine-local override │ ~/.zshrc.local (gitignored)         │
│ Pin a project's node version │ project-level mise.toml             │
│ Install a global CLI tool    │ Brewfile or global mise config      │
│ Add a scheduled task         │ ~/Library/LaunchAgents/ (launchd)   │
│ Store a secret               │ gopass or macOS Keychain            │
│ Add an iTerm2 profile        │ iterm2/profiles/ + install script   │
└──────────────────────────────┴──────────────────────────────────────┘
```
