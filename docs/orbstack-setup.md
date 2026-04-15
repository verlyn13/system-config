---
title: OrbStack Setup
category: reference
component: orbstack_setup
status: active
version: 2.0.0
last_updated: 2026-04-08
tags: [orbstack, containers]
priority: high
---

# OrbStack Setup

OrbStack is an app-level dependency. This repo does not manage OrbStack through fish shell config.

## Policy

- Install OrbStack with Homebrew cask or the vendor installer.
- Let OrbStack manage its own DynamicProfiles entry.
- Do not add OrbStack-specific fish config back into this repo.

## Typical Usage

```bash
brew install --cask orbstack
orb version
```
