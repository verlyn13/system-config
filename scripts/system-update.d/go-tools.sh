# shellcheck shell=bash
plugin_register "go-tools" "Go tools (go install)" "go" "false"

run_go-tools() {
  if ! have go; then
    log info "go not found, skipping"
    return 0
  fi
  if [[ ${#SYSTEM_UPDATE_GO_TOOLS[@]} -eq 0 ]]; then
    log info "SYSTEM_UPDATE_GO_TOOLS empty, skipping"
    return 0
  fi
  local tool
  for tool in "${SYSTEM_UPDATE_GO_TOOLS[@]}"; do
    go install "${tool}@latest"
  done
}

check_go-tools() {
  if ! have go; then
    return 0
  fi
  if [[ ${#SYSTEM_UPDATE_GO_TOOLS[@]} -eq 0 ]]; then
    echo "SYSTEM_UPDATE_GO_TOOLS empty"
    return 0
  fi
  printf '%s\n' "${SYSTEM_UPDATE_GO_TOOLS[@]}"
}
