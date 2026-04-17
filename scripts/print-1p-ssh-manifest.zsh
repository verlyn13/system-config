#!/usr/bin/env zsh

set -euo pipefail

MANIFEST_PATH="${1:-$HOME/Documents/1p-ssh-import-manifest.tsv}"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  printf '[ERROR] Manifest not found: %s\n' "$MANIFEST_PATH" >&2
  exit 1
fi

if ! command -v ssh-keygen >/dev/null 2>&1; then
  printf '[ERROR] Required command not found: ssh-keygen\n' >&2
  exit 1
fi

while IFS=$'\t' read -r src title tags note || [[ -n "${src:-}" ]]; do
  [[ -n "${src:-}" ]] || continue

  printf '\n== %s ==\n' "$title"
  printf 'source      %s\n' "$src"
  printf 'tags        %s\n' "$tags"
  printf 'note        %s\n' "$note"

  if [[ -f "$src" ]]; then
    fingerprint="$(ssh-keygen -lf "$src" 2>/dev/null)" || {
      printf 'fingerprint [unable to read key]\n'
      continue
    }
    printf 'fingerprint %s\n' "$fingerprint"
  else
    printf 'fingerprint [missing file]\n'
  fi
done < "$MANIFEST_PATH"
