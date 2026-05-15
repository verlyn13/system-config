---
title: Windows Terminal Admin Baseline Template
category: operations
component: device_admin
status: template
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, windows, openssh, powershell, baseline, template, read-only]
priority: high
---

# Windows Terminal Admin Baseline Template

This is a packet **template** for Phase 0 intake under
[windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
Device Lifecycle. It is not itself an authorized live action; it is
the skeleton from which each device's `<device>-terminal-admin-baseline`
packet is written.

## Instantiation

Copy this file to:

```text
docs/device-admin/<device>-terminal-admin-baseline-YYYY-MM-DD.md
```

Substitute every `<device>`, `<DEVICE>`, and `<YYYY-MM-DD>` token with
the target device name (lowercase for IDs, uppercase for the Windows
COMPUTERNAME) and the prepare date. The output of an instantiated
packet is its companion `<device>-terminal-admin-baseline-apply-YYYY-MM-DD.md`
plus a backfill of `current-status.yaml.devices[<device>]`.

## Session Class

`read-only-probe`. This template is intentionally inert. It captures
state, writes evidence to a Windows-local path, and returns a
non-secret summary. It does not:

- start, stop, restart, or reconfigure any Windows service;
- add, edit, enable, or disable any firewall rule;
- modify any account, group, password, ACL, or registry key;
- touch `sshd_config`, `administrators_authorized_keys`, per-user
  `authorized_keys`, BitLocker state, Defender exclusions, network
  profile, DNS, DHCP, OPNsense, Cloudflare, or 1Password.

## Approval Phrase

> Run the `<device>-terminal-admin-baseline` packet read-only over
> `ssh <device>`. Capture services, firewall, accounts, OpenSSH
> effective configuration, scheduled tasks by principal, optional
> features, BitLocker / Defender posture, and power/wake state.
> Write evidence to `C:\Users\Public\Documents\jefahnierocks-device-admin\<device>-baseline-<timestamp>\`.
> No live host change.

## Preflight

Before running anything, verify the MacBook SSH client resolves to
the intended target:

```bash
ssh -G <device> | grep -iE '^(user|hostname|identityfile|identityagent|identitiesonly|hostkeyalias)'
```

Expected fields must match the host stanza in the spec's Fleet
Standard table. If they do not match, fall back to the explicit
SSH option set from the spec's SSH Client Rules section and stop
the baseline if `ssh -G` still does not converge.

Identity proof (must run first; abort if not as expected):

```bash
ssh <device> 'cmd /c "hostname && whoami"'
```

Expected output:

```text
<DEVICE>
<DEVICE>\<admin-username>
```

Admin token proof (only required if the baseline includes admin-only
queries; pure inventory queries below do not strictly need admin):

```bash
ssh <device> 'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ProgressPreference = ''SilentlyContinue''; $i=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=New-Object Security.Principal.WindowsPrincipal($i); $i.Name; $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)"'
```

Expected output:

```text
<DEVICE>\<admin-username>
True
```

If `IsInRole` is `False`, stop and surface the elevation gap before
capturing admin-only state. Pure inventory (accounts, services,
listeners, firewall, BitLocker `manage-bde -status`) generally works
without elevation; OpenSSH effective settings (`sshd -T`), full
optional-feature enumeration, and `Get-WindowsCapability -Online`
require admin.

## Stop Rules

Stop and surface to the operator rather than improvising if any of
the following occur:

- `ssh -G` resolves to the wrong user, identity, host, or HostKeyAlias;
- the identity proof returns a different `<DEVICE>` or admin username;
- a command would touch any live state outside the read-only set
  enumerated above;
- `Get-WindowsCapability -Online` or `Get-WindowsOptionalFeature -Online`
  fails with `Class not registered` under pwsh 7 — fall back to
  Windows PowerShell 5.1 for those specific queries (this hit MAMAWORK
  in the 2026-05-13 intake);
- Defender Real-Time Protection blocks the script from running.

## Evidence Layout

Evidence lands in a per-run directory on the Windows host:

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\<device>-baseline-<UTC-yyyymmddThhmmssZ>\
  00-run.txt              # ts, ssh user, OS quick facts
  01-identity.txt         # WindowsIdentity, IsInRole, token level
  02-os.txt               # Get-ComputerInfo subset
  03-accounts.txt         # Get-LocalUser, group memberships, last logon
  04-network.txt          # NIC, IPv4, profile, listeners
  05-firewall.txt         # profiles + named rules
  06-services.txt         # sshd / TermService / WinRM / cloudflared / WARP
  07-openssh.txt          # sshd -T (admin), config file presence, ACLs
  08-scheduled-tasks.txt  # scheduled tasks grouped by Principal.UserId
  09-optional-features.txt # Get-WindowsCapability / Get-WindowsOptionalFeature
  10-power.txt            # powercfg /a, hibernation, wake-armed
  11-security.txt         # BitLocker, Defender, Secure Boot
```

Use the Evidence Writer pattern from the spec — the
`ValueFromPipeline=$true` + `process` form is mandatory because
the call sites pipe `... | Format-List | Out-String | Write-Evidence`.

## Read-Only Probe Script

The shape below is the canonical Phase 0 set. Edit only to remove
queries that are not relevant on a given device (for example,
`nvidia-smi` only on a GPU-equipped host). Do not add queries that
mutate state.

```powershell
# windows-terminal-admin-baseline.ps1
# Run from an elevated SSH session as the documented admin user.

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$ts        = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$EvidenceDir = "C:\Users\Public\Documents\jefahnierocks-device-admin\<device>-baseline-$ts"
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
"timestamp: $ts"                          | Write-Evidence -File '00-run.txt'
"ssh_user: $env:USERNAME"                 | Write-Evidence -File '00-run.txt'
"computer:  $env:COMPUTERNAME"            | Write-Evidence -File '00-run.txt'

# 01-identity.txt
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
"whoami:        $($identity.Name)"                                                    | Write-Evidence -File '01-identity.txt'
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
& 'C:\Windows\System32\OpenSSH\sshd.exe' -T 2>&1 | Out-String | Write-Evidence -File '07-openssh.txt'
foreach ($p in 'C:\ProgramData\ssh\sshd_config','C:\ProgramData\ssh\administrators_authorized_keys') {
  "=== $p ===" | Write-Evidence -File '07-openssh.txt'
  if (Test-Path $p) {
    (Get-Acl $p) | Format-List | Out-String | Write-Evidence -File '07-openssh.txt'
  } else {
    "  (path not present)" | Write-Evidence -File '07-openssh.txt'
  }
}

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
# Use Windows PowerShell 5.1 for this section if pwsh 7 fails with "Class not registered".
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
```

## Return Shape

The apply record `<device>-terminal-admin-baseline-apply-YYYY-MM-DD.md`
should contain a non-secret summary for each evidence file, plus the
following at the top:

```text
device:                  <DEVICE>
applied_at:              <ISO-8601 timestamp>
ssh_user:                <admin-username>
sshd -T sample:          PubkeyAuthentication / PasswordAuthentication /
                         AuthorizedKeysFile / StrictModes / LogLevel
admin_token_high_integrity: <True|False>
network_profile_live:    <Private|Public|Domain>
listeners_22_3389_5985:  <list>
firewall_rules_in_scope: <Jefahnierocks SSH/RDP rule names + Enabled>
scheduled_tasks_by_principal: <count per principal, only principals of interest>
disk_encryption:         <BitLocker on/off, recovery key handling note>
defender:                <RealTime, TamperProtect, signatures date>
hibernation_state:       <available|unavailable>
wake_armed_devices:      <names>
optional_features_pwsh51_rerun_needed: <yes|no>
findings_that_differ:    <bullet list>
followup_packets:        <bullet list of <device>-* packets that this
                         baseline justifies>
```

Do not include raw paths, secrets, BitLocker recovery values, Defender
exclusion contents, account SIDs that imply private identity, Wi-Fi
PSKs, or tunnel credentials. If a finding requires private detail,
record it under a dated operator-controlled path outside the repo,
for example:

```text
~/Library/Logs/device-admin/<YYYY-MM-DD>/
```

## Cross-References

- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) —
  fleet spec, Device Lifecycle, Stop Rules, Evidence Writer pattern.
- [current-status.yaml](./current-status.yaml) — record
  `lifecycle_phase` and `classification` after the apply record is
  committed.
- [handback-format.md](./handback-format.md) — apply record / handback
  conventions.
