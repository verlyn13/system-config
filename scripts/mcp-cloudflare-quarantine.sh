#!/usr/bin/env bash
#
# Temporarily quarantine the authenticated Cloudflare API MCP wrapper.
# This leaves cloudflare-docs and other MCP servers alone.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/system-config"
DISABLE_FILE="$STATE_DIR/mcp-cloudflare.disabled"
TARGET_URL="https://mcp.cloudflare.com/mcp"

usage() {
  cat <<EOF
Usage: $0 <command>

Commands:
  on       Disable new authenticated Cloudflare MCP wrapper launches
  off      Re-enable authenticated Cloudflare MCP wrapper launches
  status   Show disable marker and active Cloudflare MCP sessions
  reap     Terminate active mcp-remote sessions for authenticated Cloudflare MCP

Notes:
  - This does not affect cloudflare-docs.
  - This does not call Cloudflare.
  - Existing sessions continue until closed or reaped.
EOF
}

active_pids() {
  python3 - "$TARGET_URL" <<'PY'
import subprocess
import sys

target_url = sys.argv[1]
proc = subprocess.run(
    ["ps", "-axo", "pid=,command="],
    check=True,
    capture_output=True,
    text=True,
)

for line in proc.stdout.splitlines():
    parts = line.strip().split(None, 1)
    if len(parts) != 2:
        continue
    pid, command = parts
    if target_url not in command or "mcp-remote" not in command:
        continue
    if "node" not in command:
        continue
    print(pid)
PY
}

show_status() {
  if [[ -e "$DISABLE_FILE" ]]; then
    echo "Cloudflare MCP quarantine: ON"
    echo "Marker: $DISABLE_FILE"
    sed 's/^/  /' "$DISABLE_FILE" 2>/dev/null || true
  else
    echo "Cloudflare MCP quarantine: OFF"
    echo "Marker: $DISABLE_FILE"
  fi

  mapfile -t pids < <(active_pids)
  echo "Active authenticated Cloudflare MCP node sessions: ${#pids[@]}"
  if ((${#pids[@]} > 0)); then
    printf '  %s\n' "${pids[@]}"
  fi
}

enable_quarantine() {
  mkdir -p "$STATE_DIR"
  {
    printf 'disabled_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'reason=%s\n' "temporary Cloudflare API 429 containment"
    printf 'target=%s\n' "$TARGET_URL"
  } > "$DISABLE_FILE"
  echo "Cloudflare MCP quarantine enabled."
  show_status
}

disable_quarantine() {
  rm -f "$DISABLE_FILE"
  echo "Cloudflare MCP quarantine disabled."
  show_status
}

reap_sessions() {
  mapfile -t pids < <(active_pids)
  if ((${#pids[@]} == 0)); then
    echo "No active authenticated Cloudflare MCP sessions found."
    return 0
  fi

  echo "Terminating authenticated Cloudflare MCP sessions:"
  printf '  %s\n' "${pids[@]}"
  kill -TERM "${pids[@]}" 2>/dev/null || true
  sleep 2

  mapfile -t remaining < <(active_pids)
  if ((${#remaining[@]} > 0)); then
    echo "Force-killing remaining sessions:"
    printf '  %s\n' "${remaining[@]}"
    kill -KILL "${remaining[@]}" 2>/dev/null || true
  fi

  show_status
}

case "${1:-}" in
  on)
    enable_quarantine
    ;;
  off)
    disable_quarantine
    ;;
  status)
    show_status
    ;;
  reap)
    reap_sessions
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 2
    ;;
esac
