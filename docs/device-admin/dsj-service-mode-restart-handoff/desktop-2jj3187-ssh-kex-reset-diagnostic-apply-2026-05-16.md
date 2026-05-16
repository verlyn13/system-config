---
title: DESKTOP-2JJ3187 SSH KEX Reset Diagnostic v0.1.0 Apply - 2026-05-16
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, diagnostic, read-only-probe, evidence, sshd-session-crash]
priority: high
---

# DESKTOP-2JJ3187 SSH KEX Reset Diagnostic v0.1.0 Apply - 2026-05-16

Apply record for
[desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md)
(packet v0.1.0). Read-only probe completed; decisive finding
returned. Follow-up diagnostic v0.2.0 with foreground `sshd -ddd`
required to capture the actual sshd crash cause; this apply record
captures what v0.1.0 surfaced plus two v0.1.0 script bugs found.

## Apply Context

```text
device:           DESKTOP-2JJ3187
applied_at:       2026-05-16T02:46:34Z
applied_by:       DESKTOP-2JJ3187\jeffr (elevated Windows PowerShell 5.1, Desktop 5.1.26100.8457)
session_class:    read-only-probe
executable:       scripts/device-admin/desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1
executable_sha256: 9a7a54a3a9da4c180720f06795194469159439fecff3e227c3f241396b894e1e
                   (verified on host before execution)
evidence_dir:     C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-20260516T024628Z\
                  (host-local; preserved alongside v0.5.0 install and
                  v0.4.0 partial-apply evidence dirs)
```

## Decisive Finding

**The KEX-stage connection reset reproduces on loopback
(`ssh 127.0.0.1` from the host itself).** Same symptom as the
LAN-side MacBook probe: TCP handshake + banner exchange complete,
client sends `SSH2_MSG_KEXINIT`, server resets without sending its
own KEXINIT or any SSH_MSG_DISCONNECT.

This is the most actionable signal in the spec's hypothesis
ladder: **root cause is sshd-process-internal, not LAN-path
interference.** The agent's per-connection privsep child is dying
immediately on KEXINIT receipt, before any log emission.

## Follow-up Manual Test (2026-05-16, post-v0.1.0)

After the v0.1.0 diagnostic, the operator ran the diagnostic-
equivalent manually on DESKTOP-2JJ3187:

```powershell
Stop-Service sshd
C:\Windows\System32\OpenSSH\sshd.exe -d -d -d
```

From the MacBook:

```bash
ssh desktop-2jj3187 'hostname'
```

**Result: full end-to-end success.** The foreground sshd produced
a complete `-ddd` log showing:

- KEX completed (curve25519-sha256, ssh-ed25519 host key,
  aes128-gcm@openssh.com cipher, zlib compression).
- Authentication completed (`debug1: trying public key file
  __PROGRAMDATA__/ssh/administrators_authorized_keys` → matching
  key found at line 1, `debug3: mm_answer_keyverify: publickey
  ED25519 signature using ssh-ed25519 verified`, `Accepted
  publickey for jeffr from 192.168.0.10 port 49524 ssh2: ED25519
  SHA256:0oDYmXRFr...+/s`).
- Command execution: `hostname` returned `DESKTOP-2JJ3187`.
- Clean disconnect (`Received disconnect from 192.168.0.10 port
  49524:11: disconnected by user`).
- TOFU prompt was answered on the MacBook side; ED25519 host
  key `SHA256:OFNLsVw4RJlChJef1Db+eelKZnqJfPsVYLkNPVED6V8`
  persisted to `~/.ssh/known_hosts` on the MacBook.

This **proves the SSH infrastructure is end-to-end correct**:
drop-in (`PasswordAuthentication no`, `KbdInteractiveAuthentication
no`, `PermitRootLogin no`, `PubkeyAuthentication yes`, `LogLevel
INFO`, `AllowGroups administrators`) is in effect via the `Include
sshd_config.d/*.conf` directive injected by v0.5.0 S3b; the
`Match Group administrators` block routes admin users to
`administrators_authorized_keys`; the pinned admin key matches
the 1Password fingerprint; the Windows Firewall scoped rule
`Jefahnierocks SSH LAN TCP 22` accepts the connection.

The foreground log also revealed the Microsoft privsep
architecture in use on this host: sshd spawns its own binary
with `-y` (network child, pre-auth) and `-z` (user child,
post-auth), **not** `sshd-session.exe`. The earlier hypothesis
that `sshd-session.exe` was the crashing child was incorrect.
The real privsep child is `sshd.exe -y` / `sshd.exe -z`.

Most informative diagnostic line in the foreground log:

```
debug1: Not running as SYSTEM: skipping loading user profile
```

This appears when sshd is running under jeffr's interactive
admin token (the foreground test). It hints that the SYSTEM-
context code path — the one taken when sshd runs as a Windows
service under the SCM-default account — does extra work
(loading the user profile via LSA APIs) that the user-context
path skips. That extra work is the candidate failure point.

**Narrowed blocker**: the KEX-stage reset is exhibited only when
sshd runs under the Service Control Manager (default install
account, expected `NT AUTHORITY\SYSTEM`), not when sshd runs
under an interactive admin token. The SSH infrastructure itself
is correct.

## Hand-Back: `08-summary.json` (returned verbatim)

```json
{
    "script":  "desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1",
    "finished_at":  "2026-05-16T02:46:34.5345373Z",
    "computer":  "DESKTOP-2JJ3187",
    "user":  "jeffr",
    "shell":  "Desktop 5.1.26100.8457",
    "evidence_dir":  "C:\\Users\\Public\\Documents\\jefahnierocks-device-admin\\desktop-2jj3187-ssh-kex-diagnostic-20260516T024628Z",
    "sshd_service_status":  "Running",
    "sshd_service_starttype":  "Automatic",
    "sshd_pid":  18188,
    "listener_count":  2,
    "sshd_t_passed":  true,
    "sshd_t_exit":  0,
    "openssh_oplog_found":  true,
    "openssh_oplog_enabled":  true,
    "openssh_oplog_records":  8,
    "sshd_log_file_exists":  false,
    "sshd_log_file_size":  0,
    "loopback_ssh_exit":  1,
    "loopback_connection_reset":  false,
    "loopback_reached_kex":  false,
    "files_written":  [
        "00-preflight.json","01-service.json","01-service-system-events.json",
        "02-listeners.json","02-listener-procs.json",
        "03-sshd-t.json","03-sshd-T-macbook.txt","03-sshd-T-loopback.txt","03-sshd-T-directives.json",
        "04-event-log-config.json","04-openssh-events.json",
        "05-sshd-log-meta.json","05-sshd-log-tail.txt",
        "06-acls.json",
        "07-loopback-ssh.txt","07-loopback-meta.json",
        "08-summary.json","00-run.log"
    ]
}
```

**Note on `loopback_connection_reset: false` and
`loopback_reached_kex: false`:** these are **stale due to a
v0.1.0 script bug** (see §v0.1.0 Capture Bugs below). The actual
loopback `ssh.exe` stdout (captured by the operator from their
terminal) shows both `SSH2_MSG_KEXINIT sent` and `Connection
reset by 127.0.0.1 port 22`. The JSON values do not reflect
reality; the visible terminal output is the source of truth and
is the basis of the Decisive Finding above.

## Observations Beyond the Priority Files

### Observation 1 — `OpenSSH/Operational` has ZERO connection-attempt records

`04-openssh-events.json` returned 8 records, all of them
`Server listening on 0.0.0.0 port 22` / `:: port 22` at the four
sshd restart points (2026-05-15 16:03:06, 16:03:19, 16:11:19,
18:09:14 -08:00). **No record of the 02:46Z probe attempt or its
reset.** No connection-level, auth-level, or error events.

Combined with the `no DISCONNECT, just RST` client-side symptom:
**sshd-session.exe terminates before emitting any log entry.** The
listener (`sshd.exe`, pid 18188, started at the v0.5.0 S7 restart)
is healthy and stable across the period; only the per-connection
child crashes.

### Observation 2 — `sshd -T` parses identically for both source addresses

`03-sshd-T-directives.json` shows identical effective config for
`addr=192.168.0.10` and `addr=127.0.0.1`:

| Directive | Value |
|---|---|
| `allowgroups` | `administrators` |
| `pubkeyauthentication` | `yes` |
| `passwordauthentication` | `no` |
| `kbdinteractiveauthentication` | `no` |
| `strictmodes` | `yes` |
| `loglevel` | `INFO` |
| `authorizedkeysfile` | `__PROGRAMDATA__/ssh/administrators_authorized_keys` |
| `kexalgorithms` | `curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256` |
| `hostkeyalgorithms` | `ssh-ed25519-cert-v01@openssh.com,...,ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,...,rsa-sha2-512,rsa-sha2-256` |
| `ciphers` | `chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com` |
| `macs` | `umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-64@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512` |

`macbook_addr_exit: 0`, `loopback_addr_exit: 0`. **Configuration
is not the cause.** The drop-in is in effect via the Include
directive (v0.5.0's fix), all expected hardening directives are
present, KEX/cipher/MAC/host-key algorithm lists are standard
OpenSSH 9.5 defaults. There is no Algorithm Posture mismatch to
fix.

### Observation 3 — Host-key ACLs are clean

`06-acls.json`:

| File | Owner | Group | ACL summary |
|---|---|---|---|
| `ssh_host_ed25519_key` | SYSTEM | SYSTEM | SYSTEM + BUILTIN\Administrators FullControl only |
| `ssh_host_ed25519_key.pub` | SYSTEM | SYSTEM | SYSTEM + BUILTIN\Administrators FullControl only |
| `ssh_host_rsa_key` | SYSTEM | SYSTEM | same |
| `ssh_host_rsa_key.pub` | SYSTEM | SYSTEM | same |
| `ssh_host_ecdsa_key` | SYSTEM | SYSTEM | same |
| `ssh_host_ecdsa_key.pub` | SYSTEM | SYSTEM | same |
| `sshd_config` | Administrators | SYSTEM | SYSTEM + Administrators FullControl, Authenticated Users ReadAndExecute (Microsoft default) |
| `sshd_config.d\20-jefahnierocks-admin.conf` | Administrators | jeffr | SYSTEM + Administrators FullControl only (v0.5.0 S4 Set-AdminOnlyAcl) |
| `administrators_authorized_keys` | Administrators | jeffr | SYSTEM + Administrators FullControl only (v0.5.0 S5 Set-AdminOnlyAcl) |

**No `Authenticated Users` access on any host key or auth file.**
`StrictModes yes` (which is effective per `sshd -T`) cannot reject
these — they meet OpenSSH's tightening requirement.

### Observation 4 — Listener stable; child is the suspect

`02-listener-procs.json`: sshd pid 18188, started 2026-05-15
18:09:14 -08:00 (matches v0.5.0 S7 sshd restart at 02:09:14Z UTC).
The process has not crashed/restarted between the v0.5.0 install
and this diagnostic run. **The listener parent is healthy.** The
crash happens in the spawned per-connection child
(`sshd-session.exe` in Windows OpenSSH 9.5's split architecture).

## v0.1.0 Capture Bugs (for v0.1.1+)

Two script-level capture defects identified by the operating
agent; they do not affect the Decisive Finding (the agent
verified the loopback stdout manually), but they need fixing in
the next diagnostic version:

### Bug 1: `07-loopback-ssh.txt` is empty (5 bytes)

The v0.1.0 script captured the loopback ssh probe via:

```powershell
$loopbackCmd = '& C:\Windows\System32\OpenSSH\ssh.exe -v ...'
$loopbackOut = & cmd /c "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"$loopbackCmd`""
Set-Content -LiteralPath $loopbackOutPath -Value ($loopbackOut | Out-String) -Encoding utf8
```

The nested `cmd /c "powershell.exe -Command ..."` pattern does
not pass stderr through; the verbose `ssh -v` output (which goes
to stderr) was lost. The operator captured the actual stdout
from their terminal verbatim — that is the source the Decisive
Finding is based on:

```
ssh.exe : OpenSSH_for_Windows_9.5p2, LibreSSL 3.8.2
debug1: Connecting to 127.0.0.1 [127.0.0.1] port 22.
debug1: Connection established.
debug1: Local version string SSH-2.0-OpenSSH_for_Windows_9.5
debug1: Remote protocol version 2.0, remote software version OpenSSH_for_Windows_9.5
debug1: compat_banner: match: OpenSSH_for_Windows_9.5 pat OpenSSH* compat 0x04000000
debug1: Authenticating to 127.0.0.1:22 as 'jeffr'
debug1: load_hostkeys: fopen __PROGRAMDATA__\\ssh/ssh_known_hosts: No such file or directory
debug1: load_hostkeys: fopen __PROGRAMDATA__\\ssh/ssh_known_hosts2: No such file or directory
debug1: SSH2_MSG_KEXINIT sent
Connection reset by 127.0.0.1 port 22
```

**Same KEX-stage reset on loopback as on LAN.**

**Fix for v0.2.0**: invoke `ssh.exe` directly with shell-level
stderr redirection (`cmd /c "ssh.exe ... 2>file"` or
`Start-Process -RedirectStandardError`) so verbose output reaches
the evidence file regardless of NativeCommandError handling.

### Bug 2: declared files not always written

The summary's `files_written` array lists
`01-service-system-events.json` and `05-sshd-log-tail.txt`, but
the operator reports those files were not actually present on
disk. The script declared them as expected outputs in the array
without verifying they were written. Likely cause: when
`Get-WinEvent` returns no records (or throws under
`-ErrorAction SilentlyContinue`), downstream variable assignment
in the pipeline left the file-write step skipped silently.

**Fix for v0.2.0**: always initialize the result variable to `@()`
before the pipeline so `Write-Json` always runs and always writes
a file (even an empty `[]`). Verify file existence at the end of
each step and exclude unwritten files from the `files_written`
array. Mirror the spec's §Structured Evidence requirement: the
absence-of-data is data, recorded as an empty JSON, not as a
missing file.

## What This Apply Record Confirms

1. **The connection reset is sshd-process-internal**, not LAN
   middleware. (Decisive finding; rules out one of the six
   hypotheses from the diagnostic packet.)
2. **The configuration is not the cause.** `sshd -T` parses
   identically for both source addresses; all expected directives
   are present and effective.
3. **Host-key and auth-file ACLs meet `StrictModes`.** Not a
   permission rejection.
4. **The listener is stable.** Not a service-level crash; the
   per-connection child is the failing component.
5. **`OpenSSH/Operational` is enabled and has records**, but
   captures only listener-start events at this `LogLevel INFO`.
   No connection-level events at INFO. The next diagnostic must
   either crank `LogLevel` higher or capture sshd's own
   verbose output via `sshd -ddd`.

## What Remains to Confirm (after the foreground-success finding)

The follow-up manual test narrows the blocker substantially.
The simplest possible reset may resolve it (Windows service state
machines sometimes need a clean stop/start after manual sshd
foreground runs). Failing that, the standard Microsoft recovery
is `install-sshd.ps1`. Failing that, the v0.2.0 diagnostic packet
remains drafted as a deeper-investigation fallback.

Remaining steps in order of likelihood-to-fix:

1. **Plain restart of the sshd service.** After the operator's
   manual foreground test, the sshd service was left in the
   stopped state. A fresh `Start-Service sshd` followed by a
   MacBook probe will tell us whether the previous service-mode
   failure was a transient state issue or a persistent
   service-account bug. **Try this first.**

2. **Microsoft `install-sshd.ps1` reset.** If `Start-Service` +
   probe still resets at KEX, run:
   ```powershell
   Stop-Service sshd
   cd 'C:\Windows\System32\OpenSSH'
   .\install-sshd.ps1
   Start-Service sshd
   ```
   This re-creates the sshd service with the Microsoft-default
   account (`NT AUTHORITY\SYSTEM`) and permissions. If the
   service was somehow left with a non-default account or wrong
   privileges, this fixes it.

3. **v0.2.0 diagnostic packet.** If `install-sshd.ps1` does not
   fix it, the v0.2.0 packet (drafted alongside this apply
   record) captures binary inventory, Defender state, WER crash
   dumps, Application log entries, and the same foreground
   `sshd -ddd` test the operator just did manually — automated
   so the evidence is structured JSON the apply record can cite
   directly. Use this if the simple fixes do not resolve the
   service-mode issue.

The foreground-success finding rules out:
- Drop-in / Include / Match-block / hardening directives
- Host-key ACLs / StrictModes rejection
- 1Password / public-key fingerprint mismatch
- Windows Firewall LAN-scope rule
- LAN-path middleware (router, switch, IPS)

Those are all proven working end-to-end.

## Stop Rules Observed

None tripped. The session class was `read-only-probe`, and the
spec [§Packet-Defect Halt Rule](./windows-terminal-admin-spec.md)
allows continuing past individual command failures for read-only
probes. The two capture bugs are precisely the kind of failure
that the read-only-probe softer halt rule was written for: the
script kept going, gathered the rest of the evidence, and the
agent surfaced the missing data points alongside the manual
fallback (terminal stdout for loopback).

## After This Apply

`docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- Move `desktop-2jj3187-ssh-kex-reset-diagnostic` (v0.1.0) from
  `prepared_packets[]` to `applied_packets[]` with this apply
  record reference.
- `approval_required[]` entry for the v0.1.0 diagnostic ->
  `state: applied`.
- Add `prepared_packets[]` entry for v0.2.0 diagnostic
  (`desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1`,
  `session_class: scoped-live-change` due to the foreground sshd
  step).
- Add `approval_required[]` entry for the v0.2.0 diagnostic.
- Keep `lifecycle_phase: 2` and `classification: rdp-only-host`.
- Repoint `next_recommended_action.preferred_packet` to v0.2.0.
- `blocked_items[]` entry `desktop-2jj3187-real-auth-probe-failure`
  updated with the Decisive Finding narrowing the hypothesis
  space.

## Cross-References

- [desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md) (the v0.1.0 packet)
- [desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0-2026-05-16.md) (the v0.2.0 follow-up — to be created in this commit chain)
- [desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md) (the install apply record; v0.5.0 verification gap finding)
- [desktop-2jj3187-windows-side-directive-2026-05-15.md](./desktop-2jj3187-windows-side-directive-2026-05-15.md) (the agent directive)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) — §Read-only-probe halt rule, §Structured Evidence
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
