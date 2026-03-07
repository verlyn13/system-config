# shellcheck shell=bash
plugin_register "pipx" "pipx packages" "pipx" "true"

run_pipx() {
  if ! have pipx; then
    log info "pipx not found, skipping"
    return 0
  fi
  pipx upgrade-all
}

check_pipx() {
  if ! have pipx; then
    return 0
  fi
  pipx list
}
