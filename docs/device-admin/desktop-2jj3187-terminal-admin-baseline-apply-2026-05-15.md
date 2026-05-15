---
title: DESKTOP-2JJ3187 Terminal Admin Baseline Apply - 2026-05-15
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, baseline, evidence, read-only, phase-0]
priority: high
---

# DESKTOP-2JJ3187 Terminal Admin Baseline Apply - 2026-05-15

Apply record for
[desktop-2jj3187-terminal-admin-baseline-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-2026-05-15.md).
Read-only Phase 0 intake; no live host change.

## Apply Context

```text
device:          DESKTOP-2JJ3187
applied_at:      2026-05-15T03:26:52Z
applied_by:      DESKTOP-2JJ3187\jeffr (elevated PowerShell, pwsh 7.6.1)
session_class:   read-only-probe
evidence_path:   C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-baseline-20260515T032652Z\
                 (files 00-run.txt … 11-security.txt; private — not for repo)
```

## Return Shape

```text
device:                                 DESKTOP-2JJ3187
applied_at:                             2026-05-15T03:26:52Z
ssh_user:                               DESKTOP-2JJ3187\jeffr
admin_token_high_integrity:             True
openssh_server_state:                   not-installed
                                        (sshd.exe absent at C:\Windows\System32\OpenSSH\;
                                        Get-WindowsCapability OpenSSH.* threw
                                        Class-not-registered under pwsh 7.6.1)
sshd_config_present:                    False
administrators_authorized_keys_present: False
network_profile_live:                   Private (Ethernet 1 Gbps, 192.168.0.217)
listeners_22_3389:                      22 absent;
                                        3389 listening on 0.0.0.0 and ::
firewall_rules_in_scope:                Jefahnierocks RDP LAN TCP 3389  Enabled Private
                                        Jefahnierocks RDP LAN UDP 3389  Enabled Private
                                        (no SSH / WinRM / Dad-Remote rules present)
scheduled_tasks_by_principal:           per-SID Principal column elided by Format-Table
                                        -AutoSize at terminal width; presence inferred
                                        from path SIDs. \SoftLanding\ and \ (root) hives
                                        for kid RIDs 1001..1004; no Codex-sandbox-account
                                        SIDs surfaced in elided table. Re-run with
                                        Format-Table -Property * if explicit per-principal
                                        counts are needed (template fix noted below).
disk_encryption:                        Off, as attested.
                                        BitLocker None / Fully Decrypted / Protection Off
                                        / 0.0% on C:.
defender:                               RealTimeProtectionEnabled=True
                                        IsTamperProtected=True
                                        AMServiceEnabled=True
                                        AntivirusSignatureLastUpdated 2026-05-14 09:55:19
hibernation_state:                      Hibernation not available (powercfg /a)
                                        HiberbootEnabled=1 in registry but inert
                                        (matches 2026-05-12 RDP-phase posture)
wake_armed_devices:                     HID Keyboard Device
                                        Remote Desktop Mouse Device
                                        HID-compliant mouse (001)
                                        HID Keyboard Device (001)
                                        Intel(R) I211 Gigabit Network Connection
                                        HID Keyboard Device (002)
optional_features_pwsh51_rerun_needed:  yes (anticipated by baseline §Stop Rules)
findings_that_differ:
  - OS build 26200 (24H2/25H2 era), not 26100 from baseline §Known Facts.
    Windows Update advanced between intake and now. Benign for the
    install packet — OpenSSH.Server capability still ships on 26200.
  - SecureBootUEFI=False. Baseline §Expected Findings asked to "capture
    truth"; no expected value. Informational; out of scope for this
    Phase 3 packet.
  - Two cloudflared services present (`cloudflared` and `Cloudflared`,
    both Stopped/Automatic). Pre-existing from the 2026-05-12 intake;
    cleanup deferred to a separate future packet.
  - Get-WindowsCapability -Online "Class not registered" under pwsh
    7.6.1 — anticipated by baseline §Stop Rules. Probably blocks
    install packet §S1 unchanged. (Addressed in install v0.3.0; see
    "Concern Resolved" below.)
  - Residual APIPA interfaces ("AndroidX11 3" and "Bluetooth Network
    Connection" with 169.254.x.x). Ethernet 192.168.0.217 is the live
    interface. Non-blocking; evidence only.
  - jeffr group membership shows
    "NT AUTHORITY\Local account and member of Administrators group"
    + "BUILTIN\Administrators (Group owner)". Token is high-integrity
    elevated admin; matches §Preflight requirements.
followup_packets:
  - desktop-2jj3187-ssh-lane-install-2026-05-15 (v0.3.0 — see below)
  - macbook-ssh-conf-d-desktop-2jj3187-2026-05-15 (already applied
    2026-05-15T03:08:00Z, commit f0fb9c1)
```

## Concern Resolved: pwsh 7 / DISM `Class not registered`

The agent's hand-back flagged that the install packet's §S1
(`Get-WindowsCapability -Online -Name 'OpenSSH.Server*'` +
`Add-WindowsCapability`) would halt under pwsh 7.6.1 on build 26200
with the same `Class not registered` error seen during the baseline.

Resolved in install packet v0.3.0:

- New **§Shell Choice** section at the top of the install packet
  directs the operator to launch Windows PowerShell 5.1
  (`powershell.exe`), not pwsh 7. Confirms via `$PSVersionTable.PSVersion`.
- **§S1 rewritten** to shell DISM-backed cmdlets through
  `powershell.exe -Command` defensively. Both `Get-WindowsCapability`
  and `Add-WindowsCapability` are routed via WinPS 5.1 with
  `ConvertTo-Json -Compress` so the call succeeds whether the operator
  launched from WinPS 5.1 or pwsh 7. The verification readback at the
  end of §S1 also goes through WinPS 5.1.

Net: §S1 will not halt on `Class not registered` in the next apply.

## Baseline Verified Facts

These confirm the install packet's §Expected Findings:

- Hostname `DESKTOP-2JJ3187`; admin user `jeffr` in `Administrators`.
- `Get-Service sshd` absent; OpenSSH Server capability not installed.
- `Get-Service WinRM` Stopped (per posture).
- `Get-Service TermService` Running, Automatic.
- `Get-NetTCPConnection -State Listen` includes 3389 on `0.0.0.0` and `::`;
  22 absent.
- `Get-NetConnectionProfile` shows Private profile on the live LAN
  Ethernet (192.168.0.217).
- Firewall: `Jefahnierocks RDP LAN TCP 3389` + `UDP 3389` Enabled,
  Private. No `Jefahnierocks SSH LAN TCP 22` rule yet (expected; will
  be added by §S6 of install packet).
- BitLocker Off on C:.
- Defender Real-Time Protection enabled with current signatures.
- Codex sandbox SIDs not surfaced in the (elided) scheduled-tasks
  output. The agent's caveat about Format-Table elision is noted; the
  install packet does not depend on this row, but the baseline template
  should be amended to use `-Property` (see "Template Note" below).
- Power: hibernation unavailable; wake-armed devices include the Intel
  I211 NIC (consistent with 2026-05-12 RDP-phase WoL prep).

## Template Note (separate followup)

The baseline template's §08 scheduled-tasks block uses
`Format-Table -AutoSize` which elided the `Principal` column at this
terminal width. For future Windows hosts the template should use
`Format-Table -Property Principal,TaskPath,TaskName,State` + an
`Out-String -Width 240` or equivalent to prevent elision. Not blocking
for DESKTOP-2JJ3187; tracked as a template-improvement item.

## Stop Rules Observed

No stop rule tripped. The Class-not-registered failure for
Get-WindowsCapability matched the baseline's §Stop Rule list (the one
that says "fall back to Windows PowerShell 5.1 for those specific
queries"); the agent treated it as anticipated and surfaced it as
addendum-required for the install packet rather than halting the
baseline.

No out-of-scope surface was touched. The session ran read-only.

## After This Apply

Update `docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- Move `desktop-2jj3187-terminal-admin-baseline` from `prepared_packets[]`
  to `applied_packets[]` with this apply record reference.
- Remove the `desktop-2jj3187-baseline-apply-record-pending` blocked_item.
- Update the `desktop-2jj3187-ssh-lane-install` prepared entry to
  packet_version 0.3.0.
- The device remains lifecycle_phase 2 / classification `rdp-only-host`
  until the Phase 3 install applies and the MacBook real-auth probe
  succeeds.

Next step is to proceed to install §S1 → §S8 from a fresh elevated
Windows PowerShell 5.1 session on DESKTOP-2JJ3187.
