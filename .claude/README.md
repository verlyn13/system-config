---
title: Claude Code Project Configuration
category: reference
component: claude-config
status: active
version: 2.0.0
last_updated: 2026-02-09
tags: [claude-code, configuration]
priority: medium
---

# .claude/ Directory

Project-specific Claude Code configuration for SystemConfig.

## Files

| File | Purpose | Committed |
|------|---------|-----------|
| `settings.json` | Project permissions (tools, MCP, scripts) | Yes |
| `settings.local.json` | Personal accumulated permissions | No (gitignored) |
| `README.md` | This file | Yes |

## Settings Hierarchy

Claude Code merges settings in order (later overrides earlier):

1. **Global** (`~/.claude/settings.json`) — user-wide defaults
2. **Project** (`.claude/settings.json`) — shared team permissions
3. **Local** (`.claude/settings.local.json`) — personal overrides, gitignored

## Global Agents and Commands

Generic agents (reviewer, architect, tester, etc.) and commands (commit, feature, debug, etc.) live at `~/.claude/` and are available in every project. Do not duplicate them here.

## Adding Project-Specific Commands

If this repo needs a repeatable workflow specific to SystemConfig:

1. Create `.claude/commands/<name>.md` with the prompt
2. Invoke with `/project:<name>` in Claude Code
3. Commit the file so other contributors get it

Currently no project-specific commands are needed — global commands cover all workflows.

## SSOT Workflow

SystemConfig is the source of truth for chezmoi templates. To propagate changes to the live dotfiles: edit in `06-templates/chezmoi/` → run `scripts/sync-chezmoi-templates.sh` → `chezmoi apply`. See `AGENTS.md` for the full SSOT policy.
