#!/usr/bin/env bash
set -euo pipefail

# Update or install the Terraform CLI via Homebrew (macOS).
# Ensures Homebrew-managed version is used, not mise.

echo "[terraform] Ensuring latest Terraform CLI via Homebrew..."

if ! command -v brew >/dev/null 2>&1; then
  echo "[terraform] Homebrew not found. Please install Homebrew: https://brew.sh" >&2
  exit 1
fi

# Ensure HashiCorp tap is present
brew tap hashicorp/tap >/dev/null

if brew list --formula | grep -qE '^terraform$'; then
  echo "[terraform] Upgrading terraform (brew upgrade hashicorp/tap/terraform)"
  brew upgrade hashicorp/tap/terraform || true
else
  echo "[terraform] Installing terraform (brew install hashicorp/tap/terraform)"
  brew install hashicorp/tap/terraform
fi

# Use Homebrew's terraform explicitly
BREW_PREFIX="$(brew --prefix)"
TF_BIN="${BREW_PREFIX}/bin/terraform"

if [[ ! -x "${TF_BIN}" ]]; then
  echo "[terraform] ERROR: Homebrew terraform binary not found at ${TF_BIN}" >&2
  exit 2
fi

echo "[terraform] Binary: ${TF_BIN}"
echo "[terraform] Version: $(${TF_BIN} -version | head -n 1)"

# Warn if mise is managing terraform
if command -v mise >/dev/null 2>&1; then
  MISE_TF="$(command -v terraform 2>/dev/null || true)"
  if [[ -n "${MISE_TF}" && "${MISE_TF}" != "${TF_BIN}" ]]; then
    echo "[terraform] WARNING: mise-managed terraform found at ${MISE_TF}"
    echo "[terraform] WARNING: This conflicts with Homebrew version at ${TF_BIN}"
    echo "[terraform] RECOMMENDED: Remove 'terraform = \"latest\"' from .mise.toml"
    echo "[terraform] RECOMMENDED: Run 'mise uninstall terraform' to remove mise version"
  fi
fi

echo "[terraform] Done."

