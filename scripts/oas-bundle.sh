#!/usr/bin/env bash
set -euo pipefail

SRC=${1:-openapi.yaml}
OUT=${2:-build/openapi.bundled.yaml}

mkdir -p "$(dirname "$OUT")"

if ! command -v npx >/dev/null 2>&1 && ! command -v redocly >/dev/null 2>&1; then
  echo "redocly CLI not found; install with: npm i -g @redocly/cli" >&2
  exit 1
fi

if command -v redocly >/dev/null 2>&1; then
  redocly bundle "$SRC" --dereferenced -o "$OUT"
else
  npx @redocly/cli bundle "$SRC" --dereferenced -o "$OUT"
fi

echo "Bundled spec written to $OUT"

