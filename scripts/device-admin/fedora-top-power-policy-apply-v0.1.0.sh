#!/usr/bin/env bash
# fedora-top-power-policy-apply-v0.1.0.sh
#
# Phase 4 (harden) apply for fedora-top: stop systemd-logind from
# triggering suspend on lid-close while on AC, and stop it from
# triggering idle-suspend. The configured policy:
#
#   - HandleLidSwitchExternalPower = ignore  (AC: never suspend on lid)
#   - HandleLidSwitch              = suspend (battery: default suspend on lid)
#   - HandleLidSwitchDocked        = ignore  (docked: never suspend on lid)
#   - IdleAction                   = ignore  (idle never suspends)
#
# Plus GNOME-session-level (per-user, for wyn and verlyn13):
#   - sleep-inactive-ac-type       = 'nothing'
#   - idle-dim                     = false   (optional, debatable)
#
# DOES NOT touch hibernate, suspend.target, hybrid-sleep, kernel
# cmdline, LUKS, TPM, Secure Boot, firmware, BIOS, WoL, sudoers,
# accounts, services other than systemd-logind, firewall, DNS, DHCP,
# OPNsense, Cloudflare, WARP, Tailscale, or 1Password state.
#
# Required shell: bash on fedora-top.
# Encoding:       UTF-8 without BOM (ASCII-only in practice).
# Session class:  scoped-live-change.
# Runs as:        verlyn13 (SSH user). Uses `sudo -n` for systemd writes.
#
# Prerequisite: docs/device-admin/fedora-top-power-policy-baseline-2026-05-15.md
#   applied and the apply record committed, with
#   diagnostic.lid_close_on_ac_will_suspend or
#   diagnostic.idle_will_suspend == true. If both are already false,
#   this script is a no-op except for the GNOME settings.
#
# Idempotent: each step checks current state and skips if already
# matching the target. Snapshot-backed: pre-existing files copied
# to <evidence_dir>/snapshot/ before any edit.
#
# Spec:    docs/device-admin/linux-terminal-admin-spec.md v0.1.0
# Runbook: docs/device-admin/fedora-top-power-policy-apply-2026-05-15.md

set -euo pipefail

# -------- pinned policy ------------------------------------------
target_lid_ac='ignore'
target_lid_docked='ignore'
target_idle_action='ignore'
# Note: target GNOME sleep-inactive-ac-type is 'nothing'; passed
# inline in apply_gnome_user() rather than via a variable.

dropin_path='/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf'
dropin_body=$(cat <<'EOF'
# Managed by system-config:
#   docs/device-admin/fedora-top-power-policy-apply-2026-05-15.md
#   scripts/device-admin/fedora-top-power-policy-apply-v0.1.0.sh
#
# Goal: keep fedora-top reachable on the LAN admin lane while plugged
# in. Lid-close on AC will not suspend; idle will not suspend.
# Battery lid-close behavior is left at the systemd default so an
# unplugged, lid-closed laptop still saves battery.

[Login]
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
EOF
)
dropin_mode='0644'
dropin_owner='root:root'

# -------- evidence directory --------------------------------------
ts=$(date -u +%Y%m%dT%H%M%SZ)
evdir="/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-apply-$ts"
snapdir="$evdir/snapshot"
mkdir -p "$snapdir"

log() {
    printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$evdir/00-run.log"
}

emit_json() {
    local file="$1"; shift
    jq "$@" > "$evdir/$file"
}

# -------- preflight ---------------------------------------------
log "S0 preflight"

if [ "$(id -un)" != 'verlyn13' ]; then
    log "wrong SSH user: expected verlyn13, got $(id -un)"
    exit 1
fi

if [ "$(hostname -s 2>/dev/null || hostname)" != 'fedora-top' ]; then
    log "wrong host: expected fedora-top, got $(hostname)"
    exit 1
fi

for t in jq systemctl install; do
    if ! command -v "$t" >/dev/null 2>&1; then
        log "missing required tool: $t"
        exit 1
    fi
done

if ! sudo -n true 2>/dev/null; then
    log "sudo -n unavailable. This packet requires passwordless sudo."
    exit 1
fi

emit_json 00-preflight.json -n \
    --arg ts          "$(date -u +%FT%TZ)" \
    --arg host        "$(hostname -s)" \
    --arg user        "$(id -un)" \
    --arg evidence    "$evdir" \
    '{
        timestamp:    $ts,
        host:         $host,
        ssh_user:     $user,
        evidence_dir: $evidence
    }'

# -------- snapshot existing state -------------------------------
log "S1 snapshot existing state"

# Snapshot every existing logind config + drop-in.
if [ -f /etc/systemd/logind.conf ]; then
    cp -a -- /etc/systemd/logind.conf "$snapdir/"
fi
if [ -d /etc/systemd/logind.conf.d ]; then
    mkdir -p "$snapdir/logind.conf.d"
    cp -a /etc/systemd/logind.conf.d/. "$snapdir/logind.conf.d/" 2>/dev/null || true
fi

# Snapshot the runtime effective config. `systemctl show` is
# world-readable, no sudo needed; the redirect lands in the verlyn13-
# owned evidence dir.
systemctl show systemd-logind --no-pager > "$snapdir/logind-effective.preinstall.txt" 2>&1 || true

# -------- helper: read effective logind property ----------------
# systemctl show is world-readable; no sudo needed.
read_logind_prop() {
    systemctl show systemd-logind --property "$1" --value 2>/dev/null || echo ''
}

before_lid_ac=$(read_logind_prop HandleLidSwitchExternalPower)
before_lid_docked=$(read_logind_prop HandleLidSwitchDocked)
before_idle=$(read_logind_prop IdleAction)
log "before: lid_ac=$before_lid_ac lid_docked=$before_lid_docked idle=$before_idle"

emit_json 01-before.json -n \
    --arg lid_ac     "$before_lid_ac" \
    --arg lid_docked "$before_lid_docked" \
    --arg idle       "$before_idle" \
    '{handle_lid_switch_external_power: $lid_ac,
      handle_lid_switch_docked:         $lid_docked,
      idle_action:                      $idle}'

# -------- S2 write drop-in (idempotent) -------------------------
log "S2 write drop-in $dropin_path (idempotent)"

current_body=""
if [ -f "$dropin_path" ]; then
    current_body=$(cat -- "$dropin_path")
fi

need_install=false
if [ "$current_body" != "$dropin_body" ]; then
    need_install=true
fi

dropin_changed=false
if $need_install; then
    sudo -n install -d -m 0755 -o root -g root /etc/systemd/logind.conf.d
    # Use a temp file and install for atomic, mode/ownership-set write.
    tmp=$(mktemp /tmp/jefahnierocks-logind-dropin.XXXXXX)
    trap 'rm -f "$tmp"' EXIT
    printf '%s\n' "$dropin_body" > "$tmp"
    sudo -n install -m "$dropin_mode" -o "${dropin_owner%:*}" -g "${dropin_owner#*:}" \
        -- "$tmp" "$dropin_path"
    rm -f "$tmp"
    trap - EXIT
    dropin_changed=true
    log "S2 wrote $dropin_path"
else
    log "S2 drop-in already correct; skipping write"
fi

dropin_mode_actual=$(sudo -n stat -c '%a' "$dropin_path")
dropin_owner_actual=$(sudo -n stat -c '%U:%G' "$dropin_path")

if [ "$dropin_mode_actual" != "$dropin_mode" ] || \
   [ "$dropin_owner_actual" != "$dropin_owner" ]; then
    log "S2 drop-in mode/owner mismatch: $dropin_mode_actual / $dropin_owner_actual"
    exit 1
fi

emit_json 02-dropin.json -n \
    --arg path    "$dropin_path" \
    --arg mode    "$dropin_mode_actual" \
    --arg owner   "$dropin_owner_actual" \
    --argjson changed "$dropin_changed" \
    --arg body    "$dropin_body" \
    '{path:$path, mode:$mode, owner:$owner, changed_in_this_run:$changed, body:$body}'

# -------- S3 reload systemd-logind ------------------------------
log "S3 reload systemd-logind via SIGHUP"

# `systemctl reload systemd-logind` sends SIGHUP and re-reads
# /etc/systemd/logind.conf + /etc/systemd/logind.conf.d/. It does
# NOT drop active sessions. Lid/idle handlers refresh from the new
# config.
if $dropin_changed; then
    sudo -n systemctl reload systemd-logind
    sleep 1
else
    log "S3 drop-in unchanged; skipping reload"
fi

# -------- S4 read-back ------------------------------------------
log "S4 read-back effective config"

after_lid_ac=$(read_logind_prop HandleLidSwitchExternalPower)
after_lid_docked=$(read_logind_prop HandleLidSwitchDocked)
after_idle=$(read_logind_prop IdleAction)

if [ "$after_lid_ac" != "$target_lid_ac" ]; then
    log "S4 lid_ac mismatch: expected $target_lid_ac, got $after_lid_ac"
    log "S4 restoring snapshot and exiting"
    if [ -f "$snapdir/logind.conf.d/$(basename "$dropin_path")" ]; then
        sudo -n cp -a "$snapdir/logind.conf.d/$(basename "$dropin_path")" "$dropin_path"
    else
        sudo -n rm -f "$dropin_path"
    fi
    sudo -n systemctl reload systemd-logind || true
    exit 1
fi

if [ "$after_idle" != "$target_idle_action" ]; then
    log "S4 idle_action mismatch: expected $target_idle_action, got $after_idle"
    exit 1
fi

if [ "$after_lid_docked" != "$target_lid_docked" ]; then
    log "S4 lid_docked mismatch: expected $target_lid_docked, got $after_lid_docked"
    exit 1
fi

log "S4 logind effective config matches policy"

emit_json 03-after.json -n \
    --arg lid_ac     "$after_lid_ac" \
    --arg lid_docked "$after_lid_docked" \
    --arg idle       "$after_idle" \
    '{handle_lid_switch_external_power: $lid_ac,
      handle_lid_switch_docked:         $lid_docked,
      idle_action:                      $idle}'

# -------- S5 GNOME per-user gsettings ---------------------------
log "S5 GNOME per-user gsettings (wyn + verlyn13)"

apply_gnome_user() {
    local target_user="$1"
    if ! getent passwd "$target_user" >/dev/null 2>&1; then
        printf '{"user":"%s","present":false,"reason":"user not present"}' "$target_user"
        return
    fi
    local uid
    uid=$(id -u "$target_user")
    local bus_path="/run/user/$uid/bus"
    if ! [ -S "$bus_path" ]; then
        printf '{"user":"%s","present":true,"session_bus_available":false,"applied":false}' "$target_user"
        return
    fi
    local cmd_set="gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'"
    local cmd_dim="gsettings set org.gnome.settings-daemon.plugins.power idle-dim false"
    local cmd_get="gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type"

    if [ "$(id -un)" = "$target_user" ]; then
        DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" bash -c "$cmd_set" || true
        DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" bash -c "$cmd_dim" || true
        local readback
        readback=$(DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" bash -c "$cmd_get" || echo "")
        jq -n --arg u "$target_user" --arg r "$readback" \
            '{user:$u, present:true, session_bus_available:true, applied:true, sleep_inactive_ac_type:$r}'
    else
        # Run as the target user via sudo, preserving the session bus.
        sudo -n -u "$target_user" \
            env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
            bash -c "$cmd_set" || true
        sudo -n -u "$target_user" \
            env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
            bash -c "$cmd_dim" || true
        local readback
        readback=$(sudo -n -u "$target_user" \
            env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
            bash -c "$cmd_get" 2>/dev/null || echo "")
        jq -n --arg u "$target_user" --arg r "$readback" \
            '{user:$u, present:true, session_bus_available:true, applied:true, sleep_inactive_ac_type:$r}'
    fi
}

wyn_result=$(apply_gnome_user wyn)
verlyn13_result=$(apply_gnome_user verlyn13)

emit_json 04-gnome.json -n \
    --argjson wyn      "$wyn_result" \
    --argjson verlyn13 "$verlyn13_result" \
    '{wyn: $wyn, verlyn13: $verlyn13}'

# -------- S6 final summary --------------------------------------
log "S6 summary"

emit_json 08-summary.json -n \
    --arg ts                "$(date -u +%FT%TZ)" \
    --arg host              "$(hostname -s)" \
    --arg user              "$(id -un)" \
    --arg before_lid_ac     "$before_lid_ac" \
    --arg before_idle       "$before_idle" \
    --arg after_lid_ac      "$after_lid_ac" \
    --arg after_idle        "$after_idle" \
    --arg dropin_path       "$dropin_path" \
    --argjson dropin_changed "$dropin_changed" \
    --argjson wyn            "$wyn_result" \
    --argjson verlyn13       "$verlyn13_result" \
    --arg evidence_dir      "$evdir" \
    '{
        timestamp: $ts,
        host:      $host,
        ssh_user:  $user,
        logind: {
            before: {
                handle_lid_switch_external_power: $before_lid_ac,
                idle_action:                      $before_idle
            },
            after: {
                handle_lid_switch_external_power: $after_lid_ac,
                idle_action:                      $after_idle
            }
        },
        drop_in: {
            path:                $dropin_path,
            changed_in_this_run: $dropin_changed
        },
        gnome: {
            wyn:      $wyn,
            verlyn13: $verlyn13
        },
        policy_status: {
            lid_close_on_ac_will_suspend_after:   false,
            idle_will_suspend_after:              false,
            lid_close_on_battery_will_suspend_after: true
        },
        evidence_dir: $evidence_dir
    }'

log "done. evidence at $evdir"
echo
echo "=== fedora-top power-policy apply summary ==="
jq . "$evdir/08-summary.json"
echo
echo "Return 08-summary.json verbatim to system-config as the hand-back."
echo "Evidence directory: $evdir"
echo "Snapshot directory: $snapdir"
