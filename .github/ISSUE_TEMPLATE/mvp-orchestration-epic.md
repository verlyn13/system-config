---
name: MVP Orchestration Epic
about: Track the full MVP across four agents (A Bridge, B DS CLI, C Dashboard, D MCP)
title: "MVP Orchestration Epic"
labels: ["epic","mvp"]
assignees: []
---

## Overview

Track the end-to-end MVP across repos using staged checklists. Agents:
- Agent A = Bridge/Contracts (this repo)
- Agent B = DS CLI repo
- Agent C = Dashboard repo
- Agent D = MCP server repo

Link the per-stage tracker issues under this epic as they’re created.

## Milestones

- [ ] Stage 0 — Prep & Baseline
- [ ] Stage 1 — Contract Freeze & CI Gates
- [ ] Stage 2 — Typed Clients & Adapters
- [ ] Stage 3 — SSE & Observers
- [ ] Stage 4 — UX & Prefetch
- [ ] Stage 5 — Demo & Rollout

---

## Stage 0 — Prep & Baseline

### Agent A (Bridge/Contracts)
- [ ] Discovery endpoints complete: `/api/discovery/services`, `/api/discovery/schemas`, `/api/schemas/{name}`
- [ ] Project endpoints complete: `/api/projects/{id}/{manifest,integration}`
- [ ] Tools endpoints complete: `POST /api/tools/{obs_validate,obs_migrate}`
- [ ] SSE: `/api/events/stream` emitting events
- [ ] Aliases under `/api/obs/*` mirror primary routes
- [ ] `.well-known/obs-bridge.json` published
- [ ] CI workflow `validate-endpoints` present and green on main
- [ ] Dev helpers exist: `scripts/run-bridge-dev.sh`, `scripts/sse-listen.js`, `scripts/ds-validate.mjs`

### Agent B (DS CLI)
- [ ] `schema_version: "ds.v1"` on core endpoints
- [ ] `/api/self-status` includes `nowMs:number`
- [ ] Discovery present: `/.well-known/obs-bridge.json`, `/api/discovery/services`
- [ ] Go client `pkg/dsclient` + example & tests present

### Agent C (Dashboard)
- [ ] `bridgeAdapter` scaffolded (typed client fallback-safe)
- [ ] `dsAdapter` scaffolded (optional in Stage 0)
- [ ] Contracts viewer page exists
- [ ] DS/MCP status cards scaffolded

### Agent D (MCP)
- [ ] `/api/obs/*` parity routes implemented
- [ ] OpenAPI + schemas served
- [ ] Self-status includes `schemaVersion`, `contractVersion`, `nowMs`

### Acceptance
- [ ] `node scripts/validate-endpoints.js` passes (optionally with `PROJECT_ID`)
- [ ] `DS_BASE_URL=... DS_TOKEN=... node scripts/ds-validate.mjs` passes
- [ ] Discovery shows `ts:number` and `ds.self_status` present

---

## Stage 1 — Contract Freeze & CI Gates

### Agent A (Bridge/Contracts)
- [ ] Contracts annotated (e.g., docs note for "obs.v1"); examples use epoch ms
- [ ] OpenAPI + JSON Schemas finalized for MVP
- [ ] CI gates: Ajv schema validation, Redocly lint, endpoint validation

### Agent B (DS CLI)
- [ ] `/api/self-status` confirms `schema_version` and `nowMs`
- [ ] Readme/docs note `schema_version` + envelope behavior

### Agent C (Dashboard)
- [ ] Docs page links to: discovery, openapi, registry and schemas
- [ ] ETag-aware schema fetch + raw toggle in Contracts view

### Agent D (MCP)
- [ ] Alias parity tests in CI
- [ ] Endpoint smoke for typed discovery and self-status

### Acceptance
- [ ] All repos have CI gates and green builds

---

## Stage 2 — Typed Clients & Adapters

### Agent A (Bridge/Contracts)
- [ ] Scripts to generate clients: Bridge, DS, MCP
- [ ] Client-generation guide published

### Agent C (Dashboard)
- [ ] Bridge TS client generated and used by `bridgeAdapter`
- [ ] DS client optional; `dsAdapter` scaffold ready
- [ ] Core pages render typed `integration` + `manifest`; tools wired

### Agent D (MCP)
- [ ] Optional MCP client generated (for demos)

### Acceptance
- [ ] Dashboard builds with typed client preferred; fallback works

---

## Stage 3 — SSE & Observers

### Agent A (Bridge/Contracts)
- [ ] Observers run (`git`, `mise`) and write NDJSON
- [ ] Hourly runner present (e.g., `scripts/obs-hourly.sh`)
- [ ] SSE emits `ProjectObsCompleted` and `SLOBreach`
- [ ] Optional Ajv SSE validator script added

### Agent C (Dashboard)
- [ ] SSE client validates events via Ajv before rendering

### Agent D (MCP)
- [ ] Observer routes under `/api/obs/projects/:id/...` wired

### Acceptance
- [ ] SSE events observed and validate; health rollup ok

---

## Stage 4 — UX & Prefetch

### Agent C (Dashboard)
- [ ] React Query prefetch (batched IDs, idle prefetch)
- [ ] Header chips + tooltips (last-checked, service status)
- [ ] Manifest/Integration cards: `checkedAt` + typed chips

### Agent A (Bridge/Contracts)
- [ ] `integration` includes `checkedAt:number`, typed `summary`, `services.ds.self_status`

### Acceptance
- [ ] Smooth render; ETag-aware Contracts page; chips correct

---

## Stage 5 — Demo & Rollout

### Agent A (Bridge/Contracts)
- [ ] Demo runbook and scripts present (start bridge, validate, discovery, observers, SSE)

### Agent B (DS CLI)
- [ ] Secure serve demo; `verify-ds-services.sh` passes; example client runs

### Agent C (Dashboard)
- [ ] UI walkthrough ready (Contracts, Docs, Projects, Project detail)

### Agent D (MCP)
- [ ] Alias parity showcased; typed OpenAPI served; optional client demo

### Acceptance
- [ ] One bridge contract; typed clients; typed UI; SSE validated; CI passes; observer loop functional

