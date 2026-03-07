# shellcheck shell=bash
plugin_register "uv" "uv tools" "uv" "true"

run_uv() {
  if ! have uv; then
    log info "uv not found, skipping"
    return 0
  fi
  if uv tool list >/dev/null 2>&1; then
    uv tool upgrade --all
  else
    uv self update
  fi
}

check_uv() {
  if ! have uv; then
    return 0
  fi
  if uv tool list >/dev/null 2>&1; then
    uv tool list
  else
    uv --version
  fi
}
