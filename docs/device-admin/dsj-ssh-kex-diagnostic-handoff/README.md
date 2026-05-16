---
title: DESKTOP-2JJ3187 SSH KEX Reset Diagnostic - Handoff Bundle
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, diagnostic, read-only-probe, handoff, bundle]
priority: high
---

# DESKTOP-2JJ3187 SSH KEX Reset Diagnostic - Handoff Bundle

This folder is a **transient snapshot** of the diagnostic packet
and references that the Windows-side agent or operator on
DESKTOP-2JJ3187 needs to surface the root cause of the
post-v0.5.0 SSH connection reset.

Canonical copies live at their normal repo paths. This bundle is a
flat folder so the entire set can be copied or zipped and dropped
into the RDP session in one step. Relative `[link](./other.md)`
references inside these documents resolve to the sibling files in
this same folder.

## Context (what just happened)

- **v0.5.0 ssh-lane-install applied cleanly on 2026-05-16T02:09:17Z.**
  All 23 acceptance-gate fields true. `Include sshd_config.d/*.conf`
  is now at the top of `sshd_config` (the v0.4.0 -> v0.5.0 fix).
  `sshd` is Running+Automatic on pid 18188, listening on
  `0.0.0.0:22` and `[::]:22`, drop-in directives in effective
  config, admin key fingerprint
  `SHA256:0oDYmXRFr...+/s` confirmed in
  `administrators_authorized_keys`,
  `Jefahnierocks SSH LAN TCP 22` rule scoped to `192.168.0.0/24`.
- **The MacBook real-auth probe failed.**
  `ssh desktop-2jj3187 'cmd /c "hostname && whoami"'` returned
  `Connection reset by 192.168.0.217 port 22` at
  `SSH_MSG_KEXINIT`. TCP + banner exchange both complete. Server
  resets without sending its own KEXINIT or any
  SSH_MSG_DISCONNECT message.
- **The install itself is not at fault.** v0.5.0's S7 verification
  (`sshd -T -C user=jeffr,addr=127.0.0.1`) proves the config
  parses correctly with those parameters in mind. It does not
  open a real TCP listener for an incoming test connection.
  Necessary, but not sufficient for end-to-end connectivity. This
  gap will be closed in future install-packet versions.
- **Server-side root cause is unknown from this side.** Needs
  OpenSSH event log access, which is what this diagnostic pulls.

## Transfer

From the MacBook:

```text
/Users/verlyn13/Organizations/jefahnierocks/system-config/docs/device-admin/dsj-ssh-kex-diagnostic-handoff/
```

Suggested target on the Windows host (writable by `jeffr`,
outside the evidence dir):

```text
C:\Users\jeffr\Documents\device-admin\dsj-ssh-kex-diagnostic-handoff\
```

(Same parent dir as the v0.5.0 handoff bundle from earlier. The
diagnostic script in here is a different file, with a different
sha256.)

## Reading order

| # | File | Why |
|---|---|---|
| 1 | `desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md` | **Entry point.** The diagnostic packet. Lists hypotheses, the read-only commands, evidence layout, hand-back schema. Read first. |
| 2 | `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1` | The executable. sha256 `9a7a54a3a9da4c180720f06795194469159439fecff3e227c3f241396b894e1e`. Don't transcribe; run this exact file. |
| 3 | `desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md` | Context: the v0.5.0 install apply record + the downstream blocker analysis (the "v0.5.0 verification gap" finding). Explains why this diagnostic exists. |
| 4 | `desktop-2jj3187-windows-side-directive-2026-05-15.md` | The standing agent directive on this device. Halt rules and authority still apply. |
| 5 | `windows-terminal-admin-spec.md` | The fleet spec. Especially §Packet-Defect Halt Rule (note: read-only-probes have softer halt rules than scoped-live-change packets — individual command failures continue, not halt), §Structured Evidence, §Windows OpenSSH Defaults, §Encoding Contract. |
| 6 | `handback-format.md` | Hand-back format reference. |

## Verify integrity before running

```powershell
$expected = '9a7a54a3a9da4c180720f06795194469159439fecff3e227c3f241396b894e1e'
$path     = 'C:\Users\jeffr\Documents\device-admin\dsj-ssh-kex-diagnostic-handoff\desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1'
$actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
```

## Execute

Elevated Windows PowerShell 5.1 (not pwsh 7). Confirm
`$PSVersionTable.PSVersion.Major -eq 5` first.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  'C:\Users\jeffr\Documents\device-admin\dsj-ssh-kex-diagnostic-handoff\desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1'
```

The script is read-only. It collects evidence with
`$ErrorActionPreference = 'Continue'` so an individual step
failing (e.g., OpenSSH/Operational log disabled) does NOT halt
the run; the absence/failure is captured as evidence and the rest
proceeds.

Evidence lands at
`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-<UTC-timestamp>\`.
This is a new directory alongside the preserved v0.5.0 install
evidence dir (`desktop-2jj3187-ssh-install-20260516T020851Z`) and
the v0.4.0 partial-apply evidence dir. Do not modify those.

## Return path

Priority order for files to paste back to system-config:

1. **`08-summary.json`** — always (1-2 KB)
2. **`04-openssh-events.json`** — if `openssh_oplog_records > 0`;
   usually the smoking-gun
3. **`03-sshd-T-directives.json`** — extracted directives from
   both sshd -T readbacks; tells us if the runtime config drifted
   from install-time
4. **`07-loopback-ssh.txt`** — verbose ssh client output from the
   loopback probe; whether the KEX reset reproduces locally
5. **`06-acls.json`** — file ACLs on sshd_config + key files
6. `01-service-system-events.json` — only if sshd has been
   crashing/restarting (would appear here)
7. `05-sshd-log-tail.txt` — only if
   `sshd_log_file_exists: true` in the summary

The summary's `loopback_*` fields are the most directly
actionable signals:
- `loopback_connection_reset: true` AND
  `loopback_reached_kex: true` → root cause is sshd-process-
  internal (algorithm, host key, drop-in, runtime config).
- `loopback_connection_reset: false` AND probe reaches auth → LAN
  path interference (Defender, EDR, Windows Firewall Connection
  Security).

## Preservation requirements (Hard Stops)

- **v0.5.0 on-host evidence dir** must remain untouched. Do not
  delete, rename, or rotate
  `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-20260516T020851Z\`.
- **v0.4.0 on-host evidence dir** must remain untouched.
- **The diagnostic `.ps1` file** must remain unmodified. Find
  yourself wanting to edit it on the host? Halt and hand back
  instead.
- **No mutation surfaces.** The diagnostic does not touch
  registry, services, sshd_config, drop-in, host keys,
  administrators_authorized_keys, firewall rules, network
  profile, RDP, BitLocker, Defender, accounts, or 1Password. If
  the script appears to attempt any of those, halt — the script
  may have been modified from its declared sha256.

## What happens next (after the hand-back)

System-config writes
`docs/device-admin/desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md`
with the returned evidence and an analysis of the root cause.
Depending on findings:

- **OpenSSH event log shows algorithm rejection** → v0.5.1
  install-packet adjusts the drop-in (or main `sshd_config`) to
  align algorithms. Spec gains a §SSH Algorithm Posture section.
- **OpenSSH event log shows StrictModes rejection on a host key**
  → small packet re-applies sshd's expected ACLs on
  `C:\ProgramData\ssh\ssh_host_*` and re-tests. Spec gains a
  §Windows OpenSSH ACL Constraints section.
- **Loopback probe reproduces the reset (sshd-internal cause)** →
  drill into specific cause from the event log.
- **Loopback probe succeeds past KEX (network-path cause)** →
  investigate Windows Firewall Connection Security, Defender,
  third-party EDR. Spec gains a §LAN-Path Interference section.
- **Event log empty / disabled** → tiny scoped-live-change packet
  to enable the OpenSSH/Operational channel
  (`wevtutil set-log "OpenSSH/Operational" /enabled:true`), then
  re-run this diagnostic.

In all cases the next install-packet version will include a
real-loopback test (`Test-NetConnection 127.0.0.1 -Port 22` plus
actual `ssh 127.0.0.1` from the host) inside S7 so the v0.5.0
verification gap cannot recur.

## Bundle source

Assembled from `docs/device-admin/` and `scripts/device-admin/`
in the `jefahnierocks/system-config` repo, MacBook side. The
repo HEAD when this bundle was assembled is recorded in the
commit that adds this folder.
