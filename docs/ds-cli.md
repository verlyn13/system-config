---
title: Ds Cli
category: reference
component: ds_cli
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# DS CLI (ds-go) Integration

The DS CLI/server provides a local API to execute configuration-approved tasks and workflows for agents and humans. This repo treats DS as a first-class integration for observability, automation, and agent workflows.

## Server

Start the server:

```
ds serve --addr 127.0.0.1:7777
```

Discovery endpoints (served by ds):
- `GET /v1/capabilities` (standard discovery)
- `/.well-known/obs-bridge.json` (AI discovery manifest)
- `/openapi.yaml` (OpenAPI 3.0+ spec)
- `GET /api/self-status` (MCP parity; includes nowMs)

Docs (when hosted by ds):
- `/API.md` – full API reference
- `/QUICKSTART.md` – 5-minute guide

## This repo’s awareness

- AI discovery manifest included at `.well-known/ai-discovery.json` (for hosting or reference)
- MCP configuration example: `examples/agents/mcp-config.yaml`
- Claude integration guide: `examples/agents/claude-integration.md`
- Example clients:
  - Python: `examples/python/ds_client.py`
  - Shell: `examples/shell/ds-automation.sh`

## Policy & Validation

- `04-policies/policy-as-code.yaml` includes DS under tools (optional) and discovery endpoints.
- `scripts/validate-observability.sh` checks DS presence and warns if server is not reachable.

## Dashboard

The dashboard agent can discover DS automatically when the server is running on `127.0.0.1:7777` using `GET /v1/capabilities` or `/.well-known/ai-discovery.json`.
 
## Contract Requirements

- All core DS responses include a top-level `schema_version` (e.g., `"ds.v1"`) for strict typing.
- `nowMs` and other timestamps are epoch milliseconds where applicable (`/api/self-status`, envelope=true, etc.).
- Token auth: Bearer token is supported across all endpoints when configured.
