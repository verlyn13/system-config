---
title: MAMAWORK SSH Key Bootstrap Apply - 2026-05-14
category: operations
component: device_admin
status: applied-remote-verify-fails-server-side
version: 0.2.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, openssh, admin-key, evidence]
priority: high
---

> **2026-05-14 v0.2.0 changes**: ingested system-config-run
> remote-verify probes from the MacBook
> (`2026-05-14T23:30:00Z`). Result: MacBook → MAMAWORK SSH pubkey
> authentication is rejected by the server for three admin
> usernames (`DadAdmin`, `jeffr`, `Administrator`), even though
> the verbose-mode client confirms the correct key
> (`SHA256:qilvkR7/...`) is offered via the 1Password SSH agent
> and the matching public-key line is present in
> `administrators_authorized_keys` per this packet's evidence.
> Root cause is on MAMAWORK: most likely a file ACL / owner /
> encoding issue that causes Windows OpenSSH to silently ignore
> the file. Read-only diagnostic is queued; see the inbound TCP
> blackhole remediation apply record's "Next Diagnostic Step"
> section.

# MAMAWORK SSH Key Bootstrap Apply - 2026-05-14

Operator applied
[mamawork-ssh-key-bootstrap-packet-2026-05-14.md](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md)
on MAMAWORK from an elevated PowerShell 7+ session. The
authoritative install of the new `verlyn13@mamawork-admin` public-
key line into `C:\ProgramData\ssh\administrators_authorized_keys`
occurred during the operator's morning session at
`2026-05-14T08:40:59-08:00` (AKDT). A formal re-run inside the
evening apply wrapper at `2026-05-14T14:47:51-08:00` confirmed the
install was idempotent (Step 3 took the "identical line already
present" skip branch with no file mutation).

Local verification is complete; **remote SSH login verification
from the MacBook is pending** until the operator returns the
post-remediation LAN nc probes that confirm TCP/22 reachability.

No live `system-config` host change happened; the operator ran the
script on MAMAWORK and returned a non-secret evidence summary
which is ingested here.

## Approval

Guardian approval matches the packet's
[Required Approval Phrase](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md#required-approval-phrase)
section. The new public-key body
(`ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2FlNNQ337TaP51lwouo/5+ZIG2WGy431b4UxtYIHnH verlyn13@mamawork-admin`,
fingerprint `SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY`,
1Password item
`op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13`) was
copied from the operator MacBook (where 1Password is installed) and
pasted into the PowerShell `$NewPubKeyLine` variable on MAMAWORK.
No `op` call ran on MAMAWORK.

## Apply Sequence (Actual)

### Morning session (authoritative install)

```text
slot:        C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-ssh-key-bootstrap-20260514-084059\
timestamp:   2026-05-14T08:40:59-08:00 (AKDT)
operator:    MAMAWORK\jeffr (elevated)
outcome:     Step 3 wrote the new key line to
             C:\ProgramData\ssh\administrators_authorized_keys.
             Step 2 fingerprint check matched
             SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY.
             Step 4 mirror into
             C:\Users\DadAdmin\.ssh\authorized_keys: see "ACL Gap
             Discovered" below.
```

This is the apply that actually installed the key. Evidence
artefacts are in the morning slot directory. The operator did not
return individual files for this session in the prior chat
hand-back; the evening idempotent re-run confirms the state.

### Evening session (idempotent confirmation)

```text
slot:        C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-ssh-key-bootstrap-20260514-144751\
timestamp:   2026-05-14T14:47:51-08:00 (AKDT)
operator:    MAMAWORK\jeffr (elevated)
outcome:     Step 3 took the idempotent skip branch: "identical
             public-key line already present in
             administrators_authorized_keys". No file mutation.
             Step 4 mirror into DadAdmin per-user authorized_keys
             failed Access denied (see "ACL Gap Discovered").
             Steps 0, 1, 2, 5 succeeded normally.
```

The evening session ran inside the apply wrapper
`apply-mamawork-blackhole-and-sshkey-2026-05-14.ps1` alongside the
inbound TCP blackhole remediation.

## Evidence (Operator-Returned, Repo-Safe)

### Identity And Elevation

```text
hostname:                 MAMAWORK
operator:                 MAMAWORK\jeffr
elevation:                yes (True)
session timestamp:        2026-05-14T14:47:51-08:00 (evening confirm)
                          (authoritative install at
                           2026-05-14T08:40:59-08:00)
```

### Fingerprint Verification (Step 2)

```text
expected_fingerprint:     SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY
computed_fingerprint:     SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY
result:                   match (proceed)
```

### `administrators_authorized_keys` Posture

```text
path:                     C:\ProgramData\ssh\administrators_authorized_keys
before fingerprints (evening session):
                          SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk DadAdmin_WinNet (ED25519)
                          SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin (ED25519)
after fingerprints (evening session):
                          SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk DadAdmin_WinNet (ED25519)
                          SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin (ED25519)
Step 3 outcome:           skip - identical public-key line already
                          present (idempotent)
```

The new canonical admin key is present alongside the legacy
`DadAdmin_WinNet` entry. The legacy entry's private half is
confirmed NOT on `fedora-top` per the 2026-05-14 operator check;
its removal is deferred to a small follow-up packet after the new
key is verified end-to-end.

### DadAdmin Per-User `authorized_keys` (Step 4)

```text
path:                     C:\Users\DadAdmin\.ssh\authorized_keys
before fingerprints:      UNREADABLE - Access denied for elevated
                          MAMAWORK\jeffr
after fingerprints:       UNREADABLE - Access denied
Step 4 outcome:           FAILED Access denied (see "ACL Gap
                          Discovered" below)
```

### `sshd` Service And Config

```text
sshd service Status:      Running
sshd service StartType:   not captured in this snapshot (confirm separately)
sshd_config relevant directives:
  Port 22
  LogLevel DEBUG3
  PubkeyAuthentication yes
  PasswordAuthentication no
  AuthorizedKeysFile .ssh/authorized_keys
  StrictModes no
  AllowUsers / AllowGroups / ListenAddress not present in config
```

`PasswordAuthentication no` and `PubkeyAuthentication yes` are
preserved per scope. The hardening of `sshd_config` (LogLevel,
StrictModes, AllowGroups, removing `DadAdmin_WinNet`, reconciling
`C:\Users\jeffr\.ssh\authorized_keys.txt`) is the future
`mamawork-ssh-hardening` packet, deliberately out of scope here.

### Remote Verification

```text
from operator MacBook (1P SSH agent serves the new key's private half),
run by system-config 2026-05-14T23:30:00Z:

   ssh -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub \
       -o IdentityAgent=$HOME/.1password-ssh-agent.sock \
       -o IdentitiesOnly=yes \
       -o PreferredAuthentications=publickey \
       -o BatchMode=yes \
       <user>@192.168.0.101 'hostname; whoami'

users tried:
   DadAdmin       -> Permission denied (publickey,keyboard-interactive)
   jeffr          -> Permission denied (publickey,keyboard-interactive)
   Administrator  -> Permission denied (publickey,keyboard-interactive)

client offering (verified via ssh -vvv):
   /Users/verlyn13/.ssh/id_ed25519_mamawork_admin.1password.pub
   ED25519 SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY
   sourced "explicit agent" (from 1P SSH agent socket)

result:   FAILED. Authentication rejected by MAMAWORK Windows
          OpenSSH for all three admin users. LAN reachability is
          fine (the 4 MacBook -> MAMAWORK nc probes all succeed
          on TCP/22 + TCP/3389). The matching public-key line is
          confirmed present in administrators_authorized_keys per
          the morning bootstrap's evidence. Root cause is on the
          server: most likely an ACL / owner / encoding issue on
          C:\ProgramData\ssh\administrators_authorized_keys that
          causes Windows OpenSSH to silently ignore the file.
          See "Next Diagnostic Step" in
          [mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md)
          for the read-only PowerShell investigation to run on
          MAMAWORK.

macbook artefact:
   ~/.ssh/id_ed25519_mamawork_admin.1password.pub  (new; non-secret;
       extracted from 1P SSH agent; mode 644). Matches the existing
       chezmoi-style id_ed25519_*.1password.pub naming pattern.
       Candidate for chezmoi-managed inclusion alongside a
       ~/.ssh/conf.d/mamawork.conf host entry.
```

Per [feedback-1password-managed-device-assumption](#related), the
SSH client invocation runs on the MacBook only.

## ACL Gap Discovered

`C:\Users\DadAdmin\.ssh\authorized_keys` is unreadable by
elevated `MAMAWORK\jeffr` (a different administrator account).
Both Step 1 (pre-snapshot read) and Step 4 (mirror write) fail
Access denied even with elevation. The directory's ACL appears to
restrict access to the `DadAdmin` SID itself, plus possibly SYSTEM,
without explicit `Administrators` inheritance.

**Operational impact**: nil. Windows OpenSSH for users in the local
`Administrators` group (which includes `DadAdmin`) consults
`C:\ProgramData\ssh\administrators_authorized_keys`, NOT the
per-user `authorized_keys`. The per-user file at
`C:\Users\DadAdmin\.ssh\authorized_keys` is therefore not on the
authentication path for the admin SSH lane. Step 4's mirror was
defensive consistency, not a functional requirement.

**Deferred packet**:
`mamawork-dadadmin-authorized-keys-acl-repair-packet` (to be
drafted) will normalize the ACL so future hardening packets can
read/write the per-user file. Approach options:
`icacls "C:\Users\DadAdmin\.ssh" /grant Administrators:F /T`,
or take ownership of the directory tree first via `takeown /F /R`.
Either is a hardening packet decision; treat as low priority and
not blocking remote admin.

## Sequencing With The Inbound TCP Blackhole Remediation

The SSH key bootstrap is independent of LAN reachability (it only
writes to local files on MAMAWORK). Both the morning install
session and the evening idempotent re-run happened before the LAN
inbound TCP path was fully open at the firewall level. End-to-end
remote verification waits until the
[inbound TCP blackhole remediation apply](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md)
records the LAN nc probes as succeeding.

## Boundary Assertions

The apply did NOT change any of the following:

- The legacy `DadAdmin_WinNet` line in
  `administrators_authorized_keys`. Deferred to a small follow-up
  packet after end-to-end verification.
- `sshd_config`, `sshd_config.d/`, or any sshd hardening
  directive. Hardening is the separate
  `mamawork-ssh-hardening` packet.
- `C:\Users\jeffr\.ssh\authorized_keys.txt` (the non-standard
  filename observed at intake).
- `C:\Users\DadAdmin.MamaWork\` profile copy.
- Windows Firewall rules (the new `Jefahnierocks SSH LAN TCP 22`
  rule came from the blackhole remediation, not this packet).
- RDP, WinRM, PSRemoting, accounts, groups, BitLocker, Secure
  Boot, TPM, Defender, ASR, powercfg, NIC wake-policy.
- Cloudflare, WARP, `cloudflared`, Tailscale, OPNsense, DNS, DHCP.
- 1Password items from MAMAWORK's side. No `op` call ran on
  MAMAWORK; the new public-key body was operator-pasted from a
  retrieval on the MacBook.

## Rollback

Not used. Rollback was authored as restoring the pre-snapshot from
the morning slot:

```powershell
$SNAP = 'C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-ssh-key-bootstrap-20260514-084059'
if (Test-Path "$SNAP\administrators_authorized_keys.before") {
    Copy-Item -Force -Path "$SNAP\administrators_authorized_keys.before" `
              -Destination 'C:\ProgramData\ssh\administrators_authorized_keys'
}
```

## Open Items

1. **Remote verification from the MacBook**: pending the inbound
   TCP blackhole remediation's LAN nc probes succeeding. When
   probes succeed, run the `ssh ... DadAdmin@mamawork.home.arpa
   'hostname; whoami'` invocation from the MacBook (using the
   1Password SSH agent) and append result here.
2. **Legacy `DadAdmin_WinNet` line removal**: drafteable as a
   small follow-up packet after remote verification succeeds.
3. **DadAdmin per-user `authorized_keys` ACL repair**:
   drafteable, low priority, not blocking the admin SSH lane.
4. **`sshd_config` hardening** (LogLevel, StrictModes, AllowGroups,
   non-standard `authorized_keys.txt` reconciliation): future
   `mamawork-ssh-hardening` packet.

## Remaining Blockers

None for local key installation. The end-to-end verification block
above is the next thing that closes once the LAN probes succeed.

## Related

- [mamawork-ssh-key-bootstrap-packet-2026-05-14.md](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md) -
  the packet this apply executed (v0.2.0; the 1P-on-managed-device
  clarification did not affect the apply procedure itself).
- [mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md) -
  parallel apply in the same elevated PowerShell session.
- [fedora-top-admin-backup-ssh-key-strategy-apply-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-apply-2026-05-14.md) -
  the parallel pattern on the fedora-top side.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
