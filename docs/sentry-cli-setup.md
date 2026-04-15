---
title: Sentry CLI Setup
category: reference
component: sentry_cli_setup
status: active
version: 2.0.0
last_updated: 2026-04-08
tags: [cli, sentry, envrc]
priority: medium
---

# Sentry CLI Setup

Sentry CLI is treated as a project tool, not a shell-managed global surface.

## Policy

- Install the CLI with the package manager you prefer for the project.
- Keep auth tokens in the project’s `.envrc`.
- Do not add Sentry-specific shell init to this repo.

## Typical Usage

```bash
npm install -g @sentry/cli
sentry-cli --version
```

Project auth example:

```bash
export SENTRY_AUTH_TOKEN="$(op read "op://Dev/sentry/auth-token")"
```
