---
title: Stage 2
category: reference
component: stage_2
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Stage 2 — Typed Clients & Adapters

Epic: <link to MVP Orchestration Epic>
Owners: @AgentA @AgentB @AgentC @AgentD

## Entrance Criteria
- [x] Stage 1 complete (contracts frozen, CI gates in place, typed endpoint validation in CI)

## Agent A — Bridge/Contracts ✅ COMPLETE
- [x] Provide client generation guide (docs/guides/client-generation.md) ✅
- [x] Ensure dev CORS + strict defaults (scripts/run-bridge-dev.sh) ✅
- [x] OpenAPI accessible at /openapi.yaml (verified: HTTP 200 with CORS headers) ✅
- [x] Keep OpenAPI and Schemas stable during Stage 2 (no breaking changes) ✅

**Completion Date**: 2025-09-30
**All Agent A tasks complete. CI continues to enforce contract stability.**

## Agent B — DS CLI
- [ ] DS OpenAPI available and versioned; client generation guide/usage documented
- [ ] Ensure `schema_version: "ds.v1"` across endpoints

## Agent C — Dashboard
- [ ] Generate Bridge TS client and integrate via `bridgeAdapter` (fallback-safe)
- [ ] Optionally generate DS TS client and scaffold `dsAdapter`
- [ ] Pages render typed Integration/Manifest using adapter methods

## Agent D — MCP
- [ ] Ensure MCP OpenAPI available; optional MCP client generation for parity demos
- [ ] Maintain alias parity and discovery consistency during adapter rollout

## Validation Steps

```
# Bridge client
./scripts/generate-openapi-client.sh examples/dashboard/generated/bridge-client

# DS client (optional)
DS_BASE_URL=http://127.0.0.1:7777 ./scripts/generate-openapi-client-ds.sh examples/dashboard/generated/ds-client

# MCP client (optional)
MCP_BASE_URL=http://127.0.0.1:4319 ./scripts/generate-openapi-client-mcp.sh examples/dashboard/generated/mcp-client
```

## Acceptance
- [ ] Dashboard builds and runs using generated Bridge client via adapter
- [ ] Fallback to fetch remains working if client absent
- [ ] No contract-breaking changes merged during Stage 2

