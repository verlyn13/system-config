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

The following device-side, HomeNetOps, and operator hand-back outputs were
ingested as external evidence references:

| Source document | Device | Repo-safe facts captured here |
|---|---|---|
| `/Users/verlyn13/Documents/temp/readiness-2026-05-12.md` | `DESKTOP-2JJ3187` | Ethernet is now connected and preferred; Ethernet network profile is `Public`; BIOS pass completed; BitLocker is off by operator attestation; RDP/OpenSSH/WARP remain not ready; duplicate stopped `cloudflared` services remain; Windows-side power/PME hardening remains pending. |
| `/Users/verlyn13/Documents/temp/bios-result-2026-05-12.md` | `DESKTOP-2JJ3187` | Operator reports `AC BACK = Always On`, `ErP = Disabled`, `Wake on LAN = Enabled`, `Resume by Alarm = Disabled`, `Fast Boot = Disabled`, `CSM Support = Disabled`, and successful native UEFI Windows boot. |
| `/Users/verlyn13/Downloads/apply-rdp-and-power-result-2026-05-12T20-32-22.md` | `DESKTOP-2JJ3187` | Elevated Windows apply log reports Ethernet `Private`, RDP enabled with NLA, `TermService` running automatic, custom LAN-only RDP rules created, hibernation/power settings applied, NIC PME enabled, and no WinRM/WAN/Cloudflare/OPNsense/OpenSSH/user changes. |
| `/Users/verlyn13/Downloads/rdp-and-power-apply-report-2026-05-12.md` | `DESKTOP-2JJ3187` | Post-apply report confirms RDP listener on TCP/UDP `3389`, custom firewall rules scoped to `192.168.0.0/24`, built-in RDP rules disabled, power readiness improved, and remaining gaps include HomeNetOps WoL smoke and stable naming. |
| `/Users/verlyn13/Repos/verlyn13/HomeNetOps/docs/archive/2026-05-12-desktop-2jj3187-handoff.md` plus operator hand-back | `DESKTOP-2JJ3187` | HomeNetOps verified static DHCP for wired MAC `18:c0:4d:39:7f:49`, retained IP `192.168.0.217`, created local DNS `desktop-2jj3187.home.arpa`, verified RDP over the FQDN, registered OPNsense WoL UUID `93980551-709a-40d3-83e7-a708ee616373`, and completed cold-to-wake-to-RDP WoL smoke. |
| Operator update in chat, 2026-05-13 | `DESKTOP-2JJ3187` | MacBook Windows App profile update completed for the stable local FQDN; Windows Update is fully current; NVIDIA driver is latest available. |
| `/Users/verlyn13/Documents/temp/fedora-top-readiness-report-2026-05-12.md` | `fedora-top` | Fresh read-only pass confirms `wyn` sudo risk, `axel`/`ila`/`mesh-ops` admin memberships, WARP/cloudflared absence, Tailscale logged out, permissive firewalld posture, LUKS2, AC not connected, recent suspend, and Redis/Infisical LAN exposure. |
| `/Users/verlyn13/Downloads/fedora-top-phase-1-ssh-foothold-report-2026-05-13.md` plus [fedora-top-phase-1-ssh-foothold-2026-05-13.md](./fedora-top-phase-1-ssh-foothold-2026-05-13.md) | `fedora-top` | Phase 1 Fedora-side checks confirm AC connected, Wi-Fi MAC `66:B5:8C:F5:45:74`, current IP `192.168.0.206/24`, `sshd` enabled/active/listening on TCP `22`, and `authorized_keys` permissions correct. MacBook-side TCP `22` reachability succeeded, but public-key SSH login failed because the approved MacBook key is not yet installed/selected. |
| `/Users/verlyn13/Downloads/fedora-top-authorized-key-install-report-2026-05-13.md` plus [fedora-top-ssh-login-and-baseline-2026-05-13.md](./fedora-top-ssh-login-and-baseline-2026-05-13.md) | `fedora-top` | Authorized-key install succeeded for approved key fingerprint `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`; MacBook public-key SSH as `verlyn13` now succeeds. Remote baseline confirms SSH is usable but not hardened, `PasswordAuthentication yes` remains, FedoraWorkstation firewall is broad, elevated group memberships remain, and Infisical/Redis are still LAN-exposed. |
| `/home/verlyn13/device-admin-prep/fedora-top-prehardening-report-2026-05-13.md` plus [fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md) | `fedora-top` | Fedora-side pre-hardening detail report confirms SSH is reachable but permissive, three `authorized_keys` entries exist with only one approved for this slice, firewall and Docker zones are broad, sudoers has mode/duplicate/NOPASSWD issues, Infisical and Redis are LAN-published, Tailscale is logged out, WARP/cloudflared are absent, AC is online, and LUKS2/TPM2/dual-boot facts are verified. |
| HomeNetOps hand-back plus [fedora-top-homenetops-lan-identity-2026-05-13.md](./fedora-top-homenetops-lan-identity-2026-05-13.md) | `fedora-top` | HomeNetOps confirms static DHCP via OPNsense ISC DHCPv4 for Wi-Fi MAC `66:b5:8c:f5:45:74`, retained IP `192.168.0.206`, local DNS `fedora-top.home.arpa`, Unbound UUID `ce8c9be1-7b03-4965-8f40-d3adc8a079ac`, FQDN resolution, SSH TCP `22` reachability, and no WAN/public DNS/Cloudflare/WARP/Tailscale/firewall/WoL changes. |
| [fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md) | `fedora-top` | Prepared SSH hardening packet confirms live SSH is still permissive, direct FQDN SSH needs host-key trust reconciliation, `authorized_keys` currently has four active lines with one approved key and a duplicated `ansible@hetzner.hq` key, and records exact cleanup, drop-in, validation, and rollback commands. No live SSH change was made while preparing the packet. |
| [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md) | `fedora-top` | Live apply of the SSH hardening packet on 2026-05-13: `authorized_keys` cleaned to the approved MacBook fingerprint only, drop-in `/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf` installed (`root:root`, `0600`), `sshd -t` passed, `systemctl reload sshd` succeeded, the nine target effective settings verified from a fresh SSH process, negative password-auth check refused as expected, rollback unused. One minimal cleanup-script deviation recorded for kernel `fs.protected_regular` hardening on Fedora 44. |
| [fedora-top-privilege-cleanup-packet-2026-05-13.md](./fedora-top-privilege-cleanup-packet-2026-05-13.md) | `fedora-top` | Privilege cleanup packet. Read-only verification on 2026-05-13 confirmed `wheel`=`verlyn13,wyn,axel,ila,mesh-ops`, `docker`=`verlyn13,ila,mesh-ops`, `systemd-journal`=`mesh-ops`, the duplicate `wyn` grant at `/etc/sudoers:108`, `verlyn13` `NOPASSWD: ALL` via `/etc/sudoers.d/ansible-automation`, and broad `mesh-ops` NOPASSWD wildcards in `/etc/sudoers.d/50-mesh-ops` (mode `0644` instead of required `0440`). Default path applied on 2026-05-13 (see apply record). |
| [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md) | `fedora-top` | Live apply of the privilege cleanup packet on 2026-05-13: snapshot to `/var/backups/jefahnierocks-priv-cleanup-20260513T212114Z`; removed `wyn`/`axel`/`ila`/`mesh-ops` from `wheel`, `ila`/`mesh-ops` from `docker`, `mesh-ops` from `systemd-journal`; removed duplicate `wyn ALL=(ALL) ALL` at `/etc/sudoers:108` via temp + `visudo -c` + `install` swap-in; removed `/etc/sudoers.d/50-mesh-ops`; ran `restorecon -RFv` to normalize SELinux user to policy default `system_u`; validation green (visudo, per-user `sudo -l`, contexts, sshd `allowusers` unchanged). Rollback unused. One minor R10 flag deviation recorded (`-F` needed to reset SELinux user, not just type). |

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
- At the start of this slice, neither device had a static IP address.
  HomeNetOps has since completed static DHCP/local DNS for
  `desktop-2jj3187` and `fedora-top`. Future DHCP, DNS, or hostname changes
  remain HomeNetOps/OPNsense approval-gated work.
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
| Fedora 44 laptop | [fedora-44-laptop.md](./fedora-44-laptop.md) | MacBook public-key SSH as `verlyn13`, static DHCP, and local DNS are verified; SSH hardening packet applied; privilege cleanup packet applied; Infisical/Redis retirement packet applied; firewalld narrowing packet applied; Tailscale retain-or-remove decided (Option B Retain logged-out, documentation-only); remote-admin routing design packet pending; WARP/Cloudflare/LUKS decisions remain pending. |

## Client Profiles

| Client | Profile | Purpose |
|---|---|---|
| MacBook M3 Max Windows App | [windows-app-desktop-2jj3187.md](./windows-app-desktop-2jj3187.md) | Prepared RDP GUI-management profile values for `DESKTOP-2JJ3187`; TCP reachability and interactive Windows App GUI management are verified on LAN. |

## Device Agent Handoffs

Use these documents when starting an agent directly on the target device:

| Device | Handoff | Purpose |
|---|---|---|
| Windows PC | [handoff-desktop-2jj3187.md](./handoff-desktop-2jj3187.md) | Read-only local readiness refresh and approval-gated next-step report for `DESKTOP-2JJ3187`. |
| Additional Windows LAN PC | [handoff-windows-lan-intake.md](./handoff-windows-lan-intake.md) | Identity-pending Windows PC intake for comprehensive LAN administration inventory before approving live remote-access changes. |
| Fedora 44 laptop | [handoff-fedora-top.md](./handoff-fedora-top.md) | Read-only local readiness refresh and approval-gated next-step report for `fedora-top`. |
| Fedora 44 laptop | [fedora-top-complete-instructions.md](./fedora-top-complete-instructions.md) | Active Fedora-side SSH foothold, MacBook smoke test, remote baseline, and approval-gated hardening instructions for `fedora-top`. |
| Fedora 44 laptop | [fedora-top-authorized-key-install-2026-05-13.md](./fedora-top-authorized-key-install-2026-05-13.md) | Narrow Fedora-side handoff to install the approved MacBook public key for `verlyn13` and return repo-safe evidence. |
| Fedora 44 laptop | [fedora-top-next-agent-handoff-2026-05-13.md](./fedora-top-next-agent-handoff-2026-05-13.md) | Fedora-side pre-hardening detail pass and report directive; copied to `/home/verlyn13/device-admin-prep/` on `fedora-top`. |
| Fedora 44 laptop | [fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md) | MacBook-side live SSH hardening packet with key cleanup, sshd drop-in, verification, and rollback commands; applied on 2026-05-13 with evidence in [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md). |
| Fedora 44 laptop | [fedora-top-privilege-cleanup-packet-2026-05-13.md](./fedora-top-privilege-cleanup-packet-2026-05-13.md) | MacBook-side privilege cleanup packet: snapshot, group removals (`wheel`, `docker`, `systemd-journal`), `/etc/sudoers` duplicate cleanup, `/etc/sudoers.d/50-mesh-ops` decision (default: remove), `restorecon`, `visudo -c`, fresh-session validation, snapshot-backed rollback, and risks. Applied on 2026-05-13 along the default path; evidence in [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md). Retains `verlyn13 NOPASSWD: ALL` pending separate review. |
| Fedora 44 laptop | [fedora-top-infisical-redis-retirement-packet-2026-05-13.md](./fedora-top-infisical-redis-retirement-packet-2026-05-13.md) | MacBook-side Infisical/Redis retirement packet for the `happy-secrets` compose project: forensic-only snapshot, `docker compose -p happy-secrets down --volumes --remove-orphans`, project-image removal (~1.95 GB), Infisical DNF repo file removal, `dnf clean metadata`, validation, and an explicit irreversibility note. Applied on 2026-05-13 along the default path with S4 (image removal) approved; evidence in [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md). |
| Fedora 44 laptop | [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md) | Live apply of the Infisical/Redis retirement packet on 2026-05-13: forensic snapshot to `/var/backups/jefahnierocks-infisical-redis-retirement-20260513T214856Z` (redacted env keys for KEY/SECRET/PASSWORD/TOKEN/JWT/AUTH/CONNECTION_URI patterns); `docker compose -p happy-secrets down --volumes --remove-orphans` reported all three containers + two volumes + one network removed; remnant verification empty by label and by name; listeners on `18080`/`6379`/`5432` gone; three project-only images and 33 layer sha256s deleted (~1.95 GB reclaimed); `/etc/yum.repos.d/infisical-infisical-cli.repo` deleted; `dnf clean metadata` reported 221 MiB cleaned; `dnf repolist` shows no infisical; SSH `allowusers verlyn13` unchanged; `visudo -c` clean; `firewalld` unchanged. Rollback not applicable (intentional irreversible destruction). |
| Fedora 44 laptop | [fedora-top-firewalld-narrowing-packet-2026-05-13.md](./fedora-top-firewalld-narrowing-packet-2026-05-13.md) | MacBook-side firewalld narrowing packet for `fedora-top`: pre-apply snapshot of zones (runtime + permanent) and listeners; `firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/{tcp,udp}` then `firewall-cmd --reload`; preserves services `ssh`, `mdns`, `samba-client`, `dhcpv6-client`. Applied on 2026-05-13 along the default path; evidence in [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md). |
| Fedora 44 laptop | [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md) | Live apply of the firewalld narrowing packet on 2026-05-13: snapshot to `/var/backups/jefahnierocks-firewalld-narrowing-20260513T230224Z` (state, default zone, active zones, runtime + permanent zone listings, direct rules, listeners, full pre-apply zone XML, sha256 manifest); `firewall-cmd --permanent --remove-port=1025-65535/tcp,udp` and `--reload` succeeded; runtime + permanent `ports` empty post-apply; services `dhcpv6-client mdns samba-client ssh` unchanged; active zones unchanged; rich rules empty; docker zone unchanged; sshd `allowusers verlyn13` unchanged; positive SSH check from a fresh MacBook session succeeded. Rollback unused. |
| All devices (index) | [current-status.yaml](./current-status.yaml) | Machine-readable per-device current state. Tracks applied/prepared/blocked packets, latest commits, remote-admin paths, and the next recommended action. Read this first when picking up a device-admin directive. |
| All devices (format) | [handback-format.md](./handback-format.md) | Schema for `current-status.yaml`, the packet-state vocabulary (`applied`, `prepared`, `approval-required`, `blocked`, `planned`), the agent handback template, the cross-cutting `outbound_handback_requests` block, and rules for when to update the YAML. |
| MAMAWORK mini-PC | [windows-pc-mamawork.md](./windows-pc-mamawork.md) | Master record for the second household Windows host (`MAMAWORK`, AZW SER mini-PC, Windows 11 Pro 25H2). Ingests the elevated read-only intake captured 2026-05-13 by `MAMAWORK\jeffr` in PowerShell 7.6.1. LAN SSH from the MacBook is now operational as `jeffr@mamawork.home.arpa` using the 1Password-backed key `SHA256:qilvkR7/...`; LAN RDP also works but is secondary because it conflicts with the active console session. WinRM/PSRemoting disabled; BitLocker/Secure Boot off; PIA fully removed. Status: partially managed, not yet hardened. |
| MAMAWORK mini-PC | [handoff-mamawork.md](./handoff-mamawork.md) | Follow-up handoff that captures 16 operator questions (SSH key continuity from fedora-top, family Microsoft Account mapping, `DadAdmin` replacement, `CodexSandboxOnline`/`CodexSandboxOffline`/`WsiAccount` identities, Defender exclusion subjects, BitLocker / Secure Boot stance, backup plan, etc.) and lists the future approval-gated packets that each question gates. |
| Outbound to cloudflare-dns | [handback-request-cloudflare-dns-2026-05-13.md](./handback-request-cloudflare-dns-2026-05-13.md) | Request to `/Users/verlyn13/Repos/local/cloudflare-dns` for the org-wide Zero Trust / WARP / Access / Tunnel posture and per-device Zero Trust profile recommendations for fedora-top (Wyn user, verlyn13 administrator) and MAMAWORK (kids' learning device, verlyn13 administrator). Non-secret only; no live Cloudflare change requested. |
| Outbound to HomeNetOps | [handback-request-homenetops-2026-05-13.md](./handback-request-homenetops-2026-05-13.md) | Two-item request to `~/Repos/verlyn13/HomeNetOps`: (1) posture confirmation for fedora-top (no new rule requested); (2) static-DHCP reservation for MAMAWORK Ethernet MAC `B0-41-6F-0E-B7-B6` -> `192.168.0.101` plus Unbound host override `mamawork.home.arpa`. Mirrors the 2026-05-13 fedora-top pattern. Non-secret only. **Answered 2026-05-14** - see [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md). |
| MAMAWORK mini-PC | [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md) | Ingest of the HomeNetOps PASS hand-back for MAMAWORK. OPNsense static DHCP reservation bound, Unbound override `mamawork.home.arpa -> 192.168.0.101`, LAN/igc1 ARP confirms IP-to-MAC, `dig` PASS from LAN resolver. The earlier TCP/22 timeout was Windows-side and has since been resolved for the MacBook admin lane. ARP `permanent=false` because MAMAWORK is host-static; switching to DHCP would activate ISC static-ARP defense (optional follow-up packet). |
| Hetzner (advisory) | [hetzner-cloudflare-management-status-ingest-2026-05-14.md](./hetzner-cloudflare-management-status-ingest-2026-05-14.md) | Advisory-only ingest of `/Users/verlyn13/Organizations/the-nash-group/hetzner` commit `009c091`. Hetzner brokers Cloudflare Tunnel ingress for hosted apps (Infisical, Postal Web, runpod-review-webui); it is NOT a household device control plane. Encodes the decision to NOT route household device admin through Hetzner; preferred target remains Cloudflare Zero Trust/WARP via cloudflare-dns; Tailscale stays transition/break-glass. Does **not** satisfy the outbound `cloudflare-dns` request - that stays open until an actual reply from `/Users/verlyn13/Repos/local/cloudflare-dns` arrives. |
| Fedora 44 laptop | [fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md) | Prepared. Adds one additional `verlyn13` ED25519 admin public key to `fedora-top` `/home/verlyn13/.ssh/authorized_keys`, with the private half held only in 1Password (Dev vault on my.1password.com) and served via the 1Password SSH agent on a backup operator device. Keeps `AllowUsers verlyn13`. Keeps `PasswordAuthentication no`. Does not add any other admin user. Does not reuse the legacy MAMAWORK `DadAdmin_WinNet` key. Snapshot-backed rollback. Closes the single-MacBook dependency for fedora-top remote administration. |
| MAMAWORK mini-PC | [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md), [mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md), [mamawork-sshd-admin-match-block-apply-2026-05-14.md](./mamawork-sshd-admin-match-block-apply-2026-05-14.md) | SSH investigation/remediation chain. Scoped investigation found Windows network-identity drift; remediation restored LAN TCP/22 and TCP/3389 reachability from the MacBook. Admin auth still failed until the sshd admin Match block packet restored `AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys` for local Administrators. MacBook real-auth proof now returns `MamaWork` / `mamawork\jeffr`. |
| MAMAWORK mini-PC | [mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md) | Prepared, optional. Switches the MAMAWORK wired adapter from host-side static IP (`192.168.0.101` manual) to DHCP so the existing OPNsense reservation owns the address and ISC static-ARP defense can activate (currently `permanent=false`). Brief 2-10 second reconnect window. Intentionally separate from the SSH investigation packet so connectivity changes are not bundled with debugging. |
| Fleet (Cloudflare) | [cloudflare-dns-handback-ingest-2026-05-14.md](./cloudflare-dns-handback-ingest-2026-05-14.md), [cloudflare-windows-multi-user-ingest-2026-05-15.md](./cloudflare-windows-multi-user-ingest-2026-05-15.md), [handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md](./handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md) | Authoritative `cloudflare-dns` handback (cited commit `b5b9460`, path `docs/handback-system-config-2026-05-13.md` in the cloudflare-dns repo), corrected for MAMAWORK by the 2026-05-15 Windows multi-user addendum. Single Cloudflare account, team `homezerotrust`, IaC is Pulumi-TypeScript (NOT OpenTofu), tokens in **gopass** (NOT 1Password). WARP active on 7 fleet devices but neither fedora-top nor MAMAWORK is enrolled yet. Identity providers: Google OAuth + email OTP. Four profiles (Default + Kids locked + Adults unlocked + Headless MDM). fedora-top remains Kids profile with WARP identity `wynrjohnson@gmail.com`. MAMAWORK target is Windows multi-user mode: admin/operator accounts in Adults/Admin, `ahnie` / Mama / Litecky in adult/work, kids in Kids; cloudflare-dns rebaseline requested for MDM `multi_user=true`, pre-login, profile policy, and per-user enrollment recipe. No SSH Access app or Tunnel exists today (working naming candidates recorded). Supersedes any earlier mistakenly-circulated "cloudflare-dns reply" text. |
| Fedora 44 laptop | [fedora-top-admin-backup-ssh-key-strategy-apply-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-apply-2026-05-14.md) | Live apply 2026-05-14T02:42:25Z of the admin-backup SSH key strategy. Appended a second `verlyn13` ED25519 key (`SHA256:VUu4nr5J+JjTpwFzRw+l2WQoKbfLhQhXAwGQmdlL6qU`, item `op://Dev/jefahnierocks-device-fedora-top-admin-backup-verlyn13`) to fedora-top `authorized_keys` via fingerprint-match gate. Primary MacBook path verified post-apply; sshd effective settings unchanged. Snapshot at `/var/backups/jefahnierocks-fedora-top-admin-backup-key-20260514T024225Z`. Closes the single-MacBook dependency. |
| MAMAWORK mini-PC | [mamawork-ssh-key-bootstrap-packet-2026-05-14.md](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md), [mamawork-ssh-key-bootstrap-apply-2026-05-14.md](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md) | Applied. Installed the new 1Password-backed admin key (`SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY`, item `op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13`) into `C:\ProgramData\ssh\administrators_authorized_keys`. The DadAdmin per-user mirror failed access denied but is operationally inert. Legacy `DadAdmin_WinNet` line was removed by the later admin-streamline packet. Remote verification now passes after the sshd Match-block apply. |
| MAMAWORK mini-PC | [mamawork-lan-rdp-implementation-2026-05-14.md](./mamawork-lan-rdp-implementation-2026-05-14.md), [mamawork-lan-rdp-implementation-apply-2026-05-14.md](./mamawork-lan-rdp-implementation-apply-2026-05-14.md) | Applied and verified after inbound-TCP remediation. Mirrors the DESKTOP-2JJ3187 RDP pattern: NLA enabled, TermService running/Automatic, custom `Jefahnierocks RDP LAN TCP 3389` + `UDP 3389` rules for Private / `192.168.0.0/24`, built-in Remote Desktop firewall group disabled, hibernate off + AC sleep/hibernate 0 + hybrid sleep 0. MacBook Windows App RDP works end-to-end but prompts the active console user to log out; SSH is preferred for concurrent admin. |
| MAMAWORK mini-PC | [windows-app-mamawork.md](./windows-app-mamawork.md) | Prepared. MacBook Windows App profile for MAMAWORK: `PC name = mamawork.home.arpa`; `Credentials = Ask when required` (NEVER saved); `Friendly name = MAMAWORK - Jefahnierocks Admin`; `Gateway = No gateway`; reconnect checked; admin-session unchecked; no redirected folders/devices beyond minimum. Pairs with the MAMAWORK LAN RDP implementation packet. |
| Fedora 44 laptop | [fedora-top-known-hosts-reconciliation-packet-2026-05-13.md](./fedora-top-known-hosts-reconciliation-packet-2026-05-13.md) | MacBook-side packet that adds a `fedora-top.home.arpa` entry to `~/.ssh/known_hosts` using the verified ED25519 fingerprint `SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w`, so routine SSH no longer needs `HostKeyAlias=192.168.0.206`. ssh-keyscan + fingerprint-match gate (not blind TOFU). Approval-gated; no fedora-top side change. |
| Fedora 44 laptop | [fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md) | MacBook-side Tailscale retain-or-remove packet. Two options with their own approval phrases. Guardian chose Option B (Retain logged-out) on 2026-05-13 - see [fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md). Documentation-only; live state unchanged. Auth-URL exposure note carried forward; no daemon restart performed. |
| Fedora 44 laptop | [fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md) | Decision record for Option B (Retain logged-out). No live host change. Tailscale package, daemon, repo, GPG key, and listener posture unchanged from the 2026-05-13T23:18:14Z verification. Operator stop rules attached: no login, no enrollment, no auth-key creation, no firewalld passage, no upgrade, no daemon restart, no auth-URL recording in repo. Further Tailscale work is blocked on the remote-admin routing design packet. |
| Fedora 44 laptop | [fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md) | Prepared remote-admin routing design. LAN-only SSH = current; Tailscale (logged-out) = transition / break-glass; Cloudflare WARP + `cloudflared` = target; direct WAN SSH = rejected. Records household admin / family-account stance. Requests `cloudflare-dns` handback (Zero Trust org, WARP enrollment, Access posture, Tunnel naming, profile recommendation for a Wyn-used + verlyn13-administered device) and a minor HomeNetOps confirmation (no new LAN rule required). Lists four future approval-gated packets (`known-hosts-reconciliation`, `cloudflare-warp-cloudflared-cutover`, `tailscale-login-with-acl`, `tailscale-remove-after-cloudflare-proven`) with placeholder approval phrases. Design only; no live action authorized by approving this packet. |
| Fedora 44 laptop | [fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md) | Directive for the active `system-config` agent to prepare or apply the Fedora SSH hardening packet, depending on explicit guardian approval. |

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
| Fedora 44 laptop | Use verified `verlyn13` SSH from the MacBook over trusted LAN, then complete hardening remotely from `system-config`. Later off-LAN access should use Cloudflare private routing or an Access-protected path; optional Cockpit only through Cloudflare Access; Tailscale only as ACL-restricted break-glass. | LAN public-key SSH is verified. Current blockers are approval-gated SSH hardening, firewall narrowing, privilege cleanup, Infisical/Redis retirement, HomeNetOps stable naming, and LUKS/power strategy. |

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
| Physical/admin context | Home LAN behind OPNsense, same LAN context as `nas.jefahnierocks.com` and `opnsense.jefahnierocks.com`; Ethernet now connected after operator action; BIOS power/WoL prep completed | Home LAN behind OPNsense, same LAN context as `nas.jefahnierocks.com` and `opnsense.jefahnierocks.com`; laptop on Wi-Fi; AC connected in Phase 1; no unattended reboot until LUKS strategy is chosen |
| MAC / LAN IP / overlay identity | Ethernet MAC `18:C0:4D:39:7F:49`; static IP `192.168.0.217`; FQDN `desktop-2jj3187.home.arpa`; Wi-Fi MAC `CC:D9:AC:1F:92:7B` intentionally not mapped; WARP absent | Wi-Fi MAC `66:B5:8C:F5:45:74`; static IP `192.168.0.206`; FQDN `fedora-top.home.arpa`; Tailscale installed but logged out; WARP absent |
| Local admin credential item | Planned; not created | Planned; not created |
| Recovery key item | No BitLocker recovery item needed; BitLocker is not in target state for this slice | Planned; not created; LUKS2 present in source report |
| Remote access enabled | Partial: LAN RDP enabled, firewall-scoped to `192.168.0.0/24`, TCP `3389` reachable from MacBook using `desktop-2jj3187.home.arpa`, interactive GUI management verified, and WoL verified. OpenSSH/WARP absent and duplicate stopped `cloudflared` services remain | Partial: LAN SSH as `verlyn13` from the MacBook is verified using `fedora-top.home.arpa` or `192.168.0.206`. SSH still allows password auth and broad forwarding, has no `AllowUsers`, and contains two non-approved existing public keys that need disposition before hardening. |
| Disk encryption verified | BitLocker off by operator attestation; agent-side elevated check still pending | LUKS2 root/home encryption reported; remote reboot blocked unless unlock strategy is solved |
| Firewall verified | Ethernet profile now `Private`; custom `Jefahnierocks RDP LAN TCP/UDP 3389` rules scoped to `192.168.0.0/24`; built-in RDP rules disabled | `firewalld` active; FedoraWorkstation allows broad high TCP/UDP ports plus `ssh`, `mdns`, `samba-client`, and `dhcpv6-client`; Docker zone target is `ACCEPT` |
| Patch/update posture verified | Windows Update and NVIDIA driver current by operator report; BIOS/UEFI posture improved; RDP/power LAN apply complete; HomeNetOps static DHCP/DNS/WoL complete; `cloudflared` status still pending Cloudflare truth refresh | Firmware current at prior capture; DNF refresh hit signing-key failures for Tailscale and Infisical repos, and no keys were accepted |
| Backup/recovery verified | Backup strategy out of scope in source report | Recovery path depends on LUKS/local helper/TPM strategy; Infisical should not be recovered on this laptop and should be retired from local Docker |

## Next Manual Data Needed

Before any live change, collect or decide:

- Confirm Google identities needed for WARP profile placement. For
  MAMAWORK specifically, do not choose one kid identity for the whole
  machine; use the Windows multi-user rebaseline request.
- Reconcile Windows WARP enrollment with `cloudflare-dns`: per-user
  identity and profile separation must be preserved for shared Windows
  devices.
- Decide whether Windows remote access is strictly Private Network only or also
  gets Access-protected public hostnames.
- Confirm whether the legacy Windows named tunnel should be retained or migrated
  to a dashboard-managed connector token.
- Decide whether to create a Windows break-glass local Administrator account
  and where its credential record belongs in 1Password.
- Continue using the MacBook Windows App profile with
  `desktop-2jj3187.home.arpa` as the target.
- Current packet priorities live in
  `current-status.yaml.current_device_admin_priorities_2026_05_15`.
  MAMAWORK LAN SSH/RDP are operational; the next MAMAWORK action is a
  read-only terminal-admin baseline over `ssh mamawork`, then SSH
  hardening and cleanup packets based on that evidence. WARP remains
  blocked on the `cloudflare-dns` Windows multi-user rebaseline.
- Fedora SSH hardening packet was applied on 2026-05-13; only the approved
  MacBook key remains in `authorized_keys`, and the WSL key plus both
  duplicate `ansible@hetzner.hq` entries were removed. Evidence in
  [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md).
- Reconcile MacBook `known_hosts` for `fedora-top.home.arpa` so the
  `HostKeyAlias=192.168.0.206` workaround is no longer needed for routine
  SSH.
- Decide whether `mesh-ops` remains required after Infisical is retired from
  the laptop.
- Decide whether to remove retired Infisical DNF repos and whether to repair
  Tailscale repo trust only if Tailscale remains part of the target state.
- Use `fedora-top.home.arpa` as the stable Fedora LAN SSH target.
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
