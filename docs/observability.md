---
title: Observability Platform
category: reference
component: observability
status: active
version: 1.0.0
last_updated: 2025-09-28
---

# Observability Platform (Local + MCP)

Core pieces delivered:

- Schemas: `schema/project.manifest.schema.json`, `schema/observer.output.schema.json`
- Observers: `observers/repo-observer.sh`, `observers/deps-observer.sh`
  - Also: `observers/build-observer.sh`, `observers/quality-observer.sh`, `observers/sbom-observer.sh`
- Orchestrators: `scripts/project-discover.sh`, `scripts/obs-run.sh`
- Validation: `scripts/validate-observability.sh`
- Schedules: `scripts/obs-hourly.sh`, `scripts/install-observability-launchagent.sh`
- HTTP Bridge: `scripts/http-bridge.js` (read-only)
  - Aggregated health at `/api/projects/:id/health` (rollup + basic SLO eval)
  - SSE events at `/api/events/stream`

## Output Contract (NDJSON)

See `schema/observer.output.schema.json` for full contract. One JSON object per line.

## Endpoints (HTTP Bridge)

- `GET /api/telemetry-info`
- `GET /api/projects`
- `GET /api/projects/:id/status?limit=100&cursor=...`
- `GET /api/health`
- `GET /api/events/stream` (SSE; heartbeat + tail of latest entries)

Start: `node scripts/http-bridge.js` (default port 7171)

## MCP Integration

Use the local registry and observation files as backing stores for read-only MCP resources and tools:

- Resources: `project_manifest`, `project_status`, `project_inventory`
- Tools: `project_discover`, `project_obs_run`, `project_health`

Reference implementation examples in `PROJECT-OBSERVABILITY-PLAN.md`.

## Rollup & SLOs

- `scripts/obs-rollup.js` computes a simple aggregate from recent NDJSON entries and checks `p95LocalBuildSec` if applicable.
- Bridge injects this summary into `/api/projects` and exposes `/api/projects/:id/health`.

## SBOM Observer

- `observers/sbom-observer.sh` uses `syft` (if installed) with a 60s timeout to summarize packages and licenses. Missing tools result in `status: warn` without failing the run.
