---
title: Vercel CLI Setup
category: reference
component: vercel_cli_setup
status: active
version: 2.0.0
last_updated: 2026-04-08
tags: [cli, vercel, envrc]
priority: medium
---

# Vercel CLI Setup

Vercel CLI is treated as a project tool, not a shell-managed global surface.

## Policy

- Install the CLI with the package manager you prefer for the project.
- Keep auth and project env in the project’s `.envrc`.
- Do not add Vercel-specific shell init to this repo.

## Typical Usage

```bash
npm install -g vercel
vercel --version
```
