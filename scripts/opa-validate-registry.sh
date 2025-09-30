#!/usr/bin/env bash
set -euo pipefail

REG_JSON=$(mktemp)
POLICY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/04-policies/opa"
REG_YAML="${1:-$HOME/.config/system/registry.yaml}"

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required" >&2; exit 1
fi
if ! command -v opa >/dev/null 2>&1 && ! command -v conftest >/dev/null 2>&1; then
  echo "opa or conftest is required" >&2; exit 1
fi

yq -o=json "$REG_YAML" > "$REG_JSON"

if command -v conftest >/dev/null 2>&1; then
  conftest test --policy "$POLICY_DIR" "$REG_YAML"
else
  opa eval -f pretty -i "$REG_JSON" -d "$POLICY_DIR" 'data.system.integration'
fi

rm -f "$REG_JSON"
echo "Registry policy validation complete"

