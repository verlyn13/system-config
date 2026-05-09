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

_iterm2_resolved_badge_text=""
_iterm2_resolve_badge_text() {
  _iterm2_resolved_badge_text=""

  if (( ${+ITERM_BADGE_TEXT} )); then
    _iterm2_resolved_badge_text="$ITERM_BADGE_TEXT"
    return 0
  fi

  local nash_root="$HOME/Organizations/the-nash-group"
  [[ "$PWD" == "$nash_root" || "$PWD" == "$nash_root"/* ]] || return 0

  if [[ "${_ITERM2_LAST_BADGE_PWD-}" == "$PWD" ]]; then
    _iterm2_resolved_badge_text="${_ITERM2_LAST_RESOLVED_BADGE_TEXT-}"
    return 0
  fi

  local git_root badge
  git_root="$(command git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" || git_root=""

  if [[ "$git_root" == "$nash_root" ]]; then
    badge=$'\U1F6E1\ufe0f THE GUARDIAN L0'
  elif [[ "$git_root" == "$nash_root"/* ]]; then
    badge="TNG REPO: ${git_root##*/}"
  else
    badge="TNG WORKSPACE"
  fi

  _ITERM2_LAST_BADGE_PWD="$PWD"
  _ITERM2_LAST_RESOLVED_BADGE_TEXT="$badge"
  _iterm2_resolved_badge_text="$badge"
}

_iterm2_emit_badge() {
  # Empty ITERM_BADGE_TEXT explicitly clears the badge; does not fall through to
  # the profile's static Badge Text. Tab color is the primary SSH safety signal.
  _iterm2_resolve_badge_text
  local badge="$_iterm2_resolved_badge_text"
  [[ "${_ITERM2_LAST_BADGE_TEXT-__unset__}" == "$badge" ]] && return 0
  _ITERM2_LAST_BADGE_TEXT="$badge"
  printf '\e]1337;SetBadgeFormat=%s\a' \
    "$(printf '%s' "$badge" | base64 | tr -d '\n')"
}

typeset -ga precmd_functions
precmd_functions=(${precmd_functions:#_iterm2_emit_badge} _iterm2_emit_badge)
