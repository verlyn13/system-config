#!/usr/bin/env bash
set -euo pipefail

REGISTRY="$HOME/.local/share/devops-mcp/project-registry.json"
if [ ! -f "$REGISTRY" ]; then
  echo "Registry not found: $REGISTRY" >&2
  exit 0
fi

STANDARD_ENVRC='#! direnv
# Load mise integration and activate tools (no external calls)
use_mise() {
  direnv_load mise direnv exec
}
use mise

PATH_add bin
PATH_add node_modules/.bin

dotenv_if_exists .env.local
dotenv_if_exists .env
'

changed=0
trusted=0
total=0

paths=$(jq -r '.projects[]?.path // empty' < "$REGISTRY")
while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  [ -d "$repo" ] || continue
  total=$((total+1))

  # Align .envrc
  if [ -f "$repo/.envrc" ]; then
    if ! grep -q 'direnv_load mise direnv exec' "$repo/.envrc" || grep -q '\$(mise direnv)' "$repo/.envrc"; then
      cp "$repo/.envrc" "$repo/.envrc.bak" || true
      printf "%s\n" "$STANDARD_ENVRC" > "$repo/.envrc"
      changed=$((changed+1))
    fi
  else
    printf "%s\n" "$STANDARD_ENVRC" > "$repo/.envrc"
    changed=$((changed+1))
  fi

  # Trust .mise.toml if present
  if [ -f "$repo/.mise.toml" ]; then
    (cd "$repo" && mise trust .mise.toml >/dev/null 2>&1 || true)
    trusted=$((trusted+1))
  fi
done <<< "$paths"

echo "Aligned .envrc in $changed repo(s); trusted mise in $trusted repo(s); scanned $total repo(s)."

