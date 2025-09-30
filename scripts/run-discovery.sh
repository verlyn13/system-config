#!/usr/bin/env bash
set -euo pipefail

BRIDGE_URL=${OBS_BRIDGE_URL:-http://127.0.0.1:7171}

echo "Triggering discovery at $BRIDGE_URL/api/discover..."
curl -fsS "$BRIDGE_URL/api/discover" | jq .
echo "Done."

