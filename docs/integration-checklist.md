# Integration Checklist (15‑Minute Demo)

Use this checklist to validate the MVP end-to-end locally.

## Prerequisites

- Bridge repo cloned; Node 18+
- DS CLI available; `mise` if using provided tasks
- Optional: Dashboard running for UI validation

## Steps

1) Start DS (secure)

```
DS_TOKEN=<token> DS_CORS=1 mise run serve-secure
```

2) Start Bridge (dev, strict + CORS)

```
./scripts/run-bridge-dev.sh
```

3) Validate typed endpoints

```
node scripts/validate-endpoints.js
PROJECT_ID=<id> node scripts/validate-endpoints.js  # to include manifest/integration
```

4) Validate DS contracts

```
DS_BASE_URL=http://127.0.0.1:7777 DS_TOKEN=<token> node scripts/ds-validate.mjs
```

5) Run discovery

```
./scripts/run-discovery.sh
```

6) Run observers

```
./scripts/run-observers-all.sh
```

7) Observe SSE

```
node scripts/sse-listen.js
```

8) UI Walkthrough (optional)

- Contracts page: schemas + registry (ETag-aware)
- Docs page: DS/MCP status cards
- Projects grid/table: readiness chips
- Project page: Manifest Validate (`checkedAt`), Integration Refresh (`checkedAt` + summary)

## Expected Outcomes

- Endpoint validation scripts exit 0
- DS validation script prints `DS validation passed`
- SSE outputs `ProjectObsCompleted` and/or `SLOBreach` events
- Dashboard renders typed cards without raw JSON by default

