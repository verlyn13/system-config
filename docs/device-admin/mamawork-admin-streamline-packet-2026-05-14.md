---
title: MAMAWORK Admin Surface Streamline Packet - 2026-05-14
category: operations
component: device_admin
status: applied
version: 0.2.0
last_updated: 2026-05-15
tags: [device-admin, mamawork, windows, openssh, firewall, accounts, streamline, ssh-repair]
priority: highest
---

# MAMAWORK Admin Surface Streamline Packet - 2026-05-14

Applied 2026-05-14T15:44:01-08:00. See
[mamawork-admin-streamline-apply-2026-05-14.md](./mamawork-admin-streamline-apply-2026-05-14.md)
and [handback-mamawork-admin-streamline-2026-05-14.md](./handback-mamawork-admin-streamline-2026-05-14.md).
Phase 5 self-skipped because two OneDrive scheduled tasks run under
the `DadAdmin` SID, so `DadAdmin` remains enabled pending a follow-up
decision. The packet removed the legacy key line and disabled the
old SSH firewall rule, but it did not close SSH auth by itself; the
actual auth blocker was the missing Windows OpenSSH administrators
Match block, resolved by the follow-up `mamawork-sshd-admin-match-block`
packet.

Repairs the MAMAWORK SSH lockout (the actual `administrators_authorized_keys`
posture bug discovered 2026-05-15T00:15:00Z) **and** streamlines the
MAMAWORK admin surface in the same approval-gated apply so we don't
accumulate verification debt across multiple smaller packets.

The streamline collapses to a single principle: **one operator admin
identity per device (`MAMAWORK\jeffr`), one operator admin key per
device (`SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY`), real
auth probes as the success criterion**. The legacy `DadAdmin_WinNet`
key line, the `DadAdmin` local admin account, and the `Dad Remote
Management` firewall rule have all been retained "for caution" or
"to remove in a later packet." Together they masked the SSH lockout
and widened the admin surface for no operational benefit. They go in
this same packet so the next packet operates on a clean baseline.

This packet is **operator-applied on MAMAWORK** from an elevated
PowerShell 7+ session. The closing success criterion is **not** a
file-content check — it is a real `ssh jeffr@mamawork.home.arpa
'hostname; whoami'` probe run by `system-config` from the MacBook
after the operator returns the apply evidence. (See
[feedback-auth-packet-success-criterion](../../home/feedback-cache).)

## Scope

In scope:

1. **Read-only diagnostic** on `C:\ProgramData\ssh\administrators_authorized_keys`:
   `Get-Acl`, owner SID + name, first-4-bytes BOM check, `sshd -T`
   effective config (search for any `Match` block override),
   recent `OpenSSH/Operational` event-log entries for AuthorizedKeysFile
   / pubkey errors. Captured to the evidence dir for repo ingest.
2. **Conditional ACL repair** on `administrators_authorized_keys`:
   `icacls /inheritance:r /grant SYSTEM:F /grant Administrators:F
   /setowner Administrators`. Applied only if Phase-1 finds the
   owner or DACL is not in the canonical {Administrators, SYSTEM}
   shape that Windows OpenSSH hardcodes a check for.
3. **Conditional BOM strip** on the same file: rewrite via
   `[IO.File]::WriteAllLines(... UTF8Encoding(false))`. Applied
   only if Phase-1 finds the file starts with `EF BB BF`. Idempotent.
4. **Remove the legacy `DadAdmin_WinNet` line** from
   `administrators_authorized_keys`. Its private half is confirmed
   not on fedora-top (2026-05-14 operator check) and not in the
   MacBook 1Password agent (2026-05-15 system-config check). Dead
   surface.
5. **Disable** (not delete) the local `DadAdmin` Windows user with
   `Disable-LocalUser -Name DadAdmin`. Account stays intact for
   audit / break-glass; can be enabled again with a single command
   if needed. After the new SSH path is verified end-to-end, a
   tiny follow-up packet can delete the account deliberately.
6. **Disable** (not delete) the `Dad Remote Management` Windows
   Firewall rule with `Disable-NetFirewallRule`. The rule was
   `Profile=Any` `TCP 22` `RemoteAddress=192.168.0.200`, widened
   2026-05-14T14:14 to `192.168.0.0/24`, now functionally a
   duplicate of `Jefahnierocks SSH LAN TCP 22` (which is
   `Profile=Private`, the cleaner shape).
7. **Read-only inventory** of two suspect paths so the operator
   can decide their fate from a small follow-up packet rather than
   inside this larger one:
   - `C:\Users\jeffr\.ssh\authorized_keys.txt` — capture its size,
     first-line key type only (no full key body to evidence file).
   - `C:\Users\DadAdmin.MamaWork\` — capture a directory listing
     (paths, sizes, last-write-times); do NOT remove.
8. **Pre-flight safety check** for any service or scheduled task
   running as `MAMAWORK\DadAdmin`. If anything matches, the script
   STOPS before disabling the account and surfaces the finding.
9. **Closing real auth probe** (system-config side, on the MacBook):
   `ssh -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub
     -o IdentityAgent=$HOME/.1password-ssh-agent.sock
     -o IdentitiesOnly=yes
     -o PreferredAuthentications=publickey
     -o BatchMode=yes
     jeffr@mamawork.home.arpa 'hostname; whoami'`
   expecting `MAMAWORK / jeffr`. If this probe fails, packet
   status stays `applied-pending-auth-verification` and a follow-up
   diagnostic packet is required (most likely cause would be a
   `Match Group administrators` block in `sshd_config` redirecting
   AuthorizedKeysFile, which this packet's Phase 1 will surface).

Out of scope (deliberately, kept for future packets):

- **Deleting** the `DadAdmin` local user, **deleting** the
  `C:\Users\DadAdmin.MamaWork\` profile directory, **deleting**
  `C:\Users\jeffr\.ssh\authorized_keys.txt`, **removing** the
  `Dad Remote Management` rule. All four become trivial follow-up
  decisions after the streamlined surface is verified working.
- **`sshd_config` hardening** (LogLevel, StrictModes, AllowGroups,
  removing the dead HostKey reference). That's the separate
  `mamawork-ssh-hardening` packet, still queued.
- **`C:\Users\DadAdmin\.ssh\authorized_keys`** per-user ACL gap
  (the Step-4 mirror failure from the bootstrap packet). Different
  file, different ACL surface, different decision; tracked as
  `mamawork-dadadmin-per-user-authorized-keys-acl-gap` blocker.
- **Network identity registry cleanup** (the stale
  `Bob's Internet 2` Public profile). Future
  `mamawork-network-list-registry-cleanup` packet.
- **WoL per-device wake policy** (`powercfg /deviceenablewake`).
  Future small packet.
- **Cloudflare / WARP / Tunnel cutover**, **Tailscale activation**,
  **BitLocker**, **Secure Boot**, **TPM** — all deferred per
  established operator priorities.
- **Kid Windows accounts** (`ahnie`, `axelp`, `ilage`, `wynst`),
  **Microsoft Account `jeffr`** privileges (stays admin),
  **built-in `Administrator`** (stays disabled). Unchanged.
- **MAMAWORK switch from host-static IP to DHCP** — separate
  approved-deferred packet, runs after admin is stable.

## Verified Current State (as of 2026-05-15T00:15:00Z)

```text
LAN reachability (MacBook -> MAMAWORK):
  TCP/3389  Succeeded (Jefahnierocks RDP LAN TCP 3389 rule, Private)
  TCP/22    Succeeded (Jefahnierocks SSH LAN TCP 22 rule, Private,
                       added by inbound-blackhole remediation;
                       Dad Remote Management also still Allow Any
                       TCP 22 192.168.0.0/24 from morning session)

RDP from MacBook:                 Working end-to-end (kicks active console user)

SSH from MacBook (jeffr/DadAdmin/Administrator):
                                  Permission denied (publickey)
                                  even though the correct key
                                  (SHA256:qilvkR7/...) is offered
                                  via the 1P SSH agent, and the
                                  matching public-key line is in
                                  administrators_authorized_keys
                                  per the bootstrap apply evidence.

Strongly-suspected root cause:    Windows OpenSSH's hardcoded ACL
                                  check on administrators_authorized_keys
                                  rejects the file silently
                                  (owner != Administrators, or DACL
                                  grants a non-{Administrators,SYSTEM}
                                  principal). sshd_config StrictModes
                                  no does NOT disable that check.
                                  Phase 1 of this packet captures
                                  the actual ACL/owner/encoding to
                                  confirm.

Accounts (intake-derived; not yet re-verified post-streamline):
  Administrator         disabled (built-in)
  ahnie                 enabled  (kid MS Account; not admin)
  axelp                 enabled  (kid MS Account; not admin)
  ilage                 enabled  (kid MS Account; not admin)
  wynst                 enabled  (kid MS Account; not admin)
  DadAdmin              enabled  (local; admin)         <- streamline target
  jeffr                 enabled  (MS Account; admin)    <- canonical admin

Firewall (current):
  Jefahnierocks RDP LAN TCP 3389        Allow Private TCP 3389  192.168.0.0/24
  Jefahnierocks RDP LAN UDP 3389        Allow Private UDP 3389  192.168.0.0/24
  Jefahnierocks SSH LAN TCP 22          Allow Private TCP 22    192.168.0.0/24  <- canonical
  Dad Remote Management                 Allow Any     TCP 22    192.168.0.0/24  <- streamline target
  Remote Assistance (DCOM-In)           Allow Domain  TCP 135   Any              (dormant; no domain join)

Authorized keys (file content per bootstrap evidence):
  C:\ProgramData\ssh\administrators_authorized_keys
    SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk DadAdmin_WinNet (ED25519)
        <- streamline target; private half exists nowhere accessible
    SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin (ED25519)
        <- canonical; private half in MacBook 1P SSH agent

  C:\Users\jeffr\.ssh\authorized_keys.txt        <- inventory only this packet
  C:\Users\DadAdmin.MamaWork\                    <- inventory only this packet
  C:\Users\DadAdmin\.ssh\authorized_keys         <- separate per-user ACL gap; not in scope
```

## Apply Procedure (operator-side on MAMAWORK)

Open an **elevated PowerShell 7+** session on MAMAWORK as
`MAMAWORK\jeffr`. The full script below runs as one operator
session; sub-phases are explicit and the script HARD-STOPS before
proceeding past the ACL/BOM repair if that core fix fails.

### Single elevated PowerShell 7+ script

```powershell
# Jefahnierocks MAMAWORK Admin Surface Streamline - 2026-05-14
# Run from Administrator PowerShell 7+ on MAMAWORK as MAMAWORK\jeffr.

$ErrorActionPreference = 'Stop'

$ExpectedHostname = 'MAMAWORK'
$EvidenceDir = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$SlotDir = Join-Path $EvidenceDir "mamawork-admin-streamline-$Timestamp"
$EvidencePath = Join-Path $SlotDir 'streamline.txt'

New-Item -ItemType Directory -Path $SlotDir -Force | Out-Null

function Write-Evidence {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [AllowEmptyString()]
    [AllowNull()]
    [string]$Message
  )
  process {
    Add-Content -Path $EvidencePath -Value $Message
    Write-Host $Message
  }
}

Write-Evidence "timestamp: $(Get-Date -Format o)"
Write-Evidence "scope: MAMAWORK admin surface streamline (SSH lockout repair + legacy cleanups)"
Write-Evidence "slot_dir: $SlotDir"

if ((hostname) -ne $ExpectedHostname) {
  throw "Unexpected hostname. Expected $ExpectedHostname."
}

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $IsAdmin) { throw 'This script must run from Administrator PowerShell.' }

Write-Evidence "operator: $env:USERDOMAIN\$env:USERNAME"
Write-Evidence "elevation: $IsAdmin"

# ============================================================
# PHASE 1 — Read-only diagnostic + snapshot (no side effects)
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 1 — READ-ONLY DIAGNOSTIC ==='

$F = 'C:\ProgramData\ssh\administrators_authorized_keys'

if (-not (Test-Path $F)) {
  Write-Evidence "phase_1_error: $F not present; this packet assumes the bootstrap apply ran. STOPPING."
  throw "administrators_authorized_keys missing"
}

# Snapshot file content + ACL
Copy-Item -Path $F -Destination "$SlotDir\admin_authorized_keys.before"
Get-Acl $F | Format-List | Out-File "$SlotDir\admin_authorized_keys.acl.before.txt"

# Capture owner SID + name
$acl = Get-Acl $F
$ownerSid = $acl.GetOwner([Security.Principal.SecurityIdentifier])
$ownerName = $acl.Owner
Write-Evidence "owner_sid: $ownerSid"
Write-Evidence "owner_name: $ownerName"

# Capture DACL principals
Write-Evidence 'dacl_principals:'
$acl.Access | ForEach-Object {
  Write-Evidence "  $($_.IdentityReference) -> $($_.FileSystemRights) ($($_.AccessControlType))"
}

# BOM check (first 4 bytes)
$bytes = [IO.File]::ReadAllBytes($F) | Select-Object -First 4
$bomHex = ($bytes | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
$hasBOM = ($bytes.Count -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
Write-Evidence "file_first_4_bytes_hex: $bomHex"
Write-Evidence "has_utf8_bom: $hasBOM"

# sshd -T effective config + Match-block check
$sshdExe = 'C:\Windows\System32\OpenSSH\sshd.exe'
if (Test-Path $sshdExe) {
  & $sshdExe -T 2>&1 | Out-File "$SlotDir\sshd_T_effective.txt"
  $authKeyDirectives = Get-Content "$SlotDir\sshd_T_effective.txt" | Select-String -Pattern '^(authorizedkeysfile|authorizedkeyscommand|match)'
  Write-Evidence 'sshd_T_relevant:'
  $authKeyDirectives | ForEach-Object { Write-Evidence "  $_" }
} else {
  Write-Evidence "sshd_T_skipped: $sshdExe not present"
}

# Parse sshd_config for Match blocks (sshd -T only shows effective, not the source Match)
$sshdConfig = 'C:\ProgramData\ssh\sshd_config'
if (Test-Path $sshdConfig) {
  Copy-Item -Path $sshdConfig -Destination "$SlotDir\sshd_config.before"
  $matchBlocks = Get-Content $sshdConfig | Select-String -Pattern '^\s*Match\s'
  if ($matchBlocks) {
    Write-Evidence 'sshd_config_Match_blocks_present:'
    $matchBlocks | ForEach-Object { Write-Evidence "  $_" }
  } else {
    Write-Evidence 'sshd_config_Match_blocks_present: none'
  }
}

# Recent OpenSSH/Operational events about pubkey / AuthorizedKeysFile
try {
  $logEvents = Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 200 -ErrorAction Stop |
    Where-Object { $_.Message -match 'AuthorizedKeysFile|pubkey|administrators_authorized_keys|publickey|authentication failed' } |
    Select-Object TimeCreated, Id, LevelDisplayName, @{N='Message';E={ $_.Message -replace "`r`n", ' | ' }}
  $logEvents | Export-Csv "$SlotDir\openssh_operational_recent.csv" -NoTypeInformation
  Write-Evidence "openssh_operational_relevant_events_captured: $($logEvents.Count) (see openssh_operational_recent.csv)"
} catch {
  Write-Evidence "openssh_operational_capture_failed: $($_.Exception.Message)"
}

# DadAdmin account info
$dadAdminUser = Get-LocalUser -Name 'DadAdmin' -ErrorAction SilentlyContinue
if ($dadAdminUser) {
  Write-Evidence "dadadmin_user: Enabled=$($dadAdminUser.Enabled) SID=$($dadAdminUser.SID) Description='$($dadAdminUser.Description)' LastLogon=$($dadAdminUser.LastLogon)"
} else {
  Write-Evidence "dadadmin_user: NOT PRESENT"
}

# Pre-flight: anything running as DadAdmin?
$dadServices = Get-CimInstance -Class Win32_Service -ErrorAction SilentlyContinue |
  Where-Object { $_.StartName -match 'DadAdmin' }
$dadTasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
  Where-Object { $_.Principal.UserId -match 'DadAdmin' }
Write-Evidence "services_as_dadadmin: $($dadServices.Count)"
$dadServices | ForEach-Object { Write-Evidence "  service: $($_.Name) ($($_.DisplayName)) state=$($_.State)" }
Write-Evidence "scheduled_tasks_as_dadadmin: $($dadTasks.Count)"
$dadTasks | ForEach-Object { Write-Evidence "  task: $($_.TaskName) ($($_.TaskPath)) state=$($_.State)" }

if ($dadServices.Count -gt 0 -or $dadTasks.Count -gt 0) {
  Write-Evidence "phase_4_disable_dadadmin: WILL SKIP (something runs as DadAdmin; manual review required)"
  $script:skipDisableDadAdmin = $true
} else {
  $script:skipDisableDadAdmin = $false
}

# Dad Remote Management firewall rule current state
$drmRule = Get-NetFirewallRule -DisplayName 'Dad Remote Management' -ErrorAction SilentlyContinue
if ($drmRule) {
  $drmFilter = $drmRule | Get-NetFirewallAddressFilter
  $drmPort = $drmRule | Get-NetFirewallPortFilter
  Write-Evidence "dad_remote_management_rule: Enabled=$($drmRule.Enabled) Profile=$($drmRule.Profile) Action=$($drmRule.Action) Proto=$($drmPort.Protocol) LocalPort=$($drmPort.LocalPort) RemoteAddress=$($drmFilter.RemoteAddress)"
} else {
  Write-Evidence "dad_remote_management_rule: NOT PRESENT"
}

# authorized_keys.txt inventory (no content to evidence)
$txtPath = 'C:\Users\jeffr\.ssh\authorized_keys.txt'
if (Test-Path $txtPath) {
  $txtItem = Get-Item $txtPath
  Copy-Item -Path $txtPath -Destination "$SlotDir\jeffr_authorized_keys_txt.captured"
  $firstLineType = (Get-Content $txtPath -TotalCount 1 -ErrorAction SilentlyContinue) -replace '^\s*([^\s]+).*$', '$1'
  Write-Evidence "authorized_keys_txt: present size=$($txtItem.Length) bytes first_token='$firstLineType' last_write=$($txtItem.LastWriteTime)"
} else {
  Write-Evidence "authorized_keys_txt: NOT PRESENT"
}

# DadAdmin.MamaWork profile inventory
$dadProf = 'C:\Users\DadAdmin.MamaWork'
if (Test-Path $dadProf) {
  Get-ChildItem -Path $dadProf -Recurse -Force -ErrorAction SilentlyContinue |
    Select-Object FullName, Length, LastWriteTime, Mode |
    Export-Csv "$SlotDir\dadadmin_mamawork_profile_inventory.csv" -NoTypeInformation
  $profEntries = (Import-Csv "$SlotDir\dadadmin_mamawork_profile_inventory.csv" -ErrorAction SilentlyContinue).Count
  Write-Evidence "dadadmin_mamawork_profile_dir: present entries=$profEntries (inventory in dadadmin_mamawork_profile_inventory.csv)"
} else {
  Write-Evidence "dadadmin_mamawork_profile_dir: NOT PRESENT"
}

# ============================================================
# PHASE 2 — Decide ACL/BOM fix
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 2 — DECIDE ACL/BOM FIX ==='

$expectedPrincipals = @('NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators')
$badPrincipals = $acl.Access | Where-Object {
  $expectedPrincipals -notcontains [string]$_.IdentityReference
}

$fixAclOwner = ($ownerName -notmatch 'Administrators$' -and $ownerName -notmatch 'SYSTEM$')
$fixAclDacl  = ($badPrincipals.Count -gt 0)
$fixBom      = $hasBOM

Write-Evidence "fix_acl_owner_needed: $fixAclOwner (owner='$ownerName')"
Write-Evidence "fix_acl_dacl_needed:  $fixAclDacl"
if ($fixAclDacl) {
  Write-Evidence 'fix_acl_dacl_bad_principals:'
  $badPrincipals | ForEach-Object { Write-Evidence "  $($_.IdentityReference) -> $($_.FileSystemRights) ($($_.AccessControlType))" }
}
Write-Evidence "fix_bom_needed:       $fixBom"

# ============================================================
# PHASE 3 — Apply ACL/BOM repair (HARD STOP on failure)
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 3 — APPLY ACL / BOM REPAIR ==='

try {
  if ($fixBom) {
    Write-Evidence 'phase_3_bom_strip: rewriting file without BOM'
    $lines = [IO.File]::ReadAllLines($F)
    [IO.File]::WriteAllLines($F, $lines, [System.Text.UTF8Encoding]::new($false))
  } else {
    Write-Evidence 'phase_3_bom_strip: skipped (no BOM)'
  }

  if ($fixAclOwner -or $fixAclDacl) {
    Write-Evidence 'phase_3_acl_repair: applying icacls'
    & icacls $F /inheritance:r 2>&1 | Out-File "$SlotDir\icacls.txt" -Append
    & icacls $F /grant 'SYSTEM:F' 2>&1 | Out-File "$SlotDir\icacls.txt" -Append
    & icacls $F /grant 'Administrators:F' 2>&1 | Out-File "$SlotDir\icacls.txt" -Append
    & icacls $F /setowner Administrators 2>&1 | Out-File "$SlotDir\icacls.txt" -Append
  } else {
    Write-Evidence 'phase_3_acl_repair: skipped (owner + DACL already canonical)'
  }

  # Re-verify ACL state
  $aclAfter = Get-Acl $F
  $ownerAfter = $aclAfter.Owner
  $badAfter = $aclAfter.Access | Where-Object { $expectedPrincipals -notcontains [string]$_.IdentityReference }

  Write-Evidence "post_acl_owner: $ownerAfter"
  Write-Evidence 'post_dacl_principals:'
  $aclAfter.Access | ForEach-Object { Write-Evidence "  $($_.IdentityReference) -> $($_.FileSystemRights) ($($_.AccessControlType))" }

  if ($ownerAfter -notmatch 'Administrators$' -and $ownerAfter -notmatch 'SYSTEM$') {
    throw "ACL repair did not set owner to Administrators (still $ownerAfter)"
  }
  if ($badAfter.Count -gt 0) {
    throw "ACL repair did not narrow DACL (still has principals other than {Administrators, SYSTEM})"
  }
  Write-Evidence 'phase_3_status: ACL/BOM repair succeeded'
} catch {
  Write-Evidence "phase_3_failed: $($_.Exception.Message)"
  Write-Evidence "STOPPING. Legacy cleanups will NOT run because the core SSH fix is not in place."
  throw
}

# ============================================================
# PHASE 4 — Remove legacy DadAdmin_WinNet line
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 4 — REMOVE LEGACY DadAdmin_WinNet LINE ==='

$linesBefore = [IO.File]::ReadAllLines($F)
$linesAfter = $linesBefore | Where-Object {
  ($_ -notmatch '\bDadAdmin_WinNet\b') -and ($_.Trim() -ne '' -or $_ -eq '')
}
$removed = $linesBefore.Count - $linesAfter.Count

[IO.File]::WriteAllLines($F, $linesAfter, [System.Text.UTF8Encoding]::new($false))

# Re-apply ACL (file rewrite may have preserved or reset DACL; idempotent re-apply)
& icacls $F /inheritance:r 2>&1 | Out-Null
& icacls $F /grant 'SYSTEM:F' 2>&1 | Out-Null
& icacls $F /grant 'Administrators:F' 2>&1 | Out-Null
& icacls $F /setowner Administrators 2>&1 | Out-Null

Write-Evidence "dadadmin_winnet_lines_removed: $removed"

# Post-content snapshot + fingerprint enumeration
Copy-Item -Path $F -Destination "$SlotDir\admin_authorized_keys.after"
Get-Content $F | ForEach-Object {
  if ($_ -match '^\s*ssh-') { $_ | ssh-keygen -lf - 2>$null }
} | Out-File "$SlotDir\admin_authorized_keys.fingerprints.after.txt"
Write-Evidence 'post_admin_authorized_keys_fingerprints:'
Get-Content "$SlotDir\admin_authorized_keys.fingerprints.after.txt" | ForEach-Object { Write-Evidence "  $_" }

# ============================================================
# PHASE 5 — Disable DadAdmin local user
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 5 — DISABLE DadAdmin LOCAL USER ==='

if ($script:skipDisableDadAdmin) {
  Write-Evidence 'phase_5_skipped: services or scheduled tasks run as DadAdmin (see Phase 1 capture); manual review required'
} elseif (-not $dadAdminUser) {
  Write-Evidence 'phase_5_skipped: DadAdmin local user not present'
} else {
  try {
    Disable-LocalUser -Name 'DadAdmin' -ErrorAction Stop
    $after = Get-LocalUser -Name 'DadAdmin'
    Write-Evidence "phase_5_status: disabled (Enabled=$($after.Enabled))"
  } catch {
    Write-Evidence "phase_5_failed: $($_.Exception.Message); CONTINUING with subsequent phases"
  }
}

# ============================================================
# PHASE 6 — Disable Dad Remote Management firewall rule
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 6 — DISABLE Dad Remote Management RULE ==='

if (-not $drmRule) {
  Write-Evidence 'phase_6_skipped: rule not present'
} else {
  try {
    Disable-NetFirewallRule -DisplayName 'Dad Remote Management' -ErrorAction Stop
    $after = Get-NetFirewallRule -DisplayName 'Dad Remote Management'
    Write-Evidence "phase_6_status: Enabled=$($after.Enabled)"
  } catch {
    Write-Evidence "phase_6_failed: $($_.Exception.Message); CONTINUING"
  }
}

# ============================================================
# PHASE 7 — Final state snapshot
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 7 — FINAL STATE SNAPSHOT ==='

Write-Evidence 'inbound_rules_for_22_and_3389:'
@('Jefahnierocks RDP LAN TCP 3389',
  'Jefahnierocks RDP LAN UDP 3389',
  'Jefahnierocks SSH LAN TCP 22',
  'Dad Remote Management') | ForEach-Object {
    $rule = Get-NetFirewallRule -DisplayName $_ -ErrorAction SilentlyContinue
    if ($rule) {
      $pf = $rule | Get-NetFirewallPortFilter
      $af = $rule | Get-NetFirewallAddressFilter
      Write-Evidence "  $($rule.DisplayName): Enabled=$($rule.Enabled) Profile=$($rule.Profile) Action=$($rule.Action) Proto=$($pf.Protocol) LocalPort=$($pf.LocalPort) RemoteAddress=$($af.RemoteAddress)"
    } else {
      Write-Evidence "  $_ : NOT PRESENT"
    }
}

Write-Evidence 'local_admins_after:'
Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue |
  ForEach-Object { Write-Evidence "  $($_.ObjectClass)  $($_.Name)  Enabled?=(see Get-LocalUser)" }
Get-LocalUser -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -in @('Administrator','DadAdmin','jeffr') } |
  ForEach-Object { Write-Evidence "  Get-LocalUser: $($_.Name) Enabled=$($_.Enabled) SID=$($_.SID)" }

Write-Evidence ''
Write-Evidence "status: completed Phases 1-7 on MAMAWORK"
Write-Evidence "evidence_slot: $SlotDir"
Write-Evidence ''
Write-Evidence 'NEXT: hand back to system-config for Phase 8 (MacBook-side real auth probe).'
```

### Phase 8 — MacBook-side real auth probe (system-config runs after evidence return)

After the operator returns the evidence, `system-config` runs from
the MacBook:

```bash
ssh -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub \
    -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
    -o IdentitiesOnly=yes \
    -o PreferredAuthentications=publickey \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o ControlMaster=no -o ControlPath=none \
    -o HostKeyAlias=192.168.0.101 \
    jeffr@mamawork.home.arpa 'hostname; whoami'
```

Expected: `MAMAWORK` / `jeffr`.

If PASS, the apply record records status `applied` and SSH end-to-end
admin is operational. If FAIL, status stays
`applied-pending-auth-verification` and a follow-up diagnostic
packet is required (most likely a `Match Group administrators`
block surfaced by Phase 1's `sshd -T` capture).

## Rollback

### Rollback Phase 6 (re-enable Dad Remote Management)

```powershell
Enable-NetFirewallRule -DisplayName 'Dad Remote Management'
```

### Rollback Phase 5 (re-enable DadAdmin)

```powershell
Enable-LocalUser -Name 'DadAdmin'
```

### Rollback Phase 4 (restore legacy DadAdmin_WinNet line)

```powershell
$SLOT = '<slot-dir-from-Phase-1>'
Copy-Item -Force -Path "$SLOT\admin_authorized_keys.before" `
          -Destination 'C:\ProgramData\ssh\administrators_authorized_keys'
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /inheritance:r
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /grant 'SYSTEM:F'
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /grant 'Administrators:F'
```

### Rollback Phase 3 (revert ACL/BOM)

Rarely useful — Phase 3 was meant to fix a broken state. To revert
deliberately:

```powershell
# Restore ACL via captured listing in $SLOT\admin_authorized_keys.acl.before.txt
# (manual; no scripted reversal because Get-Acl output is descriptive, not directly Set-Acl-able)

# Re-introduce a BOM if Phase 3 stripped one (almost never wanted):
$F = 'C:\ProgramData\ssh\administrators_authorized_keys'
$bom = [byte[]](0xEF, 0xBB, 0xBF)
$content = [IO.File]::ReadAllBytes($F)
[IO.File]::WriteAllBytes($F, $bom + $content)
```

## Required Approval Phrase

```text
I approve applying the MAMAWORK Admin Surface Streamline packet
live now on MAMAWORK. From an elevated PowerShell 7+ session as
MAMAWORK\jeffr, run the documented multi-phase script. Phase 1
read-only: capture Get-Acl + owner SID + first-4-bytes BOM check
on C:\ProgramData\ssh\administrators_authorized_keys, sshd -T
effective config, sshd_config Match blocks if any,
OpenSSH/Operational recent events for AuthorizedKeysFile/pubkey,
DadAdmin local-user state, services/scheduled-tasks running as
DadAdmin, Dad Remote Management firewall rule state, and read-only
inventory of C:\Users\jeffr\.ssh\authorized_keys.txt and
C:\Users\DadAdmin.MamaWork\. Phase 2: decide ACL/BOM fix from
Phase 1 findings. Phase 3 (HARD-STOP on failure): apply
icacls /inheritance:r /grant SYSTEM:F /grant Administrators:F
/setowner Administrators to administrators_authorized_keys if the
owner or DACL is not in the canonical {Administrators, SYSTEM}
shape; rewrite the file via UTF-8-no-BOM if Phase 1 found a BOM;
verify post-state owner is Administrators and DACL has only
{Administrators, SYSTEM}. Phase 4: remove the legacy
DadAdmin_WinNet public-key line from
administrators_authorized_keys and re-apply the canonical ACL.
Phase 5: Disable-LocalUser DadAdmin (do NOT delete; account stays
intact); skip Phase 5 if Phase 1 found any service or scheduled
task running as DadAdmin. Phase 6: Disable-NetFirewallRule 'Dad
Remote Management' (do NOT remove the rule; preserve audit trail).
Phase 7: snapshot final state (firewall rules, admin group
membership, local-user Enabled flags). Do NOT delete the DadAdmin
local user. Do NOT delete the 'Dad Remote Management' rule. Do
NOT delete or modify C:\Users\jeffr\.ssh\authorized_keys.txt. Do
NOT delete or modify C:\Users\DadAdmin.MamaWork\. Do NOT touch
sshd_config or sshd_config.d/. Do NOT touch the
C:\Users\DadAdmin\.ssh\authorized_keys per-user file (separate ACL
gap). Do NOT touch HKLM NetworkList\Profiles. Do NOT touch RDP /
WinRM / PSRemoting / accounts other than DadAdmin / kid accounts
/ Microsoft Account jeffr / BitLocker / Secure Boot / TPM /
Defender / ASR / powercfg / NIC wake / Cloudflare / WARP /
cloudflared / Tailscale / OPNsense / DNS / DHCP / 1Password. Then
return the evidence slot for system-config to ingest. system-config
will then run the MacBook-side real auth probe
(ssh -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub
 -o IdentityAgent=$HOME/.1password-ssh-agent.sock
 -o IdentitiesOnly=yes -o PreferredAuthentications=publickey
 -o BatchMode=yes jeffr@mamawork.home.arpa 'hostname; whoami')
which must return MAMAWORK / jeffr for the packet to declare
applied.
```

## Evidence Template (operator hand-back)

```text
timestamp:
operator:                                 MAMAWORK\jeffr
elevation:                                yes/no
slot_dir:                                 C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-admin-streamline-<timestamp>\

PHASE 1 findings:
  owner_name:                             <e.g. MAMAWORK\jeffr or BUILTIN\Administrators>
  dacl_principals:                        <list>
  has_utf8_bom:                           True/False
  sshd_config_Match_blocks_present:       none / <list>
  openssh_operational_relevant_events:    <count> (csv attached)
  dadadmin_user:                          Enabled=True/False SID=... LastLogon=...
  services_as_dadadmin:                   <count> + list
  scheduled_tasks_as_dadadmin:            <count> + list
  dad_remote_management_rule:             Enabled=True/False Profile=... Proto=TCP LocalPort=22 RemoteAddress=...
  authorized_keys_txt:                    present/absent (size, first_token, last_write)
  dadadmin_mamawork_profile_dir:          present/absent (entry count, csv attached)

PHASE 3 ACL/BOM repair:
  fix_acl_owner_needed:                   True/False
  fix_acl_dacl_needed:                    True/False
  fix_bom_needed:                         True/False
  phase_3_status:                         "ACL/BOM repair succeeded" | "STOPPED <reason>"
  post_acl_owner:                         <expected: ...\Administrators>
  post_dacl_principals:                   <expected: SYSTEM + Administrators only>

PHASE 4 legacy line removal:
  dadadmin_winnet_lines_removed:          <expected: 1>
  post_admin_authorized_keys_fingerprints:
    SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin (ED25519)
    (no DadAdmin_WinNet line)

PHASE 5 DadAdmin disable:
  phase_5_status:                         disabled / skipped (<reason>) / failed (<reason>)

PHASE 6 Dad Remote Management disable:
  phase_6_status:                         Enabled=False / skipped / failed

PHASE 7 final-state snapshot:
  rule: Jefahnierocks RDP LAN TCP 3389    Enabled=True  Profile=Private TCP 3389 192.168.0.0/24
  rule: Jefahnierocks RDP LAN UDP 3389    Enabled=True  Profile=Private UDP 3389 192.168.0.0/24
  rule: Jefahnierocks SSH LAN TCP 22      Enabled=True  Profile=Private TCP 22   192.168.0.0/24
  rule: Dad Remote Management             Enabled=False (disabled this packet)
  local admins (Enabled): jeffr; Administrator (disabled-builtin); DadAdmin (disabled this packet)

credentials_in_repo_chat_argv:            None
remaining_blockers:                       Phase 8 (MacBook-side real auth probe) pending system-config
```

Do NOT paste passwords, private keys, full key bodies (fingerprints
only are non-secret and OK), 1Password item UUIDs / secret-reference
URIs, Wi-Fi PSKs, BitLocker recovery material, RDP credential blobs,
or any secret value.

## Boundary Assertions

After this packet applies, the following are **unchanged**:

- `sshd_config`, `sshd_config.d/`. Hardening is the separate
  `mamawork-ssh-hardening` packet.
- `C:\Users\jeffr\.ssh\authorized_keys.txt` content (read-only
  inventory only; no edit, no delete).
- `C:\Users\DadAdmin.MamaWork\` directory tree (read-only inventory
  only; no edit, no delete).
- `C:\Users\DadAdmin\.ssh\authorized_keys` per-user file (separate
  ACL gap; out of scope here).
- The `DadAdmin` local user is DISABLED, not deleted. SID + profile
  preserved. Re-enable via `Enable-LocalUser` if needed.
- The `Dad Remote Management` firewall rule is DISABLED, not
  removed. Re-enable via `Enable-NetFirewallRule` if needed.
- The legacy `DadAdmin_WinNet` line is REMOVED from
  `administrators_authorized_keys`. Snapshot in
  `admin_authorized_keys.before` allows reinstating if ever
  necessary (which is very unlikely; no working private half exists).
- Microsoft Account `jeffr` (admin), built-in `Administrator`
  (disabled), kid accounts (`ahnie`, `axelp`, `ilage`, `wynst`) -
  untouched.
- RDP host-side state (`Jefahnierocks RDP LAN TCP/UDP 3389`,
  TermService Automatic, `fDenyTSConnections=0`, NLA, no
  built-in Remote Desktop group enabled) - unchanged.
- `HKLM\Software\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*`
  registry entries (stale `Bob's Internet 2` Public profile stays;
  future small packet).
- `powercfg`, NIC wake-policy, Defender, ASR, BitLocker, Secure
  Boot, TPM, WinRM, PSRemoting, Cloudflare, WARP, `cloudflared`,
  Tailscale, OPNsense, DNS, DHCP, 1Password (no `op` runs on
  MAMAWORK).
- The MAMAWORK host-static-vs-DHCP question (separate
  approved-deferred packet).

## Sequencing With Other Packets

This packet supersedes / closes the following blockers in
`current-status.yaml`:

- `mamawork-administrators-authorized-keys-not-honored` (root cause
  identified + fixed)
- `mamawork-legacy-dadadmin-winnet-key-removal-pending` (line
  removed)
- `mamawork-ssh-end-to-end-verification-pending` (closes when Phase 8
  passes)

Independent of this packet (remain open):

- `mamawork-dadadmin-per-user-authorized-keys-acl-gap` (different
  file)
- `mamawork-network-identity-name-still-unidentified` (separate
  packet)
- `mamawork-fedora-top-probes-deferred` (waits on fedora-top online)
- `mamawork-ssh-conf-d-on-macbook-pending` (chezmoi packet, follows)
- `mamawork-operator-questions` (intake answers)
- WARP / Tunnel / Tailscale / BitLocker / Secure Boot decisions
- `mamawork-switch-to-dhcp-source-of-truth` (deferred)

After this packet's Phase 8 passes, three small follow-ups become
drafteable:

1. **`mamawork-dadadmin-deletion-packet`** — delete the disabled
   `DadAdmin` user + the `C:\Users\DadAdmin.MamaWork\` profile dir
   (if Phase 1 inventory confirms dead). Operator-blessing-stamp on
   the inventory CSV.
2. **`mamawork-authorized-keys-txt-resolution-packet`** — based on
   Phase 1 inventory, decide what to do with
   `C:\Users\jeffr\.ssh\authorized_keys.txt`.
3. **`macbook-ssh-conf-d-streamline-packet`** — chezmoi-managed
   `~/.ssh/conf.d/mamawork.conf` and `~/.ssh/conf.d/fedora-top.conf`,
   plus the `mamawork_admin.1password.pub` already on disk.

## Related

- [mamawork-ssh-key-bootstrap-packet-2026-05-14.md](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md) -
  the bootstrap that installed the new key but did not verify
  Windows OpenSSH would honor the file. This packet fixes that.
- [mamawork-ssh-key-bootstrap-apply-2026-05-14.md](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md) -
  the apply record whose v0.2.0 surfaced the auth-rejected
  finding.
- [mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md) -
  the LAN reachability fix that preceded this one.
- [mamawork-lan-rdp-implementation-2026-05-14.md](./mamawork-lan-rdp-implementation-2026-05-14.md) -
  RDP host-side packet; untouched by this packet.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
