# desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1
#
# Read-only diagnostic to surface why incoming SSH connections to
# DESKTOP-2JJ3187 reset at SSH_MSG_KEXINIT.
#
# Trigger: after v0.5.0 ssh-lane-install applied cleanly (all 23
# acceptance-gate fields true; see
# docs/device-admin/desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md),
# the MacBook real-auth probe failed with "Connection reset by
# 192.168.0.217 port 22" at SSH_MSG_KEXINIT. TCP handshake + banner
# exchange both complete; sshd resets without sending its own
# KEXINIT or any SSH_MSG_DISCONNECT.
#
# Required shell:   Windows PowerShell 5.1 (powershell.exe)
# Invocation:       powershell.exe -NoProfile -ExecutionPolicy Bypass -File <this file>
# Session class:    read-only-probe
# Encoding:         ASCII-only
#
# Surfaces touched by this script (READ ONLY):
#   - Get-WinEvent OpenSSH/Operational
#   - Get-WinEvent System (sshd-related entries only)
#   - Get-Service sshd
#   - Get-NetTCPConnection :22
#   - sshd.exe -t (config syntax check; no mutation)
#   - sshd.exe -T -C user=jeffr,addr=192.168.0.10 (config readback;
#     no mutation)
#   - Get-Acl on sshd_config, drop-in, administrators_authorized_keys,
#     and ssh_host_*_key{,.pub}
#   - Get-Content (tail) on C:\ProgramData\ssh\logs\sshd.log if present
#   - Loopback test: ssh.exe 127.0.0.1 -p 22 -o ... (real connection
#     attempt from the host to itself; if the same KEX reset
#     occurs locally, the issue is purely sshd-process-internal and
#     not network middleware)
#
# Surfaces NOT touched: registry, services, firewall, sshd_config,
# administrators_authorized_keys, drop-in, host keys, network
# profile, RDP, BitLocker, Defender, accounts. This script is
# read-only.
#
# Spec: docs/device-admin/windows-terminal-admin-spec.md (v0.5.0+)
# Runbook: docs/device-admin/desktop-2jj3187-ssh-kex-reset-diagnostic-2026-05-16.md

# Collect everything we can even when individual steps fail.
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

# -------- pinned facts (for self-check only) ----------------------
$ExpectedHostname  = 'DESKTOP-2JJ3187'
$ExpectedAdminUser = 'jeffr'
$MacBookSourceIp   = '192.168.0.10'

# -------- evidence directory --------------------------------------
$ts          = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$EvidenceDir = "C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-$ts"
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

function Write-Json {
    param(
        [Parameter(Mandatory = $true)] [string] $FileName,
        [Parameter(Mandatory = $true)] $Value
    )
    $path = Join-Path $EvidenceDir $FileName
    $Value | ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $path -Encoding utf8
}

function Append-Text {
    param(
        [Parameter(Mandatory = $true)] [string] $FileName,
        [Parameter(Mandatory = $true)] [string] $Text
    )
    $path = Join-Path $EvidenceDir $FileName
    Add-Content -LiteralPath $path -Value $Text -Encoding utf8
}

function Step-Log {
    param([string] $StepId, [string] $Message)
    $line = "[$((Get-Date).ToUniversalTime().ToString('o'))] $StepId : $Message"
    Append-Text -FileName '00-run.log' -Text $line
    Write-Host $line
}

# ==================================================================
# D0 -- Preflight (no halt; just record)
# ==================================================================
Step-Log 'D0' 'preflight'

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$preflight = [pscustomobject]@{
    started_at           = (Get-Date).ToUniversalTime().ToString('o')
    computer             = $env:COMPUTERNAME
    expected_computer    = $ExpectedHostname
    user                 = $env:USERNAME
    expected_user        = $ExpectedAdminUser
    shell                = "$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion.ToString())"
    is_admin_role        = [bool]$isAdmin
    high_mandatory_level = (((whoami /groups) | Out-String) -match 'High Mandatory Level')
    evidence_dir         = $EvidenceDir
}
Write-Json -FileName '00-preflight.json' -Value $preflight

if ($env:COMPUTERNAME -ne $ExpectedHostname) {
    Step-Log 'D0' "WARN: hostname mismatch ($env:COMPUTERNAME vs $ExpectedHostname); continuing"
}
if (-not $isAdmin) {
    Step-Log 'D0' "WARN: not running in elevated token; some queries may be restricted"
}

# ==================================================================
# D1 -- Service state and recent service-control events
# ==================================================================
Step-Log 'D1' 'service state'

$svc = Get-Service -Name sshd -ErrorAction SilentlyContinue
$svcWmi = Get-CimInstance -ClassName Win32_Service -Filter "Name='sshd'" -ErrorAction SilentlyContinue
$serviceRecord = [pscustomobject]@{
    name           = if ($svc) { [string]$svc.Name } else { $null }
    status         = if ($svc) { [string]$svc.Status } else { 'absent' }
    starttype      = if ($svc) { [string]$svc.StartType } else { 'absent' }
    pid            = if ($svcWmi) { [int]$svcWmi.ProcessId } else { 0 }
    path_name      = if ($svcWmi) { [string]$svcWmi.PathName } else { '' }
    start_name     = if ($svcWmi) { [string]$svcWmi.StartName } else { '' }
    state          = if ($svcWmi) { [string]$svcWmi.State } else { '' }
    exit_code      = if ($svcWmi) { [int]$svcWmi.ExitCode } else { -1 }
    service_w32ec  = if ($svcWmi) { [int]$svcWmi.ServiceSpecificExitCode } else { -1 }
}
Write-Json -FileName '01-service.json' -Value $serviceRecord

# System log events tagged with sshd service control / errors
$sysEvents = Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    ProviderName = @('Service Control Manager', 'Microsoft-Windows-WER-SystemErrorReporting')
    StartTime = (Get-Date).AddHours(-24)
} -ErrorAction SilentlyContinue | Where-Object {
    $_.Message -match 'sshd'
} | Select-Object -First 30

$sysEventsOut = $sysEvents | ForEach-Object {
    [pscustomobject]@{
        time    = $_.TimeCreated.ToString('o')
        id      = $_.Id
        level   = [string]$_.LevelDisplayName
        provider= [string]$_.ProviderName
        message = (($_.Message -replace "`r`n", ' | ') -replace "\s+", ' ').Trim()
    }
}
Write-Json -FileName '01-service-system-events.json' -Value @($sysEventsOut)

# ==================================================================
# D2 -- Listener state
# ==================================================================
Step-Log 'D2' 'listener state'

$listeners = Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue
$listenerRecords = if ($listeners) {
    foreach ($l in $listeners) {
        [pscustomobject]@{
            local_address = [string]$l.LocalAddress
            local_port    = [int]$l.LocalPort
            owning_pid    = [int]$l.OwningProcess
        }
    }
} else {
    @()
}
Write-Json -FileName '02-listeners.json' -Value @($listenerRecords)

# Cross-check pids against sshd
$listenerProcs = $listenerRecords | ForEach-Object {
    $p = Get-Process -Id $_.owning_pid -ErrorAction SilentlyContinue
    if ($p) {
        [pscustomobject]@{
            pid       = $_.owning_pid
            name      = [string]$p.ProcessName
            path      = [string]$p.Path
            cpu       = [double]$p.CPU
            start_time= [string]$p.StartTime
        }
    } else {
        [pscustomobject]@{
            pid  = $_.owning_pid
            name = 'unknown'
        }
    }
}
Write-Json -FileName '02-listener-procs.json' -Value @($listenerProcs)

# ==================================================================
# D3 -- Effective sshd config readback (no mutation)
# ==================================================================
Step-Log 'D3' 'sshd -t and sshd -T'

# Plain sshd -t -- does config syntax still validate?
$sshdT  = & 'C:\Windows\System32\OpenSSH\sshd.exe' -t 2>&1
$sshdTCode = $LASTEXITCODE
$sshdTOutput = ($sshdT | Out-String).Trim()

# sshd -T with MacBook source IP and admin user -- simulates the
# config as it would be evaluated for the real-auth probe
$sshdT2 = & 'C:\Windows\System32\OpenSSH\sshd.exe' -T `
    -C "user=$ExpectedAdminUser,host=desktop-2jj3187.home.arpa,addr=$MacBookSourceIp" 2>&1
$sshdT2Code = $LASTEXITCODE
$sshdT2Output = ($sshdT2 | Out-String)

# Same readback but with addr=127.0.0.1 (mirrors v0.5.0 S7 readback;
# any drift from the install-time readback is informative)
$sshdT3 = & 'C:\Windows\System32\OpenSSH\sshd.exe' -T `
    -C "user=$ExpectedAdminUser,host=desktop-2jj3187.home.arpa,addr=127.0.0.1" 2>&1
$sshdT3Code = $LASTEXITCODE
$sshdT3Output = ($sshdT3 | Out-String)

Write-Json -FileName '03-sshd-t.json' -Value ([pscustomobject]@{
    sshd_t_exit       = $sshdTCode
    sshd_t_output     = $sshdTOutput
})

# Write the full sshd -T outputs as text files for direct grep
Set-Content -LiteralPath (Join-Path $EvidenceDir '03-sshd-T-macbook.txt') -Value $sshdT2Output -Encoding utf8
Set-Content -LiteralPath (Join-Path $EvidenceDir '03-sshd-T-loopback.txt') -Value $sshdT3Output -Encoding utf8

# Also extract a small set of directives we care about for the JSON
function Get-DirectiveValue {
    param([string] $Text, [string] $Pattern)
    $m = [regex]::Match($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($m.Success) { return $m.Groups[1].Value.Trim() } else { return $null }
}

$dirSet = @(
    @{ key='ciphers';             pat='^ciphers\s+(\S+)' },
    @{ key='macs';                pat='^macs\s+(\S+)' },
    @{ key='kexalgorithms';       pat='^kexalgorithms\s+(\S+)' },
    @{ key='hostkeyalgorithms';   pat='^hostkeyalgorithms\s+(\S+)' },
    @{ key='pubkeyacceptedalgorithms'; pat='^pubkeyacceptedalgorithms\s+(\S+)' },
    @{ key='pubkeyauthentication';pat='^pubkeyauthentication\s+(\S+)' },
    @{ key='passwordauthentication'; pat='^passwordauthentication\s+(\S+)' },
    @{ key='kbdinteractiveauthentication'; pat='^kbdinteractiveauthentication\s+(\S+)' },
    @{ key='strictmodes';         pat='^strictmodes\s+(\S+)' },
    @{ key='loglevel';            pat='^loglevel\s+(\S+)' },
    @{ key='allowgroups';         pat='^allowgroups\s+(\S+)' },
    @{ key='allowusers';          pat='^allowusers\s+(\S+)' },
    @{ key='denygroups';          pat='^denygroups\s+(\S+)' },
    @{ key='denyusers';           pat='^denyusers\s+(\S+)' },
    @{ key='authorizedkeysfile';  pat='^authorizedkeysfile\s+(.+)$' }
)

$dirsMacbook = @{}
$dirsLoopback = @{}
foreach ($d in $dirSet) {
    $dirsMacbook[$d.key]  = Get-DirectiveValue -Text $sshdT2Output -Pattern $d.pat
    $dirsLoopback[$d.key] = Get-DirectiveValue -Text $sshdT3Output -Pattern $d.pat
}

Write-Json -FileName '03-sshd-T-directives.json' -Value ([pscustomobject]@{
    macbook_addr_192_168_0_10 = $dirsMacbook
    loopback_addr_127_0_0_1   = $dirsLoopback
    macbook_addr_exit         = $sshdT2Code
    loopback_addr_exit        = $sshdT3Code
})

# ==================================================================
# D4 -- OpenSSH/Operational event log
# ==================================================================
Step-Log 'D4' 'OpenSSH/Operational events'

# Check if log exists / is enabled
$logConfig = $null
try {
    $logConfig = Get-WinEvent -ListLog 'OpenSSH/Operational' -ErrorAction Stop
} catch {
    $logConfig = $null
}

$logState = [pscustomobject]@{
    found            = ($null -ne $logConfig)
    enabled          = if ($logConfig) { [bool]$logConfig.IsEnabled } else { $false }
    log_mode         = if ($logConfig) { [string]$logConfig.LogMode } else { '' }
    record_count     = if ($logConfig) { [long]$logConfig.RecordCount } else { -1 }
    file_size        = if ($logConfig) { [long]$logConfig.FileSize } else { -1 }
}
Write-Json -FileName '04-event-log-config.json' -Value $logState

$openSshEvents = @()
if ($logConfig -and $logConfig.IsEnabled -and $logConfig.RecordCount -gt 0) {
    $openSshEvents = Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 50 -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated -Descending |
        ForEach-Object {
            [pscustomobject]@{
                time    = $_.TimeCreated.ToString('o')
                id      = $_.Id
                level   = [string]$_.LevelDisplayName
                provider= [string]$_.ProviderName
                message = (($_.Message -replace "`r`n", ' | ') -replace "\s+", ' ').Trim()
            }
        }
}
Write-Json -FileName '04-openssh-events.json' -Value @($openSshEvents)

if (-not $logConfig -or -not $logConfig.IsEnabled -or $logConfig.RecordCount -eq 0) {
    Step-Log 'D4' "WARN: OpenSSH/Operational not available, not enabled, or empty (found=$($logState.found), enabled=$($logState.enabled), records=$($logState.record_count)). sshd may be logging to file only."
}

# ==================================================================
# D5 -- sshd.log file (if present)
# ==================================================================
Step-Log 'D5' 'sshd.log tail'

$sshdLogPath = 'C:\ProgramData\ssh\logs\sshd.log'
$sshdLog = [pscustomobject]@{
    path   = $sshdLogPath
    exists = (Test-Path -LiteralPath $sshdLogPath)
    size   = if (Test-Path -LiteralPath $sshdLogPath) { (Get-Item -LiteralPath $sshdLogPath).Length } else { 0 }
}
Write-Json -FileName '05-sshd-log-meta.json' -Value $sshdLog

if ($sshdLog.exists) {
    Get-Content -LiteralPath $sshdLogPath -Tail 100 -ErrorAction SilentlyContinue |
        Set-Content -LiteralPath (Join-Path $EvidenceDir '05-sshd-log-tail.txt') -Encoding utf8
} else {
    Step-Log 'D5' "sshd.log file absent at $sshdLogPath. Windows OpenSSH logs to Event Log by default unless `SyslogFacility LOCAL0` is set with file logging configured."
}

# ==================================================================
# D6 -- ACLs on relevant files
# ==================================================================
Step-Log 'D6' 'ACLs on sshd config + key files'

$aclTargets = @(
    'C:\ProgramData\ssh\sshd_config',
    'C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf',
    'C:\ProgramData\ssh\administrators_authorized_keys',
    'C:\ProgramData\ssh\ssh_host_ed25519_key',
    'C:\ProgramData\ssh\ssh_host_ed25519_key.pub',
    'C:\ProgramData\ssh\ssh_host_ecdsa_key',
    'C:\ProgramData\ssh\ssh_host_ecdsa_key.pub',
    'C:\ProgramData\ssh\ssh_host_rsa_key',
    'C:\ProgramData\ssh\ssh_host_rsa_key.pub'
)

$aclResults = @{}
foreach ($p in $aclTargets) {
    if (Test-Path -LiteralPath $p) {
        $a = Get-Acl -LiteralPath $p -ErrorAction SilentlyContinue
        if ($a) {
            $aclResults[$p] = [pscustomobject]@{
                exists = $true
                owner  = [string]$a.Owner
                group  = [string]$a.Group
                access = ($a.AccessToString -replace "`r`n", ' | ').Trim()
                size   = (Get-Item -LiteralPath $p).Length
            }
        } else {
            $aclResults[$p] = [pscustomobject]@{
                exists = $true
                owner  = ''
                group  = ''
                access = '(Get-Acl returned null)'
                size   = (Get-Item -LiteralPath $p).Length
            }
        }
    } else {
        $aclResults[$p] = [pscustomobject]@{
            exists = $false
        }
    }
}
Write-Json -FileName '06-acls.json' -Value $aclResults

# ==================================================================
# D7 -- Loopback SSH connection probe (no auth required to surface
#       the KEX behavior; -o ConnectionAttempts=1 -o BatchMode=yes
#       so we just see if the server resets on a local connection)
# ==================================================================
Step-Log 'D7' 'loopback SSH probe'

$loopbackOutPath = Join-Path $EvidenceDir '07-loopback-ssh.txt'

# Use BatchMode + a short ConnectTimeout. We don't expect this to
# succeed in terms of auth (we don't have a key here), but we want
# to see what stage of the SSH protocol it gets to. If the same
# "Connection reset" happens here, the issue is sshd-internal and
# unrelated to network middleware. If it succeeds past KEX (gets
# to authentication), the issue is network-path-specific (firewall
# rule, IDS/IPS, NIC).
$loopbackCmd = '& C:\Windows\System32\OpenSSH\ssh.exe -v -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=NUL -o BatchMode=yes -o ConnectTimeout=5 -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o IdentitiesOnly=yes -o IdentityFile=NUL ' + $ExpectedAdminUser + '@127.0.0.1 hostname 2>&1'

$loopbackOut = & cmd /c "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"$loopbackCmd`""
$loopbackExitCode = $LASTEXITCODE
Set-Content -LiteralPath $loopbackOutPath -Value ($loopbackOut | Out-String) -Encoding utf8

Write-Json -FileName '07-loopback-meta.json' -Value ([pscustomobject]@{
    exit_code         = $loopbackExitCode
    output_path       = $loopbackOutPath
    output_first_line = if ($loopbackOut) { [string]$loopbackOut[0] } else { '' }
    output_last_line  = if ($loopbackOut) { [string]$loopbackOut[-1] } else { '' }
    has_connection_reset = (($loopbackOut | Out-String) -match 'Connection reset')
    has_kexinit_sent     = (($loopbackOut | Out-String) -match 'SSH2_MSG_KEXINIT sent')
    has_permission_denied = (($loopbackOut | Out-String) -match 'Permission denied')
    has_auth_failure     = (($loopbackOut | Out-String) -match 'No supported authentication methods available|publickey')
})

# ==================================================================
# D8 -- Summary
# ==================================================================
$summary = [pscustomobject]@{
    script                 = 'desktop-2jj3187-ssh-kex-reset-diagnostic-v0.1.0.ps1'
    finished_at            = (Get-Date).ToUniversalTime().ToString('o')
    computer               = $env:COMPUTERNAME
    user                   = $env:USERNAME
    shell                  = "$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion.ToString())"
    evidence_dir           = $EvidenceDir
    sshd_service_status    = $serviceRecord.status
    sshd_service_starttype = $serviceRecord.starttype
    sshd_pid               = $serviceRecord.pid
    listener_count         = @($listenerRecords).Count
    sshd_t_passed          = ($sshdTCode -eq 0)
    sshd_t_exit            = $sshdTCode
    openssh_oplog_found    = $logState.found
    openssh_oplog_enabled  = $logState.enabled
    openssh_oplog_records  = $logState.record_count
    sshd_log_file_exists   = $sshdLog.exists
    sshd_log_file_size     = $sshdLog.size
    loopback_ssh_exit      = $loopbackExitCode
    loopback_connection_reset = ((Get-Content -LiteralPath $loopbackOutPath -Raw -ErrorAction SilentlyContinue) -match 'Connection reset')
    loopback_reached_kex   = ((Get-Content -LiteralPath $loopbackOutPath -Raw -ErrorAction SilentlyContinue) -match 'SSH2_MSG_KEXINIT sent')
    files_written = @(
        '00-preflight.json',
        '01-service.json',
        '01-service-system-events.json',
        '02-listeners.json',
        '02-listener-procs.json',
        '03-sshd-t.json',
        '03-sshd-T-macbook.txt',
        '03-sshd-T-loopback.txt',
        '03-sshd-T-directives.json',
        '04-event-log-config.json',
        '04-openssh-events.json',
        '05-sshd-log-meta.json',
        '05-sshd-log-tail.txt',
        '06-acls.json',
        '07-loopback-ssh.txt',
        '07-loopback-meta.json',
        '08-summary.json',
        '00-run.log'
    )
}
Write-Json -FileName '08-summary.json' -Value $summary

Write-Host ''
Write-Host '=== SSH KEX reset diagnostic summary ==='
$summary | Format-List
Write-Host ''
Write-Host "Evidence directory: $EvidenceDir"
Write-Host 'Return 08-summary.json plus 04-openssh-events.json plus 07-loopback-ssh.txt to system-config.'
Write-Host 'If 04-openssh-events.json is empty/unavailable, also send 05-sshd-log-tail.txt if it exists.'
