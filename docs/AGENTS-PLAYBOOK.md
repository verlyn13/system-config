---
title: Agents Playbook (Integration)
category: reference
component: agents
status: active
version: 1.0.0
last_updated: 2025-09-28
---

# Agents Playbook: How to Integrate Correctly

Non-negotiables
- Use the bridge for discovery and data; do not read repo files directly.
- Load schemas from `/api/discovery/schemas` and build Ajv validators before rendering.
- Only use canonical observer enum externally: `git, mise, sbom, build, manifest`.
- Map internal aliases at boundaries: `repo→git`, `deps→mise`.
- Validate SSE events (ProjectObsCompleted, SLOBreach) before using them.
- Registry and observations live under `~/.local/share/devops-mcp/`.

Discovery
- Services and contracts: `GET /api/discovery/registry`
- Schemas: `GET /api/discovery/schemas` (with ETag)

Data
- Projects: `GET /api/projects`
- Project health: `GET /api/projects/:id/health`
- Observer lines: `GET /api/obs/projects/:id/observers`
- SSE: `GET /api/events/stream` (ProjectObsCompleted, SLOBreach only)

Actions
- Trigger discovery: `GET /api/discover`
- Run observers: `POST /api/tools/project_obs_run { project_id, observer? }`

Ports & Env Conventions (All Agents)
- Bridge (Agent A): port `7171`, `OBS_BRIDGE_URL` (default `http://127.0.0.1:7171`)
- MCP (Agent D): port `4319`, `MCP_URL` / `MCP_BASE_URL` (default `http://127.0.0.1:4319`)
- DS (Agent B): port `7777`, `DS_BASE_URL` (default `http://127.0.0.1:7777`)

Use the canonical ports above in examples and defaults. Avoid mixing Bridge/MCP ports in the same role. Client generation should use `*_BASE_URL`; runtime validators should honor overrides and not hardcode ports.

Validation Rules
- Fail fast: invalid payloads should be rejected or surfaced prominently.
- Do not emit or accept `quality` as a targetable observer in public APIs.
- Do not extend enums or schemas without a version bump.

CI Gates (recommended)
- Validate JSON Schemas (ajv), OpenAPI (Redocly), registry policy (Conftest), and breaking changes (oasdiff) on PR.
