---
title: Gopass Definitive Guide
category: reference
component: gopass_definitive_guide
status: archived
version: 2.0.0
last_updated: 2026-04-08
tags: [gopass, secrets, envrc]
priority: medium
---

> **Deprecated**: This system now uses 1Password CLI (`op`) for secret
> management. See [`docs/1password-migration-plan.md`](../1password-migration-plan.md).
> Gopass remains installed as a cold archive until all secrets are migrated.

# Gopass Secret Management

## Quick Start

This repo does not store the gopass passphrase in version control.

```bash
gopass list
gopass show github/dev-tools-token
echo "my-secret-value" | gopass insert development/new-api-key
```

Use the local machine’s approved unlock flow. If you need the passphrase or keychain workflow, consult `~/.config/gopass/README-AGENTS.md` instead of this repo.

## How Gopass Works On This System

- Encryption: age
- Store location: `~/.local/share/gopass/stores/root/`
- Config: `~/.config/gopass/config`

## Project Usage

Keep project secrets in `.envrc`, not in shell startup files or global agent configs.

```bash
export OPENAI_API_KEY="$(gopass show -o openai/api-key)"
export FIRECRAWL_API_KEY="$(gopass show -o firecrawl/api-key)"
```

## MCP Wrappers

Global auth-required MCP servers use runtime wrapper commands under `~/.local/bin/`. Those wrappers:

- prefer an already-exported env var
- fall back to `gopass show -o ...`
- fail without writing the secret into the user config file
