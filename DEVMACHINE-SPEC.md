---
title: Development Machine Spec Archive
category: archive
component: devmachine_spec
status: archived
version: 2.0.0
last_updated: 2026-04-08
tags: [archive, migration]
priority: low
---

# Development Machine Spec Archive

This file is retained as historical context from the earlier migration and fish-transition design work. It is not the live specification anymore.

Current authoritative documents:
- `AGENTS.md`
- `README.md`
- `docs/agentic-tooling.md`

Current settled architecture:
- zsh is the only managed interactive shell
- bash is runtime-only
- fish is removed from the managed config surface
- `home/` is the active chezmoi source
- global MCP config is a small user-level baseline only
- project-specific runtime, env, and MCP decisions belong in `.mise.toml`, `.envrc`, and `.mcp.json`
