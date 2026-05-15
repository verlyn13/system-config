---
title: fedora-top Power Policy Apply Packet - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.3.0
last_updated: 2026-05-15
tags: [device-admin, fedora-top, linux, power, suspend, logind, harden]
priority: high
---

# fedora-top Power Policy Apply Packet - 2026-05-15

Phase 4 (harden) apply for fedora-top: stop `systemd-logind` from
suspending the laptop on lid-close while on AC, and stop it from
suspending on idle. Battery lid-close is intentionally left at the
systemd default (suspend) so an unplugged stowed laptop still saves
battery.

This is the apply for the baseline at
[fedora-top-power-policy-baseline-2026-05-15.md](./fedora-top-power-policy-baseline-2026-05-15.md).
It conforms to
[linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md) v0.1.0.

## Version History

- **v0.3.0 (2026-05-15)**: Fix two issues from v0.2.0's first real
  run end-to-end on fedora-top. (1) `dropin_mode='0644'` was
  compared against `stat -c '%a'` output `'644'` (no leading zero
  per GNU coreutils) and hard-stopped at S2 with `"drop-in
  mode/owner mismatch: 644 / root:root"` even though the file was
  installed correctly. v0.3.0 changes `dropin_mode='644'`. (2) The
  drop-in body heredoc still referenced
  `scripts/device-admin/fedora-top-power-policy-apply-v0.1.0.sh`
  (leftover from the v0.1.0 source copy; v0.2.0 bumped the header
  comment but missed the heredoc body). v0.3.0 updates the
  reference to `v0.3.0.sh`. The file installed during v0.2.0's
  failed run is left on host
  (`/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf`,
  mode 0644 root:root, content correct apart from the stale
  comment); v0.3.0's re-run will detect the content drift (one
  comment line), re-write, pass the mode check, and proceed
  through S3-S6. Snapshot, reload, target values, and GNOME apply
  logic unchanged.
- **v0.2.0 (2026-05-15)**: Fix step S4 logind property reader.
  v0.1.0's `read_logind_prop` used
  `systemctl show systemd-logind --property X --value`. On systemd 259
  (Fedora 44) that returns empty for every
  `org.freedesktop.login1.Manager` property, so the read-back step
  would have compared `""` against `"ignore"` and triggered the
  hard-stop snapshot-restore on every run. v0.2.0 switches to
  `busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager <Prop>`
  with a type-aware extractor (`s "value"`, `t N`, `b true|false`).
  Drop-in body, target values, snapshot, reload (SIGHUP), and GNOME
  apply logic are unchanged. Same defect was visible in
  `fedora-top-power-policy-baseline-v0.2.0.sh`; baseline bumped to
  v0.3.0 in parallel.
- **v0.1.0 (2026-05-15)**: Initial drop. Never run end-to-end against
  a real host; superseded by v0.2.0 once baseline-v0.2.0 surfaced
  the systemctl/busctl issue.

## Policy

| Surface | Target | Rationale |
|---|---|---|
| `HandleLidSwitchExternalPower` | `ignore` | On AC, lid-close never suspends. This is the normal admin state. |
| `HandleLidSwitch` (battery) | `suspend` (default; unchanged) | Unplugged lid-closed laptops still save battery. |
| `HandleLidSwitchDocked` | `ignore` | Docked laptops never suspend on lid. |
| `IdleAction` | `ignore` | Idle never suspends. Long-running SSH sessions stay alive. |
| GNOME `sleep-inactive-ac-type` for `wyn` | `'nothing'` | GNOME session-level idle suspend on AC disabled. Belt-and-suspenders with the logind IdleAction. |
| GNOME `sleep-inactive-ac-type` for `verlyn13` | `'nothing'` | Same for the admin user when they have an active desktop session. |
| GNOME `idle-dim` for `wyn` and `verlyn13` | `false` | Screen does not dim on idle. Optional; debatable. |

Surfaces **not** touched: hibernate, `suspend.target` / `hybrid-sleep.target`
masking, kernel cmdline, LUKS, TPM, Secure Boot, firmware, BIOS, WoL,
sudoers, accounts, services other than `systemd-logind`, firewall,
DNS, DHCP, OPNsense, Cloudflare, WARP, Tailscale, 1Password.

## Executable Artifact

```text
script:     scripts/device-admin/fedora-top-power-policy-apply-v0.3.0.sh
sha256:     e28302253de495343e5adcb73f205f6ad4f1a4c24c986c167f1c497261d6c6e8
encoding:   ASCII (python: 14962 bytes, 0 bytes > 0x7F; 404 lines)
shell:      /usr/bin/bash on fedora-top
session:    SSH from MacBook as verlyn13
sudo:       required (verlyn13 NOPASSWD via /etc/sudoers.d/ansible-automation)
tools:      jq, systemctl, install, busctl
```

## Prerequisites

1. **Baseline apply record committed.**
   `docs/device-admin/fedora-top-power-policy-baseline-apply-2026-05-15.md`
   landed in git. The `08-summary.json` body in that apply record
   must include at least one of
   `diagnostic.lid_close_on_ac_will_suspend == true` or
   `diagnostic.idle_will_suspend == true`. If both are already false,
   the logind drop-in is a no-op; only the GNOME settings will change.
2. **fedora-top reachable**: `ssh fedora-top 'uptime'` returns
   without timeout.
3. **`sudo -n true` succeeds** for `verlyn13` (NOPASSWD grant per
   the privilege-cleanup record).
4. **Operator decision recorded** on these knobs (default values
   shown):
   - Battery lid-close: keep default `suspend` (yes, by default).
   - GNOME `idle-dim`: turn off (yes, by default).
   - Apply per-user GNOME settings for both `wyn` and `verlyn13`
     (yes, by default; per-user settings only apply when the user
     has an active session bus, otherwise the script records
     `session_bus_available: false` and continues).

## Approval Phrase

> Apply the `fedora-top-power-policy-apply-v0.3.0` script on
> fedora-top via SSH from the MacBook as `verlyn13`. The script
> installs `/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf`
> with `HandleLidSwitchExternalPower=ignore`, `HandleLidSwitchDocked=ignore`,
> and `IdleAction=ignore`, owned `root:root` mode `0644`. It
> `systemctl reload systemd-logind` (SIGHUP — does not drop sessions),
> reads back the effective config, and sets per-user GNOME
> `sleep-inactive-ac-type=nothing` and `idle-dim=false` for `wyn`
> and `verlyn13` if they have active session buses. Snapshots
> pre-existing files to the evidence directory before any edit.
> Return `08-summary.json` verbatim to system-config.

## Session Class

`scoped-live-change`. Surfaces mutated:

- `/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf` (create / overwrite)
- `systemd-logind` runtime (SIGHUP reload)
- GNOME per-user gsettings for `wyn` and `verlyn13` (only when session bus is available)
- Evidence directory `/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-apply-<ts>/` (write-only)

## Execute

```bash
# From the MacBook, in the system-config checkout:
scp scripts/device-admin/fedora-top-power-policy-apply-v0.3.0.sh \
    fedora-top:/var/tmp/

ssh fedora-top
# On the host:
cd /var/tmp
expected='e28302253de495343e5adcb73f205f6ad4f1a4c24c986c167f1c497261d6c6e8'
actual=$(sha256sum fedora-top-power-policy-apply-v0.3.0.sh | awk '{print $1}')
if [ "$actual" != "$expected" ]; then
    echo "sha256 mismatch: $actual vs $expected" >&2
    exit 1
fi
bash fedora-top-power-policy-apply-v0.3.0.sh
```

Stdin-piped form is also acceptable for this packet because the
script is idempotent and produces evidence regardless:

```bash
ssh fedora-top 'bash -s' < scripts/device-admin/fedora-top-power-policy-apply-v0.3.0.sh
```

## What The Script Does

| Step | Operation | Idempotent gate | Read-back |
|---|---|---|---|
| S0 | Preflight: confirm `id -un=verlyn13`, `hostname -s=fedora-top`, `sudo -n true`, `jq`/`systemctl`/`install` present | n/a | n/a |
| S1 | Snapshot `/etc/systemd/logind.conf` and every `.conf` in `/etc/systemd/logind.conf.d/` to `<evidence_dir>/snapshot/`. Snapshot effective `systemctl show systemd-logind` to `logind-effective.preinstall.txt`. | always run | n/a |
| S2 | Write drop-in to `/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf` only if current contents differ; verify mode `0644` and owner `root:root` | content-equal short-circuit | `stat -c %a %U:%G` |
| S3 | `systemctl reload systemd-logind` (SIGHUP, no session drop) | skip if S2 did not change anything | n/a |
| S4 | Read effective `HandleLidSwitchExternalPower`, `HandleLidSwitchDocked`, `IdleAction` and compare against targets | n/a | hard-stop + snapshot restore on mismatch |
| S5 | For `wyn` and `verlyn13`: if user has session bus at `/run/user/<uid>/bus`, set `org.gnome.settings-daemon.plugins.power.sleep-inactive-ac-type='nothing'` and `idle-dim=false`. If no session bus, record `session_bus_available: false` and continue. | only call `gsettings set` if needed (gsettings is idempotent on identical values) | `gsettings get` readback |
| S6 | Emit `08-summary.json` with before / after / drop-in / GNOME result | n/a | n/a |

## Hard Stops

The script self-halts (and the agent must surface the halt without
patching) on:

- Wrong SSH user or hostname.
- Missing required tool (`jq`, `systemctl`, `install`).
- `sudo -n true` failure.
- Drop-in mode or owner does not match `0644` / `root:root` after install.
- Post-reload effective `HandleLidSwitchExternalPower` != `ignore`,
  `HandleLidSwitchDocked` != `ignore`, or `IdleAction` != `ignore`
  (snapshot is restored and `systemctl reload` runs again).

Per
[windows-terminal-admin-spec.md §Packet-Defect Halt Rule](./windows-terminal-admin-spec.md)
(inherited via the Linux spec), parser / encoding / quoting /
serialization / state-normalization halts must not be locally
repaired by the agent. Preserve evidence, halt, hand back.

## Rollback

The snapshot under `<evidence_dir>/snapshot/` contains the
pre-install state. Manual revert:

```bash
# Remove the drop-in (if pre-install state did not have one).
sudo rm -f /etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf

# If pre-install state had drop-ins under /etc/systemd/logind.conf.d/,
# restore them from <evidence_dir>/snapshot/logind.conf.d/.

# Reload systemd-logind.
sudo systemctl reload systemd-logind

# Read back to confirm pre-install effective config.
systemctl show systemd-logind --property HandleLidSwitchExternalPower --value
systemctl show systemd-logind --property IdleAction --value

# GNOME settings: gsettings reset, or revert to the user's prior value.
DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u wyn)/bus" \
  sudo -u wyn gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
```

## Hand-Back: `08-summary.json` Schema

The agent returns `08-summary.json` verbatim. Required fields and
expected values for success:

| Field | Expected |
|---|---|
| `host` | `fedora-top` |
| `ssh_user` | `verlyn13` |
| `logind.after.handle_lid_switch_external_power` | `ignore` |
| `logind.after.idle_action` | `ignore` |
| `drop_in.path` | `/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf` |
| `policy_status.lid_close_on_ac_will_suspend_after` | `false` |
| `policy_status.idle_will_suspend_after` | `false` |
| `policy_status.lid_close_on_battery_will_suspend_after` | `true` |
| `gnome.wyn.applied` or `present` | `true` if `wyn` has a session bus, else `present: false` / `session_bus_available: false` |
| `gnome.verlyn13.applied` or `present` | same shape for `verlyn13` |

If `gnome.<user>.session_bus_available == false` for either user,
the per-user GNOME setting is a no-op for that user. That is not a
halt — record as evidence and let the user log into GNOME so the
setting takes effect on their next session.

## Out Of Scope

- **LUKS / TPM2 / FIDO2 remote-reboot strategy.** Coupled to power
  policy in prose but tracked as a separate decision in
  `current-status.yaml`'s `luks-remote-reboot-strategy` blocked_item.
- **`suspend.target` masking.** Not done. This packet leaves the
  ability to manually suspend (e.g., `systemctl suspend`) intact;
  it only stops `logind` from triggering it on lid/idle.
- **Hibernate / hybrid-sleep behavior.** Untouched.
- **Wake-on-LAN.** Not configured. If the laptop ever suspends
  intentionally (battery + lid close), it has to be woken physically.
- **Cloudflare WARP / off-LAN access.** Phase 5 work, separate gate.
- **BIOS-level power management** (e.g., wake-on-keyboard, lid
  behavior at the firmware level).

## After Apply

Update `docs/device-admin/current-status.yaml.devices[fedora-top]`:

- Add this packet to `applied_packets[]` with apply-record reference,
  packet commit, apply commit, applied_at, outcome.
- Resolve the prose-only "AC/no-sleep policy" item in the
  `current_management_status` and `fedora-44-laptop.md:460` notes.

Validation worth running by the operator:

```bash
# A. Confirm lid-close on AC does NOT suspend.
#    Plug in, close lid for 30 s, open lid. The SSH session
#    should still be alive. Verify with: ssh fedora-top 'uptime'.
#    The 'uptime' command should NOT show recent boot or
#    sleep/resume.

# B. Confirm idle does NOT suspend.
#    Leave the laptop alone for >IdleActionUSec interval (default
#    30 min). SSH session should remain alive. Repeat the uptime
#    check.

# C. Confirm battery lid-close STILL suspends (the intended battery
#    behavior). Unplug, close lid; the laptop should still suspend
#    to save battery. This is the operator's choice; if Wyn finds
#    it inconvenient, run a separate packet to broaden the policy.

# D. Check that journalctl now records the lid-close event WITHOUT
#    a suspend:
#    journalctl -u systemd-logind --since '5 minutes ago' --no-pager
```

## Cross-References

- [fedora-top-power-policy-baseline-2026-05-15.md](./fedora-top-power-policy-baseline-2026-05-15.md)
- [linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md) v0.1.0
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
