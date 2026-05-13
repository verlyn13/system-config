---
title: Device Administration Onboarding - 2026-05-12
category: operations
component: device_admin
status: draft
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, windows, fedora, remote-access, 1password, ssh]
priority: high
---

# Device Administration Onboarding - 2026-05-12

This record starts an ad hoc-but-governed onboarding slice for two additional
Jefahnierocks-administered human devices:

- Windows PC
- Fedora 44 laptop

This is not a full IaC-backed management rollout. It is a controlled intake
record so remote access, local administration, recovery posture, and evidence
are captured without overclaiming enforcement.

## Administration Authority

Jefahnierocks owns administration of these devices from this workspace. The
downloaded device-local reports are input evidence and candidate suggestions
only; they do not define the management model, access design, secret handling,
Cloudflare posture, OPNsense posture, or implementation sequence.

Authoritative decisions for this onboarding slice must come from:

- this `system-config` device-admin record set;
- `system-config` SSH, secrets, and hardening policy;
- `cloudflare-dns` for Cloudflare Zero Trust, WARP enrollment, Gateway policy,
  and device-profile semantics;
- HomeNetOps for OPNsense, LAN, private overlay, DHCP, DNS, Wake-on-LAN, and
  router/firewall changes;
- explicit human approval for every live provider, network, secret, or
  device-side administrative change.

Operational rule: do not execute commands or phases from the downloaded reports
verbatim. Translate their facts and useful recommendations into this local
authority model first, then perform only the approved next step with fresh
verification.

## Ingested Planning Inputs

The following human-provided planning documents were ingested on 2026-05-12:

| Source document | Device | How this record uses it |
|---|---|---|
| `/Users/verlyn13/Downloads/plan (1).md` | `DESKTOP-2JJ3187` Windows PC | Source-observed current-state inventory and candidate build plan from a device-local agent. Treat facts as planning evidence; treat recommendations as non-authoritative suggestions until reconciled here. |
| `/Users/verlyn13/Downloads/fedora-top-remote-admin-report-2026-05-12.md` | `fedora-top` Fedora laptop | Source-observed current-state inventory, risks, and candidate build phases from a device-local agent. Treat facts as planning evidence; treat recommendations as non-authoritative suggestions until reconciled here. |

Do not copy raw credential files, command histories, tunnel credential JSON,
private keys, recovery keys, or passwords from the source systems into this
repo.

## Returned Device Updates

The following device-side prep outputs were received from
`/Users/verlyn13/Documents/temp` and ingested as external evidence references:

| Source document | Device | Repo-safe facts captured here |
|---|---|---|
| `/Users/verlyn13/Documents/temp/readiness-2026-05-12.md` | `DESKTOP-2JJ3187` | Ethernet is now connected and preferred; Ethernet network profile is `Public`; BIOS pass completed; BitLocker is off by operator attestation; RDP/OpenSSH/WARP remain not ready; duplicate stopped `cloudflared` services remain; Windows-side power/PME hardening remains pending. |
| `/Users/verlyn13/Documents/temp/bios-result-2026-05-12.md` | `DESKTOP-2JJ3187` | Operator reports `AC BACK = Always On`, `ErP = Disabled`, `Wake on LAN = Enabled`, `Resume by Alarm = Disabled`, `Fast Boot = Disabled`, `CSM Support = Disabled`, and successful native UEFI Windows boot. |
| `/Users/verlyn13/Downloads/apply-rdp-and-power-result-2026-05-12T20-32-22.md` | `DESKTOP-2JJ3187` | Elevated Windows apply log reports Ethernet `Private`, RDP enabled with NLA, `TermService` running automatic, custom LAN-only RDP rules created, hibernation/power settings applied, NIC PME enabled, and no WinRM/WAN/Cloudflare/OPNsense/OpenSSH/user changes. |
| `/Users/verlyn13/Downloads/rdp-and-power-apply-report-2026-05-12.md` | `DESKTOP-2JJ3187` | Post-apply report confirms RDP listener on TCP/UDP `3389`, custom firewall rules scoped to `192.168.0.0/24`, built-in RDP rules disabled, power readiness improved, and remaining gaps include HomeNetOps WoL smoke and stable naming. |
| `/Users/verlyn13/Repos/verlyn13/HomeNetOps/docs/archive/2026-05-12-desktop-2jj3187-handoff.md` plus operator hand-back | `DESKTOP-2JJ3187` | HomeNetOps verified static DHCP for wired MAC `18:c0:4d:39:7f:49`, retained IP `192.168.0.217`, created local DNS `desktop-2jj3187.home.arpa`, verified RDP over the FQDN, registered OPNsense WoL UUID `93980551-709a-40d3-83e7-a708ee616373`, and completed cold-to-wake-to-RDP WoL smoke. |
| Operator update in chat, 2026-05-13 | `DESKTOP-2JJ3187` | MacBook Windows App profile update completed for the stable local FQDN; Windows Update is fully current; NVIDIA driver is latest available. |
| `/Users/verlyn13/Documents/temp/fedora-top-readiness-report-2026-05-12.md` | `fedora-top` | Fresh read-only pass confirms `wyn` sudo risk, `axel`/`ila`/`mesh-ops` admin memberships, WARP/cloudflared absence, Tailscale logged out, permissive firewalld posture, LUKS2, AC not connected, recent suspend, and Redis/Infisical LAN exposure. |

The BIOS checklist artifact in the same directory is a useful operator runbook,
but the result artifact is the state evidence that should drive this record.

## Operator Decisions Captured 2026-05-13

The human operator provided the following administration decisions for this
slice:

- Jefahnierocks is the owner/administrator of both devices.
- Device-specific management accounts may be created on the devices if the
  implementation phase needs them. Any such account still needs a unique
  credential or key model, 1Password storage, and device-side approval before
  creation.
- Both devices will live on the same home LAN context as
  `nas.jefahnierocks.com` and `opnsense.jefahnierocks.com`.
- Neither device currently has a static IP address. Static DHCP, DNS, or
  hostname records remain HomeNetOps/OPNsense approval-gated work.
- Windows BitLocker is not part of the target state for this slice. Do not
  create a BitLocker recovery item unless a later explicit decision enables
  BitLocker.
- Fedora should be hardened so `verlyn13` is the only account that runs
  mission-critical services.
- Other Fedora accounts, including `wyn`, should remain usable for exploration
  but should not retain privilege paths that can damage the system or administer
  mission-critical services.
- Infisical belongs on the Hetzner server only for current needs. Fedora should
  not host a LAN-exposed Infisical service as part of the target state.

## HomeNetOps Transition Note

Jefahnierocks plans to bring HomeNetOps under Jefahnierocks organization
management in a later formalization pass. Do not treat the current ad hoc
device onboarding as that migration.

For the immediate static DHCP/local DNS work, follow the current HomeNetOps and
OPNsense operating model. For the formalized target state, prefer moving DHCP
administration to OPNsense Kea DHCP rather than the legacy ISC DHCP path,
because Kea has an API module suitable for future governed automation while the
legacy path does not provide the API surface needed for durable management.

This is a future-state architecture note, not approval to migrate DHCP during
the current Windows or Fedora device onboarding slice.

## Authority And Source Refresh

Read-only refresh completed before creating these records:

| Surface | Current read |
|---|---|
| `system-config` | Clean branch baseline was `main...origin/main`; branch for this slice is `feat/device-admin-onboarding`. |
| `docs/security-hardening-implementation-plan.md` | 1Password-first posture; private raw evidence stays outside git; WARP and Cloudflare control surfaces are not owned by `system-config`. |
| `docs/ssh.md` | Human interactive SSH should use the 1Password SSH agent; human workstation identities must not become unattended machine identities. |
| `docs/secrets.md` | No secrets in git, shell argv, or persistent global config; 1Password item names and non-secret metadata may be stable references. |
| HomeNetOps | Current OPNsense/HomeNetOps posture is zero direct WAN exposure for OPNsense-managed local services; LAN and private overlay paths are the safe current remote access lanes. |
| `cloudflare-dns` | Human-operated WARP devices should use browser/manual OAuth for `identity.email` behavior; MDM/service-token enrollment is for headless devices and does not match adult/kid identity policy. |

## Guardrails

- Do not expose RDP, WinRM, VNC, SSH, or remote desktop services to public WAN.
- Do not reuse local admin credentials across devices.
- Do not reuse a human interactive SSH key for unattended automation.
- Do not change OPNsense, Cloudflare, Tailscale, WARP, DNS, DHCP, firewall, or
  provider dashboard state without explicit approval.
- Do not create or modify 1Password secret values without explicit human
  approval and a GUI/template workflow that keeps values out of shell argv.
- Do not claim either device is fully managed until live device-side
  verification proves the intended controls.

## Target Records

| Device | Record | Current status |
|---|---|---|
| Windows PC | [windows-pc.md](./windows-pc.md) | LAN RDP, Windows App GUI, static DHCP/local DNS, and WoL verified; off-LAN private access still pending. |
| Fedora 44 laptop | [fedora-44-laptop.md](./fedora-44-laptop.md) | Source report ingested; live execution still pending approval. |

## Client Profiles

| Client | Profile | Purpose |
|---|---|---|
| MacBook M3 Max Windows App | [windows-app-desktop-2jj3187.md](./windows-app-desktop-2jj3187.md) | Prepared RDP GUI-management profile values for `DESKTOP-2JJ3187`; TCP reachability and interactive Windows App GUI management are verified on LAN. |

## Device Agent Handoffs

Use these documents when starting an agent directly on the target device:

| Device | Handoff | Purpose |
|---|---|---|
| Windows PC | [handoff-desktop-2jj3187.md](./handoff-desktop-2jj3187.md) | Read-only local readiness refresh and approval-gated next-step report for `DESKTOP-2JJ3187`. |
| Fedora 44 laptop | [handoff-fedora-top.md](./handoff-fedora-top.md) | Read-only local readiness refresh and approval-gated next-step report for `fedora-top`. |
| Fedora 44 laptop | [fedora-top-complete-instructions.md](./fedora-top-complete-instructions.md) | Active Fedora-side SSH foothold, MacBook smoke test, remote baseline, and approval-gated hardening instructions for `fedora-top`. |

Handoff agents should return evidence back to this record set. They should not
decide the administration architecture locally.

## Planning Deltas From Source Reports

Both source reports strengthen the target posture:

- Cloudflare One/WARP is the preferred management plane, with private routing
  or Access-protected hostnames and no public inbound ports.
- Device-side SSH/RDP enablement is not enough by itself; access must be
  restricted by Cloudflare policy, local firewall rules, and admin-only
  identities.
- Per-user WARP identity matters. For human-operated devices, preserve the
  `cloudflare-dns` convention that policy should see `identity.email` from
  browser/manual OAuth. Do not replace this with headless MDM/service-token
  enrollment unless the intended profile is `non_identity`.
- Tailscale can be a break-glass plane, but only if deliberately enrolled and
  ACL-restricted. It should not become an unmanaged parallel admin surface.
- Power and boot behavior are part of remote administration. Windows needs
  BIOS/WoL/power settings verified; Fedora needs AC/sleep policy and a LUKS
  reboot strategy.
- Existing local services matter. Fedora currently has LAN-exposed Docker
  services in the source report; Windows has stopped/duplicate `cloudflared`
  services and no OpenSSH server in the source report.

This creates two immediate planning tracks:

1. Record and review the target shape for each device.
2. Only after explicit approval, execute the live setup phases on the devices,
   Cloudflare, OPNsense, WARP/Tailscale, and 1Password.

When the downloaded reports suggest a path that conflicts with local standards,
local standards win. For example, a device-local recommendation to use a
service-token or MDM-style WARP setup is not sufficient for a human/kid device
that must match Cloudflare Gateway `identity.email` rules. That design must be
translated into the `cloudflare-dns` enrollment model before execution.

## Shared Intake Fields

Each device record must capture:

- Device label and proposed hostname.
- OS edition, version, and build.
- Intended user and Jefahnierocks ownership.
- Physical location or administrative context.
- Network identity needed for administration: MAC addresses, LAN IP if known,
  and Tailscale/WARP identity if applicable.
- Remote access path, restricted to private overlay or trusted LAN only.
- Local admin model with a unique per-device admin credential stored in
  1Password only.
- Disk encryption status and recovery-key handling.
- Firewall posture.
- Patch/update posture.
- Backup/recovery posture.
- Verified live state versus planned or blocked work.

## Proposed 1Password Metadata

Use stable item names as references. Secret values remain in 1Password only.

| Purpose | Item name pattern | Notes |
|---|---|---|
| Local admin credential | `jefahnierocks-device-<hostname>-local-admin` | Login item or locally appropriate credential item. Unique per device. |
| Recovery key | `jefahnierocks-device-<hostname>-recovery-key` | LUKS/FDE recovery material where applicable. Windows BitLocker is not in target state for this slice. |
| Administrative SSH key, if needed | `jefahnierocks-device-<hostname>-admin-ssh` | Only for device-specific admin access; do not reuse human workstation automation identity. |

Suggested non-secret tags:

```text
entity:jefahnierocks,kind:device-admin,device:<hostname>,os:<windows|fedora>,purpose:<local-admin|recovery|ssh>
```

Secret-bearing values must be entered by the human in the 1Password GUI or via
the approved edited-template workflow from `docs/secrets.md`. Do not pass
passwords, recovery keys, TOTP seeds, or private keys as command arguments.

## Remote Access Target

Remote administration is a target state, not current truth.

| Device | Preferred path | Current status |
|---|---|---|
| Windows PC | RDP for GUI administration; Windows OpenSSH is the preferred future shell path after approval; WinRM/PowerShell Remoting remains off unless a concrete need is approved. No public inbound ports. | LAN RDP is enabled, TCP `3389` is reachable from the MacBook at `desktop-2jj3187.home.arpa`, interactive Windows App GUI management is verified, and HomeNetOps static DHCP/DNS plus WoL are verified. Cloudflare/WARP remains pending. |
| Fedora 44 laptop | First prove `verlyn13` SSH from the MacBook over trusted LAN; then complete hardening remotely from `system-config`. Later off-LAN access should use Cloudflare private routing or an Access-protected path; optional Cockpit only through Cloudflare Access; Tailscale only as ACL-restricted break-glass. | Source report says SSH is active on all interfaces with password auth enabled, WARP/cloudflared absent, and Tailscale installed but logged out. |

## Evidence Model

Each evidence entry should be short and redacted:

```text
timestamp:
source:
observed:
proof:
repo-safe output:
private raw evidence:
status:
```

Do not copy raw logs containing secrets, shell history, private keys, recovery
keys, usernames/passwords, tokens, or account session material into this repo.

Private raw evidence, if needed, should live outside the repo under a dated
operator-controlled path such as:

```text
~/Library/Logs/device-admin/2026-05-12/
```

## Current Device Checklist

| Item | Windows PC | Fedora 44 laptop |
|---|---|---|
| Device label / hostname | `DESKTOP-2JJ3187` | `fedora-top` |
| OS version/build | Windows 11 Pro 24H2, build 26100, from source report | Fedora Linux 44 Workstation, kernel `7.0.4-200.fc44.x86_64`, from source report |
| Intended user/owner | Jefahnierocks-owned shared family workstation; `jeffr` current admin and kid standard users from source report | Jefahnierocks-owned Wyn summer-use laptop; `verlyn13` is the sole mission-critical admin/service owner |
| Physical/admin context | Home LAN behind OPNsense, same LAN context as `nas.jefahnierocks.com` and `opnsense.jefahnierocks.com`; Ethernet now connected after operator action; BIOS power/WoL prep completed | Home LAN behind OPNsense, same LAN context as `nas.jefahnierocks.com` and `opnsense.jefahnierocks.com`; laptop on Wi-Fi; AC required for availability; latest report says battery only and recent suspend |
| MAC / LAN IP / overlay identity | Ethernet MAC `18:C0:4D:39:7F:49`; static IP `192.168.0.217`; FQDN `desktop-2jj3187.home.arpa`; Wi-Fi MAC `CC:D9:AC:1F:92:7B` intentionally not mapped; WARP absent | Source report: Wi-Fi `192.168.0.206`; Tailscale installed but logged out; WARP absent |
| Local admin credential item | Planned; not created | Planned; not created |
| Recovery key item | No BitLocker recovery item needed; BitLocker is not in target state for this slice | Planned; not created; LUKS2 present in source report |
| Remote access enabled | Partial: LAN RDP enabled, firewall-scoped to `192.168.0.0/24`, TCP `3389` reachable from MacBook using `desktop-2jj3187.home.arpa`, interactive GUI management verified, and WoL verified. OpenSSH/WARP absent and duplicate stopped `cloudflared` services remain | Not ready: SSH active but not hardened; WARP/cloudflared absent; Tailscale logged out in latest report |
| Disk encryption verified | BitLocker off by operator attestation; agent-side elevated check still pending | LUKS2 root/home encryption reported; remote reboot blocked unless unlock strategy is solved |
| Firewall verified | Ethernet profile now `Private`; custom `Jefahnierocks RDP LAN TCP/UDP 3389` rules scoped to `192.168.0.0/24`; built-in RDP rules disabled | `firewalld` active but FedoraWorkstation zone broad in latest report |
| Patch/update posture verified | Windows Update and NVIDIA driver current by operator report; BIOS/UEFI posture improved; RDP/power LAN apply complete; HomeNetOps static DHCP/DNS/WoL complete; `cloudflared` status still pending Cloudflare truth refresh | Firmware current at prior capture; DNF refresh hit GPG prompts in latest report |
| Backup/recovery verified | Backup strategy out of scope in source report | Recovery path depends on LUKS/local helper/TPM strategy; Infisical should not be recovered on this laptop |

## Next Manual Data Needed

Before any live change, collect or decide:

- Confirm Google identities for each Windows kid account and the admin WARP
  identity.
- Reconcile Windows WARP enrollment with `cloudflare-dns`: per-user
  `identity.email` must be preserved for policy matching.
- Decide whether Windows remote access is strictly Private Network only or also
  gets Access-protected public hostnames.
- Confirm whether the legacy Windows named tunnel should be retained or migrated
  to a dashboard-managed connector token.
- Decide whether to create a Windows break-glass local Administrator account
  and where its credential record belongs in 1Password.
- Continue using the MacBook Windows App profile with
  `desktop-2jj3187.home.arpa` as the target.
- Establish MacBook-to-Fedora SSH as `verlyn13`; once that works, treat the
  Fedora device as remotely manageable from `system-config`.
- Decide whether the Fedora laptop should get a HomeNetOps-managed static DHCP
  mapping or local DNS record after Wi-Fi MAC is confirmed.
- Decide whether Fedora keeps Tailscale as break-glass or removes it.
- Decide Fedora LUKS strategy: no unattended reboot, TPM2 auto-unlock, FIDO2,
  or initramfs SSH unlock.
- Decide whether Fedora Cockpit should stay disabled or be exposed only through
  Cloudflare Access.
- Plan Fedora privilege cleanup so `verlyn13` is the only mission-critical
  admin/service owner and non-`verlyn13` accounts lose `wheel`, `docker`, and
  service-management paths unless explicitly justified.
- Retire Fedora Infisical from this laptop and stop or rebind any supporting
  Redis/admin surfaces so they are not exposed on the LAN.
