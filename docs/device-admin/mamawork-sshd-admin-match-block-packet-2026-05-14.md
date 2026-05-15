---
title: MAMAWORK sshd Admin Match Block Packet - 2026-05-14
category: operations
component: device_admin
status: applied
version: 0.2.0
last_updated: 2026-05-15
tags: [device-admin, mamawork, windows, openssh, sshd-config, match-block, admin-fix]
priority: highest
---

# MAMAWORK sshd Admin Match Block Packet - 2026-05-14

Applied 2026-05-14T16:12:32-08:00. See
[mamawork-sshd-admin-match-block-apply-2026-05-14.md](./mamawork-sshd-admin-match-block-apply-2026-05-14.md)
and [handback-mamawork-sshd-admin-match-block-2026-05-14.md](./handback-mamawork-sshd-admin-match-block-2026-05-14.md).
MacBook real-auth verification passed with the Windows-compatible
proof command `cmd /c "hostname && whoami"`, returning `MamaWork`
and `mamawork\jeffr`. The original `hostname; whoami` success form
below is preserved as historical packet text but should not be used
for future Windows proof commands.

Closes the MAMAWORK SSH lockout by restoring the standard Windows
OpenSSH `Match Group administrators` block to `sshd_config`. Without
this block, sshd consults the per-user `.ssh/authorized_keys` file
for **all** users (including admins) and never reads the system-wide
`C:\ProgramData\ssh\administrators_authorized_keys`. The canonical
admin key is in the system-wide file but sshd has not been
consulting it.

The
[`mamawork-admin-streamline` apply](./mamawork-admin-streamline-apply-2026-05-14.md)
surfaced this root cause through Phase 1's evidence
(`sshd_config_Match_blocks_present: none` plus `sshd -T` showing
only the default `.ssh/authorized_keys`). The three previously-
hypothesized causes (ACL, ownership, BOM) were not present.

This packet was **operator-applied on MAMAWORK** from an elevated
PowerShell 7+ session. The closing success criterion was a real
MacBook SSH auth probe; current Windows-compatible proof command is
`ssh mamawork 'cmd /c "hostname && whoami"'`, expected to return
`MamaWork` / `mamawork\jeffr`.

## Scope

In scope:

1. **Read-only snapshot** of `C:\ProgramData\ssh\sshd_config`,
   `sshd_T` effective config, and the current
   `OpenSSH/Operational` event-log tail (unfiltered; addresses the
   handback's surprise #2 about the 0-events-with-keyword-filter
   anomaly).
2. **Defensive re-check** that no `Match Group administrators`
   block currently exists in `sshd_config`. If one is present
   already (operator may have added one manually since the
   streamline apply at 15:44), Phase 3 STOPS — running the same
   block twice is not desired.
3. **Append the standard Windows OpenSSH Match block** to
   `sshd_config`:
   ```text
   Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
   ```
   Form matches the Microsoft-shipped `sshd_config_default`
   template. `__PROGRAMDATA__` is a literal token Windows OpenSSH
   replaces with `C:\ProgramData` at parse time.
4. **`sshd -t` syntax validation** of the edited file. **HARD-STOP**
   on fail — sshd_config syntax errors break the service on next
   reload. The pre-edit snapshot is restored automatically if
   syntax validation fails.
5. **`Restart-Service sshd`** to make the new config live. Does
   NOT disturb the active console user (the wife). Does NOT affect
   RDP. Briefly drops any in-flight SSH sessions (currently none
   because authentication is failing for all admin clients).
6. **Post-restart `sshd -T` capture** to confirm the change is
   live (the global AuthorizedKeysFile still shows
   `.ssh/authorized_keys` because Match blocks aren't reflected
   in the unconditional `-T` view, but the Match-block presence
   is verified via `Select-String` on the file).
7. **Evidence captured** to
   `C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-sshd-admin-match-block-<timestamp>\`.
8. **Closing real auth probe** (system-config side, on the MacBook):
   `ssh mamawork 'cmd /c "hostname && whoami"'` expected to return
   `MamaWork` / `mamawork\jeffr`.

Out of scope:

- **Broader `sshd_config` hardening**: `LogLevel DEBUG3 -> INFO`,
  `StrictModes no -> yes`, `AllowUsers`/`AllowGroups`, removing
  the dead `HostKey ssh_host_dsa_key` reference, etc. All deferred
  to the future `mamawork-ssh-hardening` packet. This packet does
  the **minimum** required to restore the admin auth path.
- **Refactoring `sshd_config` to use an `Include` directive +
  drop-in directory** (the fedora-top pattern). Adds a step that
  isn't required for the fix; defer to `mamawork-ssh-hardening`.
- **`DadAdmin` disable** (held back by OneDrive scheduled tasks
  per the streamline apply's Phase 5 self-skip; separate decision).
- **`authorized_keys.txt` resolution** (separate small follow-up).
- **`DadAdmin.MamaWork\` profile dir resolution** (separate small
  follow-up).
- **Network identity registry cleanup** (`Bob's Internet 2`
  Public profile).
- **All HARD-NOT-TOUCH boundaries**: `administrators_authorized_keys`
  content (already canonical post-streamline; this packet does NOT
  edit it), `C:\Users\*\.ssh\` per-user files, accounts/groups
  (including the wife's `ahnie` account which is intentional admin
  per operator clarification), kid accounts, `jeffr` MS Account,
  built-in `Administrator`, RDP, WinRM, PSRemoting, BitLocker,
  Secure Boot, TPM, Defender, ASR, powercfg, NIC wake, Cloudflare,
  WARP, `cloudflared`, Tailscale, OPNsense, DNS, DHCP, 1Password.

## Verified Current State (post-streamline, 2026-05-14T15:44:01-08:00)

```text
administrators_authorized_keys:
  owner:                BUILTIN\Administrators (canonical)
  DACL:                 NT AUTHORITY\SYSTEM:F + BUILTIN\Administrators:F (canonical)
  BOM:                  none
  content:              single line
                        SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin

sshd_config (per handback):
  Match blocks:         none
  Include directives:   none
  sshd_config.d/ dir:   NOT PRESENT
  effective sshd -T:    authorizedkeysfile .ssh/authorized_keys
                        (no AuthorizedKeysFile override for admins)
  LogLevel:             DEBUG3 (verbose; future hardening lowers to INFO)
  StrictModes:          no (relaxed; future hardening may flip; not in scope here)
  PasswordAuthentication no
  PubkeyAuthentication yes

sshd service:           Running, StartType=Automatic, StartName=LocalSystem

firewall (inbound TCP/22):
  Jefahnierocks SSH LAN TCP 22   Enabled=True  Profile=Private TCP 22 192.168.0.0/24
  Dad Remote Management          Enabled=False (disabled by streamline)

LAN reachability:
  nc -vz mamawork.home.arpa 22:  Succeeded (verified 2026-05-15T00:15:00Z)

MacBook -> MAMAWORK SSH auth (jeffr / DadAdmin / Administrator):
  Permission denied (publickey,keyboard-interactive)
  -- because sshd reads .ssh/authorized_keys per-user, NOT administrators_authorized_keys
  -- the per-user files do not contain the canonical key, hence the failure
```

## Apply Procedure (operator-side on MAMAWORK)

Open an **elevated PowerShell 7+** session on MAMAWORK as
`MAMAWORK\jeffr`.

### Single elevated PowerShell 7+ script

```powershell
# Jefahnierocks MAMAWORK sshd admin Match block fix - 2026-05-14
# Run from Administrator PowerShell 7+ on MAMAWORK as MAMAWORK\jeffr.

$ErrorActionPreference = 'Stop'

$ExpectedHostname = 'MAMAWORK'
$EvidenceDir = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$SlotDir = Join-Path $EvidenceDir "mamawork-sshd-admin-match-block-$Timestamp"
$EvidencePath = Join-Path $SlotDir 'match-block.txt'

$SshdConfigPath = 'C:\ProgramData\ssh\sshd_config'
$SshdExe = 'C:\Windows\System32\OpenSSH\sshd.exe'

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
Write-Evidence "scope: MAMAWORK sshd admin Match block restoration"
Write-Evidence "slot_dir: $SlotDir"

if ((hostname) -ne $ExpectedHostname) { throw "Unexpected hostname. Expected $ExpectedHostname." }
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $IsAdmin) { throw 'This script must run from Administrator PowerShell.' }

Write-Evidence "operator: $env:USERDOMAIN\$env:USERNAME"
Write-Evidence "elevation: $IsAdmin"

# ============================================================
# PHASE 1 — Read-only snapshot
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 1 — READ-ONLY SNAPSHOT ==='

if (-not (Test-Path $SshdConfigPath)) {
  Write-Evidence "phase_1_error: $SshdConfigPath not present"
  throw 'sshd_config missing'
}

Copy-Item -Path $SshdConfigPath -Destination "$SlotDir\sshd_config.before"
Get-Acl $SshdConfigPath | Format-List | Out-File "$SlotDir\sshd_config.acl.before.txt"

# Defensive Match-block check
$matchLines = Select-String -Path $SshdConfigPath -Pattern '^\s*Match\s' -ErrorAction SilentlyContinue
if ($matchLines) {
  Write-Evidence 'phase_1_finding: sshd_config ALREADY HAS Match block(s):'
  $matchLines | ForEach-Object { Write-Evidence "  line $($_.LineNumber): $($_.Line)" }
  Write-Evidence 'phase_3_will_skip: existing Match block(s) present; re-adding is not desired'
  $script:skipAppendMatchBlock = $true
} else {
  Write-Evidence 'phase_1_finding: no Match blocks in sshd_config (matches handback)'
  $script:skipAppendMatchBlock = $false
}

# Live sshd -T capture
if (Test-Path $SshdExe) {
  & $SshdExe -T 2>&1 | Out-File "$SlotDir\sshd_T_effective.before.txt"
  $authKeyDirectives = Get-Content "$SlotDir\sshd_T_effective.before.txt" |
    Select-String -Pattern '^(authorizedkeysfile|authorizedkeyscommand|match)'
  Write-Evidence 'sshd_T_relevant_before:'
  $authKeyDirectives | ForEach-Object { Write-Evidence "  $_" }
}

# Unfiltered OpenSSH/Operational tail (addresses handback surprise #2)
try {
  Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 100 -ErrorAction Stop |
    Select-Object TimeCreated, Id, LevelDisplayName, @{N='Message';E={ $_.Message -replace "`r`n", ' | ' }} |
    Export-Csv "$SlotDir\openssh_operational_unfiltered.csv" -NoTypeInformation
  $eventCount = (Import-Csv "$SlotDir\openssh_operational_unfiltered.csv").Count
  Write-Evidence "openssh_operational_unfiltered_events: $eventCount captured"
} catch {
  Write-Evidence "openssh_operational_capture_failed: $($_.Exception.Message)"
}

# ============================================================
# PHASE 2 — Decide edit
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 2 — DECIDE EDIT ==='

if ($script:skipAppendMatchBlock) {
  Write-Evidence 'phase_2_decision: existing Match block(s) detected; phases 3-5 will skip; restart sshd will also skip'
  Write-Evidence 'phase_2_action: operator review the existing block(s); the auth probe may already work'
} else {
  Write-Evidence 'phase_2_decision: will append standard Windows OpenSSH Match Group administrators block'
}

# ============================================================
# PHASE 3 — Append Match block
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 3 — APPEND MATCH BLOCK ==='

if ($script:skipAppendMatchBlock) {
  Write-Evidence 'phase_3_skipped: existing Match block(s) present'
} else {
  # Read current file content
  $currentContent = [IO.File]::ReadAllText($SshdConfigPath)

  # Build the appended content. Use LF line endings to match Windows OpenSSH expectations
  # (the parser tolerates CRLF, but matching the file's existing form is safer; default
  # Windows OpenSSH ships with LF endings).
  $blockToAppend = ""
  if (-not $currentContent.EndsWith("`n")) { $blockToAppend += "`n" }
  $blockToAppend += "`n"
  $blockToAppend += "# Jefahnierocks MAMAWORK admin Match block - added 2026-05-14`n"
  $blockToAppend += "# Standard Windows OpenSSH default; restores admin auth via`n"
  $blockToAppend += "# administrators_authorized_keys system-wide file.`n"
  $blockToAppend += "Match Group administrators`n"
  $blockToAppend += "    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`n"

  $newContent = $currentContent + $blockToAppend

  # Write back via .NET I/O (UTF-8 no BOM)
  [IO.File]::WriteAllText($SshdConfigPath, $newContent, [System.Text.UTF8Encoding]::new($false))

  Write-Evidence 'phase_3_status: Match block appended'

  # Snapshot post-edit
  Copy-Item -Path $SshdConfigPath -Destination "$SlotDir\sshd_config.after"

  # Verify the block is present in the file
  $appendedMatch = Select-String -Path $SshdConfigPath -Pattern '^\s*Match\s+Group\s+administrators'
  if (-not $appendedMatch) {
    throw 'Phase 3 wrote the file but the Match block was not found in the post-state file. STOPPING.'
  }
  Write-Evidence "phase_3_verified: Match block present at line $($appendedMatch.LineNumber)"
}

# ============================================================
# PHASE 4 — Validate sshd_config syntax (HARD-STOP on fail)
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 4 — SYNTAX VALIDATE sshd_config ==='

if ($script:skipAppendMatchBlock) {
  Write-Evidence 'phase_4_skipped (no edit to validate)'
} else {
  try {
    $sshdTOutput = & $SshdExe -t 2>&1
    $sshdTExit = $LASTEXITCODE
    $sshdTOutput | Out-File "$SlotDir\sshd_t_validate.txt"
    if ($sshdTExit -ne 0) {
      Write-Evidence "phase_4_failed: sshd -t exit code $sshdTExit"
      Write-Evidence "phase_4_output: $sshdTOutput"
      Write-Evidence 'phase_4_rollback: restoring sshd_config.before'
      Copy-Item -Force -Path "$SlotDir\sshd_config.before" -Destination $SshdConfigPath
      throw "sshd -t syntax check failed; restored pre-edit sshd_config. STOPPING."
    }
    Write-Evidence "phase_4_status: sshd -t passed (exit 0)"
  } catch {
    Write-Evidence "phase_4_error: $($_.Exception.Message)"
    throw
  }
}

# ============================================================
# PHASE 5 — Restart sshd
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 5 — RESTART sshd ==='

if ($script:skipAppendMatchBlock) {
  Write-Evidence 'phase_5_skipped (no edit applied)'
} else {
  $beforeStatus = Get-Service sshd | Select-Object Status, StartType
  Write-Evidence "sshd_status_before_restart: $($beforeStatus.Status) / $($beforeStatus.StartType)"

  Restart-Service sshd
  Start-Sleep -Seconds 2

  $afterStatus = Get-Service sshd | Select-Object Status, StartType
  Write-Evidence "sshd_status_after_restart: $($afterStatus.Status) / $($afterStatus.StartType)"

  if ($afterStatus.Status -ne 'Running') {
    Write-Evidence "phase_5_failed: sshd not Running after restart"
    throw 'sshd failed to start after restart'
  }
  Write-Evidence 'phase_5_status: sshd restarted, Running'
}

# ============================================================
# PHASE 6 — Post-restart sshd -T snapshot
# ============================================================
Write-Evidence ''
Write-Evidence '=== PHASE 6 — POST-RESTART STATE ==='

& $SshdExe -T 2>&1 | Out-File "$SlotDir\sshd_T_effective.after.txt"
$authKeyDirectivesAfter = Get-Content "$SlotDir\sshd_T_effective.after.txt" |
  Select-String -Pattern '^(authorizedkeysfile|authorizedkeyscommand|match)'
Write-Evidence 'sshd_T_relevant_after:'
$authKeyDirectivesAfter | ForEach-Object { Write-Evidence "  $_" }

# Final Match-block presence verification
$finalMatchBlocks = Select-String -Path $SshdConfigPath -Pattern '^\s*Match\s' -ErrorAction SilentlyContinue
Write-Evidence 'final_match_blocks_in_sshd_config:'
$finalMatchBlocks | ForEach-Object { Write-Evidence "  line $($_.LineNumber): $($_.Line)" }

# Quick listener confirmation
$listener22 = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
  Where-Object { $_.LocalPort -eq 22 } |
  Select-Object LocalAddress, LocalPort, State, OwningProcess
Write-Evidence 'listener_tcp_22_after_restart:'
$listener22 | Format-Table -AutoSize | Out-String | Write-Evidence

Write-Evidence ''
Write-Evidence "status: completed MAMAWORK sshd admin Match block restoration"
Write-Evidence "evidence_slot: $SlotDir"
Write-Evidence ''
Write-Evidence 'NEXT: hand back to system-config for Phase 7 (MacBook-side real auth probe).'
```

### Phase 7 — MacBook-side real auth probe (system-config runs after evidence return)

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

If PASS, packet status flips to `applied`. The MAMAWORK SSH lockout
is closed. Concurrent admin (operator from MacBook + wife from
MAMAWORK console) is now operational.

If FAIL, the OpenSSH/Operational unfiltered capture from Phase 1
and the Phase 6 sshd_T snapshot together should surface the next
layer. Most likely causes if this still fails:

- The `Match Group administrators` block's `__PROGRAMDATA__` token
  isn't being expanded on this OpenSSH version. Diagnostic:
  `& $SshdExe -T` should show `match group administrators` as
  conditional context; if the path appears literally as
  `__PROGRAMDATA__/ssh/administrators_authorized_keys` rather
  than `C:/ProgramData/ssh/administrators_authorized_keys`, the
  token wasn't expanded. Fix: replace with the absolute literal
  path.
- `MAMAWORK\jeffr` isn't actually a member of the local
  `administrators` group as sshd resolves the identity. The
  streamline apply's Phase 7 already confirmed
  `Get-LocalGroupMember -Group 'Administrators'` lists `jeffr`,
  so this should be fine, but the Match-block diagnostic in
  the Phase 6 sshd_T capture would confirm.

## Rollback

If the Match block addition breaks something:

```powershell
$SLOT = '<slot-dir-from-Phase-1>'
Copy-Item -Force -Path "$SLOT\sshd_config.before" -Destination 'C:\ProgramData\ssh\sshd_config'
Restart-Service sshd
& 'C:\Windows\System32\OpenSSH\sshd.exe' -T | Out-String  # verify state
```

Note: rollback returns the SSH lockout to its pre-fix state.
Use only if the Match-block addition causes a different breakage
(e.g., sshd refuses to start; though Phase 4's `sshd -t` HARD-STOP
guard should catch that before restart).

## Required Approval Phrase

```text
I approve applying the MAMAWORK sshd admin Match block packet live
now on MAMAWORK. From an elevated PowerShell 7+ session as
MAMAWORK\jeffr, run the documented multi-phase script. Phase 1
read-only: snapshot C:\ProgramData\ssh\sshd_config, capture
sshd -T effective config, capture unfiltered OpenSSH/Operational
log tail. Phase 2: decide whether to append the Match block (skip
if any Match block already present). Phase 3: append the standard
Windows OpenSSH `Match Group administrators` /
`AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`
block via `[IO.File]::WriteAllText` UTF-8 no BOM. Phase 4 HARD-STOP:
`sshd -t` syntax validation must pass; on failure restore the
pre-edit sshd_config from snapshot and STOP. Phase 5:
`Restart-Service sshd`; require Running post-restart. Phase 6:
re-capture sshd -T and verify the Match block is present in the
file. Do NOT modify administrators_authorized_keys content (the
streamline apply already made it canonical). Do NOT touch any
per-user .ssh/authorized_keys file. Do NOT touch the ahnie account
(the operator's wife's work account; intentional local Administrator
per operator clarification 2026-05-14). Do NOT touch DadAdmin user,
kid accounts, MS Account jeffr, built-in Administrator, RDP rules,
WinRM/PSRemoting, BitLocker/Secure Boot/TPM, Defender/ASR, powercfg,
NIC wake, HKLM NetworkList registry, Cloudflare/WARP/Tailscale/
cloudflared/OPNsense/DNS/DHCP/1Password, or the host-static-vs-DHCP
question. Then return the evidence slot for system-config to ingest.
system-config will then run the MacBook-side real auth probe
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
operator:                                  MAMAWORK\jeffr
elevation:                                 yes/no
slot_dir:

PHASE 1:
  sshd_config Match blocks (before):       none / <list>
  sshd_T authorizedkeysfile (before):      .ssh/authorized_keys
  openssh_operational unfiltered events:   <count> (csv attached)

PHASE 2 decision:                          append / skip (existing block)

PHASE 3 append:
  status:                                  appended / skipped
  Match block at line:                     <line number>

PHASE 4 sshd -t:                           passed (exit 0) / failed (rolled back; STOP)

PHASE 5 sshd restart:
  status_before:                           Running / Automatic
  status_after:                            Running / Automatic

PHASE 6 post-restart:
  sshd_T relevant directives:              authorizedkeysfile .ssh/authorized_keys
                                           match group administrators
                                             (or whatever sshd -T outputs)
  Match blocks in file:                    line <n>: Match Group administrators
  listener TCP/22:                         LISTEN 0.0.0.0:22 + [::]:22 (sshd, PID <n>)

credentials_in_repo_chat_argv:             None
remaining_blockers:                        Phase 7 (MacBook real auth probe) pending system-config
```

Do NOT paste private keys, 1Password item UUIDs, passwords,
recovery material, RDP credential blobs, or other secrets.

## Boundary Assertions

After this packet applies, the following are **unchanged**:

- `administrators_authorized_keys` content (already canonical
  post-streamline; this packet does not edit it).
- `C:\Users\*\.ssh\` per-user files (including the
  `authorized_keys.txt` non-standard file).
- `C:\Users\DadAdmin.MamaWork\` directory tree.
- `HKLM\Software\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*`.
- The `DadAdmin` local user (still Enabled; held back by OneDrive
  scheduled tasks; separate decision).
- The `Dad Remote Management` firewall rule (still Disabled from
  the streamline; not re-enabled by this packet).
- The `ahnie` account (the operator's wife's work account;
  intentional local Administrator per operator clarification).
- Kid accounts (`axelp`, `ilage`, `wynst`), `jeffr` MS Account,
  built-in `Administrator`.
- RDP host-side state, `Jefahnierocks RDP LAN TCP/UDP 3389` rules,
  `Jefahnierocks SSH LAN TCP 22` rule.
- `powercfg`, NIC wake-policy, Defender, ASR, BitLocker, Secure
  Boot, TPM, WinRM, PSRemoting.
- Cloudflare, WARP, `cloudflared`, Tailscale, OPNsense, DNS,
  DHCP, 1Password (no `op` runs on MAMAWORK).
- All other `sshd_config` directives. The packet appends ONE
  Match block at the end; no global directive is changed.
- The active console user session (the wife's session). Restart
  of the sshd service does not affect the console session.

## Sequencing With Other Packets

After this packet's Phase 7 PASS:

- The MAMAWORK SSH lockout is closed. `ssh mamawork` from the
  MacBook works concurrently with the wife's console session.
- `current-status.yaml` flips `mamawork-admin-streamline` outcome
  to `applied-ssh-end-to-end-verified` (the streamline's residual
  blocker `mamawork-administrators-authorized-keys-not-honored`
  resolves).
- Three small follow-ups become drafteable:
  1. `mamawork-onedrive-scheduled-tasks-decision` — surface the
     two OneDrive tasks tied to DadAdmin SID; operator picks
     re-register / unregister / accept-as-is. Once decided, a
     tiny `mamawork-dadadmin-disable-followup` packet runs
     Disable-LocalUser DadAdmin (skipped during the streamline).
  2. `mamawork-authorized-keys-txt-resolution` — delete the
     non-standard file (it's not honored by sshd anyway now that
     the Match block points admins at the system-wide file).
  3. `mamawork-dadadmin-mamawork-profile-resolution` — operator
     reviews the 15,099-entry inventory CSV from the streamline
     slot; if dead, removed; if live, left in place.
- Future `mamawork-ssh-hardening` packet then refactors sshd_config
  to drop-in pattern, lowers LogLevel from DEBUG3 to INFO, tightens
  StrictModes, etc. — same shape as fedora-top SSH hardening.

## Related

- [mamawork-admin-streamline-packet-2026-05-14.md](./mamawork-admin-streamline-packet-2026-05-14.md) -
  the prior packet whose Phase 1 surfaced the missing Match
  block as the actual root cause.
- [mamawork-admin-streamline-apply-2026-05-14.md](./mamawork-admin-streamline-apply-2026-05-14.md) -
  apply record documenting the hypothesis miss.
- [handback-mamawork-admin-streamline-2026-05-14.md](./handback-mamawork-admin-streamline-2026-05-14.md) -
  operator's handback with the surprise findings.
- [mamawork-ssh-key-bootstrap-apply-2026-05-14.md](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md) -
  the bootstrap that put the canonical key in
  `administrators_authorized_keys`. This packet makes sshd
  actually consult that file.
- [mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md)
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)
