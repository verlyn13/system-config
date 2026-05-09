---
title: system-config
category: reference
component: overview
status: active
version: 4.1.2
last_updated: 2026-05-06
tags: [overview, setup, chezmoi, mise, zsh, mcp]
priority: critical
---

# system-config

macOS development environment configuration, templates, and tooling.
Managed with chezmoi, mise, zsh, and a minimal user-level MCP baseline.

Start with [AGENTS.md](AGENTS.md) for the canonical contract.

## Quick start

```bash
chezmoi apply --dry-run
chezmoi apply

ng-doctor --summary
system-update --check

scripts/sync-mcp.sh --dry-run
scripts/sync-mcp.sh
```

## Key locations

| What | Where |
|------|-------|
| Active chezmoi source | `home/` |
| Chezmoi data | `~/.config/chezmoi/chezmoi.toml` |
| zsh modules | `home/dot_config/zshrc.d/` |
| Global MCP baseline | `scripts/mcp-servers.json` |
| MCP sync script | `scripts/sync-mcp.sh` |
| MCP secrets manifest (op URIs) | `home/dot_config/mcp/private_common.env` → `~/.config/mcp/common.env` |
| MCP wrappers | `home/dot_local/bin/executable_mcp-*.tmpl` → `~/.local/bin/mcp-*-server` |
| Workspace launcher | `home/dot_local/bin/executable_workspace.tmpl` |
| system-update | `scripts/system-update.sh` + `scripts/system-update.d/*.sh` |
| system-update logs | `~/Library/Logs/system-update/` |

## Current model

- zsh is the only managed interactive shell; bash is runtime-only; fish is not managed here.
- Global `mise` provides stable baseline runtimes (Node, Python, Rust, etc.).
- Global MCP config is a minimal user-level baseline synced across five tools.
- Project-specific runtime, env, and MCP decisions live in the project
  (`.mise.toml`, `.envrc`, `.mcp.json`).
- Secrets live in 1Password (`my.1password.com`, `Dev` vault); resolved
  at launch time via `op run` or runtime wrappers; never in config files.

## AI tooling

| Tool | User-level config | Project-level |
|------|-------------------|---------------|
| Claude Code CLI | `~/.claude.json` (MCP), `~/.claude/settings.json` (manual settings) | `.mcp.json`, `.claude/` |
| Codex CLI | `~/.codex/config.toml` | `.codex/config.toml` (trusted projects) |
| Cursor | `~/.cursor/mcp.json` | `.cursor/mcp.json` |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` | — (no project scope) |
| GitHub Copilot CLI | `~/.copilot/mcp-config.json` | `.copilot/mcp-config.json` |

### Documentation

- [`docs/project-conventions.md`](docs/project-conventions.md) — compatibility guide for downstream projects (link this from a project's `AGENTS.md`)
- [`docs/mcp-config.md`](docs/mcp-config.md) — MCP framework (scopes, launch, sync)
- [`docs/github-mcp.md`](docs/github-mcp.md) — GitHub MCP integration
- [`docs/secrets.md`](docs/secrets.md) — 1Password + `op` policy
- [`docs/ssh.md`](docs/ssh.md) — SSH client policy
- [`docs/security-hardening-implementation-plan.md`](docs/security-hardening-implementation-plan.md) — UA wired-network audit follow-up and hardening todo plan
- [`docs/host-capability-substrate/project-substrate-adoption.md`](docs/host-capability-substrate/project-substrate-adoption.md) — transitional host-local project substrate admission policy
- [`docs/agentic-tooling.md`](docs/agentic-tooling.md) — shell + tool contract
- [`docs/workspace-management.md`](docs/workspace-management.md) — workspace POC
- [`docs/github-org-setup.md`](docs/github-org-setup.md) — org-level GitHub config (teams, ruleset, CODEOWNERS)
- [`docs/claude-cli-setup.md`](docs/claude-cli-setup.md)
- [`docs/codex-cli-setup.md`](docs/codex-cli-setup.md)
- [`docs/copilot-cli-setup.md`](docs/copilot-cli-setup.md)
- [`docs/claude-desktop-setup.md`](docs/claude-desktop-setup.md)

## Workspace POC

v1 workspace management is local-only and uses one dedicated OrbStack
workspace host with Podman inside. Operator surface: `workspace list`,
`workspace show <slug>`, `workspace host-shell`, `workspace host-run …`,
`workspace doctor`. See [`docs/workspace-management.md`](docs/workspace-management.md).

## Common fixes

```bash
chezmoi diff                      # see pending chezmoi changes
cat ~/.config/chezmoi/chezmoi.toml # machine-specific data
ng-doctor                         # environment health report
workspace doctor                  # workspace health
scripts/sync-mcp.sh --dry-run     # preview MCP config updates
system-update --list              # see system-update plugins
```
