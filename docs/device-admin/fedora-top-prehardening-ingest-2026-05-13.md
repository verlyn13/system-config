---
title: Fedora Top Pre-Hardening Report Ingest - 2026-05-13
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, pre-hardening, evidence, hardening-plan]
priority: high
---

# Fedora Top Pre-Hardening Report Ingest - 2026-05-13

This record ingests the Fedora-side pre-hardening detail report returned after
the SSH foothold was verified.

No live hardening was performed by the Fedora-side agent. The only change on
the device was creation of the report file.

## Source Evidence

| Source | Scope | Handling |
|---|---|---|
| `/home/verlyn13/device-admin-prep/fedora-top-prehardening-report-2026-05-13.md` on `fedora-top` | Fedora-side read-only pre-hardening detail pass | Read over SSH from the MacBook and summarized here. Raw report remains on the device. |

Report timestamp: `2026-05-13T11:32:06-08:00`.

## High-Level Result

The report confirms `fedora-top` is reachable and administrable over SSH from
the MacBook as `verlyn13`, but the host is still not hardened.

The next work should be split into approval-gated packets. Do not batch SSH,
firewall, sudoers, Docker, package repo, Tailscale, and power/LUKS changes
together.

## Findings

### SSH

Effective SSH posture is wide open for a managed endpoint:

- `PasswordAuthentication yes`
- `AllowAgentForwarding yes`
- `AllowTcpForwarding yes`
- `X11Forwarding yes`
- `PermitRootLogin prohibit-password`
- `AuthenticationMethods any`
- no effective `AllowUsers`
- stock Red Hat drop-ins only:
  - `/etc/ssh/sshd_config.d/40-redhat-crypto-policies.conf`
  - `/etc/ssh/sshd_config.d/50-redhat.conf`
- `sshd -t` passes

`/home/verlyn13/.ssh/authorized_keys` contains three ED25519 keys by
fingerprint:

- `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8` approved MacBook key
- `SHA256:V3oZ/zOfm/IHLHF0i+nT7R6OItQbw/2N2CZq7iS3pNg` `ansible@hetzner.hq`
- `SHA256:xHbcJoWrOxffuoiu+jS+8i9rUovVeUFeO6Y9A5WMpS4`
  `verlyn13@wsl-fedora42-to-thinkpad-t440s`

Decision needed before SSH hardening: retain, rotate, or remove the two
non-approved existing keys.

### Firewall

`firewalld` is running, but the active workstation posture is broad:

- `FedoraWorkstation` on `wlp0s20f3`
- services: `dhcpv6-client`, `mdns`, `samba-client`, `ssh`
- ports: `1025-65535/tcp`, `1025-65535/udp`
- forwarding: `yes`
- `docker` zone is active on Docker bridges with target `ACCEPT`
- no direct rules or passthroughs

Decision needed: whether SSH should remain LAN-reachable during transition or
move behind a private overlay before firewall narrowing.

### Users, Groups, And Sudoers

Elevated group membership remains broader than target:

- `wheel`: `verlyn13`, `wyn`, `axel`, `ila`, `mesh-ops`
- `docker`: `verlyn13`, `ila`, `mesh-ops`
- `mesh-ops`: also in `systemd-journal`
- `axel`: also in `dialout` and `plugdev`

Sudoers anomalies:

- `/etc/sudoers.d/50-mesh-ops` has wrong mode; `visudo -c` says it should be
  `0440`
- `/etc/sudoers:108` has duplicate explicit `wyn ALL=(ALL) ALL`
- `verlyn13` has `NOPASSWD: ALL` via `/etc/sudoers.d/ansible-automation`
- `mesh-ops` has several `NOPASSWD` wildcard grants, including:
  - `dnf install -y *`
  - `firewall-cmd *`
  - Docker/Podman wildcards
  - Tailscale service and CLI wildcards

Decision needed: whether `mesh-ops` is still required at all after Infisical is
retired from this laptop.

### Docker, Infisical, And Redis

Docker is enabled and active.

The running Infisical stack belongs to compose project `happy-secrets` at:

```text
/home/verlyn13/Projects/happy-secrets
```

Running containers:

- `infisical-app`
  - image `infisical/infisical:latest-postgres`
  - publishes `0.0.0.0:18080->8080/tcp` and `[::]:18080->8080/tcp`
- `infisical-redis`
  - image `redis:7`
  - publishes `0.0.0.0:6379->6379/tcp` and `[::]:6379->6379/tcp`
- `infisical-postgres`
  - image `postgres:14-alpine`
  - internal `5432/tcp`
  - no host port published

This conflicts with the operator decision that Infisical belongs on the Hetzner
server only for current needs.

### Updates And External Repos

Enabled external or notable repos include Visual Studio Code, Google Chrome,
GitHub CLI, Tailscale stable, RPM Fusion, and three Infisical Cloudsmith repos.

`dnf check-update --refresh --assumeno` found:

- one pending `code` upgrade
- GPG metadata verification failures for:
  - `tailscale-stable`
  - `infisical-infisical-cli`
  - `infisical-infisical-cli-noarch`
  - `infisical-infisical-cli-source`

No signing keys were accepted.

Decision needed: remove retired Infisical repos if Infisical is retired, and
decide separately whether to keep Tailscale and repair its repo trust path.

### Tailscale, WARP, Cloudflared, Cockpit

- Tailscale binary exists.
- `tailscaled` is enabled and active.
- Tailscale status is `Logged out`.
- `tailscale0` has only IPv6 link-local addressing; no IPv4 tailnet address.
- Tailscale CLI printed a login URL; it was redacted and not opened.
- WARP is absent.
- `cloudflared` is absent.
- Cockpit unit files exist.
- `cockpit.socket` is disabled.

Decision needed: whether Tailscale should become ACL-restricted break-glass,
be removed, or stay installed but logged out for now.

### Power, Sleep, LUKS, Boot

- AC is online.
- Battery is `80%`, `pending-charge`.
- sleep/suspend/hibernate targets were inactive at report time.
- journal shows suspend/resume events on 2026-05-12.
- root/home are Btrfs on LUKS2.
- `/boot` is ext4.
- `/boot/efi` is vfat.
- Secure Boot is disabled.
- TPM2 is supported.
- GRUB 2.12 is active.
- EFI boot variables list Fedora, Windows Boot Manager, and
  Linux-Firmware-Updater.
- The device is dual-boot.

Decision needed: whether the remote administration target tolerates no remote
reboot, or whether a TPM2/FIDO2/initramfs unlock strategy should be designed.

## Recommended Packet Order

Recommended next packet order:

1. HomeNetOps static DHCP/local DNS handoff for `fedora-top`.
2. SSH hardening implementation with rollback and a held-open existing SSH
   session.
3. Privilege cleanup for `wheel`, `docker`, sudoers, and `mesh-ops`.
4. Infisical/Redis retirement from the laptop.
5. `firewalld` narrowing after SSH and service-retirement sequencing is clear.
6. Tailscale/WARP/Cloudflare decision packet for off-LAN access.
7. Power/LUKS remote reboot strategy.

Rationale:

- Stable LAN identity helps all subsequent verification.
- SSH hardening is high-impact but now has a working key path.
- Privilege cleanup reduces blast radius before service and firewall work.
- Infisical/Redis retirement removes broad LAN service exposure.
- Firewall narrowing is safer after knowing which local services remain.

## Stop Rules Preserved

No public WAN admin exposure is approved.

Do not make any of these changes without explicit approval:

- SSH daemon changes or reload.
- Password SSH disablement.
- Firewall changes.
- User, group, or sudoers changes.
- Docker compose, container, image, or volume changes.
- DNF signing-key imports.
- Tailscale login or logout.
- WARP, `cloudflared`, Cloudflare, DNS, or OPNsense changes.
- Power, LUKS, Secure Boot, TPM, firmware, or reboot changes.
