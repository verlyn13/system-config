---
title: Sentry CLI Setup
category: reference
component: sentry_cli_setup
status: active
version: 2.2.0
last_updated: 2026-05-04
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

Project auth example. Replace the placeholder URI with the project's own
1Password item:

```bash
# op://<vault>/<item>/<field-label> — see Nash op-item-shape standard
export SENTRY_AUTH_TOKEN="$(op read --account my.1password.com 'op://Dev/<your-sentry-item>/auth-token')"
```

There is no shared `op://Dev/sentry/auth-token` item maintained by this
repo. Each consuming project owns its own Sentry credential under a
purpose-named, kebab-case item title (for example,
`sentry-<project>-deploy`).

For the live system-wide secret-handling rules, see [`docs/secrets.md`](./secrets.md).
For item-shape rules (naming, field uniqueness, label collisions), see the
Nash 1Password Item Shape Standard at
`~/Organizations/the-nash-group/.org/standards/op-item-shape.md`.
