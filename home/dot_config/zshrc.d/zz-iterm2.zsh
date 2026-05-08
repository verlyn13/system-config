# zz-iterm2.zsh — iTerm2 shell integration + badge emitter
# GATE: interactive-only, iTerm2-only (skipped in agentic to preserve startup budget)
# LOAD ORDER: zz- prefix sorts after 99-local so the vendor hook sees final prompt state

[[ "$NG_MODE" == "agentic" ]] && return 0
[[ -o interactive ]] || return 0
[[ "$TERM_PROGRAM" != "iTerm.app" ]] && return 0

# Vendor script is a host artifact installed by scripts/install-iterm2-shell-integration.sh.
# Missing-file is graceful: shell comes up cleanly offline before the installer is run.
[[ -r "$HOME/.iterm2_shell_integration.zsh" ]] &&
  source "$HOME/.iterm2_shell_integration.zsh"

_iterm2_emit_badge() {
  # Empty ITERM_BADGE_TEXT explicitly clears the badge; does not fall through to
  # the profile's static Badge Text. Tab color is the primary SSH safety signal.
  local badge="${ITERM_BADGE_TEXT:-}"
  [[ "${_ITERM2_LAST_BADGE_TEXT-__unset__}" == "$badge" ]] && return 0
  _ITERM2_LAST_BADGE_TEXT="$badge"
  printf '\e]1337;SetBadgeFormat=%s\a' \
    "$(printf '%s' "$badge" | base64 | tr -d '\n')"
}

typeset -ga precmd_functions
precmd_functions=(${precmd_functions:#_iterm2_emit_badge} _iterm2_emit_badge)
