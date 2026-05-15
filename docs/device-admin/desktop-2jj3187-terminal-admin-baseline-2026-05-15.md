---
title: DESKTOP-2JJ3187 Terminal Admin Baseline Packet - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, openssh, baseline, read-only, phase-0]
priority: high
---

# DESKTOP-2JJ3187 Terminal Admin Baseline Packet - 2026-05-15

This is the Phase 0 intake packet for `DESKTOP-2JJ3187`, instantiated from
[windows-terminal-admin-baseline-template.md](./windows-terminal-admin-baseline-template.md).
It is read-only-probe and authorizes no live host change.

## Why This Packet Exists

DESKTOP-2JJ3187 is currently classified `rdp-only-host` in
[current-status.yaml](./current-status.yaml). The operator decision on
2026-05-15 is to converge DESKTOP-2JJ3187 with the MAMAWORK SSH model.
Per [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
§Device Lifecycle, the first step on any host changing posture is a
read-only Phase 0 baseline, not a live change.

Output of this baseline drives the subsequent packets:

- [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
  (Phase 3: install Windows OpenSSH Server + admin key + Match block + firewall rule)
- [macbook-ssh-conf-d-desktop-2jj3187-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-2026-05-15.md)
  (MacBook-side: add Host stanza + chezmoi public-key template)

## Known Facts (do not re-establish in the baseline)

| Surface | Current state |
|---|---|
| Hostname / DNS / IP | `DESKTOP-2JJ3187` / `desktop-2jj3187.home.arpa` / `192.168.0.217` |
| OS | Windows 11 Pro 24H2 build 26100 (per 2026-05-12 intake) |
| Admin user | `jeffr` (per source report and `windows-pc.md`) |
| Kid users (standard) | `ahnie`, `axelp`, `ilage`, `wynst` |
| Codex sandbox accounts (preserve) | `CodexSandboxOnline`, `CodexSandboxOffline`, `WsiAccount` |
| Wired NIC MAC | `18:C0:4D:39:7F:49` |
| RDP | Enabled, NLA on, custom `Jefahnierocks RDP LAN TCP/UDP 3389` Private rules scoped to `192.168.0.0/24`. Built-in Remote Desktop rules disabled. |
| BitLocker | Off by operator attestation; not in current target state for this slice. |
| WinRM | Stopped, not configured. |
| OpenSSH Server | Not installed. MacBook TCP/22 probe on 2026-05-15 from `system-config` session: timed out. |
| Static DHCP / Local DNS | HomeNetOps reservation for wired MAC `18:C0:4D:39:7F:49`; FQDN active. |
| WoL | OPNsense `os-wol` UUID `93980551-709a-40d3-83e7-a708ee616373`, cold-to-wake-to-RDP smoke verified. |
| 1Password admin item | `op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13` — **not yet created**; operator-side prerequisite for the install packet. |
| Lifecycle phase | 2 (normalize-network complete; phase 3 install-shell-lane intentionally skipped until now) |

## Approval Phrase

> Run the `desktop-2jj3187-terminal-admin-baseline` packet read-only
> from an elevated PowerShell session on DESKTOP-2JJ3187. Capture
> services, firewall, accounts, OpenSSH state (expected: not
> installed), scheduled tasks by principal, optional features,
> BitLocker (expected: off) / Defender / Secure Boot posture, and
> power/wake state. Write evidence to
> `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-baseline-<timestamp>\`.
> Return a redacted summary to system-config. No live host change.

## Session Class

`read-only-probe`. Inert: no service start/stop/reconfigure, no
firewall rule mutation, no account/group/password/ACL/registry change,
no `sshd_config`, no BitLocker, no Defender exclusions, no network
profile change, no DNS/DHCP/OPNsense/Cloudflare/1Password mutation.

## Preflight (operator side, before running)

This baseline runs **on the Windows host**, not from the MacBook. The
operator is expected to:

1. RDP into DESKTOP-2JJ3187 from the MacBook Windows App profile (PC
   name `desktop-2jj3187.home.arpa`, no saved credentials).
2. Open an elevated PowerShell session as `jeffr`.
3. Verify identity:

```powershell
hostname
whoami
$PSVersionTable.PSVersion
```

Expected:

```text
DESKTOP-2JJ3187
DESKTOP-2JJ3187\jeffr
<PowerShell version>
```

Stop if either of the first two values differ from the expected.

Admin token proof (verify before running admin-only queries):

```powershell
$i = [Security.Principal.WindowsIdentity]::GetCurrent()
$p = New-Object Security.Principal.WindowsPrincipal($i)
"is_admin_role=$($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
whoami /groups | Select-String 'High Mandatory Level','Mandatory Label'
```

Expect `is_admin_role=True` and `Mandatory Label\High Mandatory Level`.
If the token is not elevated, stop and re-open PowerShell as
administrator.

## Stop Rules

Stop and surface to system-config rather than improvising if:

- Identity proof returns a different hostname or admin username.
- A command would touch any live state (service/firewall/account/sshd_config/registry/Defender exclusions).
- `Get-WindowsCapability -Online` or `Get-WindowsOptionalFeature -Online`
  fails with `Class not registered` under pwsh 7 — fall back to
  Windows PowerShell 5.1 for those specific queries.
- Defender Real-Time Protection blocks the script.
- TCP/3389 RDP becomes interrupted (Mama is not on this device, but
  do not displace any active console user).

## Evidence Layout

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-baseline-<UTC-yyyymmddThhmmssZ>\
  00-run.txt
  01-identity.txt
  02-os.txt
  03-accounts.txt
  04-network.txt
  05-firewall.txt
  06-services.txt
  07-openssh.txt
  08-scheduled-tasks.txt
  09-optional-features.txt
  10-power.txt
  11-security.txt
```

## Read-Only Probe Script

```powershell
# DESKTOP-2JJ3187 terminal-admin baseline
# Run from elevated PowerShell as DESKTOP-2JJ3187\jeffr.

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$ts          = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$EvidenceDir = "C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-baseline-$ts"
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

function Write-Evidence {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [AllowEmptyString()]
    [AllowNull()]
    [string]$Message,
    [Parameter(Mandatory = $true)]
    [string]$File
  )
  process {
    Add-Content -LiteralPath (Join-Path $EvidenceDir $File) -Value $Message -Encoding utf8
  }
}

# 00-run.txt — header
"timestamp: $ts"                  | Write-Evidence -File '00-run.txt'
"ssh_user:  $env:USERNAME"        | Write-Evidence -File '00-run.txt'
"computer:  $env:COMPUTERNAME"    | Write-Evidence -File '00-run.txt'
"target:    DESKTOP-2JJ3187"      | Write-Evidence -File '00-run.txt'

# 01-identity.txt
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
"whoami:        $($identity.Name)" | Write-Evidence -File '01-identity.txt'
"is_admin_role: $($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))" | Write-Evidence -File '01-identity.txt'
(whoami /groups) -join "`n" | Out-String | Write-Evidence -File '01-identity.txt'

# 02-os.txt
Get-ComputerInfo -Property OsName,OsDisplayVersion,OsBuildNumber,WindowsVersion,CsName,CsDomain,TimeZone |
  Format-List | Out-String | Write-Evidence -File '02-os.txt'

# 03-accounts.txt
Get-LocalUser | Select-Object Name,Enabled,PrincipalSource,LastLogon |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '03-accounts.txt'
foreach ($g in 'Administrators','Remote Desktop Users','Hyper-V Administrators','docker-users') {
  "=== group: $g ===" | Write-Evidence -File '03-accounts.txt'
  try { Get-LocalGroupMember $g -ErrorAction Stop |
          Select-Object Name,ObjectClass,PrincipalSource |
          Format-Table -AutoSize | Out-String |
          Write-Evidence -File '03-accounts.txt' }
  catch { "  (group not present)" | Write-Evidence -File '03-accounts.txt' }
}

# 04-network.txt
Get-NetAdapter -Physical | Select-Object Name,Status,LinkSpeed,MacAddress |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '04-network.txt'
Get-NetIPConfiguration | Select-Object InterfaceAlias,IPv4Address,IPv6Address,DNSServer |
  Format-List | Out-String | Write-Evidence -File '04-network.txt'
Get-NetConnectionProfile | Format-List | Out-String | Write-Evidence -File '04-network.txt'
Get-NetTCPConnection -State Listen |
  Where-Object LocalPort -in 22,3389,5985,5986,5432,6379 |
  Select-Object LocalAddress,LocalPort,OwningProcess |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '04-network.txt'

# 05-firewall.txt
Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '05-firewall.txt'
Get-NetFirewallRule | Where-Object DisplayName -match 'SSH|RDP|WinRM|Jefahnierocks|Dad Remote' |
  Select-Object DisplayName,Enabled,Direction,Action,Profile,DisplayGroup |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '05-firewall.txt'

# 06-services.txt
Get-Service sshd,ssh-agent,TermService,WinRM,cloudflared,Cloudflared,CloudflareWARP -ErrorAction SilentlyContinue |
  Select-Object Name,Status,StartType |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '06-services.txt'

# 07-openssh.txt
$sshdExe = 'C:\Windows\System32\OpenSSH\sshd.exe'
if (Test-Path $sshdExe) {
  & $sshdExe -T 2>&1 | Out-String | Write-Evidence -File '07-openssh.txt'
} else {
  "sshd.exe not present at $sshdExe — OpenSSH Server not installed." | Write-Evidence -File '07-openssh.txt'
}
foreach ($p in 'C:\ProgramData\ssh\sshd_config','C:\ProgramData\ssh\administrators_authorized_keys') {
  "=== $p ===" | Write-Evidence -File '07-openssh.txt'
  if (Test-Path $p) {
    (Get-Acl $p) | Format-List | Out-String | Write-Evidence -File '07-openssh.txt'
  } else {
    "  (path not present)" | Write-Evidence -File '07-openssh.txt'
  }
}
Get-WindowsCapability -Online -Name 'OpenSSH.*' -ErrorAction SilentlyContinue |
  Select-Object Name,State | Format-Table -AutoSize | Out-String |
  Write-Evidence -File '07-openssh.txt'

# 08-scheduled-tasks.txt
Get-ScheduledTask | ForEach-Object {
  [pscustomobject]@{
    TaskPath  = $_.TaskPath
    TaskName  = $_.TaskName
    State     = $_.State
    Principal = $_.Principal.UserId
  }
} | Sort-Object Principal,TaskPath,TaskName |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '08-scheduled-tasks.txt'

# 09-optional-features.txt
try {
  Get-WindowsCapability -Online -ErrorAction Stop |
    Where-Object State -eq 'Installed' |
    Select-Object Name | Format-Table -AutoSize | Out-String |
    Write-Evidence -File '09-optional-features.txt'
} catch {
  "Get-WindowsCapability failed: $_" | Write-Evidence -File '09-optional-features.txt'
}
try {
  Get-WindowsOptionalFeature -Online -ErrorAction Stop |
    Where-Object State -eq 'Enabled' |
    Select-Object FeatureName | Format-Table -AutoSize | Out-String |
    Write-Evidence -File '09-optional-features.txt'
} catch {
  "Get-WindowsOptionalFeature failed: $_" | Write-Evidence -File '09-optional-features.txt'
}

# 10-power.txt
powercfg /a 2>&1 | Out-String | Write-Evidence -File '10-power.txt'
powercfg /devicequery wake_armed 2>&1 | Out-String | Write-Evidence -File '10-power.txt'
(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction SilentlyContinue) |
  Select-Object HiberbootEnabled | Format-List | Out-String |
  Write-Evidence -File '10-power.txt'

# 11-security.txt
manage-bde -status C: 2>&1 | Out-String | Write-Evidence -File '11-security.txt'
Get-MpComputerStatus -ErrorAction SilentlyContinue |
  Select-Object AMServiceEnabled,RealTimeProtectionEnabled,IsTamperProtected,AntivirusSignatureLastUpdated |
  Format-List | Out-String | Write-Evidence -File '11-security.txt'
$secureBoot = try { Confirm-SecureBootUEFI } catch { "unavailable: $_" }
"SecureBootUEFI: $secureBoot" | Write-Evidence -File '11-security.txt'

"done. evidence at $EvidenceDir" | Write-Evidence -File '00-run.txt'
Write-Host "done. evidence at $EvidenceDir"
```

## Expected Findings (to reconcile against)

The baseline should confirm:

- Hostname `DESKTOP-2JJ3187`; admin user `jeffr` in `Administrators`.
- Standard users include `ahnie`, `axelp`, `ilage`, `wynst`.
- `CodexSandboxOnline`, `CodexSandboxOffline`, `WsiAccount` are present
  and should remain untouched.
- `Get-Service sshd` returns Status=Stopped / StartType=Disabled OR the
  service is absent. `sshd.exe` at
  `C:\Windows\System32\OpenSSH\sshd.exe` may or may not be present;
  the OpenSSH.Server Windows capability may be `NotPresent`.
- `Get-Service WinRM` Status=Stopped, StartType=Manual.
- `Get-Service TermService` Status=Running, StartType=Automatic.
- `Get-NetTCPConnection -State Listen` should show 3389 listeners; 22
  absent.
- `Get-NetConnectionProfile` shows Private profile on the LAN
  interface (assumes 2026-05-12 RDP apply set this).
- Firewall: `Jefahnierocks RDP LAN TCP 3389` + `UDP 3389` Enabled,
  Private, RemoteAddress `192.168.0.0/24`. No `Jefahnierocks SSH LAN
  TCP 22` rule yet.
- BitLocker off on C:.
- Defender Real-Time Protection enabled.
- Secure Boot status: capture truth.

If any of these expected facts differ, surface to system-config before
the install packet is drafted further.

## Return Shape

The apply record
(`desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md`) should
contain:

```text
device:                       DESKTOP-2JJ3187
applied_at:                   <ISO-8601>
ssh_user:                     DESKTOP-2JJ3187\jeffr
admin_token_high_integrity:   <True|False>
openssh_server_state:         <not-installed | installed-stopped | installed-running>
sshd_config_present:          <True|False>
administrators_authorized_keys_present: <True|False>
network_profile_live:         <Private|Public|Domain>
listeners_22_3389:            <list>
firewall_rules_in_scope:      <Jefahnierocks rule names + Enabled>
scheduled_tasks_by_principal: <count per principal of interest>
disk_encryption:              <off as attested | other>
defender:                     <RealTime, TamperProtect, signatures date>
hibernation_state:            <available|unavailable>
wake_armed_devices:           <names>
optional_features_pwsh51_rerun_needed: <yes|no>
findings_that_differ:         <bullet list>
followup_packets:             desktop-2jj3187-ssh-lane-install-2026-05-15,
                              macbook-ssh-conf-d-desktop-2jj3187-2026-05-15
```

No secrets, BitLocker recovery values, Defender exclusion contents, Wi-Fi
PSKs, account SIDs implying private identity, or RDP credentials in the
evidence summary. Private detail goes to a dated operator-controlled
path outside the repo.

## Boundaries

This baseline does **not** authorize:

- Installing OpenSSH Server.
- Editing `sshd_config` or `administrators_authorized_keys`.
- Adding firewall rules.
- Changing account, group, password, ACL, or registry state.
- Enabling/disabling BitLocker, WinRM, Defender exclusions.
- Modifying `CodexSandboxOnline`, `CodexSandboxOffline`, `WsiAccount`.
- Mutating Cloudflare, WARP, DNS, DHCP, OPNsense, or 1Password state.

Those changes belong to subsequent approval-gated packets.
