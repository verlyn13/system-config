#!/usr/bin/env bash
set -euo pipefail

# Generate a TypeScript Axios client from the bridge OpenAPI
# Requires network and node/npm or docker for openapitools

BRIDGE_URL=${OBS_BRIDGE_URL:-http://127.0.0.1:7171}
OUT_DIR=${1:-examples/dashboard/generated/bridge-client}

# Prefer bundled spec if available (build/openapi.bundled.yaml) or accept explicit input as $2
INPUT=${2:-}
if [[ -z "${INPUT}" && -f build/openapi.bundled.yaml ]]; then
  INPUT="build/openapi.bundled.yaml"
fi
if [[ -z "${INPUT}" ]]; then
  INPUT="$BRIDGE_URL/openapi.yaml"
fi

mkdir -p "$OUT_DIR"

if command -v npx >/dev/null 2>&1; then
  npx @openapitools/openapi-generator-cli generate \
    -g typescript-axios \
    -o "$OUT_DIR" \
    -i "$INPUT" \
    --skip-validate-spec
  echo "Client generated in $OUT_DIR"
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  docker run --rm -v "$(pwd):/local" openapitools/openapi-generator-cli generate \
    -g typescript-axios \
    -o "/local/$OUT_DIR" \
    -i "$INPUT" \
    --skip-validate-spec
  echo "Client generated in $OUT_DIR"
  exit 0
fi

echo "Neither npx nor docker is available. Please install one to generate the client."
exit 1
