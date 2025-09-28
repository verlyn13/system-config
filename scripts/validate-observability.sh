#!/bin/bash
# Validate Observability Platform compliance and data
# - Ensures single-source-of-truth for implementation status
# - Validates latest observation payloads against schema (basic if ajv missing)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
STATUS_CANON_PATH="$ROOT_DIR/07-reports/status/implementation-status.md"
STATUS_ROOT_PATH="$ROOT_DIR/implementation-status.md"
OVERALL_STATUS_PATH="$ROOT_DIR/MASTER-STATUS.md"
SCHEMA_OBS="$ROOT_DIR/schema/observer.output.schema.json"
OBS_DIR="$HOME/.local/share/devops-mcp/observations"
DS_CAPS_URL="http://127.0.0.1:7777/v1/capabilities"

violations=()
checked=0

# 0) Repository role and naming
if command -v git >/dev/null 2>&1; then
  REPO_ROOT=$(git -C "$ROOT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$ROOT_DIR")
  REPO_NAME=$(basename "$REPO_ROOT")
  if [[ "$REPO_NAME" != "system-setup-update" ]]; then
    violations+=("Repo name '$REPO_NAME' is not canonical. Expected 'system-setup-update' for authoritative system repo.")
  fi
  # Heuristic: warn if sibling legacy repo exists
  PARENT_DIR=$(dirname "$REPO_ROOT")
  if [[ -d "$PARENT_DIR/system-setup" ]]; then
    violations+=("Legacy repo detected at: $PARENT_DIR/system-setup. Treat it as read-only/archive to avoid confusion.")
  fi
fi

# 1) Single source of truth for implementation status
if [[ -f "$STATUS_ROOT_PATH" ]]; then
  violations+=("Duplicate implementation-status at repo root: implementation-status.md")
fi
if [[ ! -f "$STATUS_CANON_PATH" ]]; then
  violations+=("Missing canonical implementation-status: 07-reports/status/implementation-status.md")
fi
if [[ ! -f "$OVERALL_STATUS_PATH" ]]; then
  violations+=("Missing overall status: MASTER-STATUS.md")
fi

# 2) Validate latest observation entries
obs_files_found=0
obs_files_valid=0
obs_files_invalid=0

if [[ -d "$OBS_DIR" ]]; then
  while IFS= read -r -d '' ndjson; do
    obs_files_found=$((obs_files_found + 1))
    last_line="$(tail -n 1 "$ndjson" || echo '')"
    if [[ -z "$last_line" ]]; then
      violations+=("Empty observation file: $ndjson")
      obs_files_invalid=$((obs_files_invalid + 1))
      continue
    fi

    if command -v ajv >/dev/null 2>&1; then
      # Convert single JSON to tmp and validate with schema
      if echo "$last_line" | ajv validate -s "$SCHEMA_OBS" --data-file=/dev/stdin --strict=false >/dev/null 2>&1; then
        obs_files_valid=$((obs_files_valid + 1))
      else
        violations+=("Schema validation failed for: $ndjson (last entry)")
        obs_files_invalid=$((obs_files_invalid + 1))
      fi
    else
      # Basic jq checks for required fields
      if echo "$last_line" | jq -e '.apiVersion=="obs.v1" and (.run_id|type=="string") and (.timestamp|type=="string") and (.project_id|type=="string") and (.observer|type=="string") and (.summary|type=="string") and (.metrics|type=="object") and (.status|type=="string")' >/dev/null 2>&1; then
        obs_files_valid=$((obs_files_valid + 1))
      else
        violations+=("Basic field validation failed for: $ndjson (last entry)")
        obs_files_invalid=$((obs_files_invalid + 1))
      fi
    fi
  done < <(find "$OBS_DIR" -type f -name 'observations.ndjson' -print0)
fi

checked=$((obs_files_found))

# 2b) DS CLI presence and (optional) discovery reachability
if ! command -v ds >/dev/null 2>&1; then
  violations+=("DS CLI not found in PATH (ds). Install ds-go for agent workflows.")
else
  # Optional: if curl present, attempt lightweight discovery
  if command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 1 "$DS_CAPS_URL" >/dev/null 2>&1 || violations+=("DS server not reachable at $DS_CAPS_URL. Start with: ds serve --addr 127.0.0.1:7777")
  fi
fi

# 3) Output summary JSON
summary=$(jq -n \
  --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg canon "$STATUS_CANON_PATH" \
  --arg overall "$OVERALL_STATUS_PATH" \
  --arg obsdir "$OBS_DIR" \
  --argjson found $obs_files_found \
  --argjson valid $obs_files_valid \
  --argjson invalid $obs_files_invalid \
  --argjson vcount ${#violations[@]} \
  '{
     timestamp: $now,
     implementation_status: $canon,
     overall_status: $overall,
     observations_dir: $obsdir,
     observations: { found: $found, valid: $valid, invalid: $invalid },
     violations: []
   }')

for v in "${violations[@]:-}"; do
  summary=$(jq --arg v "$v" '.violations += [$v]' <<<"$summary")
done

echo "$summary" | jq .

# Exit non-zero if any violations
if [[ ${#violations[@]} -gt 0 ]]; then
  exit 1
fi

exit 0
