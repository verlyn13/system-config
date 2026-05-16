---
title: DESKTOP-2JJ3187 SSH Service-Mode KEX-Reset Root Cause Analysis - 2026-05-16
category: operations
component: device_admin
status: rca-recorded
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, service-mode, rca, privsep, root-cause]
priority: high
---

# DESKTOP-2JJ3187 SSH Service-Mode KEX-Reset RCA - 2026-05-16

Root-cause analysis for the service-mode SSH KEX reset that
v0.4.0, v0.5.0, and the v0.1.0 diagnostic surfaced over the
course of 2026-05-15 / 2026-05-16. Identifies the canonical cause
and names the fix path. Pairs with
[desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md)
(the v0.1.0 diagnostic apply record).

## Symptom (restated)

- v0.5.0 ssh-lane-install applied cleanly (all 23 acceptance-gate
  fields true; the install was correct on paper).
- MacBook real-auth probe failed:
  ```
  ssh desktop-2jj3187 'hostname'
  -> Connection reset by 192.168.0.217 port 22
  ```
- TCP handshake + SSH banner exchange both complete.
- Client sends `SSH2_MSG_KEXINIT`. Server resets the connection
  without sending its own KEXINIT or any `SSH_MSG_DISCONNECT`.
- `OpenSSH/Operational` event log records only listener-start
  events; zero entries for connection attempts or errors.

## Bisection: foreground sshd works, service-mode sshd fails

The decisive experiment, run manually by the operator on
2026-05-16:

```powershell
Stop-Service sshd
C:\Windows\System32\OpenSSH\sshd.exe -d -d -d
```

Then from the MacBook:

```bash
ssh desktop-2jj3187 'hostname'
```

**Result: full end-to-end success.** KEX completed
(curve25519-sha256 + ssh-ed25519), authentication succeeded with
matching ED25519 fingerprint, `hostname` returned
`DESKTOP-2JJ3187`, clean disconnect. TOFU prompt answered; host
key `SHA256:OFNLsVw4RJlChJef1Db+eelKZnqJfPsVYLkNPVED6V8`
persisted to MacBook `known_hosts`.

Foreground vs service-mode is the **only difference** between
success and failure. The SSH protocol bytes are identical; the
configuration is identical; the host keys are identical; the
firewall rule is identical; the admin key is identical; the
network path is identical. The only variable is the launching
context of the sshd process.

## Root Cause

Windows OpenSSH uses privilege separation similar to POSIX
OpenSSH but implemented differently. On Windows there is no
`fork()`; the main sshd process (running under the service
account) launches a per-connection child via process
spawning. Microsoft's OpenSSH 9.5 implementation uses the same
`sshd.exe` binary with `-y` (network child, pre-auth) and `-z`
(user child, post-auth) flags. Earlier hypotheses about
`sshd-session.exe` were incorrect for this version of Win32-
OpenSSH; the foreground log explicitly shows:

```
debug3: spawning "C:\\Windows\\System32\\OpenSSH\\sshd.exe" -d -d -d -y as user
debug2: Network child is on pid 6132
...
debug3: spawning "C:\\Windows\\System32\\OpenSSH\\sshd.exe" -d -d -d -z as user
User child is on pid 19808
```

For privsep to work, Microsoft's design requires a **virtual
local account named `sshd`** under which the network child runs.
That account must:

1. Exist as a local Windows account (typically created by
   `install-sshd.ps1`).
2. Have specific LSA privileges (also granted by
   `install-sshd.ps1`).
3. Have read access to `C:\ProgramData\ssh\` and the configured
   subdirectories (granted by `FixHostFilePermissions.ps1`,
   which sets the NTFS ACL).

**The bug:** on Windows 11 24H2, `Add-WindowsCapability -Online
-Name OpenSSH.Server*` installs the OpenSSH binaries and creates
the sshd service entry, but **does not** create the `sshd`
virtual user, **does not** grant the LSA privileges, and **does
not** apply the NTFS ACL on `C:\ProgramData\ssh\` that the
privsep child requires.

When a connection arrives at the listener sshd (running as
`NT AUTHORITY\SYSTEM` per the service definition), it spawns
`sshd.exe -y` to handle the network/KEX phase. The spawn is
supposed to drop privileges to the `sshd` virtual user. Either:
- the user doesn't exist and the spawn fails silently
- the user exists but lacks NTFS read on its own config files
  and crashes on first config read

Either way, the per-connection child dies before sending any
SSH_MSG_KEXINIT response and before attaching to the Event Log
writer — hence the `Connection reset by ...` symptom + zero log
entries.

When sshd is launched manually as `jeffr` (an interactive
Administrator), the privsep model is bypassed because the
launching account is already a regular user with full NTFS
access. The foreground log explicitly says:

```
debug1: Not running as SYSTEM: skipping loading user profile
debug3: get_user_token - i am running as jeffr, returning process token
```

The `-y` and `-z` children also run as `jeffr` and inherit
`jeffr`'s read access on `C:\ProgramData\ssh\`. They work.

## Why Microsoft's repair scripts are needed

Microsoft maintains the install/repair tooling in their
`openssh-portable` upstream:

- `install-sshd.ps1` — creates the `sshd` service AND the
  virtual `sshd` user, grants LSA privileges, sets the service
  startup type.
- `FixHostFilePermissions.ps1` — applies the correct NTFS ACL
  on `C:\ProgramData\ssh\` and its child files so the privsep
  user can read them.
- `OpenSSHUtils.psm1` / `.psd1` — supporting PowerShell module
  used by both scripts.

These scripts exist in `C:\Windows\System32\OpenSSH\` on the
older "OpenSSH GitHub Release" install path (the MSI from
PowerShell/openssh-portable Releases). They are **not** present
on Windows 11 24H2 systems where OpenSSH was installed via
`Add-WindowsCapability` — Microsoft strips them from the native
payload.

This is the Win 11 24H2 specific gap. The capability install is
necessary but not sufficient. Without the repair scripts, the
service has no working privsep account.

## Fix path

Operator ran on 2026-05-16:

```powershell
# 1. Reset state
Stop-Service sshd -ErrorAction SilentlyContinue
Remove-LocalUser -Name 'sshd' -ErrorAction SilentlyContinue

# 2. Remove ad-hoc debug lines added during the diagnostic phase
$cfg = 'C:\ProgramData\ssh\sshd_config'
(Get-Content $cfg) -notmatch '^SyslogFacility|^LogLevel' |
  Set-Content $cfg -Encoding ascii

# 3. Fetch the missing repair scripts from Microsoft upstream
cd C:\Windows\System32\OpenSSH
$repo = 'https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh'
Invoke-WebRequest -Uri "$repo/install-sshd.ps1"          -OutFile install-sshd.ps1
Invoke-WebRequest -Uri "$repo/FixHostFilePermissions.ps1" -OutFile FixHostFilePermissions.ps1
Invoke-WebRequest -Uri "$repo/OpenSSHUtils.psm1"          -OutFile OpenSSHUtils.psm1
Invoke-WebRequest -Uri "$repo/OpenSSHUtils.psd1"          -OutFile OpenSSHUtils.psd1

# 4. Apply the fix
.\install-sshd.ps1
.\FixHostFilePermissions.ps1 -Confirm:$false
Restart-Service sshd
```

This is the immediate operator-driven fix. The v0.5.1 install
packet (forthcoming) codifies this as a permanent solution with
proper supply-chain hygiene (see Spec Implications below).

## Negative findings (what we ruled out)

The bisection cleanly rules out:

- **SSH infrastructure** — drop-in, Include directive, Match
  block, AllowGroups administrators, admin key fingerprint,
  host key trust. All proven correct end-to-end by the
  foreground test.
- **LAN-path interference** — loopback `ssh 127.0.0.1` inside
  DSJ reproduces the same reset under service-mode, AND
  foreground sshd accepts the MacBook connection over the LAN.
  The bug is sshd-process-internal.
- **WARP / Cloudflare Zero Trust intercept** — the foreground
  sshd's connection log records `Connection from 192.168.0.10
  port 49524 on 192.168.0.217 port 22`. The source IP
  `192.168.0.10` is the MacBook's LAN IP (not a Cloudflare edge
  IP), confirming WARP's RFC1918-exclude rule kept the traffic
  direct over the LAN. The MacBook is enrolled in WARP (Kids /
  personal profile); DSJ is not yet enrolled. The asymmetry
  does not affect LAN SSH today.
- **Algorithm posture** — `sshd -T` parses cleanly with the
  same KEX / cipher / MAC / host-key-algorithm lists for both
  source IPs (MacBook and loopback). No algorithm rejection.
- **Host-key ACLs** — every key file under `C:\ProgramData\ssh\`
  is SYSTEM + Administrators FullControl only. No
  `Authenticated Users` access. StrictModes cannot reject these.
- **Defender** — the connection reset happens with Defender's
  default real-time protection enabled, but the foreground test
  succeeds under the same Defender posture. Not the cause.

The narrow positive finding is the virtual `sshd` user + NTFS
ACL gap. That is the single variable.

## Spec implications

A new section will be added to
[windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md):
**§Windows OpenSSH Capability Install Gaps**.

Key points:
- `Add-WindowsCapability OpenSSH.Server*` is necessary but not
  sufficient on Win 11 24H2.
- The privsep virtual user + NTFS ACL on `C:\ProgramData\ssh\`
  require Microsoft's `install-sshd.ps1` +
  `FixHostFilePermissions.ps1` to be run after capability
  install.
- These scripts are stripped from the native payload on Win 11
  24H2 and must be fetched from upstream (`PowerShell/openssh-
  portable`, branch `latestw_all`, path
  `contrib/win32/openssh/`).
- Supply-chain hygiene for runtime download: pin to a specific
  commit SHA (not `latestw_all`), verify sha256 checksums after
  download, copy to `C:\Windows\System32\OpenSSH\` only after
  verification. Future install packets should embed pinned
  commit references in the packet markdown.
- Alternative path (longer-term): vendor copies of the scripts
  into the system-config repo with proper attribution + license
  preservation (PowerShell/openssh-portable is MIT-licensed),
  and have the install packet copy them locally rather than
  fetching at runtime.

## v0.5.0 install packet implications

The v0.5.0 install packet is now known to be insufficient on
its own for a Win 11 24H2 host. v0.5.0 codifies the OpenSSH-on-
Windows configuration (capability install, Match block,
Include directive injection, drop-in, admin key, firewall rule)
but does not codify the privsep-user / NTFS-ACL repair step.

v0.5.1 will:
1. Run the v0.5.0 steps as-is (capability, service start, Match
   block, Include directive, drop-in, admin key, firewall).
2. After S2 (service start), check whether the privsep `sshd`
   user exists with the correct ACLs. If yes, proceed. If no,
   download (with pinned commit + sha256 checksum) the four
   Microsoft repair scripts, copy to
   `C:\Windows\System32\OpenSSH\`, run `install-sshd.ps1` and
   `FixHostFilePermissions.ps1`, then proceed.
3. Add a real-loopback test inside S7 (`ssh -o BatchMode=yes -i
   <pinned-pubkey> 127.0.0.1 hostname`) to close the v0.5.0
   verification gap recorded in the install apply record. The
   loopback test will catch service-mode failures before the
   install reports success.

The v0.5.0 packet markdown stays preserved with a SUPERSEDED
notice (same pattern as v0.3.0 and v0.4.0). v0.5.0 on-host
evidence dir, v0.4.0 on-host evidence dir, v0.1.0 diagnostic
on-host evidence dir all stay preserved untouched.

## WARP / Cloudflare future-state note

For the eventual Cloudflare WARP enrollment of DSJ (currently
blocked on `cloudflare-dns-windows-multi-user-rebaseline`):

- The `Jefahnierocks SSH LAN TCP 22` firewall rule is scoped to
  `RemoteAddress 192.168.0.0/24`. WARP's default split-tunnel
  exclude rule preserves RFC1918 traffic on the LAN, so this
  rule should continue to work after WARP enrollment.
- The MacBook is currently enrolled in WARP under the Kids /
  personal profile. The source IP for incoming SSH connections
  is the MacBook's LAN IP (`192.168.0.10`), not a Cloudflare
  edge IP, because WARP's RFC1918-exclude rule applies.
- At WARP-cutover time on DSJ, an explicit verification step
  is needed: confirm `ssh desktop-2jj3187 'hostname'` from the
  MacBook still succeeds after WARP enrolls DSJ. If WARP
  changes the apparent source IP for LAN traffic, the firewall
  rule will need adjustment (or DSJ's WARP split-tunnel config
  will need explicit LAN-exclude).
- This is tracked separately as the
  `desktop-2jj3187-warp-enrollment-cutover-pending` blocked
  item. Not in scope for v0.5.1.

## Lessons-learned ledger

The DSJ Phase 3 sequence has now produced four distinct spec
sections, each named for a class of Windows-OpenSSH-vs-Linux-
OpenSSH default divergence:

| Spec section | Origin failure | Class |
|---|---|---|
| `§Encoding Contract` | v0.3.0 mojibake | shell-default difference (WinPS 5.1 vs UTF-8) |
| `§Cross-Shell Data Normalization` | v0.3.0 enum-as-int | serialization difference |
| `§Windows OpenSSH Defaults` | v0.4.0 no-Include | upstream-default difference |
| `§Windows OpenSSH Capability Install Gaps` (new) | v0.5.0 service-mode KEX reset | capability-install completeness difference |

The pattern: assume Linux-distro / POSIX default → ship → fail
→ write spec section. The forward-looking guard remains the
same: **before drafting a packet that touches Windows OpenSSH,
read the upstream Microsoft source AND verify install
completeness, not just binary presence.** Each iteration has
narrowed what "upstream Microsoft source" means in practice
(the binary, the default config, now the install scripts).

## Cross-References

- [desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md) (v0.1.0 apply record with the foreground-success finding)
- [desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md) (v0.5.0 install apply record + verification-gap finding)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) (spec; new §Windows OpenSSH Capability Install Gaps section added in the same commit chain)
- [current-status.yaml](./current-status.yaml)
- Upstream Microsoft repair scripts (branch `latestw_all`):
  - https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/install-sshd.ps1
  - https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/FixHostFilePermissions.ps1
  - https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/OpenSSHUtils.psm1
  - https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/OpenSSHUtils.psd1
- Upstream Win32-OpenSSH issue tracker: https://github.com/PowerShell/Win32-OpenSSH/issues
