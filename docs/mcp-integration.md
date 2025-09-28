---
title: MCP Integration Guide
category: reference
component: mcp
status: active
version: 1.0.0
last_updated: 2025-09-28
---

# MCP Integration (Project-Aware)

This guide shows how to expose project-aware resources and tools from your existing MCP server using the local registry and NDJSON observation cache.

## Resources (read-only)

- `devops://project_manifest/<project_id>` → registry.manifest
- `devops://project_status/<project_id>` → latest and history from `observations.ndjson`
- `devops://project_inventory` → full registry

See example implementations: `examples/mcp-integration/resources.ts`.

## Tools

- `project_discover({})` → wraps `scripts/project-discover.sh`
- `project_obs_run({ project_id, observers? })` → wraps `scripts/obs-run.sh`
- `project_health({ project_id })` → aggregate via `scripts/obs-rollup.js`

See example implementations: `examples/mcp-integration/tools.ts`.

## Telemetry & IDs

- Pass `run_id` through tool executions and attach `{project_id, tier, kind}` attributes.
- Emit `ProjectObsCompleted` JSON logs for observability.

## Security

- Tools run read-only observers; mutators must require `confirm=true`.
- Path allowlists and URL redaction are enforced by the shell orchestrators.

