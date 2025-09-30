#!/usr/bin/env bash
set -euo pipefail

DS_URL=${DS_BASE_URL:-http://127.0.0.1:7777}
OUT_DIR=${1:-examples/dashboard/generated/ds-client}

mkdir -p "$OUT_DIR"

if command -v npx >/dev/null 2>&1; then
  npx @openapitools/openapi-generator-cli generate \
    -g typescript-axios \
    -o "$OUT_DIR" \
    -i "$DS_URL/openapi.yaml" \
    --skip-validate-spec
  echo "DS client generated in $OUT_DIR"
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  docker run --rm -v "$(pwd):/local" openapitools/openapi-generator-cli generate \
    -g typescript-axios \
    -o "/local/$OUT_DIR" \
    -i "$DS_URL/openapi.yaml" \
    --skip-validate-spec
  echo "DS client generated in $OUT_DIR"
  exit 0
fi

echo "Neither npx nor docker is available to generate DS client."
exit 1

