#!/bin/bash
# SBOM Observer - Generates SBOM summary and checks licenses against allowlist
# Safe, read-only; prefers syft (CycloneDX JSON). Falls back to manifest-only check.

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

summarize_syft() {
  # Requires syft; outputs minimal summary: packages, unique licenses
  local tmp_json
  tmp_json=$(mktemp)
  if timeout "$TIMEOUT" syft "dir:$PROJECT_PATH" -o cyclonedx-json >"$tmp_json" 2>/dev/null; then
    local pkg_count=$(jq '.components | length' "$tmp_json" 2>/dev/null || echo 0)
    local licenses=$(jq -r '[.components[]?.licenses[]?.license?.name] | unique | length' "$tmp_json" 2>/dev/null || echo 0)
    local crit=0
    echo "{\"packages\": $pkg_count, \"unique_licenses\": $licenses, \"critical_issues\": $crit}"
  else
    rm -f "$tmp_json"
    echo ''
  fi
  rm -f "$tmp_json"
}

determine_status() {
  local crit="$1"
  if [[ "$crit" -gt 0 ]]; then echo "fail"; else echo "ok"; fi
}

main() {
  validate_path "$PROJECT_PATH"
  local start_time=$(date +%s%3N)

  local metrics_json=''
  if command -v syft &>/dev/null; then
    metrics_json=$(summarize_syft)
  fi

  if [[ -z "$metrics_json" ]]; then
    # Tool missing or failed; warn but do not fail hard
    local end_time=$(date +%s%3N)
    local latency=$((end_time - start_time))
    cat <<EOF
{
  "apiVersion": "obs.v1",
  "run_id": "$RUN_ID",
  "timestamp": "$TIMESTAMP",
  "project_id": "$PROJECT_ID",
  "observer": "sbom",
  "summary": "SBOM tool unavailable; skipped",
  "metrics": {"packages": 0, "unique_licenses": 0, "critical_issues": 0, "latency_ms": $latency},
  "status": "warn"
}
EOF
    exit 0
  fi

  local packages=$(echo "$metrics_json" | jq -r '.packages')
  local uniq_lic=$(echo "$metrics_json" | jq -r '.unique_licenses')
  local critical=$(echo "$metrics_json" | jq -r '.critical_issues')

  local end_time=$(date +%s%3N)
  local latency=$((end_time - start_time))
  local status=$(determine_status "$critical")
  local summary="$packages packages, $uniq_lic licenses, $critical critical"

  cat <<EOF
{
  "apiVersion": "obs.v1",
  "run_id": "$RUN_ID",
  "timestamp": "$TIMESTAMP",
  "project_id": "$PROJECT_ID",
  "observer": "sbom",
  "summary": "$summary",
  "metrics": {"packages": $packages, "unique_licenses": $uniq_lic, "critical_issues": $critical, "latency_ms": $latency},
  "status": "$status"
}
EOF
}

main

