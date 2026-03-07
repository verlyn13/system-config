#!/usr/bin/env bash
set -euo pipefail

echo "[doctor] PATH: $PATH"

check() {
  local name="$1";
  shift || true
  if command -v "$name" >/dev/null 2>&1; then
    printf "%-14s %s\n" "$name:" "$(command -v "$name")"
  else
    printf "%-14s %s\n" "$name:" "missing"
  fi
}

echo "\n[doctor] Core commands"
for c in brew git node npm npx pnpm bun python3 go java direnv starship jq; do
  check "$c"
done

echo "\n[doctor] Claude CLI"
check claude
check claude-code
check anthropic

echo "\n[doctor] Direnv config"
if [ -f "$HOME/.config/direnv/direnv.toml" ]; then
  echo "~/.config/direnv/direnv.toml:"; sed -n '1,60p' "$HOME/.config/direnv/direnv.toml" | sed 's/^/  /'
else
  echo "~/.config/direnv/direnv.toml missing"
fi

echo "\n[doctor] Fish conf.d"
ls -1 "$HOME/.config/fish/conf.d" 2>/dev/null | sed 's/^/  /' || echo "  ~/.config/fish/conf.d missing"

echo "\n[doctor] Suggestions"
if ! command -v anthropic >/dev/null 2>&1 && ! command -v claude >/dev/null 2>&1; then
  cat <<'EOT'
  - Install Claude Code CLI (native installer):
      curl -fsSL https://claude.ai/install.sh | bash
EOT
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "  - Install pnpm: brew install pnpm"
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "  - Install jq: brew install jq"
fi

echo "\n[doctor] Complete"
