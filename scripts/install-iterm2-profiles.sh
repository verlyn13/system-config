#!/usr/bin/env bash
# install-iterm2-profiles.sh — symlink managed profiles into iTerm2 DynamicProfiles
# Idempotent. Safe to re-run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PROFILES_SRC="$REPO_DIR/iterm2/profiles"
DYN_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

if [[ ! -d "$PROFILES_SRC" ]]; then
  echo "ERROR: $PROFILES_SRC not found" >&2
  exit 1
fi

mkdir -p "$DYN_DIR"

# Remove stale managed symlinks that no longer have a source profile.
for target in "$DYN_DIR"/*.json; do
  [[ -e "$target" ]] || continue
  if [[ -L "$target" ]]; then
    resolved="$(readlink "$target")"
    if [[ "$resolved" == "$PROFILES_SRC/"* ]] && [[ ! -e "$resolved" ]]; then
      rm "$target"
    fi
  fi
done

installed=0
for src in "$PROFILES_SRC"/*.json; do
  name=$(basename "$src")
  target="$DYN_DIR/$name"

  # Remove stale symlink or non-symlink file we own
  if [[ -L "$target" ]]; then
    rm "$target"
  elif [[ -f "$target" ]]; then
    echo "WARN: $target exists as regular file, skipping (not a symlink)" >&2
    continue
  fi

  ln -s "$src" "$target"
  echo "  $name → $src"
  installed=$((installed + 1))
done

echo "Installed $installed profile(s) into DynamicProfiles/"

# Verify no GUID conflicts between dynamic and static profiles
if command -v python3 &>/dev/null; then
  python3 - "$DYN_DIR" << 'PYCHECK'
import json, sys
from pathlib import Path

dyn_dir = Path(sys.argv[1])
guids = {}
dupes = []

for f in sorted(dyn_dir.iterdir()):
    if not f.suffix == ".json":
        continue
    resolved = f.resolve() if f.is_symlink() else f
    if not resolved.exists():
        continue
    try:
        with resolved.open() as fh:
            data = json.load(fh)
        for p in data.get("Profiles", []):
            guid = p.get("Guid", "")
            name = p.get("Name", "?")
            if guid in guids:
                dupes.append((guid, name, guids[guid], f.name))
            else:
                guids[guid] = f.name
    except Exception:
        pass

if dupes:
    print("WARNING: Duplicate GUIDs found in DynamicProfiles:")
    for guid, name, first, second in dupes:
        print(f"  {guid} ({name}) in both {first} and {second}")
    sys.exit(1)
else:
    print(f"OK: {len(guids)} unique GUIDs, no conflicts.")
PYCHECK
fi
