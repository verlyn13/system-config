---
title: Stage 4 — UX & Prefetch
category: tracking
component: dashboard
status: planned
version: 1.1.0
last_updated: 2025-09-30
---

# Stage 4 — UX & Prefetch

Epic: <link to MVP Orchestration Epic>
Owners: @AgentA @AgentB @AgentC @AgentD

## Entrance Criteria
- [x] Stage 3: SSE & Observers validated (Bridge SSE schema-valid)
- [x] Prefetch endpoints expose ETag/Cache-Control (Bridge)

## Agent A — Bridge/Contracts
- [ ] Ensure ETag/Cache-Control headers present on discovery/projects endpoints
- [ ] Provide prefetch map for Dashboard (routes + TTLs)
- [x] Provide prefetch validator: `scripts/prefetch-validate.mjs`
 - [x] Document prefetch usage: `docs/prefetch.md` (includes `docs/prefetch-map.json`)

## Agent B — DS CLI
- [ ] Provide DS summary endpoint for quick prefetch (optional)
- [ ] Emit lightweight heartbeat for dashboards (optional)

## Agent C — Dashboard
- [ ] Implement prefetch on app boot (parallel fetch + cache)
- [ ] Respect ETag with conditional GETs
- [ ] Show skeleton UI while prefetch resolves; hydrate from cache

## Agent D — MCP
- [ ] Expose quick status endpoint (schemaVersion, contractVersion, nowMs)
- [ ] Optional: mirror Bridge prefetch map for parity

## Validation Steps

```
# Validate prefetch/cache semantics
OBS_BRIDGE_URL=http://127.0.0.1:7171 node scripts/prefetch-validate.mjs

# GitHub Action (manual trigger)
# .github/workflows/stage-4-prefetch.yml
```

## Acceptance
- [ ] Prefetch smoke workflow green
- [ ] Dashboard honors ETag and uses conditional GETs
- [ ] UX renders skeletons and hydrates with prefetched data
