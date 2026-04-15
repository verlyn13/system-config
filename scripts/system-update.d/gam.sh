# shellcheck shell=bash
plugin_register "gam" "GAM7 Google Workspace CLI" "curl" "false"

run_gam() {
  if ! have curl; then
    log warn "curl not found, cannot update GAM"
    return 0
  fi
  if [[ ! -d "$HOME/bin/gam7" ]]; then
    log info "GAM not installed, skipping (install: https://github.com/GAM-team/GAM)"
    return 0
  fi
  # SECURITY: This pipes a remote script to bash (supply-chain risk).
  # GAM does not provide checksums for the installer. This plugin is
  # default-off for this reason. Review the script before enabling:
  #   https://github.com/GAM-team/GAM/blob/main/src/gam-install.sh
  log info "Updating GAM..."
  bash <(curl -s -S -L https://raw.githubusercontent.com/GAM-team/GAM/main/src/gam-install.sh) -l
}

check_gam() {
  if [[ ! -x "$HOME/bin/gam7/gam" ]]; then
    log info "GAM not installed"
    return 0
  fi
  "$HOME/bin/gam7/gam" version 2>/dev/null | head -3
}
