#!/usr/bin/env bash
# sync-chezmoi-templates.sh — Sync SystemConfig templates to chezmoi source
# SystemConfig is the SSOT. See AGENTS.md for the full SSOT policy.
#
# Usage:
#   sync-chezmoi-templates.sh            # Sync all files; warn on reverse divergence
#   sync-chezmoi-templates.sh --check    # Report diffs only; exit 1 if any found
#   sync-chezmoi-templates.sh --force    # Overwrite even if dotfiles file is newer
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT_DIR/06-templates/chezmoi"
DEST="$HOME/.local/share/chezmoi"
TS=$(date +%Y%m%d-%H%M%S)

# Parse flags
CHECK=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    --force) FORCE=1 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || { printf 'Missing: %s\n' "$1" >&2; exit 1; }; }

backup() {
  local f="$1"
  if [ -e "$f" ] || [ -L "$f" ]; then
    mv "$f" "${f}.bak.${TS}"
    printf '[backup] %s -> %s.bak.%s\n' "$f" "$f" "$TS"
  fi
}

copy_rel() {
  local rel="$1"
  local src="$SRC/$rel"
  local dst="$DEST/$rel"
  mkdir -p "$(dirname "$dst")"
  backup "$dst"
  cp "$src" "$dst"
  chmod 0644 "$dst" || true
  printf '[sync] %s\n' "$rel"
}

yellow() {
  if [ -t 1 ]; then printf '\033[33m%s\033[0m\n' "$1"; else printf '%s\n' "$1"; fi
}

printf '[sync] Verifying prerequisites\n'
need chezmoi

printf '[sync] Source: %s\n' "$SRC"
printf '[sync] Destination: %s\n' "$DEST"

DIVERGED=0

# Build file list dynamically from all files in SRC (excludes macOS artifacts and repo docs)
while IFS= read -r full_path; do
  rel="${full_path#"${SRC}/"}"
  dst="$DEST/$rel"

  if [ "$CHECK" -eq 1 ]; then
    # --check mode: report diffs only; no modifications made
    if [ -f "$dst" ]; then
      if ! diff -q "$full_path" "$dst" >/dev/null 2>&1; then
        printf '[diverged] %s\n' "$rel"
        diff -u "$dst" "$full_path" || true
        DIVERGED=1
      fi
    else
      printf '[new] %s (present in SystemConfig, absent from dotfiles)\n' "$rel"
      DIVERGED=1
    fi
  else
    # Sync mode: warn if dotfiles version is newer (possible manual edit)
    if [ -f "$dst" ] && [ "$dst" -nt "$full_path" ]; then
      yellow "[warning] dotfiles/$rel is newer than SystemConfig — possible manual edit"
      diff -u "$full_path" "$dst" || true
      if [ "$FORCE" -eq 0 ]; then
        yellow "[skip] Skipping $rel (use --force to overwrite)"
        continue
      fi
    fi
    copy_rel "$rel"
  fi
done < <(find "$SRC" -type f -not -name '.DS_Store' -not -name 'README.md' | sort)

if [ "$CHECK" -eq 1 ]; then
  if [ "$DIVERGED" -eq 1 ]; then
    printf '[check] Divergence found. Run sync to update dotfiles source (SystemConfig is SSOT).\n'
    exit 1
  fi
  printf '[check] No divergence found.\n'
  exit 0
fi

printf '[sync] Applying with chezmoi\n'
chezmoi apply --source="$DEST" --include=files --verbose \
  ~/.config/fish/conf.d/00-homebrew.fish \
  ~/.config/fish/conf.d/01-mise.fish \
  ~/.config/fish/conf.d/02-direnv.fish \
  ~/.config/fish/conf.d/03-starship.fish \
  ~/.config/fish/conf.d/04-paths.fish \
  ~/.config/fish/conf.d/10-claude.fish \
  ~/.config/direnv/direnv.toml \
  ~/.config/direnv/direnvrc || true

printf '[sync] Done. Open a new shell or run: exec fish\n'
