---
title: Stage 0
category: reference
component: stage_0
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

# Stage 0 — Prep & Baseline

Epic: <link to MVP Orchestration Epic>
Owners: @AgentA @AgentB @AgentC @AgentD
**Status**: Agent A COMPLETE (2025-09-29)

## Agent A — Bridge/Contracts ✅ COMPLETE
- [x] Discovery endpoints complete: `/api/discovery/services`, `/api/discovery/schemas`, `/api/schemas/{name}`
- [x] Project endpoints complete: `/api/projects/{id}/{manifest,integration}`
- [x] Tools endpoints complete: `POST /api/tools/{obs_validate,obs_migrate}`
- [x] SSE: `/api/events/stream` emitting events
- [x] Aliases under `/api/obs/*` mirror primary routes
- [x] `.well-known/obs-bridge.json` published
- [x] CI workflow `validate-endpoints` present and green on main
- [x] Dev helpers exist: `scripts/run-bridge-dev.sh`, `scripts/sse-listen.js`, `scripts/ds-validate.mjs`

## Agent B — DS CLI
- [ ] `schema_version: "ds.v1"` on core endpoints
- [ ] `/api/self-status` includes `nowMs:number`
- [ ] Discovery present: `/.well-known/obs-bridge.json`, `/api/discovery/services`
- [ ] Go client `pkg/dsclient` + example & tests present

## Agent C — Dashboard
- [ ] `bridgeAdapter` scaffolded (typed client fallback-safe)
- [ ] `dsAdapter` scaffolded (optional in Stage 0)
- [ ] Contracts viewer page exists
- [ ] DS/MCP status cards scaffolded

## Agent D — MCP
- [ ] `/api/obs/*` parity routes implemented
- [ ] OpenAPI + schemas served
- [ ] Self-status includes `schemaVersion`, `contractVersion`, `nowMs`

## Validation Steps

```
node scripts/validate-endpoints.js
DS_BASE_URL=http://127.0.0.1:7777 DS_TOKEN=... node scripts/ds-validate.mjs
node scripts/sse-listen.js
```

