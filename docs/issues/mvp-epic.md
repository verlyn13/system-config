# MVP Orchestration Epic

Track the end-to-end MVP across repos using staged checklists. Agents:
- Agent A = Bridge/Contracts (this repo)
- Agent B = DS CLI repo
- Agent C = Dashboard repo
- Agent D = MCP server repo

## Milestones

- [ ] Stage 0 — Prep & Baseline
- [ ] Stage 1 — Contract Freeze & CI Gates
- [ ] Stage 2 — Typed Clients & Adapters
- [ ] Stage 3 — SSE & Observers
- [ ] Stage 4 — UX & Prefetch
- [ ] Stage 5 — Demo & Rollout

---

## Stage 0 — Prep & Baseline

### Agent A (Bridge/Contracts) ✅ COMPLETE
- [x] Discovery endpoints complete: `/api/discovery/services`, `/api/discovery/schemas`, `/api/schemas/{name}`
- [x] Project endpoints complete: `/api/projects/{id}/{manifest,integration}`
- [x] Tools endpoints complete: `POST /api/tools/{obs_validate,obs_migrate}`
- [x] SSE: `/api/events/stream` emitting events
- [x] Aliases under `/api/obs/*` mirror primary routes
- [x] `.well-known/obs-bridge.json` published
- [x] CI workflow `validate-endpoints` present and green on main
- [x] Dev helpers exist: `scripts/run-bridge-dev.sh`, `scripts/sse-listen.js`, `scripts/ds-validate.mjs`

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

