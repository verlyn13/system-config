#!/usr/bin/env bash
set -euo pipefail

BASE="http://127.0.0.1:7777"

menu() {
  echo "DS Automation"
  echo "1) Capabilities"
  echo "2) Run system.validate"
  echo "q) Quit"
}

while true; do
  menu
  read -rp "> " choice
  case "$choice" in
    1) curl -sS "$BASE/v1/capabilities" | jq . ;;
    2) curl -sS -X POST "$BASE/v1/tasks/run" -H 'Content-Type: application/json' -d '{"task":"system.validate","params":{}}' | jq . ;;
    q) exit 0 ;;
  esac
done

