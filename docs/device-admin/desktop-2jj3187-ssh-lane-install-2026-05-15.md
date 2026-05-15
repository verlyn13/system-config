---
title: DESKTOP-2JJ3187 SSH Lane Install Packet - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, openssh, admin-key, firewall, sshd-config, phase-3]
priority: high
---

# DESKTOP-2JJ3187 SSH Lane Install Packet - 2026-05-15

This packet brings DESKTOP-2JJ3187 from Phase 2 (`rdp-only-host`,
phase-3 intentionally skipped) to Phase 3 complete
(`reference-ssh-host`). It is a single greenfield install packet
because DESKTOP-2JJ3187 has no prior SSH state to clean up — bundling
install + key + Match block + firewall rule is one coherent operator
sit-down rather than three separate sessions with broken intermediate
state.

For history: MAMAWORK split this work across four packets because the
host had inherited legacy SSH state (`DadAdmin_WinNet` key, `Dad
Remote Management` rule, missing `Match Group administrators` block,
LAN inbound-TCP blackhole). DESKTOP-2JJ3187 starts clean per the
baseline.

## Prerequisites

Confirm before scheduling apply:

1. **Phase 0 baseline applied and apply record committed.**
   See [desktop-2jj3187-terminal-admin-baseline-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-2026-05-15.md)
   and its apply record. The baseline's "Expected Findings" must match;
   if any expected fact differs, this install packet may need revision.
2. **1Password admin key item created.** Operator-side prerequisite.
   The item must exist before apply:
   ```text
   item:        op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13
   account:     my.1password.com
   vault:       Dev
   key type:    ED25519
   fields:      private key, public key, fingerprint, comment
   public key:  ssh-ed25519 AAAA... verlyn13@desktop-2jj3187-admin
   ```
   Generate the keypair locally on the operator MacBook with
   `ssh-keygen -t ed25519 -C verlyn13@desktop-2jj3187-admin`, store
   the private key + public key in 1Password through the GUI or the
   approved edited-template workflow per `docs/secrets.md`, then
   delete the on-disk private key from the MacBook. The private half
   never lives outside 1Password.
3. **Operator decision:** confirm `jeffr` is the intended admin SSH
   user (or supply the actual Windows admin account name).
4. **Operator decision:** confirm `192.168.0.0/24` is the intended
   LAN scope for the SSH firewall rule (matches the existing RDP
   rule scope).

## Approval Phrase

> Apply the `desktop-2jj3187-ssh-lane-install` packet on
> DESKTOP-2JJ3187 from an elevated PowerShell session as `jeffr`. The
> packet installs the Windows OpenSSH Server capability, starts and
> enables the `sshd` service, adds the `Jefahnierocks SSH LAN TCP 22`
> Private firewall rule scoped to `192.168.0.0/24`, ensures the
> standard `Match Group administrators` block in `sshd_config`,
> installs `PasswordAuthentication no` via a drop-in, sets
> `LogLevel INFO`, pastes the operator-supplied public key body for
> 1Password item
> `op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13`
> into `C:\ProgramData\ssh\administrators_authorized_keys` with the
> Microsoft-required ACL (`Administrators` + `SYSTEM` only), runs
> `sshd -t`, restarts `sshd`, and writes evidence to
> `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<timestamp>\`.
> The operator MacBook then runs the real-auth probe
> `ssh -o IdentityAgent=... jeffr@desktop-2jj3187.home.arpa 'cmd /c "hostname && whoami"'`
> and expects `DESKTOP-2JJ3187` / `desktop-2jj3187\jeffr`. The
> [macbook-ssh-conf-d-desktop-2jj3187-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-2026-05-15.md)
> packet (separate apply) then adds the short alias `ssh desktop-2jj3187`.

## Session Class

`scoped-live-change`. Six surfaces touched:

- Windows OpenSSH Server capability (install)
- `sshd` service state (start, enable)
- `C:\ProgramData\ssh\sshd_config` (verify Match block, add drop-in)
- `C:\ProgramData\ssh\administrators_authorized_keys` (create + paste public key + ACL)
- Windows Firewall (one new inbound-allow rule)
- Evidence directory (write-only)

Not touched: accounts, groups, ACLs outside the two SSH paths, BitLocker,
Defender, RDP rules, WinRM, scheduled tasks, codex sandbox accounts,
network profile, DNS, DHCP, OPNsense, Cloudflare, WARP, 1Password.

## Preflight

From elevated PowerShell on DESKTOP-2JJ3187 as `DESKTOP-2JJ3187\jeffr`:

```powershell
hostname
whoami
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
"is_admin_role=$($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
```

Expect:

```text
DESKTOP-2JJ3187
DESKTOP-2JJ3187\jeffr
is_admin_role=True
```

Stop if either value differs. The Match block, key install, firewall
rule, and config drop-in all require `High Mandatory Level`.

## Hard Stops

Halt the script and revert if:

- Preflight identity proof fails.
- `Get-WindowsCapability -Online -Name OpenSSH.Server*` indicates a
  state other than `NotPresent` or `Installed`.
- `sshd -t` syntax check fails after any `sshd_config` change.
- Setting ACL on `administrators_authorized_keys` fails.
- The MacBook real-auth probe fails after restart.

## Snapshot (Step S0)

Write a pre-apply snapshot to the evidence directory so any rollback
has source-of-truth state to revert to.

```powershell
$ts          = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$EvidenceDir = "C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-$ts"
$SnapDir     = Join-Path $EvidenceDir 'snapshot'
New-Item -ItemType Directory -Path $SnapDir -Force | Out-Null

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

"timestamp: $ts" | Write-Evidence -File '00-run.txt'
"step:      S0 snapshot" | Write-Evidence -File '00-run.txt'

Get-WindowsCapability -Online -Name 'OpenSSH.*' -ErrorAction SilentlyContinue |
  Select-Object Name,State | Format-Table -AutoSize | Out-String |
  Write-Evidence -File '00-run.txt'

Get-Service sshd,ssh-agent -ErrorAction SilentlyContinue |
  Select-Object Name,Status,StartType |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '00-run.txt'

foreach ($p in 'C:\ProgramData\ssh\sshd_config',
               'C:\ProgramData\ssh\administrators_authorized_keys',
               'C:\ProgramData\ssh\sshd_config.d') {
  if (Test-Path $p) {
    "PRESENT: $p" | Write-Evidence -File '00-run.txt'
    if ((Get-Item $p).PSIsContainer) {
      Get-ChildItem $p | Select-Object FullName,Length | Format-Table | Out-String |
        Write-Evidence -File '00-run.txt'
    } else {
      Copy-Item -LiteralPath $p -Destination (Join-Path $SnapDir (Split-Path $p -Leaf)) -Force
    }
  } else {
    "ABSENT:  $p" | Write-Evidence -File '00-run.txt'
  }
}

Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' -ErrorAction SilentlyContinue |
  Format-List | Out-String | Write-Evidence -File '00-run.txt'
```

## Step S1 — Install OpenSSH.Server Windows Capability

```powershell
"step:      S1 install OpenSSH.Server" | Write-Evidence -File '00-run.txt'

$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' |
         Select-Object -First 1

if (-not $cap) {
  "no OpenSSH.Server capability returned by DISM — halt" | Write-Evidence -File '00-run.txt'
  throw "OpenSSH.Server capability not enumerable on this host."
}

if ($cap.State -eq 'Installed') {
  "OpenSSH.Server already Installed — skip" | Write-Evidence -File '00-run.txt'
} elseif ($cap.State -eq 'NotPresent') {
  "installing $($cap.Name) ..." | Write-Evidence -File '00-run.txt'
  $r = Add-WindowsCapability -Online -Name $cap.Name
  $r | Format-List | Out-String | Write-Evidence -File '00-run.txt'
} else {
  "OpenSSH.Server in unexpected state $($cap.State) — halt" | Write-Evidence -File '00-run.txt'
  throw "Unexpected OpenSSH.Server state: $($cap.State)"
}

Get-WindowsCapability -Online -Name 'OpenSSH.Server*' |
  Select-Object Name,State | Format-Table -AutoSize | Out-String |
  Write-Evidence -File '00-run.txt'
```

## Step S2 — Configure `sshd` Service

```powershell
"step:      S2 configure sshd service" | Write-Evidence -File '00-run.txt'

Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd

Get-Service sshd | Format-List Name,Status,StartType | Out-String |
  Write-Evidence -File '00-run.txt'

Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue |
  Select-Object LocalAddress,LocalPort,OwningProcess |
  Format-Table -AutoSize | Out-String | Write-Evidence -File '00-run.txt'
```

The Windows OpenSSH installer typically creates the firewall rule
`OpenSSH-Server-In-TCP`. Disable that broad rule in Step S4 and
replace with a narrow named rule scoped to LAN.

## Step S3 — Verify / Install `Match Group administrators` Block

The standard Windows OpenSSH `sshd_config` ships with the
`administrators_authorized_keys` Match block enabled by default since
the Windows 10/Server 2019 OpenSSH refresh. Verify presence; only add
if missing.

```powershell
"step:      S3 verify Match Group administrators block" | Write-Evidence -File '00-run.txt'

$sshdConfig = 'C:\ProgramData\ssh\sshd_config'
$matchPattern = '(?ms)^Match\s+Group\s+administrators\b.*?AuthorizedKeysFile\s+__PROGRAMDATA__/ssh/administrators_authorized_keys'

if (-not (Test-Path $sshdConfig)) {
  "$sshdConfig absent — OpenSSH server install failed?" | Write-Evidence -File '00-run.txt'
  throw "sshd_config missing after capability install."
}

$cfg = Get-Content -Raw $sshdConfig
if ($cfg -match $matchPattern) {
  "Match Group administrators block present (default)" | Write-Evidence -File '00-run.txt'
} else {
  "Match Group administrators block missing — appending stock form" | Write-Evidence -File '00-run.txt'
  Add-Content -LiteralPath $sshdConfig -Value @"

Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
"@
}

# Validate syntax before touching service.
& 'C:\Windows\System32\OpenSSH\sshd.exe' -t 2>&1 | Out-String |
  Write-Evidence -File '00-run.txt'
if ($LASTEXITCODE -ne 0) {
  "sshd -t failed — restoring snapshot" | Write-Evidence -File '00-run.txt'
  Copy-Item -LiteralPath (Join-Path $SnapDir 'sshd_config') -Destination $sshdConfig -Force
  throw "sshd -t failed after Match block edit."
}
```

## Step S4 — Install Hardening Drop-In

Place the Jefahnierocks hardening drop-in. Windows OpenSSH supports
`sshd_config.d` since the 2024 refresh.

```powershell
"step:      S4 install hardening drop-in" | Write-Evidence -File '00-run.txt'

$dropInDir = 'C:\ProgramData\ssh\sshd_config.d'
if (-not (Test-Path $dropInDir)) {
  New-Item -ItemType Directory -Path $dropInDir -Force | Out-Null
}

$dropIn = Join-Path $dropInDir '20-jefahnierocks-admin.conf'
@"
# Managed by system-config docs/device-admin/desktop-2jj3187-ssh-lane-install-2026-05-15.md
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
LogLevel INFO
AllowGroups administrators
"@ | Set-Content -LiteralPath $dropIn -Encoding ascii

# Apply Microsoft-required ACL: System + Administrators only.
$acl = New-Object System.Security.AccessControl.FileSecurity
$acl.SetAccessRuleProtection($true, $false)
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
  'NT AUTHORITY\SYSTEM','FullControl','Allow')))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
  'BUILTIN\Administrators','FullControl','Allow')))
Set-Acl -Path $dropIn -AclObject $acl

Get-Acl -Path $dropIn | Format-List | Out-String |
  Write-Evidence -File '00-run.txt'

& 'C:\Windows\System32\OpenSSH\sshd.exe' -t 2>&1 | Out-String |
  Write-Evidence -File '00-run.txt'
if ($LASTEXITCODE -ne 0) {
  "sshd -t failed after drop-in — removing drop-in and restoring snapshot" | Write-Evidence -File '00-run.txt'
  Remove-Item -LiteralPath $dropIn -Force
  Copy-Item -LiteralPath (Join-Path $SnapDir 'sshd_config') -Destination $sshdConfig -Force
  throw "sshd -t failed after drop-in install."
}
```

## Step S5 — Install Admin Public Key

The operator pastes the public key body in line as `$PublicKeyBody`.
Do NOT have the script read 1Password from the Windows host —
1Password is not installed there, and the spec forbids it.

```powershell
"step:      S5 install admin public key" | Write-Evidence -File '00-run.txt'

# === OPERATOR: REPLACE THIS LINE WITH THE EXACT PUBLIC KEY BODY ===
# Copy from 1Password item
# op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13/public key
$PublicKeyBody = '<paste-from-1password-here>'
# ==================================================================

if ($PublicKeyBody -notmatch '^ssh-ed25519 \S+ \S+$') {
  "public key body does not look like ed25519 — halt" | Write-Evidence -File '00-run.txt'
  throw "Invalid public key body."
}

$authKeysPath = 'C:\ProgramData\ssh\administrators_authorized_keys'

# Idempotent gate: skip if line already present.
$existing = if (Test-Path $authKeysPath) {
  (Get-Content -LiteralPath $authKeysPath -ErrorAction SilentlyContinue) -join "`n"
} else { '' }

if ($existing -match [regex]::Escape($PublicKeyBody.Split(' ')[1])) {
  "public key already present — skip" | Write-Evidence -File '00-run.txt'
} else {
  if (-not (Test-Path $authKeysPath)) {
    New-Item -ItemType File -Path $authKeysPath -Force | Out-Null
  }
  Add-Content -LiteralPath $authKeysPath -Value $PublicKeyBody -Encoding ascii
  "appended public key" | Write-Evidence -File '00-run.txt'
}

# Microsoft-required ACL: Administrators + SYSTEM only.
$acl = New-Object System.Security.AccessControl.FileSecurity
$acl.SetAccessRuleProtection($true, $false)
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
  'NT AUTHORITY\SYSTEM','FullControl','Allow')))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
  'BUILTIN\Administrators','FullControl','Allow')))
Set-Acl -Path $authKeysPath -AclObject $acl

(Get-Acl -Path $authKeysPath) | Format-List | Out-String |
  Write-Evidence -File '00-run.txt'

# Compute and record the fingerprint for evidence (non-secret).
$fp = (& 'C:\Windows\System32\OpenSSH\ssh-keygen.exe' -lf $authKeysPath 2>&1) -join "`n"
$fp | Write-Evidence -File '00-run.txt'
```

## Step S6 — Replace Default Firewall Rule

The OpenSSH installer creates `OpenSSH-Server-In-TCP` (often broad).
Disable it and add the named scoped rule.

```powershell
"step:      S6 replace firewall rule" | Write-Evidence -File '00-run.txt'

Get-NetFirewallRule -DisplayName 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue |
  Disable-NetFirewallRule

$existing = Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' -ErrorAction SilentlyContinue
if ($existing) {
  "rule Jefahnierocks SSH LAN TCP 22 already present — enabling and re-scoping" | Write-Evidence -File '00-run.txt'
  $existing | Enable-NetFirewallRule
  $existing | Set-NetFirewallRule -Profile Private -Direction Inbound -Action Allow
  $existing | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress '192.168.0.0/24'
  $existing | Get-NetFirewallPortFilter   | Set-NetFirewallPortFilter   -Protocol TCP -LocalPort 22
} else {
  New-NetFirewallRule `
    -DisplayName 'Jefahnierocks SSH LAN TCP 22' `
    -Description 'system-config managed: LAN SSH for Jefahnierocks admin' `
    -Direction Inbound -Action Allow `
    -Protocol TCP -LocalPort 22 `
    -Profile Private `
    -RemoteAddress '192.168.0.0/24' `
    -Enabled True | Out-Null
}

Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' |
  Format-List DisplayName,Enabled,Direction,Action,Profile | Out-String |
  Write-Evidence -File '00-run.txt'
Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' |
  Get-NetFirewallAddressFilter |
  Format-List RemoteAddress | Out-String |
  Write-Evidence -File '00-run.txt'
```

## Step S7 — Restart `sshd` and Confirm Effective Config

```powershell
"step:      S7 restart sshd and confirm effective config" | Write-Evidence -File '00-run.txt'

Restart-Service -Name sshd
Start-Sleep -Seconds 2

Get-Service sshd | Format-List Name,Status,StartType | Out-String |
  Write-Evidence -File '00-run.txt'

# Conditional sshd -T proves the Match Group block fires for the admin user.
& 'C:\Windows\System32\OpenSSH\sshd.exe' -T `
  -C "user=jeffr,host=desktop-2jj3187.home.arpa,addr=127.0.0.1" 2>&1 |
  Select-String 'authorizedkeysfile|pubkey|password|kbd|strictmodes|loglevel|allowgroups' |
  Out-String | Write-Evidence -File '00-run.txt'
```

Expected in conditional output:

```text
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
strictmodes yes
loglevel INFO
authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys
allowgroups administrators
```

## Step S8 — Operator MacBook Real-Auth Probe

From the operator MacBook (not on the Windows host). Explicit option
form because the short alias is not yet in place; the
`macbook-ssh-conf-d-desktop-2jj3187` packet adds the alias separately.

```bash
ssh \
  -i ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o BatchMode=yes \
  -o ConnectTimeout=5 \
  -o ControlMaster=no \
  -o ControlPath=none \
  -o HostKeyAlias=192.168.0.217 \
  jeffr@desktop-2jj3187.home.arpa \
  'cmd /c "hostname && whoami"'
```

Expected:

```text
DESKTOP-2JJ3187
desktop-2jj3187\jeffr
```

The probe assumes the operator has already deployed the public key file
`~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub` on the MacBook
side via `chezmoi apply` of the chezmoi template introduced in the
companion conf.d packet. If the public key file is not yet on disk on
the MacBook, the explicit `-i` arg can point at the on-disk public-key
text temporarily — but the 1Password agent is the authoritative key
holder.

If the probe returns `Permission denied (publickey)`:

- Verify the public key body in
  `C:\ProgramData\ssh\administrators_authorized_keys` matches the
  fingerprint of the 1P item with `(Get-FileHash ... -Algorithm SHA256)`-style
  manual comparison or with `ssh-keygen -lf` on the path.
- Verify ACLs on `administrators_authorized_keys` are
  `Administrators + SYSTEM` only.
- Confirm the conditional `sshd -T` output shows `authorizedkeysfile
  __PROGRAMDATA__/ssh/administrators_authorized_keys`.

## Rollback

Snapshot covers it:

```powershell
# 1. Stop service.
Stop-Service -Name sshd

# 2. Restore sshd_config from snapshot.
Copy-Item -LiteralPath (Join-Path $SnapDir 'sshd_config') `
          -Destination 'C:\ProgramData\ssh\sshd_config' -Force

# 3. Remove drop-in.
Remove-Item -LiteralPath 'C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf' -Force -ErrorAction SilentlyContinue

# 4. Remove or revert administrators_authorized_keys.
#    If pre-apply state was ABSENT, delete the file:
Remove-Item -LiteralPath 'C:\ProgramData\ssh\administrators_authorized_keys' -Force -ErrorAction SilentlyContinue
#    If pre-apply state had contents, restore the snapshot copy.

# 5. Disable the new firewall rule.
Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' -ErrorAction SilentlyContinue |
  Disable-NetFirewallRule

# 6. Re-enable default firewall rule if it was previously enabled.
Get-NetFirewallRule -DisplayName 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue |
  Enable-NetFirewallRule

# 7. Optionally uninstall the OpenSSH.Server capability if pre-apply state was NotPresent.
#    Only if the operator wants to fully unwind; harmless to leave installed.
# Remove-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
```

## Validation Checklist (apply record must confirm)

- [ ] Preflight identity proof matched expected `DESKTOP-2JJ3187\jeffr` admin.
- [ ] `OpenSSH.Server` capability state is `Installed`.
- [ ] `Get-Service sshd` Status=Running, StartType=Automatic.
- [ ] `Get-NetTCPConnection -State Listen -LocalPort 22` returns a listener on `0.0.0.0` and `::`.
- [ ] `sshd_config` contains `Match Group administrators` →
      `AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`.
- [ ] `sshd_config.d/20-jefahnierocks-admin.conf` present with `Administrators + SYSTEM` ACL only and contents as documented.
- [ ] `administrators_authorized_keys` contains the exact `verlyn13@desktop-2jj3187-admin` public key body and has `Administrators + SYSTEM` ACL only.
- [ ] `Jefahnierocks SSH LAN TCP 22` Enabled, Private profile, RemoteAddress `192.168.0.0/24`.
- [ ] `OpenSSH-Server-In-TCP` (default) Disabled.
- [ ] Conditional `sshd -T -C user=jeffr,...` shows `pubkeyauthentication yes`, `passwordauthentication no`, `authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys`, `loglevel INFO`, `allowgroups administrators`.
- [ ] MacBook real-auth probe returns `DESKTOP-2JJ3187` / `desktop-2jj3187\jeffr` with admin token (verify via the same `is_admin_role` query in an SSH session).

## Boundaries

This packet does NOT touch:

- accounts, groups, passwords, ACLs outside the two SSH paths;
- BitLocker, Secure Boot, Defender exclusions;
- RDP rules / TermService state (RDP fallback remains);
- WinRM (stays stopped);
- scheduled tasks (Codex sandbox accounts preserved);
- network profile (already Private from 2026-05-12 apply);
- DNS, DHCP, OPNsense, WARP, Cloudflare, Tailscale, 1Password.

The MacBook-side conf.d update is the next packet
([macbook-ssh-conf-d-desktop-2jj3187-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-2026-05-15.md))
and is independent — it can be applied before or after this packet but
the real-auth probe in S8 is more convenient once the short alias is
in place.

## After Apply

Update `docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- `lifecycle_phase: 3`
- `classification: reference-ssh-host`
- Add this packet to `applied_packets[]` with packet_commit, apply_commit, applied_at, outcome.
- Remove the `phase 3 intentionally skipped` note from the device's
  notes / current_management_status fields.

Update `docs/device-admin/windows-pc.md` to reflect that the device is
now also SSH-managed. Update `docs/device-admin/handoff-desktop-2jj3187.md`
to lift the "OpenSSH stop and ask" item.

Subsequent followup packets (separate, approval-gated each):

- `desktop-2jj3187-ssh-hardening` — once the baseline + this install
  apply records are landed, consider tightening `StrictModes`, removing
  any stale config lines, deciding `LogLevel` (drop-in already sets to
  `INFO`), and reconciling per-user `authorized_keys` if any.
- `desktop-2jj3187-known-hosts-reconciliation` — MacBook-side, drops
  the `HostKeyAlias 192.168.0.217` once the FQDN host-key entry is
  added.
- `desktop-2jj3187-cloudflare-warp-cutover` — gated on
  `cloudflare-dns` Windows multi-user rebaseline (the same gate as
  MAMAWORK).
