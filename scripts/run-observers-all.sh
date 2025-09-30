#!/usr/bin/env bash
set -euo pipefail

BRIDGE=${OBS_BRIDGE_URL:-http://127.0.0.1:7171}

projects=$(curl -fsS "$BRIDGE/api/projects" | jq -r '.projects[].id')
for pid in $projects; do
  echo "Running observers for $pid"
  ./scripts/run-observer.sh "$pid" || true
done

echo "Done."

