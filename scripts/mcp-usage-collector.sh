#!/usr/bin/env bash
#
# Temporary local MCP usage collector for host-capability-substrate planning.
# It collects local process/log/state shape only. It does not call external
# APIs, read process environments, or resolve secrets.

set -euo pipefail

LABEL="${MCP_USAGE_COLLECTOR_LABEL:-com.jefahnierocks.mcp-usage-collector}"
INTERVAL_SECONDS="${MCP_USAGE_COLLECTOR_INTERVAL_SECONDS:-60}"
STATE_DIR="${MCP_USAGE_COLLECTOR_STATE_DIR:-$HOME/.local/state/system-config/mcp-usage-collector}"
LOG_DIR="${MCP_USAGE_COLLECTOR_LOG_DIR:-$HOME/Library/Logs/system-config}"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

usage() {
  cat <<EOF
Usage: $0 <command>

Commands:
  snapshot   Collect one JSONL sample
  install    Install and start the temporary launchd collector
  uninstall  Stop and remove the launchd collector
  status     Show launchd status and recent sample files
  path       Print the collector state directory

Environment overrides:
  MCP_USAGE_COLLECTOR_INTERVAL_SECONDS=$INTERVAL_SECONDS
  MCP_USAGE_COLLECTOR_STATE_DIR=$STATE_DIR
EOF
}

ensure_dirs() {
  mkdir -p "$STATE_DIR" "$LOG_DIR" "$HOME/Library/LaunchAgents"
}

snapshot() {
  ensure_dirs
  umask 077

  local lock_dir output_file
  lock_dir="$STATE_DIR/.snapshot.lock"
  output_file="$STATE_DIR/$(date -u +%Y-%m-%d).jsonl"

  local lock_acquired=false
  if mkdir "$lock_dir" 2>/dev/null; then
    lock_acquired=true
  else
    if [[ -d "$lock_dir" ]] && [[ -n "$(find "$lock_dir" -prune -mmin +5 -print 2>/dev/null)" ]]; then
      rmdir "$lock_dir" 2>/dev/null || true
      if mkdir "$lock_dir" 2>/dev/null; then
        lock_acquired=true
      fi
    fi
  fi

  if [[ "$lock_acquired" != "true" ]]; then
    return 0
  fi
  SNAPSHOT_LOCK_DIR="$lock_dir"
  trap 'rmdir "${SNAPSHOT_LOCK_DIR:-}" 2>/dev/null || true' EXIT

  python3 - "$STATE_DIR" <<'PY' >> "$output_file"
import datetime as dt
import glob
import json
import os
import platform
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Optional

state_dir = Path(sys.argv[1])
home = Path.home()


def run(command: list[str]) -> str:
    try:
        return subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        ).stdout
    except Exception as exc:
        return f"__error__ {type(exc).__name__}: {exc}"


def redact(value: str) -> str:
    patterns = [
        (r"(Authorization:\s*Bearer\s+)[^\s]+", r"\1<redacted>"),
        (r"(?i)(\bbearer\s+)[A-Za-z0-9._~+/=-]+", r"\1<redacted>"),
        (r"(?i)((?:api[-_]?key|token|secret|password|passwd|pwd)=)[^&\s]+", r"\1<redacted>"),
        (r"(?i)((?:--api-key|--token|--secret|--password)\s+)[^\s]+", r"\1<redacted>"),
        (r"(?i)((?:CLOUDFLARE_API_TOKEN|RUNPOD_API_KEY|GITHUB_PAT|BRAVE_API_KEY|FIRECRAWL_API_KEY)=)[^\s]+", r"\1<redacted>"),
    ]
    redacted = value
    for pattern, replacement in patterns:
        redacted = re.sub(pattern, replacement, redacted)
    return redacted


def parse_ps() -> dict[int, dict[str, Any]]:
    output = run(["ps", "-axo", "pid=,ppid=,pcpu=,pmem=,rss=,vsz=,etime=,command="])
    processes: dict[int, dict[str, Any]] = {}
    for line in output.splitlines():
        parts = line.strip().split(None, 7)
        if len(parts) != 8:
            continue
        pid_s, ppid_s, pcpu_s, pmem_s, rss_s, vsz_s, etime, command = parts
        try:
            pid = int(pid_s)
            processes[pid] = {
                "pid": pid,
                "ppid": int(ppid_s),
                "pcpu": float(pcpu_s),
                "pmem": float(pmem_s),
                "rss_kb": int(rss_s),
                "vsz_kb": int(vsz_s),
                "etime": etime,
                "command": command,
            }
        except ValueError:
            continue
    return processes


def ancestors(processes: dict[int, dict[str, Any]], pid: int, limit: int = 10) -> list[dict[str, Any]]:
    chain: list[dict[str, Any]] = []
    current = pid
    seen: set[int] = set()
    for _ in range(limit):
        process = processes.get(current)
        if process is None or current in seen:
            break
        seen.add(current)
        chain.append(process)
        current = int(process.get("ppid", 0))
    return chain


def classify(commands: list[str]) -> str:
    joined = "\n".join(commands)
    lowered = joined.lower()
    if "@openai/codex" in joined or "/codex/codex" in joined:
        return "Codex CLI"
    if "/Library/Application Support/Claude/claude-code/" in joined:
        return "Claude Code macOS app"
    if any(command == "claude" or command.endswith("/claude") for command in commands):
        return "Claude Code CLI"
    if "/Applications/Claude.app/" in joined:
        return "Claude Desktop"
    if "/Applications/Cursor.app/" in joined or "cursor helper" in lowered:
        return "Cursor"
    if "windsurf" in lowered or "codeium" in lowered:
        return "Windsurf"
    if "/Applications/Warp.app/" in joined or "warp" in lowered:
        return "Warp"
    if "copilot" in lowered:
        return "Copilot CLI"
    return "other"


def endpoint_from(command: str) -> Optional[str]:
    match = re.search(r"https?://[^\s\"'<>]+/mcp(?:\?[^\s\"'<>]+)?", command)
    if match:
        return match.group(0)
    return None


def command_digest(command: str) -> str:
    import hashlib

    return hashlib.sha256(redact(command).encode("utf-8", errors="replace")).hexdigest()[:16]


def collect_markers() -> list[dict[str, str]]:
    candidates: list[Path] = []
    patterns = [
        home / "Repos/verlyn13/*/docs/system-state/*.md",
        home / "Organizations/jefahnierocks/*/docs/system-state/*.md",
    ]
    for pattern in patterns:
        candidates.extend(Path(path) for path in glob.glob(str(pattern)))

    markers: list[dict[str, str]] = []
    marker_re = re.compile(r"^(last_[a-z0-9_]+_mcp_429):\s*(.*)$")
    for path in sorted(set(candidates)):
        try:
            text = path.read_text(errors="replace")
        except OSError:
            continue
        for line in text.splitlines()[:80]:
            match = marker_re.match(line)
            if not match:
                continue
            markers.append({
                "file": str(path),
                "key": match.group(1),
                "value": match.group(2).strip(),
            })
    return markers


def collect_logs() -> list[dict[str, Any]]:
    log_paths = [
        home / "Library/Logs/Claude/mcp.log",
        home / "Library/Logs/Claude/mcp-server-cloudflare.log",
        home / "Library/Logs/Claude/mcp-server-cloudflare-docs.log",
    ]
    patterns = {
        "rate_limit": re.compile(r"HTTP 429|status.?429|Too Many Requests|rate[- ]limit|fetchWithRetry: 429", re.I),
        "init_or_tools_list": re.compile(r"Initializing server|tools/list"),
        "transport_close": re.compile(r"Client transport closed|Server transport closed|SSE stream disconnected"),
        "cloudflare_line": re.compile(r"\[cloudflare(-docs)?\]"),
    }
    metrics: list[dict[str, Any]] = []
    for path in log_paths:
        if not path.exists():
            continue
        try:
            stat = path.stat()
            with path.open("rb") as handle:
                handle.seek(max(0, stat.st_size - 1_000_000))
                text = handle.read().decode("utf-8", errors="replace")
        except OSError as exc:
            metrics.append({"file": str(path), "error": str(exc)})
            continue
        cloudflare_only = path.name == "mcp.log"
        lines = text.splitlines()
        if cloudflare_only:
            lines = [line for line in lines if patterns["cloudflare_line"].search(line)]
        joined = "\n".join(lines)
        metrics.append({
            "file": str(path),
            "size_bytes": stat.st_size,
            "mtime": dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).isoformat().replace("+00:00", "Z"),
            "tail_window_bytes": min(stat.st_size, 1_000_000),
            "tail_rate_limit_markers": len(patterns["rate_limit"].findall(joined)),
            "tail_init_or_tools_list_markers": len(patterns["init_or_tools_list"].findall(joined)),
            "tail_transport_close_markers": len(patterns["transport_close"].findall(joined)),
        })
    return metrics


processes = parse_ps()
agent_resources: dict[str, dict[str, Any]] = {}
mcp_processes: list[dict[str, Any]] = []
mcp_remote_sessions: list[dict[str, Any]] = []
top_candidates: list[dict[str, Any]] = []
op_processes = 0

for pid, process in processes.items():
    chain = ancestors(processes, pid)
    commands = [str(item["command"]) for item in chain]
    owner = classify(commands)
    command = str(process["command"])
    lower = command.lower()
    is_mcp = "mcp" in lower or "modelcontextprotocol" in lower
    is_agent = owner != "other"
    if re.search(r"(^|/)op( daemon)?(\s|$)", command):
        op_processes += 1

    if is_agent:
        bucket = agent_resources.setdefault(owner, {
            "process_count": 0,
            "mcp_process_count": 0,
            "rss_kb": 0,
            "cpu_percent": 0.0,
        })
        bucket["process_count"] += 1
        bucket["rss_kb"] += int(process["rss_kb"])
        bucket["cpu_percent"] = round(float(bucket["cpu_percent"]) + float(process["pcpu"]), 2)
        if is_mcp:
            bucket["mcp_process_count"] += 1

    if is_mcp:
        detail = {
            "pid": pid,
            "ppid": process["ppid"],
            "owner": owner,
            "pcpu": process["pcpu"],
            "pmem": process["pmem"],
            "rss_kb": process["rss_kb"],
            "vsz_kb": process["vsz_kb"],
            "etime": process["etime"],
            "endpoint": endpoint_from(command),
            "command_hash": command_digest(command),
            "command": redact(command)[:500],
        }
        mcp_processes.append(detail)
        if "mcp-remote" in lower and "node" in lower:
            detail["parent_chain"] = [
                {
                    "pid": item["pid"],
                    "command_hash": command_digest(str(item["command"])),
                    "command": redact(str(item["command"]))[:300],
                }
                for item in chain[:6]
            ]
            mcp_remote_sessions.append(detail)

    if is_agent or is_mcp:
        top_candidates.append({
            "pid": pid,
            "owner": owner,
            "pcpu": process["pcpu"],
            "pmem": process["pmem"],
            "rss_kb": process["rss_kb"],
            "etime": process["etime"],
            "command_hash": command_digest(command),
            "command": redact(command)[:300],
        })

sessions_by_owner: dict[str, int] = {}
sessions_by_endpoint: dict[str, int] = {}
for session in mcp_remote_sessions:
    owner = str(session["owner"])
    endpoint = str(session.get("endpoint") or "unknown")
    sessions_by_owner[owner] = sessions_by_owner.get(owner, 0) + 1
    sessions_by_endpoint[endpoint] = sessions_by_endpoint.get(endpoint, 0) + 1

loadavg = os.getloadavg() if hasattr(os, "getloadavg") else None
sample = {
    "schema_version": 1,
    "sampled_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
    "host": platform.node(),
    "collector": {
        "state_dir": str(state_dir),
        "policy": "local ps/log/state only; no external APIs; no env capture; command argv redacted",
    },
    "system": {
        "loadavg": list(loadavg) if loadavg is not None else None,
        "process_count": len(processes),
        "op_process_count": op_processes,
    },
    "summary": {
        "mcp_process_count": len(mcp_processes),
        "mcp_remote_session_count": len(mcp_remote_sessions),
        "mcp_remote_sessions_by_owner": dict(sorted(sessions_by_owner.items())),
        "mcp_remote_sessions_by_endpoint": dict(sorted(sessions_by_endpoint.items())),
        "agent_resources": dict(sorted(agent_resources.items())),
    },
    "mcp_remote_sessions": sorted(mcp_remote_sessions, key=lambda item: (str(item["owner"]), int(item["pid"]))),
    "mcp_processes": sorted(mcp_processes, key=lambda item: int(item["pid"])),
    "top_agent_or_mcp_processes_by_rss": sorted(top_candidates, key=lambda item: int(item["rss_kb"]), reverse=True)[:25],
    "markers": collect_markers(),
    "log_metrics": collect_logs(),
}

print(json.dumps(sample, sort_keys=True, separators=(",", ":")))
PY
  rmdir "$lock_dir" 2>/dev/null || true
  trap - EXIT
}

write_plist() {
  ensure_dirs
  python3 - "$PLIST_PATH" "$SCRIPT_PATH" "$LABEL" "$INTERVAL_SECONDS" "$LOG_DIR" <<'PY'
import plistlib
import sys
from pathlib import Path

plist_path = Path(sys.argv[1])
script_path = sys.argv[2]
label = sys.argv[3]
interval = int(sys.argv[4])
log_dir = Path(sys.argv[5])

plist = {
    "Label": label,
    "ProgramArguments": [script_path, "snapshot"],
    "StartInterval": interval,
    "RunAtLoad": True,
    "ProcessType": "Background",
    "LowPriorityIO": True,
    "StandardOutPath": str(log_dir / "mcp-usage-collector.out.log"),
    "StandardErrorPath": str(log_dir / "mcp-usage-collector.err.log"),
}

plist_path.parent.mkdir(parents=True, exist_ok=True)
with plist_path.open("wb") as handle:
    plistlib.dump(plist, handle, sort_keys=False)
PY
}

install_service() {
  write_plist
  launchctl bootout "gui/$(id -u)" "$PLIST_PATH" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
  launchctl kickstart -k "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
  echo "Installed $LABEL"
  echo "  plist: $PLIST_PATH"
  echo "  state: $STATE_DIR"
  echo "  interval: ${INTERVAL_SECONDS}s"
}

uninstall_service() {
  launchctl bootout "gui/$(id -u)" "$PLIST_PATH" >/dev/null 2>&1 || true
  rm -f "$PLIST_PATH"
  echo "Uninstalled $LABEL"
  echo "  retained state: $STATE_DIR"
}

status_service() {
  echo "Label: $LABEL"
  echo "Plist: $PLIST_PATH"
  echo "State: $STATE_DIR"
  if [[ -f "$PLIST_PATH" ]]; then
    echo "LaunchAgent: installed"
  else
    echo "LaunchAgent: not installed"
  fi
  echo
  launchctl print "gui/$(id -u)/$LABEL" 2>/dev/null || true
  echo
  if [[ -d "$STATE_DIR" ]]; then
    find "$STATE_DIR" -maxdepth 1 -type f -name '*.jsonl' -print -exec wc -l {} \; | sed 's/^/  /'
  fi
}

case "${1:-}" in
  snapshot)
    snapshot
    ;;
  install)
    install_service
    ;;
  uninstall)
    uninstall_service
    ;;
  status)
    status_service
    ;;
  path)
    echo "$STATE_DIR"
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
