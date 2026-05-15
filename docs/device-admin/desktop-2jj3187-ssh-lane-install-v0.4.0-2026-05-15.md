---
title: DESKTOP-2JJ3187 SSH Lane Install Packet v0.4.0 - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.4.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, openssh, admin-key, firewall, sshd-config, phase-3]
priority: high
---

# DESKTOP-2JJ3187 SSH Lane Install Packet v0.4.0 - 2026-05-15

Phase 3 greenfield install of the DESKTOP-2JJ3187 SSH admin lane.
Supersedes
[desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
v0.3.0, which had two packet defects (encoding + enum serialization)
and is preserved as the postmortem reference.

This packet conforms to
[windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
v0.5.0 — specifically §Packet Artifact Separation, §Encoding Contract,
§Cross-Shell Data Normalization, §Structured Evidence, and §Packet-
Defect Halt Rule. The executable artifact lives in
`scripts/device-admin/`. The agent **runs the named `.ps1` directly**;
do not transcribe content from this Markdown into a separate file.

## Executable Artifact

```text
script:      scripts/device-admin/desktop-2jj3187-ssh-lane-install-v0.4.0.ps1
sha256:      8bc1b29bb0391ca55c2262a0847c546e0252347c93e784e1c9358085bc474e0c
encoding:    ASCII (verified python: 20481 bytes, 0 bytes > 0x7F; 515 lines)
shell:       C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
invocation:  powershell.exe -NoProfile -ExecutionPolicy Bypass -File <full-path>\desktop-2jj3187-ssh-lane-install-v0.4.0.ps1
```

The pinned public-key body and fingerprint are embedded as constants
at the top of the script:

```text
PublicKeyBody       = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRgw1xN2rjmlIFbAPsp7cc6SJcm0h5IMvrL8o6CyLh9
ExpectedFingerprint = SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s
```

The script verifies the installed key fingerprint matches the pinned
value and halts otherwise. No transcription, no 1Password read from
the host, no manual paste.

## Prerequisites

1. **Reconciliation apply record committed.**
   [desktop-2jj3187-reconciliation-2026-05-15.md](./desktop-2jj3187-reconciliation-2026-05-15.md)
   applied and the apply record committed under
   `docs/device-admin/desktop-2jj3187-reconciliation-apply-2026-05-15.md`.
   The summary must show `OpenSSH.Server = NotPresent`,
   `sshd_exe_present = false`, `sshd_config_present = false`,
   `admin_authkeys_present = false`, no v0.3.0 mutation. If any of
   those is different, **halt** and have system-config refresh the
   packet before this v0.4.0 install applies.

2. **MacBook chezmoi conf.d already applied** (commit `f0fb9c1`).
   `ssh -G desktop-2jj3187` on the MacBook resolves to `jeffr` /
   `192.168.0.217` / HostKeyAlias `192.168.0.217` / IdentityFile
   `id_ed25519_desktop_2jj3187_admin.1password.pub`.

3. **1Password admin key item exists** (created 2026-05-14
   19:05 AKDT, fingerprint
   `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s`).

4. **v0.3.0 evidence preserved untouched.** Both the v0.3.0 markdown
   packet and any on-host evidence directories
   (`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-baseline-*`
   and any v0.3.0 install evidence dirs) remain intact for the
   postmortem trail.

## Approval Phrase

> Apply the `desktop-2jj3187-ssh-lane-install-v0.4.0` script on
> DESKTOP-2JJ3187 from an elevated Windows PowerShell 5.1 session
> (`powershell.exe`) as `DESKTOP-2JJ3187\jeffr`. The script installs
> the Windows OpenSSH Server capability, starts and enables `sshd`,
> ensures the standard `Match Group administrators` block,
> installs the Jefahnierocks hardening drop-in
> (`20-jefahnierocks-admin.conf`) with `Administrators+SYSTEM`-only
> ACL, installs the pinned admin public key
> `ssh-ed25519 ...IFRgw1xN2rjmlIFbAPsp7cc6SJcm0h5IMvrL8o6CyLh9`
> into `administrators_authorized_keys` with the same ACL,
> verifies the installed-key fingerprint matches
> `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s`, disables the
> broad `OpenSSH-Server-In-TCP` rule, creates
> `Jefahnierocks SSH LAN TCP 22` (Private profile, RemoteAddress
> `192.168.0.0/24`), `sshd -t` passes, restarts `sshd`, and reads
> back the conditional effective config. JSON evidence lands at
> `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<timestamp>\`.
> Return `08-summary.json` verbatim to system-config. After the
> apply record commits, the operator MacBook runs
> `ssh desktop-2jj3187 'cmd /c "hostname && whoami"'`.

## Session Class

`scoped-live-change`. Surfaces mutated:

- Windows OpenSSH Server capability (install if `NotPresent`)
- `sshd` service (`StartType=Automatic`, `Status=Running`)
- `C:\ProgramData\ssh\sshd_config` (verify Match block; append if missing)
- `C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf` (create or overwrite)
- `C:\ProgramData\ssh\administrators_authorized_keys` (create / idempotent append + ACL)
- Windows Firewall: `Jefahnierocks SSH LAN TCP 22` (create / re-shape), `OpenSSH-Server-In-TCP` (disable)
- Evidence directory (write-only)

Not touched: accounts, groups, ACLs outside the SSH paths,
BitLocker, Defender, RDP rules, WinRM, scheduled tasks, Codex
sandbox accounts, network profile, DNS, DHCP, OPNsense, Cloudflare,
WARP, Tailscale, 1Password.

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
   $expected = '8bc1b29bb0391ca55c2262a0847c546e0252347c93e784e1c9358085bc474e0c'
   $actual   = (Get-FileHash -Algorithm SHA256 `
       -LiteralPath '<full-path-to>\desktop-2jj3187-ssh-lane-install-v0.4.0.ps1').Hash.ToLower()
   if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
   ```

   If the sha256 does not match, **halt and hand back**. Do not run
   the script. The exact bytes the packet referred to are what must
   execute.

## Execute

From the elevated WinPS 5.1 session, having confirmed sha256:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  '<full-path-to>\desktop-2jj3187-ssh-lane-install-v0.4.0.ps1'
```

The script prints step-by-step progress, writes JSON evidence under
the per-run evidence directory, and self-halts on any unexpected
state (identity mismatch, wrong shell, unexpected DISM enum,
fingerprint mismatch, `sshd -t` failure, post-restart service not
running, missing effective-config directives).

## What the Script Does

Each step is idempotent and read-back-gated. Detailed code is in the
`.ps1`; this is a description for the runbook reader.

| Step | Operation | Idempotent gate | Read-back |
|---|---|---|---|
| S0 | Identity + elevation preflight | hostname / user / shell-major match | n/a (terminates if mismatch) |
| S1 | `Get-WindowsCapability OpenSSH.Server*`; normalize enum to string in this shell; `Add-WindowsCapability` only if state is `NotPresent` | skip if already `Installed`; halt on any other state | re-query, must read `Installed` |
| S2 | `Set-Service sshd Automatic`; `Start-Service sshd` | only set/start if not already so | `Get-Service sshd`, must be Running+Automatic |
| S3 | Confirm `Match Group administrators` → `AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys` is in `sshd_config`; backup `sshd_config` to snapshot before any edit; append the stock block only if absent | regex check; skip if present | `sshd -t` must pass; if not, restore from snapshot and halt |
| S4 | Install `sshd_config.d\20-jefahnierocks-admin.conf` (`PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `PermitRootLogin no`, `PubkeyAuthentication yes`, `LogLevel INFO`, `AllowGroups administrators`); apply Admins+SYSTEM-only ACL | overwrite drop-in (snapshotted first); ACL set idempotently | `sshd -t` must pass; if not, remove drop-in and halt |
| S5 | Validate pinned key shape; snapshot `administrators_authorized_keys` if it exists; append the pinned key body only if not already present; apply Admins+SYSTEM-only ACL; `ssh-keygen -lf` fingerprint readback must match pinned value | skip append if key body already there; halt on fingerprint mismatch | `ssh-keygen -lf` matches pinned fingerprint |
| S6 | Disable `OpenSSH-Server-In-TCP` if present and enabled; create or re-shape `Jefahnierocks SSH LAN TCP 22` (Private, TCP/22, RemoteAddress `192.168.0.0/24`) | skip enable if already enabled; idempotent re-shape | rule fields read back |
| S7 | `sshd -t`; `Restart-Service sshd`; conditional `sshd -T -C user=jeffr,host=desktop-2jj3187.home.arpa,addr=127.0.0.1` | always run | halts unless effective config includes `pubkeyauthentication yes`, `passwordauthentication no`, `kbdinteractiveauthentication no`, `strictmodes yes`, `loglevel INFO`, `authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys`, `allowgroups administrators` |
| S8 | Final summary JSON | n/a | n/a |

## Evidence Layout

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<UTC-yyyymmddThhmmssZ>\
  00-preflight.json
  00-run.log                  (timestamped step log)
  01-capability-before.json
  01-capability-add.json       (only if Add-WindowsCapability ran)
  01-capability-after.json
  02-service.json
  03-match-block.json
  04-dropin.json
  05-admin-keys.json
  06-firewall.json
  07-sshd-effective.json
  08-summary.json              (hand-back to system-config)
  snapshot/
    sshd_config.preinstall
    20-jefahnierocks-admin.conf.preinstall   (if it existed before)
    administrators_authorized_keys.preinstall (if it existed before)
```

All JSON via `ConvertTo-Json -Depth 8` + `Set-Content -Encoding utf8`.

## Hard Stops

The script self-halts (and the agent must surface the halt without
patching) on any of:

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
- Pinned public key body does not match the expected `ssh-ed25519
  <body>(<comment>)?` shape.
- Installed key fingerprint does not match the pinned
  `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s`.
- After S7, the conditional `sshd -T` readback is missing any of:
  `pubkeyauthentication yes`, `passwordauthentication no`,
  `kbdinteractiveauthentication no`, `strictmodes yes`,
  `loglevel INFO`, `authorizedkeysfile __PROGRAMDATA__/...`,
  `allowgroups administrators`.

Per
[windows-terminal-admin-spec.md §Packet-Defect Halt Rule](./windows-terminal-admin-spec.md),
**the agent does not patch a halt locally**. It surfaces the halt
class as a hand-back and waits for the next packet version.

## Hand-Back: `08-summary.json` Schema

Return verbatim. System-config writes
`docs/device-admin/desktop-2jj3187-ssh-lane-install-v0.4.0-apply-2026-05-15.md`
with this body.

Required fields and expected values for success:

| Field | Expected |
|---|---|
| `script` | `desktop-2jj3187-ssh-lane-install-v0.4.0.ps1` |
| `computer` | `DESKTOP-2JJ3187` |
| `user` | `jeffr` |
| `shell` | `Desktop 5.1.x.x` |
| `openssh_capability` | `Installed` |
| `sshd_service_status` | `Running` |
| `sshd_service_starttype` | `Automatic` |
| `match_block_present` | `true` |
| `expected_fingerprint` | `SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s` |
| `firewall_rule` | `Jefahnierocks SSH LAN TCP 22` |
| `firewall_scope` | `192.168.0.0/24` |
| `listener_22[].local_port` | `22` (count >= 1) |
| `effective_config.pubkeyauth` | `true` |
| `effective_config.passwordauth_off` | `true` |
| `effective_config.kbdinteractive_off` | `true` |
| `effective_config.strictmodes_on` | `true` |
| `effective_config.loglevel_info` | `true` |
| `effective_config.auth_keys_file` | `true` |
| `effective_config.allow_groups_admin` | `true` |

## Rollback

The script writes snapshot copies of `sshd_config`,
`20-jefahnierocks-admin.conf` (if pre-existing), and
`administrators_authorized_keys` (if pre-existing) to
`<evidence-dir>\snapshot\` before any edit. Manual rollback if the
operator chooses to revert after a successful apply:

```powershell
# Stop service.
Stop-Service -Name sshd

# Restore sshd_config from snapshot.
Copy-Item -LiteralPath '<evidence-dir>\snapshot\sshd_config.preinstall' `
          -Destination 'C:\ProgramData\ssh\sshd_config' -Force

# Remove drop-in (or restore prior if pre-existing).
Remove-Item -LiteralPath 'C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf' -Force

# Remove or restore administrators_authorized_keys.
# If snapshot exists: Copy-Item ... .preinstall -> ...
# Else: Remove-Item ...
Remove-Item -LiteralPath 'C:\ProgramData\ssh\administrators_authorized_keys' -Force

# Disable scoped rule, re-enable broad default if needed.
Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' |
  Disable-NetFirewallRule
Get-NetFirewallRule -DisplayName 'OpenSSH-Server-In-TCP' |
  Enable-NetFirewallRule

# Optionally Remove-WindowsCapability if reverting to NotPresent.
```

## After Apply

Update
`docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- Add this packet to `applied_packets[]` with apply record reference.
- Set `lifecycle_phase: 3` and `classification: reference-ssh-host`.
- Update `remote_admin_paths[]` SSH lane from `planned-after-install`
  to live.

Operator MacBook runs the real-auth probe:

```bash
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

Expected: `DESKTOP-2JJ3187` / `desktop-2jj3187\jeffr`.

After the probe passes, DESKTOP-2JJ3187 is at SSH-managed parity with
MAMAWORK. Followup packets (separate, approval-gated):
`desktop-2jj3187-ssh-hardening` (tighten StrictModes / drop-in
review), `desktop-2jj3187-known-hosts-reconciliation` (drop the
`HostKeyAlias 192.168.0.217` from MacBook conf.d once the FQDN
known_hosts entry is added), `desktop-2jj3187-cloudflared-cleanup`,
`desktop-2jj3187-cloudflare-warp-cutover` (blocked on cloudflare-dns
Windows multi-user rebaseline).
