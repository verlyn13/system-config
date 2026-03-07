# shellcheck shell=bash
plugin_register "brew-casks" "Homebrew casks" "brew" "false"

run_brew-casks() {
  if ! have brew; then
    log info "brew not found, skipping"
    return 0
  fi
  brew upgrade --cask
}

check_brew-casks() {
  if ! have brew; then
    return 0
  fi
  brew outdated --cask || true
}
