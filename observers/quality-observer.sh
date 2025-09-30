#!/bin/bash
# Quality Observer - Runs quick lint checks if available

set -euo pipefail

readonly PROJECT_PATH="${1:?Project path required}"
readonly PROJECT_ID="${2:?Project ID required}"
readonly RUN_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
readonly TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
readonly TIMEOUT=45

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

  local status="warn"
  local summary="no linter configured"
  local issues=0

  if [[ -f "$PROJECT_PATH/package.json" ]] && command -v npm >/dev/null 2>&1; then
    if jq -e '.scripts.lint' "$PROJECT_PATH/package.json" >/dev/null 2>&1; then
      if timeout "$TIMEOUT" bash -lc "cd '$PROJECT_PATH' && npm run -s lint" >/dev/null 2>&1; then
        status="ok"; summary="lint ok"; issues=0
      else
        status="fail"; summary="lint failed"; issues=1
      fi
    fi
  elif compgen -G "$PROJECT_PATH/**/*.py" >/dev/null 2>&1 && command -v ruff >/dev/null 2>&1; then
    if timeout "$TIMEOUT" bash -lc "cd '$PROJECT_PATH' && ruff check ." >/dev/null 2>&1; then
      status="ok"; summary="ruff ok"; issues=0
    else
      status="fail"; summary="ruff issues"; issues=1
    fi
  fi

  local end_time=$(date +%s%3N)
  local latency=$((end_time - start_time))
  jq -nc --arg run "$RUN_ID" --arg ts "$TIMESTAMP" --arg pid "$PROJECT_ID" --arg sum "$summary" --arg st "$status" --argjson issues "$issues" --argjson lat "$latency" \
    '{apiVersion:"obs.v1",run_id:$run,timestamp:$ts,project_id:$pid,observer:"quality",summary:$sum,metrics:{issues:$issues,latency_ms:$lat},status:$st}'
}

main
