---
title: fedora-top Power Policy Baseline Packet - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, fedora-top, linux, power, suspend, logind, baseline, read-only]
priority: high
---

# fedora-top Power Policy Baseline Packet - 2026-05-15

Read-only baseline of fedora-top power/suspend posture, prompted by
the 2026-05-14 19:23:29 AKDT suspend-mid-SSH-session that dropped a
mid-edit Claude session on a shelltutor file. No host mutation.

This is the first packet under
[linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md) v0.1.0.
It conforms to the spec's Linux deltas (bash, ASCII-portable, JSON
evidence via `jq`, structured types not stringly typed) and the
inherited Windows-spec rules (§Packet Artifact Separation,
§Packet-Defect Halt Rule).

## Why This Packet Exists

The MacBook SSH session on 2026-05-14 19:23:29 AKDT received this
broadcast from `wyn@fedora-top` immediately before the transport died:

```
Broadcast message from wyn@fedora-top (Thu 2026-05-14 19:23:29 AKDT):
The system will suspend now!
```

After suspend, the laptop's network dropped; the MacBook SSH client
sat on the dead transport for ~30 s of keepalive misses, then closed:

```
Read from remote host 192.168.0.206: Operation timed out
Connection to 192.168.0.206 closed.
client_loop: send disconnect: Broken pipe
```

This is the failure the existing prose docs had warned about:

- `fedora-44-laptop.md:460`: "no sleep/hibernate on AC ... AC/no-sleep
  policy still needs deliberate verification before relying on remote
  availability."
- `fedora-top-complete-instructions.md:539`: "No sleep on AC while the
  laptop is expected to be remotely administered."
- `current-status.yaml` `luks-remote-reboot-strategy` blocked_item:
  "Affects AC/no-sleep policy."
- `fedora-top-prehardening-ingest-2026-05-13.md:169`: "journal shows
  suspend/resume events on 2026-05-12."

The intent has been recorded since 2026-05-13. This packet starts the
formal phase-4 work to apply it.

## Executable Artifact

The agent runs the named script directly. Do not transcribe content
from this Markdown into a separate file.

```text
script:     scripts/device-admin/fedora-top-power-policy-baseline-v0.1.0.sh
sha256:     3294f168d428067eb60c3936f2b6104ca51727632306d31eeaf9a47f9831970d
encoding:   ASCII (python: 17385 bytes, 0 bytes > 0x7F; 439 lines)
shell:      /usr/bin/bash on fedora-top (any modern bash)
session:    SSH from MacBook as verlyn13
sudo:       only for journalctl -u systemd-logind (optional)
```

The script can be transferred to the host via either of two
spec-conforming flows:

**Option A — scp + verify on host (recommended for evidence trail):**

```bash
# From the MacBook, in the system-config checkout:
scp scripts/device-admin/fedora-top-power-policy-baseline-v0.1.0.sh \
    fedora-top:/var/tmp/

ssh fedora-top
# On the host:
cd /var/tmp
expected='3294f168d428067eb60c3936f2b6104ca51727632306d31eeaf9a47f9831970d'
actual=$(sha256sum fedora-top-power-policy-baseline-v0.1.0.sh | awk '{print $1}')
if [ "$actual" != "$expected" ]; then
    echo "sha256 mismatch: $actual vs $expected" >&2
    exit 1
fi
bash fedora-top-power-policy-baseline-v0.1.0.sh
```

**Option B — pipe via stdin (no on-host persistence):**

```bash
# From the MacBook:
ssh fedora-top 'bash -s' < scripts/device-admin/fedora-top-power-policy-baseline-v0.1.0.sh
```

Both are read-only. Option A leaves an inspectable copy on the host;
Option B keeps the host filesystem unchanged. Prefer Option A for any
mutating packet.

## Prerequisites

1. fedora-top reachable: `ssh fedora-top 'uptime'` returns without
   timeout. Today's reality (2026-05-14 22:28 AKDT) is that the host
   is still suspended from the 19:23 event; this packet can only run
   after the laptop wakes. Use lid-open or power button on the
   physical device, OR wait for it to be powered up tomorrow.
2. SSH user `verlyn13` reaches the SSH lane as documented in
   [fedora-44-laptop.md](./fedora-44-laptop.md).
3. `jq` is installed on fedora-top (default on Fedora Workstation).
   The script halts early if not present.

## Approval Phrase

> Run the `fedora-top-power-policy-baseline-v0.1.0` script on
> fedora-top via SSH from the MacBook as `verlyn13`. The script is
> read-only and writes a JSON evidence directory under
> `/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-<timestamp>/`.
> Return the `08-summary.json` body verbatim to system-config as the
> hand-back. No host mutation. Do not change LUKS, TPM, Secure Boot,
> firmware, sleep targets, power policy, sudoers, accounts, services,
> firewall, DNS, DHCP, OPNsense, Cloudflare, WARP, or 1Password state.

## Session Class

`read-only-probe`. The script captures state and emits JSON; it does
not modify any file outside `/var/tmp/jefahnierocks-device-admin/`,
does not start/stop/reload any unit, does not call `gsettings set`,
does not write to `/etc/`.

## Hard Stops

Halt and hand back rather than improvise if:

- `ssh fedora-top` cannot connect (host still suspended) — operator
  physically wakes the laptop; do not bypass with WoL until the
  packet records the policy decision.
- `jq` is missing on fedora-top. Hand back the missing-tool error;
  do not `dnf install` from a baseline packet.
- The script's sha256 does not match the value declared above.
- `sudo -n` fails for the journalctl step. The script handles this
  gracefully (event counts come back as zero) but the operator
  should note the lost evidence in the hand-back.
- A baseline finding suggests the host has been mutated by another
  agent or process — surface the divergence, do not "fix" it.

## What The Script Captures

| File | Concern |
|---|---|
| `00-run.log` | Per-step timestamps. |
| `01-identity.json` | Hostname, SSH user, uname, OS id, shell. |
| `02-logind-conf.json` | On-disk `/etc/systemd/logind.conf` + every `.conf` in `/etc/systemd/logind.conf.d/`, with mode, owner, full contents. |
| `03-logind-effective.json` | Runtime values from `systemctl show systemd-logind` for `HandleLidSwitch`, `HandleLidSwitchExternalPower`, `HandleLidSwitchDocked`, `IdleAction`, `IdleActionUSec`, `HandlePowerKey`, `HandleSuspendKey`, `HandleHibernateKey`, `InhibitDelayMaxUSec`, `SuspendState`. Plus three booleans: `lid_close_on_ac_will_suspend`, `lid_close_on_battery_will_suspend`, `idle_will_suspend`. |
| `04-sleep-targets.json` | `sleep.target`, `suspend.target`, `hibernate.target`, `hybrid-sleep.target`, `suspend-then-hibernate.target`: active + enabled state. |
| `05-upower.json` | AC vs battery, battery percentage, battery state. |
| `06-gnome-power.json` | For `wyn` and `verlyn13` users: `org.gnome.settings-daemon.plugins.power.sleep-inactive-ac-type`, `sleep-inactive-battery-type`, `idle-dim`, `org.gnome.desktop.session.idle-delay`, `power-button-action`. Records `session_bus_available: false` if the user has no active session bus rather than failing. |
| `07-kernel-cmdline.json` | `/proc/cmdline`. |
| `08-summary.json` | **The hand-back.** One-page composite of the diagnostics. |
| `09-inhibitors.json` | `systemd-inhibit --list` output (held wake locks). |
| `10-recent-suspend-events.json` | Suspend/resume event counts from `journalctl -u systemd-logind --since '7 days ago'`, plus the last 100 raw log lines. |

## Hand-Back Schema

The agent returns `08-summary.json` verbatim. The fields are stable
strings and explicit booleans; system-config compares against
expected values listed below to decide what the apply packet should
do.

| Field | Type | Note |
|---|---|---|
| `host` | string | expected `fedora-top` or its FQDN |
| `ssh_user` | string | expected `verlyn13` |
| `logind.handle_lid_switch_external_power` | string | likely `suspend` (default) — this is the value the apply packet will change to `ignore` |
| `logind.handle_lid_switch_battery` | string | default `suspend`; apply packet leaves this alone per operator decision |
| `logind.idle_action` | string | likely `ignore` or absent — verify |
| `diagnostic.lid_close_on_ac_will_suspend` | bool | **expected `true` before the apply packet runs** |
| `diagnostic.lid_close_on_battery_will_suspend` | bool | expected `true` (default) |
| `diagnostic.idle_will_suspend` | bool | **drives the GNOME settings decision** |
| `sleep_targets["suspend.target"]` | string | expected `inactive` while not currently suspended; if `masked`, the apply packet's logind drop-in is redundant |
| `power.on_battery` | string/bool | `true` / `false` / `discharging` / etc. |
| `power.battery_state` | string | `charging`, `fully-charged`, `discharging`, `pending-charge` |
| `suspend_events_last_7d.suspend_count` | int | how many suspends were logged in the last 7 days (the 2026-05-14 19:23 event should be in this window) |
| `suspend_events_last_7d.resume_count` | int | the resume count should match — if it lags, the host suspended and didn't resume cleanly |

Tonight's 2026-05-14 19:23:29 suspend should appear in
`suspend_events_last_7d.suspend_count` along with the matching
`resume_count` after the laptop wakes.

## After Apply

The apply record
(`fedora-top-power-policy-baseline-apply-2026-05-15.md`) captures:

- The `08-summary.json` body verbatim.
- Any deviation from the expected values above (e.g., if
  `HandleLidSwitchExternalPower` is already `ignore`, the apply
  packet is a no-op and we record that).
- A go/no-go decision for the
  [fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md)
  packet.

## Boundaries

This packet does **not** authorize:

- Any change to `/etc/systemd/logind.conf` or `/etc/systemd/logind.conf.d/`.
- Any `gsettings set` for any user.
- Any `systemctl mask|unmask|reload|restart`.
- Any LUKS, TPM, Secure Boot, firmware, sleep target, hibernate, power
  button, kernel cmdline, or BIOS change.
- Any sudoers, account, group, firewall, DNS, DHCP, OPNsense,
  Cloudflare, WARP, Tailscale, or 1Password mutation.
- Wake-on-LAN configuration (the laptop is currently suspended; if
  WoL becomes part of the recovery, it's a separate packet).

## Cross-References

- [linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md) v0.1.0
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) v0.5.0 (parent for §Packet Artifact Separation, §Packet-Defect Halt Rule)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md) (the next packet)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
