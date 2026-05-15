---
title: MAMAWORK Inbound TCP Blackhole Remediation Apply - 2026-05-14
category: operations
component: device_admin
status: applied-lan-reachable-ssh-auth-fails
version: 0.2.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, firewall, network-identity, evidence]
priority: high
---

> **2026-05-14 v0.2.0 changes**: ingested the MacBook-side LAN
> verification probes (4 of 4 MacBook → MAMAWORK probes SUCCEEDED
> for both TCP/3389 and TCP/22 via IP + FQDN). fedora-top probes
> not runnable (fedora-top offline / unreachable from MacBook).
> SSH end-to-end pubkey auth from MacBook FAILED with "Permission
> denied (publickey)" for three different admin usernames
> (DadAdmin, jeffr, Administrator) even though the verbose-mode
> client confirms the correct key (SHA256:qilvkR7/...) is offered
> via the 1Password SSH agent. Root cause is on MAMAWORK's side:
> `C:\ProgramData\ssh\administrators_authorized_keys` is not being
> honored by Windows OpenSSH (ACL, ownership, or encoding issue).
> See "SSH End-To-End Verification Result" below.

# MAMAWORK Inbound TCP Blackhole Remediation Apply - 2026-05-14

Operator applied
[mamawork-inbound-tcp-blackhole-remediation-packet-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-packet-2026-05-14.md)
on MAMAWORK from an elevated PowerShell 7+ session at
`2026-05-14T14:47:40-08:00` (AKDT). Phase 1 (network-identity
reclassification) was a deliberate no-op because a prior
operator-side session earlier the same afternoon had already
flipped the live binding to `Private`. Phase 2 Option B (new
`Jefahnierocks SSH LAN TCP 22` rule) was applied cleanly.
**Host-side state is now correct** for both RDP and SSH on the
trusted LAN; **LAN nc probes are still pending** on the operator
side and will be appended to this record when returned.

No live `system-config` host change happened; the operator ran the
script on MAMAWORK and returned a non-secret evidence summary which
is ingested here.

## Approval

Guardian approval was Option B, recorded
2026-05-14T20:45:00Z (UTC), matching the
[Required Approval Phrase - Option B](./mamawork-inbound-tcp-blackhole-remediation-packet-2026-05-14.md#if-choosing-option-b-add-jefahnierocks-ssh-lan-tcp-22)
section of the packet. Operator executed the documented Phase 1
script then the Phase 2 Option B script as `MAMAWORK\jeffr` in an
elevated PowerShell 7+ session and returned the evidence in chat
via `handback-2026-05-14-evening.md`.

## Apply Sequence (Actual)

1. Operator opened elevated PowerShell 7+ on MAMAWORK as
   `MAMAWORK\jeffr` and ran a local wrapper
   `apply-mamawork-blackhole-and-sshkey-2026-05-14.ps1` that
   bundled the packet's Phase 1, Phase 2 Option B, and the SSH
   key bootstrap procedure into one session.
2. The packet's `Write-Evidence` helper silently dropped
   pipeline-input bodies (see "Packet Bug Discovered" below); the
   operator wrapped the run to recapture post-apply state cleanly
   into a `SUPPLEMENTAL CAPTURE` section appended to the same
   evidence file
   (`C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-inbound-blackhole-remediation-20260514-144740.txt`).
3. **Phase 1** executed:
   `Set-NetConnectionProfile -InterfaceIndex 9 -NetworkCategory Private`.
   This was a deliberate no-op because the live binding was
   already `Private` from a prior operator-side session at
   `2026-05-14T14:14:52-08:00` (evidence dir
   `mamawork-inbound-blackhole-apply-20260514-141452\`). No state
   regression.
4. **Phase 2 Option B** executed cleanly: created new rule
   `Jefahnierocks SSH LAN TCP 22` (Inbound Allow Private TCP 22
   RemoteAddress `192.168.0.0/24`). The `Dad Remote Management`
   rule was left untouched per the Option B directive.

## Evidence (Operator-Returned, Repo-Safe)

### Identity And Adapter

```text
timestamp:        2026-05-14T14:47:40.4267633-08:00
operator:         MAMAWORK\jeffr (elevated = True)
hostname:         MamaWork
wired_adapter:    Ethernet 2  ifIndex=9  MAC B0-41-6F-0E-B7-B6  1 Gbps
wired_ipv4:       192.168.0.101/24
```

### Pre-Apply State

```text
NetworkCategory:                            Private (already; from prior 14:14 session)
profile Name:                               Unidentified network
listener TCP/22:                            LISTEN 0.0.0.0:22 + [::]:22 (sshd, PID 5224)
listener TCP/3389:                          LISTEN 0.0.0.0:3389 + [::]:3389 (svchost, PID 1876)
listener TCP/445:                           LISTEN 0.0.0.0:445 + [::]:445 (System, PID 4)
rule: Jefahnierocks RDP LAN TCP 3389:       Allow Private TCP 3389  192.168.0.0/24
rule: Jefahnierocks RDP LAN UDP 3389:       Allow Private UDP 3389  192.168.0.0/24
rule: Dad Remote Management:                Allow Any TCP 22 RemoteAddress=192.168.0.0/24 (widened in prior 14:14 session; see "Prior Operator-Side Session" below)
rule: Jefahnierocks SSH LAN TCP 22:         absent
```

### Post-Apply State

```text
NetworkCategory:                            Private  (Set-NetConnectionProfile re-applied; idempotent)
profile Name:                               Unidentified network  (unchanged; see "Open Items" below)
listener TCP/22:                            LISTEN 0.0.0.0:22 + [::]:22  (unchanged)
listener TCP/3389:                          LISTEN 0.0.0.0:3389 + [::]:3389  (unchanged)
listener TCP/445:                           LISTEN 0.0.0.0:445 + [::]:445  (unchanged)

rule: Jefahnierocks SSH LAN TCP 22 (NEW):
    Enabled              True
    Direction            Inbound
    Action               Allow
    Profile              Private
    Protocol             TCP
    LocalPort            22
    LocalAddress         Any
    RemoteAddress        192.168.0.0/255.255.255.0

rule: Dad Remote Management (UNCHANGED):
    Enabled              True
    Direction            Inbound
    Action               Allow
    Profile              Any
    Protocol             TCP
    LocalPort            22
    LocalAddress         Any
    RemoteAddress        192.168.0.0/255.255.255.0

rule: Jefahnierocks RDP LAN TCP 3389 (UNCHANGED):
    Enabled              True; Allow Private TCP 3389 RemoteAddress 192.168.0.0/24

rule: Jefahnierocks RDP LAN UDP 3389 (UNCHANGED):
    Enabled              True; Allow Private UDP 3389 RemoteAddress 192.168.0.0/24
```

### LAN Reachability Verification

Probes were run by system-config from the operator MacBook at
`2026-05-14T23:30:00Z`. Results:

| # | Source host | Probe | Expected | Result |
|---|---|---|---|---|
| 1 | MacBook | `nc -vz -G 3 192.168.0.101 3389` | Succeeded | **Succeeded** (tcp/ms-wbt-server) |
| 2 | MacBook | `nc -vz -G 3 mamawork.home.arpa 3389` | Succeeded | **Succeeded** (tcp/ms-wbt-server) |
| 3 | MacBook | `nc -vz -G 3 192.168.0.101 22` | Succeeded | **Succeeded** (tcp/ssh) |
| 4 | MacBook | `nc -vz -G 3 mamawork.home.arpa 22` | Succeeded | **Succeeded** (tcp/ssh) |
| 5 | fedora-top | `nc -vz -w 3 192.168.0.101 3389` | Succeeded | **skipped** (fedora-top unreachable from MacBook; see note A) |
| 6 | fedora-top | `nc -vz -w 3 192.168.0.101 22` | Succeeded | **skipped** (fedora-top unreachable; see note A) |
| 7 | MacBook | Windows App RDP login (`MAMAWORK\DadAdmin`) | full session | **pending** (GUI interaction; requires operator) |
| 8 | MacBook | `ssh DadAdmin@mamawork.home.arpa 'hostname; whoami'` via 1P agent | `MAMAWORK / DadAdmin` | **FAILED** Permission denied (publickey); see "SSH End-To-End Verification Result" below |

**Note A (fedora-top unreachable from MacBook at probe time)**:
`ping 192.168.0.206` returns `Host is down`; `nc -vz fedora-top.home.arpa 22`
returns `No route to host`. DNS still resolves `fedora-top.home.arpa`
to `192.168.0.206` via the LAN resolver. fedora-top is likely
powered off, suspended, or off the LAN at probe time. The
fedora-top → MAMAWORK probes don't affect the MacBook → MAMAWORK
admin path conclusion and can be re-run after fedora-top is back
online; their purpose is to confirm same-subnet reachability from
a second vantage point, which the four successful MacBook probes
already cover.

**Conclusion on LAN reachability**: PASS. MacBook → MAMAWORK
inbound TCP/3389 and TCP/22 are both reachable, by both IP and
FQDN. The remediation packet's primary goal (closing the
LAN-inbound-TCP blackhole) is achieved.

### SSH End-To-End Verification Result

```text
test:      ssh -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub \
               -o IdentityAgent=$HOME/.1password-ssh-agent.sock \
               -o IdentitiesOnly=yes \
               -o PreferredAuthentications=publickey \
               -o BatchMode=yes \
               <user>@192.168.0.101 'hostname; whoami'

users tried (all three failed identically):
  DadAdmin       -> Permission denied (publickey,keyboard-interactive)
  jeffr          -> Permission denied (publickey,keyboard-interactive)
  Administrator  -> Permission denied (publickey,keyboard-interactive)

client offering (verified via ssh -vvv):
  ED25519 SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY
  (sourced from "explicit agent" = the 1Password SSH agent's
   AAAAIN2FlNNQ337TaP51lwouo/5+ZIG2WGy431b4UxtYIHnH entry)

server response:
  Authentications that can continue: publickey,keyboard-interactive
  (i.e., the offered key was rejected; no MaxAuthTries exhaustion)
```

The MacBook side is correct: the agent has the right private half,
the client offers it cleanly, the host-key check passes against
the existing `192.168.0.101` known_hosts entries. The failure is
on the MAMAWORK side. The SSH key bootstrap apply record's
evidence shows the public-key line is **in** the file:

```text
C:\ProgramData\ssh\administrators_authorized_keys after:
  SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk DadAdmin_WinNet
  SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin
```

…yet Windows OpenSSH rejects the matching key for three different
admin usernames. The most likely causes are:

1. **`administrators_authorized_keys` ACL/owner is wrong**. Windows
   OpenSSH enforces a hardcoded ACL check on this file (regardless
   of `sshd_config StrictModes`): owner must be `Administrators` or
   `SYSTEM`, and the DACL must grant access only to those two
   principals. If the existing file's owner is `MAMAWORK\jeffr`
   (the user who created or last wrote it) or if the DACL has any
   other principal, sshd silently ignores all keys in the file.
2. **File encoding has a UTF-8 BOM**. The bootstrap script's
   `Add-Content -Encoding utf8` is BOM-less in PowerShell 7+, but
   if the file already existed and had a BOM from an earlier
   create, the BOM persists and corrupts the first line. Less
   likely (would only break the first key line, not the second),
   but worth checking.
3. **`Match Group administrators` override** in `sshd_config` or a
   drop-in that redirects `AuthorizedKeysFile` to a non-default
   path. The intake captured `AuthorizedKeysFile .ssh/authorized_keys`
   but did not capture any `Match` blocks.

Diagnosis requires server-side inspection on MAMAWORK. See "Next
Diagnostic Step" below.

### MacBook-Side Artifacts Created

```text
~/.ssh/id_ed25519_mamawork_admin.1password.pub  (NEW; non-secret;
    public-key body extracted from the 1Password SSH agent;
    fingerprint SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY;
    comment "verlyn13@mamawork-admin"; mode 644)
```

Created during probing because the MacBook's chezmoi-managed
`~/.ssh/config` has `Host * IdentitiesOnly yes` without a default
`IdentityFile` matching the agent's keys, so ssh otherwise only
offered the on-disk `~/.ssh/id_ed25519` (`SHA256:dvFc8TNaUeE/...`)
which is unrelated to MAMAWORK admin.

The `.pub` file matches the existing chezmoi pattern for 1P-backed
identities (`id_ed25519_personal.1password.pub`,
`id_ed25519_happy_patterns.1password.pub`, etc.). It is a
candidate for chezmoi management alongside a corresponding
`~/.ssh/conf.d/mamawork.conf` host entry (`User DadAdmin`,
`IdentityFile ~/.ssh/id_ed25519_mamawork_admin.1password.pub`,
`HostKeyAlias 192.168.0.101` until known_hosts is reconciled for
`mamawork.home.arpa`). Treat as a future small chezmoi packet.

## Prior Operator-Side Session (2026-05-14 ~14:14 AKDT)

Before this packet's formal apply, a prior operator-side
PowerShell session ran a script named
`apply-mamawork-inbound-blackhole-2026-05-14.ps1` (evidence dir
`C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-inbound-blackhole-apply-20260514-141452\`).
That session is not formally tracked as a packet apply in
`current-status.yaml`; the operator's notes indicate it:

- Set `Ethernet 2` `NetworkCategory` to `Private` (Phase 1
  effect; this evening's Phase 1 was therefore a deliberate
  no-op).
- Widened `Dad Remote Management` `RemoteAddress` from
  `192.168.0.200` to `192.168.0.0/24` (this is the same change
  Option A of this packet would have made, except the prior
  session left `Profile=Any` instead of narrowing to `Private`).

The evening Option B apply (this record) layered the new
`Jefahnierocks SSH LAN TCP 22` rule on top of the prior session's
widened `Dad Remote Management`, leaving the latter untouched per
the Option B directive. The two rules are now functional duplicates
on the LAN scope (`Dad Remote Management` is broader because
`Profile=Any` includes Private + Public + Domain). The future
`mamawork-ssh-hardening` packet will consolidate them.

## Packet Bug Discovered

The packet's `Write-Evidence` helper in both Phase 1 and Phase 2
blocks used `param([string]$Message)` without
`[Parameter(ValueFromPipeline=$true)]`. Documented call sites use
the form
`... | Format-List | Out-String | Write-Evidence`,
which piped a multi-line string into a parameter that does not
accept pipeline input. PowerShell silently dropped the body and
captured only the literal-argument `Write-Evidence "header"` calls
in the evidence file, producing a "headers but no body" output.

The operator wrapped the run to recapture state cleanly with a
`SUPPLEMENTAL CAPTURE` section appended via direct
`Out-String | Add-Content` after the script finished. The
recaptured post-apply state is what the "Post-Apply State" section
above is based on.

**Fix landed**: the packet text is patched to v0.2.0 (this same
commit) declaring `Write-Evidence` with
`[Parameter(ValueFromPipeline=$true)]` and a `process` block. Both
positional and piped invocation forms now capture the body.

**Adjacent fix**: the same structural bug exists in the RDP
implementation packet (v0.2.0 patched the writer but not the
call-site binding). That packet is also patched in the same commit,
bumped to v0.3.0.

## Boundary Assertions

The apply did NOT change any of the following:

- `sshd_config`, `PasswordAuthentication`, legacy `DadAdmin_WinNet`
  authorized-key line, `C:\Users\jeffr\.ssh\authorized_keys.txt`,
  or the `C:\Users\DadAdmin.MamaWork\` profile copy. SSH key path
  changes are documented in
  [mamawork-ssh-key-bootstrap-apply-2026-05-14.md](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md).
- `HKLM:\Software\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*`
  registry entries. The stale `Bob's Internet 2` Public profile
  and the live binding's `Name=Unidentified network` are unchanged.
- `powercfg`, NIC wake-policy
  (`powercfg /deviceenablewake "Ethernet 2"`), Defender, ASR,
  BitLocker, Secure Boot, TPM, WinRM, PSRemoting, accounts,
  groups.
- Cloudflare, WARP, `cloudflared`, Tailscale, OPNsense, DNS,
  DHCP, 1Password. No `op` call ran on MAMAWORK.
- The `Jefahnierocks RDP LAN TCP/UDP 3389` rules from the RDP
  packet, the `Remote Assistance (DCOM-In)` Domain rule, and the
  two enabled inbound Block rules scoped to Reolink `\Camera\rqd.exe`.

## Rollback

Not used. Phase 1 was a no-op (already Private); Phase 2 added a
single new rule. If rollback is wanted later:

```powershell
Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' -ErrorAction SilentlyContinue |
  Remove-NetFirewallRule
```

Reverting Phase 1 to Public is not recommended; the live binding's
default-Public state was the bug.

## Next Diagnostic Step (SSH Pubkey Auth Failure)

A small read-only Windows-side investigation packet
(`mamawork-administrators-authorized-keys-investigation-packet`)
should run from elevated PowerShell 7+ on MAMAWORK and capture:

```powershell
$F = 'C:\ProgramData\ssh\administrators_authorized_keys'

# 1. ACL + owner (most likely cause)
Get-Acl $F | Format-List
(Get-Item $F).GetAccessControl().GetOwner([Security.Principal.SecurityIdentifier])

# 2. File encoding / BOM check (first 4 bytes)
$bytes = [IO.File]::ReadAllBytes($F) | Select-Object -First 4
$bytes | ForEach-Object { '{0:X2}' -f $_ }

# 3. Verbatim line content (raw, no parsing)
[IO.File]::ReadAllText($F)

# 4. sshd effective config + any Match blocks
& 'C:\Windows\System32\OpenSSH\sshd.exe' -T 2>&1 | Select-String 'authorized|match'

# 5. OpenSSH/Operational event log: recent AUTHKEYS / pubkey events
Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 50 |
  Where-Object { $_.Message -match 'AuthorizedKeysFile|pubkey|administrators_authorized_keys' } |
  Format-List TimeCreated, Id, Message
```

Operator returns the captured output (non-secret; public keys + ACL
+ event-log strings only). The likely fix is one of:

- ACL repair:
  `icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "SYSTEM:F" /grant "Administrators:F" /setowner Administrators`
- BOM strip: rewrite the file with `Set-Content -Encoding ascii`
  or `-Encoding utf8NoBOM`.
- If a `Match Group administrators` block redirects `AuthorizedKeysFile`,
  surface that to the future `mamawork-ssh-hardening` packet's
  scope.

This investigation packet is the immediate next step before
`mamawork-legacy-dadadmin-winnet-key-removal`,
`mamawork-ssh-hardening`, or the `mamawork-ssh-conf-d-on-macbook`
chezmoi-managed entry.

## Open Items

1. **`administrators_authorized_keys` is not being honored by
   Windows OpenSSH** (described above). Blocks MacBook → MAMAWORK
   SSH end-to-end. RDP is unaffected.
2. **Live profile Name = "Unidentified network"**: the
   reclassification flipped `NetworkCategory` only; the underlying
   identity-matching against the registry profile-list still does
   not pick up `Bob's Internet` (Private) for this binding.
   Recurrence is possible after reboot / adapter bounce / VPN
   toggle, in which case Phase 1 needs re-running. Permanent fix
   is the future `mamawork-network-list-registry-cleanup` packet.
3. **`Dad Remote Management` rule**: now functionally a duplicate
   of `Jefahnierocks SSH LAN TCP 22` on the LAN scope, but at
   `Profile=Any` instead of `Private`. Future `mamawork-ssh-hardening`
   packet decides whether to disable, narrow, or remove it.
4. **WoL per-device wake policy**: `Ethernet 2` is still not in
   `wake_armed`. Out of scope here; future `mamawork-nic-wake-enable`
   packet closes the gap.
5. **fedora-top offline at probe time**: the two fedora-top probes
   were skipped. Confirm fedora-top is reachable and re-run them
   to add a second-vantage-point datapoint. Not blocking.
6. **`mamawork.home.arpa` not in MacBook `known_hosts`**: the
   probe used `HostKeyAlias=192.168.0.101` because no FQDN entry
   exists. Same gap pattern as fedora-top; future small chezmoi
   packet adds both.
7. **`~/.ssh/id_ed25519_mamawork_admin.1password.pub` newly on
   disk**: matches the existing chezmoi pattern but not yet
   chezmoi-managed. Future small packet adds it to chezmoi
   source alongside a `~/.ssh/conf.d/mamawork.conf` host entry.

## Remaining Blockers

- **MacBook → MAMAWORK SSH end-to-end** is blocked by the
  `administrators_authorized_keys` issue above. RDP from MacBook
  → MAMAWORK is unaffected (LAN reachability passes, GUI smoke
  test is a separate operator action).

## Related

- [mamawork-inbound-tcp-blackhole-remediation-packet-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-packet-2026-05-14.md) -
  the packet this apply executed.
- [mamawork-lan-rdp-implementation-apply-2026-05-14.md](./mamawork-lan-rdp-implementation-apply-2026-05-14.md) -
  the 2026-05-14 morning RDP apply where the LAN inbound blackhole
  was first surfaced.
- [mamawork-ssh-key-bootstrap-apply-2026-05-14.md](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md) -
  the SSH key bootstrap apply (idempotent re-run; key install
  happened in the 2026-05-14 08:40 session).
- [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md) -
  HomeNetOps PASS evidence.
- [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md) -
  read-only investigation packet; the verdict that drove this
  remediation came from a scoped Phase 1 + Phase 4 run.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)
