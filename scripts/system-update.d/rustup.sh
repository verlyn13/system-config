# shellcheck shell=bash
plugin_register "rustup" "Legacy rustup toolchains" "rustup" "false"

run_rustup() {
  if ! have rustup; then
    log info "rustup not found, skipping"
    return 0
  fi
  rustup update
}

check_rustup() {
  if ! have rustup; then
    return 0
  fi
  rustup check
}
