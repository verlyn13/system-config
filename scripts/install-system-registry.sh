#!/usr/bin/env bash
set -euo pipefail

CONF_DIR="$HOME/.config/system"
REG_FILE="$CONF_DIR/registry.yaml"
SRC_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/docs/system-registry.example.yaml"

mkdir -p "$CONF_DIR"
cp "$SRC_FILE" "$REG_FILE"
echo "Installed system registry to $REG_FILE"

