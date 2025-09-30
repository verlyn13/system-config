---
title: Dashboard Integration
category: reference
component: dashboard
status: active
version: 1.0.0
last_updated: 2025-09-28
---

# Dashboard Integration Guide

Preferred data source: the HTTP bridge from this repo (system-setup-update).

## Environment

- `OBS_BRIDGE_URL` (default `http://127.0.0.1:7171`)
- Optional `BRIDGE_TOKEN` → add header `Authorization: Bearer <token>` to requests
- `DS_BASE_URL` (if using DS discovery) `http://127.0.0.1:7777`

## Endpoints

- `GET /api/health` – health
- `GET /api/telemetry-info` – contract/schema info
- `GET /api/projects` – registry (auto-discovers if empty)
- `GET /api/projects/:id/status?limit=…&cursor=…` – NDJSON tail
- `GET /api/projects/:id/health` – aggregate rollup + SLO flags
- `GET /api/obs/projects/:id/observers` – combined lines (compat route)
- `GET /api/obs/projects/:id/observer/:type` – filtered by observer
- `GET /api/events/stream` – SSE live updates
- `GET /api/discover` – manual discovery trigger
- `GET /api/obs/validate` – presence of registry and observations
- `POST /api/tools/project_obs_run` – run observer(s)
 - `GET /api/projects/:id/integration` – consolidated integration view (health, latest observers, DS/MCP status)
- `GET /api/discovery/registry` – system registry (services/contracts/paths)
- `GET /api/discovery/schemas` – contract schemas (with ETag)

## Typical Flow

1. On app start: call `/api/health` and `/api/telemetry-info`.
2. Load `/api/discovery/schemas` and build Ajv validators; cache by ETag.
3. Fetch `/api/projects`. If empty, POST a UI action calling `/api/discover`.
4. For a project detail page:
   - `/api/projects/:id/health`
   - `/api/obs/projects/:id/observers` (or the `:type` filter route)
5. Subscribe to `/api/events/stream` (SSE) for `ProjectObsCompleted` and `SLOBreach`. Validate payloads using Ajv validators.

## Notes

- Bridge merges observations from both `~/.local/share/devops-mcp/observations` and `~/Library/Application Support/devops.mcp/observations`.
- Lines are single-line NDJSON. Do not expect pretty JSON in files.
- Repo roles: authoritative repo is `system-setup-update`. Do not read files from legacy `system-setup`.

## Typed Rendering Example (React)

```js
import { loadSchemas, buildValidators, sseConnect, validateObsEvent, typedFetchHealth, validateObsList } from '../../examples/dashboard/helpers';

const BRIDGE = import.meta.env.VITE_OBS_BRIDGE_URL || 'http://127.0.0.1:7171';

useEffect(() => {
  let es;
  (async () => {
    const data = await loadSchemas(BRIDGE);
    const { validateObs, validateHealth, validateBreach } = buildValidators(data.schemas);
    es = sseConnect(BRIDGE, (type, payload) => {
      if (type === 'ProjectObsCompleted') validateObsEvent(validateObs, payload);
      if (type === 'SLOBreach' && validateBreach) validateObsEvent(validateBreach, payload);
      // render typed payload here
    });
  })();
  return () => es && es.close();
}, []);
```
// Example typed fetch of project health
const health = await typedFetchHealth(BRIDGE, projectId, validateHealth);
// Example typed validation of a list of ObserverLine
validateObsList(validateObs, observerItems);
