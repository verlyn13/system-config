---
title: DESKTOP-2JJ3187 SSH KEX Reset Diagnostic Packet - 2026-05-16
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, diagnostic, read-only-probe, kex-reset, phase-3-blocker]
priority: high
---

# DESKTOP-2JJ3187 SSH KEX Reset Diagnostic Packet - 2026-05-16

Read-only diagnostic to identify why incoming SSH connections to
DESKTOP-2JJ3187 reset at `SSH_MSG_KEXINIT`. The v0.5.0 ssh-lane-
install applied cleanly (all 23 acceptance-gate fields true; see
[desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md))
but the MacBook real-auth probe failed with
`Connection reset by 192.168.0.217 port 22` immediately after the
client sent its KEX init. This packet pulls the server-side
evidence needed to identify root cause.

## Symptom (from the MacBook side)

```
debug1: Connecting to 192.168.0.217 [192.168.0.217] port 22.
debug1: Connection established.
debug1: Local version string SSH-2.0-OpenSSH_10.2
debug1: Remote protocol version 2.0, remote software version OpenSSH_for_Windows_9.5
debug1: compat_banner: match: OpenSSH_for_Windows_9.5 pat OpenSSH* compat 0x04000000
debug1: Authenticating to 192.168.0.217:22 as 'jeffr'
debug3: send packet: type 20
debug1: SSH2_MSG_KEXINIT sent
Connection reset by 192.168.0.217 port 22
```

Reproducible across configurations (with/without HostKeyAlias,
with/without IdentityAgent, restricted KEX/HostKey algorithm
lists, `-F /dev/null`). `ssh-keyscan` returns banner-only — same
KEX-stage failure. Client itself is healthy
(`ssh -T git@github.com` succeeds).

## Hypotheses to test (in order)

1. **OpenSSH/Operational event log carries a sshd error message.**
   `Bad permissions on host key`, `kex_choose_conf: no match`,
   `fatal: ...`, or any structured rejection. Most likely
   source of root cause.
2. **`sshd.log` file at `C:\ProgramData\ssh\logs\sshd.log` has
   stderr-style entries** (only present if
   `SyslogFacility LOCAL0` plus file logging were configured;
   not the default).
3. **Service-control / WER events in the System log** show sshd
   per-connection child processes crashing.
4. **Host-key ACLs are too open**, tripping `StrictModes` at
   per-connection time (`StrictModes yes` is the Microsoft
   default and is confirmed effective via the v0.5.0 install
   readback).
5. **`sshd -T` directives drift between MacBook-source-IP
   parameters and loopback parameters**, indicating a Match
   block somewhere is applying differently from the install-
   time simulation.
6. **The host's own loopback `ssh.exe 127.0.0.1` produces the
   same KEX reset.** If so: the issue is purely sshd-process-
   internal and not network middleware. If loopback succeeds
   past KEX (e.g., reaches auth and fails for lack of a key):
   the issue is on the LAN path (Windows Firewall connection
   security, Defender, third-party EDR).

## Executable Artifact

```text
script:      scripts/device-admin/desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1
sha256:      9a7a54a3a9da4c180720f06795194469159439fecff3e227c3f241396b894e1e
encoding:    ASCII (verified python: 20151 bytes, 0 bytes > 0x7F; 457 lines, LF)
shell:       C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
invocation:  powershell.exe -NoProfile -ExecutionPolicy Bypass -File <full-path>\desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1
```

The script collects evidence with `$ErrorActionPreference =
'Continue'` so individual failures don't abort the whole
collection. Writes structured JSON evidence under
`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-<UTC-timestamp>\`.

## Session Class

`read-only-probe`. No host state is mutated. The script:

- Reads service state (`Get-Service`, `Get-CimInstance Win32_Service`)
- Reads listener state (`Get-NetTCPConnection`)
- Runs `sshd.exe -t` (config syntax check; no mutation)
- Runs `sshd.exe -T -C user=jeffr,addr=192.168.0.10` and
  `-C user=jeffr,addr=127.0.0.1` (config readback; no mutation)
- Reads OpenSSH/Operational event log (`Get-WinEvent`)
- Reads recent System log entries tagged with sshd
- Tails `C:\ProgramData\ssh\logs\sshd.log` if present (read-only)
- Reads file ACLs via `Get-Acl` on sshd_config, drop-in,
  administrators_authorized_keys, ssh_host_*_key{,.pub}
- Runs `ssh.exe 127.0.0.1 -p 22` loopback connection probe with
  `-o BatchMode=yes -o ConnectTimeout=5` (no host mutation; the
  loopback connection's exit and verbose output reveal whether
  the KEX reset reproduces locally)

Not touched: registry, sshd_config, drop-in, host keys,
authorized_keys, firewall rules, network profile, RDP, BitLocker,
Defender, accounts, scheduled tasks, Cloudflare/WARP, 1Password.

## Approval Phrase

> Run `desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1` on
> DESKTOP-2JJ3187 from an elevated Windows PowerShell 5.1 session
> as `DESKTOP-2JJ3187\jeffr`. Read-only; writes JSON + text
> evidence at
> `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-<timestamp>\`.
> Pulls OpenSSH/Operational event log entries, sshd.log if
> present, service + listener state, sshd -T directive readbacks
> for both MacBook source IP (192.168.0.10) and loopback
> (127.0.0.1), ACLs on sshd_config / drop-in /
> administrators_authorized_keys / host keys, and a loopback
> ssh.exe probe to see if the KEX reset reproduces locally. No
> mutation. Return the `08-summary.json`,
> `04-openssh-events.json`, `03-sshd-T-directives.json`,
> `07-loopback-ssh.txt`, and `06-acls.json` files verbatim. If
> the OpenSSH/Operational log is not enabled or has no records,
> also include `05-sshd-log-tail.txt` if present and
> `01-service-system-events.json`.

## Preflight (operator)

1. RDP into DESKTOP-2JJ3187 as `DESKTOP-2JJ3187\jeffr`.
2. Open elevated **Windows PowerShell 5.1** (not pwsh 7). Confirm
   `$PSVersionTable.PSVersion.Major -eq 5`.
3. Confirm script sha256:

   ```powershell
   $expected = '9a7a54a3a9da4c180720f06795194469159439fecff3e227c3f241396b894e1e'
   $path     = '<full-path-to>\desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1'
   $actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
   if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
   ```

4. Confirm the v0.5.0 install evidence directory and the v0.4.0
   evidence directory are intact (this packet writes a new
   timestamped directory alongside them; do not rotate or delete
   the existing ones).

## Execute

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  '<full-path-to>\desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1'
```

The script self-prints step-by-step progress. Each step is
fail-soft (continues on individual error so the diagnostic
gathers everything possible).

## Evidence Layout

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-<UTC-yyyymmddThhmmssZ>\
  00-preflight.json
  00-run.log                        (timestamped step log)
  01-service.json                   (Get-Service + Win32_Service)
  01-service-system-events.json     (System log sshd-tagged events, last 24h)
  02-listeners.json                 (Get-NetTCPConnection :22)
  02-listener-procs.json            (process detail for each listener pid)
  03-sshd-t.json                    (sshd -t exit + output)
  03-sshd-T-macbook.txt             (sshd -T -C user=jeffr,addr=192.168.0.10 full output)
  03-sshd-T-loopback.txt            (sshd -T -C user=jeffr,addr=127.0.0.1 full output)
  03-sshd-T-directives.json         (extracted key directives from both readbacks)
  04-event-log-config.json          (OpenSSH/Operational log config + record count)
  04-openssh-events.json            (last 50 OpenSSH/Operational events)
  05-sshd-log-meta.json             (sshd.log file existence + size)
  05-sshd-log-tail.txt              (last 100 lines of sshd.log if present)
  06-acls.json                      (file ACLs on relevant paths)
  07-loopback-ssh.txt               (verbose ssh.exe 127.0.0.1 probe output)
  07-loopback-meta.json             (loopback probe exit + parsed indicators)
  08-summary.json                   (one-page summary + hand-back checklist)
```

## Hand-Back: `08-summary.json` Schema

The agent returns `08-summary.json` verbatim. Plus, depending on
findings, also the supporting files named in the Approval Phrase
above. The summary fields:

| Field | Type | Why |
|---|---|---|
| `script` | string | self-identification |
| `computer` | string | identity proof |
| `user` | string | identity proof |
| `shell` | string | shell choice |
| `sshd_service_status` | string | expected `Running` |
| `sshd_service_starttype` | string | expected `Automatic` |
| `sshd_pid` | int | sshd's PID; cross-checks listener owner |
| `listener_count` | int | expected `2` (IPv4 + IPv6) |
| `sshd_t_passed` | bool | expected `true` (config syntax) |
| `openssh_oplog_found` | bool | does OpenSSH/Operational log exist on the host? |
| `openssh_oplog_enabled` | bool | is it enabled (collecting events)? |
| `openssh_oplog_records` | int | how many records does it have? |
| `sshd_log_file_exists` | bool | is `C:\ProgramData\ssh\logs\sshd.log` present? |
| `sshd_log_file_size` | int | size of that file |
| `loopback_ssh_exit` | int | exit code of `ssh 127.0.0.1` probe |
| `loopback_connection_reset` | bool | did the loopback probe see "Connection reset"? **Critical signal.** If `true`, the issue is sshd-process-internal. If `false`, the issue is network-path-specific. |
| `loopback_reached_kex` | bool | did the loopback probe at least send KEXINIT? |
| `files_written` | string[] | filenames in the evidence directory |

The `loopback_*` fields are the most directly actionable. If
`loopback_connection_reset = true` AND
`loopback_reached_kex = true`: sshd itself is rejecting the
KEXINIT — root cause is in the sshd process (algorithm,
host key, drop-in, runtime config). If
`loopback_connection_reset = false` AND the probe gets further
(e.g., reaches authentication and fails for lack of an
identity): the LAN-to-sshd path has middleware interfering.

## Files to return (in priority order)

1. `08-summary.json` (always; ~1-2 KB)
2. `04-openssh-events.json` (if `openssh_oplog_records > 0`;
   typically the smoking-gun)
3. `03-sshd-T-directives.json` (extracted directives from both
   readbacks; tells us if the runtime config drifted from the
   install-time config)
4. `07-loopback-ssh.txt` (verbose ssh client output from the
   loopback probe; shows exactly what stage was reached)
5. `06-acls.json` (file ACLs on sshd config + key files)
6. `01-service-system-events.json` (if sshd has been crashing /
   restarting)
7. `05-sshd-log-tail.txt` (if `sshd_log_file_exists = true`)

Optional: the full `03-sshd-T-macbook.txt` and
`03-sshd-T-loopback.txt` for deeper inspection.

## Hard Stops

Read-only probes have softer halt rules than scoped-live-change
packets, per spec §Packet-Defect Halt Rule ("read-only-probe
packets may continue past a single command failure if the failed
command is non-mutating and the rest of the evidence is still
useful"). Stop and hand back rather than improvising only if:

- Identity proof returns a different hostname or admin username.
- `$PSVersionTable.PSVersion.Major` is not `5`.
- Script sha256 does not match.
- The script's behavior diverges from this Markdown description
  in any way (e.g., starts attempting writes outside the
  evidence directory).

Individual step failures (e.g., OpenSSH/Operational log is
disabled, `sshd.log` file absent, loopback probe times out) are
expected as findings, not halts. The script captures the
absence/failure as evidence.

## Boundaries

This diagnostic does **not** authorize:

- Any service start/stop/reconfigure.
- Any firewall rule mutation.
- Any sshd_config or drop-in edit.
- Any DISM / capability mutation.
- Any rotation, deletion, or modification of the v0.4.0 or
  v0.5.0 evidence directories or scripts (preserve verbatim).
- Any change to BitLocker, Defender, network profile, DNS,
  DHCP, OPNsense, Cloudflare, WARP, or 1Password.
- Any enabling of OpenSSH/Operational logging if it is currently
  disabled. (If it's disabled, that is itself a finding — report
  it as such; system-config will issue a separate small packet
  to enable the channel if needed.)

If the script's own logic appears to do anything beyond the
read-only operations described in this packet, halt — the script
may have been modified from its declared sha256.

## After Apply

System-config writes
`docs/device-admin/desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md`
with the returned summary + event log entries + (depending on
finding) directive drift + ACL state + loopback result. From
that evidence, the next packet shape is chosen:

- **OpenSSH event log shows algorithm rejection** → v0.5.1
  install-packet adjusts the drop-in (or main `sshd_config`)
  to align algorithms. Spec gains a §SSH Algorithm Posture
  section.
- **OpenSSH event log shows StrictModes rejection on a host
  key** → small packet re-applies sshd's expected ACLs on
  `C:\ProgramData\ssh\ssh_host_*` and re-tests. Spec gains a
  §Windows OpenSSH ACL Constraints section.
- **Loopback probe reproduces the reset** → root cause is
  sshd-process-internal; drill into the specific cause from
  the event log.
- **Loopback probe succeeds past KEX** → root cause is
  network-path; investigate Windows Firewall connection
  security rules, Defender / EDR, third-party security
  software. Spec gains a §LAN-Path Interference section.
- **Event log empty / disabled** → tiny scoped-live-change
  packet to enable the OpenSSH/Operational channel via
  `wevtutil set-log "OpenSSH/Operational" /enabled:true`, then
  re-run this diagnostic.

In all cases, the next install-packet version will also include
a real-loopback test (Test-NetConnection 127.0.0.1 -Port 22
plus `ssh 127.0.0.1 hostname`) inside S7 so the "v0.5.0
verification gap" recorded in the apply record cannot recur.

## Cross-References

- [desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md) (the install apply record; explains the v0.5.0 verification gap)
- [desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md) (the install packet)
- [desktop-2jj3187-windows-side-directive-2026-05-15.md](./desktop-2jj3187-windows-side-directive-2026-05-15.md) (the agent directive)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) — §Read-only-probe halt rule, §Packet Artifact Separation, §Structured Evidence
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
