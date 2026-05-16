---
title: DESKTOP-2JJ3187 Reconciliation Apply - 2026-05-15
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, openssh, reconciliation, read-only, phase-3-prep, evidence]
priority: high
---

# DESKTOP-2JJ3187 Reconciliation Apply - 2026-05-15

Apply record for
[desktop-2jj3187-reconciliation-2026-05-15.md](./desktop-2jj3187-reconciliation-2026-05-15.md)
(v0.1.0). Read-only probe; no host mutation.

## Apply Context

```text
device:           DESKTOP-2JJ3187
applied_at:       2026-05-15T23:36:40Z
applied_by:       DESKTOP-2JJ3187\jeffr (elevated Windows PowerShell 5.1, Desktop 5.1.26100.8457)
session_class:    read-only-probe
executable:       scripts/device-admin/desktop-2jj3187-reconciliation-v0.1.0.ps1
executable_sha256: 4cd75bcb8f31857d53a02a2de29fa94f73700c882ebb6b739154f26261dc8b43
                   (verified on host before execution)
evidence_dir:     C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-reconciliation-20260515T233616Z\
                  (host-local; 10 files including 00-run.json … 08-summary.json;
                  not copied into repo)
```

## Hand-Back: `08-summary.json` (returned verbatim)

```json
{
    "computer":  "DESKTOP-2JJ3187",
    "expected_computer":  "DESKTOP-2JJ3187",
    "user":  "jeffr",
    "expected_user":  "jeffr",
    "shell":  "Desktop 5.1.26100.8457",
    "expected_shell_match":  true,
    "admin_role":  true,
    "high_mandatory_level":  true,
    "openssh_capability_present":  true,
    "openssh_capability_state":  "NotPresent",
    "sshd_exe_present":  false,
    "sshd_config_present":  false,
    "admin_authkeys_present":  false,
    "sshd_service_status":  "",
    "sshd_service_starttype":  "",
    "tcp_22_listening":  false,
    "tcp_3389_listening":  true,
    "jefahnierocks_ssh_rule":  false,
    "jefahnierocks_rdp_tcp_rule":  true,
    "jefahnierocks_rdp_udp_rule":  true,
    "evidence_dir":  "C:\\Users\\Public\\Documents\\jefahnierocks-device-admin\\desktop-2jj3187-reconciliation-20260515T233616Z",
    "finished_at":  "2026-05-15T23:36:40.4930246Z"
}
```

## Acceptance Gate: All Expected Fields Match

All 20 fields in the [reconciliation packet's Hand-Back schema table](./desktop-2jj3187-reconciliation-2026-05-15.md#hand-back-08-summaryjson-schema)
match the expected values verbatim:

| Field | Expected | Observed | Match |
|---|---|---|---|
| `computer` | `DESKTOP-2JJ3187` | `DESKTOP-2JJ3187` | ✓ |
| `expected_computer` | `DESKTOP-2JJ3187` | `DESKTOP-2JJ3187` | ✓ |
| `user` | `jeffr` | `jeffr` | ✓ |
| `expected_user` | `jeffr` | `jeffr` | ✓ |
| `shell` | `Desktop 5.1.x.x` | `Desktop 5.1.26100.8457` | ✓ |
| `expected_shell_match` | `true` | `true` | ✓ |
| `admin_role` | `true` | `true` | ✓ |
| `high_mandatory_level` | `true` | `true` | ✓ |
| `openssh_capability_present` | `true` | `true` | ✓ |
| `openssh_capability_state` | `NotPresent` | `NotPresent` | ✓ |
| `sshd_exe_present` | `false` | `false` | ✓ |
| `sshd_config_present` | `false` | `false` | ✓ |
| `admin_authkeys_present` | `false` | `false` | ✓ |
| `sshd_service_status` | empty | `""` | ✓ |
| `sshd_service_starttype` | empty | `""` | ✓ |
| `tcp_22_listening` | `false` | `false` | ✓ |
| `tcp_3389_listening` | `true` | `true` | ✓ |
| `jefahnierocks_ssh_rule` | `false` | `false` | ✓ |
| `jefahnierocks_rdp_tcp_rule` | `true` | `true` | ✓ |
| `jefahnierocks_rdp_udp_rule` | `true` | `true` | ✓ |

The two self-check fields (`expected_shell_match`, plus the
`expected_computer`/`expected_user` mirrors) confirm the script
itself agreed with the operator-facing identity proof before
emitting the summary.

## What This Confirms

- **No drift from Phase 0 baseline** (apply record
  [desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md),
  commit `00ee787`, 2026-05-15T03:26:52Z).
- **No v0.3.0 §S2/§S5/§S6/§S7 mutation occurred.** The v0.3.0
  install halt in §S1 is now objectively confirmed to have been a
  pre-mutation halt:
  - `openssh_capability_state: NotPresent` (DISM enum, normalized
    through WinPS 5.1's structured emit — not the integer `0` the
    v0.3.0 `ConvertTo-Json -Compress` produced).
  - `sshd_exe_present`, `sshd_config_present`,
    `admin_authkeys_present`, `tcp_22_listening`,
    `jefahnierocks_ssh_rule` all `false` — no install/config/key/
    listener/firewall mutation.
  - `sshd_service_status` and `sshd_service_starttype` empty —
    the service itself does not exist.
- **RDP lane intact.** `tcp_3389_listening: true`,
  `jefahnierocks_rdp_tcp_rule: true`, `jefahnierocks_rdp_udp_rule:
  true`. RDP-only-host classification holds today.
- **Elevation confirmed.** `admin_role: true` +
  `high_mandatory_level: true` — script ran in an elevated WinPS
  5.1 token, not a UAC-split shell.
- **Shell choice enforced.** `shell: "Desktop 5.1.26100.8457"` —
  Windows PowerShell 5.1 (host name `ConsoleHost` /
  `$PSVersionTable.PSVersion` major `5`), not pwsh 7. The build
  number `26100.8457` is the Windows 11 24H2 servicing build for
  the bundled WinPS 5.1 ([documented OS build is 26200 per the
  Phase 0 baseline](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md);
  WinPS reports the engine version, not the OS build, so these are
  not in conflict).

## Stop Rules Observed

None tripped. Specifically:

- sha256 of the executable matched the packet pin
  `4cd75bcb...8b43` before run.
- Identity proof matched (`DESKTOP-2JJ3187` / `jeffr`).
- `$PSVersionTable.PSVersion.Major` was `5`.
- v0.3.0 evidence directory was preserved (the operator-side
  hand-back confirmed evidence moved to
  `evidence\desktop-2jj3187-reconciliation-20260515T233616Z\`
  without disturbing the v0.3.0 trail).
- No `08-summary.json` field deviated from the expected table.
- No out-of-scope surface (BitLocker, Defender, WARP, cloudflared,
  registry, DNS, account, RDP rule, WinRM, Secure Boot) was touched.

The session ran read-only as declared by `session_class:
read-only-probe`.

## Consequence: v0.4.0 Install Unblocked

Per the [Windows-side directive's Hand-back checkpoint](./desktop-2jj3187-windows-side-directive-2026-05-15.md#step-1--reconciliation-read-only),
the v0.4.0 install packet's blocked-on-reconciliation gate is
released by this apply record landing in git.

The v0.4.0 install
([desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md),
script sha256
`8bc1b29bb0391ca55c2262a0847c546e0252347c93e784e1c9358085bc474e0c`)
may now run, subject to its own approval phrase, sha256 verification,
shell-choice gate, and the [§Packet-Defect Halt Rule](./windows-terminal-admin-spec.md)
that the spec v0.5.0 introduced after the v0.3.0 incident.

The other prerequisites for v0.4.0 were already in place before
this apply:

- 1Password admin key item
  `op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13`
  exists with public key fingerprint
  `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s` (created
  2026-05-14T19:05:13-08:00, keypair generated in-place by 1Password).
- MacBook chezmoi conf.d applied at commit `f0fb9c1`
  ([macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md));
  `ssh -G desktop-2jj3187` resolves to `jeffr` / `192.168.0.217` /
  IdentityFile `~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub`.

## After This Apply

Update `docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- Move `desktop-2jj3187-reconciliation` from `prepared_packets[]`
  to `applied_packets[]` with this apply record reference.
- Change `desktop-2jj3187-ssh-lane-install` state from
  `approval-required-blocked-on-reconciliation` to
  `approval-required` in both `prepared_packets[]` and the
  `approval_required[]` section.
- Update `next_recommended_action` to point at the v0.4.0 install
  packet now that it is unblocked.

The device remains `lifecycle_phase: 2` / classification
`rdp-only-host` until the v0.4.0 install apply lands and the
MacBook real-auth probe succeeds — that transition is the v0.4.0
install's responsibility, not this reconciliation's.

## Cross-References

- [desktop-2jj3187-reconciliation-2026-05-15.md](./desktop-2jj3187-reconciliation-2026-05-15.md) (packet)
- [desktop-2jj3187-windows-side-directive-2026-05-15.md](./desktop-2jj3187-windows-side-directive-2026-05-15.md)
- [desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md) (now unblocked)
- [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md) (v0.3.0 SUPERSEDED; preservation confirmed)
- [desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md) (Phase 0 baseline)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) v0.5.0
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
