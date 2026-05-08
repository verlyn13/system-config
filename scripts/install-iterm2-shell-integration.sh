#!/usr/bin/env bash
# install-iterm2-shell-integration.sh — repo-owned fetcher for iTerm2 zsh shell-integration.
# Idempotent. Verifies SHA-256 against a pinned value. Refuses to install on mismatch.
# Does NOT run iTerm2's upstream install_shell_integration.sh, which mutates dotfiles
# directly. Shell loading lives in zshrc.d/zz-iterm2.zsh and is repo-managed.
#
# Usage:
#   install-iterm2-shell-integration.sh             # install (or no-op if SHA matches)
#   install-iterm2-shell-integration.sh --install   # same as above (explicit)
#   install-iterm2-shell-integration.sh --verify    # exit 0 if installed and SHA matches
#                                                   # exit 1 if missing or mismatched
#
# To bump the pin: fetch the upstream script, compute `shasum -a 256`, update
# EXPECTED_SHA below, commit. Both the installer and ng-doctor probe read this file.
#
# The SHA is pinned because the upstream script is fetched over TLS but iTerm2 has
# no cryptographic signature on the artifact; a pinned SHA is the only way to detect
# unexpected upstream changes (and to refuse to apply them automatically).

set -euo pipefail

readonly SOURCE_URL="https://iterm2.com/shell_integration/zsh"
readonly EXPECTED_SHA="91027c6d5221ee7123609e8e5aa8840ea218f98583e516c3d425d5f8a2b20e7a"
readonly DEST="$HOME/.iterm2_shell_integration.zsh"

log()  { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

current_sha() {
  [[ -f "$DEST" ]] || return 0
  shasum -a 256 "$DEST" | awk '{print $1}'
}

verify() {
  local got
  got="$(current_sha)"
  if [[ -z "$got" ]]; then
    log "MISSING: $DEST"
    return 1
  fi
  if [[ "$got" == "$EXPECTED_SHA" ]]; then
    log "OK: $DEST matches pinned SHA ($EXPECTED_SHA)"
    return 0
  fi
  log "MISMATCH: $DEST"
  log "  expected: $EXPECTED_SHA"
  log "  got:      $got"
  return 1
}

install() {
  if verify >/dev/null 2>&1; then
    log "Already installed and verified ($DEST)."
    return 0
  fi

  command -v curl   >/dev/null 2>&1 || die "curl not found"
  command -v shasum >/dev/null 2>&1 || die "shasum not found"

  local tmp
  tmp="$(mktemp -t iterm2-shell-integration.XXXXXX)"
  trap 'rm -f "$tmp"' EXIT

  if ! curl -fsSL "$SOURCE_URL" -o "$tmp"; then
    die "download failed: $SOURCE_URL"
  fi

  local got
  got="$(shasum -a 256 "$tmp" | awk '{print $1}')"
  if [[ "$got" != "$EXPECTED_SHA" ]]; then
    rm -f "$tmp"
    trap - EXIT
    die "SHA mismatch — expected $EXPECTED_SHA, got $got. Refusing to install. \
Investigate upstream change before bumping EXPECTED_SHA."
  fi

  mv "$tmp" "$DEST"
  chmod 0644 "$DEST"
  trap - EXIT
  log "Installed: $DEST"
  log "SHA-256:   $got"
}

main() {
  case "${1-}" in
    --verify)            verify ;;
    ""|--install)        install ;;
    -h|--help)
      sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
      ;;
    *) die "unknown argument: $1 (try --help)" ;;
  esac
}

main "$@"
