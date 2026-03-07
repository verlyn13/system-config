---
title: SystemConfig
category: reference
component: overview
status: active
version: 3.0.0
last_updated: 2026-02-23
tags: [overview, setup, chezmoi, mise, fish]
priority: critical
---

# SystemConfig

macOS development environment configuration, templates, and tooling.
Managed with chezmoi (dotfiles), mise (runtimes), and Fish shell.

See [AGENTS.md](AGENTS.md) for the canonical project contract and [REPO-STRUCTURE.md](REPO-STRUCTURE.md) for the full directory layout.

---

## Quick Start

```bash
# Apply dotfiles to live system
chezmoi apply --dry-run    # preview first
chezmoi apply

# Update all packages, tools, and runtimes
system-update

# Sync SystemConfig templates into dotfiles source (SSOT workflow)
~/SystemConfig/scripts/sync-chezmoi-templates.sh
```

---

## Key Locations

| What | Where |
|------|-------|
| Chezmoi templates (SSOT) | `06-templates/chezmoi/` |
| Chezmoi source (live) | `~/.local/share/chezmoi/` |
| Chezmoi data | `~/.config/chezmoi/chezmoi.toml` |
| Fish config | `~/.config/fish/conf.d/` |
| Global MCP servers | `ai-tools/mcp-servers.json` |
| system-update config | `~/.config/system-update/config` |
| system-update logs | `~/Library/Logs/system-update/` |

---

## SSOT Workflow

`SystemConfig/06-templates/chezmoi/` is the source of truth for all shell integration,
global mise config, and run_once installers.

```
Edit in SystemConfig → sync-chezmoi-templates.sh → chezmoi apply
```

```bash
# Check for divergence without writing (suitable for pre-commit hook)
~/SystemConfig/scripts/sync-chezmoi-templates.sh --check

# Sync and overwrite even if dotfiles file is newer
~/SystemConfig/scripts/sync-chezmoi-templates.sh --force
```

---

## AI CLI Tools

| Tool | Location | Version | Update |
|------|----------|---------|--------|
| Claude Code CLI | `~/.local/bin/claude` | 2.1.50 | `claude update` or `system-update` |
| Codex CLI | `/opt/homebrew/bin/codex` | — | `brew upgrade codex` |

Claude Code fish config: `~/.config/fish/conf.d/10-claude.fish` (managed via chezmoi)
Claude Code docs: [`docs/claude-cli-setup.md`](docs/claude-cli-setup.md)

---

## Phase Status

Phases 0-9 complete (Phase 7 Android skipped by choice). Phase 10 (System Optimization) not started.
See [AGENTS.md § Phase Status](AGENTS.md#phase-status) for details.

---

## Common Fixes

```bash
# PATH not resolving claude/mise/node
fish -c 'echo $PATH | tr " " "\n" | grep local'

# Template "map has no entry for key" error
cat ~/.config/chezmoi/chezmoi.toml    # ensure headless, android, shell keys present

# Brew GUI bundle timed out
cd ~/.local/share/chezmoi/workspace/dotfiles && brew bundle --file=Brewfile.gui

# Check what chezmoi would change
chezmoi diff
```

---

## Secrets

Managed via gopass. See [`docs/guides/GOPASS-DEFINITIVE-GUIDE.md`](docs/guides/GOPASS-DEFINITIVE-GUIDE.md).
