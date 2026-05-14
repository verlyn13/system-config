---
title: MAMAWORK LAN RDP Implementation Packet - 2026-05-14
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, rdp, firewall, lan, power]
priority: high
---

# MAMAWORK LAN RDP Implementation Packet - 2026-05-14

Prepares MAMAWORK for **LAN-only RDP** from the MacBook Windows
App, mirroring the working pattern from
[windows-lan-rdp-implementation-2026-05-13.md](./windows-lan-rdp-implementation-2026-05-13.md)
(`DESKTOP-2JJ3187`).

Operator-applied on MAMAWORK from an elevated PowerShell 7+
session. No `system-config` host change is authorized by approving
this document; the operator executes the procedure on MAMAWORK
directly and returns a non-secret summary.

Hard boundary preserved: **no public WAN administrative exposure**.
RDP is enabled with Network Level Authentication, scoped to
`192.168.0.0/24` only, on the Private profile only.

## Scope

In scope:

- Enable RDP with Network Level Authentication (`fDenyTSConnections=0`,
  `UserAuthentication=1`).
- Set `TermService` to `Running` and `StartType=Automatic`.
- Disable the built-in broad `Remote Desktop` firewall display
  group (matches the DESKTOP-2JJ3187 pattern).
- Create two LAN-scoped custom firewall rules:
  - `Jefahnierocks RDP LAN TCP 3389` (Inbound Allow, Private, TCP
    `3389`, RemoteAddress `192.168.0.0/24`)
  - `Jefahnierocks RDP LAN UDP 3389` (Inbound Allow, Private, UDP
    `3389`, RemoteAddress `192.168.0.0/24`)
- Set the wired Ethernet network profile to `Private`.
- Apply MAMAWORK-appropriate power readiness:
  - `powercfg /hibernate off`
  - `standby-timeout-ac 0`
  - `hibernate-timeout-ac 0`
  - hybrid sleep disabled
- Best-effort enable Wake-on-LAN NIC properties (Magic Packet,
  Pattern Match, PME). Intake already showed all three Enabled;
  this is idempotent.
- Local 3389 port smoke test (`Test-NetConnection 127.0.0.1 3389`).
- Evidence captured to
  `C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-rdp-lan-<timestamp>.txt`.

Out of scope (matches the DESKTOP-2JJ3187 precedent's "Not
approved in this phase" list):

- Public WAN exposure of RDP, WinRM, VNC, SSH, or any admin service.
- Cloudflare, WARP, Tunnel, Access, Gateway, DNS changes.
- OPNsense, static DHCP, local DNS, WoL plugin/API changes.
- 1Password item creation or modification.
- BitLocker enable, Secure Boot enable, TPM clearing.
- WinRM or PowerShell Remoting enablement.
- OpenSSH `sshd_config`, `administrators_authorized_keys`, or
  per-user `authorized_keys` changes - those are the separate
  [mamawork-ssh-key-bootstrap packet (2026-05-14)](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md).
- Switching MAMAWORK from host-static IP to DHCP - separate
  [mamawork-switch-to-dhcp-source-of-truth packet (2026-05-14)](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md).
- Deleting users, modifying Codex sandbox accounts (`CodexSandboxOnline`,
  `CodexSandboxOffline`), or removing `WsiAccount`.
- Defender, ASR, AppLocker, or Smart App Control changes.
- Any change visible to the kid Windows user accounts (`ahnie`,
  `axelp`, `ilage`, `wynst`); kids continue to sign in with their
  own MS Accounts; RDP from the MacBook lands on a separate
  administrator session by default.

## Verified Current State (from 2026-05-13 intake + 2026-05-14 inputs)

```text
hostname:                 MAMAWORK  (DNS host MamaWork)
fqdn:                     mamawork.home.arpa
ip:                       192.168.0.101  (host-side static today;
                          ISC DHCP reservation exists on OPNsense;
                          ARP permanent=false until host switches
                          to DHCP - separate optional packet)
wired MAC:                B0-41-6F-0E-B7-B6  (Realtek PCIe GbE
                          Family Controller #2, Up @ 1 Gbps)
trusted LAN:              192.168.0.0/24
network category:         Private (intake)
RDP today:                Disabled (fDenyTSConnections=1,
                          TermService Stopped, all three built-in
                          Remote Desktop firewall rules Disabled)
existing SSH (LAN-only):  custom "Dad Remote Management" rule on
                          TCP 22, Profile=Any (will not be
                          touched by this RDP packet; separate
                          mamawork-ssh-hardening packet narrows
                          it later)
existing local admins:    Administrator (disabled), ahnie (MS,
                          enabled), DadAdmin (local, enabled),
                          jeffr (MS, enabled)
power:                    Mini-PC (always AC). HiberbootEnabled=1
                          (Fast Startup ON; will be effectively
                          unavailable after powercfg /hibernate
                          off). WoL armed on Ethernet 2 (Magic
                          Packet, Pattern Match, Shutdown WoL all
                          Enabled).
BitLocker:                Off (out of scope here).
Secure Boot:              Off (out of scope here).
HomeNetOps PASS:          2026-05-14 hand-back confirms static
                          DHCP reservation + Unbound override for
                          mamawork.home.arpa.
```

## Account Posture

Phase 1 does not create a new Windows account. RDP-from-MacBook
uses an existing approved Windows administrator credential entered
**at connect time** by the human via the Windows App profile
("Credentials: Ask when required"). The two practical choices for
the first RDP test are:

| Login username form | Account | Where the credential lives |
|---|---|---|
| `MAMAWORK\DadAdmin` | Local Windows account `DadAdmin` | Operator memory / 1Password (separate item, system-config does not create or read it) |
| `MAMAWORK\jeffr` or `jeffr@<MS-tenant>` | Microsoft Account `jeffr` | Microsoft Account login flow |

The packet does not assert either choice; the human picks at
connect time. Whichever account is used, it must be a member of
the local `Administrators` group (or `Remote Desktop Users` for a
non-admin RDP session - not in scope here).

The packet does **not** add anyone to `Remote Desktop Users`. The
existing `Administrators` membership is sufficient for RDP.

If a device-specific management account is later wanted (e.g. a
1Password-managed local admin replacement for `DadAdmin`), that is
a separate approval step.

## Elevated Windows PowerShell Script

Run from an Administrator PowerShell session on MAMAWORK. The
script is non-secret: no users created, no passwords set, no
software installed, no 1Password touch, no Cloudflare touch, no
OPNsense touch.

```powershell
# Jefahnierocks MAMAWORK LAN RDP bootstrap
# Run from Administrator PowerShell 7+ on MAMAWORK.

$ErrorActionPreference = 'Stop'

$ExpectedHostname = 'MAMAWORK'
$TrustedLan = '192.168.0.0/24'
$ExpectedWiredMac = 'B0-41-6F-0E-B7-B6'
$EvidenceDir = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidencePath = Join-Path $EvidenceDir "mamawork-rdp-lan-$Timestamp.txt"

New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

function Write-Evidence {
  param([string]$Message)
  $Message | Tee-Object -FilePath $EvidencePath -Append
}

Write-Evidence "timestamp: $(Get-Date -Format o)"
Write-Evidence "scope: MAMAWORK LAN RDP bootstrap, no secrets"
Write-Evidence "hostname: $(hostname)"

if ((hostname) -ne $ExpectedHostname) {
  throw "Unexpected hostname. Expected $ExpectedHostname."
}

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $IsAdmin) {
  throw 'This script must run from Administrator PowerShell.'
}

$Adapter = Get-NetAdapter -Physical |
  Where-Object { $_.MacAddress -eq $ExpectedWiredMac -and $_.Status -eq 'Up' } |
  Select-Object -First 1

if (-not $Adapter) {
  throw "Expected wired adapter $ExpectedWiredMac is not up."
}

$IPv4 = Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 |
  Where-Object { $_.IPAddress -like '192.168.0.*' } |
  Select-Object -First 1

if (-not $IPv4) {
  throw 'Expected 192.168.0.0/24 Ethernet IPv4 address was not found.'
}

Write-Evidence "wired_adapter: $($Adapter.Name) $($Adapter.MacAddress) $($Adapter.LinkSpeed)"
Write-Evidence "wired_ipv4: $($IPv4.IPAddress)/$($IPv4.PrefixLength)"

Write-Evidence ''
Write-Evidence 'pre_state_connection_profile:'
Get-NetConnectionProfile -InterfaceIndex $Adapter.ifIndex |
  Select-Object InterfaceAlias, NetworkCategory, IPv4Connectivity |
  Format-List |
  Out-String |
  Write-Evidence

Write-Evidence 'pre_state_rdp_registry:'
Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' |
  Select-Object fDenyTSConnections |
  Format-List |
  Out-String |
  Write-Evidence
Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' |
  Select-Object UserAuthentication |
  Format-List |
  Out-String |
  Write-Evidence

# Trust only the wired home LAN profile for this phase.
Set-NetConnectionProfile -InterfaceIndex $Adapter.ifIndex -NetworkCategory Private

# Enable RDP with NLA.
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
Set-Service TermService -StartupType Automatic
Start-Service TermService

# Avoid broad built-in Remote Desktop firewall enablement. Use explicit
# Jefahnierocks LAN-only rules instead.
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue |
  Disable-NetFirewallRule
Get-NetFirewallRule -DisplayName 'Jefahnierocks RDP LAN*' -ErrorAction SilentlyContinue |
  Remove-NetFirewallRule

New-NetFirewallRule `
  -DisplayName 'Jefahnierocks RDP LAN TCP 3389' `
  -Direction Inbound `
  -Action Allow `
  -Enabled True `
  -Profile Private `
  -Protocol TCP `
  -LocalPort 3389 `
  -RemoteAddress $TrustedLan `
  -Description 'Allow RDP from trusted home LAN only for Jefahnierocks administration of MAMAWORK.'

New-NetFirewallRule `
  -DisplayName 'Jefahnierocks RDP LAN UDP 3389' `
  -Direction Inbound `
  -Action Allow `
  -Enabled True `
  -Profile Private `
  -Protocol UDP `
  -LocalPort 3389 `
  -RemoteAddress $TrustedLan `
  -Description 'Allow RDP UDP transport from trusted home LAN only for Jefahnierocks administration of MAMAWORK.'

# Power readiness: keep AC remote-admin sessions available and remove Fast
# Startup dependency by disabling hibernate.
powercfg /hibernate off
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setactive SCHEME_CURRENT

# Best-effort NIC wake properties. Intake showed Magic Packet, Pattern
# Match, and Shutdown WoL all Enabled on Ethernet 2; this is idempotent.
$WakeProps = Get-NetAdapterAdvancedProperty -Name $Adapter.Name -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName -match 'Magic Packet|Pattern Match|PME' }

foreach ($Prop in $WakeProps) {
  try {
    Set-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName $Prop.DisplayName -DisplayValue 'Enabled' -NoRestart -ErrorAction Stop
  } catch {
    Write-Evidence "wake_property_not_changed: $($Prop.DisplayName) current=$($Prop.DisplayValue) error=$($_.Exception.Message)"
  }
}

Write-Evidence ''
Write-Evidence 'post_state_connection_profile:'
Get-NetConnectionProfile -InterfaceIndex $Adapter.ifIndex |
  Select-Object InterfaceAlias, NetworkCategory, IPv4Connectivity |
  Format-List |
  Out-String |
  Write-Evidence

Write-Evidence 'post_state_rdp_registry:'
Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' |
  Select-Object fDenyTSConnections |
  Format-List |
  Out-String |
  Write-Evidence
Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' |
  Select-Object UserAuthentication |
  Format-List |
  Out-String |
  Write-Evidence

Write-Evidence 'post_state_firewall_rules:'
Get-NetFirewallRule -DisplayName 'Jefahnierocks RDP LAN*' |
  Get-NetFirewallPortFilter |
  Format-Table -AutoSize |
  Out-String |
  Write-Evidence
Get-NetFirewallRule -DisplayName 'Jefahnierocks RDP LAN*' |
  Get-NetFirewallAddressFilter |
  Format-Table -AutoSize |
  Out-String |
  Write-Evidence

Write-Evidence 'post_state_power:'
powercfg /a | Out-String | Write-Evidence
powercfg /devicequery wake_armed | Out-String | Write-Evidence
Get-NetAdapterAdvancedProperty -Name $Adapter.Name |
  Where-Object { $_.DisplayName -match 'Magic Packet|Pattern Match|PME' } |
  Select-Object DisplayName, DisplayValue |
  Format-Table -AutoSize |
  Out-String |
  Write-Evidence

Write-Evidence 'local_rdp_port_test:'
Test-NetConnection -ComputerName 127.0.0.1 -Port 3389 |
  Select-Object ComputerName, RemotePort, TcpTestSucceeded |
  Format-List |
  Out-String |
  Write-Evidence

Write-Evidence ''
Write-Evidence "status: completed MAMAWORK LAN RDP bootstrap"
Write-Evidence "evidence_file: $EvidencePath"

Write-Host "Completed. Evidence written to $EvidencePath"
Write-Host "Test from MacBook: nc -vz -G 3 $($IPv4.IPAddress) 3389"
Write-Host "Test from MacBook: nc -vz -G 3 mamawork.home.arpa 3389"
```

## MacBook Test After Windows Script

From the MacBook, run **both** liveness checks and capture results:

```bash
nc -vz -G 3 192.168.0.101 3389
nc -vz -G 3 mamawork.home.arpa 3389
```

Both should succeed (LAN reachability is confirmed by the 2026-05-14
HomeNetOps PASS). After both succeed, launch the Windows App profile
configured per
[windows-app-mamawork.md](./windows-app-mamawork.md) and verify
the interactive session.

## Windows App GUI Smoke Test

Use the profile from
[windows-app-mamawork.md](./windows-app-mamawork.md). Expected
outcome:

| Check | Pass criterion |
|---|---|
| Windows App connection from MacBook to MAMAWORK | Succeeded |
| GUI remote management | Worked as expected |
| Public WAN path | Not used |
| Credentials in repo/chat | Not recorded |

After the first successful connection, record a repo-safe summary in
[windows-pc-mamawork.md](./windows-pc-mamawork.md) and create a
small apply record at
`mamawork-lan-rdp-implementation-apply-2026-05-14.md` (mirrors the
DESKTOP-2JJ3187 pattern: ingest the operator's evidence file +
non-secret post-state).

## Rollback

Run from Administrator PowerShell on MAMAWORK if RDP should be
disabled:

```powershell
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 1
Get-NetFirewallRule -DisplayName 'Jefahnierocks RDP LAN*' -ErrorAction SilentlyContinue |
  Remove-NetFirewallRule
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue |
  Disable-NetFirewallRule
```

Rollback does not undo power-readiness changes. Reverting hibernate
or sleep policy should be a separate deliberate action.

## Required Approval Phrase

```text
I approve applying the MAMAWORK LAN RDP implementation packet live
now on MAMAWORK. From an elevated PowerShell 7+ session as
MAMAWORK\<admin>, run the documented script: verify hostname
MAMAWORK and wired MAC B0-41-6F-0E-B7-B6 are present and up, set
the wired adapter's NetworkCategory to Private, set
fDenyTSConnections=0 and UserAuthentication=1, set TermService
Running + Automatic, disable the built-in Remote Desktop firewall
group, create the two custom rules Jefahnierocks RDP LAN TCP 3389
and Jefahnierocks RDP LAN UDP 3389 (Inbound Allow, Private, port
3389, RemoteAddress 192.168.0.0/24), set powercfg /hibernate off
plus AC sleep/hibernate timeouts to 0 and HYBRIDSLEEP=0,
best-effort idempotent enable of NIC Magic Packet / Pattern Match
/ PME, and capture Test-NetConnection 127.0.0.1 3389 + post-state
evidence to
C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-rdp-lan-<timestamp>.txt.
Do NOT touch sshd / sshd_config / authorized_keys / OpenSSH
firewall rules (those are the separate ssh bootstrap packet), do
NOT enable WinRM or PSRemoting, do NOT install VNC or any
third-party remote agent, do NOT change accounts/groups, do NOT
enable BitLocker or Secure Boot, do NOT touch Cloudflare /
Tailscale / WARP / cloudflared / OPNsense / DNS / DHCP / 1Password,
do NOT switch from host-static to DHCP (that's the separate DHCP
source-of-truth packet). Verify from the MacBook with
nc -vz -G 3 192.168.0.101 3389 and nc -vz -G 3 mamawork.home.arpa
3389; both should succeed. Then verify the Windows App GUI
connection using the profile in windows-app-mamawork.md and
record a repo-safe summary in windows-pc-mamawork.md.
```

## Evidence Template (operator hand-back)

```text
timestamp:
operator:
elevation:                yes/no
hostname:                 MAMAWORK
wired adapter MAC:        B0-41-6F-0E-B7-B6
wired IPv4:               192.168.0.101/24
pre-apply NetworkCategory:  <Private | Public | DomainAuthenticated>
post-apply NetworkCategory: Private
pre-apply fDenyTSConnections: <0 | 1>
post-apply fDenyTSConnections: 0
post-apply UserAuthentication: 1
TermService Status/StartType: Running / Automatic
built-in Remote Desktop rules Disabled: yes
"Jefahnierocks RDP LAN TCP 3389":
  Enabled / Action / Profile / RemoteAddress
"Jefahnierocks RDP LAN UDP 3389":
  Enabled / Action / Profile / RemoteAddress
powercfg /hibernate off:  ok
powercfg /a summary:      <hibernate unavailable; standby summary>
NIC wake properties (Magic Packet / Pattern Match / PME): Enabled / Enabled / Enabled
local Test-NetConnection 127.0.0.1:3389: TcpTestSucceeded=True
MacBook nc -vz 192.168.0.101:3389:        Succeeded
MacBook nc -vz mamawork.home.arpa:3389:   Succeeded
Windows App GUI connection:               Succeeded / Failed
credentials in repo/chat/shell argv:      None
remaining blockers:
```

Do NOT paste passwords, saved credentials, RDP credential blobs,
Wi-Fi PSKs, browser data, BitLocker recovery material, or any
secret value into the hand-back.

## Related

- [windows-lan-rdp-implementation-2026-05-13.md](./windows-lan-rdp-implementation-2026-05-13.md) -
  the DESKTOP-2JJ3187 precedent this packet mirrors.
- [windows-app-mamawork.md](./windows-app-mamawork.md) -
  MacBook Windows App profile guidance.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md) -
  the 2026-05-14 HomeNetOps PASS for MAMAWORK static DHCP + Unbound.
- [mamawork-ssh-key-bootstrap-packet-2026-05-14.md](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md) -
  the parallel SSH bootstrap; this RDP packet does NOT touch SSH.
- [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md) -
  separate read-only SSH-investigation packet, unaffected by RDP.
- [mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md) -
  separate optional packet (NOT bundled with RDP work).
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)
