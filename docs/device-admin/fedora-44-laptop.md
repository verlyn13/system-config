---
title: Fedora 44 Laptop Device Administration Record
category: operations
component: device_admin
status: draft
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, luks, firewalld, 1password]
priority: high
---

# Fedora 44 Laptop Device Administration Record

This scaffold captures non-secret administration posture for the Fedora 44
laptop. It is an intake record only until live device-side checks are
performed.

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

Repo-safe current facts from that update:

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
| Wi-Fi MAC | Pending device access |
| Current LAN IP | `192.168.0.206/24` on Wi-Fi from source report; no static IP is assigned yet |
| Tailscale identity | Tailscale installed and service active but logged out; no Tailscale IP in source report |
| WARP identity | WARP not installed in source report |
| DNS / hostname record | Planned only; no DNS change approved |

## Administration Model

| Control | Target | Current status |
|---|---|---|
| Local admin credential | Unique per-device admin credential stored in 1Password only. Device-specific management account may be created if the implementation needs it. | Planned; item/account not created. |
| 1Password local admin item | `jefahnierocks-device-fedora-top-local-admin` | Planned; secret value not created here. |
| Recovery key item | `jefahnierocks-device-fedora-top-recovery-key` | Planned for LUKS recovery material. |
| Administrative SSH | Public-key SSH over Cloudflare private routing or Access-protected hostname only. | Source report says SSH is enabled on all interfaces and needs hardening. |
| SSH identity | Device-specific or explicitly approved human-interactive key use only; no unattended automation with a human workstation key. | Pending design. |
| Password SSH | Disable after key-based access is confirmed and local fallback remains open. | Source report says `PasswordAuthentication yes`. |
| Mission-critical service owner | `verlyn13` is the only account that should own or run mission-critical services. | Current service ownership needs live review before cleanup. |
| Exploratory users | `wyn`, `axel`, `ila`, and other human exploratory accounts may remain usable, but should not have `wheel`, sudo, Docker, or service-management authority by default. | Latest report says `wyn`, `axel`, `ila`, and `mesh-ops` retain elevated memberships or grants; critical hardening target. |

## Remote Access

Preferred path:

- SSH over private overlay/VPN or trusted LAN only.
- Public-key authentication first.
- Do not expose SSH on public WAN.
- Do not use the human workstation SSH identity as unattended automation.
- Follow the existing `system-config` 1Password SSH-agent posture for human
  interactive access.

Current state:

- Source report says OpenSSH server is active and listening on all IPv4/IPv6
  interfaces, password authentication is enabled, WARP/cloudflared are absent,
  and Tailscale is installed but logged out.
- Do not claim this Fedora laptop is remotely administered yet.

## Security Posture

| Area | Target | Current status |
|---|---|---|
| Disk encryption | LUKS/FDE status verified; recovery material stored in 1Password only if applicable. | Source report says root/home volume is LUKS2. Remote reboot is blocked unless TPM2/FIDO2/initramfs/local unlock strategy is chosen. |
| SSH daemon | Enabled only with key-only admin access and private routing constraints. | Latest report says enabled, active, and all-interface listen. Effective password-auth posture still requires sudo-backed verification. |
| SSH auth | Public-key auth confirmed before disabling password SSH. | Prior source report said password auth enabled; latest non-root handoff could not freshly reverify the effective config. Treat as not hardened. |
| Firewall | `firewalld` or equivalent active; SSH limited to Cloudflare/Tailscale/trusted path. | Latest report confirms FedoraWorkstation zone allows broad high ports plus `ssh`, `mdns`, and `samba-client` on Wi-Fi. |
| Updates | Fedora updates current or scheduled; repo GPG prompts resolved deliberately. | Latest report says DNF refresh prompted for Infisical/Tailscale signing-key imports; prompts were not accepted. |
| Containers | No Redis or admin surface exposed broadly on LAN. Infisical should not run on this laptop; current needed Infisical location is Hetzner only. | Latest report confirms Redis on all interfaces at `6379` and Infisical on all interfaces at `18080`. |
| Power/recovery | AC connected; no sleep/hibernate on AC; no remote reboot until LUKS strategy is proven. | Latest report says laptop was on battery, about 5 hours remaining, and recently suspended. |

## Approval-Gated Build Phases

Do not execute these without explicit approval:

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

Source evidence has been ingested from the downloaded Fedora report. No new
live Fedora commands were run from this session.

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

### Safe Next Manual Step

- Live-review users, groups, sudoers, lingering user services, and Docker
  access, then prepare a privilege cleanup that leaves `verlyn13` as the only
  mission-critical admin/service owner.
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
- Confirmed admin SSH public key and authorized_keys state.
- Sudo-backed effective SSH configuration check.
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
