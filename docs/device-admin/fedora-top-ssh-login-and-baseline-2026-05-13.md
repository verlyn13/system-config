---
title: Fedora Top SSH Login And Remote Baseline - 2026-05-13
category: operations
component: device_admin
status: ssh-foothold-verified
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, baseline, evidence]
priority: high
---

# Fedora Top SSH Login And Remote Baseline - 2026-05-13

This record captures the result after the Fedora-side authorized-key install
report was returned and the MacBook-side SSH smoke test was retried.

The SSH foothold is now verified. `fedora-top` is reachable from the MacBook
and accepts the approved 1Password-backed human interactive key for
`verlyn13`.

This is not full hardening or full management.

## Source Evidence

| Source | Scope | Repo-safe handling |
|---|---|---|
| `/Users/verlyn13/Downloads/fedora-top-authorized-key-install-report-2026-05-13.md` | Fedora-side authorized-key install report | Ingested as redacted facts; no raw `authorized_keys`, passwords, private keys, recovery keys, tokens, login URLs, or shell history copied. |
| MacBook SSH smoke test at `2026-05-13T11:05:29-08:00` | LAN TCP check, public-key SSH login, and read-only remote baseline | Machine ID, boot ID, LUKS UUID, and raw interface noise omitted or summarized. |

## Fedora-Side Key Install Result

The Fedora-side agent reported:

- Host: `fedora-top`
- Fedora: Fedora release 44 (Forty Four)
- LAN IP: `192.168.0.206/24` on `wlp0s20f3`
- `sshd`: `active`
- Approved key fingerprint installed:
  `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`
- `/home/verlyn13/.ssh`: `700`, `verlyn13:verlyn13`
- `/home/verlyn13/.ssh/authorized_keys`: `600`, `verlyn13:verlyn13`
- SELinux types:
  - `/home/verlyn13`: `user_home_dir_t`
  - `/home/verlyn13/.ssh`: `ssh_home_t`
  - `/home/verlyn13/.ssh/authorized_keys`: `ssh_home_t`
- No `sshd`, firewall, password SSH, user/group/sudoers, Docker/Infisical,
  WARP/Cloudflare/Tailscale, reboot, or power-policy change was made.

## MacBook SSH Smoke Test

From the MacBook:

```bash
nc -vz -G 3 192.168.0.206 22
ssh -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o BatchMode=yes \
  -o ConnectTimeout=5 \
  verlyn13@192.168.0.206 \
  'hostname; whoami; id; sudo -n true || echo sudo-needs-human'
```

Observed result:

```text
Connection to 192.168.0.206 port 22 [tcp/ssh] succeeded.
fedora-top
verlyn13
uid=1000(verlyn13) gid=1000(verlyn13) groups=1000(verlyn13),10(wheel),973(docker)
```

The command exited successfully and did not print `sudo-needs-human`, so
`sudo -n true` succeeded during the smoke test.

## Remote Read-Only Baseline

The remote baseline was collected over SSH from the MacBook after the smoke
test succeeded.

### Identity

- Hostname: `fedora-top`
- OS: Fedora Linux 44 Workstation Edition
- Kernel: `7.0.4-200.fc44.x86_64`
- Hardware: Lenovo ThinkPad X1 Carbon Gen 10
- Firmware version: `N3AET89W (1.54 )`
- Firmware date: 2026-02-17

Machine ID and boot ID were observed but intentionally omitted from this repo
record.

### Network

- Active Wi-Fi interface: `wlp0s20f3`
- Current IPv4: `192.168.0.206/24`
- Default gateway: `192.168.0.1`
- Active Wi-Fi connection: `Bob's Internet`
- `tailscale0` exists but has no Tailscale IPv4 address in this baseline.
- Several Docker bridge interfaces exist; one bridge was up during the
  baseline.

### Services

Read-only service check showed these services are enabled and active:

- `sshd`
- `firewalld`
- `docker`
- `tailscaled`

### SSH Effective Config

`sudo -n sshd -T` showed:

- `permitrootlogin prohibit-password`
- `pubkeyauthentication yes`
- `passwordauthentication yes`
- `kbdinteractiveauthentication no`
- `x11forwarding yes`
- `allowtcpforwarding yes`
- `allowagentforwarding yes`
- `authorizedkeysfile .ssh/authorized_keys`

Interpretation: SSH is usable but not hardened. Password authentication remains
enabled and forwarding defaults are still broad.

### Listeners

Selected listeners still present on all interfaces:

- SSH: TCP `22` on IPv4 and IPv6
- Redis: TCP `6379` on IPv4 and IPv6
- Infisical app: TCP `18080` on IPv4 and IPv6

### Firewall

`firewalld` is running.

Active zones:

- `FedoraWorkstation` on `wlp0s20f3`
- `docker` on Docker bridge interfaces

`FedoraWorkstation` currently allows:

- services: `dhcpv6-client`, `mdns`, `samba-client`, `ssh`
- broad high ports: `1025-65535/udp`, `1025-65535/tcp`
- forwarding: `yes`

Interpretation: the firewall posture is still broad and must not be treated as
hardened.

### Local Privilege And Account Groups

Group membership observed:

- `wheel`: `verlyn13`, `wyn`, `axel`, `ila`, `mesh-ops`
- `docker`: `verlyn13`, `ila`, `mesh-ops`

Selected user IDs/groups:

- `verlyn13`: in `wheel` and `docker`
- `wyn`: in `wheel`
- `axel`: in `wheel`, `dialout`, and `plugdev`
- `ila`: in `wheel` and `docker`
- `mesh-ops`: in `wheel`, `systemd-journal`, and `docker`

Interpretation: this does not match the target state where `verlyn13` is the
only mission-critical admin/service owner and exploratory users stay usable
without high-impact privileges.

### Containers

Docker containers still running:

- `infisical-app`: image `infisical/infisical:latest-postgres`, publishing
  `0.0.0.0:18080->8080/tcp` and `[::]:18080->8080/tcp`
- `infisical-redis`: image `redis:7`, publishing
  `0.0.0.0:6379->6379/tcp` and `[::]:6379->6379/tcp`
- `infisical-postgres`: image `postgres:14-alpine`, internal `5432/tcp`,
  healthy

Interpretation: laptop-hosted Infisical and Redis are still live LAN-exposed
surfaces. This conflicts with the operator decision that Infisical belongs on
the Hetzner server only for current needs.

### Disk Encryption

Block-device summary:

- Root disk: NVMe, about 1.8 TB
- EFI partition: vFAT mounted at `/boot/efi`
- `/boot`: ext4
- root/home: LUKS2 container with Btrfs filesystem labeled `fedora`

Raw LUKS mapper UUID was observed but omitted from this repo record.

## Current Read

Verified now:

- MacBook can SSH to `fedora-top` as `verlyn13` using the selected
  1Password-backed key.
- `verlyn13` currently has non-interactive sudo capability.
- Remote read-only baseline can be collected from `system-config`.

Still not hardened:

- SSH password authentication remains enabled.
- SSH listens on all IPv4/IPv6 interfaces.
- SSH forwarding options remain permissive.
- `FedoraWorkstation` firewalld zone exposes broad high ports.
- `wyn`, `axel`, `ila`, and `mesh-ops` retain elevated group memberships.
- Docker-published Infisical and Redis remain exposed on all interfaces.
- LUKS remote reboot strategy is not solved.
- No HomeNetOps static DHCP/local DNS mapping is recorded yet.
- No Cloudflare/WARP private access path is active.

## Next Safe Actions

Do not perform all hardening in one batch. The next work should be split into
small approval-gated packets:

1. HomeNetOps handoff for static DHCP/local DNS using Wi-Fi MAC
   `66:B5:8C:F5:45:74`, current IP `192.168.0.206`, hostname `fedora-top`.
2. SSH hardening packet: add a drop-in, keep an existing SSH session open,
   validate with `sshd -t`, then reload only after explicit approval.
3. Firewall narrowing packet: move Wi-Fi to a narrow admin zone and verify a
   second SSH session before making the change permanent.
4. Privilege cleanup packet: remove exploratory users from `wheel`, `docker`,
   and sudoers paths unless a documented admin purpose exists.
5. Infisical/Redis retirement packet: identify compose owner, stop/rebind
   services, and preserve data until recovery expectations are clear.
6. Power/LUKS packet: define AC/no-sleep policy and decide remote reboot
   strategy before relying on unattended reboot.

No public WAN admin exposure is approved.

