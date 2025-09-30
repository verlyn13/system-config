#!/usr/bin/env bash
set -euo pipefail

BRIDGE=${OBS_BRIDGE_URL:-http://127.0.0.1:7171}

echo "== Bridge Self-Status =="
curl -fsS "$BRIDGE/api/self-status" | jq . || true

echo "== OpenAPI (bridge) =="
curl -fsS "$BRIDGE/openapi.yaml" | head -n 5 || true

echo "== System Registry =="
curl -fsS "$BRIDGE/api/discovery/registry" | jq . || echo "No registry found"

echo "== DS Discovery (if configured) =="
DS_URL=$(jq -r '.services.ds.url // empty' <(curl -fsS "$BRIDGE/api/discovery/registry" 2>/dev/null) 2>/dev/null || echo "")
if [[ -n "$DS_URL" ]]; then curl -fsS "$DS_URL/v1/capabilities" | jq . || echo "DS unreachable"; else echo "DS URL not found in registry"; fi

echo "== MCP Self-Status (if configured) =="
MCP_URL=$(jq -r '.services.mcp.url // empty' <(curl -fsS "$BRIDGE/api/discovery/registry" 2>/dev/null) 2>/dev/null || echo "")
if [[ -n "$MCP_URL" ]]; then curl -fsS "$MCP_URL/api/self-status" | jq . || echo "MCP unreachable"; else echo "MCP URL not found in registry"; fi

echo "OK"

