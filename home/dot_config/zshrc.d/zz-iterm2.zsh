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
_iterm2_resolve_root_badge() {
  local root="$1"
  local root_badge="$2"
  local child_prefix="$3"
  local workspace_badge="$4"

  [[ "$PWD" == "$root" || "$PWD" == "$root"/* ]] || return 1

  local git_root badge
  git_root="$(command git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" || git_root=""

  if [[ "$git_root" == "$root" ]]; then
    badge="$root_badge"
  elif [[ "$git_root" == "$root"/* ]]; then
    badge="${child_prefix}${git_root##*/}"
  else
    badge="$workspace_badge"
  fi

  _iterm2_resolved_badge_text="$badge"
  return 0
}

_iterm2_resolve_jefahnierocks_badge() {
  local root="$1"
  [[ "$PWD" == "$root" || "$PWD" == "$root"/* ]] || return 1

  local git_root repo badge
  git_root="$(command git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" || git_root=""

  if [[ "$git_root" == "$root" ]]; then
    badge=$'\U1F3A8 JEF AHNIE ROCKS \u2022 EXPLORER'
  elif [[ "$git_root" == "$root"/* ]]; then
    repo="${git_root##*/}"
    case "$repo" in
      system-config) badge=$'\u2699\ufe0f SYSTEM CONFIG' ;;
      host-capability-substrate) badge=$'\u25C7 HCS SUBSTRATE' ;;
      flux) badge=$'\u223F FLUX' ;;
      flux-deploy) badge=$'\u21E7 FLUX DEPLOY' ;;
      *) badge=$'\U1F3A8 JEF REPO: '"$repo" ;;
    esac
  else
    badge="JEF WORKSPACE"
  fi

  _iterm2_resolved_badge_text="$badge"
  return 0
}

_iterm2_resolve_happy_patterns_badge() {
  local root="$1"
  [[ "$PWD" == "$root" || "$PWD" == "$root"/* ]] || return 1

  local git_root repo badge
  git_root="$(command git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" || git_root=""

  if [[ "$git_root" == "$root" ]]; then
    badge=$'\u25A3 HAPPY PATTERNS'
  elif [[ "$git_root" == "$root"/* ]]; then
    repo="${git_root#$root/}"
    case "$repo" in
      apps/scopecam) badge=$'\u25CE SCOPECAM' ;;
      apps/happy-patterns-org.github.io) badge=$'\u25A3 HP SITE' ;;
      records) badge=$'\u25A4 HP RECORDS' ;;
      *) badge=$'\u25A3 HP REPO: '"${repo##*/}" ;;
    esac
  else
    badge="HP WORKSPACE"
  fi

  _iterm2_resolved_badge_text="$badge"
  return 0
}

_iterm2_resolve_badge_text() {
  _iterm2_resolved_badge_text=""

  if (( ${+ITERM_BADGE_TEXT} )); then
    _iterm2_resolved_badge_text="$ITERM_BADGE_TEXT"
    return 0
  fi

  local nash_root="$HOME/Organizations/the-nash-group"
  local jefahnierocks_root="$HOME/Organizations/jefahnierocks"
  local happy_patterns_root="$HOME/Organizations/happy-patterns"
  [[ "$PWD" == "$nash_root" || "$PWD" == "$nash_root"/* ||
     "$PWD" == "$jefahnierocks_root" || "$PWD" == "$jefahnierocks_root"/* ||
     "$PWD" == "$happy_patterns_root" || "$PWD" == "$happy_patterns_root"/* ]] || return 0

  if [[ "${_ITERM2_LAST_BADGE_PWD-}" == "$PWD" ]]; then
    _iterm2_resolved_badge_text="${_ITERM2_LAST_RESOLVED_BADGE_TEXT-}"
    return 0
  fi

  _iterm2_resolve_root_badge \
    "$nash_root" \
    $'\U1F6E1\ufe0f THE GUARDIAN L0' \
    "TNG REPO: " \
    "TNG WORKSPACE" ||
    _iterm2_resolve_jefahnierocks_badge "$jefahnierocks_root" ||
    _iterm2_resolve_happy_patterns_badge "$happy_patterns_root"

  _ITERM2_LAST_BADGE_PWD="$PWD"
  _ITERM2_LAST_RESOLVED_BADGE_TEXT="$_iterm2_resolved_badge_text"
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
