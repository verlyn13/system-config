#!/bin/bash
# Install/Uninstall/Status for Observability LaunchAgent

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/com.devops.obs.plist"
RUNNER="$SCRIPT_DIR/obs-hourly.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [install|uninstall|status|run]

install    Install and load LaunchAgent for hourly observations
uninstall  Unload and remove LaunchAgent
status     Show whether the agent is loaded and next run
run        Run the hourly job immediately (foreground)
EOF
}

write_plist() {
  mkdir -p "$PLIST_DIR"
  cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.devops.obs</string>
    <key>ProgramArguments</key>
    <array>
      <string>$RUNNER</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>StandardOutPath</key>
    <string>$HOME/.local/share/devops-mcp/logs/obs-hourly.out</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.local/share/devops-mcp/logs/obs-hourly.err</string>
    <key>RunAtLoad</key>
    <true/>
  </dict>
  </plist>
PLIST
}

install() {
  write_plist
  launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
  launchctl load "$PLIST_PATH"
  echo "✓ Observability LaunchAgent installed: com.devops.obs"
}

uninstall() {
  if [[ -f "$PLIST_PATH" ]]; then
    launchctl unload "$PLIST_PATH" || true
    rm -f "$PLIST_PATH"
    echo "✓ Observability LaunchAgent removed"
  else
    echo "Agent not installed"
  fi
}

status() {
  launchctl list | grep com.devops.obs || echo "Agent not loaded"
  echo "Plist: $PLIST_PATH"
}

run_now() {
  exec "$RUNNER"
}

case "${1:-}" in
  install) install ;;
  uninstall) uninstall ;;
  status) status ;;
  run) run_now ;;
  *) usage; exit 1 ;;
esac

