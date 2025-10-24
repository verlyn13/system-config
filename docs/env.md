---
title: Env
category: reference
component: env
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Environment Variables (Bridge + Integration)

Bridge
- `PORT` (default: 7171): bridge listening port
- `BRIDGE_TOKEN` (optional): if set, require `Authorization: Bearer <token>` on all non-public endpoints
- `BRIDGE_AUTO_DISCOVER` (default: 1): if not `0/false`, auto-runs discovery when registry missing
- `BRIDGE_STRICT` (default: 0): if `1/true`, validate observer writes; violations recorded per observer
- `BRIDGE_STRICT_FAIL` (default: 0): if `1/true`, return HTTP 422 if any strict validation failed
- `BRIDGE_CORS` (default: 0): if `1/true`, enables permissive CORS for dev (GET/POST/OPTIONS, `*` origin)
- `DS_BASE_URL` (fallback): DS server URL if not present in system registry
- `MCP_BASE_URL` (fallback): MCP server URL if not present in system registry

System Registry
- Location: `~/.config/system/registry.yaml` (install with `./scripts/install-system-registry.sh`)
- Validate with: `./scripts/opa-validate-registry.sh`

Data Paths
- Primary: `~/.local/share/devops-mcp/`
  - Registry: `project-registry.json`
  - Observations: `observations/<project_id_encoded>/`
- macOS fallback (read-only merge): `~/Library/Application Support/devops.mcp/observations`
