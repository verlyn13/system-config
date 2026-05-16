---
title: DESKTOP-2JJ3187 SSH Lane Install v0.5.0 Apply - 2026-05-16
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, phase-3, install, evidence, partial-success]
priority: high
---

# DESKTOP-2JJ3187 SSH Lane Install v0.5.0 Apply - 2026-05-16

Apply record for
[desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md)
(packet v0.5.0). All eight install steps completed cleanly on the
host; the MacBook real-auth probe (a downstream verification step
performed from the operator workstation) failed with a server-side
connection reset at SSH KEX. The install itself is **applied**;
the probe failure is tracked separately as a Phase 3 blocker — see
"Downstream Blocker" below.

## Apply Context

```text
device:           DESKTOP-2JJ3187
applied_at:       2026-05-16T02:09:17Z
applied_by:       DESKTOP-2JJ3187\jeffr (elevated Windows PowerShell 5.1, Desktop 5.1.26100.8457)
session_class:    scoped-live-change
executable:       scripts/device-admin/desktop-2jj3187-ssh-lane-install-v0.5.0.ps1
executable_sha256: a4df7f944ba87bce439af03698ba715c6a4e871e7887ebfa49aa39ad1240928c
                   (verified on host before execution)
evidence_dir:     C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-20260516T020851Z\
                  (host-local; 13 files including 00-preflight.json …
                  08-summary.json plus snapshot/; not copied to repo)
                  Preserved alongside the v0.4.0 partial-apply
                  evidence directory.
```

## Hand-Back: `08-summary.json` (returned verbatim)

```json
{
    "script":  "desktop-2jj3187-ssh-lane-install-v0.5.0.ps1",
    "finished_at":  "2026-05-16T02:09:17.8924046Z",
    "computer":  "DESKTOP-2JJ3187",
    "user":  "jeffr",
    "shell":  "Desktop 5.1.26100.8457",
    "openssh_capability":  "Installed",
    "sshd_service_status":  "Running",
    "sshd_service_starttype":  "Automatic",
    "match_block_present":  true,
    "include_directive":  "Include sshd_config.d/*.conf",
    "include_present":  true,
    "drop_in_path":  "C:\\ProgramData\\ssh\\sshd_config.d\\20-jefahnierocks-admin.conf",
    "admin_keys_path":  "C:\\ProgramData\\ssh\\administrators_authorized_keys",
    "expected_fingerprint":  "SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s",
    "firewall_rule":  "Jefahnierocks SSH LAN TCP 22",
    "firewall_scope":  "192.168.0.0/24",
    "listener_22":  [
                        {"local_port": 22, "local_address": "::", "owning_pid": 18188},
                        {"local_port": 22, "local_address": "0.0.0.0", "owning_pid": 18188}
                    ],
    "effective_config":  {
                             "pubkeyauth":           true,
                             "passwordauth_off":     true,
                             "kbdinteractive_off":   true,
                             "strictmodes_on":       true,
                             "loglevel_info":        true,
                             "auth_keys_file":       true,
                             "allow_groups_admin":   true
                         },
    "evidence_dir":  "C:\\Users\\Public\\Documents\\jefahnierocks-device-admin\\desktop-2jj3187-ssh-install-20260516T020851Z"
}
```

## Acceptance Gate

The packet's [Hand-Back schema table](./desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md#hand-back-08-summaryjson-schema)
required all of these to be true. Field-by-field:

| Field | Expected | Observed | Match |
|---|---|---|---|
| `script` | `desktop-2jj3187-ssh-lane-install-v0.5.0.ps1` | same | ✓ |
| `computer` | `DESKTOP-2JJ3187` | same | ✓ |
| `user` | `jeffr` | same | ✓ |
| `shell` | `Desktop 5.1.x.x` | `Desktop 5.1.26100.8457` | ✓ |
| `openssh_capability` | `Installed` | `Installed` | ✓ |
| `sshd_service_status` | `Running` | `Running` | ✓ |
| `sshd_service_starttype` | `Automatic` | `Automatic` | ✓ |
| `match_block_present` | `true` | `true` | ✓ |
| `include_directive` | `Include sshd_config.d/*.conf` | same | ✓ |
| `include_present` | `true` | `true` | ✓ — **this is the v0.4.0 → v0.5.0 fix landing** |
| `drop_in_path` | `…\sshd_config.d\20-jefahnierocks-admin.conf` | same | ✓ |
| `admin_keys_path` | `…\administrators_authorized_keys` | same | ✓ |
| `expected_fingerprint` | `SHA256:0oDYmXRFr…+/s` | same | ✓ |
| `firewall_rule` | `Jefahnierocks SSH LAN TCP 22` | same | ✓ |
| `firewall_scope` | `192.168.0.0/24` | same | ✓ |
| `listener_22[].local_port` | `22` | `22` × 2 (IPv4 + IPv6) | ✓ |
| `effective_config.pubkeyauth` | `true` | `true` | ✓ |
| `effective_config.passwordauth_off` | `true` | `true` | ✓ — **was `false` in v0.4.0 → halt; now drop-in is in effect** |
| `effective_config.kbdinteractive_off` | `true` | `true` | ✓ |
| `effective_config.strictmodes_on` | `true` | `true` | ✓ |
| `effective_config.loglevel_info` | `true` | `true` | ✓ |
| `effective_config.auth_keys_file` | `true` | `true` | ✓ |
| `effective_config.allow_groups_admin` | `true` | `true` | ✓ — **drop-in directive now loaded via Include** |

All 23 fields pass.

## What This Confirms

- **The S3b Include-injection fix landed cleanly.** `Include
  sshd_config.d/*.conf` is in effect at the top of
  `C:\ProgramData\ssh\sshd_config`. `sshd -T` reads all six drop-in
  directives (passwordauthentication, kbdinteractiveauthentication,
  pubkeyauthentication, loglevel, allowgroups, plus the Match-block
  authorizedkeysfile override).
- **v0.4.0 partial-apply state was correctly resumed.** S1
  (capability) was already Installed, S2 (service) Running+Automatic,
  S3 (Match block) present, S4 (drop-in) present, S5 (admin key)
  present with matching fingerprint, S6 (firewall rule) present.
  The idempotent gates read each as "already done" and only S3b +
  S7 (restart + readback) did new work.
- **Per-shell normalization, encoding discipline, and packet-defect
  halt rule all behaved correctly.** sha256 verified before run,
  no encoding issues, no parser failures, no enum-as-int mishaps,
  no local-repair improvisation. The discipline from v0.3.0 and
  v0.4.0 incidents held.

## Stop Rules Observed

None tripped during the install run.

## Downstream Blocker: MacBook Real-Auth Probe Failed

Per the v0.5.0 packet's
[§Step 3 — MacBook real-auth probe](./desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md#after-apply)
the operator MacBook ran:

```bash
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

Expected: `DESKTOP-2JJ3187\njeffr`.

Observed: **connection reset by 192.168.0.217 at SSH KEX**.

The TCP handshake completes, the SSH banners exchange, the client
sends `SSH2_MSG_KEXINIT`, and the Windows sshd resets the
connection without responding. Reproducible across configurations
(with/without HostKeyAlias, with/without IdentityAgent, with
restricted KEX and HostKey algorithm lists, with `-F /dev/null`).
`ssh-keyscan -t ed25519 192.168.0.217` returns banner-only — the
same KEX-stage failure. The MacBook client itself works against
other hosts (verified `ssh -T git@github.com` → `Hi verlyn13!`).

This is **not** an install defect — the install is in the state
the packet's acceptance gate verified, byte-for-byte. The failure
is in a code path that v0.5.0's S7 does not actually exercise:

> **Finding (v0.5.0 verification gap):** `sshd -T -C
> user=jeffr,host=…,addr=127.0.0.1` proves the configuration
> *parses* with those parameters in mind. It does not open a
> real TCP listener for an incoming test connection. The seven
> `effective_config: true` flags in the hand-back are necessary
> but not sufficient for end-to-end connectivity.

The next install-packet version (and any future Windows-OpenSSH
install packet) should include a real-loopback test before S8 —
something like `Test-NetConnection 127.0.0.1 -Port 22` plus an
actual `ssh -i <pinned-key> -o BatchMode=yes 127.0.0.1 hostname`
from the host itself. That gap is recorded as a spec evolution
item.

The connection-reset diagnosis happens through a separate read-
only-probe packet:
[desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md).
That packet pulls `OpenSSH/Operational` event log entries,
`sshd.log` contents, service/listener state, and ACLs on the
relevant files — the data needed to identify root cause from the
MacBook side once the hand-back arrives.

## After This Apply

`docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- Move `desktop-2jj3187-ssh-lane-install` from
  `prepared_packets[]` to `applied_packets[]` with this apply
  record reference (v0.5.0).
- `approval_required[]` entry `desktop-2jj3187-ssh-lane-install`
  → `state: applied`, `packet_version: 0.5.0`.
- Add `approval_required[]` entry for
  `desktop-2jj3187-ssh-kex-reset-diagnostic` (read-only-probe,
  `state: approval-required`).
- Add `blocked_items[]` entry
  `desktop-2jj3187-real-auth-probe-failure` with diagnostic plan
  referenced.
- **Keep `lifecycle_phase: 2`** and `classification:
  rdp-only-host`. The classification flip to `reference-ssh-host`
  is gated on the real-auth probe succeeding, not on the install
  apply record. Until the connection reset is diagnosed and
  resolved, the device's working remote-admin lane is still RDP.
- Repoint `next_recommended_action.preferred_packet` to the
  diagnostic.

The on-host v0.4.0 partial-apply evidence dir and the v0.5.0
install evidence dir both remain preserved untouched. v0.4.0 and
v0.3.0 packet markdowns remain SUPERSEDED-noticed in the repo.

## Cross-References

- [desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md) (the packet)
- [desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md) (next read-only probe)
- [desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md) (v0.4.0 postmortem; explains the S3b origin)
- [desktop-2jj3187-reconciliation-apply-2026-05-15.md](./desktop-2jj3187-reconciliation-apply-2026-05-15.md) (the pre-install reconciliation)
- [desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md) (the Phase 0 baseline)
- [desktop-2jj3187-windows-side-directive-2026-05-15.md](./desktop-2jj3187-windows-side-directive-2026-05-15.md) (the agent directive)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) — §Windows OpenSSH Defaults, §Encoding Contract, §Cross-Shell Data Normalization, §Packet-Defect Halt Rule
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
