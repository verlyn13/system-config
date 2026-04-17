---
title: GitHub Copilot CLI Setup
category: reference
component: copilot_cli_setup
status: active
version: 3.0.1
last_updated: 2026-04-15
tags: [cli, copilot, ai, npm, mcp, zsh]
priority: medium
---

# GitHub Copilot CLI Setup

Minimal configuration for GitHub Copilot CLI. This repo does not manage Copilot shell aliases or fish snippets.

## Overview

- Installation: `npm install -g @github/copilot`
- Configuration: `~/.copilot/`
- Optional MCP baseline file: `~/.copilot/mcp-config.json`

## Installation

```bash
npm install -g @github/copilot
copilot --version
```

## MCP Policy

If `~/.copilot/mcp-config.json` is used on this machine, `scripts/sync-mcp.sh` manages only the approved global MCP baseline there. Project-specific MCP servers are not synced into Copilot’s user-global config.

## Updates

```bash
npm update -g @github/copilot
```

## Troubleshooting

- Use Copilot’s native `/login` flow or the documented GitHub token flow.
- If MCP state looks wrong, rerun `scripts/sync-mcp.sh`; do not hand-edit a project server into the user-global file.
- Keep project tokens in `.envrc`, not in shell startup files.
- For live system-wide secret-handling rules, use [`docs/secrets.md`](./secrets.md).

## Related

- [`docs/secrets.md`](./secrets.md)
- [`docs/agentic-tooling.md`](./agentic-tooling.md)
- [Official Copilot CLI Docs](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
- [Copilot Plans](https://github.com/features/copilot/plans)
