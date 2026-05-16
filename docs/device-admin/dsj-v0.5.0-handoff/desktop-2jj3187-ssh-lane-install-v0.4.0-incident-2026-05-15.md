---
title: DESKTOP-2JJ3187 v0.4.0 SSH Lane Install Incident - 2026-05-15
category: operations
component: device_admin
status: incident-recorded
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, openssh, incident, postmortem, partial-apply, superseded]
priority: high
---

# DESKTOP-2JJ3187 v0.4.0 SSH Lane Install Incident - 2026-05-15

The v0.4.0 SSH lane install
([desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md))
applied steps S1-S6 cleanly on DESKTOP-2JJ3187 and then halted at S7
when the effective-config readback (`sshd -T -C user=jeffr,…`) did
not contain the hardening directives that the drop-in file
`C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf`
declared. This is a packet-design defect that fits the spec's
[§Packet-Defect Halt Rule](./windows-terminal-admin-spec.md);
the script halted correctly and made no further mutations.

## Halt classification

`scoped-live-change` packet, **partial apply, halted before
verification gate**.

- **Halt step:** S7 (`Restart sshd and conditional effective-config
  readback`).
- **Halt class:** state-normalization mismatch — effective config
  readback missing expected directive (specifically
  `passwordauthentication no`, which the drop-in declared but
  `sshd` did not see).
- **Host mutation actually performed (S1-S6):**
  1. S1 — OpenSSH Server capability installed via DISM.
  2. S2 — `sshd` service set to Automatic + Running.
  3. S3 — `Match Group administrators` block confirmed present in
     `sshd_config` (no edit; the block ships in the Microsoft
     default — see below).
  4. S4 — drop-in file `20-jefahnierocks-admin.conf` written, ACL
     applied (`PasswordAuthentication no`, `KbdInteractiveAuthentication
     no`, `PermitRootLogin no`, `PubkeyAuthentication yes`,
     `LogLevel INFO`, `AllowGroups administrators`).
  5. S5 — admin public key (fingerprint
     `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s`) appended
     to `administrators_authorized_keys` with Admins+SYSTEM-only ACL.
  6. S6 — `Jefahnierocks SSH LAN TCP 22` firewall rule
     created/verified (Private profile, TCP/22, RemoteAddress
     192.168.0.0/24); broad OpenSSH default rule disabled.
- **Host mutation NOT performed:** none beyond S1-S6. S7's
  `Restart-Service sshd` did run (the post-S4 readback gate `sshd
  -t` passed), and the effective-config readback then failed — at
  that point the script `throw`s without further mutation.

## Root cause

**Wrong assumption:** the v0.4.0 packet assumed that Microsoft's
default `sshd_config` (the file dropped onto the host by
`Add-WindowsCapability OpenSSH.Server*`) contains an
`Include sshd_config.d/*.conf` directive — the convention common
to Linux distros that ship OpenSSH 8.2+. The drop-in pattern in S4
depends on `sshd` auto-loading the file.

**Reality:** Microsoft's `sshd_config` ships with no `Include`
directive. The drop-in file is silently ignored by `sshd`.
Authoritative source:

```text
https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/sshd_config
```

The file is 94 lines. It has two non-commented global directives
(`AuthorizedKeysFile .ssh/authorized_keys` and `Subsystem sftp
sftp-server.exe`) followed by a single `Match Group administrators`
block at the bottom. No `Include` anywhere.

Consequence at S7:

- `sshd -T -C user=jeffr,host=desktop-2jj3187.home.arpa,addr=127.0.0.1`
  returned defaults plus the Match-block-derived
  `authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys`.
- The expected directives the S7 read-back asserted from the drop-in
  (`passwordauthentication no`, `kbdinteractiveauthentication no`,
  `allowgroups administrators`) were absent.
- The S7 foreach loop iterated `pubkeyauth` (present by default,
  value `yes`) → ok, then `passwordauth_off` (default is `yes`,
  expected `no`) → **throw**.

The defect is in the packet, not the host. The drop-in pattern is
sound; the install script must also inject the `Include` directive
that activates it.

## Confirming evidence layout

The v0.4.0 evidence directory on the host
(`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<UTC-timestamp>\`)
contains the canonical evidence for this incident. Per the
[§Packet-Defect Halt Rule](./windows-terminal-admin-spec.md), it
must remain preserved untouched:

- `00-preflight.json` — identity/elevation/shell-major confirmed
- `00-run.log` — timestamped step-by-step trace
- `01-capability-*.json` — DISM enum normalized to string in WinPS 5.1
- `02-service.json` — sshd service Automatic + Running
- `03-match-block.json` — `block_present: true; wrote_in_this_run:
  false` (Match block was already there, as the Microsoft default
  ships it)
- `04-dropin.json` — drop-in installed at its expected path with
  Admins+SYSTEM ACL
- `05-admin-keys.json` — public key appended; ssh-keygen
  fingerprint matches pinned value
- `06-firewall.json` — Jefahnierocks SSH LAN TCP 22 enabled,
  Private, scoped to 192.168.0.0/24
- `07-sshd-effective.json` — the readback that failed; this is
  where the `passwordauth_off: false` row lives. **Most direct
  evidence of the bug.**
- `snapshot\sshd_config.preinstall` — pre-edit copy of the
  Microsoft default `sshd_config` (S3 snapshot). Useful to
  confirm the upstream default matches the Microsoft GitHub
  reference cited above.

The evidence does not need to be copied to the repo. The
references above plus the upstream `sshd_config` source are
authoritative for the postmortem.

## Spec response

`windows-terminal-admin-spec.md` now has a `§Windows OpenSSH
Defaults` section (added in the same commit chain as this incident
record). It states:

- The upstream source is the authority — agents must consult it
  before designing any packet that touches `sshd_config`.
- Microsoft's default does not include `Include`; any drop-in
  approach must inject the directive explicitly with snapshot +
  idempotent gate.
- `Match Group administrators` is at the bottom of the default and
  the standard since 1809; "ensure Match block" steps should
  no-op when the regex finds it (which is what v0.4.0's S3 already
  did, correctly).
- Forward slashes are the convention even on Windows for
  `sshd_config` paths.

That section is the doc-clarity change that should have existed
before v0.4.0 shipped.

## Forward path

**v0.5.0** (sibling packet
`desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md`) adds a
new step **S3b** between S3 (Match block) and S4 (drop-in) that
ensures `Include sshd_config.d/*.conf` is at the top of
`sshd_config`, idempotently, snapshotted before edit, with `sshd
-t` gate. Everything else in v0.5.0 is unchanged from v0.4.0; the
existing idempotent gates in S1, S2, S3, S4, S5, S6 will read
"already done" on re-apply against the v0.4.0 partial-apply host
state, and only S3b + the S7 restart-and-readback need to do work.

The v0.4.0 packet markdown stays preserved on disk with a
SUPERSEDED notice (same pattern as v0.3.0). The v0.4.0 evidence
directory on the host stays preserved untouched. No
`Set-Content`, `Remove-Item`, or rotation against either of those
artifacts is in scope for v0.5.0.

## Lessons learned

The v0.3.0 / v0.4.0 / v0.5.0 sequence has now produced three
distinct spec sections, each named for a class of Windows-OpenSSH
deviation from Linux-OpenSSH assumptions:

| Spec section | Origin failure | Class |
|---|---|---|
| `§Encoding Contract` | v0.3.0 mojibake | shell-default difference (WinPS 5.1 vs UTF-8) |
| `§Cross-Shell Data Normalization` | v0.3.0 enum-as-int | serialization difference |
| `§Windows OpenSSH Defaults` | v0.4.0 no-Include | upstream-default difference |

The common pattern across all three: assume Linux-distro / POSIX
default → ship → fail → write spec section. The forward-looking
guard is the last paragraph of `§Windows OpenSSH Defaults`:
**before drafting a packet that touches `sshd_config`, read the
upstream Microsoft file.** That single check is the inversion of
the failure pattern.

## Cross-references

- [desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md) (the superseded packet)
- [desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md) (the replacement)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) `§Windows OpenSSH Defaults`
- [desktop-2jj3187-windows-side-directive-2026-05-15.md](./desktop-2jj3187-windows-side-directive-2026-05-15.md) (now points at v0.5.0)
- [desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md) (Phase 0 baseline; correctly captured pre-install state)
- [desktop-2jj3187-reconciliation-apply-2026-05-15.md](./desktop-2jj3187-reconciliation-apply-2026-05-15.md) (pre-v0.4.0 reconciliation; correctly captured pre-install state)
- Upstream: https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/sshd_config
