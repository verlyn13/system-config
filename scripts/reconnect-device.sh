#!/usr/bin/env bash
# reconnect-device.sh — Reconnect ADB to a device over WiFi
#
# Usage:
#   ./scripts/reconnect-device.sh <target>
#   ./scripts/reconnect-device.sh                     # uses ADB_TARGET or PIXEL_IP
#   ./scripts/reconnect-device.sh 192.168.1.42       # assumes :5555
#   ./scripts/reconnect-device.sh 192.168.1.42:5555
#   ./scripts/reconnect-device.sh '[fe80::1%en0]:5555'

set -euo pipefail

PORT=5555
TARGET=""

normalize_target() {
    local raw="$1"

    case "$raw" in
        \[*\]:*)
            printf '%s\n' "$raw"
            ;;
        \[*\])
            printf '%s:%s\n' "$raw" "$PORT"
            ;;
        *:*)
            printf '%s\n' "$raw"
            ;;
        *)
            printf '%s:%s\n' "$raw" "$PORT"
            ;;
    esac
}

usage() {
    cat <<'EOF'
Usage: reconnect-device.sh <target>
   or: export ADB_TARGET=<target>
   or: export PIXEL_IP=<ip>   # legacy fallback

Examples:
  reconnect-device.sh 192.168.1.42
  reconnect-device.sh 192.168.1.42:5555
  reconnect-device.sh '[fe80::1%en0]:5555'
EOF
}

if ! command -v adb >/dev/null 2>&1; then
    echo "adb not found on PATH" >&2
    exit 1
fi

if [[ -n ${1:-} ]]; then
    TARGET="$(normalize_target "$1")"
elif [[ -n ${ADB_TARGET:-} ]]; then
    TARGET="$(normalize_target "$ADB_TARGET")"
elif [[ -n ${PIXEL_IP:-} ]]; then
    TARGET="$(normalize_target "$PIXEL_IP")"
else
    usage
    exit 1
fi

echo "Disconnecting stale connection for ${TARGET}..."
adb disconnect "${TARGET}" >/dev/null 2>&1 || true

echo "Connecting to ${TARGET}..."
adb connect "${TARGET}"

echo ""
echo "Connected devices:"
adb devices -l
