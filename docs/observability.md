---
title: Observability
category: reference
component: observability
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
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
- `GET /api/discover` (triggers discovery using scripts/project-discover.sh)
- `GET /api/obs/validate` (bridge-level validation: presence of registry and observations)
- `POST /api/tools/project_obs_run` (run observer(s), append NDJSON)
- `GET /api/migrate/obs[?project_id=...]` (consolidate per-observer files into canonical observations.ndjson)

Start: `node scripts/http-bridge.js` (default port 7171)

Auto-discovery: When `BRIDGE_AUTO_DISCOVER` is not `0/false`, the bridge will attempt to run `scripts/project-discover.sh` if the registry cache is missing/empty.

Migration: Use `scripts/migrate-observations.js` or `GET /api/migrate/obs` to consolidate per-observer `*.ndjson` into a canonical `observations.ndjson` per project.

Strict mode: Set `BRIDGE_STRICT=1` to enable stricter self-status reporting and SSE validation behavior.

## SSE (Server-Sent Events)

- Events: `ProjectObsCompleted` and `SLOBreach` only.
- Validation: Bridge validates `ProjectObsCompleted` against ObserverLine schema before emission; `SLOBreach` validated against slobreach schema.
- Clients should connect to `/api/events/stream` and validate payloads via schemas for strict typing.

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
