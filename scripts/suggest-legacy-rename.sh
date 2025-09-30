#!/usr/bin/env bash
set -euo pipefail

ROOT=${1:-$HOME/Development/personal}

if [[ -d "$ROOT/system-setup" && -d "$ROOT/system-setup-update" ]]; then
  echo "Detected legacy repo: $ROOT/system-setup"
  echo "Authoritative repo:    $ROOT/system-setup-update"
  echo
  echo "Suggested (dry-run):"
  echo "  mv \"$ROOT/system-setup\" \"$ROOT/system-setup-ARCHIVED-$(date +%Y%m%d)\""
  echo
  echo "This prevents accidental wiring to the legacy repo."
else
  echo "No legacy/authoritative pair detected under $ROOT"
fi

