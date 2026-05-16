# desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1
#
# Diagnostic v0.2.0: foreground sshd -ddd capture + targeted
# read-only probes to identify why sshd-session.exe (Windows OpenSSH
# 9.5's privsep child) crashes immediately on KEXINIT receipt with
# no event log entry.
#
# v0.1.0 confirmed sshd-process-internal cause (loopback ssh reset
# reproduces with same symptom as LAN probe), parses sshd_config
# cleanly (sshd -T exits 0 for both source addresses), and ruled
# out host-key ACL StrictModes rejection (every key has
# SYSTEM+Administrators FullControl only).
#
# v0.2.0 adds the definitive next step: run sshd.exe -ddd in the
# foreground with output redirected to a log file, then probe it
# locally. sshd's -ddd (debug3) emits every step of KEX processing
# including the failure point that the service-mode sshd hides via
# the silent sshd-session.exe crash. v0.2.0 also adds:
#   - OpenSSH binary inventory (verify sshd-session.exe exists,
#     check ACL and Authenticode signature)
#   - Windows Defender state and recent threats
#   - WER (Windows Error Reporting) crash dump search for
#     sshd / sshd-session
#   - Application log entries for the sshd-session.exe path
#   - Fixed v0.1.0 capture bugs (loopback stderr, fail-soft file
#     initialization)
#
# Required shell:   Windows PowerShell 5.1 (powershell.exe)
# Invocation:       powershell.exe -NoProfile -ExecutionPolicy Bypass -File <this file>
# Session class:    scoped-live-change (D9 stops/starts sshd
#                   service temporarily; foreground sshd binds to
#                   port 22 while service is stopped; sshd service
#                   is restored at end. RDP unaffected.)
# Encoding:         ASCII-only
#
# Mutations performed by this script:
#   - Stop-Service sshd (D9 begin)
#   - Start sshd.exe -ddd as foreground process (D9 begin)
#   - Stop the foreground sshd process (D9 end)
#   - Start-Service sshd (D9 end)
#
# Read-only operations:
#   - All D0-D8 probes (same as v0.1.0 + new additions)
#   - The loopback ssh probe inside D9 (no host mutation; just a
#     network connection attempt)
#
# Surfaces NOT touched: sshd_config, drop-in, host keys,
# administrators_authorized_keys, firewall rules, network profile,
# RDP, BitLocker, Defender exclusions, accounts, scheduled tasks,
# Cloudflare/WARP, 1Password.
#
# Spec: docs/device-admin/windows-terminal-admin-spec.md (v0.5.0+)
# Runbook: docs/device-admin/desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0-2026-05-16.md

# Collect everything we can even when individual steps fail.
# D9 has stricter halt semantics (see D9 itself).
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

# -------- pinned facts (for self-check only) ----------------------
$ExpectedHostname  = 'DESKTOP-2JJ3187'
$ExpectedAdminUser = 'jeffr'
$MacBookSourceIp   = '192.168.0.10'

# -------- evidence directory --------------------------------------
$ts          = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$EvidenceDir = "C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-v020-$ts"
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

function Write-Json {
    param(
        [Parameter(Mandatory = $true)] [string] $FileName,
        [Parameter(Mandatory = $true)] $Value
    )
    $path = Join-Path $EvidenceDir $FileName
    try {
        $Value | ConvertTo-Json -Depth 10 |
            Set-Content -LiteralPath $path -Encoding utf8
    } catch {
        Set-Content -LiteralPath $path -Value "ConvertTo-Json failed: $_" -Encoding utf8
    }
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
# D0 -- Preflight
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
    throw "Hostname mismatch: expected $ExpectedHostname, got $env:COMPUTERNAME"
}
if ($PSVersionTable.PSVersion.Major -ne 5) {
    throw "Wrong shell: this script requires Windows PowerShell 5.1; got $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion). Open powershell.exe and re-run with -File."
}
if (-not $isAdmin) {
    throw 'Token is not in the Administrators role. Re-launch powershell.exe as Administrator. D9 requires elevation to stop/start the sshd service.'
}

# ==================================================================
# D1 -- Service state (with start_name + Win32_Service detail)
# ==================================================================
Step-Log 'D1' 'service state'

$svc    = Get-Service -Name sshd -ErrorAction SilentlyContinue
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

# Service-related System log entries (always initialize to empty array)
$sysEventsOut = @()
try {
    $sysEvents = @(Get-WinEvent -FilterHashtable @{
        LogName      = 'System'
        ProviderName = @('Service Control Manager', 'Microsoft-Windows-WER-SystemErrorReporting')
        StartTime    = (Get-Date).AddHours(-24)
    } -ErrorAction Stop | Where-Object { $_.Message -match 'sshd' } | Select-Object -First 30)
    foreach ($e in $sysEvents) {
        $sysEventsOut += [pscustomobject]@{
            time     = $e.TimeCreated.ToString('o')
            id       = $e.Id
            level    = [string]$e.LevelDisplayName
            provider = [string]$e.ProviderName
            message  = (($e.Message -replace "`r`n", ' | ') -replace "\s+", ' ').Trim()
        }
    }
} catch {
    # No matching events is the common "no error to find" case; record it
    Append-Text -FileName '00-run.log' -Text "D1 : Get-WinEvent System (sshd-tagged) returned no events or failed: $_"
}
Write-Json -FileName '01-service-system-events.json' -Value $sysEventsOut

# ==================================================================
# D2 -- Listeners
# ==================================================================
Step-Log 'D2' 'listeners'

$listenerRecords = @()
$listeners = @(Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue)
foreach ($l in $listeners) {
    $listenerRecords += [pscustomobject]@{
        local_address = [string]$l.LocalAddress
        local_port    = [int]$l.LocalPort
        owning_pid    = [int]$l.OwningProcess
    }
}
Write-Json -FileName '02-listeners.json' -Value $listenerRecords

$listenerProcs = @()
foreach ($r in $listenerRecords) {
    $p = Get-Process -Id $r.owning_pid -ErrorAction SilentlyContinue
    if ($p) {
        $listenerProcs += [pscustomobject]@{
            pid        = $r.owning_pid
            name       = [string]$p.ProcessName
            path       = [string]$p.Path
            cpu        = [double]$p.CPU
            start_time = [string]$p.StartTime
        }
    } else {
        $listenerProcs += [pscustomobject]@{
            pid  = $r.owning_pid
            name = 'unknown'
        }
    }
}
Write-Json -FileName '02-listener-procs.json' -Value $listenerProcs

# ==================================================================
# D2b -- OpenSSH binary inventory
# ==================================================================
Step-Log 'D2b' 'OpenSSH binary inventory'

$openSshDir = 'C:\Windows\System32\OpenSSH'
$binaryInventory = @{}
if (Test-Path -LiteralPath $openSshDir) {
    $files = Get-ChildItem -LiteralPath $openSshDir -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $key = $f.Name
        $entry = [pscustomobject]@{
            full_name      = $f.FullName
            length         = $f.Length
            last_write_utc = $f.LastWriteTimeUtc.ToString('o')
            version_info   = $null
            signature      = $null
            acl_summary    = $null
        }
        # Version info
        try {
            $vi = (Get-Item $f.FullName).VersionInfo
            $entry.version_info = [pscustomobject]@{
                file_version    = [string]$vi.FileVersion
                product_version = [string]$vi.ProductVersion
                product_name    = [string]$vi.ProductName
                company_name    = [string]$vi.CompanyName
                file_description= [string]$vi.FileDescription
            }
        } catch {
            $entry.version_info = "VersionInfo failed: $_"
        }
        # Authenticode signature
        try {
            $sig = Get-AuthenticodeSignature -LiteralPath $f.FullName -ErrorAction Stop
            $entry.signature = [pscustomobject]@{
                status       = [string]$sig.Status
                status_message = [string]$sig.StatusMessage
                signer_subject = if ($sig.SignerCertificate) { [string]$sig.SignerCertificate.Subject } else { $null }
            }
        } catch {
            $entry.signature = "Get-AuthenticodeSignature failed: $_"
        }
        # ACL summary
        try {
            $a = Get-Acl -LiteralPath $f.FullName -ErrorAction Stop
            $entry.acl_summary = [pscustomobject]@{
                owner  = [string]$a.Owner
                access = (($a.AccessToString -replace "`r`n", ' | ').Trim())
            }
        } catch {
            $entry.acl_summary = "Get-Acl failed: $_"
        }
        $binaryInventory[$key] = $entry
    }
} else {
    $binaryInventory['_error'] = "$openSshDir not found"
}
Write-Json -FileName '02b-openssh-binaries.json' -Value $binaryInventory

# Critical finding flags
$sshdSessionPath = Join-Path $openSshDir 'sshd-session.exe'
$sshdSessionPresent = Test-Path -LiteralPath $sshdSessionPath
Step-Log 'D2b' "sshd-session.exe present: $sshdSessionPresent"

# ==================================================================
# D3 -- Effective sshd config readback (sshd -t and sshd -T -C)
# ==================================================================
Step-Log 'D3' 'sshd -t and sshd -T'

$sshdT  = & 'C:\Windows\System32\OpenSSH\sshd.exe' -t 2>&1
$sshdTCode = $LASTEXITCODE
$sshdTOutput = ($sshdT | Out-String).Trim()

$sshdT2 = & 'C:\Windows\System32\OpenSSH\sshd.exe' -T `
    -C "user=$ExpectedAdminUser,host=desktop-2jj3187.home.arpa,addr=$MacBookSourceIp" 2>&1
$sshdT2Code = $LASTEXITCODE
$sshdT2Output = ($sshdT2 | Out-String)

$sshdT3 = & 'C:\Windows\System32\OpenSSH\sshd.exe' -T `
    -C "user=$ExpectedAdminUser,host=desktop-2jj3187.home.arpa,addr=127.0.0.1" 2>&1
$sshdT3Code = $LASTEXITCODE
$sshdT3Output = ($sshdT3 | Out-String)

Write-Json -FileName '03-sshd-t.json' -Value ([pscustomobject]@{
    sshd_t_exit   = $sshdTCode
    sshd_t_output = $sshdTOutput
})
Set-Content -LiteralPath (Join-Path $EvidenceDir '03-sshd-T-macbook.txt') -Value $sshdT2Output -Encoding utf8
Set-Content -LiteralPath (Join-Path $EvidenceDir '03-sshd-T-loopback.txt') -Value $sshdT3Output -Encoding utf8

function Get-DirectiveValue {
    param([string] $Text, [string] $Pattern)
    $m = [regex]::Match($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($m.Success) { return $m.Groups[1].Value.Trim() } else { return $null }
}

$dirSet = @(
    @{ key='ciphers';                       pat='^ciphers\s+(\S+)' },
    @{ key='macs';                          pat='^macs\s+(\S+)' },
    @{ key='kexalgorithms';                 pat='^kexalgorithms\s+(\S+)' },
    @{ key='hostkeyalgorithms';             pat='^hostkeyalgorithms\s+(\S+)' },
    @{ key='pubkeyacceptedalgorithms';      pat='^pubkeyacceptedalgorithms\s+(\S+)' },
    @{ key='pubkeyauthentication';          pat='^pubkeyauthentication\s+(\S+)' },
    @{ key='passwordauthentication';        pat='^passwordauthentication\s+(\S+)' },
    @{ key='kbdinteractiveauthentication';  pat='^kbdinteractiveauthentication\s+(\S+)' },
    @{ key='strictmodes';                   pat='^strictmodes\s+(\S+)' },
    @{ key='loglevel';                      pat='^loglevel\s+(\S+)' },
    @{ key='allowgroups';                   pat='^allowgroups\s+(\S+)' },
    @{ key='allowusers';                    pat='^allowusers\s+(\S+)' },
    @{ key='denygroups';                    pat='^denygroups\s+(\S+)' },
    @{ key='denyusers';                     pat='^denyusers\s+(\S+)' },
    @{ key='authorizedkeysfile';            pat='^authorizedkeysfile\s+(.+)$' }
)
$dirsMacbook  = @{}
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

$logConfig = $null
try { $logConfig = Get-WinEvent -ListLog 'OpenSSH/Operational' -ErrorAction Stop } catch { }

$logState = [pscustomobject]@{
    found        = ($null -ne $logConfig)
    enabled      = if ($logConfig) { [bool]$logConfig.IsEnabled } else { $false }
    log_mode     = if ($logConfig) { [string]$logConfig.LogMode } else { '' }
    record_count = if ($logConfig) { [long]$logConfig.RecordCount } else { -1 }
    file_size    = if ($logConfig) { [long]$logConfig.FileSize } else { -1 }
}
Write-Json -FileName '04-event-log-config.json' -Value $logState

$openSshEvents = @()
if ($logConfig -and $logConfig.IsEnabled -and $logConfig.RecordCount -gt 0) {
    $rawEvents = @(Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 50 -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated -Descending)
    foreach ($e in $rawEvents) {
        $openSshEvents += [pscustomobject]@{
            time     = $e.TimeCreated.ToString('o')
            id       = $e.Id
            level    = [string]$e.LevelDisplayName
            provider = [string]$e.ProviderName
            message  = (($e.Message -replace "`r`n", ' | ') -replace "\s+", ' ').Trim()
        }
    }
}
Write-Json -FileName '04-openssh-events.json' -Value $openSshEvents

# ==================================================================
# D4b -- Application log entries for the sshd-session.exe path
# ==================================================================
Step-Log 'D4b' 'Application log entries for sshd-session.exe'

$appEventsOut = @()
try {
    $appEvents = @(Get-WinEvent -FilterHashtable @{
        LogName   = 'Application'
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction Stop | Where-Object {
        $_.Message -match 'sshd-session|sshd\.exe|OpenSSH'
    } | Select-Object -First 30)
    foreach ($e in $appEvents) {
        $appEventsOut += [pscustomobject]@{
            time     = $e.TimeCreated.ToString('o')
            id       = $e.Id
            level    = [string]$e.LevelDisplayName
            provider = [string]$e.ProviderName
            message  = (($e.Message -replace "`r`n", ' | ') -replace "\s+", ' ').Trim()
        }
    }
} catch {
    Append-Text -FileName '00-run.log' -Text "D4b : Application log query returned no events or failed: $_"
}
Write-Json -FileName '04b-application-events.json' -Value $appEventsOut

# ==================================================================
# D5 -- sshd.log file (always write the file even when absent)
# ==================================================================
Step-Log 'D5' 'sshd.log tail'

$sshdLogPath = 'C:\ProgramData\ssh\logs\sshd.log'
$sshdLog = [pscustomobject]@{
    path   = $sshdLogPath
    exists = (Test-Path -LiteralPath $sshdLogPath)
    size   = if (Test-Path -LiteralPath $sshdLogPath) { (Get-Item -LiteralPath $sshdLogPath).Length } else { 0 }
}
Write-Json -FileName '05-sshd-log-meta.json' -Value $sshdLog

$tailPath = Join-Path $EvidenceDir '05-sshd-log-tail.txt'
if ($sshdLog.exists) {
    Get-Content -LiteralPath $sshdLogPath -Tail 100 -ErrorAction SilentlyContinue |
        Set-Content -LiteralPath $tailPath -Encoding utf8
} else {
    Set-Content -LiteralPath $tailPath -Value "(sshd.log absent at $sshdLogPath; Windows OpenSSH logs to Event Log by default)" -Encoding utf8
}

# Also check the logs DIRECTORY ACL (a known cause per Win32-OpenSSH #2282)
$sshLogsDir = 'C:\ProgramData\ssh\logs'
$logsDirAcl = [pscustomobject]@{
    path   = $sshLogsDir
    exists = (Test-Path -LiteralPath $sshLogsDir)
}
if ($logsDirAcl.exists) {
    try {
        $a = Get-Acl -LiteralPath $sshLogsDir -ErrorAction Stop
        $logsDirAcl | Add-Member -NotePropertyName owner  -NotePropertyValue ([string]$a.Owner)
        $logsDirAcl | Add-Member -NotePropertyName group  -NotePropertyValue ([string]$a.Group)
        $logsDirAcl | Add-Member -NotePropertyName access -NotePropertyValue (($a.AccessToString -replace "`r`n", ' | ').Trim())
    } catch {
        $logsDirAcl | Add-Member -NotePropertyName error -NotePropertyValue "Get-Acl failed: $_"
    }
}
Write-Json -FileName '05b-sshd-logs-dir-acl.json' -Value $logsDirAcl

# ==================================================================
# D6 -- ACLs on host keys + config + drop-in + authkeys
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
        try {
            $a = Get-Acl -LiteralPath $p -ErrorAction Stop
            $aclResults[$p] = [pscustomobject]@{
                exists = $true
                owner  = [string]$a.Owner
                group  = [string]$a.Group
                access = ($a.AccessToString -replace "`r`n", ' | ').Trim()
                size   = (Get-Item -LiteralPath $p).Length
            }
        } catch {
            $aclResults[$p] = [pscustomobject]@{ exists = $true; error = "Get-Acl failed: $_" }
        }
    } else {
        $aclResults[$p] = [pscustomobject]@{ exists = $false }
    }
}
Write-Json -FileName '06-acls.json' -Value $aclResults

# ==================================================================
# D6b -- Windows Defender state + recent threats
# ==================================================================
Step-Log 'D6b' 'Defender state'

$defenderState = $null
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    $defenderState = [pscustomobject]@{
        AntivirusEnabled              = [bool]$mp.AntivirusEnabled
        AMServiceEnabled              = [bool]$mp.AMServiceEnabled
        RealTimeProtectionEnabled     = [bool]$mp.RealTimeProtectionEnabled
        IoavProtectionEnabled         = [bool]$mp.IoavProtectionEnabled
        OnAccessProtectionEnabled     = [bool]$mp.OnAccessProtectionEnabled
        BehaviorMonitorEnabled        = [bool]$mp.BehaviorMonitorEnabled
        IsTamperProtected             = [bool]$mp.IsTamperProtected
        AntivirusSignatureVersion     = [string]$mp.AntivirusSignatureVersion
        AntivirusSignatureLastUpdated = [string]$mp.AntivirusSignatureLastUpdated
    }
} catch {
    $defenderState = "Get-MpComputerStatus failed: $_"
}
Write-Json -FileName '06b-defender-state.json' -Value $defenderState

$defenderPrefs = $null
try {
    $pref = Get-MpPreference -ErrorAction Stop
    $defenderPrefs = [pscustomobject]@{
        ExclusionPath      = @($pref.ExclusionPath)
        ExclusionProcess   = @($pref.ExclusionProcess)
        ExclusionExtension = @($pref.ExclusionExtension)
        AttackSurfaceReductionRules_Ids     = @($pref.AttackSurfaceReductionRules_Ids)
        AttackSurfaceReductionRules_Actions = @($pref.AttackSurfaceReductionRules_Actions)
        DisableRealtimeMonitoring           = [bool]$pref.DisableRealtimeMonitoring
        DisableIOAVProtection               = [bool]$pref.DisableIOAVProtection
    }
} catch {
    $defenderPrefs = "Get-MpPreference failed: $_"
}
Write-Json -FileName '06b-defender-prefs.json' -Value $defenderPrefs

$defenderThreats = $null
try {
    $threats = @(Get-MpThreatDetection -ErrorAction Stop | Sort-Object InitialDetectionTime -Descending | Select-Object -First 20)
    $defenderThreats = @()
    foreach ($t in $threats) {
        $defenderThreats += [pscustomobject]@{
            detection_time   = [string]$t.InitialDetectionTime
            threat_name      = [string]$t.ThreatName
            severity         = [string]$t.SeverityID
            current_status   = [string]$t.CurrentThreatExecutionStatusID
            resources        = @($t.Resources)
        }
    }
} catch {
    $defenderThreats = "Get-MpThreatDetection failed or returned no threats: $_"
}
Write-Json -FileName '06b-defender-threats.json' -Value $defenderThreats

# ==================================================================
# D6c -- WER (Windows Error Reporting) crash dumps for sshd / sshd-session
# ==================================================================
Step-Log 'D6c' 'WER crash dump search'

$werResults = @{}
foreach ($dir in @(
    'C:\ProgramData\Microsoft\Windows\WER\ReportArchive',
    'C:\ProgramData\Microsoft\Windows\WER\ReportQueue',
    'C:\ProgramData\Microsoft\Windows\WER\Temp'
)) {
    $found = @()
    if (Test-Path -LiteralPath $dir) {
        try {
            $hits = @(Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Name -match 'sshd|sshd-session|OpenSSH' -and
                    $_.LastWriteTime -gt (Get-Date).AddDays(-3)
                } |
                Select-Object -First 20)
            foreach ($h in $hits) {
                $found += [pscustomobject]@{
                    path           = $h.FullName
                    length         = $h.Length
                    last_write_utc = $h.LastWriteTimeUtc.ToString('o')
                }
            }
        } catch {
            $found = "WER search in $dir failed: $_"
        }
    }
    $werResults[$dir] = $found
}
Write-Json -FileName '06c-wer-dumps.json' -Value $werResults

# ==================================================================
# D9 -- Foreground sshd -ddd capture + loopback probe
# ==================================================================
# Stricter halt semantics for D9: this is the scoped-live-change
# portion. We stop sshd service, run sshd.exe -ddd in foreground
# with -E logfile, probe it via loopback ssh, then restore the
# service. Each step is gated; if any fails unexpectedly we still
# attempt to restore the service before exiting.
Step-Log 'D9' 'foreground sshd -ddd + loopback probe (scoped mutation)'

$fgLogPath        = Join-Path $EvidenceDir '09-foreground-sshd.log'
$probeOutPath     = Join-Path $EvidenceDir '09-loopback-probe.txt'
$probeMetaPath    = Join-Path $EvidenceDir '09-loopback-meta.json'
$d9Path           = Join-Path $EvidenceDir '09-result.json'
$fgProcessId      = $null
$serviceRestarted = $false

$d9Result = [pscustomobject]@{
    started_at              = (Get-Date).ToUniversalTime().ToString('o')
    service_was_running     = ($svc -and $svc.Status -eq 'Running')
    service_stopped         = $false
    foreground_started      = $false
    foreground_pid          = $null
    foreground_exit_code    = $null
    probe_attempted         = $false
    probe_exit_code         = $null
    probe_kex_sent          = $null
    probe_connection_reset  = $null
    service_restored        = $false
    error                   = $null
}

try {
    # Step 1: stop the service-mode sshd so port 22 is free
    if ($d9Result.service_was_running) {
        Stop-Service -Name sshd -Force -ErrorAction Stop
        $d9Result.service_stopped = $true
        Step-Log 'D9' 'sshd service stopped'
        Start-Sleep -Seconds 2
    }

    # Step 2: confirm port 22 is now free
    $stillListening = @(Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue)
    if ($stillListening.Count -gt 0) {
        throw "Port 22 still has $($stillListening.Count) listener(s) after stopping sshd service; cannot start foreground sshd."
    }

    # Step 3: start foreground sshd with -ddd, -E logfile, -e (also log to stderr)
    # Use Start-Process so we can capture PID and redirect output properly
    $fgArgs = @('-ddd', '-E', $fgLogPath)
    $fgProc = Start-Process -FilePath 'C:\Windows\System32\OpenSSH\sshd.exe' `
        -ArgumentList $fgArgs `
        -NoNewWindow `
        -PassThru
    $fgProcessId = $fgProc.Id
    $d9Result.foreground_started = $true
    $d9Result.foreground_pid     = $fgProcessId
    Step-Log 'D9' "foreground sshd started pid=$fgProcessId (-ddd -E $fgLogPath)"

    # Step 4: wait for it to bind to port 22
    $bound = $false
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        $listenerNow = @(Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue)
        if ($listenerNow.Count -gt 0) {
            $bound = $true
            break
        }
        # If the foreground sshd has already exited, stop waiting
        $procStillAlive = Get-Process -Id $fgProcessId -ErrorAction SilentlyContinue
        if (-not $procStillAlive) {
            Step-Log 'D9' "foreground sshd pid=$fgProcessId exited before binding"
            break
        }
    }
    if (-not $bound) {
        # Note this and continue to capture the log; don't throw yet
        Step-Log 'D9' "foreground sshd did NOT bind to port 22 within 10s; continuing to capture whatever -ddd output was produced"
    }

    # Step 5: loopback ssh probe (only if bound)
    if ($bound) {
        # Use cmd /c with stderr redirection so we capture ssh.exe -v output reliably
        $probeStderrPath = Join-Path $EvidenceDir '09-probe-stderr.txt'
        & cmd /c "C:\Windows\System32\OpenSSH\ssh.exe -vvv -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=NUL -o BatchMode=yes -o ConnectTimeout=8 -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o IdentitiesOnly=yes -o IdentityFile=NUL $ExpectedAdminUser@127.0.0.1 hostname > `"$probeOutPath`" 2> `"$probeStderrPath`""
        $d9Result.probe_exit_code = $LASTEXITCODE
        $d9Result.probe_attempted = $true

        # Combine stdout+stderr for analysis
        $stderrContent = if (Test-Path -LiteralPath $probeStderrPath) { Get-Content -LiteralPath $probeStderrPath -Raw -ErrorAction SilentlyContinue } else { '' }
        $stdoutContent = if (Test-Path -LiteralPath $probeOutPath) { Get-Content -LiteralPath $probeOutPath -Raw -ErrorAction SilentlyContinue } else { '' }
        $combinedProbeText = "===STDOUT===`n$stdoutContent`n===STDERR===`n$stderrContent"
        Set-Content -LiteralPath $probeOutPath -Value $combinedProbeText -Encoding utf8

        $d9Result.probe_kex_sent         = [bool]($combinedProbeText -match 'SSH2_MSG_KEXINIT sent')
        $d9Result.probe_connection_reset = [bool]($combinedProbeText -match 'Connection reset')
        Step-Log 'D9' "probe exit=$($d9Result.probe_exit_code), kex_sent=$($d9Result.probe_kex_sent), connection_reset=$($d9Result.probe_connection_reset)"
    } else {
        Set-Content -LiteralPath $probeOutPath -Value "(probe skipped: foreground sshd did not bind)" -Encoding utf8
    }

    # Brief wait so foreground sshd can flush any post-probe log lines
    Start-Sleep -Seconds 2

    # Step 6: stop the foreground sshd
    $fgStillAlive = Get-Process -Id $fgProcessId -ErrorAction SilentlyContinue
    if ($fgStillAlive) {
        Stop-Process -Id $fgProcessId -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
    $fgFinalCheck = Get-Process -Id $fgProcessId -ErrorAction SilentlyContinue
    if (-not $fgFinalCheck) {
        $d9Result.foreground_exit_code = 'stopped'
        Step-Log 'D9' "foreground sshd pid=$fgProcessId stopped"
    } else {
        Step-Log 'D9' "WARN: foreground sshd pid=$fgProcessId still alive after Stop-Process"
    }
} catch {
    $d9Result.error = "$_"
    Step-Log 'D9' "ERROR: $_"
}

# Step 7: ALWAYS attempt to restore the service if we stopped it
if ($d9Result.service_stopped) {
    try {
        Start-Service -Name sshd -ErrorAction Stop
        $serviceRestarted = $true
        $d9Result.service_restored = $true
        Step-Log 'D9' 'sshd service restored to Running'
    } catch {
        $d9Result.error = ($d9Result.error + " | restore-service: $_").Trim('| ')
        Step-Log 'D9' "CRITICAL: failed to restore sshd service after foreground test: $_. Operator must manually Start-Service sshd."
    }
}

# Step 8: confirm probe stderr / stdout / sshd log file existence
$d9Result | Add-Member -NotePropertyName foreground_log_exists -NotePropertyValue (Test-Path -LiteralPath $fgLogPath)
$d9Result | Add-Member -NotePropertyName foreground_log_size   -NotePropertyValue $(if (Test-Path -LiteralPath $fgLogPath) { (Get-Item -LiteralPath $fgLogPath).Length } else { 0 })
$d9Result | Add-Member -NotePropertyName probe_out_exists      -NotePropertyValue (Test-Path -LiteralPath $probeOutPath)
$d9Result | Add-Member -NotePropertyName probe_out_size        -NotePropertyValue $(if (Test-Path -LiteralPath $probeOutPath) { (Get-Item -LiteralPath $probeOutPath).Length } else { 0 })

Write-Json -FileName '09-result.json' -Value $d9Result

# ==================================================================
# D10 -- Summary
# ==================================================================
$svcAfter = Get-Service -Name sshd -ErrorAction SilentlyContinue

$summary = [pscustomobject]@{
    script                       = 'desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1'
    finished_at                  = (Get-Date).ToUniversalTime().ToString('o')
    computer                     = $env:COMPUTERNAME
    user                         = $env:USERNAME
    shell                        = "$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion.ToString())"
    evidence_dir                 = $EvidenceDir
    sshd_service_status_initial  = $serviceRecord.status
    sshd_service_status_final    = if ($svcAfter) { [string]$svcAfter.Status } else { 'absent' }
    sshd_service_starttype       = if ($svcAfter) { [string]$svcAfter.StartType } else { 'absent' }
    sshd_service_pid_initial     = $serviceRecord.pid
    sshd_service_start_name      = $serviceRecord.start_name
    listener_count_initial       = @($listenerRecords).Count
    sshd_t_passed                = ($sshdTCode -eq 0)
    sshd_session_present         = $sshdSessionPresent
    openssh_oplog_found          = $logState.found
    openssh_oplog_enabled        = $logState.enabled
    openssh_oplog_records        = $logState.record_count
    sshd_log_file_exists         = $sshdLog.exists
    sshd_logs_dir_exists         = $logsDirAcl.exists
    foreground_sshd_started      = $d9Result.foreground_started
    foreground_sshd_log_exists   = $d9Result.foreground_log_exists
    foreground_sshd_log_size     = $d9Result.foreground_log_size
    loopback_probe_attempted     = $d9Result.probe_attempted
    loopback_probe_exit          = $d9Result.probe_exit_code
    loopback_probe_kex_sent      = $d9Result.probe_kex_sent
    loopback_probe_connection_reset = $d9Result.probe_connection_reset
    service_restored             = $d9Result.service_restored
    d9_error                     = $d9Result.error
}
Write-Json -FileName '10-summary.json' -Value $summary

Write-Host ''
Write-Host '=== SSH KEX reset diagnostic v0.2.0 summary ==='
$summary | Format-List
Write-Host ''
Write-Host "Evidence directory: $EvidenceDir"
Write-Host ''
Write-Host 'Return verbatim to system-config (priority order):'
Write-Host '  1. 10-summary.json'
Write-Host '  2. 09-foreground-sshd.log         (the THE smoking-gun: sshd -ddd captures the actual KEX failure)'
Write-Host '  3. 09-loopback-probe.txt          (the ssh -vvv output for the loopback probe)'
Write-Host '  4. 09-result.json                 (the D9 state machine record)'
Write-Host '  5. 02b-openssh-binaries.json      (sshd-session.exe presence + ACL + signature)'
Write-Host '  6. 04b-application-events.json    (any sshd-session.exe crash entries)'
Write-Host '  7. 06b-defender-*.json            (Defender state + threats)'
Write-Host '  8. 06c-wer-dumps.json             (any WER dumps for sshd / sshd-session)'
Write-Host '  9. 05b-sshd-logs-dir-acl.json     (logs folder ACL; known Win32-OpenSSH #2282 cause)'
Write-Host ''
if ($d9Result.service_stopped -and -not $d9Result.service_restored) {
    Write-Host 'WARN: sshd service was stopped during D9 and could NOT be restored automatically.'
    Write-Host '      Run `Start-Service sshd` manually to restore SSH listener on port 22.'
}
