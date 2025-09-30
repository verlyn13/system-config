#!/usr/bin/env bash
set -euo pipefail

BRIDGE=${OBS_BRIDGE_URL:-http://127.0.0.1:7171}
PID=${1:?project_id required}
OBS=${2:-}

if [[ -n "$OBS" ]]; then
  body=$(jq -nc --arg pid "$PID" --arg obs "$OBS" '{project_id:$pid, observer:$obs}')
else
  body=$(jq -nc --arg pid "$PID" '{project_id:$pid}')
fi

curl -fsS -X POST "$BRIDGE/api/tools/project_obs_run" -H 'Content-Type: application/json' -d "$body" | jq .

