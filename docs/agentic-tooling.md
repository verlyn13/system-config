---
title: Agentic Tooling
category: reference
component: agentic_tooling
status: active
version: 1.1.0
last_updated: 2026-04-08
tags: [agentic, mcp, zsh, claude, codex, cursor, windsurf, copilot, gemini, workspace]
priority: high
---

# Agentic Tooling

This repo manages two things for agentic tools:

1. A zsh-first shell contract.
2. A minimal user-level MCP baseline.

Everything project-specific belongs in the project.

This document is also the project-facing compatibility guide for repos that want to work cleanly with the current `system-config` model.

## Shell Contract

- zsh is the only managed interactive shell.
- bash is for scripts and subprocesses.
- fish is not a supported agent shell and is not managed here.

If a tool spawns subshells, assume zsh or POSIX semantics.

## Project Contract

Keep repo-specific decisions in the repo:

| Concern | Location |
|---------|----------|
| Tool/runtime versions | `.mise.toml` |
| Secrets and env vars | `.envrc` |
| Project MCP servers | `.mcp.json` |
| Project instructions | `AGENTS.md`, `CLAUDE.md`, tool-native project docs |
| Workspace identity and lifecycle | `.workspace/workspace.toml` when the project is workspace-enrolled |

## Workspace-Compatible Projects

Projects that want to be compatible with this system should keep a narrow, explicit project surface.

### Required ideas

- The repo owns its own runtime and tool contract.
- The repo owns its own env and secret-loading contract.
- The repo owns its own agent instructions.
- The repo must not depend on user-global MCP or shell config for project-specific behavior.

### Recommended checked-in files

| File | Purpose |
|------|---------|
| `.mise.toml` | Tool versions, tasks, repo-local command surface |
| `.envrc` | Project-scoped env loading only |
| `AGENTS.md` | Canonical cross-tool project contract |
| `CLAUDE.md` | Claude-specific project guidance if needed |
| `.codex/config.toml` | Codex project-local config if the repo needs it |
| `.claude/` | Claude agents, hooks, skills, rules |
| `.cursor/rules/` | Cursor project rules if used |
| `.workspace/workspace.toml` | Workspace identity, lifecycle, labels, service categories when enrolled |
| `.workspace/README.md` | Short human-readable explanation of the workspace contract |

### Command-surface rule

Prefer relocatable commands over path-bound wrappers.

Good examples:

- `uv run python -m pytest -v`
- `uv run python -m manim render -ql ...`
- `bun x tsx ...`
- `python -m ...`

Avoid making the project contract depend on:

- direct `.venv/bin/*` entrypoints
- absolute filesystem paths
- host-global aliases
- user-global MCP config

Reason:

- projects move between paths
- workspace hosts will mount repos at different locations
- direct virtualenv shebangs can go stale after a repo move

### `.envrc` rule

`.envrc` remains project-owned, but it should stay narrow.

Use it for:

- project-scoped env vars
- project-scoped secret loading
- minimal activation glue such as `use mise`

Do not use it for:

- choosing OrbStack, Podman, or another substrate
- broad user-global exports
- hidden bootstrap logic required just to make the repo executable

If a project later becomes fully containerized, `.envrc` should become thinner, not disappear into global config.

### Workspace-enrolled projects

When a project participates in workspace management, keep these boundaries:

- `system-config` owns the substrate boundary, user config shape, and future launcher shape
- user-level config owns exact project enrollment and host ceilings
- project repo owns `.workspace/workspace.toml`, labels, service categories, requested limits, `.mise.toml`, `.envrc`, and `.mcp.json`

Projects may be compatible in more than one mode:

- local-process by default, no managed containers yet
- enrolled, but `driver = "none"`
- workspace-managed infra project using compose or containers

Compatibility does not require every project to become containerized on day one.

### Containerized project rule

If a project uses managed containers later:

- keep container runtime selection out of the repo
- keep service roles explicit in `.workspace/workspace.toml`
- move system packages and runtime dependencies needed for containerized execution into the image or container contract
- keep `.envrc` focused on project env and secrets, not substrate bootstrap

## Global MCP Baseline

`scripts/sync-mcp.sh` syncs only these user-level servers:

- `context7`
- `github`
- `memory`
- `sequential-thinking`
- `brave-search`
- `firecrawl`

Auth-required servers use runtime wrapper commands under `~/.local/bin/`. Secrets come from env vars or 1Password CLI (`op`) at launch time and must not be written into persistent user config files.

### Wrapper servers

Three servers require auth and are invoked via runtime wrappers deployed to `~/.local/bin/` by chezmoi:

| Server | Wrapper | op:// URI | Env var |
|--------|---------|-----------|---------|
| `github` | `mcp-github-server` | `op://Dev/github-dev-tools/token` | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| `brave-search` | `mcp-brave-search-server` | `op://Dev/brave-search/api-key` | `BRAVE_API_KEY` |
| `firecrawl` | `mcp-firecrawl-server` | `op://Dev/firecrawl/api-key` | `FIRECRAWL_API_KEY` |

Wrappers check the env var first. If absent, they call `op read --account my.1password.com <op://...>`. If both are absent, the wrapper exits with a diagnostic message and the MCP server fails to start.

## Tool Matrix

| Tool | User-level config | Managed by this repo | Project guidance |
|------|-------------------|----------------------|------------------|
| Claude Code CLI | `~/.claude.json` | Yes, global MCP baseline only | Use `.mcp.json` and `.claude/` in the project |
| Codex CLI | `~/.codex/config.toml` | Yes, managed MCP block only | Project MCP servers belong in `.mcp.json`, not in the user-level Codex config |
| Cursor IDE | `~/.cursor/mcp.json` | Yes, global MCP baseline only | Keep project or workspace servers outside the user-global file |
| Windsurf IDE | `~/.codeium/windsurf/mcp_config.json` | Yes, global MCP baseline only | Same rule as Cursor |
| GitHub Copilot CLI | `~/.copilot/mcp-config.json` | Yes, global MCP baseline only | Auth and repo-specific behavior stay tool-native/manual |
| Gemini CLI | tool-native config | No | Keep it project-local and manual until it has a stable project-scope MCP story |
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` | No | Separate product and config plane |

## Claude Code Permissions

`~/.claude/settings.json` is managed manually (not by chezmoi or sync-mcp.sh). Key decisions:

- `defaultMode: "acceptEdits"` — Claude applies file edits without per-edit confirmation.
- The allow list covers: standard dev tools, package managers (`npm`, `npx`, `bun`, `bunx`), shell utilities, and linting tools (`shellcheck`, `shfmt`).
- The deny list covers: `.env` files, secret material by extension (`.pem`, `.key`, `.p12`), AWS credentials, GPG directory, and destructive `rm -rf` patterns. It does not block SSH public keys or gh auth config — agents need those for git signing and GitHub operations.
- Do not add project-specific allow/deny rules or MCP tool permissions to this file. Keep them in the project's `.claude/settings.json`.

## Operational Rules

- Do not sync project servers into user-global config files.
- Do not generate fish shell helpers for agent tools.
- Do not persist expanded tokens into `~/.claude.json`, `~/.codex/config.toml`, IDE MCP JSON, or similar files.
- Prefer env vars, 1Password CLI (`op read`) at runtime, or tool-native login flows.
- Treat local tool state as local state. Track intentional config, ignore caches and machine-specific runtime artifacts.

## Related

- [`docs/workspace-management.md`](./workspace-management.md)
- [`README.md`](../README.md)
- [`AGENTS.md`](../AGENTS.md)
