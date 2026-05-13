---
title: Device Agent Handoff - Windows LAN PC Intake
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, handoff, windows, lan, inventory, rdp, ssh]
priority: high
---

# Device Agent Handoff - Windows LAN PC Intake

Use this document for the additional Windows PC that Jefahnierocks wants to
bring under LAN administration.

This is not the existing `DESKTOP-2JJ3187` record. Do not reuse
`DESKTOP-2JJ3187`, `192.168.0.217`, `desktop-2jj3187.home.arpa`, or its wired
MAC address as facts for this machine. This handoff exists because the new
Windows PC identity is still pending.

## Mission

Run a comprehensive, non-secret discovery pass on the Windows PC and return a
repo-safe readiness report to the `system-config` operator.

The goal is to learn enough to decide the next safe LAN administration step:

- device identity, ownership, hostname, and OS build;
- local users, administrators, and remote-access groups;
- wired and wireless MAC addresses, current LAN IPs, and active network
  profile;
- current RDP, OpenSSH, WinRM, firewall, power, wake, disk encryption, update,
  Defender, GPU, Docker/WSL, backup, and remote-agent posture;
- what is verified live, what is planned, and what requires human approval.

Do not implement remote access in this pass. Inventory first.

## Authority

Follow these authority rules:

- Treat this handoff as the active directive for the local Windows agent.
- Jefahnierocks owns administration of this device.
- `system-config` owns this device-admin record set.
- HomeNetOps owns OPNsense, static DHCP, local DNS, Wake-on-LAN registration,
  router policy, and LAN firewall surfaces.
- `cloudflare-dns` owns Cloudflare Zero Trust, WARP, Access, Gateway, DNS, and
  tunnel semantics.
- Existing local plans, screenshots, or agent suggestions on the Windows PC
  are evidence only. They do not define the administration model.

The likely target is the same pattern used for the first Windows PC: trusted
LAN first, no public WAN admin exposure, then later private overlay or
Cloudflare-controlled access if explicitly approved.

## Hard Stops

Stop and ask before doing any of these:

- Enabling RDP, OpenSSH Server, WinRM, PowerShell Remoting, VNC, Chrome Remote
  Desktop, RustDesk, AnyDesk, TeamViewer, Parsec, Sunshine, or any other
  remote-admin service.
- Changing Windows Firewall rules or network profile category.
- Creating, deleting, disabling, or changing users, groups, passwords, UAC, or
  local security policy.
- Installing, uninstalling, enrolling, or configuring WARP, `cloudflared`,
  Tailscale, remote-management agents, OpenSSH, or VPN software.
- Changing OPNsense, DHCP, DNS, static IP, WoL, Cloudflare, Access, Gateway,
  WARP, Tunnel, or public DNS state.
- Creating, editing, reading broadly, or reorganizing 1Password items.
- Printing passwords, private keys, recovery keys, bearer credentials, OAuth
  credentials, tunnel credential JSON, session cookies, browser data, shell
  history, or saved RDP credentials.
- Exporting Defender secrets, browser secrets, Wi-Fi PSKs, credential-manager
  contents, DPAPI material, SSH private keys, or BitLocker recovery material.
- Rebooting, shutting down, hibernating, sleeping, or waking the PC remotely.
- Claiming the device is fully managed.

Allowed change in this intake pass:

- Create a local evidence folder and write non-secret inventory outputs under
  `C:\Users\Public\Documents\jefahnierocks-device-admin\`.

## Operator Setup

Prefer an Administrator PowerShell session with the human present. More fields
are visible from an elevated shell, but the collection is still read-only.

If Administrator PowerShell is not available:

- run the same collection from normal PowerShell;
- record that elevation was unavailable;
- do not try to bypass elevation.

Do not paste secrets into the shell. Do not run commands from browser history,
PowerShell history, or older local notes.

## Step 1 - Human-Readable Identity Check

Run these quick checks first and report the answers:

```powershell
hostname
whoami
Get-ComputerInfo | Select-Object CsName, OsName, OsDisplayVersion, OsBuildNumber, WindowsVersion, CsDomain, CsWorkgroup, TimeZone
Get-NetAdapter -Physical | Select-Object Name, Status, LinkSpeed, MacAddress, InterfaceDescription
Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv6Address, DNSServer
Get-NetConnectionProfile | Select-Object InterfaceAlias, NetworkCategory, IPv4Connectivity, NetworkName
```

Return:

- current hostname;
- current signed-in user;
- Windows edition, display version, and build;
- active wired and Wi-Fi interface names;
- all physical MAC addresses;
- current IPv4 LAN address;
- active network category, such as `Private` or `Public`;
- whether the session is elevated.

## Step 2 - Run The Comprehensive Inventory Script

Save the following script as:

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\windows-lan-intake.ps1
```

Then run it from PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
& 'C:\Users\Public\Documents\jefahnierocks-device-admin\windows-lan-intake.ps1'
```

The script is read-only except for writing its output folder.

```powershell
# Jefahnierocks Windows LAN PC intake.
# Purpose: collect non-secret readiness evidence for LAN administration.
# Scope: read-only system inventory plus local output files.

$ErrorActionPreference = 'Continue'

$Root = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$OutDir = Join-Path $Root "windows-lan-intake-$Timestamp"
$SummaryPath = Join-Path $OutDir 'SUMMARY.md'

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function Test-IsAdmin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal] $identity
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Save-Text {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Script
  )

  $Path = Join-Path $OutDir "$Name.txt"
  "### $Name" | Out-File -FilePath $Path -Encoding utf8
  "timestamp: $(Get-Date -Format o)" | Out-File -FilePath $Path -Encoding utf8 -Append
  "" | Out-File -FilePath $Path -Encoding utf8 -Append

  try {
    & $Script 2>&1 |
      Out-String -Width 260 |
      Out-File -FilePath $Path -Encoding utf8 -Append
  } catch {
    "ERROR: $($_.Exception.Message)" |
      Out-File -FilePath $Path -Encoding utf8 -Append
  }
}

function Save-Json {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Script
  )

  $Path = Join-Path $OutDir "$Name.json"
  try {
    & $Script |
      ConvertTo-Json -Depth 6 |
      Out-File -FilePath $Path -Encoding utf8
  } catch {
    [pscustomobject]@{ error = $_.Exception.Message } |
      ConvertTo-Json |
      Out-File -FilePath $Path -Encoding utf8
  }
}

function Convert-SerialRedacted {
  param([string]$Serial)
  if ([string]::IsNullOrWhiteSpace($Serial)) {
    return '<empty>'
  }
  $trimmed = $Serial.Trim()
  $last4 = if ($trimmed.Length -gt 4) { $trimmed.Substring($trimmed.Length - 4) } else { $trimmed }
  return "<redacted-last4:$last4>"
}

$IsAdmin = Test-IsAdmin
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$Bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
$ComputerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$Tpm = $null
try { $Tpm = Get-Tpm -ErrorAction Stop } catch { $Tpm = $null }
$SecureBoot = $null
try { $SecureBoot = Confirm-SecureBootUEFI -ErrorAction Stop } catch { $SecureBoot = "unavailable: $($_.Exception.Message)" }

@"
# Windows LAN PC Intake Summary

timestamp: $(Get-Date -Format o)
hostname: $(hostname)
current_identity: $CurrentIdentity
elevated: $IsAdmin
output_directory: $OutDir

scope: read-only inventory for Jefahnierocks LAN administration
secret_policy: no passwords, recovery keys, private keys, bearer credentials, saved credentials, browser data, shell history, Wi-Fi PSKs, or tunnel credential JSON intentionally collected

return_to_system_config: summarize repo-safe facts only; do not commit this raw folder without review
"@ | Out-File -FilePath $SummaryPath -Encoding utf8

Save-Json '00-admin-and-machine-summary' {
  $ComputerInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
  [pscustomobject]@{
    timestamp = Get-Date -Format o
    hostname = hostname
    currentIdentity = $CurrentIdentity
    elevated = $IsAdmin
    computer = [pscustomobject]@{
      name = $ComputerInfo.CsName
      dnsHostName = $ComputerInfo.CsDNSHostName
      domain = $ComputerInfo.CsDomain
      workgroup = $ComputerInfo.CsWorkgroup
      manufacturer = $ComputerInfo.CsManufacturer
      model = $ComputerInfo.CsModel
      biosFirmwareType = $ComputerInfo.BiosFirmwareType
      processor = $ComputerInfo.CsProcessors.Name -join '; '
      logicalProcessors = $ComputerInfo.CsNumberOfLogicalProcessors
      totalPhysicalMemoryBytes = $ComputerInfo.CsTotalPhysicalMemory
    }
    os = [pscustomobject]@{
      name = $ComputerInfo.OsName
      displayVersion = $ComputerInfo.OsDisplayVersion
      version = $ComputerInfo.OsVersion
      buildNumber = $ComputerInfo.OsBuildNumber
      windowsVersion = $ComputerInfo.WindowsVersion
      productName = $ComputerInfo.WindowsProductName
      architecture = $ComputerInfo.OsArchitecture
      installDate = $ComputerInfo.OsInstallDate
      lastBoot = $ComputerInfo.OsLastBootUpTime
      timeZone = $ComputerInfo.TimeZone
    }
    bios = [pscustomobject]@{
      manufacturer = $Bios.Manufacturer
      smbiosVersion = $Bios.SMBIOSBIOSVersion
      releaseDate = $Bios.ReleaseDate
      serialNumber = Convert-SerialRedacted $Bios.SerialNumber
    }
    tpm = $Tpm
    secureBoot = $SecureBoot
  }
}

Save-Text '01-identity-os' {
  hostname
  whoami
  whoami /user
  whoami /groups
  Get-ComputerInfo |
    Select-Object CsName, CsDNSHostName, CsDomain, CsWorkgroup, OsName, OsDisplayVersion,
      OsVersion, OsBuildNumber, WindowsVersion, WindowsProductName, OsArchitecture,
      TimeZone, OsInstallDate, OsLastBootUpTime, CsManufacturer, CsModel,
      BiosFirmwareType, CsProcessors, CsNumberOfLogicalProcessors, CsTotalPhysicalMemory |
    Format-List
}

Save-Text '02-firmware-tpm-secureboot-bitlocker' {
  $redactedBios = [pscustomobject]@{
    Manufacturer = $Bios.Manufacturer
    SMBIOSBIOSVersion = $Bios.SMBIOSBIOSVersion
    ReleaseDate = $Bios.ReleaseDate
    SerialNumber = Convert-SerialRedacted $Bios.SerialNumber
  }
  $redactedBios | Format-List
  ""
  "TPM:"
  try { Get-Tpm | Format-List } catch { "Get-Tpm unavailable: $($_.Exception.Message)" }
  ""
  "Secure Boot:"
  $SecureBoot
  ""
  "BitLocker status:"
  try {
    Get-BitLockerVolume |
      Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionPercentage,
        EncryptionMethod, LockStatus |
      Format-Table -AutoSize
  } catch {
    "Get-BitLockerVolume unavailable: $($_.Exception.Message)"
  }
  ""
  "manage-bde status:"
  try { manage-bde -status } catch { "manage-bde unavailable: $($_.Exception.Message)" }
}

Save-Text '03-local-users-groups' {
  "Local users:"
  Get-LocalUser |
    Select-Object Name, Enabled, PrincipalSource, LastLogon, PasswordRequired, PasswordChangeable |
    Sort-Object Name |
    Format-Table -AutoSize
  ""
  "Local groups:"
  Get-LocalGroup |
    Select-Object Name, PrincipalSource, Description |
    Sort-Object Name |
    Format-Table -AutoSize
  ""
  "Administrators:"
  Get-LocalGroupMember Administrators -ErrorAction SilentlyContinue |
    Select-Object Name, ObjectClass, PrincipalSource |
    Format-Table -AutoSize
  ""
  "Remote Desktop Users:"
  Get-LocalGroupMember 'Remote Desktop Users' -ErrorAction SilentlyContinue |
    Select-Object Name, ObjectClass, PrincipalSource |
    Format-Table -AutoSize
  ""
  "docker-users:"
  Get-LocalGroupMember 'docker-users' -ErrorAction SilentlyContinue |
    Select-Object Name, ObjectClass, PrincipalSource |
    Format-Table -AutoSize
  ""
  "Hyper-V Administrators:"
  Get-LocalGroupMember 'Hyper-V Administrators' -ErrorAction SilentlyContinue |
    Select-Object Name, ObjectClass, PrincipalSource |
    Format-Table -AutoSize
}

Save-Text '04-network-identity' {
  "Physical adapters:"
  Get-NetAdapter -Physical |
    Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress, ifIndex |
    Sort-Object Name |
    Format-Table -AutoSize
  ""
  "IP configuration:"
  Get-NetIPConfiguration |
    Select-Object InterfaceAlias, InterfaceIndex, IPv4Address, IPv6Address, IPv4DefaultGateway, DNSServer |
    Format-List
  ""
  "IP addresses:"
  Get-NetIPAddress |
    Select-Object InterfaceAlias, AddressFamily, IPAddress, PrefixLength, Type, AddressState |
    Sort-Object InterfaceAlias, AddressFamily, IPAddress |
    Format-Table -AutoSize
  ""
  "Routes:"
  Get-NetRoute |
    Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' -or $_.DestinationPrefix -eq '::/0' -or $_.DestinationPrefix -like '192.168.*' } |
    Select-Object InterfaceAlias, DestinationPrefix, NextHop, RouteMetric, ifMetric |
    Sort-Object DestinationPrefix, InterfaceAlias |
    Format-Table -AutoSize
  ""
  "DNS servers:"
  Get-DnsClientServerAddress |
    Select-Object InterfaceAlias, AddressFamily, ServerAddresses |
    Format-Table -AutoSize
  ""
  "Network profiles:"
  Get-NetConnectionProfile |
    Select-Object InterfaceAlias, InterfaceIndex, NetworkCategory, IPv4Connectivity, IPv6Connectivity, NetworkName |
    Format-Table -AutoSize
}

Save-Text '05-listeners-and-processes' {
  "TCP listeners:"
  Get-NetTCPConnection -State Listen |
    Sort-Object LocalPort, LocalAddress |
    Select-Object LocalAddress, LocalPort, OwningProcess,
      @{Name='ProcessName';Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} |
    Format-Table -AutoSize
  ""
  "UDP endpoints:"
  Get-NetUDPEndpoint |
    Sort-Object LocalPort, LocalAddress |
    Select-Object LocalAddress, LocalPort, OwningProcess,
      @{Name='ProcessName';Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} |
    Format-Table -AutoSize
  ""
  "High-value process inventory:"
  Get-Process |
    Where-Object {
      $_.ProcessName -match 'ssh|rdp|term|winrm|cloudflare|warp|tailscale|docker|wsl|vmcompute|teamviewer|anydesk|rustdesk|vnc|parsec|sunshine|moonlight|chrome'
    } |
    Select-Object ProcessName, Id, Path |
    Sort-Object ProcessName |
    Format-Table -AutoSize
}

Save-Text '06-firewall-and-remote-access' {
  "Firewall profiles:"
  Get-NetFirewallProfile |
    Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction, NotifyOnListen, AllowInboundRules, AllowLocalFirewallRules |
    Format-Table -AutoSize
  ""
  "Remote Desktop registry:"
  try {
    Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' |
      Select-Object fDenyTSConnections |
      Format-List
    Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' |
      Select-Object UserAuthentication, SecurityLayer, MinEncryptionLevel |
      Format-List
  } catch {
    "RDP registry read failed: $($_.Exception.Message)"
  }
  ""
  "Remote Desktop firewall group:"
  Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue |
    Get-NetFirewallPortFilter |
    Select-Object InstanceID, Protocol, LocalPort, RemotePort |
    Format-Table -AutoSize
  Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue |
    Select-Object DisplayName, Enabled, Direction, Action, Profile |
    Format-Table -AutoSize
  ""
  "Remote admin related firewall rules:"
  Get-NetFirewallRule |
    Where-Object {
      $_.DisplayName -match 'Jefahnierocks|Remote Desktop|OpenSSH|WinRM|Windows Remote Management|Cloudflare|WARP|Tailscale|VNC|RustDesk|AnyDesk|TeamViewer|Parsec|Sunshine|Moonlight'
    } |
    Select-Object DisplayName, Enabled, Direction, Action, Profile |
    Sort-Object DisplayName |
    Format-Table -AutoSize
  ""
  "WinRM listeners:"
  try { winrm enumerate winrm/config/listener } catch { "WinRM listener read failed: $($_.Exception.Message)" }
}

Save-Text '07-services-remote-agents' {
  Get-Service |
    Where-Object {
      $_.Name -match 'ssh|TermService|WinRM|cloudflare|warp|tailscale|teamviewer|anydesk|rustdesk|vnc|parsec|sunshine|moonlight|docker|vmcompute|hyper-v' -or
      $_.DisplayName -match 'ssh|Remote Desktop|Windows Remote Management|Cloudflare|WARP|Tailscale|TeamViewer|AnyDesk|RustDesk|VNC|Parsec|Sunshine|Moonlight|Docker|Hyper-V'
    } |
    Select-Object Name, DisplayName, Status, StartType |
    Sort-Object Name |
    Format-Table -AutoSize
  ""
  "OpenSSH Windows capabilities:"
  try {
    Get-WindowsCapability -Online |
      Where-Object Name -like 'OpenSSH*' |
      Select-Object Name, State |
      Format-Table -AutoSize
  } catch {
    "Get-WindowsCapability failed: $($_.Exception.Message)"
  }
}

Save-Text '08-cloudflare-tailscale-vpn' {
  "Binaries:"
  Get-Command cloudflared, warp-cli, tailscale, ssh, scp -ErrorAction SilentlyContinue |
    Select-Object Name, Source, Version |
    Format-Table -AutoSize
  ""
  "Version/status checks:"
  if (Get-Command cloudflared -ErrorAction SilentlyContinue) { cloudflared --version }
  if (Get-Command warp-cli -ErrorAction SilentlyContinue) { warp-cli status }
  if (Get-Command tailscale -ErrorAction SilentlyContinue) { tailscale status }
  ""
  "Cloudflare/Tailscale related services:"
  Get-Service |
    Where-Object { $_.Name -match 'cloudflare|warp|tailscale' -or $_.DisplayName -match 'Cloudflare|WARP|Tailscale' } |
    Select-Object Name, DisplayName, Status, StartType |
    Format-Table -AutoSize
}

Save-Text '09-defender-update-security' {
  "Defender computer status:"
  try {
    Get-MpComputerStatus |
      Select-Object AMServiceEnabled, AntispywareEnabled, AntivirusEnabled, BehaviorMonitorEnabled,
        IoavProtectionEnabled, NISEnabled, OnAccessProtectionEnabled, RealTimeProtectionEnabled,
        AntivirusSignatureLastUpdated, AntispywareSignatureLastUpdated, FullScanAge, QuickScanAge |
      Format-List
  } catch {
    "Get-MpComputerStatus unavailable: $($_.Exception.Message)"
  }
  ""
  "Defender preference summary without exclusion values:"
  try {
    $pref = Get-MpPreference
    [pscustomobject]@{
      DisableRealtimeMonitoring = $pref.DisableRealtimeMonitoring
      DisableBehaviorMonitoring = $pref.DisableBehaviorMonitoring
      DisableIOAVProtection = $pref.DisableIOAVProtection
      DisableScriptScanning = $pref.DisableScriptScanning
      ExclusionPathCount = @($pref.ExclusionPath).Count
      ExclusionProcessCount = @($pref.ExclusionProcess).Count
      ExclusionExtensionCount = @($pref.ExclusionExtension).Count
      AttackSurfaceReductionRuleCount = @($pref.AttackSurfaceReductionRules_Ids).Count
    } | Format-List
  } catch {
    "Get-MpPreference unavailable: $($_.Exception.Message)"
  }
  ""
  "Recent hotfixes:"
  Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object -First 30 HotFixID, Description, InstalledOn, InstalledBy |
    Format-Table -AutoSize
}

Save-Text '10-power-wake' {
  "Available sleep states:"
  powercfg /a
  ""
  "Wake armed devices:"
  powercfg /devicequery wake_armed
  ""
  "Last wake:"
  powercfg /lastwake
  ""
  "Wake timers:"
  powercfg /waketimers
  ""
  "Power requests:"
  powercfg /requests
  ""
  "Fast Startup registry flag:"
  try {
    Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' |
      Select-Object HiberbootEnabled |
      Format-List
  } catch {
    "HiberbootEnabled read failed: $($_.Exception.Message)"
  }
  ""
  "Adapter power management:"
  Get-NetAdapter -Physical |
    ForEach-Object {
      $adapter = $_
      "Adapter: $($adapter.Name) $($adapter.MacAddress)"
      try {
        Get-NetAdapterPowerManagement -Name $adapter.Name |
          Format-List
      } catch {
        "Get-NetAdapterPowerManagement failed: $($_.Exception.Message)"
      }
      try {
        Get-NetAdapterAdvancedProperty -Name $adapter.Name |
          Where-Object DisplayName -match 'Wake|PME|Magic|Pattern|Energy|EEE|Green' |
          Select-Object DisplayName, DisplayValue |
          Format-Table -AutoSize
      } catch {
        "Get-NetAdapterAdvancedProperty failed: $($_.Exception.Message)"
      }
    }
}

Save-Text '11-storage-backup' {
  "Volumes:"
  Get-Volume |
    Select-Object DriveLetter, FileSystemLabel, FileSystem, DriveType, HealthStatus, OperationalStatus, SizeRemaining, Size |
    Sort-Object DriveLetter |
    Format-Table -AutoSize
  ""
  "Disks:"
  Get-Disk |
    Select-Object Number, FriendlyName, BusType, PartitionStyle, HealthStatus, OperationalStatus, Size |
    Sort-Object Number |
    Format-Table -AutoSize
  ""
  "Physical disks:"
  Get-PhysicalDisk -ErrorAction SilentlyContinue |
    Select-Object FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus, Size |
    Format-Table -AutoSize
  ""
  "File History:"
  try { Get-FileHistoryConfiguration | Format-List } catch { "Get-FileHistoryConfiguration unavailable: $($_.Exception.Message)" }
  ""
  "Windows Backup versions:"
  try { wbadmin get versions } catch { "wbadmin get versions unavailable or not configured: $($_.Exception.Message)" }
}

Save-Text '12-gpu-compute-virtualization' {
  "Video controllers:"
  Get-CimInstance Win32_VideoController |
    Select-Object Name, DriverVersion, AdapterRAM, VideoProcessor |
    Format-Table -AutoSize
  ""
  "nvidia-smi:"
  if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    nvidia-smi --query-gpu=name,driver_version,memory.total,temperature.gpu,power.draw --format=csv
  } else {
    "nvidia-smi not found"
  }
  ""
  "Windows optional features:"
  try {
    Get-WindowsOptionalFeature -Online |
      Where-Object FeatureName -match 'Microsoft-Windows-Subsystem-Linux|VirtualMachinePlatform|Containers|Hyper-V|OpenSSH' |
      Select-Object FeatureName, State |
      Format-Table -AutoSize
  } catch {
    "Get-WindowsOptionalFeature failed: $($_.Exception.Message)"
  }
  ""
  "WSL:"
  try { wsl --status } catch { "wsl --status unavailable: $($_.Exception.Message)" }
  try { wsl --list --verbose } catch { "wsl --list unavailable: $($_.Exception.Message)" }
  ""
  "Docker safe summary:"
  if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker version --format '{{json .}}'
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'
  } else {
    "docker not found"
  }
}

Save-Text '13-installed-apps' {
  $roots = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
  )
  foreach ($root in $roots) {
    Get-ItemProperty $root -ErrorAction SilentlyContinue |
      Where-Object DisplayName |
      Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
      Sort-Object DisplayName
  }
}

Save-Text '14-scheduled-tasks-startup-shares' {
  "Non-Microsoft scheduled tasks, names only:"
  Get-ScheduledTask |
    Where-Object { $_.TaskPath -notlike '\Microsoft\*' } |
    Select-Object TaskPath, TaskName, State, Author |
    Sort-Object TaskPath, TaskName |
    Format-Table -AutoSize
  ""
  "Remote/admin related scheduled tasks, names only:"
  Get-ScheduledTask |
    Where-Object {
      $_.TaskName -match 'cloudflare|warp|tailscale|ssh|rdp|remote|backup|docker|wsl|teamviewer|anydesk|rustdesk|vnc|parsec|sunshine|moonlight' -or
      $_.TaskPath -match 'cloudflare|warp|tailscale|ssh|rdp|remote|backup|docker|wsl|teamviewer|anydesk|rustdesk|vnc|parsec|sunshine|moonlight'
    } |
    Select-Object TaskPath, TaskName, State, Author |
    Sort-Object TaskPath, TaskName |
    Format-Table -AutoSize
  ""
  "Startup commands, command line intentionally omitted:"
  Get-CimInstance Win32_StartupCommand |
    Select-Object Name, Location, User |
    Sort-Object Name |
    Format-Table -AutoSize
  ""
  "SMB shares:"
  try {
    Get-SmbShare |
      Select-Object Name, Path, Description, CurrentUsers, ScopeName, Special |
      Format-Table -AutoSize
  } catch {
    "Get-SmbShare unavailable: $($_.Exception.Message)"
  }
}

Save-Text '15-recent-system-events' {
  "Recent power and service events:"
  $filter = @{
    LogName = 'System'
    ProviderName = @('Microsoft-Windows-Kernel-Power', 'Microsoft-Windows-Power-Troubleshooter', 'Service Control Manager', 'User32')
    StartTime = (Get-Date).AddDays(-14)
  }
  try {
    Get-WinEvent -FilterHashtable $filter -MaxEvents 80 |
      Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message |
      Format-List
  } catch {
    "Get-WinEvent failed: $($_.Exception.Message)"
  }
}

Save-Text '16-environment-names-only' {
  "Environment variable names only. Values intentionally omitted."
  Get-ChildItem Env: |
    Select-Object Name |
    Sort-Object Name |
    Format-Table -AutoSize
}

@"

## Collection Complete

completed_at: $(Get-Date -Format o)

Output folder:
$OutDir

Before returning anything to `system-config`, review for accidental sensitive
data. Do not copy browser data, saved credentials, private keys, recovery
material, shell history, credential-manager contents, or tunnel credential JSON.
"@ | Out-File -FilePath $SummaryPath -Encoding utf8 -Append

Write-Host "Jefahnierocks Windows LAN intake complete."
Write-Host "Output folder: $OutDir"
Write-Host "Review outputs before sharing. Return repo-safe summaries only."
```

## Step 3 - Manual Checks The Script Cannot Prove Well

Ask the human or local operator to answer these:

- Who is the intended owner/user set for this PC?
- Is this a shared family PC, a personal workstation, gaming PC, lab machine,
  or server-like host?
- What physical room/location or administrative context should be recorded?
- Should the PC remain awake for remote administration?
- Is Ethernet available and preferred, or is Wi-Fi the expected stable path?
- Is the machine expected to wake from shutdown, sleep, or both?
- Is BitLocker intentionally off, intentionally on, or undecided?
- Is Windows Hello/PIN in use for human sign-in?
- Are any Microsoft accounts used for primary login?
- Is there an existing local admin credential that should be replaced by a
  unique device-specific credential stored in 1Password later?
- Does the PC have any workload that must not be interrupted?
- Is there any backup or restore path already in place?

Do not ask the human to reveal passwords, recovery keys, PINs, or private
credential material.

## Step 4 - Return Report To Jefahnierocks

Return a concise report with this shape:

```text
Device:
Timestamp:
Local operator:
PowerShell elevation:
Output folder:

Identity:
- Hostname:
- OS:
- Build:
- Owner/user intent:
- Physical/admin context:

Network:
- Active interface:
- Wired MAC:
- Wi-Fi MAC:
- Current LAN IP:
- Network category:
- DNS servers:
- Default gateway:

Remote access current state:
- RDP:
- OpenSSH:
- WinRM:
- Remote Desktop Users group:
- Administrators group:
- Firewall profile defaults:
- Firewall rules relevant to RDP/SSH/WinRM:
- Listening admin ports:
- Third-party remote tools:

Security and recovery:
- Defender:
- Windows Update/hotfix posture:
- BitLocker:
- TPM:
- Secure Boot:
- Local users and privilege concerns:
- Backup/recovery:

Power and wake:
- AC/power role:
- Sleep states:
- Fast Startup/hibernate:
- Wake-armed devices:
- NIC Magic Packet/PME/Pattern Match:

Compute/runtime:
- GPU:
- NVIDIA driver:
- WSL:
- Docker:
- Hyper-V/virtualization:

Cloud/private access:
- WARP:
- cloudflared:
- Tailscale:
- VPN/overlay notes:

Verified current state:
- ...

Changed nothing confirmation:
- ...

Blocked because elevation or human access is needed:
- ...

Recommended next safe step:
- ...

Approval-needed actions:
- ...

Redaction note:
- ...
```

Do not attach the raw output bundle to git unless a human has reviewed it and
confirmed it is repo-safe.

## Interpretation Rules

Use these rules when summarizing findings:

- If RDP is disabled, say `RDP disabled/not ready`. Do not enable it.
- If RDP is enabled but firewall scope is broad, say `RDP present but not
  approved for administration until scoped to trusted LAN/private overlay`.
- If OpenSSH Server is absent, say `OpenSSH absent`. Do not install it.
- If OpenSSH is running, record listener, firewall, auth posture, and group
  membership, but do not harden it yet.
- If WinRM listeners exist, record them as a risk unless there is an explicit
  known reason.
- If a network profile is `Public`, record that LAN-scoped RDP/SSH work will
  need a deliberate profile/firewall decision.
- If BitLocker is off, do not recommend immediate enablement unless the human
  separately asks. For this onboarding slice, record current state first.
- If BitLocker is on, do not print or export recovery keys. Record whether
  protection is on and whether the human says recovery is stored in 1Password.
- If Cloudflare/WARP/Tailscale exists, record installed/enrolled/running state
  only. Do not enroll or change policy.
- If third-party remote tools exist, record them as current exposure to review.
- If Docker/WSL exposes LAN ports, record them as service exposure to review.
- If any command fails due to elevation, record `blocked pending elevated
  PowerShell`; do not work around it.

## Likely Next Steps After Report Return

The `system-config` operator will decide the next step after reviewing the
report. Likely follow-up packets are:

1. Create a real device record with the returned hostname, MACs, current IP,
   OS build, owner/user model, and remote-admin target.
2. Ask HomeNetOps for static DHCP and local DNS if the LAN identity should be
   stable.
3. Prepare a Windows App profile for same-LAN GUI management if RDP is
   approved.
4. Run a separate elevated Windows implementation pass if RDP or OpenSSH is
   approved.
5. Consider unique per-device local admin credential metadata for 1Password,
   with the human entering secret values through the approved workflow.
6. Route future off-LAN access through Cloudflare/private overlay planning,
   not public WAN exposure.

Until those steps are completed and verified, call this PC `inventory pending`
or `partially onboarded`, not fully managed.
