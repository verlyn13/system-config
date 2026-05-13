---
title: Windows PC Device Administration Record
category: operations
component: device_admin
status: draft
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, windows, rdp, bitlocker, firewall, 1password]
priority: high
---

# Windows PC Device Administration Record

This scaffold captures non-secret administration posture for the Windows PC.
It is an intake record only until approved live changes are performed.

## Source Input

Ingested source: `/Users/verlyn13/Downloads/plan (1).md`.

The source report was captured from the Windows host on 2026-05-12, mostly from
a non-elevated PowerShell session. Treat its current-state observations as
planning evidence that still needs targeted re-verification during execution,
especially anything requiring elevation.

The source report's build plan is not authoritative for Jefahnierocks
administration. Access setup, WARP enrollment, Cloudflare routing, OPNsense
Wake-on-LAN, 1Password records, and device-side changes must be translated into
the local `system-config`, `cloudflare-dns`, and HomeNetOps standards before
execution.

## Returned Readiness Updates

External evidence ingested from:

- `/Users/verlyn13/Documents/temp/readiness-2026-05-12.md`
- `/Users/verlyn13/Documents/temp/bios-result-2026-05-12.md`
- `/Users/verlyn13/Downloads/apply-rdp-and-power-result-2026-05-12T20-32-22.md`
- `/Users/verlyn13/Downloads/rdp-and-power-apply-report-2026-05-12.md`
- `/Users/verlyn13/Repos/verlyn13/HomeNetOps/docs/archive/2026-05-12-desktop-2jj3187-handoff.md`

Repo-safe current facts from those updates:

- Operator connected Ethernet; latest report says Ethernet is up at 1 Gbps and
  is now the preferred default-route interface.
- Windows categorized the Ethernet LAN as `Public`; future RDP/SSH firewall
  work must account for this or reclassify the LAN to `Private` in an elevated
  implementation phase.
- Operator attested BitLocker is off on C:. BitLocker is not in the target
  state for this onboarding slice, so no Windows recovery-key item is needed.
- BIOS pass completed: `AC BACK = Always On`, `ErP = Disabled`, `Wake on LAN =
  Enabled`, `Resume by Alarm = Disabled`, `Fast Boot = Disabled`, `CSM Support
  = Disabled`, `AMD CPU fTPM = Enabled`, and Windows booted successfully in
  native UEFI mode.
- Agent-side post-boot verification confirmed `BiosFirmwareType: Uefi`,
  Ethernet still up, Intel I211 still wake-armed, Magic Packet enabled, Pattern
  Match enabled, and `Enable PME` still disabled.
- Windows-side RDP-on-LAN implementation completed at 2026-05-12 20:32 AKST:
  Ethernet profile set to `Private`, RDP enabled with NLA, `TermService`
  running automatic, built-in Remote Desktop rules disabled, custom
  `Jefahnierocks RDP LAN TCP/UDP 3389` firewall rules enabled for
  `192.168.0.0/24`, and no WinRM/WAN/Cloudflare/OPNsense changes made.
- Windows-side power readiness improved: hibernation, hybrid sleep, and Fast
  Startup are effectively unavailable via `powercfg /a`; Magic Packet, Pattern
  Match, and PME are enabled on the wired NIC.
- MacBook LAN TCP smoke test succeeded against `192.168.0.217:3389` on
  2026-05-12 from this repo session. `DESKTOP-2JJ3187.local:3389` also
  succeeded after an initial timeout.
- Operator reported successful Windows App GUI connection and remote management
  from the MacBook at 2026-05-12 20:49 AKDT.
- HomeNetOps retained `192.168.0.217` as a static DHCP reservation for the
  wired MAC, created local DNS `desktop-2jj3187.home.arpa`, and verified RDP
  reachability over the FQDN.
- HomeNetOps registered the host in OPNsense `os-wol` with UUID
  `93980551-709a-40d3-83e7-a708ee616373` and completed cold-to-wake-to-RDP WoL
  smoke under `automation_svc`.
- ICMP echo remains blocked by Windows default posture; use
  `nc -vz desktop-2jj3187.home.arpa 3389` for LAN liveness, not `ping`.
- Operator confirmed the MacBook Windows App profile was updated for the
  stable local FQDN, Windows Update is fully current, and the NVIDIA driver has
  been updated to the latest available version as of 2026-05-13.

## Identity

| Field | Value |
|---|---|
| Device label | Shared family Windows PC / gaming and homework workstation |
| Proposed hostname | `DESKTOP-2JJ3187` |
| OS edition/version/build | Windows 11 Pro 24H2, build 26100, from source report |
| Intended user/owner | Jefahnierocks-owned shared family workstation; `jeffr` current admin; kid users `ahnie`, `axelp`, `ilage`, `wynst` as standard users in source report |
| Physical location / administrative context | Home LAN behind OPNsense, same LAN context as `nas.jefahnierocks.com` and `opnsense.jefahnierocks.com`; intended remotely administered compute host |
| Serial/service tag | Not recorded in this repo record |

Accounts explicitly called out as do-not-touch in the source report:
`CodexSandboxOnline`, `CodexSandboxOffline`, and `WsiAccount`.

## Network Identity

| Field | Value |
|---|---|
| Wired MAC | `18:C0:4D:39:7F:49`; latest readiness report says Ethernet is now connected at 1 Gbps |
| Wi-Fi MAC | `CC:D9:AC:1F:92:7B` from source report |
| Current LAN IP | `192.168.0.217`, static via OPNsense ISC DHCPv4 reservation for wired MAC `18:C0:4D:39:7F:49`. |
| Tailscale identity | Not part of the Windows source plan |
| WARP identity | WARP not installed in source report; per-user Google identities pending |
| Cloudflare tunnel | Existing named tunnel resource reported, but service stopped/duplicated and config absent; do not copy credential JSON into repo |
| DNS / hostname record | `desktop-2jj3187.home.arpa` via HomeNetOps/OPNsense local DNS. No public DNS or Cloudflare change. |

## Administration Model

| Control | Target | Current status |
|---|---|---|
| Local admin credential | Unique per-device local admin credential stored in 1Password only. Device-specific management account may be created if the implementation needs it. | Planned; item/account not created. |
| 1Password local admin item | `jefahnierocks-device-desktop-2jj3187-local-admin` | Planned; secret value not created here. |
| Recovery key item | None for this slice. | BitLocker is not in target state; do not create a recovery-key item unless a later explicit decision enables BitLocker. |
| Shared admin password | Not allowed. | No shared credential approved. |
| Remote administration | RDP plus SSH/PowerShell over Cloudflare private network or Access-protected hostnames only. | LAN RDP server-side enablement applied, TCP `3389` reachable from the MacBook on `desktop-2jj3187.home.arpa`, and Windows App GUI management verified by operator report. |
| PowerShell Remoting / WinRM | Disabled unless explicit need and approval. | Not approved. |
| Kid local privilege | Kids remain standard users. | Source report says this is already correct. |
| Codex sandbox accounts | Preserve. | Source report says leave sandbox accounts untouched. |

## Remote Access

Preferred path:

- RDP and Windows OpenSSH are acceptable only through Cloudflare private
  network, Cloudflare Access-protected hostnames, or trusted LAN during
  transition.
- RDP, SSH, WinRM, VNC, and broader remote admin services must not be exposed
  through public WAN.
- WinRM and PowerShell Remoting remain disabled unless a later explicit
  approval names the need, path, and verification method.
- The MacBook Windows App profile is documented in
  [windows-app-desktop-2jj3187.md](./windows-app-desktop-2jj3187.md). That
  profile defines client-side values only and does not approve broader RDP
  exposure beyond the LAN-scoped rules already applied.

Current state:

- RDP is now enabled for trusted LAN use only, with custom Private-profile
  firewall rules scoped to `192.168.0.0/24`.
- Built-in broad Remote Desktop firewall rules remain disabled.
- OpenSSH server is not installed, WARP is not installed, and duplicate stopped
  `cloudflared` services still exist.
- LAN GUI administration is verified. Do not claim this Windows PC is fully
  managed yet.

Client profile target:

- Use `DESKTOP-2JJ3187 - Jefahnierocks Admin` as the Windows App friendly name.
- Keep credentials set to `Ask when required`; retrieve credentials from
  1Password instead of saving them in Windows App.
- Use `No gateway`; Cloudflare WARP/private routing is a network path, not an
  RD Gateway.
- Leave `Connect to an admin session` unchecked by default for this Windows 11
  workstation.
- Disable printer, smart-card, microphone, camera, and folder redirection by
  default.
- Do not use a public IP or public WAN DNS name as the PC name. Use
  `desktop-2jj3187.home.arpa` as the stable same-LAN target. Keep
  `192.168.0.217` only as a break-glass direct-IP fallback.

Important enrollment note:

- The source plan mentions MDM-style WARP preconfiguration, but local
  `cloudflare-dns` policy requires human-operated devices to produce
  `identity.email` for adult/kid profile matching. Preconfiguring the team
  name is fine if each user still completes browser/manual OAuth. Do not use
  headless service-token enrollment for kid/admin identity policy.

## Security Posture

| Area | Target | Current status |
|---|---|---|
| Disk encryption | BitLocker intentionally not used for this onboarding slice. | Operator attested BitLocker is off; elevated agent-side verification still pending. |
| Windows Defender | Enabled and healthy. | Pending elevated verification. |
| Windows Firewall | Enabled for active profiles; RDP/SSH restricted to Cloudflare/private/LAN ranges only. | RDP custom rules `Jefahnierocks RDP LAN TCP/UDP 3389` are enabled for Private profile and remote address `192.168.0.0/24`; built-in Remote Desktop rule group remains disabled. |
| Updates | Windows Update and GPU driver posture kept current; `cloudflared` cleanup handled only after Cloudflare tunnel ownership is confirmed. | Operator reports Windows Update fully current and NVIDIA driver latest as of 2026-05-13. `cloudflared` remains a separate pending Cloudflare truth-refresh item. |
| Power/wake | Ethernet connected; BIOS WoL/AC restore verified; Windows-side Fast Startup/hibernate/hybrid sleep/PME handled deliberately; box stays awake. | BIOS-side prep complete by operator report; Windows-side RDP/power apply reports hibernation, hybrid sleep, and Fast Startup effectively unavailable, and Magic Packet, Pattern Match, and PME enabled. HomeNetOps cold-to-wake-to-RDP WoL smoke verified. |
| Backup/recovery | Recovery path identified before relying on the device for administered work. | Backup strategy out of scope in source report; break-glass path needs decision. |

## BIOS And Power Evidence

Operator-reported BIOS result from 2026-05-12:

| Setting | Current value |
|---|---|
| `AC BACK` | `Always On` |
| `ErP` | `Disabled` |
| `Wake on LAN` | `Enabled` |
| `Resume by Alarm` | `Disabled` |
| `Fast Boot` | `Disabled` |
| `CSM Support` | `Disabled` |
| `AMD CPU fTPM` | `Enabled` |

Planning impact:

- BIOS-side Wake-on-LAN and AC-recovery prerequisites are substantially ready.
- Successful boot after disabling CSM confirms native UEFI boot from Windows.
- Windows-side power hardening was applied for the LAN RDP phase.
- End-to-end WoL was verified by HomeNetOps using OPNsense `os-wol` automation
  after the static DHCP/DNS pass.

## Approval-Gated Build Phases

Do not execute these without explicit approval:

1. Physical/BIOS prep: reconnect Ethernet, verify Wake-on-LAN and AC power
   recovery. BIOS-side prep is completed by operator report and end-to-end WoL
   smoke is verified by HomeNetOps.
2. Windows power hardening: disable Fast Startup/hibernate/hybrid sleep and
   configure stay-awake policy. Applied 2026-05-12; WoL smoke verified by
   HomeNetOps.
3. Install and harden Windows OpenSSH Server, including admin key placement.
4. Enable RDP with NLA and private-network-only firewall constraints. Applied
   for LAN scope 2026-05-12; interactive Windows App GUI login verified by
   operator report.
5. Clean up and update `cloudflared`, then configure the approved tunnel mode.
6. Install WARP and complete per-user identity enrollment.
7. Configure Cloudflare Zero Trust routes, Access policies, device profiles,
   and Gateway policies.
8. Install/configure OPNsense WoL plugin or scripted WoL access.
   Completed by HomeNetOps with `os-wol` UUID
   `93980551-709a-40d3-83e7-a708ee616373`; cold-to-wake-to-RDP smoke verified.
9. Update NVIDIA driver for compute use.
   Completed by operator report as of 2026-05-13.

## Evidence

Source evidence has been ingested from the downloaded Windows plan. No new live
Windows commands were run from this session.

Current repo-safe evidence:

```text
timestamp: 2026-05-12 20:49 AKDT
source: operator report in chat; MacBook-side TCP smoke from repo session
observed: Windows App GUI connection to DESKTOP-2JJ3187 worked from MacBook;
  remote management worked as expected
proof: operator attestation; prior TCP test succeeded to 192.168.0.217:3389
repo-safe output: LAN GUI administration verified; no credential values
  recorded; no public WAN path used
private raw evidence: none recorded in repo
status: verified interactive LAN GUI access; full management still pending
```

```text
timestamp: 2026-05-13
source: HomeNetOps hand-back plus local repo-session verification
observed: wired MAC 18:c0:4d:39:7f:49 has static IP 192.168.0.217;
  desktop-2jj3187.home.arpa resolves to 192.168.0.217; RDP is reachable on
  TCP 3389 by FQDN; OPNsense os-wol UUID
  93980551-709a-40d3-83e7-a708ee616373 completed cold-to-wake-to-RDP smoke
proof: HomeNetOps report; `dig @192.168.0.1 desktop-2jj3187.home.arpa +short`
  returned 192.168.0.217; `nc -vz desktop-2jj3187.home.arpa 3389` succeeded
repo-safe output: static DHCP/local DNS/WoL verified; no public WAN path,
  public DNS, Cloudflare, or WARP change
private raw evidence: HomeNetOps repo handoff under
  `/Users/verlyn13/Repos/verlyn13/HomeNetOps/docs/archive/2026-05-12-desktop-2jj3187-handoff.md`
status: LAN remote-administration substrate verified; off-LAN private access
  still pending
```

Future entries should use this shape:

```text
timestamp:
source:
observed:
proof:
repo-safe output:
private raw evidence:
status:
```

Useful non-secret proof sources once the human has access:

- Windows Settings: System, About.
- Windows Security: Virus and threat protection, Firewall and network
  protection, Device security.
- BitLocker control panel or `manage-bde -status` with recovery values redacted.
- `ipconfig /all` with private data redacted before copying into repo docs.
- Tailscale or WARP client status, if installed.

## Checklist

### Verified Current State

- Source report identifies the host as `DESKTOP-2JJ3187`, Windows 11 Pro 24H2
  build 26100.
- Source report says kid accounts are standard users and `jeffr` is the
  principal admin.
- Original source baseline said RDP was disabled before the approved LAN apply;
  OpenSSH server remains absent, WARP remains absent, and `cloudflared` remains
  present but stopped/duplicated without config.
- Latest readiness report says Ethernet is connected and preferred, BIOS-side
  WoL/AC-recovery prep is complete, BitLocker is off by operator attestation
  and not in target state, and native UEFI boot is confirmed.
- Windows-side RDP/power implementation report says RDP is enabled with NLA,
  `TermService` is running automatic, custom LAN-only RDP firewall rules are in
  place, hibernation/hybrid sleep/Fast Startup are effectively unavailable, and
  NIC Magic Packet, Pattern Match, and PME are enabled.
- MacBook LAN TCP smoke test succeeded against `192.168.0.217:3389`; hostname
  test against `DESKTOP-2JJ3187.local:3389` also succeeded after an initial
  timeout.
- Operator reported successful Windows App GUI login and remote management from
  the MacBook.
- HomeNetOps hand-back verifies static DHCP reservation for wired MAC
  `18:C0:4D:39:7F:49`, FQDN `desktop-2jj3187.home.arpa`, LAN RDP by FQDN, and
  OPNsense WoL cold-to-wake-to-RDP smoke.
- Operator confirmed the MacBook Windows App profile now uses the stable local
  FQDN, Windows Update is fully current, and the NVIDIA driver is current.

### Safe Next Manual Step

- Use the MacBook Windows App profile targeting stable FQDN
  `desktop-2jj3187.home.arpa` for GUI administration.
- For this ad hoc mapping, follow current HomeNetOps/OPNsense process. For
  later formal management, prefer Kea DHCP over legacy ISC DHCP because Kea has
  an API module suitable for governed automation.
- Confirm whether the existing named tunnel should be retained or migrated to a
  dashboard-managed connector.
- Confirm whether remote access should remain strictly Private Network only or
  also use Access-protected public hostnames for SSH/RDP.
- Confirm whether a device-specific management or break-glass local
  Administrator account is required.

### Blocked Pending Human/Device Access

- Elevated re-verification of OpenSSH/Defender/BitLocker/Windows Update state
  if a second direct Windows-side proof pass is required.
- Cloudflare dashboard confirmation of tunnel, route, Access policy, WARP
  profiles, and enrollment permissions.
- 1Password secret item creation or update.

### Requires Explicit Approval

- Creating or editing any 1Password item containing a password or recovery key.
- Installing OpenSSH Server.
- Changing or broadening RDP exposure.
- Opening or changing firewall rules beyond the current LAN-only RDP rules.
- Changing static DHCP or DNS records.
- Enrolling in WARP or any management agent.
- Changing Cloudflare tunnel, private route, Access, Gateway, or device profile
  state.
- Changing OPNsense Wake-on-LAN plugin, host registration, or API access.
- Enabling BitLocker or creating/storing a recovery key; this is outside the
  target state for the current slice.
- Enabling WinRM, PowerShell Remoting, VNC, or another remote admin service.
