# shellcheck shell=bash
plugin_register "mas" "Mac App Store apps" "mas" "false"

run_mas() {
  if ! have mas; then
    log info "mas not found, skipping"
    return 0
  fi
  mas upgrade
}

check_mas() {
  if ! have mas; then
    return 0
  fi
  mas outdated || true
}
