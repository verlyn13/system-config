#!/usr/bin/env bash
set -euo pipefail

BRIDGE=${OBS_BRIDGE_URL:-http://127.0.0.1:7171}

echo "== Health =="
curl -fsS "$BRIDGE/api/health" | jq .

echo "== Telemetry Info =="
curl -fsS "$BRIDGE/api/telemetry-info" | jq .

echo "== Schemas =="
curl -fsS "$BRIDGE/api/discovery/schemas" | jq '.schemas | map(."$id")'

echo "== Projects =="
curl -fsS "$BRIDGE/api/projects" | jq '.count'

PID=$(curl -fsS "$BRIDGE/api/projects" | jq -r '.projects[0].id // empty')
if [[ -n "$PID" ]]; then
  echo "== Project Health ($PID) =="
  curl -fsS "$BRIDGE/api/projects/$(python3 - <<PY
import urllib.parse,sys
print(urllib.parse.quote(sys.argv[1]))
PY
"$PID")/health" | jq .

  echo "== Observer Items ($PID) =="
  curl -fsS "$BRIDGE/api/obs/projects/$(python3 - <<PY
import urllib.parse,sys
print(urllib.parse.quote(sys.argv[1]))
PY
"$PID")/observers" | jq '.items | length'
else
  echo "No projects found; run discovery: $BRIDGE/api/discover"
fi

echo "OK"

