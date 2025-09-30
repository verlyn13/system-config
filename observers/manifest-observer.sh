#!/bin/bash
# Manifest Observer - Reports presence and key fields from project.manifest.yaml

set -euo pipefail

readonly PROJECT_PATH="${1:?Project path required}"
readonly PROJECT_ID="${2:?Project ID required}"
readonly RUN_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
readonly TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

main() {
  local manifest="$PROJECT_PATH/project.manifest.yaml"
  local present=0
  local org="" tier="" kind="" lang="" name=""
  if [[ -f "$manifest" ]] && command -v yq >/dev/null 2>&1; then
    present=1
    org=$(yq -r '.project.org // ""' "$manifest")
    tier=$(yq -r '.project.tier // ""' "$manifest")
    kind=$(yq -r '.project.kind // ""' "$manifest")
    lang=$(yq -r '.runtime.language // ""' "$manifest")
    name=$(yq -r '.project.name // ""' "$manifest")
  fi
  local summary
  if [[ $present -eq 1 ]]; then
    summary="manifest present: $name ($org/$tier/$kind, $lang)"
  else
    summary="manifest missing"
  fi
  jq -nc --arg run "$RUN_ID" --arg ts "$TIMESTAMP" --arg pid "$PROJECT_ID" --arg sum "$summary" \
    --arg org "$org" --arg tier "$tier" --arg kind "$kind" --arg lang "$lang" --arg name "$name" \
    '{apiVersion:"obs.v1",run_id:$run,timestamp:$ts,project_id:$pid,observer:"manifest",summary:$sum,metrics:{present:($name != ""),org:$org,tier:$tier,kind:$kind,language:$lang},status:(if $name == "" then "warn" else "ok" end)}'
}

main

