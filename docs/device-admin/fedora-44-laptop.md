---
title: Fedora 44 Laptop Device Administration Record
category: operations
component: device_admin
status: ssh-foothold-verified
version: 0.4.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, luks, firewalld, 1password]
priority: high
---

# Fedora 44 Laptop Device Administration Record

This record captures non-secret administration posture for the Fedora 44
laptop. MacBook-to-Fedora public-key SSH as `verlyn13` is verified, and a
remote read-only baseline has been collected. The device is not fully hardened
or fully managed yet.

## Source Input

Ingested source:
`/Users/verlyn13/Downloads/fedora-top-remote-admin-report-2026-05-12.md`.

The source report was captured locally from `fedora-top` on 2026-05-12 AKDT /
2026-05-13 UTC. Treat its current-state observations as planning evidence that
still needs targeted re-verification during execution.

The source report's build plan is not authoritative for Jefahnierocks
administration. Access setup, WARP enrollment, Cloudflare routing, Tailscale
break-glass, 1Password records, and device-side changes must be translated into
the local `system-config`, `cloudflare-dns`, and HomeNetOps standards before
execution.

## Returned Readiness Update

External evidence ingested from:

- `/Users/verlyn13/Documents/temp/fedora-top-readiness-report-2026-05-12.md`
- `/Users/verlyn13/Downloads/fedora-top-phase-1-ssh-foothold-report-2026-05-13.md`
- [fedora-top-phase-1-ssh-foothold-2026-05-13.md](./fedora-top-phase-1-ssh-foothold-2026-05-13.md)
  for the repo-safe Phase 1 ingestion and MacBook-side smoke test result.
- `/Users/verlyn13/Downloads/fedora-top-authorized-key-install-report-2026-05-13.md`
- [fedora-top-ssh-login-and-baseline-2026-05-13.md](./fedora-top-ssh-login-and-baseline-2026-05-13.md)
  for the repo-safe key-install result, successful MacBook SSH test, and
  remote read-only baseline.

Repo-safe current facts from these updates:

- Fresh read-only pass confirms `fedora-top`, Fedora 44 Workstation, kernel
  `7.0.4-200.fc44.x86_64`, and Wi-Fi `192.168.0.206/24`.
- `wyn` remains in `wheel`; `sudo -l -U wyn` reports two `(ALL) ALL` grants.
- `axel`, `ila`, and `mesh-ops` remain in `wheel`; `ila` and `mesh-ops` are in
  `docker`.
- `sshd` is enabled and active, listening on all IPv4/IPv6 interfaces.
- The handoff did not freshly verify effective SSH password-auth settings
  because non-root `sshd -T` could not read the full config.
- `firewalld` is active with the permissive `FedoraWorkstation` zone on Wi-Fi,
  allowing `ssh`, `mdns`, `samba-client`, and broad high TCP/UDP ports.
- WARP and `cloudflared` are absent.
- Tailscale is installed and active but logged out; login URL was intentionally
  omitted.
- LUKS2 root/home encryption remains confirmed; TPM2 exists; Secure Boot is
  disabled.
- Laptop was on battery, not AC, and recent suspend activity was observed.
- Docker publishes Redis on all interfaces at `6379` and Infisical on all
  interfaces at `18080`.
- `dnf check-update --refresh` prompted for Infisical/Tailscale signing-key
  imports; prompts were not accepted.
- Human operator clarified that Jefahnierocks owns the device, `verlyn13`
  should be the only account running mission-critical services, exploratory
  accounts should stay usable without dangerous privileges, and Infisical
  belongs on the Hetzner server only.
- Phase 1 Fedora-side SSH foothold report confirms AC power connected, Wi-Fi
  MAC `66:B5:8C:F5:45:74`, current LAN IP `192.168.0.206/24`, `sshd` enabled
  and active, TCP `22` listening on IPv4/IPv6, and
  `/home/verlyn13/.ssh/authorized_keys` present with correct ownership and
  permissions.
- MacBook-side smoke test initially confirmed TCP `22` reachability but failed
  public-key SSH before the approved MacBook key was installed.
- Authorized-key install report confirms approved key fingerprint
  `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8` was installed with
  correct permissions and SELinux context.
- MacBook-side public-key SSH as `verlyn13` now succeeds using the selected
  1Password-backed human interactive key. `sudo -n true` succeeded during the
  smoke test.
- Remote baseline confirms effective SSH still has `PasswordAuthentication
  yes`, `X11Forwarding yes`, `AllowTcpForwarding yes`, and
  `AllowAgentForwarding yes`; SSH is usable but not hardened.

## Identity

| Field | Value |
|---|---|
| Device label | Lenovo ThinkPad X1 Carbon Gen 10 |
| Proposed hostname | `fedora-top` |
| OS version/build | Fedora Linux 44 Workstation Edition; kernel `7.0.4-200.fc44.x86_64`, from source report |
| Intended user/owner | Jefahnierocks-owned Wyn summer-use laptop; `verlyn13` is the sole mission-critical admin/service owner |
| Physical location / administrative context | Home LAN behind OPNsense, same LAN context as `nas.jefahnierocks.com` and `opnsense.jefahnierocks.com`; laptop currently on home Wi-Fi; remote administration requires AC power and no unattended reboot unless LUKS unlock is solved |
| Serial/service tag | Recorded in source report; omitted from this repo record unless needed for support workflow |

## Network Identity

| Field | Value |
|---|---|
| Wired MAC | Pending device access |
| Wi-Fi MAC | `66:B5:8C:F5:45:74`, verified in Phase 1 report |
| Current LAN IP | `192.168.0.206/24` on Wi-Fi from Phase 1 report; no static IP is assigned yet |
| Tailscale identity | Tailscale installed and service active but logged out; no Tailscale IP in source report |
| WARP identity | WARP not installed in source report |
| DNS / hostname record | Planned only; no DNS change approved |

## Administration Model

| Control | Target | Current status |
|---|---|---|
| Local admin credential | Unique per-device admin credential stored in 1Password only. Device-specific management account may be created if the implementation needs it. | Planned; item/account not created. |
| 1Password local admin item | `jefahnierocks-device-fedora-top-local-admin` | Planned; secret value not created here. |
| Recovery key item | `jefahnierocks-device-fedora-top-recovery-key` | Planned for LUKS recovery material. |
| Administrative SSH | Use verified `verlyn13` SSH from the MacBook over trusted LAN; finish hardening remotely from `system-config` in small approval-gated packets. | Verified from MacBook to `192.168.0.206` using the selected 1Password-backed human interactive key. |
| SSH identity | Device-specific or explicitly approved human-interactive key use only; no unattended automation with a human workstation key. | Selected human interactive key fingerprint `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8` is installed for `verlyn13`. |
| Password SSH | Disable after key-based access is confirmed and local fallback remains open. | Effective config still says `passwordauthentication yes`; hardening not yet applied. |
| Mission-critical service owner | `verlyn13` is the only account that should own or run mission-critical services. | Current service ownership needs live review before cleanup. |
| Exploratory users | `wyn`, `axel`, `ila`, and other human exploratory accounts may remain usable, but should not have `wheel`, sudo, Docker, or service-management authority by default. | Latest report says `wyn`, `axel`, `ila`, and `mesh-ops` retain elevated memberships or grants; critical hardening target. |

## Remote Access

Preferred path:

- SSH over trusted LAN first, then Cloudflare private routing or
  Access-protected hostname later if needed.
- Public-key authentication first; keep password SSH temporarily until
  MacBook-to-Fedora public-key access is verified.
- Do not expose SSH on public WAN.
- Do not use the human workstation SSH identity as unattended automation.
- Follow the existing `system-config` 1Password SSH-agent posture for human
  interactive access.

Current state:

- Phase 1 confirms OpenSSH server is enabled, active, and listening on all
  IPv4/IPv6 interfaces.
- MacBook TCP reachability to `192.168.0.206:22` is verified.
- MacBook public-key SSH as `verlyn13` is verified.
- `verlyn13` currently has non-interactive sudo capability.
- Prior source report says password authentication is enabled,
  WARP/cloudflared are absent, and Tailscale is installed but logged out.
- Do not claim this Fedora laptop is fully managed until SSH hardening,
  firewall narrowing, privilege cleanup, service exposure cleanup, and
  recovery/power posture are completed and verified.

## SSH Foothold Phase

The SSH foothold is complete. Most remaining administration can now be done
remotely from here, but hardening still needs explicit approval and should be
split into small packets.

Phase 1 current result:

- Fedora-side checks are complete.
- AC power is connected.
- TCP `22` is reachable from the MacBook.
- Public-key SSH from the MacBook succeeds as `verlyn13`.
- Remote read-only baseline has been collected.

Next work should do the larger hardening remotely from the MacBook:

- SSH drop-in hardening and password-SSH disablement after a rollback path is
  ready.
- `firewalld` narrowing for SSH and removal of broad workstation-zone
  exposure.
- Privilege cleanup so `verlyn13` is the only mission-critical
  admin/service owner.
- Retirement of laptop-hosted Infisical and rebinding/stopping broad Redis or
  Docker-published admin surfaces.
- Fedora update/GPG-key decisions.
- LUKS/reboot strategy and AC/no-sleep policy.
- HomeNetOps static DHCP/local DNS after Wi-Fi MAC is confirmed.

## Security Posture

| Area | Target | Current status |
|---|---|---|
| Disk encryption | LUKS/FDE status verified; recovery material stored in 1Password only if applicable. | Source report says root/home volume is LUKS2. Remote reboot is blocked unless TPM2/FIDO2/initramfs/local unlock strategy is chosen. |
| SSH daemon | Enabled only with key-only admin access and private routing constraints. | Enabled, active, all-interface listen. Effective config is verified and not hardened yet. |
| SSH auth | Public-key auth confirmed before disabling password SSH. | Public-key login from MacBook succeeds. Effective config still has `passwordauthentication yes`; do not leave this as final posture. |
| Firewall | `firewalld` or equivalent active; SSH limited to Cloudflare/Tailscale/trusted path. | Latest report confirms FedoraWorkstation zone allows broad high ports plus `ssh`, `mdns`, and `samba-client` on Wi-Fi. |
| Updates | Fedora updates current or scheduled; repo GPG prompts resolved deliberately. | Latest report says DNF refresh prompted for Infisical/Tailscale signing-key imports; prompts were not accepted. |
| Containers | No Redis or admin surface exposed broadly on LAN. Infisical should not run on this laptop; current needed Infisical location is Hetzner only. | Latest report confirms Redis on all interfaces at `6379` and Infisical on all interfaces at `18080`. |
| Power/recovery | AC connected; no sleep/hibernate on AC; no remote reboot until LUKS strategy is proven. | Phase 1 report says AC is now connected and battery is `80%`, `pending-charge`; prior readiness report showed recent suspend, so AC/no-sleep policy still needs deliberate verification before relying on remote availability. |

## Approval-Gated Build Phases

Do not execute these without explicit approval:

0. Establish the LAN SSH foothold for `verlyn13` from the MacBook.
   Completed on 2026-05-13; remote management can now continue from here.
1. Remove non-`verlyn13` accounts from `wheel`, sudoers, Docker, and
   service-management paths unless an account has a documented administrative
   purpose.
2. Confirm `verlyn13` key access, then harden `sshd` with a drop-in.
3. Install/enroll Cloudflare WARP and install/configure `cloudflared`.
4. Create Cloudflare Access/private routing for SSH and optional Cockpit.
5. Tighten `firewalld` after Cloudflare access is proven.
6. Retire Infisical from the laptop and stop or rebind Docker-published Redis
   and admin surfaces so they are not exposed on the LAN.
7. Configure AC/no-sleep/no-hibernate policy for the summer period.
8. Choose and test the LUKS remote-reboot strategy.
9. Decide whether to enroll Tailscale as ACL-restricted break-glass or remove
   it.
10. Optionally investigate AMT/vPro in BIOS, but do not assume it is live.

## Evidence

Source evidence has been ingested from the downloaded Fedora reports.
MacBook-side TCP and SSH checks plus the remote read-only baseline were run
from this repo session and recorded in
[fedora-top-ssh-login-and-baseline-2026-05-13.md](./fedora-top-ssh-login-and-baseline-2026-05-13.md).

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

- `hostnamectl`
- `cat /etc/fedora-release`
- `nmcli device show` with private data redacted before copying into repo docs.
- `lsblk -f` or `cryptsetup status <name>` with identifiers redacted as needed.
- `systemctl status sshd --no-pager`
- `ss -tulpn` with attention to SSH binding.
- `firewall-cmd --state` and `firewall-cmd --list-all`
- Tailscale or WARP client status, if installed.

## Checklist

### Verified Current State

- Source report identifies the host as `fedora-top`, Fedora Linux 44
  Workstation Edition on a ThinkPad X1 Carbon Gen 10.
- Source report says LUKS2 protects the root/home volume.
- Latest readiness report freshly verifies `wyn` has admin rights through
  `wheel` and duplicate `(ALL) ALL` sudo grants.
- Latest readiness report confirms SSH is enabled with broad listen scope.
  Effective SSH auth settings still need sudo-backed verification.
- Latest readiness report confirms WARP and `cloudflared` are absent; Tailscale
  is installed but logged out.
- Latest readiness report confirms AC/power readiness is not met and Docker
  exposes Redis/Infisical broadly on LAN.
- Phase 1 Fedora-side report confirms AC is now connected, Wi-Fi MAC is
  `66:B5:8C:F5:45:74`, TCP `22` is listening, and
  `/home/verlyn13/.ssh/authorized_keys` permissions are correct.
- Authorized-key install report confirms the selected MacBook public key is
  present with correct ownership, permissions, and SELinux context.
- MacBook-side check confirms public-key SSH login as `verlyn13` succeeds.
- Remote baseline confirms `verlyn13` currently has non-interactive sudo and
  Docker group membership.

### Safe Next Manual Step

- Treat the SSH foothold as verified. Do not perform broad hardening in one
  batch.
- Prepare HomeNetOps static DHCP/local DNS handoff using Wi-Fi MAC
  `66:B5:8C:F5:45:74`, current IP `192.168.0.206`, hostname `fedora-top`.
- Prepare a narrow SSH hardening packet, with rollback, for explicit approval.
- Prepare a narrow firewalld packet after SSH hardening is ready.
- Prepare a narrow privilege cleanup packet for `wheel`, `docker`, sudoers,
  and service ownership.
- Use Wi-Fi MAC `66:B5:8C:F5:45:74` and current IP `192.168.0.206` if
  HomeNetOps static DHCP/local DNS planning is requested.
- After SSH is verified, remotely live-review users, groups, sudoers,
  lingering user services, and Docker access, then prepare a privilege cleanup
  that leaves `verlyn13` as the only mission-critical admin/service owner.
- Keep exploratory accounts, including `wyn`, usable as standard accounts
  without sudo, Docker, broad service control, or ownership of critical
  services.
- Confirm whether Tailscale should be retained as break-glass or removed.
- Choose LUKS strategy before remote reboot is relied on.
- Decide whether Cockpit is useful enough to enable behind Cloudflare Access.
- Retire the laptop-hosted Infisical surface; current Infisical authority is the
  Hetzner server only.
- Stop or rebind Redis and any remaining Docker-published admin surfaces so
  they are not exposed on the LAN.
- Decide whether a static DHCP mapping or local DNS record should be requested
  through HomeNetOps.
- Connect AC power before relying on this device remotely.

### Blocked Pending Human/Device Access

- Live re-verification of current users/groups/sudoers before privilege edits.
- Approval for SSH hardening implementation.
- Approval for firewall narrowing implementation.
- Approval for privilege cleanup implementation.
- Cloudflare package repo setup and WARP/cloudflared installation.
- Firewall changes after an alternate admin path is proven.
- 1Password recovery/admin credential item creation or update.
- Repository signing-key decisions for Infisical and Tailscale package sources.

### Requires Explicit Approval

- Creating or editing any 1Password item containing a password, private key, or
  recovery key.
- Changing local users, groups, or sudoers.
- Reloading or changing SSH configuration.
- Disabling password SSH.
- Opening or changing firewall rules.
- Creating static DHCP or DNS records.
- Enrolling in Tailscale, WARP, or any management agent.
- Changing Cloudflare tunnel, private route, Access, Gateway, or device profile
  state.
- Changing Docker compose/port bindings for Infisical or Redis, including
  retiring laptop-hosted Infisical.
- Changing power/sleep/LUKS/TPM/AMT behavior.
