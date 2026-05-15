---
title: fedora-top Power Policy Baseline Apply - 2026-05-15
category: operations
component: device_admin
status: applied
version: 0.4.0
last_updated: 2026-05-15
tags: [device-admin, fedora-top, linux, power, suspend, logind, baseline, evidence, read-only, phase-4]
priority: high
---

# fedora-top Power Policy Baseline Apply - 2026-05-15

Apply record for
[fedora-top-power-policy-baseline-2026-05-15.md](./fedora-top-power-policy-baseline-2026-05-15.md)
(packet v0.4.0). Read-only Phase 4 baseline; no live host change.

## Apply Context

```text
device:          fedora-top (fedora-top.home.arpa, 192.168.0.206)
applied_at:      2026-05-15T16:54:15Z
applied_by:      verlyn13@fedora-top (SSH from MacBook 192.168.0.10)
session_class:   read-only-probe
script:          scripts/device-admin/fedora-top-power-policy-baseline-v0.4.0.sh
script_sha256:   b0c411b06eae09a616a25ba1d65eba3f91e6a014ee4a3bc102c693b78feea2ae
script_commit:   a2e3f90
evidence_path:   /var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-20260515T165414Z/
                 (files 00-run.log, 01..10-*.json; host-private; not for repo)
```

## Hand-Back: 08-summary.json (verbatim)

```json
{
  "timestamp": "2026-05-15T16:54:15Z",
  "host": "fedora-top",
  "ssh_user": "verlyn13",
  "logind": {
    "handle_lid_switch_external_power": "",
    "handle_lid_switch_battery": "suspend",
    "handle_lid_switch_docked": "ignore",
    "idle_action": "ignore"
  },
  "diagnostic": {
    "lid_close_on_ac_will_suspend": true,
    "lid_close_on_battery_will_suspend": true,
    "idle_will_suspend": false
  },
  "sleep_targets": {
    "suspend.target": "unknown",
    "hibernate.target": "unknown"
  },
  "power": {
    "on_battery": "false",
    "battery_percent": "80%",
    "battery_state": "pending-charge"
  },
  "suspend_events_last_7d": {
    "suspend_count": 2,
    "resume_count": 2
  },
  "evidence_dir": "/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-20260515T165414Z"
}
```

## State Interpretation

- `logind.handle_lid_switch_external_power = ""` — empty. Per
  `logind.conf(5)`, behavior falls through to `HandleLidSwitch`.
  `HandleLidSwitch = "suspend"`, so lid-close on AC suspends. v0.4.0
  diagnostic correctly resolves the fallback and reports
  `lid_close_on_ac_will_suspend: true`.
- `idle_action = "ignore"` — the systemd default. Idle does not
  trigger suspend at the logind layer. GNOME-level idle is captured
  in `06-gnome-power.json`; see expected state below.
- `handle_lid_switch_docked = "ignore"` — set explicitly (matches
  systemd default; no fall-through needed).
- `suspend_events_last_7d`: `suspend_count: 2`, `resume_count: 2`.
  These are the post-2026-05-15 events captured within the
  7-day window after the laptop's restart. The 2026-05-14T19:23:29
  AKDT suspend that motivated this whole chain falls outside the
  window from this run timestamp, so the count is not a recount of
  every historical event — it is "events visible to journalctl
  --since '7 days ago' at the moment of capture".
- `sleep_targets.suspend.target = "unknown"`: `systemctl is-active
  suspend.target` returns `inactive` (exit 3), and the baseline
  script's `if state=$(... )` branch tests exit code. This is a
  minor script idiom defect (cosmetic; the target is simply not
  currently active because the system is not currently suspending).
  Not a blocker. Recorded for a future v0.5.0 polish if useful;
  does not affect the apply decision.

## Go / No-Go Decision For Apply

**Go.** The diagnostic surfaces the exact failure mode the apply
packet was authored to fix: lid-close on AC suspends because
`HandleLidSwitchExternalPower` is empty (default), which falls
through to `HandleLidSwitch = suspend`. The apply packet
[fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md)
(v0.2.0) writes `/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf`
with `HandleLidSwitchExternalPower=ignore`, `HandleLidSwitchDocked=ignore`,
and `IdleAction=ignore`, then reloads logind via SIGHUP.

Battery lid-close (`lid_close_on_battery_will_suspend: true`) is
preserved by intent — the apply leaves `HandleLidSwitch` at the
default `suspend` so an unplugged stowed laptop still saves battery.

## Packet-Defect History (this baseline run)

The 2026-05-15 baseline went through three packet revisions in one
session before producing a sound 08-summary.json. Each defect was
surfaced and handed back for a new packet version per
[linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md)
§Packet-Defect Halt Rule:

| Version | Defect | Resolution |
|---|---|---|
| v0.1.0 | step 10 `jq: Argument list too long` (E2BIG): full 7-day `journalctl -u systemd-logind` passed whole as `--arg raw` exceeded `getconf ARG_MAX` (~128 KB) | v0.2.0 truncates `events_raw` to last 500 lines in shell before passing to jq; counts still come from full output |
| v0.2.0 | step 03 captured all-empty strings for every logind manager property: `systemctl show systemd-logind` returns only service-unit props on systemd 259 (Fedora 44), not `org.freedesktop.login1.Manager` props; even `--property X --value` returns empty | v0.3.0 switches `get_prop` to busctl against `org.freedesktop.login1.Manager` with type-aware extractor for `s "value"`, `t N`, `b true|false`. Same defect existed latent in `fedora-top-power-policy-apply-v0.1.0.sh` step S4 read-back; apply bumped to v0.2.0 in parallel. |
| v0.3.0 | `lid_close_on_ac_will_suspend = false` despite actual behavior being suspend: case statement only matched literal `HandleLidSwitchExternalPower` value; empty value (the systemd default) did not match | v0.4.0 resolves empty `HandleLidSwitchExternalPower` to `HandleLidSwitch` before evaluating the diagnostic case |

Three preserved evidence directories on the host (do not delete
until apply record commits and operator is comfortable rotating
diagnostic artifacts):

- v0.1.0 partial run (E2BIG halt at step 10):
  `/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-20260515T162313Z/`
  (files 00..09 intact; 10 zero-byte; 08 not generated)
- v0.2.0 full run (all-empty manager props):
  `/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-20260515T162424Z/`
  (all files generated; values wrong)
- v0.3.0 full run (correct raw, wrong diagnostic):
  `/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-20260515T165052Z/`
  (all files generated; raw values correct; diagnostic misleading)
- v0.4.0 final run (this apply record):
  `/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-20260515T165414Z/`

## Ad-Hoc Drift During Investigation (now rolled back)

Before the packet framework was rediscovered in this session, an
ad-hoc logind drop-in was written and then rolled back:

- 2026-05-15T08:12 UTC: `/etc/systemd/logind.conf.d/10-keep-awake-on-ac.conf`
  installed via hand-rolled heredoc + `sudo systemctl restart systemd-logind`.
  Same target semantics as the canonical packet
  (`HandleLidSwitchExternalPower=ignore`,
  `HandleLidSwitchDocked=ignore`, `IdleAction=ignore`), but wrong
  filename (canonical is `20-jefahnierocks-no-suspend.conf`), wrong
  reload verb (`restart` rather than `reload`/SIGHUP), no snapshot,
  no structured evidence, no per-user GNOME apply, no apply record.
- 2026-05-15T08:22 UTC: rolled back. `sudo rm` the drop-in;
  `sudo systemctl reload systemd-logind` returned the host to true
  pre-policy state. The v0.4.0 baseline above captured the
  post-rollback state, which is the pre-canonical-apply state.

Lesson recorded in this apply record so the audit trail shows the
ad-hoc drift and its reversal; the canonical apply that follows
will install the correct drop-in with full evidence.

## Cross-References

- [fedora-top-power-policy-baseline-2026-05-15.md](./fedora-top-power-policy-baseline-2026-05-15.md)
- [fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md)
- [fedora-top-power-policy-directive-2026-05-15.md](./fedora-top-power-policy-directive-2026-05-15.md)
- [linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md) v0.1.0
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
