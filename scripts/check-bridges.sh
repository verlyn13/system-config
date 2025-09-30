#!/usr/bin/env bash
set -euo pipefail

BRIDGE=${OBS_BRIDGE_URL:-http://127.0.0.1:7171}
MCP_URL=${MCP_BASE_URL:-http://127.0.0.1:4319}
DS_URL=${DS_BASE_URL:-http://127.0.0.1:7777}

echo "== Bridge =="
curl -fsS "$BRIDGE/api/self-status" | jq '{ok, contractVersion, schemaVersion, registry_path, project_count}' || true

echo "== MCP =="
curl -fsS "$MCP_URL/api/self-status" | jq . || echo "MCP unreachable"

echo "== DS =="
if [[ -n "${DS_TOKEN:-}" ]]; then AUTH=(-H "Authorization: Bearer $DS_TOKEN"); else AUTH=(); fi
curl -fsS "${AUTH[@]}" "$DS_URL/v1/health" | jq . || echo "DS unreachable"

echo "OK"

