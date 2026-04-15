---
title: system-config
category: reference
component: overview
status: active
version: 3.0.0
last_updated: 2026-04-08
tags: [overview, setup, chezmoi, mise, zsh, mcp]
priority: critical
---

# system-config

macOS development environment configuration, templates, and tooling.
Managed with chezmoi, mise, zsh, and a minimal user-level MCP baseline.

See [AGENTS.md](AGENTS.md) for the canonical contract and [`docs/agentic-tooling.md`](docs/agentic-tooling.md) for tool-specific ownership.

## Quick Start

```bash
chezmoi apply --dry-run
chezmoi apply

ng-doctor --summary
workspace doctor

system-update

scripts/sync-mcp.sh --dry-run
scripts/sync-mcp.sh
```

## Key Locations

| What | Where |
|------|-------|
| Active chezmoi source | `home/` |
| Chezmoi data | `~/.config/chezmoi/chezmoi.toml` |
| Legacy dotfiles repo | `~/.local/share/chezmoi/` |
| zsh modules | `home/dot_config/zshrc.d/` |
| Global MCP baseline | `scripts/mcp-servers.json` |
| MCP sync script | `scripts/sync-mcp.sh` |
| Workspace config template | `home/dot_config/workspaces/config.toml.tmpl` |
| Workspace launcher | `home/dot_local/bin/executable_workspace.tmpl` |
| Workspace doctor | `home/dot_local/bin/executable_workspace-doctor.tmpl` |
| Example system-update config | `scripts/system-update.config.example` |
| system-update logs | `~/Library/Logs/system-update/` or `${TMPDIR:-/tmp}/system-update-$USER/` |

## Current Model

- zsh is the only managed interactive shell.
- bash is a script/runtime shell only.
- fish is no longer a managed shell surface in this repo.
- Global MCP config is intentionally small and user-level only.
- Project runtime, env, and MCP decisions belong in `.mise.toml`, `.envrc`, and `.mcp.json`.

## AI Tooling

| Tool | User-level config | Project-level config |
|------|-------------------|----------------------|
| Claude Code | `~/.claude.json` | `.mcp.json`, `.claude/` |
| Codex CLI | `~/.codex/config.toml` | project-local only when explicitly needed |
| Cursor | `~/.cursor/mcp.json` | workspace/project config if supported |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` | workspace/project config if supported |
| GitHub Copilot CLI | `~/.copilot/mcp-config.json` | tool-native/manual only |
| Gemini CLI | unmanaged by this repo | tool-native/manual only |

Current tooling docs:
- [`docs/agentic-tooling.md`](docs/agentic-tooling.md)
- [`docs/claude-cli-setup.md`](docs/claude-cli-setup.md)
- [`docs/codex-cli-setup.md`](docs/codex-cli-setup.md)
- [`docs/copilot-cli-setup.md`](docs/copilot-cli-setup.md)
- [`docs/claude-desktop-setup.md`](docs/claude-desktop-setup.md)
- [`docs/workspace-management.md`](docs/workspace-management.md)

## Workspace POC

- v1 workspace management is local-only and uses one dedicated OrbStack workspace host with Podman inside that host.
- Project compatibility rules live in [`docs/agentic-tooling.md`](docs/agentic-tooling.md).
- The current operator surface is `workspace list`, `workspace show <slug>`, `workspace host-shell`, `workspace host-run ...`, and `workspace doctor`.

## Common Fixes

```bash
chezmoi diff
cat ~/.config/chezmoi/chezmoi.toml
workspace list
workspace doctor
scripts/install-iterm2-profiles.sh
scripts/sync-mcp.sh --dry-run
system-update --list
```

## Secrets

Secrets are managed with 1Password CLI (`op`) and project `.envrc` files.
See [`docs/1password-migration-plan.md`](docs/1password-migration-plan.md). The repo must not contain plaintext passphrases or API keys.
