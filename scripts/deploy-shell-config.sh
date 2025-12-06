#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TS=$(date +%Y%m%d-%H%M%S)

backup() {
  local f="$1"
  if [ -e "$f" ] || [ -L "$f" ]; then
    mv "$f" "$f.bak.$TS"
    echo "[backup] $f -> $f.bak.$TS"
  fi
}

copy_tmpl() {
  local src="$1"; shift
  local dest="$1"; shift
  mkdir -p "$(dirname "$dest")"
  backup "$dest"
  cp "$src" "$dest"
  chmod 0644 "$dest"
  echo "[install] $dest"
}

echo "[deploy] Applying direnv + fish configuration to HOME"

# 1) direnv configs
mkdir -p "$HOME/.config/direnv"
copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/direnv/direnv.toml.tmpl" "$HOME/.config/direnv/direnv.toml"
copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/direnv/direnvrc.tmpl" "$HOME/.config/direnv/direnvrc"

# 2) fish conf.d snippets
mkdir -p "$HOME/.config/fish/conf.d"
copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/fish/conf.d/00-homebrew.fish.tmpl" "$HOME/.config/fish/conf.d/00-homebrew.fish"
copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/fish/conf.d/01-mise.fish.tmpl" "$HOME/.config/fish/conf.d/01-mise.fish"
copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/fish/conf.d/02-direnv.fish.tmpl" "$HOME/.config/fish/conf.d/02-direnv.fish"
copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/fish/conf.d/10-claude.fish.tmpl" "$HOME/.config/fish/conf.d/10-claude.fish"
copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/fish/conf.d/03-starship.fish.tmpl" "$HOME/.config/fish/conf.d/03-starship.fish"
copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/fish/conf.d/04-paths.fish.tmpl" "$HOME/.config/fish/conf.d/04-paths.fish"

# 2b) starship config (optional)
if command -v starship >/dev/null 2>&1; then
  mkdir -p "$HOME/.config"
  # Source of truth is this repo; back up then install
  copy_tmpl "$ROOT_DIR/06-templates/chezmoi/dot_config/starship.toml.tmpl" "$HOME/.config/starship.toml"
fi

# 3) vendor hook clean-up (stale ~/.local/bin/direnv reference)
VENDOR_HOOK="$HOME/.local/share/fish/vendor_conf.d/direnv.fish"
if [ -f "$VENDOR_HOOK" ]; then
  backup "$VENDOR_HOOK"
fi

# 3b) remove stale claude shim if present (replaced by unified 10-claude)
CLAUDE_STALE="$HOME/.config/fish/conf.d/11-claude.fish"
if [ -f "$CLAUDE_STALE" ]; then
  backup "$CLAUDE_STALE"
fi

echo "[deploy] Done. Open a new Fish session or run: exec fish"
