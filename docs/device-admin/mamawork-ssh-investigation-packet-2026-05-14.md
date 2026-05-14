---
title: MAMAWORK Windows-Side SSH Investigation Packet - 2026-05-14
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, ssh, openssh, firewall, investigation]
priority: high
---

# MAMAWORK Windows-Side SSH Investigation Packet - 2026-05-14

The 2026-05-13 elevated intake records `sshd.exe` listening on
`0.0.0.0:22` and `[::]:22` on MAMAWORK and a custom Windows Firewall
rule `Dad Remote Management` allowing inbound TCP/22 with
`Profile=Any`. The 2026-05-14 HomeNetOps PASS hand-back confirms that
DNS resolves correctly, ARP binds the IP to the wired MAC, and
OPNsense does **not** gate same-subnet TCP/22. Yet `nc -vz` and
`ssh ... verlyn13@mamawork.home.arpa` from `fedora-top` time out.

This packet prepares a **read-only Windows-side investigation** of why
TCP/22 is not reachable from the LAN despite the upstream posture
looking correct. The investigation may produce a small remediation
follow-up, but **no live remediation is authorized by approving this
investigation packet**. Findings + a separate remediation packet
follow.

## Scope

In scope (investigation, read-only):

- Whether the Windows OpenSSH Server **feature** is installed.
- Whether the `sshd` Windows service is **present**, **running**,
  and set to **Automatic** start.
- Whether the `ssh-agent` Windows service state matters here (it is
  not required for inbound SSH, but its absence may be confusing).
- Whether the **Network category** for the active wired interface is
  `Private` (required for our LAN-scoped rules to apply).
- Whether the `Dad Remote Management` firewall rule is **enabled**,
  **inbound**, **TCP**, **port 22**, and reachable on the **Private**
  profile specifically. Document the current `Profile=Any` posture
  even though scoping to `Private` belongs in a separate remediation
  packet.
- Whether any **other firewall rule blocks 22/tcp inbound** at higher
  priority than the allow rule.
- Whether `netstat`/`Get-NetTCPConnection` confirms `sshd.exe`
  binding on `0.0.0.0:22` and `[::]:22`.
- Whether `Test-NetConnection -ComputerName 127.0.0.1 -Port 22` and
  `Test-NetConnection -ComputerName 192.168.0.101 -Port 22` from
  MAMAWORK itself both succeed (rules out host-firewall block by
  loopback test, then localhost-vs-LAN comparison).
- Whether **Windows Defender Firewall** is active per profile and
  whether `NetFirewallProfile` `DefaultInboundAction` is `Block` or
  `NotConfigured` on `Private`.
- Whether `C:\ProgramData\ssh\sshd_config` settings are consistent
  with the intake (`Port 22`, `PubkeyAuthentication yes`,
  `PasswordAuthentication no`, `AuthorizedKeysFile`,
  `Subsystem sftp`).
- Whether `C:\ProgramData\ssh\administrators_authorized_keys`
  contains the expected `DadAdmin_WinNet` ED25519 fingerprint
  `SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`.
- Whether `C:\Users\<user>\.ssh\authorized_keys` for the intended
  admin user is sane.
- Confirmation of the **exact SSH username form** to use:
  - For a local account: `DadAdmin`
  - For a Microsoft Account: `MAMAWORK\jeffr` (or `jeffr@mamawork`)
- Whether the `sshd` event log (`Application` -> `OpenSSH/Operational`
  or `Microsoft-Windows-Security-Auditing`) shows refused connections
  from the LAN.

Out of scope (separate packets, even if the investigation suggests
them):

- Enabling, restricting, or modifying any firewall rule (including
  scoping `Dad Remote Management` to `Profile=Private` only - that
  is the remediation packet).
- Enabling, disabling, or starting/stopping `sshd`, `ssh-agent`,
  WinRM, or any other service.
- Changing the network category (Public -> Private).
- Editing `sshd_config`, `administrators_authorized_keys`, or per-
  user `authorized_keys`.
- Adding or removing accounts, group memberships, or admin
  privileges.
- Enabling RDP, WinRM, PSRemoting, VNC, or any other remote-admin
  service.
- Adding a new SSH key. The MAMAWORK SSH key bootstrap is a
  separate future packet, gated on the DadAdmin_WinNet continuity
  answer.
- Switching MAMAWORK from host-static IP to DHCP. That is the
  separate
  [mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md).
- Cloudflare, Tailscale, WARP, `cloudflared`, 1Password, LUKS, power,
  reboot.

## Known Facts At Packet Time

| Fact | Value | Source |
|---|---|---|
| Hostname | `MAMAWORK` (DNS `MamaWork`) | [windows-pc-mamawork.md](./windows-pc-mamawork.md) |
| Static LAN IP | `192.168.0.101/24` | same |
| Wired MAC | `B0-41-6F-0E-B7-B6` | same |
| FQDN | `mamawork.home.arpa` | [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md) |
| LAN resolution | `dig @192.168.0.1 mamawork.home.arpa +short` -> `192.168.0.101` | same |
| ARP binding | LAN/igc1 confirms `192.168.0.101 <-> b0:41:6f:0e:b7:b6` | same |
| OPNsense block on TCP/22 | None; same-subnet, no rule | same |
| `sshd.exe` listening per intake | `0.0.0.0:22` and `[::]:22` (PID 4652) | [windows-pc-mamawork.md](./windows-pc-mamawork.md) |
| `Dad Remote Management` firewall rule | Enabled, Allow, Inbound, port 22, **Profile=Any** | same |
| `sshd_config` highlights | `Port 22`, `PubkeyAuthentication yes`, `PasswordAuthentication no`, `StrictModes no`, `LogLevel DEBUG3` | same |
| Authorized admin key | `DadAdmin_WinNet` ED25519 `SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk` in `administrators_authorized_keys` and `C:\Users\DadAdmin\.ssh\authorized_keys` | same |
| Network category | `Private` at intake time | same |
| Probe outcome from fedora-top | TCP/22 times out (to `mamawork.home.arpa` and to `192.168.0.101`) | [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md) |

The intake's snapshot is from 2026-05-13. The TCP timeout was
observed 2026-05-14. Anything that changed on MAMAWORK between
those two timestamps is a candidate cause; the investigation
explicitly re-checks every relevant fact.

## Hypothesis Tree

In order of likelihood, given the evidence:

1. **Network category flipped from `Private` back to `Public`** (e.g.
   after a reboot, after a new ethernet plug-in, or after Windows
   reclassified the network). The `Dad Remote Management` rule is
   `Profile=Any` so it should still apply, but the Windows
   third-party-firewall + Windows-Defender-firewall combination can
   behave unexpectedly when the active profile changes.
2. **`sshd` service stopped** (manually, or due to a service
   crash, or due to a Windows update). Even if intake captured it
   running, the timeout is now.
3. **An additional firewall rule** at higher priority deny-overrides
   the allow rule. Windows Firewall evaluates **deny first**; a
   later deny rule for TCP/22 inbound on any profile would
   trump the allow rule.
4. **`sshd_config` change** (`AllowUsers`, `ListenAddress`,
   `Match`) that excludes the LAN client. The intake's
   `sshd_config` highlights do not show these directives, but the
   full file was not read in v1.0 of the intake script.
5. **Network adapter change** moved the listening socket to a
   different interface (e.g. a USB Ethernet, a virtual adapter, a
   Wi-Fi adapter that came online and Windows changed the active
   route).
6. **Third-party endpoint security** (Defender ASR or external EDR)
   silently blocking inbound TCP/22 on the LAN. Defender exclusions
   exist (intake noted 1 path + 1 process + 1 extension + 1 ASR
   rule) but the rule values were intentionally not captured.

The investigation reads enough to disambiguate at least items 1-5
without changing state.

## Investigation Procedure

The operator runs this procedure on MAMAWORK from an elevated
PowerShell 7+ session (with Windows PowerShell 5.1 fallbacks
noted). All steps are read-only; the script writes to
`C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-ssh-investigation-<timestamp>\`
matching the intake script's pattern.

### Step 0 - Identity and session

```powershell
hostname
whoami
[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
```

Return: hostname (must be `MAMAWORK` or `MamaWork`), the signed-in
user (typically `MAMAWORK\jeffr`), and whether the session is
elevated.

### Step 1 - Network identity and category

```powershell
Get-NetAdapter -Physical |
  Select-Object Name, Status, LinkSpeed, MacAddress, InterfaceDescription |
  Format-Table -AutoSize

Get-NetIPConfiguration |
  Select-Object InterfaceAlias, IPv4Address, IPv6Address, DNSServer

Get-NetConnectionProfile |
  Select-Object InterfaceAlias, NetworkCategory, IPv4Connectivity, NetworkName
```

Return: the wired interface name, MAC, IPv4 (must be
`192.168.0.101/24`), and **NetworkCategory** per interface.

### Step 2 - `sshd` service state

```powershell
Get-Service sshd, ssh-agent |
  Select-Object Name, Status, StartType, DisplayName

# Confirm sshd binary, version, and last service status changes
Get-Command sshd | Select-Object Source
sshd -V 2>&1
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Service Control Manager'} -MaxEvents 20 |
  Where-Object { $_.Message -match 'sshd' } |
  Select-Object TimeCreated, Id, LevelDisplayName, Message |
  Format-List
```

Return: `sshd` Status (`Running` / `Stopped`), StartType
(`Automatic` desired); recent service start/stop events.

### Step 3 - Listener confirmation

```powershell
Get-NetTCPConnection -State Listen |
  Where-Object { $_.LocalPort -eq 22 } |
  Select-Object LocalAddress, LocalPort, OwningProcess

# Resolve the process to a name
$pid22 = (Get-NetTCPConnection -State Listen -LocalPort 22 |
  Select-Object -ExpandProperty OwningProcess -First 1)
if ($pid22) {
  Get-Process -Id $pid22 | Select-Object Id, ProcessName, Path
}

# Same-host probes
Test-NetConnection -ComputerName 127.0.0.1 -Port 22 -InformationLevel Detailed
Test-NetConnection -ComputerName 192.168.0.101 -Port 22 -InformationLevel Detailed
```

Return: which local addresses are listening on 22; which PID owns
them; and whether localhost and LAN-IP probes from MAMAWORK to
MAMAWORK succeed.

### Step 4 - Firewall posture

```powershell
Get-NetFirewallProfile |
  Select-Object Name, Enabled, DefaultInboundAction,
    DefaultOutboundAction, NotifyOnListen, LogBlocked

# Find every rule that touches TCP/22 inbound
$rules22 = Get-NetFirewallRule |
  Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' } |
  Where-Object {
    ($_ | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue).LocalPort -contains 22
  }
$rules22 |
  Select-Object DisplayName, Action, Profile,
    @{n='Program'; e={ ($_ | Get-NetFirewallApplicationFilter).Program }} |
  Format-Table -AutoSize

# Specifically the 'Dad Remote Management' rule
Get-NetFirewallRule -DisplayName 'Dad Remote Management' -ErrorAction SilentlyContinue |
  Select-Object DisplayName, Enabled, Action, Direction, Profile
```

Return: per-profile firewall state; every enabled inbound rule that
mentions TCP/22, with action (Allow/Block); the explicit
`Dad Remote Management` rule's current Profile and Action.

If any **Block** rule for TCP/22 inbound appears on the active
profile, that is the cause and the remediation packet narrows or
removes it.

### Step 5 - sshd_config consistency

```powershell
# Read the running sshd_config (not the per-user one)
Get-Content C:\ProgramData\ssh\sshd_config |
  Select-String -Pattern '^(\s*[A-Za-z]|^\s*#)' |
  Out-File -Encoding utf8 "$OutDir\sshd_config-active.txt"

# Show the AllowUsers / AllowGroups / ListenAddress / Match lines specifically
Get-Content C:\ProgramData\ssh\sshd_config |
  Select-String -Pattern '^(AllowUsers|DenyUsers|AllowGroups|DenyGroups|ListenAddress|Match|Port|PubkeyAuthentication|PasswordAuthentication|PermitRootLogin|AuthenticationMethods|AuthorizedKeysFile|StrictModes|LogLevel)\b'
```

Return: every directive that could refuse the LAN client.

If `AllowUsers` excludes the operator, or `ListenAddress` is bound
to `127.0.0.1` only, that is the cause.

### Step 6 - authorized_keys posture

```powershell
$adminKeys = 'C:\ProgramData\ssh\administrators_authorized_keys'
if (Test-Path $adminKeys) {
  Get-Acl $adminKeys | Format-List
  Get-Content $adminKeys | ForEach-Object {
    if ($_ -match '^\s*ssh-') { ssh-keygen -lf - 2>$null <<<< $_ }
  }
}

foreach ($u in 'DadAdmin','jeffr','ahnie') {
  $p = "C:\Users\$u\.ssh\authorized_keys"
  if (Test-Path $p) {
    Write-Host "--- $p ---"
    Get-Acl $p | Format-List
    Get-Content $p | ForEach-Object {
      if ($_ -match '^\s*ssh-') { ssh-keygen -lf - 2>$null <<<< $_ }
    }
  }
}
```

Return: ACL on each `authorized_keys` (matters because
`StrictModes no` is set, but document the ACL anyway) and the
fingerprints present.

Compare against the intake's recorded
`SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`.

### Step 7 - OpenSSH event log

```powershell
Get-WinEvent -LogName OpenSSH/Operational -MaxEvents 100 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, LevelDisplayName, Message |
  Format-List

Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 20 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, Message |
  Format-List
```

If `OpenSSH/Operational` is enabled (DEBUG3 in `sshd_config`
suggests so), the most recent timeout from fedora-top should be in
there. Look for `error: kex_exchange_identification: read: Connection reset`,
`Connection from <fedora-top ip> port <p> on 192.168.0.101 port 22`,
or no entry at all (which means traffic never reached sshd).

### Step 8 - Write a summary report

The script writes a `SUMMARY.md` per the intake-script pattern with
the verdict for each hypothesis.

## SSH Username Form For The Client

Independent of the investigation, the operator may want to verify
the **exact SSH username form** at apply time. Three plausible
forms; the right one depends on which account holds the
authorized_key:

| Form | When to use |
|---|---|
| `DadAdmin` | Local Windows account `DadAdmin`. Matches the intake's `administrators_authorized_keys` and `C:\Users\DadAdmin\.ssh\authorized_keys`. **This is the expected form.** |
| `MAMAWORK\jeffr` (or `MAMAWORK\\jeffr` in shells) | Microsoft Account `jeffr` referenced as a local-machine identity. Use only if the operator decides Microsoft-Account-backed SSH is the target (separate packet). |
| `jeffr@MAMAWORK` | Same as above with alternate syntax. |

The default for the future remediation is `DadAdmin` until and
unless a separate decision moves the admin-key to a Microsoft-
Account-backed identity. That decision belongs to the privilege-
cleanup packet, not this investigation.

## Possible Outcomes And The Follow-Up Packets They Imply

| Finding | Follow-up packet |
|---|---|
| `sshd` service is stopped or set to Manual | `mamawork-ssh-service-restart-and-auto-start-packet` |
| Network category is `Public` | `mamawork-network-profile-private-packet` |
| `Dad Remote Management` rule disabled, deleted, or replaced | `mamawork-ssh-firewall-rule-restore-packet` |
| Higher-priority deny rule blocks 22/tcp | `mamawork-ssh-firewall-conflict-resolution-packet` |
| `AllowUsers` / `ListenAddress` / `Match` excludes the LAN client | `mamawork-sshd-config-fix-packet` (and the broader `mamawork-ssh-hardening` packet from `handoff-mamawork.md` covers similar work) |
| `administrators_authorized_keys` missing the expected key | depends on the DadAdmin_WinNet continuity answer (see handoff Q1); either `mamawork-ssh-key-restore-packet` or `mamawork-ssh-key-bootstrap-packet` |
| All-Windows-side state looks fine, traffic never reached sshd | escalate to HomeNetOps for L2/L3 diagnostics on the OPNsense LAN segment (out of system-config scope) |

Every follow-up requires its own approval phrase. The investigation
itself is read-only.

## Security / Secret Policy

- Do **not** copy private keys, credentials, OAuth tokens, OpenSSH
  session secrets, Defender exclusion path/process/value contents,
  ASR rule IDs, BitLocker recovery values, Wi-Fi PSKs, browser
  data, saved RDP credentials, or shell history into the
  investigation output folder.
- Public-key fingerprints, hostnames, MAC addresses, LAN IPs, port
  numbers, service names, network category, firewall rule names,
  and event-log Event IDs are recordable.
- The output folder follows the intake-script pattern:
  `C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-ssh-investigation-<UTC-timestamp>\`.
  Bring the folder to the MacBook for review; do not commit raw
  output to git. A repo-safe summary belongs in a future apply or
  evidence-ingest doc.

## Required Approval Phrase

```text
I approve running the MAMAWORK Windows-Side SSH Investigation
Packet read-only on MAMAWORK: from an elevated PowerShell session
as MAMAWORK\jeffr, run the documented steps 0-8 to capture
hostname/identity/elevation, Get-NetAdapter / Get-NetIPConfiguration
/ Get-NetConnectionProfile, Get-Service sshd ssh-agent,
Get-NetTCPConnection state Listen for port 22, Test-NetConnection
to 127.0.0.1:22 and 192.168.0.101:22, Get-NetFirewallProfile +
every enabled inbound rule for TCP/22 + the Dad Remote Management
rule, sshd_config directives (Port, PubkeyAuthentication,
PasswordAuthentication, AllowUsers, AllowGroups, DenyUsers,
DenyGroups, ListenAddress, Match, PermitRootLogin,
AuthenticationMethods, AuthorizedKeysFile, StrictModes, LogLevel),
administrators_authorized_keys + per-user authorized_keys ACLs and
fingerprints, OpenSSH/Operational + Security 4625 events. Write
the output to
C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-ssh-investigation-<timestamp>\
and return a non-secret SUMMARY.md to system-config. Do not start,
stop, enable, disable, install, or remove any service. Do not edit
any firewall rule. Do not edit sshd_config or any authorized_keys
file. Do not change the network profile. Do not add or remove any
user, group, or admin membership. Do not touch BitLocker, Secure
Boot, RDP, WinRM, Tailscale, Cloudflare, WARP, cloudflared, or
1Password. Do not paste secrets into the shell or into the output
folder. Read-only investigation only.
```

## Evidence Template (post-investigation hand-back)

```text
timestamp:
operator:
elevation: yes/no
hostname:
network category (wired):
sshd service status: running/stopped + starttype
sshd binding: 0.0.0.0:22 and [::]:22 confirmed yes/no
loopback probe (127.0.0.1:22): pass/fail
LAN-self probe (192.168.0.101:22): pass/fail
"Dad Remote Management" rule: enabled? profile? action?
any deny rule for TCP/22 inbound: yes/no
sshd_config AllowUsers / ListenAddress / Match lines: <values>
administrators_authorized_keys present: yes/no
expected DadAdmin_WinNet fingerprint present: yes/no
recent OpenSSH/Operational entries from fedora-top probe: yes/no
recent Security Event 4625 entries from fedora-top probe: yes/no
hypothesis verdict (1 through 6 from packet):
recommended follow-up packet:
remaining blockers:
```

## Related

- [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md)
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [handoff-windows-lan-intake.md](./handoff-windows-lan-intake.md) -
  the generic Windows intake script pattern this investigation
  mirrors.
- [mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md) -
  separate optional packet for the host-static vs DHCP question.
- [fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md) -
  the parallel packet on the fedora-top side.
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
