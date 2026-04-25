#!/usr/bin/env bash
#
# Local-only diagnostics for Cloudflare MCP fan-out and recorded 429 markers.
# This script does not call Cloudflare or resolve any secrets.

set -euo pipefail

TARGET_URL="https://mcp.cloudflare.com/mcp"

echo "Cloudflare MCP local diagnostics"
echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Target: $TARGET_URL"
echo

if command -v python3 >/dev/null 2>&1; then
  python3 - "$TARGET_URL" <<'PY'
import re
import subprocess
import sys
from collections import Counter

target_url = sys.argv[1]


def redact(value: str) -> str:
    return re.sub(r"(Authorization:\s*Bearer\s+)[^\s]+", r"\1<redacted>", value)


proc = subprocess.run(
    ["ps", "-axo", "pid=,ppid=,etime=,command="],
    check=True,
    capture_output=True,
    text=True,
)

processes: dict[int, tuple[int, str, str]] = {}
for line in proc.stdout.splitlines():
    parts = line.strip().split(None, 3)
    if len(parts) != 4:
        continue
    pid_s, ppid_s, etime, command = parts
    try:
        processes[int(pid_s)] = (int(ppid_s), etime, command)
    except ValueError:
        continue


def ancestor_commands(pid: int, limit: int = 10) -> list[tuple[int, str]]:
    chain: list[tuple[int, str]] = []
    current = pid
    seen: set[int] = set()
    for _ in range(limit):
        if current in seen or current not in processes:
            break
        seen.add(current)
        ppid, _etime, command = processes[current]
        chain.append((current, command))
        current = ppid
    return chain


def classify(commands: list[str]) -> str:
    joined = "\n".join(commands)
    if "@openai/codex" in joined or "/codex/codex" in joined:
        return "Codex CLI"
    if "/Library/Application Support/Claude/claude-code/" in joined:
        return "Claude Code macOS app"
    if any(command == "claude" or command.endswith("/claude") for command in commands):
        return "Claude Code CLI"
    if "/Applications/Claude.app/" in joined:
        return "Claude Desktop"
    if "/Applications/Cursor.app/" in joined or "Cursor Helper" in joined:
        return "Cursor"
    if "Windsurf" in joined or "Codeium" in joined:
        return "Windsurf"
    if "/Applications/Warp.app/" in joined or "Warp" in joined:
        return "Warp"
    return "unknown"


sessions: list[tuple[int, str, str, str]] = []
for pid, (_ppid, etime, command) in processes.items():
    if target_url not in command or "mcp-remote" not in command:
        continue
    if "npm exec" in command:
        continue
    if "node" not in command:
        continue
    chain = ancestor_commands(pid)
    commands = [command for _pid, command in chain]
    owner = classify(commands)
    launcher = redact(commands[1]) if len(commands) > 1 else redact(command)
    sessions.append((pid, etime, owner, launcher))

sessions.sort(key=lambda item: item[2])
counts = Counter(owner for _pid, _etime, owner, _launcher in sessions)

print("Active Cloudflare MCP sessions")
print(f"  node mcp-remote sessions: {len(sessions)}")
for owner, count in sorted(counts.items()):
    print(f"  {owner}: {count}")

if sessions:
    print()
    print("Session detail")
    for pid, etime, owner, launcher in sessions:
        print(f"  pid={pid} age={etime} owner={owner} launcher={launcher[:180]}")

if len(sessions) > 1:
    print()
    print("Warning: more than one authenticated Cloudflare MCP session is live.")
    print("Use a single broker before Cloudflare mutations; leave other agents read-only or quit them.")
PY
else
  echo "python3 not found; skipping process fan-out analysis"
fi

echo
echo "Known last_cf_mcp_429 markers"
markers_found=false
state_files=(
  "$HOME/Repos/verlyn13/hetzner/docs/system-state/runpod-stack.md"
  "$HOME/Repos/verlyn13/runpod-inference/docs/system-state/runpod-stack.md"
  "$HOME/Repos/verlyn13/runpod-review-webui/docs/system-state/runpod-stack.md"
  "$HOME/Organizations/jefahnierocks/host-capability-substrate/docs/system-state/runpod-stack.md"
)

for state_file in "${state_files[@]}"; do
  [[ -f "$state_file" ]] || continue
  marker="$(awk '/^last_cf_mcp_429:/ { sub(/^[^:]+:[[:space:]]*/, ""); print; exit }' "$state_file")"
  [[ -n "$marker" ]] || continue
  printf '  %s: %s\n' "$state_file" "$marker"
  markers_found=true
done

if ! $markers_found; then
  echo "  none found in known state files"
fi

echo
echo "Local Claude MCP log hints"
logs=(
  "$HOME/Library/Logs/Claude/mcp.log"
  "$HOME/Library/Logs/Claude/mcp-server-cloudflare.log"
  "$HOME/Library/Logs/Claude/mcp-server-cloudflare-docs.log"
)

count_pattern() {
  local log_file="$1"
  local pattern="$2"
  local cloudflare_only="${3:-false}"

  if [[ "$cloudflare_only" == "true" ]]; then
    grep -E '\[cloudflare(-docs)?\]' "$log_file" | grep -Eic "$pattern" || true
  else
    grep -Eic "$pattern" "$log_file" || true
  fi
}

for log_file in "${logs[@]}"; do
  [[ -f "$log_file" ]] || continue
  cloudflare_only=false
  [[ "$(basename "$log_file")" == "mcp.log" ]] && cloudflare_only=true

  rate_count="$(count_pattern "$log_file" 'HTTP 429|status.?429|Too Many Requests|rate[- ]limit|fetchWithRetry: 429' "$cloudflare_only")"
  init_count="$(count_pattern "$log_file" 'Initializing server|tools/list' "$cloudflare_only")"
  close_count="$(count_pattern "$log_file" 'Client transport closed|Server transport closed|SSE stream disconnected' "$cloudflare_only")"
  printf '  %s\n' "$log_file"
  printf '    rate-limit markers: %s\n' "$rate_count"
  printf '    init/tools-list markers: %s\n' "$init_count"
  printf '    transport-close markers: %s\n' "$close_count"
done
