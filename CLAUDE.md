---
title: Claude Code Project Context
category: reference
component: ai-context
status: active
version: 3.0.0
last_updated: 2026-02-09
tags: [ai-cli, configuration]
priority: medium
---

@AGENTS.md

## Claude-Specific Notes

- Prefer specialized tools: `Read` over `cat`, `Grep` over `rg`, `Glob` over `find`, `Edit` over `sed`
- Format shell scripts with `fish_indent` (Fish) and lint with `shellcheck` (Bash)
- Global agents and commands are available at `~/.claude/` — do not duplicate here
- Chezmoi templates use Go syntax, not Jinja2
