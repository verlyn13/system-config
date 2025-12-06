#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT_DIR/06-templates/chezmoi"
DEST="$HOME/.local/share/chezmoi"
TS=$(date +%Y%m%d-%H%M%S)

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }

backup() {
  local f="$1"
  if [ -e "$f" ] || [ -L "$f" ]; then
    mv "$f" "$f.bak.$TS"
    echo "[backup] $f -> $f.bak.$TS"
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
  echo "[sync] $rel"
}

echo "[sync] Verifying prerequisites"
need chezmoi

echo "[sync] Copying templates into chezmoi source: $DEST"

# Fish conf.d templates
# Remove conflicting non-template files if present
for f in dot_config/fish/conf.d/00-homebrew.fish dot_config/fish/conf.d/01-mise.fish dot_config/fish/conf.d/02-direnv.fish dot_config/fish/conf.d/04-paths.fish; do
  if [ -f "$DEST/$f" ]; then backup "$DEST/$f"; fi
done
copy_rel dot_config/fish/conf.d/00-homebrew.fish.tmpl
copy_rel dot_config/fish/conf.d/01-mise.fish.tmpl
copy_rel dot_config/fish/conf.d/02-direnv.fish.tmpl
copy_rel dot_config/fish/conf.d/10-claude.fish.tmpl
copy_rel dot_config/fish/conf.d/03-starship.fish.tmpl
copy_rel dot_config/fish/conf.d/04-paths.fish.tmpl

# direnv configs
# Remove conflicting non-template files if present
for f in dot_config/direnv/direnv.toml dot_config/direnv/direnvrc; do
  if [ -f "$DEST/$f" ]; then backup "$DEST/$f"; fi
done
copy_rel dot_config/direnv/direnv.toml.tmpl
copy_rel dot_config/direnv/direnvrc.tmpl

# starship config
copy_rel dot_config/starship.toml.tmpl

# run-once installer scripts
copy_rel run_once_10-install-claude.sh.tmpl

# Optional: zsh/bash templates (kept in sync)
copy_rel dot_bashrc.tmpl
copy_rel dot_zshrc.tmpl

echo "[sync] Applying with chezmoi"
chezmoi apply --source="$DEST" --include=files --verbose \
  ~/.config/fish/conf.d/00-homebrew.fish \
  ~/.config/fish/conf.d/01-mise.fish \
  ~/.config/fish/conf.d/02-direnv.fish \
  ~/.config/fish/conf.d/03-starship.fish \
  ~/.config/fish/conf.d/04-paths.fish \
  ~/.config/direnv/direnv.toml \
  ~/.config/direnv/direnvrc || true

echo "[sync] Done. Open a new shell or run: exec fish"
