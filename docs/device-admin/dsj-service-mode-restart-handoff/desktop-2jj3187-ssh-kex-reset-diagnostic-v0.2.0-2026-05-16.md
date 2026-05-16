---
title: DESKTOP-2JJ3187 SSH KEX Reset Diagnostic Packet v0.2.0 - 2026-05-16
category: operations
component: device_admin
status: prepared
version: 0.2.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, diagnostic, scoped-live-change, foreground-sshd, kex-reset]
priority: high
---

# DESKTOP-2JJ3187 SSH KEX Reset Diagnostic Packet v0.2.0 - 2026-05-16

Follow-up diagnostic after v0.1.0
([apply record](./desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md))
confirmed sshd-process-internal cause for the KEX-stage connection
reset. v0.1.0 ruled out config issues, host-key ACL issues, and
LAN-path interference; loopback `ssh 127.0.0.1` reproduces the
same `SSH2_MSG_KEXINIT sent` -> `Connection reset by 127.0.0.1
port 22` symptom with zero entries in `OpenSSH/Operational`.

The pattern fits Windows OpenSSH 9.5's split architecture:
`sshd.exe` listener spawns a separate `sshd-session.exe` per
connection (Microsoft's PrivSep substitute for POSIX `fork()`).
The per-connection child appears to be dying immediately on
KEXINIT receipt, before any log emission. v0.2.0 captures the
actual failure by running `sshd.exe -ddd` (debug3) in the
foreground with its log redirected to a file, then probing it
locally. sshd's `-ddd` emits every step of KEX processing -- the
failure point will be visible in the log even if the per-
connection handler dies before reaching the event log writer.

## What Changed From v0.1.0

| Change | Why |
|---|---|
| **New D9 step**: foreground `sshd.exe -ddd -E <evidence>\09-foreground-sshd.log` + loopback `ssh -vvv -p 22 jeffr@127.0.0.1 hostname` | sshd's `-ddd` is the only mechanism that surfaces the per-connection child's KEX-stage failure without relying on the event log writer (which the silent crash bypasses). |
| **New D2b step**: OpenSSH binary inventory | Confirm `sshd-session.exe` exists, check its ACL, capture file version + Authenticode signature. Rules out missing/tampered/wrong-permission binary. |
| **New D4b step**: Application log entries for `sshd-session.exe` path | Catches crash events that landed in the Application channel rather than `OpenSSH/Operational`. |
| **New D5b step**: ACL on `C:\ProgramData\ssh\logs\` directory | Known cause per Win32-OpenSSH issue #2282 (logs folder ACLs can crash sshd-session on connection if not SYSTEM+Administrators only). |
| **New D6b step**: Defender state + recent threats + ASR rules | `Get-MpComputerStatus`, `Get-MpPreference`, `Get-MpThreatDetection`. Surfaces any AV intercept of `sshd-session.exe` spawn. |
| **New D6c step**: WER (Windows Error Reporting) crash dump search | Look in `C:\ProgramData\Microsoft\Windows\WER\` for any `sshd` / `sshd-session` dumps from the past 3 days. |
| **Fixed v0.1.0 capture bugs** | `07-loopback-ssh.txt` now uses `cmd /c "ssh.exe ... > out 2> err"` for reliable stderr capture; all `Write-Json` calls now have always-initialized empty-array fallbacks so files are always written. |

## Session Class

`scoped-live-change`. D9 stops the sshd service, runs
`sshd.exe -ddd` as a foreground process bound to port 22, runs a
loopback probe, then stops the foreground process and **restarts
the sshd service**. The service is restored before the script
exits. RDP is unaffected. Approximate downtime of port 22: 15-30
seconds during D9 execution.

The mutation is transient and self-reversing. If anything in D9
fails, the script attempts to restart the sshd service before
exit. If restart fails, the script prints a CRITICAL warning
naming the manual recovery command (`Start-Service sshd`).

All other steps (D0-D8, D10) are read-only.

## Executable Artifact

```text
script:      scripts/device-admin/desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1
sha256:      cbe8294f0da5f0ff9d63f677069a8c51ac06ba599892996f7621ab5f56788eb1
encoding:    ASCII (verified python: 35106 bytes, 0 bytes > 0x7F; 768 lines, LF)
shell:       C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
invocation:  powershell.exe -NoProfile -ExecutionPolicy Bypass -File <full-path>\desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1
```

## Architectural Framing (informational; for future spec
evolution)

Windows OpenSSH is not Linux OpenSSH. The Microsoft port is a
shim that translates POSIX-style daemon idioms into Windows OS
internals. Three relevant differences for this packet:

1. **No `fork()`.** Linux sshd uses `fork()` to clone itself per
   connection. Windows OpenSSH 9.5 introduced `sshd-session.exe`
   as the per-connection executable; `sshd.exe` spawns it via
   `CreateProcessAsUser`. Each spawn is a fresh process from
   scratch. If the spawn or first-read fails, the child dies
   silently because it has not yet attached to the Event Log
   writer.
2. **NTFS permissions instead of POSIX modes.** `StrictModes`
   checks Windows ACLs. The
   `C:\ProgramData\ssh\logs` directory ACL is enforced as part of
   the v9.4.0.0p1 install validation (Win32-OpenSSH #2282).
3. **PowerShell shell-default mismatches.** WinPS 5.1 defaults
   to Windows-1252 and has legacy `ConvertTo-Json` enum-to-int
   serialization bugs. Already addressed in spec §Encoding
   Contract and §Cross-Shell Data Normalization.

This packet does not codify these into spec sections yet -- the
v0.2.0 evidence will tell us which specific failure class
applies, then the spec gets the right new section
(§sshd-session.exe Crash Anatomy, §LSA Token Handling, or
§Windows OpenSSH Logs Folder ACL Constraints depending on what
the foreground log shows).

## Prerequisites

1. **v0.1.0 diagnostic apply record committed.** Evidence on
   host preserved at
   `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-20260516T024628Z\`.
2. **v0.5.0 install apply record committed.** Evidence on host
   preserved at
   `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-20260516T020851Z\`.
3. **No active SSH sessions or scheduled SSH jobs.** D9 stops
   the sshd service for 15-30 seconds. Any pending SSH-based
   automation will fail during that window. (RDP is unaffected.)
4. **Operator on local console or RDP** -- not on SSH (since SSH
   to this host doesn't work yet, this is the actual situation).

## Approval Phrase

> Run `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1` on
> DESKTOP-2JJ3187 from an elevated Windows PowerShell 5.1 session
> as `DESKTOP-2JJ3187\jeffr`. The script collects read-only
> evidence (D0-D8, D10) including OpenSSH binary inventory,
> Application log entries, Defender state and threats, WER crash
> dumps, sshd_config + drop-in + host-key ACLs, and the logs
> folder ACL. D9 (the scoped-live-change portion) stops the sshd
> service, runs `sshd.exe -ddd` as a foreground process with
> `-E <evidence>\09-foreground-sshd.log` redirection, runs a
> loopback `ssh -vvv -p 22 jeffr@127.0.0.1 hostname` probe to
> exercise the per-connection path, stops the foreground sshd,
> and restarts the sshd service. Approximate port-22 downtime
> during D9: 15-30 seconds. RDP unaffected. Return
> `10-summary.json`, `09-foreground-sshd.log`,
> `09-loopback-probe.txt`, `09-result.json`,
> `02b-openssh-binaries.json`, `04b-application-events.json`,
> `06b-defender-*.json`, `06c-wer-dumps.json`, and
> `05b-sshd-logs-dir-acl.json` verbatim.

## Preflight

1. RDP into DESKTOP-2JJ3187 as `DESKTOP-2JJ3187\jeffr`.
2. Open elevated **Windows PowerShell 5.1**, not pwsh 7. Confirm
   `$PSVersionTable.PSVersion.Major -eq 5`.
3. Confirm script sha256:
   ```powershell
   $expected = 'cbe8294f0da5f0ff9d63f677069a8c51ac06ba599892996f7621ab5f56788eb1'
   $path     = '<full-path-to>\desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1'
   $actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
   if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
   ```
4. Confirm no active SSH automation depends on the host during
   the next 60 seconds.
5. Confirm the v0.5.0 install evidence dir, v0.4.0 evidence dir,
   and v0.1.0 diagnostic evidence dir are intact.

## Execute

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  '<full-path-to>\desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1'
```

The script prints step-by-step progress. D0-D8 and D10 are
read-only. D9 is the only mutation step and is bounded with
explicit service stop/restart.

## Evidence Layout

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-v020-<UTC-yyyymmddThhmmssZ>\
  00-preflight.json
  00-run.log
  01-service.json
  01-service-system-events.json
  02-listeners.json
  02-listener-procs.json
  02b-openssh-binaries.json            (NEW: sshd-session.exe inventory + signature)
  03-sshd-t.json
  03-sshd-T-macbook.txt
  03-sshd-T-loopback.txt
  03-sshd-T-directives.json
  04-event-log-config.json
  04-openssh-events.json
  04b-application-events.json          (NEW: Application log entries for sshd-session.exe)
  05-sshd-log-meta.json
  05-sshd-log-tail.txt
  05b-sshd-logs-dir-acl.json           (NEW: logs folder ACL - Win32-OpenSSH #2282 known cause)
  06-acls.json
  06b-defender-state.json              (NEW: Get-MpComputerStatus)
  06b-defender-prefs.json              (NEW: Get-MpPreference + ASR rules)
  06b-defender-threats.json            (NEW: Get-MpThreatDetection)
  06c-wer-dumps.json                   (NEW: WER crash dump search for sshd / sshd-session)
  09-foreground-sshd.log               (NEW: THE smoking gun -- sshd -ddd output)
  09-loopback-probe.txt                (NEW: ssh -vvv stdout+stderr from loopback probe)
  09-probe-stderr.txt                  (NEW: ssh -vvv stderr separately)
  09-result.json                       (NEW: D9 state machine record)
  10-summary.json                      (hand-back)
```

## Hand-Back: `10-summary.json` Schema

The summary contains all the v0.1.0 fields plus:

| Field | Type | Meaning |
|---|---|---|
| `sshd_session_present` | bool | does `C:\Windows\System32\OpenSSH\sshd-session.exe` exist? **Critical**. |
| `foreground_sshd_started` | bool | did the foreground `sshd -ddd` start in D9? |
| `foreground_sshd_log_exists` | bool | did `09-foreground-sshd.log` get written? |
| `foreground_sshd_log_size` | int | bytes |
| `loopback_probe_attempted` | bool | did D9 reach the probe step? |
| `loopback_probe_exit` | int | exit code of `ssh -vvv ... 127.0.0.1` |
| `loopback_probe_kex_sent` | bool | did the probe send KEXINIT? |
| `loopback_probe_connection_reset` | bool | did the probe see "Connection reset"? |
| `service_restored` | bool | was sshd service restarted at end of D9? |
| `d9_error` | string\|null | any error captured during D9 |

The decisive file is **`09-foreground-sshd.log`**. That contains
sshd's own `-ddd` (debug3) output of every step of KEX
processing. The failure point (DLL not found, ACL rejection,
LSA token failure, etc.) will be visible there.

## Hard Stops

D0-D8 (read-only) follow read-only-probe halt semantics: continue
past individual failures, surface absences as evidence.

D9 (scoped-live-change) has these halt rules:
- Cannot stop the sshd service -> halt
- Port 22 still has a listener after Stop-Service -> halt
- Foreground sshd does not bind to port 22 within 10 seconds AND
  the foreground process has exited -> record the foreground log
  (which should contain the binding error) and proceed to attempt
  service restart
- Loopback probe times out -> record the timeout and proceed to
  cleanup
- Cannot restart the sshd service at the end -> print CRITICAL
  warning with manual recovery command

In all cases the script attempts service restart before exit.

Other script-level halt rules (still apply per spec
§Packet-Defect Halt Rule):
- Identity mismatch (hostname or user) -> halt at D0
- Wrong shell (`$PSVersionTable.PSVersion.Major != 5`) -> halt at D0
- Not in Administrators role -> halt at D0
- Script sha256 does not match -> halt before run (operator
  preflight check)
- Script behavior diverges from this Markdown description ->
  halt (script may have been modified)

## Boundaries

This diagnostic does **not** authorize:
- Any sshd_config or drop-in edit.
- Any DISM / capability mutation.
- Any firewall rule mutation beyond port 22 listener state.
- Any rotation, deletion, or modification of the v0.4.0, v0.5.0,
  or v0.1.0 evidence directories or scripts (preserve verbatim).
- Any change to BitLocker, Defender exclusions, network profile,
  DNS, DHCP, OPNsense, Cloudflare, WARP, or 1Password.
- Any persistent change to the sshd service (start type stays
  Automatic; account stays as configured; the only mutation is
  transient stop+start during D9).

## After Apply

System-config writes
`docs/device-admin/desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0-apply-2026-05-16.md`
with the returned summary + foreground sshd log + loopback probe
output + supporting files. From the foreground log, the root
cause is identified directly, and the next packet shape is
chosen:

- **`Bad ownership or modes for directory C:\ProgramData\ssh\logs`** ->
  small ACL-fix packet, retest. Spec gains a §Windows OpenSSH
  Logs Folder ACL Constraints section.
- **`CreateProcessAsUser failed`** / **token / LSA error** ->
  investigate service start_name (should be LocalSystem),
  possibly with explicit account override. Spec gains a §LSA
  Token Handling section.
- **DLL load failure / missing dependency** -> reinstall the
  OpenSSH capability (DISM remove + add). Spec gains a §OpenSSH
  Binary Integrity section.
- **No matching cipher / algorithm rejection** -> drop-in
  adjustment. Spec gains a §SSH Algorithm Posture section.
- **EDR / Defender intercept** -> add Defender exclusion for
  the OpenSSH binary paths via a separate scoped packet.
- **Application log shows `sshd-session.exe` crash with an
  exception code** -> the exception code directly names the
  fault class.

In all cases the next install-packet version will include the
loopback test (`Test-NetConnection 127.0.0.1 -Port 22` plus
`ssh -o BatchMode=yes 127.0.0.1 hostname`) as part of S7 so
the v0.5.0 verification gap recorded in the install apply
record cannot recur.

## Cross-References

- [desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md) (v0.1.0 apply record; sets up this packet)
- [desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md) (v0.1.0 packet)
- [desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md) (install apply record)
- [desktop-2jj3187-windows-side-directive-2026-05-15.md](./desktop-2jj3187-windows-side-directive-2026-05-15.md) (agent directive)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
- [handback-format.md](./handback-format.md)
- Upstream Win32-OpenSSH issue #2282 (logs folder ACL crash regression): https://github.com/PowerShell/Win32-OpenSSH/issues/2282
- Upstream Win32-OpenSSH issue #2403 (sshd-session.exe SID lookup failure): https://github.com/PowerShell/Win32-OpenSSH/issues/2403
