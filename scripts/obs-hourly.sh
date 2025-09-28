#!/bin/bash
# Hourly observability runner (for LaunchAgent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/.local/share/devops-mcp/logs"
mkdir -p "$LOG_DIR"

{
  echo "["$(date -u +"%Y-%m-%dT%H:%M:%SZ")"] Observability hourly run start"
  "$SCRIPT_DIR/project-discover.sh" || true
  "$SCRIPT_DIR/obs-run.sh" --schedule hourly || true
  "$SCRIPT_DIR/validate-observability.sh" || true
  "$SCRIPT_DIR/eval-slo.sh" || true
  echo "["$(date -u +"%Y-%m-%dT%H:%M:%SZ")"] Observability hourly run complete"
} >> "$LOG_DIR/obs-hourly.log" 2>&1
