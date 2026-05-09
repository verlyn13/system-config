#!/usr/bin/env bash
# install-iterm2-profiles.sh — install managed iTerm2 dynamic profiles.
#
# Fail-closed: validates ALL managed sources before mutating DynamicProfiles/.
# On any validation failure the existing on-disk symlinks are left intact.
#
# Optional Phase: if iterm2/profiles/00-dev.json exists, set its GUID as iTerm2's
# Default Bookmark Guid so new windows open with the managed Dev profile.
#
# Idempotent. Safe to re-run.

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PROFILES_SRC="$REPO_DIR/iterm2/profiles"
COLOR_PRESETS_SRC="$REPO_DIR/iterm2/color-presets"
DYN_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
DEV_PROFILE="$PROFILES_SRC/00-dev.json"

die()  { printf 'ERROR: %s\n' "$*" >&2; exit 2; }
warn() { printf 'WARN:  %s\n' "$*" >&2; }
log()  { printf '%s\n' "$*"; }

[[ -d "$PROFILES_SRC" ]] || die "$PROFILES_SRC not found"
mkdir -p "$DYN_DIR"

command -v jq     >/dev/null 2>&1 || die "jq required for validation"
command -v plutil >/dev/null 2>&1 || die "plutil required for validation"

sources=("$PROFILES_SRC"/*.json)
color_presets=()
if [[ -d "$COLOR_PRESETS_SRC" ]]; then
  color_presets=("$COLOR_PRESETS_SRC"/*.itermcolors)
fi

# --- Static iTerm2 profile GUIDs (read from main plist) ---------------------

static_guids() {
  if [[ ! -f "$ITERM_PLIST" ]]; then
    return 0
  fi
  plutil -extract "New Bookmarks" json -o - "$ITERM_PLIST" 2>/dev/null \
    | jq -r '.[]? | select(.["Is Dynamic Profile"] != true) | .Guid // empty' 2>/dev/null || true
}

# --- Phase 1: validate ALL managed sources ----------------------------------

validate_sources() {
  if [[ ${#sources[@]} -eq 0 ]]; then
    log "No managed profiles in $PROFILES_SRC; skipping validation."
    return 0
  fi

  log "Validating ${#sources[@]} managed profile source(s)..."

  local src
  for src in "${sources[@]}"; do
    jq empty "$src" >/dev/null 2>&1                    || die "invalid JSON: $src"
    # plutil -lint rejects the JSON dialect that iTerm2 actually accepts; use
    # convert-to-xml (parse-only via /dev/null sink) as the syntax gate instead.
    plutil -convert xml1 -o /dev/null "$src" >/dev/null || die "invalid property list: $src"
  done

  # Collect <file>\t<guid>\t<parent_guid> for every profile in every source.
  local managed_records
  managed_records="$(
    for src in "${sources[@]}"; do
      jq -r --arg f "$(basename "$src")" \
        '.Profiles[] | "\($f)\t\(.Guid)\t\(.["Dynamic Profile Parent GUID"] // "")"' \
        "$src"
    done
  )"

  # 1a. duplicate managed GUIDs
  local dup_guids
  dup_guids="$(printf '%s\n' "$managed_records" | awk -F'\t' 'NF>=2 && $2!="" {print $2}' | sort | uniq -d)"
  [[ -z "$dup_guids" ]] || die "duplicate managed GUID(s):"$'\n'"$dup_guids"

  # 1b. conflict with static iTerm2 profiles
  local static_list
  static_list="$(static_guids)"
  if [[ -n "$static_list" ]]; then
    local mguid
    while IFS= read -r mguid; do
      [[ -z "$mguid" ]] && continue
      if printf '%s\n' "$static_list" | grep -Fxq "$mguid"; then
        die "managed GUID $mguid conflicts with a static iTerm2 profile"
      fi
    done < <(printf '%s\n' "$managed_records" | awk -F'\t' '{print $2}')
  fi

  # 1c. parent ordering — child's Dynamic Profile Parent GUID must reference
  #     either a static profile or a managed profile in an earlier-named file.
  local child_file parent_guid resolved
  while IFS=$'\t' read -r child_file _ parent_guid; do
    [[ -z "$parent_guid" ]] && continue
    resolved=0
    while IFS=$'\t' read -r mfile mguid _; do
      if [[ "$mguid" == "$parent_guid" ]]; then
        if [[ "$mfile" < "$child_file" ]]; then
          resolved=1
        else
          die "child $child_file references parent $parent_guid in $mfile (must be earlier-named than child)"
        fi
        break
      fi
    done < <(printf '%s\n' "$managed_records")
    if [[ "$resolved" -eq 0 ]]; then
      if [[ -z "$static_list" ]] || ! printf '%s\n' "$static_list" | grep -Fxq "$parent_guid"; then
        die "child $child_file references parent GUID $parent_guid that is not loaded (no managed or static match)"
      fi
    fi
  done < <(printf '%s\n' "$managed_records")

  log "Validation passed (${#sources[@]} file(s), all checks)."
}

# --- Phase 1b: validate managed Color Presets -------------------------------
# Phase B owns the preset artifacts, but does not import them yet. Direct plist
# writes wait until a known-good Custom Color Presets schema is captured.

validate_color_presets() {
  if [[ ${#color_presets[@]} -eq 0 ]]; then
    log "No managed color presets in $COLOR_PRESETS_SRC; skipping validation."
    return 0
  fi

  log "Validating ${#color_presets[@]} managed color preset(s)..."

  local preset
  for preset in "${color_presets[@]}"; do
    plutil -convert xml1 -o /dev/null "$preset" >/dev/null || die "invalid color preset plist: $preset"
    plutil -convert json -o - "$preset" \
      | jq -e 'type == "object" and (has("Profiles") | not)' >/dev/null \
      || die "invalid color preset shape: $preset"
  done

  log "Color preset validation passed (${#color_presets[@]} file(s))."
}

# --- Phase 2: install symlinks ---------------------------------------------

install_symlinks() {
  # Remove stale managed symlinks (target gone).
  local target resolved
  for target in "$DYN_DIR"/*.json; do
    [[ -e "$target" || -L "$target" ]] || continue
    if [[ -L "$target" ]]; then
      resolved="$(readlink "$target")"
      if [[ "$resolved" == "$PROFILES_SRC/"* ]] && [[ ! -e "$resolved" ]]; then
        log "  Removing stale managed symlink: $(basename "$target")"
        rm "$target"
      fi
    fi
  done

  local installed=0 src name
  for src in "${sources[@]}"; do
    name="$(basename "$src")"
    target="$DYN_DIR/$name"
    if [[ -L "$target" ]]; then
      rm "$target"
    elif [[ -f "$target" ]]; then
      warn "$target exists as regular file, skipping (not a symlink)"
      continue
    fi
    ln -s "$src" "$target"
    log "  $name → $src"
    installed=$((installed + 1))
  done

  log "Installed $installed profile(s) into DynamicProfiles/"
}

# --- Phase 3: post-install GUID-uniqueness sanity check ---------------------

guid_sanity_check() {
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$DYN_DIR" << 'PYCHECK'
import json, sys
from pathlib import Path

dyn_dir = Path(sys.argv[1])
guids = {}
dupes = []

for f in sorted(dyn_dir.iterdir()):
    if f.suffix != ".json":
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
    print(f"OK: {len(guids)} unique GUIDs across DynamicProfiles, no conflicts.")
PYCHECK
}

# --- Phase 4: Default Bookmark setter --------------------------------------
# Only runs if iterm2/profiles/00-dev.json is present (the managed Dev profile).
# Existing static default profile (e.g. seeded by iTerm2) is left in place;
# we just point Default Bookmark Guid at our managed profile.

set_default_bookmark() {
  [[ -f "$DEV_PROFILE" ]] || return 0

  local dev_guid current readback
  dev_guid="$(jq -r '.Profiles[0].Guid // empty' "$DEV_PROFILE" 2>/dev/null)"
  [[ -n "$dev_guid" && "$dev_guid" != "null" ]] || return 0

  current="$(defaults read com.googlecode.iterm2 "Default Bookmark Guid" 2>/dev/null || true)"
  if [[ "$current" == "$dev_guid" ]]; then
    log "Default Bookmark Guid already $dev_guid (no change)."
    return 0
  fi

  defaults write com.googlecode.iterm2 "Default Bookmark Guid" "$dev_guid"
  killall cfprefsd 2>/dev/null || true
  # Brief settle; cfprefsd respawns immediately.
  sleep 0.3

  readback="$(defaults read com.googlecode.iterm2 "Default Bookmark Guid" 2>/dev/null || true)"
  if [[ "$readback" == "$dev_guid" ]]; then
    log "Default Bookmark Guid: $current → $dev_guid"
  else
    warn "Default Bookmark write did not land (read back '$readback'); may need iTerm2 restart"
  fi

  if pgrep -x iTerm2 >/dev/null 2>&1; then
    log "NOTE: iTerm2 is running; new windows will pick up the new default."
  fi
}

# --- Main flow --------------------------------------------------------------

validate_sources
validate_color_presets
install_symlinks
guid_sanity_check
set_default_bookmark
