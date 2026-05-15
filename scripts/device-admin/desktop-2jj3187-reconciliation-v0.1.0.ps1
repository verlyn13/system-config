# desktop-2jj3187-reconciliation-v0.1.0.ps1
#
# Read-only reconciliation of DESKTOP-2JJ3187 admin state after the
# 2026-05-15 v0.3.0 install packet halted in S1 due to a packet
# defect (enum serialization).
#
# Source of truth:
#   docs/device-admin/desktop-2jj3187-reconciliation-2026-05-15.md
#   docs/device-admin/windows-terminal-admin-spec.md (v0.5.0)
#
# Required shell:   Windows PowerShell 5.1 (powershell.exe)
# Invocation:       powershell.exe -NoProfile -ExecutionPolicy Bypass -File <this file>
# Session class:    read-only-probe
# Encoding:         ASCII-only (verified by grep [^\x00-\x7F])
#
# Captures normalized DISM state, paths, services, listeners, and
# firewall rules. Writes structured JSON evidence. No mutation.

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

# -------- evidence directory --------------------------------------
$ts          = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$EvidenceDir = "C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-reconciliation-$ts"
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

function Write-Json {
    param(
        [Parameter(Mandatory = $true)] [string] $FileName,
        [Parameter(Mandatory = $true)] $Value
    )
    $path = Join-Path $EvidenceDir $FileName
    $Value | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $path -Encoding utf8
}

function Write-Text {
    param(
        [Parameter(Mandatory = $true)] [string] $FileName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string] $Text
    )
    process {
        $path = Join-Path $EvidenceDir $FileName
        Add-Content -LiteralPath $path -Value $Text -Encoding utf8
    }
}

# -------- 00-run.json: header -------------------------------------
$run = [pscustomobject]@{
    script        = 'desktop-2jj3187-reconciliation-v0.1.0.ps1'
    started_at    = (Get-Date).ToUniversalTime().ToString('o')
    session_class = 'read-only-probe'
    computer      = $env:COMPUTERNAME
    user          = $env:USERNAME
    shell         = "$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion.ToString())"
    evidence_dir  = $EvidenceDir
}
Write-Json -FileName '00-run.json' -Value $run

# -------- 01-identity.json: who am i, elevation, token level -----
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

$groupsRaw = (whoami /groups) 2>&1 | Out-String
$hasHigh   = $groupsRaw -match 'Mandatory Label\\High Mandatory Level'

$identityRecord = [pscustomobject]@{
    whoami                = [string]$identity.Name
    is_admin_role         = [bool]$principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    high_mandatory_level  = [bool]$hasHigh
    sid                   = [string]$identity.User.Value
    auth_type             = [string]$identity.AuthenticationType
}
Write-Json -FileName '01-identity.json' -Value $identityRecord
$groupsRaw | Write-Text -FileName '01-identity-groups.txt'

# -------- 02-openssh-capability.json: normalized DISM state ------
# Get-WindowsCapability returns enums; we MUST normalize in this
# producing shell and never let outer consumers compare raw enum
# integers against string names. The v0.3.0 install packet hit
# exactly that defect.
$cap = $null
$capError = $null
try {
    $cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' -ErrorAction Stop |
        Select-Object -First 1
} catch {
    $capError = "$_"
}

if ($cap) {
    $capRecord = [pscustomobject]@{
        present          = $true
        name             = [string]$cap.Name
        state_string     = $cap.State.ToString()
        state_int        = [int]$cap.State
        state_type       = $cap.State.GetType().FullName
        display_name     = [string]$cap.DisplayName
        description      = [string]$cap.Description
    }
} else {
    $capRecord = [pscustomobject]@{
        present = $false
        error   = $capError
        note    = 'Capability enumeration failed; treat host state as unknown.'
    }
}
Write-Json -FileName '02-openssh-capability.json' -Value $capRecord

# -------- 03-openssh-paths.json: file presence and ACLs ----------
$paths = @(
    'C:\Windows\System32\OpenSSH\sshd.exe',
    'C:\ProgramData\ssh\sshd_config',
    'C:\ProgramData\ssh\administrators_authorized_keys',
    'C:\ProgramData\ssh\sshd_config.d',
    'C:\ProgramData\ssh\ssh_host_ed25519_key',
    'C:\ProgramData\ssh\ssh_host_rsa_key'
)
$pathRecords = foreach ($p in $paths) {
    $present = Test-Path -LiteralPath $p
    $aclOwner = $null
    if ($present) {
        try { $aclOwner = (Get-Acl -LiteralPath $p).Owner } catch { $aclOwner = "$_" }
    }
    [pscustomobject]@{
        path    = $p
        present = $present
        owner   = $aclOwner
    }
}
Write-Json -FileName '03-openssh-paths.json' -Value $pathRecords

# -------- 04-services.json: sshd, ssh-agent, TermService, WinRM --
$svcNames = @('sshd', 'ssh-agent', 'TermService', 'WinRM')
$svcRecords = foreach ($n in $svcNames) {
    $svc = Get-Service -Name $n -ErrorAction SilentlyContinue
    if ($svc) {
        [pscustomobject]@{
            name      = [string]$svc.Name
            present   = $true
            status    = [string]$svc.Status
            starttype = [string]$svc.StartType
        }
    } else {
        [pscustomobject]@{
            name    = $n
            present = $false
        }
    }
}
Write-Json -FileName '04-services.json' -Value $svcRecords

# -------- 05-listeners.json: admin ports ------------------------
$ports = @(22, 3389, 5985, 5986)
$listenerRecords = foreach ($p in $ports) {
    $conns = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue
    if ($conns) {
        foreach ($c in $conns) {
            [pscustomobject]@{
                local_port    = [int]$c.LocalPort
                local_address = [string]$c.LocalAddress
                owning_pid    = [int]$c.OwningProcess
                state         = [string]$c.State
            }
        }
    } else {
        [pscustomobject]@{
            local_port = $p
            listening  = $false
        }
    }
}
Write-Json -FileName '05-listeners.json' -Value $listenerRecords

# -------- 06-firewall-rules.json: SSH / RDP / Jefahnierocks ------
$ruleMatch = 'SSH|RDP|WinRM|Jefahnierocks|Dad Remote|OpenSSH'
$fwRecords = Get-NetFirewallRule -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match $ruleMatch -or
                   $_.DisplayGroup -match $ruleMatch } |
    ForEach-Object {
        $r = $_
        $addrFilter = $r | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue
        $portFilter = $r | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
        [pscustomobject]@{
            display_name    = [string]$r.DisplayName
            display_group   = [string]$r.DisplayGroup
            enabled         = [string]$r.Enabled
            direction       = [string]$r.Direction
            action          = [string]$r.Action
            profile         = [string]$r.Profile
            protocol        = [string]$portFilter.Protocol
            local_port      = [string]$portFilter.LocalPort
            remote_address  = [string]$addrFilter.RemoteAddress
        }
    }
Write-Json -FileName '06-firewall-rules.json' -Value @($fwRecords)

# -------- 07-network-profile.json: live LAN profile -------------
$profileRecords = Get-NetConnectionProfile -ErrorAction SilentlyContinue |
    ForEach-Object {
        [pscustomobject]@{
            interface_alias       = [string]$_.InterfaceAlias
            name                  = [string]$_.Name
            network_category      = [string]$_.NetworkCategory
            ipv4_connectivity     = [string]$_.IPv4Connectivity
            ipv6_connectivity     = [string]$_.IPv6Connectivity
        }
    }
Write-Json -FileName '07-network-profile.json' -Value @($profileRecords)

# -------- 08-summary.json: one-page reconciliation --------------
# Goal: an outer agent can read this single file to decide whether
# v0.4.0 install may proceed. Keep all values normalized (no enums).
$summary = [pscustomobject]@{
    computer                    = $env:COMPUTERNAME
    expected_computer           = 'DESKTOP-2JJ3187'
    user                        = $env:USERNAME
    expected_user               = 'jeffr'
    shell                       = "$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion.ToString())"
    expected_shell_match        = ($PSVersionTable.PSVersion.Major -eq 5)
    admin_role                  = [bool]$principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    high_mandatory_level        = [bool]$hasHigh
    openssh_capability_present  = ($null -ne $cap)
    openssh_capability_state    = if ($cap) { $cap.State.ToString() } else { 'unknown' }
    sshd_exe_present            = (Test-Path 'C:\Windows\System32\OpenSSH\sshd.exe')
    sshd_config_present         = (Test-Path 'C:\ProgramData\ssh\sshd_config')
    admin_authkeys_present      = (Test-Path 'C:\ProgramData\ssh\administrators_authorized_keys')
    sshd_service_status         = (Get-Service sshd -ErrorAction SilentlyContinue |
                                    Select-Object -ExpandProperty Status |
                                    ForEach-Object { [string]$_ }) -join ''
    sshd_service_starttype      = (Get-Service sshd -ErrorAction SilentlyContinue |
                                    Select-Object -ExpandProperty StartType |
                                    ForEach-Object { [string]$_ }) -join ''
    tcp_22_listening            = (
        $null -ne (Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue))
    tcp_3389_listening          = (
        $null -ne (Get-NetTCPConnection -State Listen -LocalPort 3389 -ErrorAction SilentlyContinue))
    jefahnierocks_ssh_rule      = ($null -ne (Get-NetFirewallRule `
                                    -DisplayName 'Jefahnierocks SSH LAN TCP 22' -ErrorAction SilentlyContinue))
    jefahnierocks_rdp_tcp_rule  = ($null -ne (Get-NetFirewallRule `
                                    -DisplayName 'Jefahnierocks RDP LAN TCP 3389' -ErrorAction SilentlyContinue))
    jefahnierocks_rdp_udp_rule  = ($null -ne (Get-NetFirewallRule `
                                    -DisplayName 'Jefahnierocks RDP LAN UDP 3389' -ErrorAction SilentlyContinue))
    evidence_dir                = $EvidenceDir
    finished_at                 = (Get-Date).ToUniversalTime().ToString('o')
}
Write-Json -FileName '08-summary.json' -Value $summary

Write-Host ''
Write-Host '=== Reconciliation summary ==='
$summary | Format-List
Write-Host ''
Write-Host "Evidence directory: $EvidenceDir"
Write-Host 'Return 08-summary.json verbatim to system-config as the hand-back.'
