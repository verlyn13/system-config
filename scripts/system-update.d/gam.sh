# shellcheck shell=bash
plugin_register "gam" "GAM7 Google Workspace CLI" "curl" "false"

run_gam() {
  if ! have curl; then
    log warn "curl not found, cannot update GAM"
    return 0
  fi
  if [[ ! -d "$HOME/bin/gam7" ]]; then
    log info "GAM not installed, skipping (install: bash <(curl -s -S -L https://git.io/gam-install))"
    return 0
  fi
  log info "Updating GAM..."
  bash <(curl -s -S -L https://git.io/gam-install) -l
}

check_gam() {
  if [[ ! -x "$HOME/bin/gam7/gam" ]]; then
    log info "GAM not installed"
    return 0
  fi
  "$HOME/bin/gam7/gam" version 2>/dev/null | head -3
}
