---
title: Ports and Env Conventions
category: policy
component: bridge
status: active
version: 1.1.0
last_updated: 2025-09-30
---

# Ports and Environment Conventions

Canonical defaults and environment variable names across agents to avoid confusion.

## Canonical Ports

- Bridge (Agent A): `7171`
- MCP Server (Agent D): `4319`
- DS CLI (Agent B): `7777`

## Environment Variables

- Bridge
  - `OBS_BRIDGE_URL` — base URL for clients (default `http://127.0.0.1:7171`)
  - `PORT` — server listen port (default `7171` for the Bridge)
  - `BRIDGE_TOKEN` — optional bearer token for protected endpoints
- MCP
  - `MCP_URL` — base URL for scripts (default `http://127.0.0.1:4319`)
  - `MCP_BASE_URL` — base URL for code generation (default `http://127.0.0.1:4319`)
- DS
  - `DS_BASE_URL` — base URL (default `http://127.0.0.1:7777`)
  - `DS_TOKEN` — bearer token for DS endpoints

## Guidelines

- Examples and defaults must match the canonical ports above.
- Do not mix Bridge and MCP ports in examples. If both are referenced, use both variables explicitly.
- Client generation scripts should use the appropriate `*_BASE_URL` variable.
- Runtime validators should accept overrides via these env vars and not hardcode ports.

