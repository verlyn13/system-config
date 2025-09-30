#!/usr/bin/env bash
set -euo pipefail

export BRIDGE_AUTO_DISCOVER=${BRIDGE_AUTO_DISCOVER:-1}
export BRIDGE_STRICT=${BRIDGE_STRICT:-1}
export BRIDGE_CORS=${BRIDGE_CORS:-1}

echo "Starting bridge (PORT=${PORT:-7171}, STRICT=$BRIDGE_STRICT, CORS=$BRIDGE_CORS)"
node scripts/http-bridge.js

