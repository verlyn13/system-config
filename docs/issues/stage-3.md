---
title: Stage 3 — SSE & Observers
category: tracking
component: bridge
status: active
version: 1.1.0
last_updated: 2025-09-30
---

# Stage 3 — SSE & Observers

Epic: <link to MVP Orchestration Epic>
Owners: @AgentA @AgentB @AgentC @AgentD

## Entrance Criteria
- [x] Stage 2 complete (typed clients/adapters integrated, no contract drift)

## Agent A — Bridge/Contracts
- [x] Provide SSE validator script (scripts/sse-validate.mjs) and guide (docs/guides/sse-validation.md)
- [x] Ensure SSE emits `ProjectObsCompleted` and `SLOBreach` (already implemented)
- [x] Optional: add SSE smoke in CI (off by default, enable via `SSE_SMOKE=1`)

## Agent B — DS CLI
- [ ] Ensure DS emits relevant events or integrates with Bridge SSE if applicable (optional)

## Agent C — Dashboard
- [ ] Use EventSource and validate SSE via Ajv client-side
- [ ] Log drift if validation fails; do not render invalid payloads

## Agent D — MCP
- [ ] Maintain alias parity for observer routes; ensure feasibility of SSE mirroring if needed

## Validation Steps

```
# Validate SSE payloads (Bridge)
OBS_BRIDGE_URL=http://127.0.0.1:7171 node scripts/sse-validate.mjs
```

## Acceptance
- [ ] Bridge SSE payloads validate against schemas
- [ ] Dashboard validates SSE before rendering and logs drift
