---
title: MAMAWORK SSH Key Bootstrap Packet - 2026-05-14
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, openssh, admin-key, 1password]
priority: high
---

# MAMAWORK SSH Key Bootstrap Packet - 2026-05-14

Establishes the **administrative SSH key path** from `fedora-top`
(`verlyn13`) to MAMAWORK using a freshly minted 1Password-backed
ED25519 key. The legacy `DadAdmin_WinNet` ED25519 key (fingerprint
`SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`) is confirmed
**not present** on `fedora-top` after the prior workstation
migration: the operator's continuity check of 8 private-key files
under `/home/verlyn13/.ssh/` on `fedora-top` produced no matching
fingerprint. The new key is therefore the canonical MAMAWORK admin
key.

This packet is **operator-applied on MAMAWORK** from an elevated
PowerShell 7+ session. No live `system-config` host change is
authorized by approving this document; the operator executes the
procedure on MAMAWORK directly and returns a non-secret summary.

## Scope

In scope:

- **Append** the new admin public-key line to
  `C:\ProgramData\ssh\administrators_authorized_keys` (the
  system-wide path Windows OpenSSH consults for any user in the
  `Administrators` group).
- **Mirror** the new line into
  `C:\Users\DadAdmin\.ssh\authorized_keys` (the per-user copy seen
  at intake time) so the path is consistent.
- **Verify** the new line's fingerprint matches the operator-
  supplied expected value before any write.
- **Snapshot** the pre-apply state of both files so rollback is
  trivial.
- **Document** the SSH username form (`DadAdmin@mamawork.home.arpa`).
- **Out-of-band remote-verify** from `fedora-top` once MAMAWORK
  SSH is reachable (that part is gated on the separate MAMAWORK SSH
  investigation packet's outcome; do **not** treat absence of remote
  verification at apply time as a failure).

Out of scope (separate packets):

- **Removing the legacy `DadAdmin_WinNet` line** from
  `administrators_authorized_keys`. The legacy key's private half
  is confirmed missing from `fedora-top`, so the public-key line is
  effectively a dangling reference; however, removing it touches the
  same file twice in one session, so the cleanup is deferred to a
  small follow-up packet after the new key is verified end-to-end.
  Leaving the dangling line in place during this bootstrap does not
  weaken security (no client can present a matching private key).
- **Reconciling `C:\Users\jeffr\.ssh\authorized_keys.txt`** (the
  non-standard filename observed at intake). Separate decision; the
  intake script intentionally did not read the file in case it
  contains private-key material.
- **Reconciling the duplicate `DadAdmin.MamaWork` profile**
  (`C:\Users\DadAdmin.MamaWork\.ssh\authorized_keys`). Separate
  profile-hygiene decision; touching that path now risks breaking
  whichever profile MAMAWORK actually loads at signin.
- **Fixing MAMAWORK SSH reachability** (TCP/22 currently times out
  from `fedora-top`). The
  [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md)
  diagnoses that separately.
- **Switching MAMAWORK host-static to DHCP**
  ([mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md)).
- **Hardening `sshd_config`** (separate
  `mamawork-ssh-hardening` packet flagged in
  [handoff-mamawork.md](./handoff-mamawork.md)).
- **Adding a new Windows admin account**, changing UAC, group
  memberships, RDP, WinRM, BitLocker, Secure Boot, Tailscale, WARP,
  `cloudflared`, Cloudflare, OPNsense, DNS, DHCP, LUKS, power,
  reboot, Defender exclusions, or 1Password items.

## Verified Current State (from 2026-05-13 intake + 2026-05-14 inputs)

```text
target host:               MAMAWORK
fqdn:                      mamawork.home.arpa
ip:                        192.168.0.101  (LAN/igc1 ARP confirmed)
sshd:                      installed; listening on 0.0.0.0:22 and
                           [::]:22 per intake (TCP/22 currently
                           times out from fedora-top; cause under
                           investigation in the SSH investigation
                           packet, separately approved)
sshd_config (highlights):
  PubkeyAuthentication     yes
  PasswordAuthentication   no
  AuthorizedKeysFile       .ssh/authorized_keys (per-user)
                           (admins also consult
                            C:\ProgramData\ssh\administrators_authorized_keys
                            per Windows OpenSSH defaults)
  StrictModes              no
  LogLevel                 DEBUG3
authorized admin key today
  in administrators_authorized_keys:
                           DadAdmin_WinNet ED25519
                           SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk
                           (legacy; private half NOT present on
                            fedora-top per 2026-05-14 operator check)

new admin key to install:
  1Password item:          op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13
  expected fingerprint:    SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY
  public-key body:         ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2FlNNQ337TaP51lwouo/5+ZIG2WGy431b4UxtYIHnH verlyn13@mamawork-admin
  private half:            held in 1Password Dev vault, served by
                           the 1Password SSH agent on fedora-top
                           (and on any other operator device the
                           operator chooses to attach)

SSH username form
  for verlyn13 -> MAMAWORK
  admin SSH:               DadAdmin@mamawork.home.arpa
                           (DadAdmin is in MAMAWORK Administrators;
                            administrators_authorized_keys is the
                            authoritative key file for that path)
```

## Apply Procedure (operator-side on MAMAWORK)

Open an **elevated PowerShell 7+** session on MAMAWORK as
`MAMAWORK\jeffr` (or any administrator). The procedure writes
non-secret output to
`C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-ssh-key-bootstrap-<timestamp>\`
following the intake-script pattern.

### Step 0 - Pre-flight identity check

```powershell
hostname
whoami
[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
```

Must return `MAMAWORK` / `<admin user>` / `True`.

### Step 1 - Snapshot pre-apply state

```powershell
$Root = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$OutDir = Join-Path $Root "mamawork-ssh-key-bootstrap-$Timestamp"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$adminKeys = 'C:\ProgramData\ssh\administrators_authorized_keys'
$dadAdminKeys = 'C:\Users\DadAdmin\.ssh\authorized_keys'

# Snapshot administrators_authorized_keys
if (Test-Path $adminKeys) {
    Copy-Item -Path $adminKeys -Destination "$OutDir\administrators_authorized_keys.before"
    Get-Acl $adminKeys | Format-List | Out-File "$OutDir\administrators_authorized_keys.acl.txt"
    Get-Content $adminKeys | ForEach-Object {
        if ($_ -match '^\s*ssh-') {
            $_ | ssh-keygen -lf - 2>$null | Out-File -Append "$OutDir\fingerprints-administrators-before.txt"
        }
    }
} else {
    "FILE NOT PRESENT" | Out-File "$OutDir\administrators_authorized_keys.before.absent.txt"
}

# Snapshot DadAdmin per-user authorized_keys
if (Test-Path $dadAdminKeys) {
    Copy-Item -Path $dadAdminKeys -Destination "$OutDir\dadadmin.authorized_keys.before"
    Get-Acl $dadAdminKeys | Format-List | Out-File "$OutDir\dadadmin.authorized_keys.acl.txt"
    Get-Content $dadAdminKeys | ForEach-Object {
        if ($_ -match '^\s*ssh-') {
            $_ | ssh-keygen -lf - 2>$null | Out-File -Append "$OutDir\fingerprints-dadadmin-before.txt"
        }
    }
} else {
    "FILE NOT PRESENT" | Out-File "$OutDir\dadadmin.authorized_keys.before.absent.txt"
}

# Capture sshd service state + sshd_config for context (read-only)
Get-Service sshd | Format-List | Out-File "$OutDir\sshd-service.before.txt"
if (Test-Path 'C:\ProgramData\ssh\sshd_config') {
    Copy-Item -Path 'C:\ProgramData\ssh\sshd_config' -Destination "$OutDir\sshd_config.before"
}

Write-Output "snapshot_path=$OutDir"
```

### Step 2 - Verify the new public key body locally

The operator copies the public-key line from the 1Password item
`op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13` into a
PowerShell variable. Then:

```powershell
$NewPubKeyLine = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2FlNNQ337TaP51lwouo/5+ZIG2WGy431b4UxtYIHnH verlyn13@mamawork-admin'
$ExpectedFp   = 'SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY'

$ComputedFp = ($NewPubKeyLine | ssh-keygen -lf - 2>$null) -replace '^\d+ (\S+) .*', '$1'
if ($ComputedFp -ne $ExpectedFp) {
    throw "FAIL: pubkey line fingerprint mismatch ($ComputedFp != $ExpectedFp)"
}
Write-Output "fingerprint_match=ok ($ComputedFp)"
```

If the fingerprints do not match, **stop here**. Do not proceed.
The expected fingerprint comes from the operator's separate
verification of the 1Password item; mismatch indicates either a
copy-paste error or a wrong public-key body.

### Step 3 - Append to `administrators_authorized_keys`

```powershell
$adminKeys = 'C:\ProgramData\ssh\administrators_authorized_keys'

# Refuse duplicate
$existing = if (Test-Path $adminKeys) { Get-Content $adminKeys } else { @() }
if ($existing -contains $NewPubKeyLine) {
    Write-Output "skip: identical public-key line already present in $adminKeys"
} else {
    # Ensure the file exists with the correct ACL.
    if (-not (Test-Path $adminKeys)) {
        New-Item -ItemType File -Path $adminKeys | Out-Null
        # Set canonical Windows OpenSSH ACL: Administrators + SYSTEM only.
        icacls $adminKeys /inheritance:r
        icacls $adminKeys /grant 'Administrators:F'
        icacls $adminKeys /grant 'SYSTEM:F'
    }
    # Append the new line (UTF-8 without BOM is the Windows OpenSSH expectation).
    Add-Content -Path $adminKeys -Value $NewPubKeyLine -Encoding utf8
    Write-Output "appended_to=$adminKeys"
}

# Post-append: enumerate fingerprints
Get-Content $adminKeys | ForEach-Object {
    if ($_ -match '^\s*ssh-') { $_ | ssh-keygen -lf - }
}
```

The packet **does not** remove the legacy `DadAdmin_WinNet` line.
Leaving it in place during bootstrap is safe (no matching private
key exists on `fedora-top`); the cleanup is deferred to a small
follow-up packet once the new key path is verified end-to-end.

### Step 4 - Mirror into `C:\Users\DadAdmin\.ssh\authorized_keys`

OpenSSH on Windows reads `administrators_authorized_keys` for users
in the `Administrators` group, but mirroring keeps the
intake-observed per-user copy aligned:

```powershell
$dadAdminKeys = 'C:\Users\DadAdmin\.ssh\authorized_keys'
$dadAdminSsh  = Split-Path $dadAdminKeys -Parent
if (-not (Test-Path $dadAdminSsh)) {
    New-Item -ItemType Directory -Path $dadAdminSsh | Out-Null
}

$existingDad = if (Test-Path $dadAdminKeys) { Get-Content $dadAdminKeys } else { @() }
if ($existingDad -contains $NewPubKeyLine) {
    Write-Output "skip: identical public-key line already present in $dadAdminKeys"
} else {
    Add-Content -Path $dadAdminKeys -Value $NewPubKeyLine -Encoding utf8
    Write-Output "appended_to=$dadAdminKeys"
}

Get-Content $dadAdminKeys | ForEach-Object {
    if ($_ -match '^\s*ssh-') { $_ | ssh-keygen -lf - }
}
```

### Step 5 - Local verification

```powershell
# Confirm Windows OpenSSH sees the new line in administrators_authorized_keys
Get-Content C:\ProgramData\ssh\administrators_authorized_keys |
  ForEach-Object { if ($_ -match '^\s*ssh-') { $_ | ssh-keygen -lf - } } |
  Out-File "$OutDir\fingerprints-administrators-after.txt"

# Confirm the expected fingerprint is present
Select-String -Path "$OutDir\fingerprints-administrators-after.txt" `
              -Pattern "SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY" |
  ForEach-Object { Write-Output "expected_key_present=yes" }

# Confirm sshd_config still has PubkeyAuthentication yes
Get-Content C:\ProgramData\ssh\sshd_config |
  Select-String -Pattern '^(PubkeyAuthentication|PasswordAuthentication|AuthorizedKeysFile|AllowUsers|AllowGroups|ListenAddress|Port|StrictModes|LogLevel)' |
  Out-File "$OutDir\sshd_config.relevant-after.txt"
```

Local verification confirms the file content; **remote**
verification (logging in over SSH from `fedora-top`) is intentionally
deferred until the separate
[mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md)
identifies and fixes the cause of the TCP/22 timeout.

### Step 6 - Return non-secret evidence to system-config

The operator pastes the contents of:

- `mamawork-ssh-key-bootstrap-<timestamp>/fingerprints-administrators-before.txt`
- `mamawork-ssh-key-bootstrap-<timestamp>/fingerprints-administrators-after.txt`
- `mamawork-ssh-key-bootstrap-<timestamp>/fingerprints-dadadmin-before.txt`
  (if present)
- `mamawork-ssh-key-bootstrap-<timestamp>/sshd-service.before.txt` (summary line)
- `mamawork-ssh-key-bootstrap-<timestamp>/sshd_config.relevant-after.txt`

into a hand-back to system-config. system-config will ingest the
result and update `current-status.yaml`.

## Rollback

```powershell
$SNAP = '<snapshot-path>'   # from Step 1

# Restore administrators_authorized_keys
if (Test-Path "$SNAP\administrators_authorized_keys.before") {
    Copy-Item -Force -Path "$SNAP\administrators_authorized_keys.before" `
              -Destination 'C:\ProgramData\ssh\administrators_authorized_keys'
}

# Restore DadAdmin per-user authorized_keys
if (Test-Path "$SNAP\dadadmin.authorized_keys.before") {
    Copy-Item -Force -Path "$SNAP\dadadmin.authorized_keys.before" `
              -Destination 'C:\Users\DadAdmin\.ssh\authorized_keys'
}

Write-Output "rolled_back_from=$SNAP"
```

Rollback is local; nothing happens on `fedora-top` to roll back from.

## Required Approval Phrase

Live apply requires guardian approval substantially equivalent to:

```text
I approve applying the MAMAWORK SSH key bootstrap packet live now
on MAMAWORK. From an elevated PowerShell session as MAMAWORK\<admin>,
snapshot administrators_authorized_keys, DadAdmin .ssh\authorized_keys,
the sshd service state, and the sshd_config to
C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-ssh-
key-bootstrap-<timestamp>\. Verify the operator-supplied public-key
line's fingerprint matches SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY
before any write. Append the line to
C:\ProgramData\ssh\administrators_authorized_keys and mirror it
into C:\Users\DadAdmin\.ssh\authorized_keys, refusing duplicates.
Confirm the expected fingerprint appears in
administrators_authorized_keys after the write, and that the
sshd_config still says PubkeyAuthentication yes and
PasswordAuthentication no. Do NOT remove the legacy DadAdmin_WinNet
line. Do NOT touch C:\Users\jeffr\.ssh\authorized_keys.txt, the
C:\Users\DadAdmin.MamaWork profile copy, sshd_config itself,
Windows Firewall, RDP, WinRM, accounts/groups, BitLocker, Secure
Boot, Tailscale, Cloudflare, WARP, cloudflared, OPNsense, DNS,
DHCP, LUKS, power, reboot, or 1Password from MAMAWORK's side.
Return a non-secret summary to system-config.
```

## Evidence Template (operator hand-back)

```text
timestamp:
operator:
elevation:                yes/no
snapshot path:
fingerprint of operator-supplied public-key line locally
  recomputed:             SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY
administrators_authorized_keys path:
  before fingerprints:    <list>
  after fingerprints:     <list incl. SHA256:qilvkR7/...>
DadAdmin per-user authorized_keys:
  before fingerprints:    <list or absent>
  after fingerprints:     <list incl. SHA256:qilvkR7/...>
sshd service Status / StartType:   <e.g. Running / Automatic>
sshd_config relevant directives:   PubkeyAuthentication yes;
                                   PasswordAuthentication no;
                                   AuthorizedKeysFile ...;
                                   AllowUsers ... (if present);
                                   StrictModes no; LogLevel ...
remote verification from fedora-top:
                          deferred to after SSH investigation
                          remediation; record outcome there
rollback used:            yes/no
remaining blockers:
```

Do NOT paste private keys, OAuth tokens, OpenSSH session secrets,
Defender exclusion contents, Wi-Fi PSKs, BitLocker recovery
material, or credential-manager values into the hand-back.

## Out-Of-Band Verification (after MAMAWORK SSH is reachable)

Once the [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md)
diagnoses + remediates the TCP/22 timeout, run from `fedora-top`:

```bash
ssh \
  -i "$HOME/.ssh/<public-key-file-served-by-1password-agent>.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o ControlMaster=no \
  -o ControlPath=none \
  DadAdmin@mamawork.home.arpa 'hostname; whoami'
```

`(public-key-file-served-by-1password-agent).pub` refers to the
on-disk public-key file the operator deploys on `fedora-top` whose
matching private half lives in
`op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13`. The
private key never leaves the 1Password SSH agent.

Expected output: `MAMAWORK` / `DadAdmin`.

When this succeeds, the new bootstrap is end-to-end verified and
the small follow-up packet to **remove the legacy DadAdmin_WinNet
line** from `administrators_authorized_keys` becomes drafteable.

## Related

- [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md) -
  parallel packet; diagnoses why TCP/22 from `fedora-top` times out.
- [mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md) -
  separate optional packet for the host-static vs DHCP question.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [fedora-top-admin-backup-ssh-key-strategy-apply-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-apply-2026-05-14.md) -
  the parallel pattern on the fedora-top side.
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
