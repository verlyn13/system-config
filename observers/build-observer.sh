#!/bin/bash
# Build Observer - Runs project build task in a safe, timed way

set -euo pipefail

readonly PROJECT_PATH="${1:?Project path required}"
readonly PROJECT_ID="${2:?Project ID required}"
readonly RUN_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
readonly TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
readonly TIMEOUT=60

validate_path() {
  local path="$1"
  local allowed_roots=(
    "$HOME/Development/personal"
    "$HOME/Development/work"
    "$HOME/Development/business"
    "$HOME/workspace/projects"
  )
  local realpath=$(realpath "$path")
  for root in "${allowed_roots[@]}"; do
    if [[ "$realpath" == "$root"* ]]; then
      return 0
    fi
  done
  echo "Error: Path not in allowed roots: $path" >&2
  exit 1
}

main() {
  validate_path "$PROJECT_PATH"
  local start_time=$(date +%s%3N)

  local summary="build not configured"
  local status="warn"
  local ok=0

  if [[ -f "$PROJECT_PATH/mise.toml" ]] || [[ -f "$PROJECT_PATH/.mise.toml" ]]; then
    # Try mise task build, tolerate non-zero (we report fail)
    if timeout "$TIMEOUT" bash -lc "cd '$PROJECT_PATH' && mise run build" >/dev/null 2>&1; then
      ok=1
      summary="build succeeded"
      status="ok"
    else
      ok=0
      summary="build failed"
      status="fail"
    fi
  fi

  local end_time=$(date +%s%3N)
  local latency=$((end_time - start_time))

  cat <<EOF
{
  "apiVersion": "obs.v1",
  "run_id": "$RUN_ID",
  "timestamp": "$TIMESTAMP",
  "project_id": "$PROJECT_ID",
  "observer": "build",
  "summary": "$summary",
  "metrics": {"build_ok": $ok, "latency_ms": $latency},
  "status": "$status"
}
EOF
}

main

