# shellcheck shell=bash
plugin_register "gem" "Ruby gems" "gem" "false"

run_gem() {
  if ! have gem; then
    log info "gem not found, skipping"
    return 0
  fi
  gem update
}

check_gem() {
  if ! have gem; then
    return 0
  fi
  gem outdated || true
}
