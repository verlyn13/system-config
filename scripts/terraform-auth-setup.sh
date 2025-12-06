#!/usr/bin/env bash
set -euo pipefail

# Configure Terraform CLI authentication.
# Supports two modes:
# 1) Non-interactive via TF_TOKEN_app_terraform_io env var
# 2) Interactive via `terraform login`

CRED_DIR="${HOME}/.terraform.d"
CRED_FILE="${CRED_DIR}/credentials.tfrc.json"
HOST="app.terraform.io"

mkdir -p "${CRED_DIR}"

merge_credentials() {
  local tmp
  tmp="$(mktemp)"
  # shellcheck disable=SC2016
  jq -s 'reduce .[] as $i ({}; . * $i)' "$@" >"${tmp}"
  mv "${tmp}" "${CRED_FILE}"
}

write_token_json() {
  local token="$1"
  jq -n --arg host "${HOST}" --arg token "${token}" '{
    "credentials": { ($host): { "token": $token } }
  }'
}

if [[ -n "${TF_TOKEN_app_terraform_io:-}" ]]; then
  echo "[terraform-auth] Using TF_TOKEN_app_terraform_io from environment."
  if [[ -f "${CRED_FILE}" ]]; then
    echo "[terraform-auth] Merging token into existing ${CRED_FILE}"
    tmp_json="$(mktemp)"
    write_token_json "${TF_TOKEN_app_terraform_io}" >"${tmp_json}"
    merge_credentials "${CRED_FILE}" "${tmp_json}"
    rm -f "${tmp_json}"
  else
    echo "[terraform-auth] Creating ${CRED_FILE}"
    write_token_json "${TF_TOKEN_app_terraform_io}" >"${CRED_FILE}"
  fi
  echo "[terraform-auth] Configured token for ${HOST} in ${CRED_FILE}"
  exit 0
fi

echo "[terraform-auth] No TF_TOKEN_app_terraform_io in env. Launching interactive login..."
if ! command -v terraform >/dev/null 2>&1; then
  echo "[terraform-auth] ERROR: terraform CLI not found. Run scripts/update-terraform-cli.sh first." >&2
  exit 1
fi

terraform login "${HOST}"
echo "[terraform-auth] Completed interactive login. Credentials stored at ${CRED_FILE}" 

