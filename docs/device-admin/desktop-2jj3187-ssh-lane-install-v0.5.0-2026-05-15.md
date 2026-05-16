---
title: DESKTOP-2JJ3187 SSH Lane Install Packet v0.5.0 - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.5.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, openssh, admin-key, firewall, sshd-config, include-directive, phase-3]
priority: high
---

# DESKTOP-2JJ3187 SSH Lane Install Packet v0.5.0 - 2026-05-15

Phase 3 install of the DESKTOP-2JJ3187 SSH admin lane.

Supersedes
[desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md)
v0.4.0, which applied S1-S6 cleanly and halted at S7 because
Microsoft's default `sshd_config` does not contain an `Include`
directive (the drop-in at
`C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf` was
silently ignored). Full root-cause analysis:
[desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md).
The new spec section that should have caught the v0.4.0 assumption
upfront:
[windows-terminal-admin-spec.md `§Windows OpenSSH Defaults`](./windows-terminal-admin-spec.md).

This packet conforms to spec v0.5.0+ — specifically
§Packet Artifact Separation, §Encoding Contract,
§Cross-Shell Data Normalization, §Structured Evidence,
§Windows OpenSSH Defaults, and §Packet-Defect Halt Rule. The
executable artifact lives in `scripts/device-admin/`. The agent
**runs the named `.ps1` directly**; do not transcribe content
from this Markdown into a separate file.

## What Changed From v0.4.0

Only one operational change vs. v0.4.0: a new step **S3b** between
S3 (Match block) and S4 (drop-in) that ensures
`Include sshd_config.d/*.conf` is present at the top of
`C:\ProgramData\ssh\sshd_config`. Without this directive, the
drop-in file installed in S4 is invisible to `sshd`.

S3b properties:

- **Idempotent.** If the Include directive is already present
  (regex match, case-insensitive, leading/trailing whitespace
  tolerated), skip with no edit.
- **Snapshot before edit.** Writes
  `<evidence-dir>\snapshot\sshd_config.pre-include-inject` before
  mutation.
- **`sshd -t` gate.** Restores from snapshot and throws if config
  syntax is broken after the edit.
- **Read-back.** Re-reads `sshd_config` and confirms the line is
  present; throws if `Set-Content` reported success but the line
  is missing.

Everything else in v0.5.0 is identical to v0.4.0. The v0.4.0
mutations through S6 are idempotent — re-running on a host where
v0.4.0 already applied S1-S6 reads each step as "already done"
and only S3b + the S7 restart-and-readback do new work.

## Executable Artifact

```text
script:      scripts/device-admin/desktop-2jj3187-ssh-lane-install-v0.5.0.ps1
sha256:      a4df7f944ba87bce439af03698ba715c6a4e871e7887ebfa49aa39ad1240928c
encoding:    ASCII (verified python: 24513 bytes, 0 bytes > 0x7F; 600 lines, LF)
shell:       C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
invocation:  powershell.exe -NoProfile -ExecutionPolicy Bypass -File <full-path>\desktop-2jj3187-ssh-lane-install-v0.5.0.ps1
```

The pinned public-key body and fingerprint are embedded as
constants at the top of the script (unchanged from v0.4.0):

```text
PublicKeyBody       = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRgw1xN2rjmlIFbAPsp7cc6SJcm0h5IMvrL8o6CyLh9
ExpectedFingerprint = SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s
```

## Prerequisites

One of the following is sufficient. The script self-detects host
state via idempotent gates; the operator only needs to confirm
the appropriate `system-config`-side prerequisite is met.

### A. v0.4.0 partial-apply case (expected for DESKTOP-2JJ3187 today)

1. **v0.4.0 incident record committed.**
   `docs/device-admin/desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md`
   exists in the repo and the v0.4.0 packet markdown carries a
   SUPERSEDED notice at the top.
2. **v0.4.0 evidence preserved on host.** The on-host directory
   `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<v0.4.0-timestamp>\`
   has not been modified, rotated, or deleted. The v0.4.0 `.ps1`
   file has not been edited.
3. **1Password admin key item exists** (created 2026-05-14
   19:05 AKDT, fingerprint
   `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s`).
4. **MacBook chezmoi conf.d already applied** (commit `f0fb9c1`).
5. Re-running v0.5.0 will read S1-S6 as already-done and only run
   S3b (Include injection) + S7 (restart + readback).

### B. Fresh-host case

1. **Reconciliation apply record committed.** Summary shows
   `OpenSSH.Server = NotPresent`, all SSH paths absent. (Today's
   apply: `docs/device-admin/desktop-2jj3187-reconciliation-apply-2026-05-15.md`,
   commit `4fef412`.)
2. **MacBook chezmoi conf.d already applied** (commit `f0fb9c1`).
3. **1Password admin key item exists** (same fingerprint as above).
4. **v0.3.0 evidence preserved untouched** (its markdown carries a
   SUPERSEDED notice; on-host evidence dirs intact).

## Approval Phrase

> Apply the `desktop-2jj3187-ssh-lane-install-v0.5.0` script on
> DESKTOP-2JJ3187 from an elevated Windows PowerShell 5.1 session
> (`powershell.exe`) as `DESKTOP-2JJ3187\jeffr`. The script
> installs the Windows OpenSSH Server capability (skip if already
> installed), starts and enables `sshd`, ensures the standard
> `Match Group administrators` block, **ensures
> `Include sshd_config.d/*.conf` at the top of `sshd_config`**,
> installs the Jefahnierocks hardening drop-in
> (`20-jefahnierocks-admin.conf`) with `Administrators+SYSTEM`-only
> ACL, installs the pinned admin public key
> `ssh-ed25519 ...IFRgw1xN2rjmlIFbAPsp7cc6SJcm0h5IMvrL8o6CyLh9`
> into `administrators_authorized_keys` with the same ACL,
> verifies the installed-key fingerprint matches
> `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s`, disables
> the broad `OpenSSH-Server-In-TCP` rule, creates
> `Jefahnierocks SSH LAN TCP 22` (Private profile, RemoteAddress
> `192.168.0.0/24`), `sshd -t` passes at every config edit, and
> the post-restart conditional `sshd -T` readback shows the
> drop-in directives are in effect. Each script step is
> idempotent against the v0.4.0 partial-apply host state. JSON
> evidence lands at
> `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<UTC-timestamp>\`.
> Return `08-summary.json` verbatim to system-config. After the
> apply record commits, the operator MacBook runs
> `ssh desktop-2jj3187 'cmd /c "hostname && whoami"'`.

## Session Class

`scoped-live-change`. Surfaces mutated:

- Windows OpenSSH Server capability (install if `NotPresent`)
- `sshd` service (`StartType=Automatic`, `Status=Running`)
- `C:\ProgramData\ssh\sshd_config`:
  - verify `Match Group administrators` block; append if missing
  - **ensure `Include sshd_config.d/*.conf` at top; prepend if missing** (new in v0.5.0)
- `C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf` (create or overwrite)
- `C:\ProgramData\ssh\administrators_authorized_keys` (create / idempotent append + ACL)
- Windows Firewall: `Jefahnierocks SSH LAN TCP 22` (create / re-shape), `OpenSSH-Server-In-TCP` (disable)
- Evidence directory (write-only)

Not touched: accounts, groups, ACLs outside the SSH paths,
BitLocker, Defender, RDP rules, WinRM, scheduled tasks, Codex
sandbox accounts, network profile, DNS, DHCP, OPNsense,
Cloudflare, WARP, Tailscale, 1Password.

## Preflight (operator, before invoking the script)

1. RDP into DESKTOP-2JJ3187 as `DESKTOP-2JJ3187\jeffr`.
2. Open **elevated Windows PowerShell 5.1**:

   ```text
   Start menu → search "Windows PowerShell" → right-click → Run as
   administrator.
   ```

   Confirm via:

   ```powershell
   $PSVersionTable.PSVersion
   ```

   Expected: `Major=5  Minor=1`. If you see `7.x`, close the window
   and reopen Windows PowerShell — do **not** continue under pwsh 7.
3. Identity proof:

   ```powershell
   hostname
   whoami
   ```

   Expected: `DESKTOP-2JJ3187` / `DESKTOP-2JJ3187\jeffr`.
4. **Verify script integrity** before invocation:

   ```powershell
   $expected = 'a4df7f944ba87bce439af03698ba715c6a4e871e7887ebfa49aa39ad1240928c'
   $actual   = (Get-FileHash -Algorithm SHA256 `
       -LiteralPath '<full-path-to>\desktop-2jj3187-ssh-lane-install-v0.5.0.ps1').Hash.ToLower()
   if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
   ```

   If the sha256 does not match, **halt and hand back**. Do not
   run the script. The exact bytes the packet referred to are
   what must execute.

5. **Confirm the v0.4.0 evidence directory is intact.** Do not
   delete, rename, or modify it; v0.5.0 writes to a new
   timestamped directory.

## Execute

From the elevated WinPS 5.1 session, having confirmed sha256:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  '<full-path-to>\desktop-2jj3187-ssh-lane-install-v0.5.0.ps1'
```

The script prints step-by-step progress, writes JSON evidence
under the per-run evidence directory, and self-halts on any
unexpected state (identity mismatch, wrong shell, unexpected DISM
enum, fingerprint mismatch, `sshd -t` failure, post-restart
service not running, missing effective-config directives).

## What the Script Does

Each step is idempotent and read-back-gated. Detailed code is in
the `.ps1`; this is a description for the runbook reader.

| Step | Operation | Idempotent gate | Read-back |
|---|---|---|---|
| S0 | Identity + elevation preflight | hostname / user / shell-major match | n/a (terminates if mismatch) |
| S1 | `Get-WindowsCapability OpenSSH.Server*`; normalize enum to string in this shell; `Add-WindowsCapability` only if state is `NotPresent` | skip if already `Installed`; halt on any other state | re-query, must read `Installed` |
| S2 | `Set-Service sshd Automatic`; `Start-Service sshd` | only set/start if not already so | `Get-Service sshd`, must be Running+Automatic |
| S3 | Confirm `Match Group administrators` → `AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys` is in `sshd_config`; backup `sshd_config` to snapshot before any edit; append the stock block only if absent | regex check; skip if present | `sshd -t` must pass; if not, restore from snapshot and halt |
| **S3b** | **Ensure `Include sshd_config.d/*.conf` at top of `sshd_config`; snapshot before edit; prepend the directive line only if not present** | **regex check; skip if present** | **`sshd -t` must pass; if not, restore from snapshot. Read-back: re-read `sshd_config` and confirm the line is present.** |
| S4 | Install `sshd_config.d\20-jefahnierocks-admin.conf` (`PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `PermitRootLogin no`, `PubkeyAuthentication yes`, `LogLevel INFO`, `AllowGroups administrators`); apply Admins+SYSTEM-only ACL | overwrite drop-in (snapshotted first); ACL set idempotently | `sshd -t` must pass; if not, remove drop-in and halt |
| S5 | Validate pinned key shape; snapshot `administrators_authorized_keys` if it exists; append the pinned key body only if not already present; apply Admins+SYSTEM-only ACL; `ssh-keygen -lf` fingerprint readback must match pinned value | skip append if key body already there; halt on fingerprint mismatch | `ssh-keygen -lf` matches pinned fingerprint |
| S6 | Disable `OpenSSH-Server-In-TCP` if present and enabled; create or re-shape `Jefahnierocks SSH LAN TCP 22` (Private, TCP/22, RemoteAddress `192.168.0.0/24`) | skip enable if already enabled; idempotent re-shape | rule fields read back |
| S7 | `sshd -t`; `Restart-Service sshd`; conditional `sshd -T -C user=jeffr,host=desktop-2jj3187.home.arpa,addr=127.0.0.1` | always run | halts unless effective config includes `pubkeyauthentication yes`, `passwordauthentication no`, `kbdinteractiveauthentication no`, `strictmodes yes`, `loglevel INFO`, `authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys`, `allowgroups administrators` |
| S8 | Final summary JSON | n/a | n/a |

## Evidence Layout

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<UTC-yyyymmddThhmmssZ>\
  00-preflight.json
  00-run.log                          (timestamped step log)
  01-capability-before.json
  01-capability-add.json              (only if Add-WindowsCapability ran)
  01-capability-after.json
  02-service.json
  03-match-block.json
  03b-include-directive.json          (new in v0.5.0)
  04-dropin.json
  05-admin-keys.json
  06-firewall.json
  07-sshd-effective.json
  08-summary.json                     (hand-back to system-config)
  snapshot/
    sshd_config.preinstall                       (pre-S3 snapshot)
    sshd_config.pre-include-inject               (pre-S3b snapshot; only if S3b wrote)
    20-jefahnierocks-admin.conf.preinstall       (only if pre-existed)
    administrators_authorized_keys.preinstall    (only if pre-existed)
```

All JSON written via `ConvertTo-Json -Depth 8` +
`Set-Content -Encoding utf8`.

## Hard Stops

The script self-halts (and the agent must surface the halt
without patching) on any of:

- Identity mismatch (hostname or user).
- Wrong shell (`$PSVersionTable.PSVersion.Major != 5`).
- Not in Administrators role / no high-mandatory token.
- `Get-WindowsCapability` returns no OpenSSH.Server entry.
- Capability state is anything other than `Installed` or `NotPresent`.
- Post-S1 readback does not show `Installed`.
- `Set-Service` / `Start-Service` fails or service does not reach
  `Running` after start.
- `sshd_config` absent after capability install.
- `sshd -t` fails at any point after a config edit.
- **S3b: read-back fails to find `Include sshd_config.d/*.conf`
  after writing.**
- Pinned public key body does not match the expected `ssh-ed25519
  <body>(<comment>)?` shape.
- Installed key fingerprint does not match the pinned
  `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s`.
- `sshd` does not reach `Running` after `Restart-Service` at S7.
- Conditional `sshd -T` readback at S7 misses any of the seven
  expected directives.
- Any error from `New-NetFirewallRule` / `Set-NetFirewallRule` /
  `Get-NetFirewallRule`.

Per spec [§Packet-Defect Halt Rule](./windows-terminal-admin-spec.md),
none of these are operator-fixable on the host. Preserve evidence
and the failed script verbatim and hand back. Do not re-encode,
re-author, or rotate the evidence directory.

## Hand-Back: `08-summary.json` Schema

The agent returns `08-summary.json` verbatim. Stable string/bool
fields:

| Field | Expected | Why |
|---|---|---|
| `script` | `desktop-2jj3187-ssh-lane-install-v0.5.0.ps1` | self-identification |
| `computer` | `DESKTOP-2JJ3187` | identity |
| `user` | `jeffr` | identity |
| `shell` | `Desktop 5.1.x.x` | shell choice |
| `openssh_capability` | `Installed` | S1 result |
| `sshd_service_status` | `Running` | S2/S7 result |
| `sshd_service_starttype` | `Automatic` | S2 result |
| `match_block_present` | `true` | S3 result |
| `include_directive` | `Include sshd_config.d/*.conf` | S3b result |
| `include_present` | `true` | S3b read-back |
| `drop_in_path` | `C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf` | S4 result |
| `admin_keys_path` | `C:\ProgramData\ssh\administrators_authorized_keys` | S5 result |
| `expected_fingerprint` | `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s` | S5 pinned value |
| `firewall_rule` | `Jefahnierocks SSH LAN TCP 22` | S6 result |
| `firewall_scope` | `192.168.0.0/24` | S6 result |
| `listener_22[].local_port` | `22` | post-restart |
| `effective_config.pubkeyauth` | `true` | S7 readback |
| `effective_config.passwordauth_off` | `true` | S7 readback (was `false` in v0.4.0 → halt) |
| `effective_config.kbdinteractive_off` | `true` | S7 readback |
| `effective_config.strictmodes_on` | `true` | S7 readback |
| `effective_config.loglevel_info` | `true` | S7 readback |
| `effective_config.auth_keys_file` | `true` | S7 readback (Match block routes admins) |
| `effective_config.allow_groups_admin` | `true` | S7 readback (drop-in via Include) |
| `evidence_dir` | absolute path on host | for the apply record |

Any field that is `false` or missing is a packet defect → halt
and hand back.

## Rollback

The script halts on the first error rather than attempting full
rollback, because partial rollback of an interleaved sequence is
worse than evidence preservation. If the operator needs to revert
specific surfaces, the snapshots are deterministic per file:

```powershell
# Restore sshd_config to pre-install state (S3 snapshot).
Copy-Item `
  -LiteralPath '<evidence-dir>\snapshot\sshd_config.preinstall' `
  -Destination 'C:\ProgramData\ssh\sshd_config' -Force

# Restore sshd_config to pre-Include-injection state (S3b snapshot;
# only exists if S3b actually wrote).
Copy-Item `
  -LiteralPath '<evidence-dir>\snapshot\sshd_config.pre-include-inject' `
  -Destination 'C:\ProgramData\ssh\sshd_config' -Force

# Remove drop-in (or restore prior if pre-existing).
Remove-Item -LiteralPath 'C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf' -Force

# Restore administrators_authorized_keys (or remove if it did not exist).
Copy-Item `
  -LiteralPath '<evidence-dir>\snapshot\administrators_authorized_keys.preinstall' `
  -Destination 'C:\ProgramData\ssh\administrators_authorized_keys' -Force

# Disable the scoped firewall rule.
Disable-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22'
```

OpenSSH capability and `sshd` service are intentionally not
rolled back automatically; if needed, the operator can:

```powershell
Stop-Service -Name sshd
Set-Service -Name sshd -StartupType Manual
Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

## After Apply

System-config writes
`docs/device-admin/desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-15.md`
with the returned `08-summary.json` body, confirms the seven
`effective_config` flags are all true, and commits.

Then, from the operator MacBook:

```bash
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

Expected:

```text
DESKTOP-2JJ3187
desktop-2jj3187\jeffr
```

That is the real-auth probe. On success:

- DESKTOP-2JJ3187 moves to `lifecycle_phase: 3` /
  `classification: reference-ssh-host` in `current-status.yaml`.
- Follow-on packets (ssh-hardening, known-hosts-reconciliation)
  are unblocked.

## Cross-References

- [desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md) (v0.4.0 postmortem)
- [desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md) (SUPERSEDED packet, preserved)
- [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md) (v0.3.0 SUPERSEDED, preserved)
- [desktop-2jj3187-reconciliation-apply-2026-05-15.md](./desktop-2jj3187-reconciliation-apply-2026-05-15.md)
- [desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md)
- [desktop-2jj3187-windows-side-directive-2026-05-15.md](./desktop-2jj3187-windows-side-directive-2026-05-15.md)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) — particularly §Windows OpenSSH Defaults, §Encoding Contract, §Cross-Shell Data Normalization, §Packet-Defect Halt Rule
- [handback-format.md](./handback-format.md)
- Upstream Microsoft sshd_config default: https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/sshd_config
