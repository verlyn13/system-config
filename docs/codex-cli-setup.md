---
title: Codex CLI Setup
category: reference
component: codex_cli_setup
status: active
version: 3.1.0
last_updated: 2026-04-15
tags: [cli, codex, openai, ai, mcp, zsh]
priority: medium
---

# Codex CLI Setup

This repo manages only the user-level Codex MCP baseline. It does not use fish integration and it does not push project-specific MCP servers into the global Codex config.

## Overview

- Installation: `npm install -g @openai/codex`
- Global config: `~/.codex/config.toml`
- Managed surface: the `system-config` MCP block inside `~/.codex/config.toml`

## Installation

```bash
npm install -g @openai/codex
```

## MCP Integration

`scripts/sync-mcp.sh` replaces the managed block in `~/.codex/config.toml` between marker comments. That block contains only the approved global baseline.

Rules:
- Do not append project-specific servers to the user-global file.
- Do not persist secrets in `~/.codex/config.toml`.
- If a project needs Codex-specific config, keep it explicit and local to that repo.

## Troubleshooting

- `which codex` should resolve to the installed CLI binary.
- If MCP state looks stale, rerun `scripts/sync-mcp.sh`; it is idempotent and replaces the managed block.
- If an auth-required global server fails, fix the env var or 1Password item used by the runtime wrapper.
- If an `npx`-backed global server fails inside one project with `npm` package metadata errors, make sure the live config was regenerated after the `mcp-npx` change; managed global servers should not run `npx` from the project working directory.
- Keep `OPENAI_API_KEY` project-scoped via `.envrc` unless there is a clear reason to export it more broadly.

## Related

- [`docs/secrets.md`](./secrets.md)
- [`docs/agentic-tooling.md`](./agentic-tooling.md)
- [Official Codex Docs](https://developers.openai.com/codex/cli/)
