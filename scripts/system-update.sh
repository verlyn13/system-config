#!/usr/bin/env bash
# system-update.sh — Unified system update command
# Updates Homebrew, npm globals, pip packages, Claude Code, gh extensions,
# mise runtimes, and any plugins in system-update.d/
#
# Usage: system-update [--check] [--strict] [--no-cleanup] [--verbose] [--debug]
#                    [--list] [--only <ids>] [--skip <ids>] [--notify] [--json]
#                    [--config <path>] [--no-plugins]
#   (default)      keep-going update, quiet console output
#   --check        dry-run / show what's outdated
#   --strict       fail-fast on first error
#   --no-cleanup   skip cleanup step
#   --verbose      show step headers and summaries inline
#   --debug        full diagnostic output (all command output on console)
#   --list         list steps and plugins, then exit
#   --only <ids>   run only specified step IDs (comma-separated)
#   --skip <ids>   skip specified step IDs (comma-separated)
#   --notify       send OS notification on completion (macOS)
#   --json         emit JSON summary to stdout at end
#   --config <path> load config file (overrides defaults, CLI still wins)
#   --no-plugins   skip loading plugins in system-update.d/

set -uo pipefail

# =============================================================================
# Constants
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="${SCRIPT_DIR}/system-update.d"
LOG_DIR="${HOME}/Library/Logs/system-update"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/run-${RUN_ID}.log"
NDJSON_FILE="${LOG_DIR}/run-${RUN_ID}.ndjson"
LOCK_FILE="${LOG_DIR}/system-update.lock"
CONFIG_DIR="${HOME}/.config/system-update"
CONFIG_FILE_DEFAULT="${CONFIG_DIR}/config"
CONFIG_D_DIR="${CONFIG_DIR}/config.d"

# =============================================================================
# Parse flags + config
# =============================================================================

MODE="update"
STRICT=false
NO_CLEANUP=false
VERBOSE=false
DEBUG=false
LIST_ONLY=false
NOTIFY=false
JSON_SUMMARY=false
NO_PLUGINS=false
CONFIG_PATH=""

ONLY_RAW=""
SKIP_RAW=""

SYSTEM_UPDATE_ONLY_ENV="${SYSTEM_UPDATE_ONLY:-}"
SYSTEM_UPDATE_SKIP_ENV="${SYSTEM_UPDATE_SKIP:-}"
SYSTEM_UPDATE_ENABLE_ENV="${SYSTEM_UPDATE_ENABLE:-}"
SYSTEM_UPDATE_DISABLE_ENV="${SYSTEM_UPDATE_DISABLE:-}"
SYSTEM_UPDATE_STEP_ORDER_ENV="${SYSTEM_UPDATE_STEP_ORDER:-}"
SYSTEM_UPDATE_PIP_PACKAGES_ENV="${SYSTEM_UPDATE_PIP_PACKAGES:-}"
SYSTEM_UPDATE_GO_TOOLS_ENV="${SYSTEM_UPDATE_GO_TOOLS:-}"

declare -a SYSTEM_UPDATE_ENABLE=()
declare -a SYSTEM_UPDATE_DISABLE=()
declare -a SYSTEM_UPDATE_ONLY=()
declare -a SYSTEM_UPDATE_SKIP=()
declare -a SYSTEM_UPDATE_STEP_ORDER=()
declare -a SYSTEM_UPDATE_PIP_PACKAGES=()
declare -a SYSTEM_UPDATE_GO_TOOLS=()

print_help() {
  sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
}

parse_config_flag() {
  local arg next
  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --config)
        next="${2:-}"
        if [[ -z "$next" ]]; then
          echo "Missing value for --config" >&2
          exit 1
        fi
        CONFIG_PATH="$next"
        shift 2 || true
        ;;
      --config=*)
        CONFIG_PATH="${arg#*=}"
        shift
        ;;
      --help|-h)
        print_help
        exit 0
        ;;
      *)
        shift
        ;;
    esac
  done
}

load_config() {
  local path="$1"
  if [[ -n "$path" ]]; then
    if [[ -f "$path" ]]; then
      # shellcheck disable=SC1090
      source "$path"
    else
      echo "Config not found: $path" >&2
      exit 1
    fi
    return 0
  fi

  if [[ -f "${CONFIG_FILE_DEFAULT}" ]]; then
    # shellcheck disable=SC1090
    source "${CONFIG_FILE_DEFAULT}"
  fi

  if [[ -d "${CONFIG_D_DIR}" ]]; then
    local f
    while IFS= read -r -d '' f; do
      # shellcheck disable=SC1090
      source "$f"
    done < <(find "${CONFIG_D_DIR}" -maxdepth 1 -name '*.sh' -print0 2>/dev/null | sort -z)
  fi
}

parse_flags() {
  local arg next
  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --check)      MODE="check" ;;
      --strict)     STRICT=true ;;
      --no-cleanup) NO_CLEANUP=true ;;
      --verbose)    VERBOSE=true ;;
      --debug)      DEBUG=true; VERBOSE=true ;;
      --list)       LIST_ONLY=true ;;
      --notify)     NOTIFY=true ;;
      --json)       JSON_SUMMARY=true ;;
      --no-plugins) NO_PLUGINS=true ;;
      --only)
        next="${2:-}"
        if [[ -z "$next" ]]; then
          echo "Missing value for --only (expected comma-separated step ids)" >&2
          exit 1
        fi
        ONLY_RAW="${ONLY_RAW:+${ONLY_RAW},}${next}"
        shift
        ;;
      --only=*)
        ONLY_RAW="${ONLY_RAW:+${ONLY_RAW},}${arg#*=}"
        ;;
      --skip)
        next="${2:-}"
        if [[ -z "$next" ]]; then
          echo "Missing value for --skip (expected comma-separated step ids)" >&2
          exit 1
        fi
        SKIP_RAW="${SKIP_RAW:+${SKIP_RAW},}${next}"
        shift
        ;;
      --skip=*)
        SKIP_RAW="${SKIP_RAW:+${SKIP_RAW},}${arg#*=}"
        ;;
      --config)
        # consumed by pre-parse; skip the value argument too
        shift
        ;;
      --config=*)
        # consumed by pre-parse (single token, no extra shift needed)
        ;;
      --help|-h)
        print_help
        exit 0
        ;;
      *)
        echo "Unknown flag: $arg (try --help)" >&2
        exit 1
        ;;
    esac
    shift || true
  done
}

parse_config_flag "$@"
load_config "${CONFIG_PATH:-${SYSTEM_UPDATE_CONFIG:-}}"
parse_flags "$@"

# Check mode implies verbose (output IS the point)
[[ "$MODE" == "check" ]] && VERBOSE=true

# Config defaults (post-load, pre-use)
: "${SYSTEM_UPDATE_ENABLE_PLUGINS:=true}"
: "${SYSTEM_UPDATE_NOTIFY:=false}"
: "${SYSTEM_UPDATE_JSON:=false}"

# NOTE: normalize_config_arrays and bool_true are called after helpers are
# defined (see "Post-config initialization" section below).

# =============================================================================
# Normalize PATH
# =============================================================================

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${HOME}/.local/bin:${HOME}/.npm-global/bin:${PATH}"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash --shims 2>/dev/null)" || true
fi

# =============================================================================
# Color codes — $'...' ANSI C quoting for real ESC bytes
# =============================================================================

mkdir -p "${LOG_DIR}"

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'
  C_GREEN=$'\033[0;32m'
  C_YELLOW=$'\033[0;33m'
  C_RED=$'\033[0;31m'
  C_DIM=$'\033[0;2m'
  C_BOLD=$'\033[1m'
else
  C_RESET='' C_GREEN='' C_YELLOW='' C_RED='' C_DIM='' C_BOLD=''
fi

# =============================================================================
# Logging infrastructure — FD 3 = transcript, stdout = console
# =============================================================================

# FD 3: dedicated transcript log (full output always)
exec 3>>"${LOG_FILE}"

# Console-only output
# shellcheck disable=SC2059  # format string is always a caller-supplied literal
consolef() { printf "$@"; }

# Transcript-only output
# shellcheck disable=SC2059  # format string is always a caller-supplied literal
transcriptf() { printf "$@" >&3; }

# Log to both transcript and (selectively) console
log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts="$(date +%H:%M:%S)"

  # Always write to transcript
  printf "[%s] [%s] %s\n" "$ts" "$level" "$msg" >&3

  # Console output based on level + verbosity
  case "$level" in
    error)
      [[ -t 1 ]] && printf '\r\033[K'  # clear any progress indicator
      consolef "${C_RED}ERROR: %s${C_RESET}\n" "$msg" ;;
    warn)
      $VERBOSE && consolef "${C_YELLOW}WARN: %s${C_RESET}\n" "$msg" ;;
    info)
      $VERBOSE && consolef "${C_DIM}%s${C_RESET}\n" "$msg" ;;
    debug)
      $DEBUG && consolef "${C_DIM}DEBUG: %s${C_RESET}\n" "$msg" ;;
    step)
      $VERBOSE && consolef "${C_DIM}→ %s${C_RESET}\n" "$msg" ;;
  esac
}

ndjson() {
  local level="$1" event="$2" msg="$3"
  local extra="${4:-}"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local safe_msg
  safe_msg="${msg//\\/\\\\}"
  safe_msg="${safe_msg//\"/\\\"}"
  safe_msg="${safe_msg//$'\n'/\\n}"
  if [[ -n "$extra" ]]; then
    printf '{"ts":"%s","run_id":"%s","level":"%s","event":"%s","msg":"%s",%s}\n' \
      "$ts" "$RUN_ID" "$level" "$event" "$safe_msg" "$extra" >> "${NDJSON_FILE}"
  else
    printf '{"ts":"%s","run_id":"%s","level":"%s","event":"%s","msg":"%s"}\n' \
      "$ts" "$RUN_ID" "$level" "$event" "$safe_msg" >> "${NDJSON_FILE}"
  fi
}

# =============================================================================
# Locking
# =============================================================================

acquire_lock() {
  if command -v flock >/dev/null 2>&1; then
    exec 9>"${LOCK_FILE}"
    if ! flock -n 9; then
      log error "Another system-update is already running (flock)."
      exit 1
    fi
  else
    if [[ -f "${LOCK_FILE}.pid" ]]; then
      local old_pid
      old_pid="$(cat "${LOCK_FILE}.pid" 2>/dev/null)"
      if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
        log error "Another system-update is already running (PID ${old_pid})."
        exit 1
      fi
      rm -f "${LOCK_FILE}.pid"
    fi
    echo $$ > "${LOCK_FILE}.pid"
    trap 'rm -f "${LOCK_FILE}.pid"' EXIT
  fi
}

acquire_lock

# =============================================================================
# Signal handling — clean up temp files and lock on interrupt
# =============================================================================

_cleanup_on_exit() {
  rm -f "${LOCK_FILE}.pid" 2>/dev/null
  # Clean any leftover temp files from run_step
  rm -f /tmp/tmp.system-update.* 2>/dev/null
}
trap '_cleanup_on_exit' EXIT
trap 'echo ""; log warn "Interrupted (SIGINT)"; _cleanup_on_exit; exit 130' INT
trap 'log warn "Terminated (SIGTERM)"; _cleanup_on_exit; exit 143' TERM

# =============================================================================
# Helpers
# =============================================================================

have() { command -v "$1" >/dev/null 2>&1; }

NOTICES=()
ACTION_ITEMS=()
add_notice() { NOTICES+=("$1"); }
add_action() { ACTION_ITEMS+=("$1"); }

bool_true() {
  case "${1:-}" in
    1|true|yes|on|y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

split_csv() {
  local input="$1"
  local out=()
  local part
  IFS=',' read -r -a out <<< "$input"
  for part in "${out[@]}"; do
    part="$(trim "$part")"
    [[ -n "$part" ]] && printf '%s\n' "$part"
  done
}

# =============================================================================
# Step registry
# =============================================================================

declare -A STEP_DESC=()
declare -A STEP_FUNC=()
declare -A STEP_REQUIRES=()
declare -A STEP_KIND=()
declare -A STEP_DEFAULT=()
declare -A STEP_ALIAS=()
declare -A STEP_ENABLED=()
declare -a STEP_ORDER=()

declare -A PLUGIN_DESC=()
declare -A PLUGIN_REQUIRES=()
declare -A PLUGIN_DEFAULT=()

register_step() {
  local id="$1" name="$2" func="$3" requires="$4" default="$5" kind="$6"
  STEP_DESC["$id"]="$name"
  STEP_FUNC["$id"]="$func"
  STEP_REQUIRES["$id"]="$requires"
  STEP_KIND["$id"]="$kind"
  STEP_DEFAULT["$id"]="$default"
  STEP_ORDER+=("$id")
}

plugin_register() {
  local name="$1" desc="${2:-}" requires="${3:-}" default="${4:-true}"
  PLUGIN_DESC["$name"]="$desc"
  PLUGIN_REQUIRES["$name"]="$requires"
  PLUGIN_DEFAULT["$name"]="$default"
}

register_plugin_step() {
  local pname="$1"
  local id="plugin:${pname}"
  local desc="${PLUGIN_DESC[$pname]:-plugin:${pname}}"
  local requires="${PLUGIN_REQUIRES[$pname]:-}"
  local default="${PLUGIN_DEFAULT[$pname]:-true}"
  register_step "$id" "plugin:${pname}" "run_plugin_${pname}" "$requires" "$default" "plugin"
  STEP_ALIAS["$pname"]="$id"
  STEP_DESC["$id"]="${desc}"
}

resolve_step_id() {
  local token="$1"
  if [[ -n "${STEP_DESC[$token]:-}" ]]; then
    printf '%s' "$token"
    return 0
  fi
  if [[ -n "${STEP_ALIAS[$token]:-}" ]]; then
    printf '%s' "${STEP_ALIAS[$token]}"
    return 0
  fi
  # allow matching display name
  for id in "${STEP_ORDER[@]}"; do
    if [[ "${STEP_DESC[$id]}" == "$token" ]]; then
      printf '%s' "$id"
      return 0
    fi
  done
  return 1
}

normalize_config_arrays() {
  if [[ ${#SYSTEM_UPDATE_ONLY[@]} -eq 0 && -n "$SYSTEM_UPDATE_ONLY_ENV" ]]; then
    while IFS= read -r t; do SYSTEM_UPDATE_ONLY+=("$t"); done < <(split_csv "$SYSTEM_UPDATE_ONLY_ENV")
  fi
  if [[ ${#SYSTEM_UPDATE_SKIP[@]} -eq 0 && -n "$SYSTEM_UPDATE_SKIP_ENV" ]]; then
    while IFS= read -r t; do SYSTEM_UPDATE_SKIP+=("$t"); done < <(split_csv "$SYSTEM_UPDATE_SKIP_ENV")
  fi
  if [[ ${#SYSTEM_UPDATE_ENABLE[@]} -eq 0 && -n "$SYSTEM_UPDATE_ENABLE_ENV" ]]; then
    while IFS= read -r t; do SYSTEM_UPDATE_ENABLE+=("$t"); done < <(split_csv "$SYSTEM_UPDATE_ENABLE_ENV")
  fi
  if [[ ${#SYSTEM_UPDATE_DISABLE[@]} -eq 0 && -n "$SYSTEM_UPDATE_DISABLE_ENV" ]]; then
    while IFS= read -r t; do SYSTEM_UPDATE_DISABLE+=("$t"); done < <(split_csv "$SYSTEM_UPDATE_DISABLE_ENV")
  fi
  if [[ ${#SYSTEM_UPDATE_STEP_ORDER[@]} -eq 0 && -n "$SYSTEM_UPDATE_STEP_ORDER_ENV" ]]; then
    while IFS= read -r t; do SYSTEM_UPDATE_STEP_ORDER+=("$t"); done < <(split_csv "$SYSTEM_UPDATE_STEP_ORDER_ENV")
  fi
  if [[ ${#SYSTEM_UPDATE_PIP_PACKAGES[@]} -eq 0 && -n "$SYSTEM_UPDATE_PIP_PACKAGES_ENV" ]]; then
    while IFS= read -r t; do SYSTEM_UPDATE_PIP_PACKAGES+=("$t"); done < <(split_csv "$SYSTEM_UPDATE_PIP_PACKAGES_ENV")
  fi
  if [[ ${#SYSTEM_UPDATE_GO_TOOLS[@]} -eq 0 && -n "$SYSTEM_UPDATE_GO_TOOLS_ENV" ]]; then
    while IFS= read -r t; do SYSTEM_UPDATE_GO_TOOLS+=("$t"); done < <(split_csv "$SYSTEM_UPDATE_GO_TOOLS_ENV")
  fi
}

# =============================================================================
# Post-config initialization (requires helpers above)
# =============================================================================

normalize_config_arrays

if [[ ${#SYSTEM_UPDATE_PIP_PACKAGES[@]} -eq 0 ]]; then
  SYSTEM_UPDATE_PIP_PACKAGES=(huggingface_hub)
fi

if bool_true "${SYSTEM_UPDATE_NOTIFY}"; then
  NOTIFY=true
fi
if bool_true "${SYSTEM_UPDATE_JSON}"; then
  JSON_SUMMARY=true
fi
if ! bool_true "${SYSTEM_UPDATE_ENABLE_PLUGINS}"; then
  NO_PLUGINS=true
fi

step_available() {
  local id="$1"
  local requires="${STEP_REQUIRES[$id]:-}"
  local cmd
  for cmd in $requires; do
    if [[ "$cmd" == *"|"* ]]; then
      local ok=false
      local opt
      local -a opts
      IFS='|' read -r -a opts <<< "$cmd"
      for opt in "${opts[@]}"; do
        if have "$opt"; then
          ok=true
          break
        fi
      done
      $ok || return 1
    else
      if ! have "$cmd"; then
        return 1
      fi
    fi
  done
  return 0
}

apply_step_order_override() {
  if [[ ${#SYSTEM_UPDATE_STEP_ORDER[@]} -eq 0 ]]; then
    return 0
  fi

  local new_order=()
  local -A seen=()
  local token id

  for token in "${SYSTEM_UPDATE_STEP_ORDER[@]}"; do
    if id="$(resolve_step_id "$token")"; then
      if [[ -z "${seen[$id]:-}" ]]; then
        new_order+=("$id")
        seen["$id"]=1
      fi
    else
      echo "Unknown step id in SYSTEM_UPDATE_STEP_ORDER: $token" >&2
      exit 1
    fi
  done

  for id in "${STEP_ORDER[@]}"; do
    if [[ -z "${seen[$id]:-}" ]]; then
      new_order+=("$id")
      seen["$id"]=1
    fi
  done

  STEP_ORDER=("${new_order[@]}")
}

collect_only_skip() {
  ONLY_TOKENS=()
  SKIP_TOKENS=()

  local t
  if [[ -n "$ONLY_RAW" ]]; then
    while IFS= read -r t; do ONLY_TOKENS+=("$t"); done < <(split_csv "$ONLY_RAW")
  else
    for t in "${SYSTEM_UPDATE_ONLY[@]}"; do ONLY_TOKENS+=("$t"); done
  fi

  for t in "${SYSTEM_UPDATE_SKIP[@]}"; do SKIP_TOKENS+=("$t"); done
  if [[ -n "$SKIP_RAW" ]]; then
    while IFS= read -r t; do SKIP_TOKENS+=("$t"); done < <(split_csv "$SKIP_RAW")
  fi
}

resolve_tokens_to_ids() {
  local token id
  local invalid=0
  for token in "$@"; do
    if id="$(resolve_step_id "$token")"; then
      printf '%s\n' "$id"
    else
      echo "Unknown step id: $token" >&2
      invalid=1
    fi
  done
  return $invalid
}

compute_step_enabled() {
  local id
  for id in "${STEP_ORDER[@]}"; do
    STEP_ENABLED["$id"]="false"
    if bool_true "${STEP_DEFAULT[$id]:-false}"; then
      STEP_ENABLED["$id"]="true"
    fi
  done

  if [[ ${#SYSTEM_UPDATE_ENABLE[@]} -gt 0 ]]; then
    local enable_ids=()
    while IFS= read -r id; do enable_ids+=("$id"); done < <(resolve_tokens_to_ids "${SYSTEM_UPDATE_ENABLE[@]}") || exit 1
    for id in "${enable_ids[@]}"; do
      STEP_ENABLED["$id"]="true"
    done
  fi
  if [[ ${#SYSTEM_UPDATE_DISABLE[@]} -gt 0 ]]; then
    local disable_ids=()
    while IFS= read -r id; do disable_ids+=("$id"); done < <(resolve_tokens_to_ids "${SYSTEM_UPDATE_DISABLE[@]}") || exit 1
    for id in "${disable_ids[@]}"; do
      STEP_ENABLED["$id"]="false"
    done
  fi

  collect_only_skip

  if [[ ${#ONLY_TOKENS[@]} -gt 0 ]]; then
    local only_ids=()
    while IFS= read -r id; do only_ids+=("$id"); done < <(resolve_tokens_to_ids "${ONLY_TOKENS[@]}") || exit 1
    for id in "${STEP_ORDER[@]}"; do
      STEP_ENABLED["$id"]="false"
    done
    for id in "${only_ids[@]}"; do
      STEP_ENABLED["$id"]="true"
    done
  fi

  if [[ ${#SKIP_TOKENS[@]} -gt 0 ]]; then
    local skip_ids=()
    while IFS= read -r id; do skip_ids+=("$id"); done < <(resolve_tokens_to_ids "${SKIP_TOKENS[@]}") || exit 1
    for id in "${skip_ids[@]}"; do
      STEP_ENABLED["$id"]="false"
    done
  fi
}

print_step_list() {
  consolef "${C_BOLD}system-update steps${C_RESET}\n"
  local id status kind desc requires req_status
  for id in "${STEP_ORDER[@]}"; do
    kind="${STEP_KIND[$id]}"
    desc="${STEP_DESC[$id]}"
    status="disabled"
    [[ "${STEP_ENABLED[$id]}" == "true" ]] && status="enabled"
    if step_available "$id"; then
      req_status=""
    else
      requires="${STEP_REQUIRES[$id]}"
      req_status=" (missing: ${requires})"
    fi
    consolef " - %-16s %-8s %-6s %s%s\n" "$id" "$status" "$kind" "$desc" "$req_status"
  done
}

# =============================================================================
# Step summarizer — returns short detail string for status line
# =============================================================================

summarize_step() {
  local name="$1" tmp="$2" rc="$3"
  local detail=""

  case "$name" in
    "Homebrew index")
      [[ $rc -eq 0 ]] && detail="up to date"
      ;;

    "Homebrew formulae")
      if [[ "$MODE" == "check" ]]; then
        local count
        count="$(grep -c . "$tmp" 2>/dev/null || true)"
        if [[ "$count" -gt 0 ]]; then
          detail="${count} outdated"
        else
          detail="all up to date"
        fi
      elif [[ $rc -eq 0 ]]; then
        local upgraded
        upgraded="$(grep -ciE '==> Upgrading|Pouring' "$tmp" 2>/dev/null || true)"
        if [[ "$upgraded" -gt 0 ]]; then
          detail="upgraded ${upgraded} formulae"
        else
          detail="no changes"
        fi
      fi
      ;;

    "npm globals")
      if [[ "$MODE" == "check" ]]; then
        local count
        count="$(tail -n +2 "$tmp" | grep -c . 2>/dev/null || true)"
        if [[ "$count" -gt 0 ]]; then
          detail="${count} outdated"
        else
          detail="all up to date"
        fi
      else
        local changed dep_count
        changed="$(grep -oE 'changed [0-9]+ packages' "$tmp" 2>/dev/null | tail -1 || true)"
        dep_count="$(grep -c '^npm warn deprecated' "$tmp" 2>/dev/null || true)"
        local parts=()
        [[ -n "$changed" ]] && parts+=("$changed")
        [[ "$dep_count" -gt 0 ]] && parts+=("${dep_count} deprecations")
        if [[ ${#parts[@]} -gt 0 ]]; then
          local IFS=' · '
          detail="${parts[*]}"
        else
          detail="up to date"
        fi
      fi
      ;;

    "pip packages")
      if [[ "$MODE" == "check" ]]; then
        local installed missing
        installed="$(grep -c ' installed$' "$tmp" 2>/dev/null || true)"
        missing="$(grep -c ' not installed$' "$tmp" 2>/dev/null || true)"
        if [[ "$installed" -gt 0 || "$missing" -gt 0 ]]; then
          detail="installed ${installed}, missing ${missing}"
        else
          detail="checked"
        fi
      elif grep -q 'Successfully installed' "$tmp" 2>/dev/null; then
        local count
        count="$(grep -oE 'Successfully installed .*' "$tmp" | tail -1 | awk '{print NF-2}' 2>/dev/null || true)"
        detail="updated${count:+ (${count} packages)}"
      elif grep -qi 'already satisfied' "$tmp" 2>/dev/null; then
        detail="up to date"
      else
        detail="completed"
      fi
      ;;

    "Claude Code")
      if [[ $rc -eq 0 ]]; then
        local ver
        ver="$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$tmp" | tail -1)"
        if grep -q "successfully updated" "$tmp" 2>/dev/null; then
          detail="updated${ver:+ to $ver}"
        else
          detail="up to date${ver:+ ($ver)}"
        fi
      fi
      ;;

    "gh extensions")
      if [[ $rc -eq 0 ]]; then
        if grep -qi 'upgraded\|updated' "$tmp" 2>/dev/null; then
          detail="extensions updated"
        else
          detail="all up to date"
        fi
      fi
      ;;

    "mise runtimes")
      if [[ "$MODE" == "check" ]]; then
        # Only count lines after the action marker (skip mise current output)
        local count
        count="$(sed -n '/^--- mise action ---$/,$ p' "$tmp" | tail -n +2 | grep -c . 2>/dev/null || true)"
        if [[ "$count" -gt 0 ]]; then
          detail="${count} outdated"
        else
          detail="all up to date"
        fi
      elif grep -qi 'All tools are up to date\|no outdated' "$tmp" 2>/dev/null; then
        detail="all up to date"
      elif grep -qE 'upgraded [0-9]+ tool' "$tmp" 2>/dev/null; then
        local n
        n="$(grep -oE 'upgraded [0-9]+ tool' "$tmp" | grep -oE '[0-9]+')"
        detail="upgraded ${n} tool(s)"
      else
        detail="completed"
      fi
      ;;

    "Cleanup")
      [[ $rc -eq 0 ]] && detail="complete"
      ;;

    *)
      [[ $rc -eq 0 ]] && detail="completed" || detail="exit ${rc}"
      ;;
  esac

  echo "$detail"
}

# Collect notices from step output (runs in parent shell, CAN modify NOTICES)
collect_notices() {
  local name="$1" tmp="$2" rc="$3"
  case "$name" in
    "npm globals")
      local dep_count
      dep_count="$(grep -c '^npm warn deprecated' "$tmp" 2>/dev/null || true)"
      if [[ "$dep_count" -gt 0 ]]; then
        add_notice "npm: ${dep_count} deprecation warnings (see log, or rerun with --debug)"
      fi
      ;;
    "pip packages")
      if grep -qi 'new release of pip is available' "$tmp" 2>/dev/null; then
        add_notice "pip: new version available (update with: pip install -U pip)"
      fi
      ;;
    "Homebrew formulae")
      local restart_lines
      restart_lines="$(grep -ciE 'brew services restart|restart .* after' "$tmp" 2>/dev/null || true)"
      if [[ "$restart_lines" -gt 0 ]]; then
        add_notice "brew: service(s) may need restart (see log)"
      fi
      ;;
  esac
}

# Show failure hint: minimal by default, verbose in --debug
show_failure_hint() {
  local name="$1" tmp="$2"
  add_notice "${name}: failed (see log or rerun with --debug)"
  if $DEBUG; then
    consolef "${C_DIM}--- %s (last 40 lines) ---${C_RESET}\n" "$name"
    tail -n 40 "$tmp"
    consolef "${C_DIM}---------------------------${C_RESET}\n"
  fi
}

# Scrape actionable items (targeted patterns only)
scrape_actions() {
  local name="$1" tmp="$2"
  local line
  while IFS= read -r line; do
    add_action "${name}: ${line}"
  done < <(
    grep -iE 'brew services restart|To restart|restart .* after an upgrade' "$tmp" 2>/dev/null \
      | sed 's/^[[:space:]]*//' \
      | head -5
  )
}

# =============================================================================
# Step runner — capture output, classify, print status line
# =============================================================================

STEP_RESULTS=()
TOTAL_START="${EPOCHSECONDS:-$(date +%s)}"
CURRENT_STEP_ID=""
SUMMARY_FAILURES=0
SUMMARY_WARNINGS=0
SUMMARY_DURATION=0

run_step() {
  local name="$1"; shift
  local tmp rc=0 start_ts end_ts duration
  tmp="$(mktemp /tmp/tmp.system-update.XXXXXX)"
  start_ts="$(date +%s)"

  # Progress indicator (TTY, non-verbose default mode)
  local use_progress=false
  if [[ -t 1 ]] && ! $VERBOSE; then
    use_progress=true
    printf '\r%s→ %s...%s' "${C_DIM}" "$name" "${C_RESET}"
  fi

  log step "$name"
  ndjson info step_start "$name" "\"cmd\":\"$*\""

  # Run: capture stdout+stderr to temp file only
  ("$@") >"$tmp" 2>&1 || rc=$?

  end_ts="$(date +%s)"
  duration=$(( end_ts - start_ts ))

  # Always append full output to transcript
  transcriptf "\n=== %s (exit %d, %ds) ===\n" "$name" "$rc" "$duration"
  cat "$tmp" >&3

  # Console: show full output in debug or check mode
  if $DEBUG || [[ "$MODE" == "check" ]]; then
    cat "$tmp"
  fi

  # Get summary detail (subshell — read-only)
  local detail
  detail="$(summarize_step "$name" "$tmp" "$rc")"

  # Collect notices (parent shell — writes NOTICES array)
  collect_notices "$name" "$tmp" "$rc"

  # Classify and record result
  local step_id="${CURRENT_STEP_ID:-$name}"

  if [[ $rc -eq 0 ]]; then
    ndjson info step_ok "$name" "\"duration\":${duration}"
    STEP_RESULTS+=("${step_id}|${name}|ok|${duration}|${detail}")
  else
    local status="fail"
    if grep -qiE 'Upgraded [0-9]+ tool|Successfully installed|changed [0-9]+ package|already satisfied' "$tmp" 2>/dev/null; then
      status="warn"
    fi

    if [[ "$status" == "warn" ]]; then
      ndjson warn step_warn "$name" "\"exit_code\":${rc},\"duration\":${duration}"
      STEP_RESULTS+=("${step_id}|${name}|warn|${duration}|${detail}")
    else
      ndjson error step_fail "$name" "\"exit_code\":${rc},\"duration\":${duration}"
      STEP_RESULTS+=("${step_id}|${name}|fail|${duration}|${detail}")
      if $STRICT; then
        # Clear progress indicator before error output
        $use_progress && printf '\r\033[K'
        log error "${name} failed (exit ${rc}, ${duration}s) — aborting (--strict)"
        show_failure_hint "$name" "$tmp"
        consolef "${C_RED}✗ %-22s %3ds  %s${C_RESET}\n" "$name" "$duration" "${detail:-exit $rc}"
        rm -f "$tmp"
        print_summary
        exit "$rc"
      else
        show_failure_hint "$name" "$tmp"
      fi
    fi
  fi

  # Scrape action items
  scrape_actions "$name" "$tmp"
  rm -f "$tmp"

  # Clear progress indicator
  $use_progress && printf '\r\033[K'

  # Print status line
  local icon color
  local last="${STEP_RESULTS[-1]}"
  local s_status
  IFS='|' read -r _ _ s_status _ _ <<< "$last"

  case "$s_status" in
    ok)   icon="✓"; color="$C_GREEN" ;;
    warn) icon="⚠"; color="$C_YELLOW" ;;
    fail) icon="✗"; color="$C_RED" ;;
    *)    icon="?"; color="$C_DIM" ;;
  esac

  if [[ -n "$detail" ]]; then
    consolef "%s%s %-22s %3ds  %s%s\n" "$color" "$icon" "$name" "$duration" "$detail" "$C_RESET"
  else
    consolef "%s%s %-22s %3ds%s\n" "$color" "$icon" "$name" "$duration" "$C_RESET"
  fi
}

run_step_by_id() {
  local id="$1"
  local name="${STEP_DESC[$id]}"
  local func="${STEP_FUNC[$id]}"
  if [[ -z "$func" ]]; then
    log warn "No function registered for step ${id}"
    return 1
  fi
  CURRENT_STEP_ID="$id"
  run_step "$name" "$func"
  CURRENT_STEP_ID=""
}

record_skipped_step() {
  local id="$1" reason="$2"
  local name="${STEP_DESC[$id]}"
  STEP_RESULTS+=("${id}|${name}|warn|0|${reason}")
  add_notice "${name}: skipped (${reason})"
  consolef "%s⚠ %-22s %3ds  %s%s\n" "$C_YELLOW" "$name" 0 "$reason" "$C_RESET"
}

# =============================================================================
# Context snapshot — compact tools line (full table in --debug)
# =============================================================================

context_snapshot() {
  local strict_desc=""
  $STRICT && strict_desc="strict" || strict_desc="non-strict"

  consolef "${C_BOLD}system-update${C_RESET} %s  ${C_DIM}(%s · %s)${C_RESET}\n" \
    "$RUN_ID" "$MODE" "$strict_desc"
  ndjson info run_start "system-update" "\"mode\":\"${MODE}\",\"strict\":${STRICT}"

  # Collect tool versions
  local parts=()
  local tools=(brew mise node npm python3 gh claude)
  for t in "${tools[@]}"; do
    if have "$t"; then
      local ver="" loc
      loc="$(command -v "$t")"
      case "$t" in
        brew)    ver="$(brew --version 2>/dev/null | head -1 | awk '{print $2}' | cut -d- -f1)" ;;
        mise)    ver="$(mise --version 2>/dev/null | awk '{print $1}')" ;;
        node)    ver="$(node -v 2>/dev/null | sed 's/^v//')" ;;
        npm)     ver="$(npm -v 2>/dev/null)" ;;
        python3) ver="$(python3 --version 2>/dev/null | awk '{print $2}')" ;;
        gh)      ver="$(gh --version 2>/dev/null | head -1 | awk '{print $3}')" ;;
        claude)  ver="$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')" ;;
      esac

      local short="$t"
      [[ "$t" == "python3" ]] && short="py"
      parts+=("${short} ${ver}")

      # Full path always in transcript + NDJSON
      transcriptf "  %-10s %s  %s\n" "$t" "$loc" "$ver"
      ndjson info tool_resolved "$t" "\"path\":\"${loc}\",\"version\":\"${ver}\""

      # Full table on console only in --debug
      $DEBUG && consolef "  ${C_DIM}%-10s %s  %s${C_RESET}\n" "$t" "$loc" "$ver"
    else
      transcriptf "  %-10s not found\n" "$t"
      $DEBUG && consolef "  ${C_DIM}%-10s not found${C_RESET}\n" "$t"
    fi
  done

  # Compact one-liner (default + verbose, not debug since debug shows full table)
  if ! $DEBUG; then
    local tools_line="${parts[0]}"
    for ((i=1; i<${#parts[@]}; i++)); do
      tools_line="${tools_line} · ${parts[$i]}"
    done
    consolef "${C_DIM}tools: %s${C_RESET}\n" "$tools_line"
  fi

  # Extra debug context
  if $DEBUG; then
    have npm && log debug "npm prefix: $(npm config get prefix 2>/dev/null)"
    have python3 && log debug "pip: $(python3 -m pip --version 2>/dev/null)"
    have brew && log debug "brew prefix: $(brew --prefix 2>/dev/null)"
    have mise && log debug "mise current: $(mise current 2>/dev/null)"
  fi

  consolef "\n"
}

# =============================================================================
# Update steps
# =============================================================================

step_brew_index() {
  if ! have brew; then echo "brew not found, skipping"; return 0; fi
  if [[ "$MODE" == "check" ]]; then
    brew update --quiet
  else
    brew update
  fi
}

step_brew_formulae() {
  if ! have brew; then return 0; fi
  if [[ "$MODE" == "check" ]]; then
    brew outdated --formula || true
  else
    brew upgrade --formula
  fi
}

step_npm_globals() {
  if ! have npm; then echo "npm not found, skipping"; return 0; fi
  if [[ "$MODE" == "check" ]]; then
    npm -g outdated --long 2>&1 || true
  else
    npm update -g 2>&1
  fi
}

step_pip_packages() {
  if ! have python3; then echo "python3 not found, skipping"; return 0; fi
  local packages=("${SYSTEM_UPDATE_PIP_PACKAGES[@]}")
  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "pip packages list empty, skipping"
    return 0
  fi

  # Clear any active virtualenv so mise's python is used, not a stale .venv
  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    PATH="${PATH//"${VIRTUAL_ENV}/bin:"/}"
    unset VIRTUAL_ENV
  fi
  unset CONDA_PREFIX

  # Run from $HOME to avoid project-level .mise.toml files that may activate
  # a venv (e.g. ComfyUI's _.python.venv) and shadow the global Python.
  local pip_cmd=(python -m pip)
  if have mise; then
    pip_cmd=(env -C "$HOME" mise exec python -- python -m pip)
  else
    echo "mise not found, using bare python3 for pip"
    pip_cmd=(python3 -m pip)
  fi

  if [[ "$MODE" == "check" ]]; then
    local pkg ver
    for pkg in "${packages[@]}"; do
      ver="$("${pip_cmd[@]}" show "$pkg" 2>/dev/null | awk -F': ' '/^Version:/{print $2; exit}')"
      if [[ -n "$ver" ]]; then
        echo "${pkg} ${ver} installed"
      else
        echo "${pkg} not installed"
      fi
    done
  else
    "${pip_cmd[@]}" install --disable-pip-version-check -U "${packages[@]}" 2>&1
  fi
}

step_claude_code() {
  if ! have claude; then echo "claude not found, skipping"; return 0; fi
  if [[ "$MODE" == "check" ]]; then
    claude --version
  else
    if claude update; then
      echo "claude: successfully updated"
    else
      # claude update exits nonzero when already at latest — not a real failure
      echo "claude: already at latest"
      claude --version
    fi
  fi
}

step_gh_extensions() {
  if ! have gh; then echo "gh not found, skipping"; return 0; fi
  if [[ "$MODE" == "check" ]]; then
    gh extension list
  else
    gh extension upgrade --all 2>&1 || {
      echo "No gh extensions to upgrade (or none installed)"
      return 0
    }
  fi
}

step_mise_runtimes() {
  if ! have mise; then echo "mise not found, skipping"; return 0; fi

  # Log current state to transcript (via captured output)
  echo "--- mise current ---"
  mise current 2>/dev/null || true
  if $DEBUG; then echo "--- mise doctor ---"; mise doctor 2>&1 || true; fi

  # The actual check/upgrade (summarizer keys off output below this point)
  echo "--- mise action ---"
  if [[ "$MODE" == "check" ]]; then
    mise outdated 2>/dev/null || true
  else
    mise upgrade 2>&1
  fi
}

step_cleanup() {
  if $NO_CLEANUP; then
    echo "Cleanup skipped (--no-cleanup)"
    return 0
  fi
  if [[ "$MODE" == "check" ]]; then
    echo "Cleanup skipped in check mode"
    return 0
  fi
  have brew && brew cleanup 2>/dev/null
  have mise && mise prune -y 2>/dev/null

  # Prune system-update logs older than 30 days
  if [[ -d "${LOG_DIR}" ]]; then
    local pruned
    pruned="$(find "${LOG_DIR}" -name 'run-*.log' -mtime +30 -print -delete 2>/dev/null | wc -l | tr -d ' ')"
    find "${LOG_DIR}" -name 'run-*.ndjson' -mtime +30 -delete 2>/dev/null
    if [[ "$pruned" -gt 0 ]]; then
      echo "Pruned ${pruned} log file(s) older than 30 days"
    fi
  fi

  return 0
}

# =============================================================================
# Plugin discovery
# =============================================================================

load_plugins() {
  if $NO_PLUGINS; then
    log debug "Plugins disabled"
    return 0
  fi
  if [[ ! -d "${PLUGIN_DIR}" ]]; then
    log debug "No plugin directory at ${PLUGIN_DIR}"
    return 0
  fi

  local plugins=()
  while IFS= read -r -d '' f; do
    plugins+=("$f")
  done < <(find "${PLUGIN_DIR}" -maxdepth 1 -name '*.sh' -print0 2>/dev/null | sort -z)

  if [[ ${#plugins[@]} -eq 0 ]]; then
    log debug "No plugins found in ${PLUGIN_DIR}"
    return 0
  fi

  for plugin in "${plugins[@]}"; do
    local pname
    pname="$(basename "$plugin" .sh)"
    log debug "Loading plugin: ${pname}"

    # shellcheck disable=SC1090
    source "$plugin"

    # Create a dispatch wrapper so run_step can call a stable function name.
    eval "run_plugin_${pname}() {
      if [[ \"\$MODE\" == \"check\" ]]; then
        if declare -f \"check_${pname}\" >/dev/null 2>&1; then
          check_${pname}
        else
          log debug \"Plugin ${pname} has no check_${pname} function\"
          return 0
        fi
      else
        if declare -f \"run_${pname}\" >/dev/null 2>&1; then
          run_${pname}
        else
          log debug \"Plugin ${pname} has no run_${pname} function\"
          return 0
        fi
      fi
    }"

    register_plugin_step "$pname"
  done
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
  local total_end
  total_end="$(date +%s)"
  local total_duration=$(( total_end - TOTAL_START ))

  # Separator
  consolef "${C_DIM}──────────────────────────────────────────${C_RESET}\n"

  # Count failures and warnings
  local failures=0 warnings=0
  for entry in "${STEP_RESULTS[@]}"; do
    local s_status
    IFS='|' read -r _ _ s_status _ _ <<< "$entry"
    case "$s_status" in
      fail) ((failures++)) || true ;;
      warn) ((warnings++)) || true ;;
    esac
  done

  # Total line
  if [[ $failures -gt 0 ]]; then
    consolef "${C_RED}✗ %d step(s) failed · %ds${C_RESET}\n" "$failures" "$total_duration"
  elif [[ $warnings -gt 0 ]]; then
    consolef "${C_YELLOW}⚠ All steps completed (%d warning(s)) · %ds${C_RESET}\n" "$warnings" "$total_duration"
  else
    consolef "${C_GREEN}✓ All steps successful · %ds${C_RESET}\n" "$total_duration"
  fi

  SUMMARY_FAILURES=$failures
  SUMMARY_WARNINGS=$warnings
  SUMMARY_DURATION=$total_duration

  # Log path (using ~ for readability)
  local display_dir
  display_dir="${LOG_DIR/#"$HOME"/\~}"
  consolef "${C_DIM}log: %s/run-%s.log${C_RESET}\n" "${display_dir}" "$RUN_ID"

  # Notices
  if [[ ${#NOTICES[@]} -gt 0 ]]; then
    consolef "\n${C_BOLD}Notices${C_RESET}\n"
    for n in "${NOTICES[@]}"; do
      consolef "${C_YELLOW}• %s${C_RESET}\n" "$n"
    done
  fi

  # Action items (brew restart notices etc.)
  if [[ ${#ACTION_ITEMS[@]} -gt 0 ]]; then
    consolef "\n${C_BOLD}Action items${C_RESET}\n"
    for item in "${ACTION_ITEMS[@]}"; do
      consolef "${C_YELLOW}• %s${C_RESET}\n" "$item"
    done
  fi

  # "How to dig deeper" footer (skip if already in debug mode)
  if ! $DEBUG; then
    consolef "\n${C_DIM}Dig deeper: system-update --debug · less -R %s/latest.log${C_RESET}\n" "$display_dir"
  fi

  ndjson info run_end "system-update" \
    "\"total_duration\":${total_duration},\"failures\":${failures},\"warnings\":${warnings}"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

print_json_summary() {
  local display_dir
  display_dir="${LOG_DIR/#"$HOME"/\~}"

  printf '{'
  printf '"run_id":"%s",' "$(json_escape "$RUN_ID")"
  printf '"mode":"%s",' "$(json_escape "$MODE")"
  printf '"strict":%s,' "$STRICT"
  printf '"failures":%d,' "$SUMMARY_FAILURES"
  printf '"warnings":%d,' "$SUMMARY_WARNINGS"
  printf '"duration":%d,' "$SUMMARY_DURATION"
  printf '"log":"%s/run-%s.log",' "$(json_escape "$display_dir")" "$(json_escape "$RUN_ID")"
  printf '"ndjson":"%s/run-%s.ndjson",' "$(json_escape "$display_dir")" "$(json_escape "$RUN_ID")"

  printf '"steps":['
  local first_step=true
  local entry
  for entry in "${STEP_RESULTS[@]}"; do
    local sid sname sstatus sdur sdetail
    IFS='|' read -r sid sname sstatus sdur sdetail <<< "$entry"
    $first_step || printf ','
    first_step=false
    printf '{'
    printf '"id":"%s",' "$(json_escape "$sid")"
    printf '"name":"%s",' "$(json_escape "$sname")"
    printf '"status":"%s",' "$(json_escape "$sstatus")"
    printf '"duration":%s,' "$(json_escape "$sdur")"
    printf '"detail":"%s"' "$(json_escape "$sdetail")"
    printf '}'
  done
  printf '],'

  printf '"notices":['
  local first_notice=true
  local n
  for n in "${NOTICES[@]}"; do
    $first_notice || printf ','
    first_notice=false
    printf '"%s"' "$(json_escape "$n")"
  done
  printf '],'

  printf '"action_items":['
  local first_action=true
  local a
  for a in "${ACTION_ITEMS[@]}"; do
    $first_action || printf ','
    first_action=false
    printf '"%s"' "$(json_escape "$a")"
  done
  printf ']'

  printf '}\n'
}

send_notification() {
  if ! $NOTIFY; then
    return 0
  fi
  if ! command -v osascript >/dev/null 2>&1; then
    log debug "osascript not found; notification skipped"
    return 0
  fi
  local title body
  title="system-update ${RUN_ID}"
  if [[ $SUMMARY_FAILURES -gt 0 ]]; then
    body="${SUMMARY_FAILURES} failed · ${SUMMARY_WARNINGS} warnings · ${SUMMARY_DURATION}s"
  elif [[ $SUMMARY_WARNINGS -gt 0 ]]; then
    body="${SUMMARY_WARNINGS} warnings · ${SUMMARY_DURATION}s"
  else
    body="all steps successful · ${SUMMARY_DURATION}s"
  fi
  osascript -e "display notification \"${body}\" with title \"${title}\"" >/dev/null 2>&1 || true
}

# =============================================================================
# Register steps (core + plugins)
# =============================================================================

register_step "brew-index"    "Homebrew index"    step_brew_index    "brew"   true  "core"
register_step "brew-formulae" "Homebrew formulae" step_brew_formulae "brew"   true  "core"
register_step "npm-globals"   "npm globals"       step_npm_globals   "npm"    true  "core"
register_step "pip-packages"  "pip packages"      step_pip_packages  "python3|mise" true "core"
register_step "claude-code"   "Claude Code"       step_claude_code   "claude" true "core"
register_step "gh-extensions" "gh extensions"     step_gh_extensions "gh"     true "core"
register_step "mise-runtimes" "mise runtimes"     step_mise_runtimes "mise"   true "core"

load_plugins

register_step "cleanup"       "Cleanup"           step_cleanup       ""       true "core"

apply_step_order_override
compute_step_enabled

if $LIST_ONLY; then
  print_step_list
  exit 0
fi

# =============================================================================
# Execute
# =============================================================================

context_snapshot

for id in "${STEP_ORDER[@]}"; do
  if [[ "${STEP_ENABLED[$id]}" != "true" ]]; then
    continue
  fi
  if ! step_available "$id"; then
    record_skipped_step "$id" "missing: ${STEP_REQUIRES[$id]}"
    continue
  fi
  run_step_by_id "$id"
done

print_summary

if $JSON_SUMMARY; then
  print_json_summary
fi

send_notification

# Symlink latest
ln -sf "run-${RUN_ID}.log" "${LOG_DIR}/latest.log"
ln -sf "run-${RUN_ID}.ndjson" "${LOG_DIR}/latest.ndjson"
