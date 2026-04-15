# shellcheck shell=bash
plugin_register "pipx" "pipx packages" "pipx" "true"

run_pipx() {
  if ! have pipx; then
    log info "pipx not found, skipping"
    return 0
  fi
  local rc=0
  pipx upgrade-all 2>&1 || rc=$?
  if [[ $rc -ne 0 ]]; then
    # pipx exits 1 when any single package fails (e.g. stale interpreter),
    # even if others upgraded successfully. Surface the actionable fix.
    echo "pipx upgrade-all exited $rc (partial failure — see output above)"
    echo "Hint: run 'pipx reinstall-all' to fix stale interpreters after a Python upgrade"
  fi
  return $rc
}

check_pipx() {
  if ! have pipx; then
    return 0
  fi
  pipx list
}
