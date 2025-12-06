#!/usr/bin/env bash
set -euo pipefail

echo "[repair] Starting shell environment repair (direnv + fish)"

BREW_DIRENV="/opt/homebrew/bin/direnv"
ALT_BREW_DIRENV="/usr/local/bin/direnv"
LOCAL_DIRENV="$HOME/.local/bin/direnv"

step() { printf "\n==> %s\n" "$*"; }

step "Check current direnv resolution"
command -v direnv || true

if [ -x "$LOCAL_DIRENV" ]; then
  step "Backup stray ~/.local/bin/direnv"
  mv "$LOCAL_DIRENV" "$LOCAL_DIRENV.bak.$(date +%s)" || true
fi

step "Reinstall direnv via Homebrew"
if command -v brew >/dev/null 2>&1; then
  brew reinstall direnv
else
  echo "Homebrew not found; please install direnv via your package manager." >&2
fi

step "Purge hard-coded direnv path from Fish configs (if present)"
FISH_DIR="$HOME/.config/fish"
if [ -d "$FISH_DIR" ]; then
  # Remove functions or conf.d snippets that hardcode ~/.local/bin/direnv
  grep -RIl "$LOCAL_DIRENV" "$FISH_DIR" 2>/dev/null | while read -r f; do
    echo "Removing stale file: $f"
    rm -f "$f" || true
  done
fi

step "Verify command resolution after fix"
hash -r || true
command -v direnv || true
direnv --version || true

step "Ensure direnv uses Homebrew bash (avoid /bin/bash crash)"
mkdir -p "$HOME/.config/direnv"
CONF="$HOME/.config/direnv/direnv.toml"
if ! grep -q 'bash_path' "$CONF" 2>/dev/null; then
  echo 'bash_path = "/opt/homebrew/bin/bash"' >> "$CONF"
  echo "Configured bash_path in $CONF"
fi

step "Replace unsafe direnvrc if it overrides stdlib functions"
SAFE_RC_SRC="$(cd "$(dirname "$0")/.." && pwd)/06-templates/chezmoi/dot_config/direnv/direnvrc.tmpl"
RC_PATH="$HOME/.config/direnv/direnvrc"
if [ -e "$RC_PATH" ]; then
  if rg -q '^\s*watch_file\s*\(\)' "$RC_PATH" 2>/dev/null; then
    echo "Backing up and replacing unsafe direnvrc: $RC_PATH"
    mv "$RC_PATH" "$RC_PATH.bak.$(date +%s)" || true
    cp "$SAFE_RC_SRC" "$RC_PATH"
  fi
else
  cp "$SAFE_RC_SRC" "$RC_PATH"
fi

cat << 'EONOTE'

[repair] Next steps:
- Open a new iTerm/Fish session (or run: exec fish) to pick up PATH ordering changes.
- Ensure Fish conf.d contains only a dynamic direnv hook:
    direnv hook fish | source
- Confirm direnv uses Homebrew bash:
    grep bash_path ~/.config/direnv/direnv.toml || true
- If 'cc' alias breaks, either install the claude CLI or remove the alias:
    functions -e cc; and optional:
    function cc; if type -q claude; claude $argv; else if type -q claude-code; claude-code $argv; else echo "claude CLI not installed"; end; end

EONOTE

echo "[repair] Completed."
