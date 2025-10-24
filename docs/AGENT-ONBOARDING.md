---
title: Agent Onboarding
category: reference
component: agent_onboarding
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Agent Onboarding: Shell, direnv, mise, chezmoi

Essential context to understand and work safely in this repo.

## TL;DR

- direnv uses Homebrew Bash to avoid macOS `/bin/bash` crashes.
  - File: `~/.config/direnv/direnv.toml` with `bash_path = "/opt/homebrew/bin/bash"`
  - Script: `bash scripts/repair-shell-env.sh`
- Fish init order (interactive):
  - `00-homebrew.fish` → `01-mise.fish` → `02-direnv.fish` → `03-starship.fish` → `04-paths.fish`
  - Homebrew PATH first, mise shims, direnv hook (with self‑test fail‑safe), then user bins appended.
- .envrc standard:
  - Embedded `use_mise()` with `direnv_load mise direnv exec`, then `use mise`
  - `PATH_add bin` and `PATH_add node_modules/.bin`
  - `dotenv_if_exists .env.local` and `.env`
  - Align across repos: `bash scripts/multirepo-align-env.sh ~/Development`

## Root Cause (historical)

- A custom `~/.config/direnv/direnvrc` redefined stdlib functions and called itself, causing recursion and segfaults during `direnv export`.
- Apple `/bin/bash` 3.2 (macOS 26) further destabilized evaluation. Forcing Homebrew bash fixed the runtime aspect; replacing `direnvrc` fixed the recursion.

## Where Things Live

- Repo `.envrc`: aligned to canonical pattern
- Fish templates: `06-templates/chezmoi/dot_config/fish/conf.d/*.fish`
- direnv templates:
  - `06-templates/chezmoi/dot_config/direnv/direnv.toml.tmpl`
  - `06-templates/chezmoi/dot_config/direnv/direnvrc.tmpl`
- starship templates:
  - `06-templates/chezmoi/dot_config/starship.toml.tmpl`
  - `06-templates/chezmoi/dot_config/fish/conf.d/03-starship.fish.tmpl`
- Scripts:
  - `scripts/repair-shell-env.sh` — fixes local env (bash_path, direnvrc, vendor hook)
  - `scripts/deploy-shell-config.sh` — installs fish and direnv configs into HOME
  - `scripts/multirepo-align-env.sh` — aligns `.envrc` across repos

## Validate

- New shell: open iTerm Fish; run:
  - `command -v brew && command -v mise && command -v direnv`
  - `direnv status` shows `bash_path /opt/homebrew/bin/bash`
- Per repo:
  - `direnv allow .` then `direnv export bash` (no errors)
- CI:
  - GitHub Action `.github/workflows/shell-env-validate.yml` checks `.envrc` structure and direnv basic export on Linux

## Claude Code CLI

**Complete documentation**: `docs/claude-cli-setup.md`

### Quick Reference

- **Installation**: npm global (`@anthropic-ai/claude-code`)
- **Version**: 2.0.3+
- **Location**: `~/.npm-global/bin/claude`
- **Config**: `~/.config/fish/conf.d/10-claude.fish`
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/10-claude.fish.tmpl`
- **Installer**: `06-templates/chezmoi/run_once_10-install-claude.sh.tmpl`
- **Update script**: `scripts/update-claude-cli.sh`

### Commands

- `cc` - Claude with default model (Sonnet 4.5, subscription auth)
- `ccc` - Continue conversation
- `ccp` - Plan/headless mode
- `ccplan` - Force Opus model with API auth
- `claude_check_updates` - Check for CLI updates

### Auth Modes

- `CLAUDE_AUTH=subscription` (default, session-based)
- `CLAUDE_AUTH=api` (env key via `ANTHROPIC_API_KEY` or `CLAUDE_API_KEY_CMD`)

### Model Configuration

- `CLAUDE_DEFAULT_MODEL="claude-sonnet-4-5-20250929"` (Sonnet 4.5)
- `CLAUDE_PLAN_MODEL="claude-opus-4-20250514"` (Opus 4 for planning)

### Installation & Updates

```bash
# Install (handled by chezmoi)
npm install -g @anthropic-ai/claude-code

# Check for updates
claude_check_updates

# Update CLI
npm update -g @anthropic-ai/claude-code

# Or use automated script
~/Development/personal/system-setup-update/scripts/update-claude-cli.sh
```

See `docs/claude-cli-setup.md` for complete setup, configuration, and troubleshooting.
