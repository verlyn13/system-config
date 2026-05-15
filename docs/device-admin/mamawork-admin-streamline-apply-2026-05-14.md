---
title: MAMAWORK Admin Surface Streamline Apply - 2026-05-14
category: operations
component: device_admin
status: applied-but-ssh-lockout-persists
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, firewall, accounts, openssh, evidence]
priority: high
---

# MAMAWORK Admin Surface Streamline Apply - 2026-05-14

Operator applied
[mamawork-admin-streamline-packet-2026-05-14.md](./mamawork-admin-streamline-packet-2026-05-14.md)
on MAMAWORK from an elevated PowerShell 7+ session at
`2026-05-14T15:44:01-08:00` (AKDT). All in-scope phases completed
cleanly. The closing Phase 8 MacBook auth probe **still fails** —
not because the streamline didn't do its job, but because the
true root cause of the SSH lockout was **different from the three
hypotheses** the packet was authored against. The handback
identified the actual cause: `sshd_config` has **no
`Match Group administrators` block**, so sshd consults the per-user
`.ssh/authorized_keys` for admin users instead of the system-wide
`administrators_authorized_keys`. All the canonical-key work has
landed in a file sshd never looks at for these users.

Follow-up packet
[`mamawork-sshd-admin-match-block-packet-2026-05-14.md`](./mamawork-sshd-admin-match-block-packet-2026-05-14.md)
adds the missing Match block and closes the lockout.

No live `system-config` host change happened; the operator ran the
script on MAMAWORK and returned a non-secret evidence summary
which is ingested here.

## Approval

Guardian approval matches the packet's "Required Approval Phrase"
section. Operator executed the documented multi-phase script as
`MAMAWORK\jeffr` in an elevated PowerShell 7+ session and returned
the evidence in
[`handback-mamawork-admin-streamline-2026-05-14.md`](./handback-mamawork-admin-streamline-2026-05-14.md).

## Apply Sequence (Actual)

1. Operator extracted the packet's single PowerShell script
   verbatim to a local wrapper
   `apply-mamawork-admin-streamline-2026-05-14.ps1` (UTF-8 no BOM)
   and ran it from elevated PowerShell 7+ as `MAMAWORK\jeffr`.
2. Phase 1 (read-only diagnostic) captured all the documented
   evidence to evidence slot
   `C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-admin-streamline-20260514-154401\`.
3. Phase 2 / Phase 3 decided that none of the three hypothesized
   fixes (owner repair, DACL repair, BOM strip) were needed —
   `administrators_authorized_keys` was already
   `owner=BUILTIN\Administrators`,
   `DACL={SYSTEM:F, Administrators:F}`, first 3 bytes `73 73 68`
   ("ssh-"), no BOM. Phase 3 was a no-op.
4. Phase 4 removed the legacy `DadAdmin_WinNet` line via filtered
   rewrite + UTF-8-no-BOM `[IO.File]::WriteAllLines`; re-applied
   the canonical ACL idempotently.
5. Phase 5 (Disable `DadAdmin` local user) **self-skipped via the
   pre-flight guard**: Phase 1 found 2 scheduled tasks
   (`OneDrive Reporting Task-S-...-1013` and `OneDrive Startup
   Task-S-...-1013`) running as the `DadAdmin` SID, set
   `$skipDisableDadAdmin=$true`, and Phase 5 honored that flag.
   `DadAdmin` remains Enabled.
6. Phase 6 disabled the `Dad Remote Management` firewall rule
   cleanly (`Enabled=False`, rule preserved).
7. Phase 7 captured the final state snapshot.

## Evidence (Operator-Returned, Repo-Safe)

### Identity And Elevation

```text
timestamp:        2026-05-14T15:44:01-08:00 (AKDT)
operator:         MAMAWORK\jeffr (elevated = True)
hostname:         MAMAWORK
slot_dir:         mamawork-admin-streamline-20260514-154401\
```

### Phase 1 Findings

```text
admin_authorized_keys ACL/owner:
  owner_sid:                S-1-5-32-544
  owner_name:               BUILTIN\Administrators
  dacl_principals:
    NT AUTHORITY\SYSTEM     -> FullControl (Allow)
    BUILTIN\Administrators  -> FullControl (Allow)
  has_utf8_bom:             False (first 4 bytes: 73 73 68 2D)

sshd_T_relevant:
  authorizedkeysfile        .ssh/authorized_keys
  authorizedkeyscommand     none
  authorizedkeyscommanduser none
  (live LogLevel DEBUG3; no AuthorizedKeysFile override in sshd -T)

sshd_config_Match_blocks_present:   none      <-- the surprise
sshd_config_d_directory:            NOT PRESENT
sshd_config_Include_directives:     none

openssh_operational_relevant_events: 0 (csv empty; see "Open Items below")

DadAdmin user:
  Enabled=True; SID=...-1013; Description='Remote Management Account'
  LastLogon=12/07/2025 16:27:47

services_as_dadadmin:                0
scheduled_tasks_as_dadadmin:         2
  - OneDrive Reporting Task-S-1-5-21-...-1013 (state=Ready)
  - OneDrive Startup Task-S-1-5-21-...-1013   (state=Ready)

dad_remote_management_rule (pre):    Enabled=True Profile=Any TCP 22
                                     RemoteAddress=192.168.0.0/24

authorized_keys.txt:                 present (96 bytes; first_token='ssh-ed25519';
                                     last_write=2025-12-07 14:29:40;
                                     captured to slot as jeffr_authorized_keys_txt.captured)
DadAdmin.MamaWork profile dir:       present (15,099 entries; inventory CSV in slot)
```

### Phase 3 ACL/BOM Repair Decisions And Outcome

```text
fix_acl_owner_needed:                False (already canonical)
fix_acl_dacl_needed:                 False
fix_bom_needed:                      False
phase_3_acl_repair:                  skipped (no-op)
phase_3_bom_strip:                   skipped
phase_3_status:                      ACL/BOM repair succeeded (no-op)
post_acl_owner:                      BUILTIN\Administrators
post_dacl_principals:                NT AUTHORITY\SYSTEM, BUILTIN\Administrators (FullControl)
```

### Phase 4 Legacy Line Removal

```text
dadadmin_winnet_lines_removed:       1
post_admin_authorized_keys_fingerprints:
  256 SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin (ED25519)
post_admin_authorized_keys_content:  single line, ED25519, canonical key only
post_acl_reapplied:                  yes (idempotent re-grant of SYSTEM:F + Administrators:F)
```

### Phase 5 DadAdmin Disable (Self-Skipped)

```text
phase_5_status:                      SKIPPED via Phase 1 pre-flight guard
                                     ($skipDisableDadAdmin = $true)
reason:                              2 OneDrive scheduled tasks run as DadAdmin SID;
                                     disabling DadAdmin would orphan those tasks
DadAdmin:                            Enabled=True (unchanged)
```

### Phase 6 Dad Remote Management Disable

```text
phase_6_status:                      Enabled=False (disabled successfully)
rule:                                preserved for audit/rollback (Enable-NetFirewallRule
                                     restores it)
```

### Phase 7 Final State Snapshot

```text
inbound rules:
  Jefahnierocks RDP LAN TCP 3389     Enabled=True  Profile=Private TCP 3389 192.168.0.0/24
  Jefahnierocks RDP LAN UDP 3389     Enabled=True  Profile=Private UDP 3389 192.168.0.0/24
  Jefahnierocks SSH LAN TCP 22       Enabled=True  Profile=Private TCP 22   192.168.0.0/24
  Dad Remote Management              Enabled=False Profile=Any     TCP 22   192.168.0.0/24

local Administrators group:
  MamaWork\Administrator             (built-in, disabled)
  MamaWork\ahnie                     (operator's wife's work account;
                                      INTENTIONAL admin per operator clarification 2026-05-14;
                                      Mama / Litecky Editing Services primary user)
  MamaWork\DadAdmin                  (Enabled=True; Phase 5 self-skipped)
  MAMAWORK\jeffr                     (Enabled=True; canonical admin source)

sshd service:                        Running, StartType=Automatic, StartName=LocalSystem
sshd_T live LogLevel:                DEBUG3
```

### Phase 8 MacBook Auth Probe (system-config side)

Run at `2026-05-15T01:50:00Z`:

```bash
ssh -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub \
    -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
    -o IdentitiesOnly=yes \
    -o PreferredAuthentications=publickey \
    -o BatchMode=yes -o ConnectTimeout=5 \
    -o ControlMaster=no -o ControlPath=none \
    -o HostKeyAlias=192.168.0.101 \
    <user>@mamawork.home.arpa 'hostname; whoami'

results (BOTH users):
  jeffr@mamawork.home.arpa     -> Permission denied (publickey,keyboard-interactive)
  DadAdmin@mamawork.home.arpa  -> Permission denied (publickey,keyboard-interactive)
```

**The probe still fails after the streamline.** Removing the legacy
line wasn't the cause of the silent rejection.

## Root Cause Identified — Different From The Hypotheses

The handback's surprise finding 1 captures it:

> None of the three hypothesized root causes for the SSH auth
> failure was present.

And then provides the actual cause via Phase 1's evidence:

```text
sshd_config_Match_blocks_present:    none
sshd_T_relevant authorizedkeysfile:  .ssh/authorized_keys
```

Windows OpenSSH's standard `sshd_config` ships with this block at
the bottom:

```text
Match Group administrators
    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

Without that Match block, sshd consults `.ssh/authorized_keys`
(per-user) for **all** users, including admins. Admin users never
touch `C:\ProgramData\ssh\administrators_authorized_keys` at
authentication time.

On MAMAWORK the Match block is **missing**. Effective AuthorizedKeysFile
for admins is therefore `.ssh/authorized_keys` per-user — which is:

- For `DadAdmin`: `C:\Users\DadAdmin\.ssh\authorized_keys` (unreadable
  by `MAMAWORK\jeffr` per the bootstrap apply's Step-4 ACL gap; sshd
  may or may not be able to read it as SYSTEM, but the canonical
  key was never written here).
- For `jeffr`: `C:\Users\jeffr\.ssh\authorized_keys` (the bootstrap
  packet did NOT write here; only `authorized_keys.txt` exists at
  that path, which sshd ignores because of the non-standard
  filename).
- For `Administrator`: `C:\Users\Administrator\.ssh\authorized_keys`
  (account disabled; file likely absent).

All three admins fail auth identically because the system-wide
admin file is dead code without the Match block.

The fix is to **add the standard Windows OpenSSH `Match Group
administrators` block to `sshd_config`** and reload sshd. Drafted as
[`mamawork-sshd-admin-match-block-packet-2026-05-14.md`](./mamawork-sshd-admin-match-block-packet-2026-05-14.md).

## What Did Close

The streamline packet's in-scope work all succeeded:

- The legacy `DadAdmin_WinNet` dangling line is gone.
- `administrators_authorized_keys` is verified canonical (owner,
  DACL, encoding all correct).
- The `Dad Remote Management` firewall rule is disabled.
- `Jefahnierocks SSH LAN TCP 22` is the sole TCP/22 allow path
  (Private, 192.168.0.0/24).
- All HARD-NOT-TOUCH boundaries held.
- A surprise admin-account classification was corrected: `ahnie`
  is the operator's wife's work account (Mama / Litecky operator),
  intentional admin so she can install software for her work — NOT
  a kid account as earlier intake characterized.

The streamline laid clean groundwork for the Match-block fix to
land on. Without it, the Match block alone would have left the
legacy dangling line in place and the dead `Dad Remote Management`
rule still enabled — both confusing surface area while debugging.

## Boundary Assertions

The apply did NOT change any of the following:

- `sshd_config`, `sshd_config.d/`. The Match-block addition is
  the separate follow-up packet.
- `C:\Users\jeffr\.ssh\authorized_keys.txt` (inventory only).
- `C:\Users\DadAdmin.MamaWork\` directory (inventory only).
- `C:\Users\DadAdmin\.ssh\authorized_keys` per-user file
  (separate ACL gap).
- `HKLM\Software\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*`.
- `powercfg`, NIC wake, Defender, ASR, BitLocker, Secure Boot,
  TPM, WinRM, PSRemoting.
- Cloudflare, WARP, `cloudflared`, Tailscale, OPNsense, DNS,
  DHCP, 1Password.
- `ahnie` account (read-only enumeration in Phase 7 only).
- Kid accounts (`axelp`, `ilage`, `wynst`), `jeffr` MS Account,
  built-in `Administrator`.
- The `DadAdmin` local user (Phase 5 self-skipped).
- RDP host-side state.

## Rollback

Not used. To revert the streamline:

```powershell
$SLOT = 'C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-admin-streamline-20260514-154401'

# Phase 4 rollback (restore legacy DadAdmin_WinNet line):
Copy-Item -Force -Path "$SLOT\admin_authorized_keys.before" `
          -Destination 'C:\ProgramData\ssh\administrators_authorized_keys'
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /inheritance:r
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /grant 'SYSTEM:F'
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /grant 'Administrators:F'

# Phase 6 rollback (re-enable Dad Remote Management):
Enable-NetFirewallRule -DisplayName 'Dad Remote Management'
```

Neither rollback is recommended; the streamline state is the
correct posture going forward.

## Open Items

1. **`mamawork-sshd-admin-match-block-packet`** — the actual SSH
   fix. Small, focused, append-only edit to `sshd_config` followed
   by `Restart-Service sshd`. Closing success criterion is the
   real auth probe from MacBook.
2. **`DadAdmin` disable held back on OneDrive scheduled tasks**.
   Surface to operator: are the two OneDrive tasks
   (`OneDrive Reporting Task-S-...-1013`,
   `OneDrive Startup Task-S-...-1013`) still wanted? Three options:
   - Re-register them under another principal first
     (`Set-ScheduledTask -Principal ...`), then Disable-LocalUser
     DadAdmin in a tiny follow-up packet.
   - Unregister them (`Unregister-ScheduledTask`) if OneDrive sync
     is no longer wanted from that profile.
   - Accept that `DadAdmin` stays enabled indefinitely; treat the
     account as the OneDrive-task principal only and revoke its
     admin membership instead.
3. **`ahnie` account classification correction propagated to docs**:
   the streamline apply confirmed `ahnie` is in the local
   `Administrators` group. Per operator clarification 2026-05-14,
   `ahnie` is intentional admin (wife's work account, Mama, Litecky
   Editing Services primary user). The `current-status.yaml`
   intake-derived account block, `windows-pc-mamawork.md` accounts
   row, and `handoff-mamawork.md` Q3 all need updating from
   "kid MS Account / anomaly to confirm" to the corrected
   characterization. Doc-only follow-up (updates landing in the
   same commit as this apply record).
4. **OpenSSH/Operational 0-events anomaly**: Phase 1's keyword-
   filtered query returned 0 matching events despite DEBUG3 log
   level. Surface for the Match-block packet's diagnostic phase
   (capture unfiltered tail immediately after a fresh auth probe).
5. **`authorized_keys.txt` resolution**: 96-byte ED25519 line
   captured to slot. The Match-block fix should make sshd actually
   honor `administrators_authorized_keys`, at which point the
   `.txt` non-standard file becomes irrelevant for auth and can
   be deleted in a small follow-up packet
   (`mamawork-authorized-keys-txt-resolution-packet`).
6. **`DadAdmin.MamaWork\` profile dir (15,099 entries)**: inventory
   CSV in slot for operator review. Follow-up packet decision.
7. **Surprise: SSH host keys also recorded in handback as having
   been generated `2025-12-07 13:47`** (per windows-pc-mamawork.md).
   Phase 1 also captured `sshd_config.before`. Nothing else
   actionable from this; recorded for completeness.

## Related

- [mamawork-admin-streamline-packet-2026-05-14.md](./mamawork-admin-streamline-packet-2026-05-14.md) -
  the packet this apply executed.
- [handback-mamawork-admin-streamline-2026-05-14.md](./handback-mamawork-admin-streamline-2026-05-14.md) -
  operator's full handback narrative + surprise findings.
- [mamawork-sshd-admin-match-block-packet-2026-05-14.md](./mamawork-sshd-admin-match-block-packet-2026-05-14.md) -
  the actual SSH fix (separate small packet).
- [mamawork-ssh-key-bootstrap-apply-2026-05-14.md](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md) -
  the bootstrap that put the canonical key in
  `administrators_authorized_keys`. The Match-block fix is what
  makes sshd actually consult that file.
- [mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md) -
  the LAN reachability fix that preceded this one.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)
