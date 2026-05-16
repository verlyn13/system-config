---
title: DESKTOP-2JJ3187 SSH Service-Mode Restart - Handoff Bundle
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, service-mode, handoff, bundle, decision-tree]
priority: high
---

# DESKTOP-2JJ3187 SSH Service-Mode Restart - Handoff Bundle

The big news: **SSH works**. End-to-end, MacBook -> DSJ, real
publickey auth via 1Password, command exec, clean disconnect.

The remaining issue is narrower than we feared — it's
**service-mode-only**. When sshd is launched by the Windows
Service Control Manager (default account `NT AUTHORITY\SYSTEM`),
the KEX-stage reset happens. When sshd is launched manually by
jeffr's interactive admin shell, KEX completes and everything
works.

This bundle is the decision tree for fixing the service-mode
issue. Run the steps in order; **stop as soon as one works**.

---

## Step 0: state on the host right now

After the operator's manual foreground sshd test, the sshd
service is **stopped** and the foreground sshd process has been
Ctrl-C'd. Port 22 has no listener. MacBook ssh probe currently
times out (verified from MacBook 2026-05-16T~04:00Z).

## Step 1 (try first): plain service restart

From elevated Windows PowerShell 5.1 on DESKTOP-2JJ3187:

```powershell
Start-Service sshd
Start-Sleep -Seconds 3
Get-Service sshd | Format-List Name, Status, StartType
Get-NetTCPConnection -State Listen -LocalPort 22 |
  Format-Table LocalAddress, LocalPort, OwningProcess
```

Expected: `Status: Running`, `StartType: Automatic`, two
listeners on 0.0.0.0:22 and [::]:22.

Then from the operator MacBook:

```bash
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

Expected:

```text
DESKTOP-2JJ3187
desktop-2jj3187\jeffr
```

**If this returns the expected output, Phase 3 is done.** Report
back to system-config which will commit a v0.5.0-install-apply
addendum confirming the lane and flip the device to
`lifecycle_phase: 3` / `classification: reference-ssh-host`.

The previous service-mode failure may have been a transient
state issue (cleaned up by Stop + Start). If so, no further
packet is needed.

## Step 2 (if Step 1 still resets at KEX): Microsoft service reset

If `ssh desktop-2jj3187 'hostname'` still returns
`Connection reset by 192.168.0.217 port 22`, run Microsoft's
official sshd service reinstall:

```powershell
Stop-Service sshd
cd 'C:\Windows\System32\OpenSSH'
.\install-sshd.ps1
Start-Service sshd
Start-Sleep -Seconds 3
Get-Service sshd | Format-List Name, Status, StartType
Get-CimInstance Win32_Service -Filter "Name='sshd'" |
  Format-List Name, StartName, State, ProcessId, PathName
```

`install-sshd.ps1` re-creates the sshd service with the
Microsoft default account (`NT AUTHORITY\SYSTEM` -- the
`StartName` field in the second command confirms this) and
known-good permissions. If the service had drifted to a
non-default account or had wrong privileges, this fixes it.

Then re-probe from the MacBook:

```bash
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

**If this returns the expected output, Phase 3 is done.**

## Step 3 (if both Step 1 and Step 2 still reset): v0.2.0 deep diagnostic

If the simple fixes don't work, the v0.2.0 diagnostic packet in
this bundle is the next step. It's **scoped-live-change** (D9
stops/starts sshd service briefly during a foreground -ddd
capture) but produces structured JSON evidence the apply record
can cite directly.

The v0.2.0 packet captures everything the operator did manually
(foreground sshd -ddd + loopback probe) **plus** binary
inventory, Defender state + threats + ASR rules + scan history,
WER (Windows Error Reporting) crash dumps for sshd or
sshd-session, Application log entries for the sshd-session.exe
path, and the `C:\ProgramData\ssh\logs\` directory ACL (a known
Win32-OpenSSH #2282 cause).

Read `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0-2026-05-16.md`
in this bundle, verify the script sha256
`cbe8294f0da5f0ff9d63f677069a8c51ac06ba599892996f7621ab5f56788eb1`,
and run. Return the priority files listed in the packet doc.

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
| `README.md` | **This file.** Decision tree: Step 1, Step 2, Step 3. |
| `desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md` | v0.1.0 diagnostic apply record + the foreground-success follow-up finding (the data that narrows the blocker to service-mode-only). |
| `desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md` | v0.5.0 install apply record (for context). |
| `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0-2026-05-16.md` | **Fallback Step 3 packet doc.** Only run if Step 1 and Step 2 both fail. |
| `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1` | **Fallback Step 3 executable.** sha256 `cbe8294f0da5f0ff9d63f677069a8c51ac06ba599892996f7621ab5f56788eb1`. |
| `desktop-2jj3187-windows-side-directive-2026-05-15.md` | Standing agent directive (v0.4.0). |
| `windows-terminal-admin-spec.md` | The spec. |
| `handback-format.md` | Return format reference. |

## What "Phase 3 done" means

When `ssh desktop-2jj3187 'hostname'` from the operator MacBook
returns `DESKTOP-2JJ3187` cleanly with no manual intervention
(no foreground sshd hack), the device transitions to:

- `lifecycle_phase: 3`
- `classification: reference-ssh-host`

The SSH lane is then persistent across reboots (sshd service
is `Automatic`), the admin key in
`administrators_authorized_keys` matches the 1Password item
`op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13`,
the hardening drop-in is in effect via the Include directive,
and the MacBook `~/.ssh/known_hosts` has the host ED25519 key.

The follow-on packets (ssh-hardening, known-hosts-reconciliation)
become approval-eligible at that point.

## Preservation requirements

Throughout all three steps, do not modify:
- v0.5.0 on-host evidence directory
  (`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-20260516T020851Z\`)
- v0.4.0 on-host evidence directory
- v0.1.0 diagnostic on-host evidence directory
  (`...\desktop-2jj3187-ssh-kex-diagnostic-20260516T024628Z\`)
- v0.4.0 packet markdown (SUPERSEDED, preserved on repo side)
- v0.3.0 packet markdown (SUPERSEDED, preserved on repo side)

Step 2's `install-sshd.ps1` re-creates the sshd service but does
**not** touch any of the above. It's a service-object reset,
not a config or key reset.

Step 3's v0.2.0 diagnostic writes a new timestamped evidence
directory under
`C:\Users\Public\Documents\jefahnierocks-device-admin\` alongside
the preserved older directories.

## Bundle source

Assembled from `docs/device-admin/` and `scripts/device-admin/`
in the `jefahnierocks/system-config` repo, MacBook side. Commit
recorded in the same commit that adds this folder.
