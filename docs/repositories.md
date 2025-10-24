---
title: Repositories
category: reference
component: repositories
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Repository Roles and Usage

Authoritative vs. legacy repositories to avoid confusion and drift.

## Authoritative: system-setup-update

- Purpose: Primary, actively maintained system configuration and observability repo on this machine
- Ownership: Source of truth for policies, scripts, schemas, schedules, and docs
- Wiring: MCP server resources/tools and dashboard bridge should reference this repo’s scripts
- Data paths: `~/.local/share/devops-mcp/` (registry, observations, logs)

## Legacy: system-setup

- Purpose: Previous import/snapshot for reference
- Policy: Treat as read-only; do not point automation to it
- Migration: Copy any missing notes into `system-setup-update` and archive/rename the legacy directory

## Guardrails

- Validation: `scripts/validate-observability.sh` warns if the repo name is not `system-setup-update` or if a sibling `system-setup` directory is present
- Policy: `04-policies/policy-as-code.yaml` declares repository roles

## Dashboard & MCP

- Dashboard agent should read from the HTTP bridge (`scripts/http-bridge.js`) or via MCP resources wired to this repo’s data
- The bridge and MCP both use the same local cache under `~/.local/share/devops-mcp/`, independent of repo folders

