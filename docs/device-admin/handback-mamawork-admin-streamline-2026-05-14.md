# MAMAWORK hand-back — admin-streamline apply, 2026-05-14

Packet applied: `mamawork-admin-streamline-packet-2026-05-14.md`
(approved by system-config 2026-05-15T01:00:00Z;
operator-approved on MAMAWORK this session, 2026-05-14T15:44:01-08:00).

Apply wrapper: `apply-mamawork-admin-streamline-2026-05-14.ps1`
(extracted verbatim from the packet's single ```powershell block;
UTF-8 no BOM; 15,066 bytes).

Evidence slot:
`C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-admin-streamline-20260514-154401\`

```text
timestamp:                                 2026-05-14T15:44:01-08:00
operator:                                  MAMAWORK\jeffr
elevation:                                 yes (True)
hostname:                                  MAMAWORK
slot_dir:                                  mamawork-admin-streamline-20260514-154401\

PHASE 1 findings (read-only diagnostic):
  owner_sid:                               S-1-5-32-544
  owner_name:                              BUILTIN\Administrators
  dacl_principals:                         NT AUTHORITY\SYSTEM -> FullControl (Allow)
                                           BUILTIN\Administrators -> FullControl (Allow)
  file_first_4_bytes_hex:                  73 73 68 2D ("ssh-" — start of ssh-ed25519)
  has_utf8_bom:                            False
  sshd_T_relevant:                         authorizedkeysfile .ssh/authorized_keys
                                           authorizedkeyscommand none
                                           authorizedkeyscommanduser none
                                           (live LogLevel DEBUG3; no AuthorizedKeysFile override)
  sshd_config_Match_blocks_present:        none
  sshd_config_d_directory:                 NOT PRESENT
  sshd_config_Include_directives:          none
  openssh_operational_relevant_events:     0 (csv empty — see "Surprise findings" below)
  dadadmin_user:                           Enabled=True SID=...-1013 Description='Remote Management Account' LastLogon=12/07/2025 16:27:47
  services_as_dadadmin:                    0
  scheduled_tasks_as_dadadmin:             2
    - OneDrive Reporting Task-S-1-5-21-...-1013 (state=Ready)
    - OneDrive Startup Task-S-1-5-21-...-1013   (state=Ready)
  dad_remote_management_rule (pre):        Enabled=True Profile=Any TCP 22 RemoteAddress=192.168.0.0/24
  authorized_keys_txt:                     present size=96 bytes first_token='ssh-ed25519' last_write=2025-12-07 14:29:40
                                           (captured to slot as jeffr_authorized_keys_txt.captured)
  dadadmin_mamawork_profile_dir:           present entries=15099 (inventory CSV in slot, 2.8 MB)

PHASE 2 decisions:
  fix_acl_owner_needed:                    False (owner='BUILTIN\Administrators' — already canonical)
  fix_acl_dacl_needed:                     False
  fix_bom_needed:                          False

PHASE 3 ACL/BOM repair:
  phase_3_bom_strip:                       skipped (no BOM)
  phase_3_acl_repair:                      skipped (owner + DACL already canonical)
  post_acl_owner:                          BUILTIN\Administrators
  post_dacl_principals:                    NT AUTHORITY\SYSTEM, BUILTIN\Administrators (FullControl, Allow)
  phase_3_status:                          ACL/BOM repair succeeded (no-op)

PHASE 4 legacy line removal:
  dadadmin_winnet_lines_removed:           1
  post_admin_authorized_keys_fingerprints:
    256 SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin (ED25519)
  post_admin_authorized_keys_content:      single line, ED25519, canonical key only
                                           (legacy DadAdmin_WinNet line gone)
  post_acl_reapplied:                      yes (idempotent re-grant of SYSTEM:F + Administrators:F)

PHASE 5 DadAdmin disable:
  phase_5_status:                          SKIPPED — Phase 1 found 2 scheduled tasks running as
                                           the DadAdmin SID (both OneDrive). The script's
                                           pre-flight guard set $skipDisableDadAdmin=$true.
                                           DadAdmin local user remains Enabled. Manual review
                                           required before any future disable: either move/
                                           remove the OneDrive scheduled tasks first, or
                                           accept that DadAdmin stays enabled for OneDrive's
                                           sake.

PHASE 6 Dad Remote Management disable:
  phase_6_status:                          Enabled=False (disabled successfully; rule preserved
                                           for audit/rollback via Enable-NetFirewallRule)

PHASE 7 final-state snapshot:
  rule: Jefahnierocks RDP LAN TCP 3389     Enabled=True  Profile=Private TCP 3389 192.168.0.0/24
  rule: Jefahnierocks RDP LAN UDP 3389     Enabled=True  Profile=Private UDP 3389 192.168.0.0/24
  rule: Jefahnierocks SSH LAN TCP 22       Enabled=True  Profile=Private TCP 22   192.168.0.0/24
  rule: Dad Remote Management              Enabled=False Profile=Any     TCP 22   192.168.0.0/24
  local Administrators group members:      MamaWork\Administrator (Enabled=False, built-in)
                                           MamaWork\ahnie         (see "Account discrepancy" below)
                                           MamaWork\DadAdmin      (Enabled=True; Phase 5 skipped)
                                           MAMAWORK\jeffr         (Enabled=True; canonical admin)

sshd service after:                        Running, StartType=Automatic, StartName=LocalSystem
sshd_T live LogLevel:                      DEBUG3

evidence_slot_files:
  admin_authorized_keys.before             204 bytes (pre-state, both keys)
  admin_authorized_keys.after              106 bytes (post-state, canonical key only)
  admin_authorized_keys.acl.before.txt     364 bytes (Get-Acl Format-List capture)
  admin_authorized_keys.fingerprints.after.txt  90 bytes (ssh-keygen -lf output)
  sshd_T_effective.txt                     4,207 bytes (full live sshd -T)
  sshd_config.before                       1,420 bytes (sshd_config snapshot)
  jeffr_authorized_keys_txt.captured       96 bytes (copy of jeffr's non-standard authorized_keys.txt)
  dadadmin_mamawork_profile_inventory.csv  2.8 MB (15,099 entries)
  openssh_operational_recent.csv           0 bytes (empty — no matching events found)
  streamline.txt                           3,995 bytes (top-level evidence)

credentials_in_repo_chat_argv:             None
remaining_blockers:                        See "Open items for system-config" below.
```

## Surprise findings

### 1. None of the three hypothesized root causes for the SSH auth failure was present

- ACL is **already canonical**: owner=`BUILTIN\Administrators`,
  DACL={`NT AUTHORITY\SYSTEM`:F, `BUILTIN\Administrators`:F}.
- File has **no UTF-8 BOM**: first 3 bytes are `73 73 68`
  (the literal `ssh` of `ssh-ed25519`).
- `sshd_config` has **no `Match` blocks**; no `sshd_config.d/`
  directory exists; no `Include` directives in sshd_config. Effective
  `sshd -T` shows only the default `authorizedkeysfile .ssh/authorized_keys`
  with no override.

The streamline packet was authored on the working hypothesis that
one of those three was wrong. They aren't. Yet the 2026-05-15T00:15Z
MacBook auth probe failed with `Permission denied (publickey)` for
three usernames. So one or both of the following is true:

- The **pre-Phase-4 file had a parsing issue** caused by the legacy
  `DadAdmin_WinNet` line (malformed first line, trailing whitespace,
  embedded NULs, CRLF/LF mix that sshd's parser rejected) that
  silently invalidated the file. **Phase 4 removed that line**, so
  the post-state file is now a single clean ED25519 line. Phase 8's
  auth probe is the test.
- Something else is wrong on the server side that this packet didn't
  cover.

### 2. OpenSSH/Operational has 0 events matching the search pattern despite live LogLevel DEBUG3

`Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 200` filtered
on `AuthorizedKeysFile | pubkey | administrators_authorized_keys |
publickey | authentication failed` returned 0 hits and wrote a
0-byte CSV. DEBUG3 should be loud. Two possibilities for
system-config's Phase 8:

- The OpenSSH Windows event-log channel may emit messages whose text
  differs from what the regex expects. Try **without keyword filtering**:
  `Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 50` and
  inspect raw messages.
- The 2026-05-15T00:15Z auth attempts may have rotated out of the
  log buffer before this Phase 1 captured. Recommend Phase 8 capture
  the OpenSSH/Operational tail **immediately after** the auth probe
  fires, then ingest into the apply record.

### 3. Phase 5 self-skipped — 2 OneDrive scheduled tasks run as DadAdmin

The pre-flight guard worked correctly: it found
`OneDrive Reporting Task-S-...-1013` and `OneDrive Startup Task-S-...-1013`
both registered to the DadAdmin SID, and set `$skipDisableDadAdmin=$true`.
Disabling DadAdmin would have orphaned those tasks.

Before any future packet attempts to disable DadAdmin, decide:

- Are those OneDrive tasks still wanted? (`Get-ScheduledTask -TaskName "OneDrive*"`
  details + `(Get-ScheduledTask -TaskName "OneDrive Startup Task-S-..." | Get-ScheduledTaskInfo).LastRunTime`)
- If yes: re-register them under another principal first
  (`Set-ScheduledTask -Principal ...`).
- If no: `Unregister-ScheduledTask` them, then re-run a small disable-DadAdmin packet.

### 4. Account discrepancy — `ahnie` is in `Administrators` and is *not* a kid account

Phase 7's `Get-LocalGroupMember -Group 'Administrators'` enumerated:

```text
MamaWork\Administrator (built-in, disabled)
MamaWork\ahnie
MamaWork\DadAdmin
MAMAWORK\jeffr
```

`current-status.yaml` (lines 152-158) characterizes `ahnie` as a
"kid MS Account; not admin". **Both halves of that are wrong** per
this run's evidence plus operator clarification this session:

- `ahnie` IS in the local `Administrators` group on MAMAWORK.
- `ahnie` is **the operator's wife's work account** (the "Mama"
  user named elsewhere in `current-status.yaml` as the
  "primary user with Litecky Editing Services workload"). NOT a kid
  account.

This run did NOT modify `ahnie` (Phase 7 was read-only enumeration only).
Per operator instruction this session, `ahnie` is hands-off. Recommend
system-config update the `current-status.yaml` MAMAWORK accounts block
to reflect:

- `ahnie` is the wife's work account (Mama / Litecky operator).
- `ahnie` is a local Administrator (not "not admin").
- `axelp`, `ilage`, `wynst` characterization untested in this run;
  treat as still-claimed-kid-accounts pending operator confirmation.

This finding also has implications for the WARP cutover sequencing.
The later 2026-05-15 Windows multi-user addendum corrects the target:
Mama / `ahnie` should land in an adult/work Cloudflare profile, not a
Kids-for-whole-machine fallback, if Windows multi-user mode is viable.

## What's now true

- `administrators_authorized_keys` contains exactly one canonical key
  line: `SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin`.
  Owner + DACL canonical. No BOM. No trailing legacy line.
- `Dad Remote Management` firewall rule is **disabled** (not removed).
  The only inbound TCP/22 allow is now `Jefahnierocks SSH LAN TCP 22`
  (Profile=Private, RemoteAddress=192.168.0.0/24).
- `DadAdmin` local user is **still Enabled** (Phase 5 self-skipped
  because of the OneDrive scheduled tasks).
- `authorized_keys.txt` and `DadAdmin.MamaWork\` were **read-only**
  inventoried, not modified.
- All HARD-NOT-TOUCH boundaries held: `sshd_config`, `DadAdmin\.ssh\
  authorized_keys` per-user file, HKLM NetworkList registry, kid
  accounts, `jeffr` MS Account, built-in `Administrator`, RDP rules,
  BitLocker/Secure Boot/TPM/Defender/ASR/powercfg/NIC wake/Cloudflare/
  WARP/Tailscale/OPNsense/DNS/DHCP/1Password. `ahnie` not touched.

## Open items for system-config

1. **Run Phase 8** (MacBook-side `ssh jeffr@mamawork.home.arpa 'hostname; whoami'`
   via 1P SSH agent). If it now PASSES, the legacy `DadAdmin_WinNet`
   line parsing was the actual root cause and the packet is `applied`.
   If it FAILS, root cause is still unidentified — see item 2.
2. **If Phase 8 fails**, capture `OpenSSH/Operational` log tail
   **without** keyword filter immediately after the failed probe.
   Also worth capturing: `[IO.File]::ReadAllBytes($F)` over the
   post-state file to verify line endings (CRLF vs LF), trailing
   whitespace, and the canonical line's exact byte sequence. This
   was not done in the streamline packet because all three obvious
   causes were the hypothesized ones.
3. **Update `current-status.yaml` MAMAWORK accounts block**: `ahnie`
   is wife's work account (Mama), is local Administrator. See "Account
   discrepancy" above. Re-verify `axelp` / `ilage` / `wynst` with the
   operator before further account-related packets.
4. **DadAdmin scheduled tasks decision**: surface the 2 OneDrive tasks
   to the operator with options (re-register under another principal
   vs. unregister vs. keep DadAdmin enabled forever). Disabling
   DadAdmin via the streamlined approach is blocked until that's
   resolved.
5. **`authorized_keys.txt` content**: 96-byte ED25519 line, captured
   to slot as `jeffr_authorized_keys_txt.captured`. Operator decision
   on what to do with this non-standard file is now drafteable as the
   small follow-up packet `mamawork-authorized-keys-txt-resolution-packet`
   already noted in the streamline packet's sequencing section.
6. **`DadAdmin.MamaWork\` profile (15,099 entries, CSV in slot)**:
   operator review pending; the streamline packet noted this becomes
   a small follow-up packet decision after the streamlined surface
   is verified working.

## Boundary assertions

After this apply, the following are unchanged:

- `sshd_config` and `sshd_config.d/` (no Match blocks added; LogLevel
  remains DEBUG3 from prior state; `PasswordAuthentication no` and
  `PubkeyAuthentication yes` preserved).
- `C:\Users\jeffr\.ssh\authorized_keys.txt` content (inventory only).
- `C:\Users\DadAdmin.MamaWork\` directory tree (inventory only).
- `C:\Users\DadAdmin\.ssh\authorized_keys` per-user file (separate
  ACL gap; out of scope).
- `HKLM\Software\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*`
  (stale `Bob's Internet 2` Public profile retained; future packet).
- `powercfg`, NIC wake-policy, Defender, ASR, BitLocker, Secure Boot,
  TPM, WinRM, PSRemoting.
- Cloudflare, WARP, `cloudflared`, Tailscale, OPNsense, DNS, DHCP,
  1Password.
- **`ahnie` account** — read-only enumeration in Phase 7 only.
- Kid Windows accounts (`axelp`, `ilage`, `wynst`) — not enumerated
  beyond Phase 7's admin-group listing.
- Microsoft Account `jeffr` privileges (stays admin).
- Built-in `Administrator` (stays disabled).
- The `DadAdmin` local user is **still Enabled** (Phase 5 self-skipped).
- The `Dad Remote Management` firewall rule is **Disabled, not
  removed** (rollback via `Enable-NetFirewallRule`).
- The legacy `DadAdmin_WinNet` line is REMOVED from
  `administrators_authorized_keys`. Pre-state snapshot in
  `admin_authorized_keys.before` allows reinstatement if ever
  necessary (private half is missing on fedora-top and the MacBook
  per prior checks; reinstatement very unlikely).

## File map

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\
├── apply-mamawork-admin-streamline-2026-05-14.ps1
├── mamawork-admin-streamline-20260514-154401\
│   ├── streamline.txt                              (top-level evidence)
│   ├── admin_authorized_keys.before                (both keys, pre-Phase-4)
│   ├── admin_authorized_keys.after                 (canonical key only)
│   ├── admin_authorized_keys.acl.before.txt        (Get-Acl Format-List)
│   ├── admin_authorized_keys.fingerprints.after.txt
│   ├── sshd_T_effective.txt                        (full live sshd -T)
│   ├── sshd_config.before                          (sshd_config snapshot)
│   ├── jeffr_authorized_keys_txt.captured          (copy of jeffr's authorized_keys.txt)
│   ├── dadadmin_mamawork_profile_inventory.csv     (15099 entries)
│   ├── openssh_operational_recent.csv              (0 bytes; see Surprise finding 2)
│   └── icacls.txt                                  (NOT PRESENT — Phase 3 ran no icacls)
└── handback-mamawork-admin-streamline-2026-05-14.md   <-- this file
```

No secrets in any of these files. Public-key bodies and fingerprints
are public artifacts. ACL strings, sshd config text, and account SIDs
are non-secret.
