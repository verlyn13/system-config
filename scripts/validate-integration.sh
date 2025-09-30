#!/usr/bin/env bash
set -euo pipefail

BRIDGE_URL=${OBS_BRIDGE_URL:-http://127.0.0.1:7171}

echo "== Bridge Health =="
curl -fsS "$BRIDGE_URL/api/health" | jq . || true
echo "== Telemetry Info =="
curl -fsS "$BRIDGE_URL/api/telemetry-info" | jq . || true
echo "== Discover (optional) =="
curl -fsS "$BRIDGE_URL/api/discover" | jq . || true
echo "== Projects =="
curl -fsS "$BRIDGE_URL/api/projects" | jq '.count'
echo "== Obs Validate =="
curl -fsS "$BRIDGE_URL/api/obs/validate" | jq . || true

echo "Done."

