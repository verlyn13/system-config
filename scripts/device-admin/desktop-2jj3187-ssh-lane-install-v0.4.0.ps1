# desktop-2jj3187-ssh-lane-install-v0.4.0.ps1
#
# Phase 3 install of the DESKTOP-2JJ3187 SSH admin lane.
#
# This is the canonical executable artifact. Do NOT transcribe this
# script out of a Markdown code block; run THIS file directly.
#
# Required shell:   Windows PowerShell 5.1 (powershell.exe)
# Invocation:       powershell.exe -NoProfile -ExecutionPolicy Bypass -File <this file>
# Session class:    scoped-live-change
# Encoding:         ASCII-only
#
# Prerequisite: docs/device-admin/desktop-2jj3187-reconciliation-2026-05-15.md
#   applied and its apply record committed, with summary showing
#   OpenSSH.Server = NotPresent and no v0.3.0 mutation.
#
# Surfaces mutated by this script:
#   - OpenSSH.Server Windows capability (install)
#   - sshd service (StartType=Automatic, Status=Running)
#   - C:\ProgramData\ssh\sshd_config (Match Group administrators)
#   - C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf
#   - C:\ProgramData\ssh\administrators_authorized_keys
#   - Windows Firewall rule "Jefahnierocks SSH LAN TCP 22"
#   - Windows Firewall rule "OpenSSH-Server-In-TCP" (disabled)
#
# Spec: docs/device-admin/windows-terminal-admin-spec.md (v0.5.0)
# Runbook: docs/device-admin/desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# -------- pinned facts --------------------------------------------
$ExpectedHostname    = 'DESKTOP-2JJ3187'
$ExpectedAdminUser   = 'jeffr'
$PublicKeyBody       = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRgw1xN2rjmlIFbAPsp7cc6SJcm0h5IMvrL8o6CyLh9'
$ExpectedFingerprint = 'SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s'
$LanScope            = '192.168.0.0/24'
$SshRuleName         = 'Jefahnierocks SSH LAN TCP 22'
$OpenSshDefaultRule  = 'OpenSSH-Server-In-TCP'

# -------- evidence directory --------------------------------------
$ts          = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$EvidenceDir = "C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-$ts"
$SnapDir     = Join-Path $EvidenceDir 'snapshot'
New-Item -ItemType Directory -Path $SnapDir -Force | Out-Null

function Write-Json {
    param(
        [Parameter(Mandatory = $true)] [string] $FileName,
        [Parameter(Mandatory = $true)] $Value
    )
    $path = Join-Path $EvidenceDir $FileName
    $Value | ConvertTo-Json -Depth 8 |
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

# Apply ACL "Administrators + SYSTEM only, inheritance disabled".
# Used for sshd_config drop-in and administrators_authorized_keys.
function Set-AdminOnlyAcl {
    param([Parameter(Mandatory = $true)] [string] $Path)

    $acl = New-Object System.Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)

    $admins = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'BUILTIN\Administrators',
        'FullControl',
        [System.Security.AccessControl.AccessControlType]::Allow)
    $acl.AddAccessRule($admins)

    $system = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'NT AUTHORITY\SYSTEM',
        'FullControl',
        [System.Security.AccessControl.AccessControlType]::Allow)
    $acl.AddAccessRule($system)

    Set-Acl -Path $Path -AclObject $acl
}

# Run sshd -t. Returns $true if config syntax is valid.
function Test-SshdConfig {
    & 'C:\Windows\System32\OpenSSH\sshd.exe' -t 2>&1 | ForEach-Object {
        Append-Text -FileName '00-run.log' -Text "sshd -t : $_"
    }
    return ($LASTEXITCODE -eq 0)
}

# ==================================================================
# S0 -- Preflight identity and elevation
# ==================================================================
Step-Log 'S0' 'preflight identity check'

if ($env:COMPUTERNAME -ne $ExpectedHostname) {
    throw "Hostname mismatch: expected $ExpectedHostname, got $env:COMPUTERNAME"
}

if ($env:USERNAME -ne $ExpectedAdminUser) {
    throw "User mismatch: expected $ExpectedAdminUser, got $env:USERNAME"
}

if ($PSVersionTable.PSVersion.Major -ne 5) {
    throw ("Wrong shell: this script requires Windows PowerShell 5.1; " +
        "got $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion). " +
        "Open powershell.exe and re-run with -File.")
}

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$preflight = [pscustomobject]@{
    started_at           = (Get-Date).ToUniversalTime().ToString('o')
    computer             = $env:COMPUTERNAME
    user                 = $env:USERNAME
    shell                = "$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion.ToString())"
    is_admin_role        = [bool]$isAdmin
    high_mandatory_level = (((whoami /groups) | Out-String) -match 'High Mandatory Level')
    evidence_dir         = $EvidenceDir
}
Write-Json -FileName '00-preflight.json' -Value $preflight

if (-not $isAdmin) {
    throw 'Token is not in the Administrators role. Re-launch powershell.exe as Administrator.'
}

# ==================================================================
# S1 -- OpenSSH.Server capability install (normalized enum)
# ==================================================================
Step-Log 'S1' 'capability state query (normalized)'

$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' |
    Select-Object -First 1

if (-not $cap) {
    throw 'No OpenSSH.Server capability returned by Get-WindowsCapability.'
}

# Normalize HERE, in the producing shell. Never pass enums across
# process boundaries without .ToString().
$capRecord = [pscustomobject]@{
    name        = [string]$cap.Name
    state       = $cap.State.ToString()
    state_int   = [int]$cap.State
    state_type  = $cap.State.GetType().FullName
}
Write-Json -FileName '01-capability-before.json' -Value $capRecord

switch ($capRecord.state) {
    'Installed' {
        Step-Log 'S1' "capability already Installed: $($capRecord.name); skip Add-WindowsCapability"
    }
    'NotPresent' {
        Step-Log 'S1' "installing capability: $($capRecord.name)"
        $addResult = Add-WindowsCapability -Online -Name $capRecord.name
        $addRecord = [pscustomobject]@{
            online          = [bool]$addResult.Online
            restart_needed  = [string]$addResult.RestartNeeded
            log_path        = [string]$addResult.LogPath
        }
        Write-Json -FileName '01-capability-add.json' -Value $addRecord
    }
    default {
        throw "Unexpected OpenSSH.Server state: $($capRecord.state) (int=$($capRecord.state_int))"
    }
}

# Read back.
$capAfter = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' |
    Select-Object -First 1
$capAfterRecord = [pscustomobject]@{
    name       = [string]$capAfter.Name
    state      = $capAfter.State.ToString()
    state_int  = [int]$capAfter.State
}
Write-Json -FileName '01-capability-after.json' -Value $capAfterRecord

if ($capAfterRecord.state -ne 'Installed') {
    throw "OpenSSH.Server is not Installed after S1; state=$($capAfterRecord.state)"
}

# ==================================================================
# S2 -- sshd service: StartType=Automatic, Status=Running
# ==================================================================
Step-Log 'S2' 'service configuration'

$svc = Get-Service -Name sshd -ErrorAction Stop

if ($svc.StartType -ne 'Automatic') {
    Step-Log 'S2' "Set-Service sshd -StartupType Automatic (was $($svc.StartType))"
    Set-Service -Name sshd -StartupType Automatic
}

# Briefly start to ensure %ProgramData%\ssh is populated by Windows
# OpenSSH first-run (creates default sshd_config and host keys).
if ($svc.Status -ne 'Running') {
    Step-Log 'S2' "Start-Service sshd (was $($svc.Status))"
    Start-Service -Name sshd
    Start-Sleep -Seconds 2
}

$svcAfter = Get-Service -Name sshd
$svcRecord = [pscustomobject]@{
    name      = [string]$svcAfter.Name
    status    = [string]$svcAfter.Status
    starttype = [string]$svcAfter.StartType
}
Write-Json -FileName '02-service.json' -Value $svcRecord

if ($svcAfter.Status -ne 'Running') {
    throw "sshd did not reach Running state; current=$($svcAfter.Status)"
}

# ==================================================================
# S3 -- sshd_config Match block (backup-before-edit)
# ==================================================================
Step-Log 'S3' 'verify Match Group administrators block in sshd_config'

$sshdConfigPath = 'C:\ProgramData\ssh\sshd_config'
if (-not (Test-Path -LiteralPath $sshdConfigPath)) {
    throw "$sshdConfigPath is absent after capability install."
}

# Always snapshot the pre-edit file so rollback is deterministic.
Copy-Item -LiteralPath $sshdConfigPath `
    -Destination (Join-Path $SnapDir 'sshd_config.preinstall') -Force

$cfgContent = Get-Content -Raw -LiteralPath $sshdConfigPath
$matchPattern = '(?ms)^Match\s+Group\s+administrators\b.*?AuthorizedKeysFile\s+__PROGRAMDATA__/ssh/administrators_authorized_keys'

$wroteMatchBlock = $false
if ($cfgContent -match $matchPattern) {
    Step-Log 'S3' 'Match Group administrators block already present (default since 1809).'
} else {
    Step-Log 'S3' 'Match Group administrators block missing; appending standard form.'
    $addition = @"

Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
"@
    Add-Content -LiteralPath $sshdConfigPath -Value $addition -Encoding ascii
    $wroteMatchBlock = $true
}

if (-not (Test-SshdConfig)) {
    Step-Log 'S3' 'sshd -t failed after S3; restoring snapshot.'
    Copy-Item -LiteralPath (Join-Path $SnapDir 'sshd_config.preinstall') `
        -Destination $sshdConfigPath -Force
    throw 'sshd -t failed after Match-block edit.'
}

Write-Json -FileName '03-match-block.json' -Value ([pscustomobject]@{
    sshd_config_path  = $sshdConfigPath
    block_present     = $true
    wrote_in_this_run = $wroteMatchBlock
})

# ==================================================================
# S4 -- Jefahnierocks hardening drop-in
# ==================================================================
Step-Log 'S4' 'install hardening drop-in'

$dropInDir  = 'C:\ProgramData\ssh\sshd_config.d'
$dropInPath = Join-Path $dropInDir '20-jefahnierocks-admin.conf'
$dropInBody = @"
# Managed by system-config docs/device-admin/desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
LogLevel INFO
AllowGroups administrators
"@

if (-not (Test-Path -LiteralPath $dropInDir)) {
    New-Item -ItemType Directory -Path $dropInDir -Force | Out-Null
}

if (Test-Path -LiteralPath $dropInPath) {
    Copy-Item -LiteralPath $dropInPath `
        -Destination (Join-Path $SnapDir '20-jefahnierocks-admin.conf.preinstall') -Force
}

Set-Content -LiteralPath $dropInPath -Value $dropInBody -Encoding ascii
Set-AdminOnlyAcl -Path $dropInPath

if (-not (Test-SshdConfig)) {
    Step-Log 'S4' 'sshd -t failed after S4; removing drop-in.'
    Remove-Item -LiteralPath $dropInPath -Force
    throw 'sshd -t failed after hardening drop-in install.'
}

$dropInAcl = (Get-Acl -LiteralPath $dropInPath).AccessToString
Write-Json -FileName '04-dropin.json' -Value ([pscustomobject]@{
    path = $dropInPath
    acl  = $dropInAcl
})

# ==================================================================
# S5 -- Admin public key install (backup-before-edit, fingerprint gate)
# ==================================================================
Step-Log 'S5' 'install admin public key'

$authKeysPath = 'C:\ProgramData\ssh\administrators_authorized_keys'

# Idempotent: if file exists, snapshot it before any edit so rollback
# can restore the prior state.
if (Test-Path -LiteralPath $authKeysPath) {
    Copy-Item -LiteralPath $authKeysPath `
        -Destination (Join-Path $SnapDir 'administrators_authorized_keys.preinstall') -Force
}

# Validate pinned key body shape (no comment is fine; 1Password-
# generated keys do not include a comment by default).
if ($PublicKeyBody -notmatch '^ssh-ed25519 \S+( \S+)?$') {
    throw 'Pinned public key body does not match the expected ed25519 shape.'
}

# Check whether the key is already authorized (idempotent).
$keyBodyToken = $PublicKeyBody.Split(' ')[1]
$existing     = if (Test-Path -LiteralPath $authKeysPath) {
    (Get-Content -LiteralPath $authKeysPath -Raw -ErrorAction SilentlyContinue)
} else {
    ''
}

$alreadyPresent = ($null -ne $existing) -and ($existing -match [regex]::Escape($keyBodyToken))

if ($alreadyPresent) {
    Step-Log 'S5' 'public key already present in administrators_authorized_keys; skip append'
} else {
    if (-not (Test-Path -LiteralPath $authKeysPath)) {
        New-Item -ItemType File -Path $authKeysPath -Force | Out-Null
    }
    Add-Content -LiteralPath $authKeysPath -Value $PublicKeyBody -Encoding ascii
    Step-Log 'S5' 'public key appended'
}

# Always re-apply the Admins+SYSTEM-only ACL idempotently.
Set-AdminOnlyAcl -Path $authKeysPath

# Verify the installed key fingerprint matches the pinned value.
$keygenOutput = (& 'C:\Windows\System32\OpenSSH\ssh-keygen.exe' -lf $authKeysPath 2>&1) -join "`n"
Append-Text -FileName '00-run.log' -Text "ssh-keygen -lf : $keygenOutput"

if ($keygenOutput -notmatch [regex]::Escape($ExpectedFingerprint)) {
    throw ("Installed-key fingerprint does not match pinned value. " +
        "Expected $ExpectedFingerprint; ssh-keygen reported: $keygenOutput")
}

$keyAcl = (Get-Acl -LiteralPath $authKeysPath).AccessToString
Write-Json -FileName '05-admin-keys.json' -Value ([pscustomobject]@{
    path             = $authKeysPath
    key_already      = $alreadyPresent
    pinned_body      = $PublicKeyBody
    expected_finger  = $ExpectedFingerprint
    keygen_output    = $keygenOutput
    acl              = $keyAcl
})

# ==================================================================
# S6 -- Firewall: scoped rule, disable broad default
# ==================================================================
Step-Log 'S6' 'firewall: disable broad default; ensure named scoped rule'

# Disable the OpenSSH installer's default broad rule if it exists
# and is enabled.
$broadRule = Get-NetFirewallRule -DisplayName $OpenSshDefaultRule -ErrorAction SilentlyContinue
if ($broadRule) {
    if ($broadRule.Enabled -eq 'True') {
        Step-Log 'S6' "Disable-NetFirewallRule '$OpenSshDefaultRule'"
        $broadRule | Disable-NetFirewallRule
    }
}

# Ensure the named scoped rule exists with the right shape.
$scopedRule = Get-NetFirewallRule -DisplayName $SshRuleName -ErrorAction SilentlyContinue
if ($scopedRule) {
    Step-Log 'S6' "rule '$SshRuleName' already exists; ensuring shape"
    $scopedRule | Enable-NetFirewallRule
    $scopedRule | Set-NetFirewallRule -Direction Inbound -Action Allow -Profile Private
    $scopedRule | Get-NetFirewallPortFilter |
        Set-NetFirewallPortFilter -Protocol TCP -LocalPort 22
    $scopedRule | Get-NetFirewallAddressFilter |
        Set-NetFirewallAddressFilter -RemoteAddress $LanScope
} else {
    Step-Log 'S6' "New-NetFirewallRule '$SshRuleName' (Private, $LanScope)"
    New-NetFirewallRule `
        -DisplayName $SshRuleName `
        -Description 'system-config managed: LAN SSH for Jefahnierocks admin' `
        -Direction Inbound -Action Allow `
        -Protocol TCP -LocalPort 22 `
        -Profile Private `
        -RemoteAddress $LanScope `
        -Enabled True | Out-Null
}

# Read back.
$ruleFinal = Get-NetFirewallRule -DisplayName $SshRuleName
$portFilter = $ruleFinal | Get-NetFirewallPortFilter
$addrFilter = $ruleFinal | Get-NetFirewallAddressFilter
Write-Json -FileName '06-firewall.json' -Value ([pscustomobject]@{
    rule_name      = [string]$ruleFinal.DisplayName
    enabled        = [string]$ruleFinal.Enabled
    direction      = [string]$ruleFinal.Direction
    action         = [string]$ruleFinal.Action
    profile        = [string]$ruleFinal.Profile
    protocol       = [string]$portFilter.Protocol
    local_port     = [string]$portFilter.LocalPort
    remote_address = [string]$addrFilter.RemoteAddress
    broad_default  = if ($broadRule) {
        [string](Get-NetFirewallRule -DisplayName $OpenSshDefaultRule).Enabled
    } else { 'absent' }
})

# ==================================================================
# S7 -- Restart sshd and conditional effective-config readback
# ==================================================================
Step-Log 'S7' 'restart sshd and read back effective config'

if (-not (Test-SshdConfig)) {
    throw 'sshd -t failed at S7 before restart. Halt; do not restart sshd with a broken config.'
}

Restart-Service -Name sshd
Start-Sleep -Seconds 2

$svcFinal = Get-Service -Name sshd
if ($svcFinal.Status -ne 'Running') {
    throw "sshd not Running after restart; status=$($svcFinal.Status)"
}

# Conditional sshd -T proves the Match block routes admin users to
# administrators_authorized_keys.
$conditional = & 'C:\Windows\System32\OpenSSH\sshd.exe' -T `
    -C "user=$ExpectedAdminUser,host=desktop-2jj3187.home.arpa,addr=127.0.0.1" 2>&1
$conditionalText = ($conditional | Out-String)
Append-Text -FileName '00-run.log' -Text "sshd -T conditional : $conditionalText"

$effective = [pscustomobject]@{
    pubkeyauth          = ($conditionalText -match 'pubkeyauthentication yes')
    passwordauth_off    = ($conditionalText -match 'passwordauthentication no')
    kbdinteractive_off  = ($conditionalText -match 'kbdinteractiveauthentication no')
    strictmodes_on      = ($conditionalText -match 'strictmodes yes')
    loglevel_info       = ($conditionalText -match 'loglevel INFO')
    auth_keys_file      = ($conditionalText -match 'authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys')
    allow_groups_admin  = ($conditionalText -match 'allowgroups administrators')
}
Write-Json -FileName '07-sshd-effective.json' -Value $effective

foreach ($prop in $effective.PSObject.Properties) {
    if (-not $prop.Value) {
        throw "Effective sshd config readback missing expected directive: $($prop.Name)"
    }
}

# ==================================================================
# S8 -- Final summary
# ==================================================================
$listener22 = Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue
$listener22Record = if ($listener22) {
    foreach ($c in $listener22) {
        [pscustomobject]@{
            local_port    = [int]$c.LocalPort
            local_address = [string]$c.LocalAddress
            owning_pid    = [int]$c.OwningProcess
        }
    }
} else {
    @()
}

$summary = [pscustomobject]@{
    script                 = 'desktop-2jj3187-ssh-lane-install-v0.4.0.ps1'
    finished_at            = (Get-Date).ToUniversalTime().ToString('o')
    computer               = $env:COMPUTERNAME
    user                   = $env:USERNAME
    shell                  = "$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion.ToString())"
    openssh_capability     = $capAfterRecord.state
    sshd_service_status    = [string]$svcFinal.Status
    sshd_service_starttype = [string]$svcFinal.StartType
    match_block_present    = $true
    drop_in_path           = $dropInPath
    admin_keys_path        = $authKeysPath
    expected_fingerprint   = $ExpectedFingerprint
    firewall_rule          = $SshRuleName
    firewall_scope         = $LanScope
    listener_22            = @($listener22Record)
    effective_config       = $effective
    evidence_dir           = $EvidenceDir
}
Write-Json -FileName '08-summary.json' -Value $summary

Write-Host ''
Write-Host '=== SSH lane install summary ==='
$summary | Format-List
Write-Host ''
Write-Host "Evidence directory: $EvidenceDir"
Write-Host 'Return 08-summary.json verbatim to system-config as the hand-back.'
Write-Host 'Operator MacBook should now run: ssh desktop-2jj3187 ''cmd /c "hostname && whoami"'''
