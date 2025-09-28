#!/bin/bash
# Evaluate SLOs across projects and emit SLOBreach events (NDJSON)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
REGISTRY="$HOME/.local/share/devops-mcp/project-registry.json"
OBS_DIR="$HOME/.local/share/devops-mcp/observations"

if [[ ! -f "$REGISTRY" ]]; then
  echo "Registry not found: $REGISTRY" >&2
  exit 1
fi

node "$ROOT_DIR/scripts/obs-rollup.js" >/dev/null 2>&1 || true

timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

jq -r '.projects[] | .id' "$REGISTRY" | while read -r pid; do
  summary=$(node "$ROOT_DIR/scripts/obs-rollup.js" "$pid" 200 || echo '{}')
  ok=$(echo "$summary" | jq -r '.slo.p95LocalBuildSec_ok // ""')
  slo=$(echo "$summary" | jq -r '.slo.p95LocalBuildSec // ""')
  if [[ "$ok" == "false" ]]; then
    dir="$OBS_DIR/$(echo "$pid" | tr ':/' '__')"
    mkdir -p "$dir"
    cat <<EOF >> "$dir/events.ndjson"
{
  "apiVersion": "obs.v1",
  "type": "SLOBreach",
  "timestamp": "$(timestamp)",
  "project_id": "$pid",
  "slo": "p95LocalBuildSec",
  "threshold": "$slo",
  "details": $(echo "$summary" | jq -c '.')
}
EOF
  fi
done

echo '{"ok": true}'

