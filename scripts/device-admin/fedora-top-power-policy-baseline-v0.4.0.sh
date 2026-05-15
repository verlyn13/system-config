#!/usr/bin/env bash
# fedora-top-power-policy-baseline-v0.4.0.sh
#
# Read-only baseline of fedora-top power/suspend posture, prompted by
# the 2026-05-14 19:23:29 AKDT suspend mid-SSH-session that dropped
# an in-progress shelltutor edit. No host mutation.
#
# v0.4.0 (2026-05-15): Fix diagnostic fallback semantics.
# logind.conf(5): when HandleLidSwitchExternalPower is empty (the
# systemd default), behavior falls through to HandleLidSwitch.
# v0.3.0 captured the correct raw values but its case statement
# only matched the LITERAL value of HandleLidSwitchExternalPower,
# so an empty value (which is the actual cause of the 2026-05-14
# 19:23 suspend incident) wrongly reported
# lid_close_on_ac_will_suspend=false. v0.4.0 resolves the empty
# value to HandleLidSwitch before evaluating the case. This makes
# the diagnostic match observed behavior.
#
# v0.3.0 (2026-05-15): Fix logind property reader. v0.2.0 used
# `systemctl show systemd-logind --no-pager` and parsed `key=value`
# lines for HandleLidSwitch, IdleAction, etc. On systemd 259 (Fedora
# 44), `systemctl show` for the systemd-logind unit returns ONLY the
# service-unit properties (Id, ActiveState, ...) and NOT the
# org.freedesktop.login1.Manager properties. Even
# `systemctl show systemd-logind --property HandleLidSwitch --value`
# returns empty. The canonical mechanism is busctl against
# org.freedesktop.login1 / /org/freedesktop/login1 /
# org.freedesktop.login1.Manager. v0.3.0 switches get_prop to
# busctl with a small type-aware extractor for `s "value"`, `t N`,
# `b true|false`. SuspendState is now an unknown property in
# systemd 259 and silently extracts as empty.
#
# v0.2.0 (2026-05-15): Fix step 10 ARG_MAX overflow. v0.1.0 passed
# the full 7-day `journalctl -u systemd-logind` output as a single
# --arg to jq. On a host that suspends often, the output exceeds
# getconf ARG_MAX (~128 KB on stock Fedora) and execve("jq", ...)
# fails with E2BIG ("Argument list too long"). v0.2.0 truncates
# events_raw to the last 500 lines in shell before passing it to
# jq. Suspend/resume counts are computed from the full output and
# remain accurate; only the raw_log_tail field is bounded.
#
# Required shell: bash on fedora-top (any modern bash).
# Encoding:       UTF-8 without BOM (ASCII-only in practice).
# Session class:  read-only-probe.
# Runs as:        verlyn13 (SSH user). Uses `sudo -n` for journalctl
#                 only. Does NOT mutate any file or unit state.
#
# Spec:    docs/device-admin/linux-terminal-admin-spec.md v0.1.0
# Runbook: docs/device-admin/fedora-top-power-policy-baseline-2026-05-15.md
#
# Output goes to:
#   /var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-$ts/
#     00-run.log
#     01-identity.json
#     02-logind-conf.json
#     03-logind-effective.json
#     04-sleep-targets.json
#     05-upower.json
#     06-gnome-power.json
#     07-kernel-cmdline.json
#     08-summary.json          <- canonical hand-back to system-config
#     09-inhibitors.json
#     10-recent-suspend-events.json

set -euo pipefail

# -------- evidence directory --------------------------------------
ts=$(date -u +%Y%m%dT%H%M%SZ)
evdir="/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-$ts"
mkdir -p "$evdir"

log() {
    printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$evdir/00-run.log"
}

# -------- helper: emit a JSON file via jq -------------------------
# Usage: emit_json <filename.json> <jq filter and args>
# Example: emit_json 01-identity.json -n --arg host "$h" '{host:$host}'
emit_json() {
    local file="$1"; shift
    jq "$@" > "$evdir/$file"
}

# -------- check tools we depend on --------------------------------
need=(jq systemctl loginctl busctl)
for t in "${need[@]}"; do
    if ! command -v "$t" >/dev/null 2>&1; then
        log "missing required tool: $t"
        exit 1
    fi
done

# -------- 01-identity.json ----------------------------------------
log "01: identity"

uname_s=$(uname -s)
uname_r=$(uname -r)
uname_m=$(uname -m)
os_id=""
os_version_id=""
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    os_id="${ID:-}"
    os_version_id="${VERSION_ID:-}"
fi
hostname_full=$(hostname -f 2>/dev/null || hostname)

emit_json 01-identity.json -n \
    --arg ts             "$(date -u +%FT%TZ)" \
    --arg host           "$hostname_full" \
    --arg user           "$(id -un)" \
    --arg uid            "$(id -u)" \
    --arg uname_s        "$uname_s" \
    --arg uname_r        "$uname_r" \
    --arg uname_m        "$uname_m" \
    --arg os_id          "$os_id" \
    --arg os_version_id  "$os_version_id" \
    --arg shell          "$(bash --version | head -n1)" \
    '{
        timestamp:    $ts,
        host:         $host,
        ssh_user:     $user,
        uid:          $uid,
        os_id:        $os_id,
        os_version:   $os_version_id,
        uname:        { sys: $uname_s, release: $uname_r, machine: $uname_m },
        shell:        $shell
    }'

# -------- 02-logind-conf.json: on-disk config -------------------
log "02: logind on-disk config"

logind_files=()
[ -r /etc/systemd/logind.conf ] && logind_files+=( /etc/systemd/logind.conf )
if [ -d /etc/systemd/logind.conf.d ]; then
    while IFS= read -r -d '' f; do
        logind_files+=( "$f" )
    done < <(find /etc/systemd/logind.conf.d -maxdepth 1 -type f -name '*.conf' -print0 2>/dev/null)
fi

logind_records="[]"
for f in "${logind_files[@]}"; do
    mode=$(stat -c '%a' "$f" 2>/dev/null || echo "?")
    owner=$(stat -c '%U:%G' "$f" 2>/dev/null || echo "?:?")
    content=$(cat "$f" 2>/dev/null || echo "")
    rec=$(jq -n \
        --arg path    "$f" \
        --arg mode    "$mode" \
        --arg owner   "$owner" \
        --arg content "$content" \
        '{path:$path, mode:$mode, owner:$owner, content:$content}')
    logind_records=$(jq --argjson r "$rec" '. + [$r]' <<<"$logind_records")
done

emit_json 02-logind-conf.json --argjson files "$logind_records" \
    -n '{logind_config_files: $files}'

# -------- 03-logind-effective.json: runtime effective config -----
log "03: logind effective runtime config"

# Read each logind manager property via busctl (D-Bus). v0.2.0 used
# `systemctl show systemd-logind` which on systemd 259 (Fedora 44)
# does NOT return manager-level properties for the logind service,
# yielding empty strings for every key. busctl is the canonical
# mechanism and works on every systemd version this packet targets.
get_prop() {
    local raw v
    raw=$(busctl get-property org.freedesktop.login1 \
            /org/freedesktop/login1 \
            org.freedesktop.login1.Manager "$1" 2>/dev/null) || return 0
    case "$raw" in
        's "'*'"')
            v=${raw#s \"}
            v=${v%\"}
            printf '%s' "$v" ;;
        't '*)
            printf '%s' "${raw#t }" ;;
        'b '*)
            printf '%s' "${raw#b }" ;;
        *)
            printf '%s' "$raw" ;;
    esac
}

handle_lid_switch=$(get_prop HandleLidSwitch)
handle_lid_switch_ext=$(get_prop HandleLidSwitchExternalPower)
handle_lid_switch_doc=$(get_prop HandleLidSwitchDocked)
idle_action=$(get_prop IdleAction)
idle_action_sec=$(get_prop IdleActionUSec)
handle_power_key=$(get_prop HandlePowerKey)
handle_suspend_key=$(get_prop HandleSuspendKey)
handle_hibernate_key=$(get_prop HandleHibernateKey)
inhibit_delay_max=$(get_prop InhibitDelayMaxUSec)
suspend_state=$(get_prop SuspendState)

# Diagnostic: is HandleLidSwitchExternalPower currently set to a
# value that would cause suspend on lid close? Capture both the
# raw value and a boolean for outer consumers.
#
# logind.conf(5): empty HandleLidSwitchExternalPower falls through
# to HandleLidSwitch. v0.4.0: resolve empty to HandleLidSwitch
# before evaluating, so the diagnostic reflects observed behavior.
lid_ext_effective="$handle_lid_switch_ext"
[ -z "$lid_ext_effective" ] && lid_ext_effective="$handle_lid_switch"
lid_ext_will_suspend=false
case "$lid_ext_effective" in
    suspend|suspend-then-hibernate|hibernate|hybrid-sleep) lid_ext_will_suspend=true ;;
esac

lid_battery_will_suspend=false
case "$handle_lid_switch" in
    suspend|suspend-then-hibernate|hibernate|hybrid-sleep) lid_battery_will_suspend=true ;;
esac

idle_will_suspend=false
case "$idle_action" in
    suspend|suspend-then-hibernate|hibernate|hybrid-sleep) idle_will_suspend=true ;;
esac

emit_json 03-logind-effective.json -n \
    --arg lid_ac              "$handle_lid_switch_ext" \
    --arg lid_battery         "$handle_lid_switch" \
    --arg lid_docked          "$handle_lid_switch_doc" \
    --arg idle_action         "$idle_action" \
    --arg idle_action_usec    "$idle_action_sec" \
    --arg handle_power_key    "$handle_power_key" \
    --arg handle_suspend_key  "$handle_suspend_key" \
    --arg handle_hibernate    "$handle_hibernate_key" \
    --arg inhibit_delay       "$inhibit_delay_max" \
    --arg suspend_state       "$suspend_state" \
    --argjson lid_ac_sus      "$lid_ext_will_suspend" \
    --argjson lid_bat_sus     "$lid_battery_will_suspend" \
    --argjson idle_sus        "$idle_will_suspend" \
    '{
        handle_lid_switch_external_power: $lid_ac,
        handle_lid_switch_battery:        $lid_battery,
        handle_lid_switch_docked:         $lid_docked,
        idle_action:                      $idle_action,
        idle_action_usec:                 $idle_action_usec,
        handle_power_key:                 $handle_power_key,
        handle_suspend_key:               $handle_suspend_key,
        handle_hibernate_key:             $handle_hibernate,
        inhibit_delay_max_usec:           $inhibit_delay,
        suspend_state:                    $suspend_state,
        diagnostic: {
            lid_close_on_ac_will_suspend:     $lid_ac_sus,
            lid_close_on_battery_will_suspend:$lid_bat_sus,
            idle_will_suspend:                $idle_sus
        }
    }'

# -------- 04-sleep-targets.json: target state -------------------
log "04: sleep targets"

declare -A target_state
for tgt in sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target; do
    if state=$(systemctl is-active "$tgt" 2>/dev/null); then
        target_state[$tgt]="$state"
    else
        target_state[$tgt]="unknown"
    fi
    if enabled=$(systemctl is-enabled "$tgt" 2>/dev/null); then
        target_state["${tgt}.enabled"]="$enabled"
    else
        target_state["${tgt}.enabled"]="unknown"
    fi
done

emit_json 04-sleep-targets.json -n \
    --arg s_active   "${target_state[sleep.target]}" \
    --arg s_enabled  "${target_state[sleep.target.enabled]}" \
    --arg su_active  "${target_state[suspend.target]}" \
    --arg su_enabled "${target_state[suspend.target.enabled]}" \
    --arg h_active   "${target_state[hibernate.target]}" \
    --arg h_enabled  "${target_state[hibernate.target.enabled]}" \
    --arg hy_active  "${target_state[hybrid-sleep.target]}" \
    --arg hy_enabled "${target_state[hybrid-sleep.target.enabled]}" \
    --arg sh_active  "${target_state[suspend-then-hibernate.target]}" \
    --arg sh_enabled "${target_state[suspend-then-hibernate.target.enabled]}" \
    '{
        "sleep.target":                 { active: $s_active,  enabled: $s_enabled  },
        "suspend.target":               { active: $su_active, enabled: $su_enabled },
        "hibernate.target":             { active: $h_active,  enabled: $h_enabled  },
        "hybrid-sleep.target":          { active: $hy_active, enabled: $hy_enabled },
        "suspend-then-hibernate.target":{ active: $sh_active, enabled: $sh_enabled }
    }'

# -------- 05-upower.json: AC and battery ------------------------
log "05: upower (AC + battery)"

on_battery="unknown"
battery_pct=""
battery_state=""
upower_present=false

if command -v upower >/dev/null 2>&1; then
    upower_present=true
    # Find a battery device, if any.
    battery_dev=$(upower -e 2>/dev/null | grep -m1 -i 'battery_BAT' || true)
    if [ -n "$battery_dev" ]; then
        info=$(upower -i "$battery_dev" 2>/dev/null || true)
        battery_pct=$(printf '%s\n' "$info" | awk -F: '/percentage:/ {gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')
        battery_state=$(printf '%s\n' "$info" | awk -F: '/state:/ {gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')
        case "$battery_state" in
            discharging) on_battery=true ;;
            charging|fully-charged|pending-charge) on_battery=false ;;
            *) on_battery="$battery_state" ;;
        esac
    fi
fi

emit_json 05-upower.json -n \
    --argjson present     "$upower_present" \
    --arg     on_battery  "$on_battery" \
    --arg     pct         "$battery_pct" \
    --arg     state       "$battery_state" \
    '{
        upower_present:  $present,
        on_battery:      $on_battery,
        battery_percent: $pct,
        battery_state:   $state
    }'

# -------- 06-gnome-power.json: per-user gsettings ---------------
log "06: GNOME power gsettings (wyn + verlyn13)"

gnome_user_settings() {
    local target_user="$1"
    if ! getent passwd "$target_user" >/dev/null 2>&1; then
        printf '{"present": false, "reason": "user not present"}'
        return
    fi
    # Find the user's bus address. Without an active session we can't
    # read gsettings; capture that as evidence rather than failing.
    local uid
    uid=$(id -u "$target_user")
    local bus="unix:path=/run/user/$uid/bus"
    if ! [ -S "/run/user/$uid/bus" ]; then
        printf '{"present": true, "session_bus_available": false, "user": "%s"}' "$target_user"
        return
    fi
    # Read the keys. Run under runuser+systemd-run for DBus context.
    # Use sudo only if needed (only root or the target user can read
    # another user's session bus). If the SSH user is the target, no
    # sudo needed.
    local prefix=""
    if [ "$(id -un)" != "$target_user" ]; then
        prefix="sudo -n -u $target_user"
    fi
    local sleep_ac sleep_bat dim idle_delay power_button
    sleep_ac=$(DBUS_SESSION_BUS_ADDRESS="$bus" $prefix gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null || echo "")
    sleep_bat=$(DBUS_SESSION_BUS_ADDRESS="$bus" $prefix gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 2>/dev/null || echo "")
    dim=$(DBUS_SESSION_BUS_ADDRESS="$bus" $prefix gsettings get org.gnome.settings-daemon.plugins.power idle-dim 2>/dev/null || echo "")
    idle_delay=$(DBUS_SESSION_BUS_ADDRESS="$bus" $prefix gsettings get org.gnome.desktop.session idle-delay 2>/dev/null || echo "")
    power_button=$(DBUS_SESSION_BUS_ADDRESS="$bus" $prefix gsettings get org.gnome.settings-daemon.plugins.power power-button-action 2>/dev/null || echo "")

    jq -n \
        --arg user           "$target_user" \
        --arg sleep_ac       "$sleep_ac" \
        --arg sleep_battery  "$sleep_bat" \
        --arg dim            "$dim" \
        --arg idle_delay     "$idle_delay" \
        --arg power_button   "$power_button" \
        '{
            present: true,
            session_bus_available: true,
            user: $user,
            sleep_inactive_ac_type:      $sleep_ac,
            sleep_inactive_battery_type: $sleep_battery,
            idle_dim:                    $dim,
            session_idle_delay:          $idle_delay,
            power_button_action:         $power_button
        }'
}

wyn_json=$(gnome_user_settings wyn)
verlyn13_json=$(gnome_user_settings verlyn13)

emit_json 06-gnome-power.json -n \
    --argjson wyn       "$wyn_json" \
    --argjson verlyn13  "$verlyn13_json" \
    '{wyn: $wyn, verlyn13: $verlyn13}'

# -------- 07-kernel-cmdline.json --------------------------------
log "07: kernel cmdline"

cmdline=$(cat /proc/cmdline 2>/dev/null || echo "")
emit_json 07-kernel-cmdline.json -n \
    --arg cmdline "$cmdline" \
    '{cmdline: $cmdline}'

# -------- 09-inhibitors.json: who's holding wake locks -----------
log "09: inhibitor list"

inhibit_raw=""
if command -v systemd-inhibit >/dev/null 2>&1; then
    inhibit_raw=$(systemd-inhibit --list --no-pager 2>/dev/null || echo "")
fi
emit_json 09-inhibitors.json -n \
    --arg raw "$inhibit_raw" \
    '{raw_systemd_inhibit_list: $raw}'

# -------- 10-recent-suspend-events.json -------------------------
log "10: recent suspend/resume events (last 7 days)"

# journalctl -u systemd-logind for the last 7 days, filtered to
# the lines about suspend / sleep / resume. Requires sudo -n for
# verlyn13 unless verlyn13 is in systemd-journal group.
events_raw=""
events_count_suspend=0
events_count_resume=0

if events_raw=$(sudo -n journalctl -u systemd-logind --since '7 days ago' --no-pager 2>/dev/null); then
    events_count_suspend=$(printf '%s\n' "$events_raw" | grep -cE 'Suspending system|System is going to sleep|Lid closed' || true)
    events_count_resume=$(printf '%s\n' "$events_raw" | grep -cE 'System resumed|Lid opened' || true)
    # v0.2.0 fix: truncate to last 500 lines before passing to jq.
    # The full 7-day output can exceed getconf ARG_MAX (~128 KB) and
    # fail execve("jq", ...) with E2BIG. The inner jq filter on
    # raw_log_tail already trims to the last 100 lines, so 500 here
    # gives a comfortable margin while staying well under ARG_MAX.
    # Counts above are computed BEFORE truncation and remain accurate.
    events_raw=$(printf '%s\n' "$events_raw" | tail -n 500)
fi

emit_json 10-recent-suspend-events.json -n \
    --argjson n_suspend "$events_count_suspend" \
    --argjson n_resume  "$events_count_resume" \
    --arg     raw       "$events_raw" \
    '{
        last_7_days: {
            suspend_event_count: $n_suspend,
            resume_event_count:  $n_resume
        },
        raw_log_tail: ($raw | split("\n") | .[-100:] | join("\n"))
    }'

# -------- 08-summary.json: one-page hand-back -------------------
log "08: summary"

# Compose from the prior records. Booleans stay booleans; strings
# stay strings. The outer consumer (system-config) decides whether
# the state matches the policy.
emit_json 08-summary.json -n \
    --arg ts                          "$(date -u +%FT%TZ)" \
    --arg host                        "$hostname_full" \
    --arg user                        "$(id -un)" \
    --arg lid_ac                      "$handle_lid_switch_ext" \
    --arg lid_battery                 "$handle_lid_switch" \
    --arg lid_docked                  "$handle_lid_switch_doc" \
    --arg idle_action                 "$idle_action" \
    --arg suspend_target              "${target_state[suspend.target]}" \
    --arg hibernate_target            "${target_state[hibernate.target]}" \
    --argjson lid_ac_sus              "$lid_ext_will_suspend" \
    --argjson lid_bat_sus             "$lid_battery_will_suspend" \
    --argjson idle_sus                "$idle_will_suspend" \
    --arg on_battery                  "$on_battery" \
    --arg battery_pct                 "$battery_pct" \
    --arg battery_state               "$battery_state" \
    --argjson n_suspend_7d            "$events_count_suspend" \
    --argjson n_resume_7d             "$events_count_resume" \
    --arg evidence_dir                "$evdir" \
    '{
        timestamp:                          $ts,
        host:                               $host,
        ssh_user:                           $user,
        logind: {
            handle_lid_switch_external_power: $lid_ac,
            handle_lid_switch_battery:        $lid_battery,
            handle_lid_switch_docked:         $lid_docked,
            idle_action:                      $idle_action
        },
        diagnostic: {
            lid_close_on_ac_will_suspend:     $lid_ac_sus,
            lid_close_on_battery_will_suspend:$lid_bat_sus,
            idle_will_suspend:                $idle_sus
        },
        sleep_targets: {
            "suspend.target":   $suspend_target,
            "hibernate.target": $hibernate_target
        },
        power: {
            on_battery:      $on_battery,
            battery_percent: $battery_pct,
            battery_state:   $battery_state
        },
        suspend_events_last_7d: {
            suspend_count: $n_suspend_7d,
            resume_count:  $n_resume_7d
        },
        evidence_dir: $evidence_dir
    }'

log "done. evidence at $evdir"
echo
echo "=== fedora-top power-policy baseline summary ==="
jq . "$evdir/08-summary.json"
echo
echo "Return 08-summary.json verbatim to system-config as the hand-back."
echo "Evidence directory: $evdir"
