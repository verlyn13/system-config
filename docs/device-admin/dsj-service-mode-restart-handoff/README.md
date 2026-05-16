---
title: DESKTOP-2JJ3187 SSH Service-Mode Restart - Handoff Bundle
category: operations
component: device_admin
status: active
version: 0.2.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, service-mode, handoff, bundle, rca-anchored]
priority: high
---

# DESKTOP-2JJ3187 SSH Service-Mode Restart - Handoff Bundle

**v0.2.0 update (2026-05-16)**: re-aligned to the RCA. The
operator's manual diagnostic + browser of Microsoft's repair
script gap identified the canonical root cause:
`Add-WindowsCapability OpenSSH.Server*` on Windows 11 24H2 is
**incomplete** — it installs binaries and creates the service
entry but does NOT create the `sshd` virtual user, grant LSA
privileges, or apply the NTFS ACL on `C:\ProgramData\ssh\`. The
fix is to fetch Microsoft's stripped-from-payload repair
scripts and run them. Full RCA in this bundle:
`desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md`.

This README's Step 1 used to be "just try Start-Service" (the
pre-RCA speculation). That has been replaced with the
RCA-anchored fix block as Step 1, since the RCA shows the
install is not actually complete and a plain restart cannot
help.

---

## Status snapshot (end of 2026-05-16)

- **SSH lane proven** end-to-end via foreground sshd test
  (MacBook -> DSJ over LAN, KEX + auth + command exec + clean
  disconnect, host ED25519 key
  `SHA256:OFNLsVw4RJlChJef1Db+eelKZnqJfPsVYLkNPVED6V8` now in
  MacBook `~/.ssh/known_hosts`).
- **Bug isolated to service-mode-only.** Foreground sshd
  succeeds; service-mode sshd RSTs at KEXINIT. Root cause is
  the incomplete capability install (see RCA).
- **sshd service currently stopped** on the host (after the
  operator's foreground test ended). Port 22 has no listener
  as of 2026-05-16T~04:00Z. MacBook ssh probe currently
  times out (TCP).
- **No additional manual changes pending** beyond what the RCA
  documents. v0.5.0 + v0.4.0 + v0.1.0-diagnostic on-host
  evidence dirs are all preserved untouched per spec §Packet-
  Defect Halt Rule.

## Step 1 (primary path, RCA-anchored): Microsoft repair scripts

The operator's fix block, quoted verbatim from the RCA. Run
from elevated Windows PowerShell 5.1 on DESKTOP-2JJ3187:

```powershell
# 1. Reset state: stop service and remove any half-configured
#    sshd virtual user from prior manual attempts
Stop-Service sshd -ErrorAction SilentlyContinue
Remove-LocalUser -Name 'sshd' -ErrorAction SilentlyContinue

# 2. Remove ad-hoc debug lines added to sshd_config during the
#    diagnostic phase (SyslogFacility / LogLevel). The drop-in
#    still has LogLevel INFO which gets included.
$cfg = 'C:\ProgramData\ssh\sshd_config'
(Get-Content $cfg) -notmatch '^SyslogFacility|^LogLevel' |
  Set-Content $cfg -Encoding ascii

# 3. Fetch the missing repair scripts from Microsoft's upstream
cd 'C:\Windows\System32\OpenSSH'
$repo = 'https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh'
Invoke-WebRequest -Uri "$repo/install-sshd.ps1"          -OutFile install-sshd.ps1
Invoke-WebRequest -Uri "$repo/FixHostFilePermissions.ps1" -OutFile FixHostFilePermissions.ps1
Invoke-WebRequest -Uri "$repo/OpenSSHUtils.psm1"          -OutFile OpenSSHUtils.psm1
Invoke-WebRequest -Uri "$repo/OpenSSHUtils.psd1"          -OutFile OpenSSHUtils.psd1

# 4. Run the installer (creates sshd virtual user + LSA privileges)
.\install-sshd.ps1

# 5. Apply correct NTFS ACLs on C:\ProgramData\ssh\
.\FixHostFilePermissions.ps1 -Confirm:$false

# 6. Restart the service
Restart-Service sshd
```

Then verify on-host:

```powershell
Get-LocalUser sshd | Format-List Name, Enabled, PrincipalSource
Get-CimInstance Win32_Service -Filter "Name='sshd'" |
  Format-List Name, StartName, State, ProcessId
Get-Service sshd | Format-List Name, Status, StartType
Get-NetTCPConnection -State Listen -LocalPort 22 |
  Format-Table LocalAddress, LocalPort, OwningProcess
```

Expected:
- `sshd` local user exists (this is the key new state)
- `StartName: LocalSystem` (the sshd service still runs as
  SYSTEM; the `sshd` local user is the privsep target the
  child drops to)
- `Status: Running`, `StartType: Automatic`
- Two listeners on `0.0.0.0:22` and `[::]:22`

## Step 2: MacBook real-auth probe

From the operator MacBook:

```bash
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

Expected:

```text
DESKTOP-2JJ3187
desktop-2jj3187\jeffr
```

**If this returns the expected output, Phase 3 is done.**
Report the success to system-config (the MacBook side); it
will:

1. Write `desktop-2jj3187-ssh-lane-install-v0.5.0-apply-addendum-2026-05-16.md`
   confirming the lane is live.
2. Capture the commit SHA on `PowerShell/openssh-portable`
   branch `latestw_all` and the sha256 of each of the four
   downloaded scripts (for the v0.5.1 supply-chain pin).
3. Flip the device to `lifecycle_phase: 3` /
   `classification: reference-ssh-host` in
   `current-status.yaml`.
4. Draft v0.5.1 install packet codifying the fix permanently
   (with pinned commit SHA + sha256 verification + real-
   loopback test).
5. Drop the `desktop-2jj3187-service-mode-sshd-kex-reset`
   blocked_item.
6. Queue ssh-hardening + known-hosts-reconciliation as the
   next approval-eligible packets.

**If the probe still returns `Connection reset` at KEX**, the
install scripts did not fully repair the privsep setup.
Proceed to Step 3 (the v0.2.0 diagnostic).

## Step 3 (deep fallback): v0.2.0 diagnostic

If `install-sshd.ps1` + `FixHostFilePermissions.ps1` did not
fix the service-mode reset, run the v0.2.0 diagnostic packet
in this bundle. It's **scoped-live-change** (D9 stops/starts
the sshd service briefly during a foreground -ddd capture)
but produces structured JSON evidence the apply record can
cite directly.

The v0.2.0 packet captures everything the operator did
manually (foreground sshd -ddd + loopback probe) **plus**
binary inventory + Authenticode signature, Defender state +
threats + ASR rules, WER (Windows Error Reporting) crash
dumps for `sshd` / `sshd-session`, Application log entries,
and the `C:\ProgramData\ssh\logs\` directory ACL.

Read `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0-2026-05-16.md`
in this bundle, verify the script sha256
`cbe8294f0da5f0ff9d63f677069a8c51ac06ba599892996f7621ab5f56788eb1`,
and run. Return the priority files listed in the packet doc.

---

## Transfer

```text
/Users/verlyn13/Organizations/jefahnierocks/system-config/docs/device-admin/dsj-service-mode-restart-handoff/
```

Suggested target on the Windows host:

```text
C:\Users\jeffr\Documents\device-admin\dsj-service-mode-restart-handoff\
```

## What this bundle contains

| File | Role |
|---|---|
| `README.md` | **This file.** RCA-anchored decision tree: Step 1 (fix block), Step 2 (real-auth probe), Step 3 (v0.2.0 diagnostic if Step 1 fails). |
| `desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md` | **Full root-cause analysis.** Read this if Step 1 doesn't work or to understand what the fix block actually does. |
| `desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md` | v0.1.0 diagnostic apply record + foreground-success follow-up finding (the data that narrows the blocker to service-mode-only). |
| `desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md` | v0.5.0 install apply record (for context). |
| `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0-2026-05-16.md` | **Step 3 fallback packet doc.** Only run if Step 1 fails. |
| `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1` | **Step 3 fallback executable.** sha256 `cbe8294f0da5f0ff9d63f677069a8c51ac06ba599892996f7621ab5f56788eb1`. |
| `desktop-2jj3187-windows-side-directive-2026-05-15.md` | Standing agent directive (v0.4.0). |
| `windows-terminal-admin-spec.md` | The spec (includes the new §Windows OpenSSH Capability Install Gaps section). |
| `handback-format.md` | Return format reference. |

## What "Phase 3 done" means

When `ssh desktop-2jj3187 'hostname'` from the operator
MacBook returns `DESKTOP-2JJ3187` cleanly with no manual
intervention (no foreground sshd hack), the device
transitions to:

- `lifecycle_phase: 3`
- `classification: reference-ssh-host`

The SSH lane is then persistent across reboots, the admin key
in `administrators_authorized_keys` matches the 1Password
item, the hardening drop-in is in effect via the Include
directive, and the MacBook `~/.ssh/known_hosts` has the host
ED25519 key.

## Preservation requirements

Throughout Step 1 / Step 2 / Step 3, do not modify:
- v0.5.0 on-host evidence directory
  (`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-20260516T020851Z\`)
- v0.4.0 on-host evidence directory
- v0.1.0 diagnostic on-host evidence directory
  (`...\desktop-2jj3187-ssh-kex-diagnostic-20260516T024628Z\`)
- v0.4.0 and v0.3.0 packet markdowns (SUPERSEDED, preserved
  on repo side)

Step 1's fix block re-creates the `sshd` local user but does
**not** modify config files, host keys, or the drop-in. The
`Remove-LocalUser -Name 'sshd'` in the fix block only removes
any half-configured `sshd` user from prior manual debugging;
it doesn't affect `jeffr` or any other account.

## Bundle source

Assembled from `docs/device-admin/` and `scripts/device-admin/`
in the `jefahnierocks/system-config` repo, MacBook side. Repo
HEAD when bundle was assembled is recorded in the commit
adding this folder.
