#!/usr/bin/env bash
set -euo pipefail

echo "== System Env Doctor (direnv/mise) =="

OS=$(uname -a || true)
echo "OS: $OS"

echo "-- Versions --"
command -v direnv >/dev/null 2>&1 && direnv version || echo "direnv: not found"
command -v mise >/dev/null 2>&1 && mise --version || echo "mise: not found"
command -v fish >/dev/null 2>&1 && fish --version || true
command -v zsh >/dev/null 2>&1 && zsh --version || true
command -v bash >/dev/null 2>&1 && bash --version | head -n1 || true

echo
echo "-- mise settings --"
if command -v mise >/dev/null 2>&1; then
  mise settings || true
fi

echo
echo "-- direnv export test --"
SEGV=0
OUT=$(DIRENV_LOG_FORMAT= direnv export bash 2>&1 || true)
EXIT=$?
if echo "$OUT" | grep -qi "segmentation fault"; then
  SEGV=1
fi
echo "exit=$EXIT segv=$SEGV"
echo "$OUT" | head -n 5

if [[ $SEGV -eq 1 ]]; then
  cat <<'EOF'

Detected direnv segmentation fault during export.
Recommended remediation (macOS/Homebrew):
  brew update && brew upgrade direnv
If still failing: 
  brew reinstall direnv
  or switch to the latest release prebuilt from GitHub.

Temporary bypass (current repo):
  direnv deny .   # disable direnv for this directory
  mv .envrc .envrc.off  # disable until direnv is upgraded

After upgrade, re-enable:
  mv .envrc.off .envrc
  direnv allow .

EOF
fi

echo "-- .envrc content (first 30 lines) --"
sed -n '1,30p' .envrc 2>/dev/null || echo "no .envrc"

echo
echo "-- mise doctor --"
if command -v mise >/dev/null 2>&1; then
  mise doctor || true
fi

echo
echo "== Doctor complete =="

