---
title: Claude Code Project Context
category: reference
component: ai-context
status: active
version: 3.0.0
last_updated: 2026-04-08
tags: [ai-cli, configuration, zsh, mcp]
priority: medium
---

@AGENTS.md

## Claude-Specific Notes

- Prefer specialized tools: `Read` over `cat`, `Grep` over `rg`, `Glob` over `find`, `Edit` over `sed`
- zsh is the only managed interactive shell in this repo. Do not add fish config, fish syntax, or fish-specific aliases here.
- Lint shell scripts with `shellcheck`
- Global agents and commands are available at `~/.claude/` and `~/.codex/` where tool-native config expects them
- Chezmoi templates use Go syntax, not Jinja2
- Project runtime and secret decisions belong in `.mise.toml` and `.envrc`
- Project MCP servers belong in `.mcp.json`; `scripts/sync-mcp.sh` manages only the user-level global baseline
