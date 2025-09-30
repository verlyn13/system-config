---
title: SSE Validation (Stage 3)
category: guides
component: bridge
status: active
version: 1.1.0
last_updated: 2025-09-30
---

# SSE Validation Guide (Stage 3)

Validate live SSE payloads from the Bridge against JSON Schemas.

## Quick Start

```
OBS_BRIDGE_URL=http://127.0.0.1:7171 \
node scripts/sse-validate.mjs
```

Options:
- `BRIDGE_TOKEN` — include if the Bridge requires auth
- `SSE_VALIDATE_TIMEOUT_MS` — default 8000ms

The script returns success after validating the first `ProjectObsCompleted` or `SLOBreach` event; otherwise it times out.

