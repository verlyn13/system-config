#!/usr/bin/env bash
#
# One-shot Cloudflare Access login-event GraphQL reader.
# Use only after operator approval. This makes a single Cloudflare API request.

set -euo pipefail

ACCOUNT_ID_DEFAULT="13eb584192d9cefb730fde0cfd271328"
GRAPHQL_URL="https://api.cloudflare.com/client/v4/graphql"
OP_URI="op://Dev/cloudflare-mcp-jefahnierocks/token"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/system-config/cloudflare-access-graphql"
DISABLE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/system-config/mcp-cloudflare.disabled"
TARGET_URL="https://mcp.cloudflare.com/mcp"

usage() {
  cat <<EOF
Usage:
  $0 plan --ray-id RAY --since ISO8601 --until ISO8601 [--account-id ID]
  $0 run  --ray-id RAY --since ISO8601 --until ISO8601 [--account-id ID]

Purpose:
  Query Cloudflare GraphQL Analytics accessLoginRequestsAdaptiveGroups for one
  Access authentication event. Non-identity/service-token auth events are not
  available in the Zero Trust dashboard Access authentication log view.

Safety:
  - 'plan' makes no network calls.
  - 'run' makes exactly one POST to $GRAPHQL_URL.
  - 'run' refuses unless authenticated Cloudflare MCP is quarantined and no
    active authenticated Cloudflare MCP mcp-remote sessions are running.
  - The bearer token is passed to curl via stdin config, not argv.
EOF
}

active_cloudflare_mcp_sessions() {
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
    if target_url in command and "mcp-remote" in command and "node" in command:
        print(pid)
PY
}

write_body() {
  local body_file="$1"
  python3 - "$account_id" "$ray_id" "$since" "$until" > "$body_file" <<'PY'
import json
import sys

account_id, ray_id, since, until = sys.argv[1:5]

query = """
query accessLoginRequestsAdaptiveGroups($accountTag: string, $rayId: string, $datetimeStart: string, $datetimeEnd: string) {
  viewer {
    accounts(filter: {accountTag: $accountTag}) {
      accessLoginRequestsAdaptiveGroups(
        limit: 100,
        filter: {datetime_geq: $datetimeStart, datetime_leq: $datetimeEnd, cfRayId: $rayId},
        orderBy: [datetime_ASC]
      ) {
        dimensions {
          datetime
          isSuccessfulLogin
          hasWarpEnabled
          hasGatewayEnabled
          hasExistingJWT
          approvingPolicyId
          cfRayId
          ipAddress
          userUuid
          identityProvider
          country
          deviceId
          mtlsStatus
          mtlsCertSerialId
          mtlsCommonName
          serviceTokenId
        }
      }
    }
  }
}
""".strip()

print(json.dumps({
    "query": query,
    "variables": {
        "accountTag": account_id,
        "rayId": ray_id,
        "datetimeStart": since,
        "datetimeEnd": until,
    },
}, indent=2, sort_keys=True))
PY
}

summarize_response() {
  local response_file="$1"
  python3 - "$response_file" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())

if data.get("errors"):
    print("GraphQL errors:")
    for error in data["errors"]:
        print(f"  - {error.get('message', error)}")
    sys.exit(2)

accounts = (((data.get("data") or {}).get("viewer") or {}).get("accounts") or [])
groups = []
if accounts:
    groups = accounts[0].get("accessLoginRequestsAdaptiveGroups") or []

print(f"accessLoginRequestsAdaptiveGroups rows: {len(groups)}")
for index, group in enumerate(groups, start=1):
    dimensions = group.get("dimensions") or {}
    print(f"row {index}:")
    for key in [
        "datetime",
        "cfRayId",
        "isSuccessfulLogin",
        "identityProvider",
        "serviceTokenId",
        "approvingPolicyId",
        "hasExistingJWT",
        "hasWarpEnabled",
        "hasGatewayEnabled",
        "deviceId",
        "ipAddress",
        "country",
        "mtlsStatus",
    ]:
        print(f"  {key}: {dimensions.get(key)}")
PY
}

command="${1:-}"
shift || true

account_id="$ACCOUNT_ID_DEFAULT"
ray_id=""
since=""
until=""

while (($# > 0)); do
  case "$1" in
    --account-id)
      account_id="${2:-}"
      shift 2
      ;;
    --ray-id)
      ray_id="${2:-}"
      shift 2
      ;;
    --since)
      since="${2:-}"
      shift 2
      ;;
    --until)
      until="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$command" in
  plan|run)
    ;;
  -h|--help|help|"")
    usage
    exit 0
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 2
    ;;
esac

if [[ -z "$ray_id" || -z "$since" || -z "$until" ]]; then
  echo "Missing required --ray-id, --since, or --until." >&2
  usage >&2
  exit 2
fi

# Cloudflare docs use the bare Ray ID without the colo suffix.
ray_id="${ray_id%%-*}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
body_file="$tmp_dir/graphql-body.json"
write_body "$body_file"

if [[ "$command" == "plan" ]]; then
  echo "No network call made."
  echo "Endpoint: $GRAPHQL_URL"
  echo "Account: $account_id"
  echo "Ray ID: $ray_id"
  echo "Window: $since .. $until"
  echo
  cat "$body_file"
  exit 0
fi

if [[ ! -e "$DISABLE_FILE" ]]; then
  echo "Refusing: authenticated Cloudflare MCP is not quarantined." >&2
  echo "Run: scripts/mcp-cloudflare-quarantine.sh on && scripts/mcp-cloudflare-quarantine.sh reap" >&2
  exit 1
fi

mapfile -t active_pids < <(active_cloudflare_mcp_sessions)
if ((${#active_pids[@]} > 0)); then
  echo "Refusing: active authenticated Cloudflare MCP sessions remain:" >&2
  printf '  %s\n' "${active_pids[@]}" >&2
  exit 1
fi

token="${CLOUDFLARE_API_TOKEN:-}"
if [[ -z "$token" ]]; then
  if ! command -v op >/dev/null 2>&1; then
    echo "Refusing: CLOUDFLARE_API_TOKEN unset and op not found." >&2
    exit 1
  fi
  token="$(op read --account my.1password.com "$OP_URI")"
fi

if [[ -z "$token" ]]; then
  echo "Refusing: Cloudflare token did not resolve." >&2
  exit 1
fi

run_id="$(date -u +%Y%m%dT%H%M%SZ)-$ray_id"
run_dir="$STATE_DIR/$run_id"
mkdir -p "$run_dir"
chmod 700 "$STATE_DIR" "$run_dir"

request_file="$run_dir/request.json"
headers_file="$run_dir/headers.txt"
response_file="$run_dir/response.json"
cp "$body_file" "$request_file"

http_code="$(
  printf 'header = "Authorization: Bearer %s"\n' "$token" |
    curl \
      --silent \
      --show-error \
      --request POST \
      --config - \
      --header "Content-Type: application/json" \
      --data-binary "@$request_file" \
      --dump-header "$headers_file" \
      --output "$response_file" \
      --write-out "%{http_code}" \
      "$GRAPHQL_URL"
)"

unset token

echo "HTTP $http_code"
echo "Saved:"
echo "  request:  $request_file"
echo "  headers:  $headers_file"
echo "  response: $response_file"
echo
echo "Rate-limit headers:"
grep -Eih '^(ratelimit|ratelimit-policy|retry-after|cf-ray):' "$headers_file" || true
echo

if [[ "$http_code" == "429" ]]; then
  echo "Cloudflare returned 429. Stop all Cloudflare traffic and extend the quiet window." >&2
  exit 75
fi

if [[ "$http_code" != 2* ]]; then
  echo "Cloudflare returned non-2xx." >&2
  cat "$response_file" >&2
  exit 1
fi

summarize_response "$response_file"
