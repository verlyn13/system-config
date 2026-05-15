---
title: fedora-top Power Policy Apply Record - 2026-05-15
category: operations
component: device_admin
status: applied
version: 0.3.0
last_updated: 2026-05-15
tags: [device-admin, fedora-top, linux, power, suspend, logind, harden, evidence, phase-4]
priority: high
---

# fedora-top Power Policy Apply Record - 2026-05-15

Apply record for
[fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md)
(packet v0.3.0). Phase 4 scoped-live-change. Logind no-suspend
policy successfully installed and verified.

Prerequisite gate satisfied:
[fedora-top-power-policy-baseline-apply-2026-05-15.md](./fedora-top-power-policy-baseline-apply-2026-05-15.md)
committed at 39407d6 with `diagnostic.lid_close_on_ac_will_suspend = true`.

## Apply Context

```text
device:          fedora-top (fedora-top.home.arpa, 192.168.0.206)
applied_at:      2026-05-15T16:59:09Z
applied_by:      verlyn13@fedora-top (SSH from MacBook 192.168.0.10)
session_class:   scoped-live-change
script:          scripts/device-admin/fedora-top-power-policy-apply-v0.3.0.sh
script_sha256:   e28302253de495343e5adcb73f205f6ad4f1a4c24c986c167f1c497261d6c6e8
script_commit:   e437a2b
evidence_path:   /var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-apply-20260515T165907Z/
                 (files 00-run.log, 00-preflight.json, 01-before.json,
                  02-dropin.json, 03-after.json, 04-gnome.json,
                  08-summary.json, snapshot/; host-private; not for repo)
snapshot_path:   /var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-apply-20260515T165907Z/snapshot/
                 (pre-apply /etc/systemd/logind.conf.d/ contents and
                  systemctl show systemd-logind output; rollback source)
```

## Hand-Back: 08-summary.json (verbatim)

```json
{
  "timestamp": "2026-05-15T16:59:09Z",
  "host": "fedora-top",
  "ssh_user": "verlyn13",
  "logind": {
    "before": {
      "handle_lid_switch_external_power": "",
      "idle_action": "ignore"
    },
    "after": {
      "handle_lid_switch_external_power": "ignore",
      "idle_action": "ignore"
    }
  },
  "drop_in": {
    "path": "/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf",
    "changed_in_this_run": true
  },
  "gnome": {
    "wyn": {
      "user": "wyn",
      "present": true,
      "session_bus_available": false,
      "applied": false
    },
    "verlyn13": {
      "user": "verlyn13",
      "present": true,
      "session_bus_available": true,
      "applied": true,
      "sleep_inactive_ac_type": "'nothing'"
    }
  },
  "policy_status": {
    "lid_close_on_ac_will_suspend_after": false,
    "idle_will_suspend_after": false,
    "lid_close_on_battery_will_suspend_after": true
  },
  "evidence_dir": "/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-apply-20260515T165907Z"
}
```

## State Transition

| Surface | Before | After |
|---|---|---|
| `/etc/systemd/logind.conf.d/20-jefahnierocks-no-suspend.conf` | present from v0.2.0 failed run (mode 0644 root:root, content drifted by 1 comment line) | present (mode 0644 root:root, content canonical v0.3.0) |
| logind `HandleLidSwitchExternalPower` | `""` (default, falls through to `HandleLidSwitch=suspend`) | `"ignore"` |
| logind `HandleLidSwitchDocked` | `"ignore"` (systemd default) | `"ignore"` (now explicit in drop-in) |
| logind `IdleAction` | `"ignore"` (systemd default) | `"ignore"` (now explicit in drop-in) |
| `lid_close_on_ac_will_suspend` (effective) | `true` | `false` |
| `idle_will_suspend` (effective) | `false` | `false` |
| `lid_close_on_battery_will_suspend` (effective) | `true` | `true` (preserved by intent) |
| GNOME `sleep-inactive-ac-type` for `verlyn13` | (prior value not captured) | `'nothing'` |
| GNOME `sleep-inactive-ac-type` for `wyn` | (session bus not available; not captured) | (session bus not available; not applied) |
| GNOME `idle-dim` for `verlyn13` | (prior value not captured) | `false` |

systemd-logind reloaded via SIGHUP — no active sessions dropped.
All three multi-user sessions (verlyn13, ila, wyn manager + GNOME)
remained intact through the apply.

## GNOME Per-User Outcomes

- **verlyn13** (`session_bus_available: true`): apply succeeded.
  `sleep-inactive-ac-type` confirmed read-back as `'nothing'`.
  `idle-dim` set to `false` (no read-back captured for this key
  by the script; trust gsettings idempotency).
- **wyn** (`session_bus_available: false`): no active GNOME session
  bus at `/run/user/$(id -u wyn)/bus` at apply time. Per packet
  contract, this is **not a halt** — the per-user setting is a
  no-op for that user and will take effect on `wyn`'s next GNOME
  login. The logind-level policy is already in place for the whole
  machine, so `wyn`'s effective behavior is already correct; the
  per-user GNOME apply is belt-and-suspenders.

## Validation (operator-side, to be completed manually)

Per the directive's Step 3:

1. **A.** Confirm lid-close on AC does NOT suspend. Plug in (already
   on AC, battery 80% pending-charge per baseline), close lid for
   30 s, open lid. From the MacBook:
   `ssh fedora-top 'uptime; journalctl -u systemd-logind --since "1 minute ago" --no-pager'`.
   Expected: uptime unchanged; journalctl shows lid-close event but
   no suspend.
2. **B.** Confirm battery lid-close STILL suspends (intentional).
   Unplug AC, close lid; the laptop should still suspend.
3. **C.** Confirm idle does NOT suspend. Leave laptop alone for
   >30 min on AC. SSH session should stay alive; uptime should not
   advance through a sleep gap.

Validation not run in this apply record — operator decision; the
in-band test the user has been running all session is "we kept
working without the laptop dropping", which is the same evidence
class once policy is live. The first lid-close-on-AC after this
record commits will be the canonical proof.

## Packet-Defect History (this apply chain)

| Version | Defect | Resolution |
|---|---|---|
| v0.1.0 | step S4 `read_logind_prop` used `systemctl show systemd-logind --property X --value` which returns empty for logind manager props on systemd 259 (Fedora 44); read-back would have hard-stopped with snapshot restore on every host | v0.2.0 switches to busctl with type-aware extractor |
| v0.2.0 | first real run hard-stopped at S2 with `"drop-in mode/owner mismatch: 644 / root:root"`: `dropin_mode='0644'` string-compared against `stat -c '%a'` output `'644'` (GNU coreutils omits leading zero); also heredoc still referenced v0.1.0.sh | v0.3.0 changes `dropin_mode='644'` and updates heredoc reference |

Preserved evidence directories (do not delete until operator is
comfortable rotating diagnostic artifacts):

- v0.2.0 partial run (S2 mode-check halt):
  `/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-apply-20260515T165615Z/`
  (00-preflight.json, 01-before.json, 02-dropin.json present;
   later steps absent)
- v0.3.0 successful run (this apply record):
  `/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-apply-20260515T165907Z/`
  (all files; the canonical evidence trail)

## Ad-Hoc Drift Reconciliation

The ad-hoc drop-in at
`/etc/systemd/logind.conf.d/10-keep-awake-on-ac.conf` (installed
2026-05-15T08:12 UTC outside the packet framework) was rolled back
at 2026-05-15T08:22 UTC, before any canonical packet ran. See the
baseline apply record's "Ad-Hoc Drift During Investigation" section
for details. There is no residual ad-hoc state on disk; the only
file under `/etc/systemd/logind.conf.d/` is the canonical
`20-jefahnierocks-no-suspend.conf` installed by this packet.

## Cross-References

- [fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md)
- [fedora-top-power-policy-baseline-2026-05-15.md](./fedora-top-power-policy-baseline-2026-05-15.md)
- [fedora-top-power-policy-baseline-apply-2026-05-15.md](./fedora-top-power-policy-baseline-apply-2026-05-15.md)
- [fedora-top-power-policy-directive-2026-05-15.md](./fedora-top-power-policy-directive-2026-05-15.md)
- [linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md) v0.1.0
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
