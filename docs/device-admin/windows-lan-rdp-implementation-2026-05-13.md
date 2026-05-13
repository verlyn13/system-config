---
title: Windows LAN RDP Implementation - DESKTOP-2JJ3187
category: operations
component: device_admin
status: applied-lan-gui-verified
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, windows, rdp, firewall, lan, power]
priority: high
---

# Windows LAN RDP Implementation - DESKTOP-2JJ3187

This packet is the approved Windows-first implementation phase for
`DESKTOP-2JJ3187`.

It enables same-LAN GUI administration from the MacBook Windows App while
preserving the hard boundary that no public WAN administrative exposure is
allowed.

## Approval And Scope

Approved by the human operator on 2026-05-13 with "Windows first, lets go."

Approved in this phase:

- Elevated Windows-side RDP enablement with Network Level Authentication.
- Windows Firewall RDP rules scoped to the trusted home LAN only.
- Windows power readiness changes needed for remote administration.
- Same-LAN test from the MacBook Windows App.
- Redacted evidence capture back into `windows-pc.md`.

Not approved in this phase:

- Public WAN exposure of RDP, WinRM, VNC, SSH, or any admin service.
- Cloudflare, WARP, Tunnel, Access, Gateway, or DNS changes.
- OPNsense changes, static DHCP mappings, DNS records, or WoL plugin/API work.
- 1Password secret creation or modification by an agent.
- BitLocker enablement or recovery-key creation.
- OpenSSH Server installation.
- WinRM or PowerShell Remoting enablement.
- Deleting users, changing kid accounts, or modifying Codex sandbox accounts.

## Mac-Side Read-Only Discovery

Observed from the MacBook on 2026-05-13 before the Windows-side implementation:

| Check | Result |
|---|---|
| `DESKTOP-2JJ3187.local` resolution | Resolved to `192.168.0.217` |
| ARP for wired MAC `18:C0:4D:39:7F:49` | `192.168.0.217` |
| ARP for Wi-Fi MAC `CC:D9:AC:1F:92:7B` | `192.168.0.115` and link-local `169.254.182.245` |
| ICMP ping to `DESKTOP-2JJ3187.local` | No reply |
| TCP 3389 to `192.168.0.217` | Timed out |

Interpretation at the time: the MacBook could discover the Windows PC on LAN,
but RDP was not reachable before the Windows-side implementation. That matched
the expected pre-implementation state.

## Apply Result Ingested

Device-side result artifacts were returned and ingested on 2026-05-13:

| Source | Result |
|---|---|
| `/Users/verlyn13/Downloads/apply-rdp-and-power-result-2026-05-12T20-32-22.md` | Elevated apply run log from `DESKTOP-2JJ3187\jeffr`; every directive item was `OK`, `NOOP`, or explicit `SKIP`; zero failures. |
| `/Users/verlyn13/Downloads/rdp-and-power-apply-report-2026-05-12.md` | Post-apply report confirming RDP listener, LAN-scoped firewall, Ethernet `Private`, power/WoL settings, and no WinRM/WAN/Cloudflare/OPNsense changes. |

Repo-safe result summary:

- Apply executed 2026-05-12 20:32 AKST from elevated PowerShell.
- RDP enabled with Network Level Authentication.
- `TermService` is `Running` and `Automatic`.
- RDP is listening on TCP and UDP `3389`.
- Built-in broad Remote Desktop firewall rules remain disabled.
- Custom rules `Jefahnierocks RDP LAN TCP 3389` and
  `Jefahnierocks RDP LAN UDP 3389` are enabled, inbound allow, Private
  profile, scoped to `192.168.0.0/24`.
- Ethernet profile is `Private`.
- Hibernation, hybrid sleep, and Fast Startup are effectively unavailable per
  `powercfg /a`.
- NIC Magic Packet, Pattern Match, and PME are enabled.
- WinRM/PowerShell Remoting, WAN exposure, OPNsense, Cloudflare, OpenSSH, local
  users/groups, UAC, Codex sandbox accounts, and BitLocker were not touched.

Minor finding retained for future review: `HiberbootEnabled = 1` is stale but
cosmetic because hibernation is off and Fast Startup is effectively unavailable.

## MacBook LAN RDP Port Smoke Test

Observed from the MacBook on 2026-05-13 after the Windows-side implementation:

| Check | Result |
|---|---|
| `nc -vz -G 3 192.168.0.217 3389` | Succeeded: TCP `3389` reachable as `ms-wbt-server` |
| `nc -vz -G 3 DESKTOP-2JJ3187.local 3389` | Initially timed out, then succeeded against TCP `3389` |

Interpretation: LAN RDP listener and firewall path are reachable from the
MacBook.

## Windows App GUI Smoke Test

Observed from operator report on 2026-05-12 20:49 AKDT:

| Check | Result |
|---|---|
| Windows App connection from MacBook to Windows PC | Succeeded |
| GUI remote management | Worked as expected |
| Public WAN path | Not used |
| Credentials in repo/chat | Not recorded |

Interpretation: interactive LAN GUI administration is verified. The device is
not fully managed until any approved private off-LAN access path is completed
and verified.

## HomeNetOps Static Naming And WoL Hand-Back

Observed from HomeNetOps hand-back and local repo-session checks on 2026-05-13:

| Check | Result |
|---|---|
| Static DHCP reservation | `18:c0:4d:39:7f:49` -> `192.168.0.217`, type `static` |
| Local DNS | `desktop-2jj3187.home.arpa` -> `192.168.0.217` |
| Local verification | `dig @192.168.0.1 desktop-2jj3187.home.arpa +short` returned `192.168.0.217` |
| RDP by FQDN | `nc -vz desktop-2jj3187.home.arpa 3389` succeeded |
| OPNsense WoL host registration | `os-wol` UUID `93980551-709a-40d3-83e7-a708ee616373` |
| WoL smoke | cold -> wake -> RDP verified under `automation_svc` |

No WAN exposure, public DNS, Cloudflare, or WARP change was made for this pass.
Windows ICMP echo remains blocked by default, so use TCP `3389` liveness checks
instead of `ping`.

## Account Posture

Phase 1 does not require creating a new Windows account. Use an existing
approved administrator credential for the first same-LAN RDP test, retrieved
from 1Password or entered directly by the human.

If a device-specific management account is later required, create it in a
separate approval step with a unique credential stored in 1Password. Do not
place the password in this repo, shell argv, shell history, chat, or a script.

## Elevated Windows PowerShell Script

Run this from an Administrator PowerShell session on `DESKTOP-2JJ3187`.

It is intentionally non-secret. It does not create users, set passwords,
install software, touch 1Password, configure Cloudflare, or change OPNsense.

```powershell
# Jefahnierocks Windows LAN RDP bootstrap for DESKTOP-2JJ3187
# Run from Administrator PowerShell.

$ErrorActionPreference = 'Stop'

$ExpectedHostname = 'DESKTOP-2JJ3187'
$TrustedLan = '192.168.0.0/24'
$ExpectedWiredMac = '18-C0-4D-39-7F-49'
$EvidenceDir = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidencePath = Join-Path $EvidenceDir "desktop-2jj3187-rdp-lan-$Timestamp.txt"

New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

function Write-Evidence {
  param([string]$Message)
  $Message | Tee-Object -FilePath $EvidencePath -Append
}

Write-Evidence "timestamp: $(Get-Date -Format o)"
Write-Evidence "scope: Windows LAN RDP bootstrap, no secrets"
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
  -Description 'Allow RDP from trusted home LAN only for Jefahnierocks administration.'

New-NetFirewallRule `
  -DisplayName 'Jefahnierocks RDP LAN UDP 3389' `
  -Direction Inbound `
  -Action Allow `
  -Enabled True `
  -Profile Private `
  -Protocol UDP `
  -LocalPort 3389 `
  -RemoteAddress $TrustedLan `
  -Description 'Allow RDP UDP transport from trusted home LAN only for Jefahnierocks administration.'

# Power readiness: keep AC remote-admin sessions available and remove Fast
# Startup dependency by disabling hibernate.
powercfg /hibernate off
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setactive SCHEME_CURRENT

# Best-effort NIC wake properties. Property names vary by driver.
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
Write-Evidence "status: completed Windows-side LAN RDP bootstrap"
Write-Evidence "evidence_file: $EvidencePath"

Write-Host "Completed. Evidence written to $EvidencePath"
Write-Host "Test from MacBook: nc -vz -G 3 $($IPv4.IPAddress) 3389"
```

## MacBook Test After Windows Script

From the MacBook:

```bash
nc -vz -G 3 192.168.0.217 3389
```

This has now succeeded from the MacBook, and the Windows App GUI smoke test has
also succeeded using the profile in
[windows-app-desktop-2jj3187.md](./windows-app-desktop-2jj3187.md):

- `PC name`: `desktop-2jj3187.home.arpa`.
- `Credentials`: `Ask when required`.
- `Gateway`: `No gateway`.
- `Connect to an admin session`: unchecked.
- Redirected folders/devices: disabled by default.

After the first successful connection, update `windows-pc.md` with repo-safe
evidence. Do not record credentials.

## Rollback

Run from Administrator PowerShell on the Windows PC if RDP should be disabled:

```powershell
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 1
Get-NetFirewallRule -DisplayName 'Jefahnierocks RDP LAN*' -ErrorAction SilentlyContinue |
  Remove-NetFirewallRule
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue |
  Disable-NetFirewallRule
```

Rollback does not undo power-readiness changes. Reverting hibernate or sleep
policy should be a separate deliberate action.
