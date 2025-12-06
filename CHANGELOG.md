---
title: Changelog
category: reference
component: changelog
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

# Changelog

## v0.3.0 (RC1)

Added
- McpServer migration with newline-delimited JSON framing for stdio
- Strict typed config (zod) with cross‑platform data dir defaults
- SecretRef allowlist + traversal guards; hashed secret audits; per‑tool throttle
- `pkg_sync_plan` (brew+mise) + `pkg_sync_apply` with post‑apply residual verification and INERT mode
- WAL maintenance: checkpoint(TRUNCATE) test enabled in CI
- Integration smoke (compiled) with initialization negotiation, TAP logs, and summary

Changed
- Hardened exec timeouts and structured timeout errors (code 124)
- Normalized mise outputs for planner/inventory
- Strict Zod schemas for tool inputs; removed any casts

Fixed
- Racey stdio framing and tools/list hangs by using McpServer
- Unstable integration tests by replacing vitest stdio tests with compiled smoke

