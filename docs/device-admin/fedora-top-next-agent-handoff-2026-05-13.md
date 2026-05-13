---
title: Fedora Top Next Agent Handoff - 2026-05-13
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, pre-hardening, handoff]
priority: high
---

# Fedora Top Next Agent Handoff - 2026-05-13

Use this document for the next Fedora-side agent running locally on
`fedora-top`.

The SSH foothold is already verified from the MacBook as `verlyn13`. This
handoff is for a pre-hardening detail pass and report. Do not perform live
hardening in this packet.

Canonical repo copy:

```text
docs/device-admin/fedora-top-next-agent-handoff-2026-05-13.md
```

Fedora-side working copy:

```text
/home/verlyn13/device-admin-prep/fedora-top-next-agent-handoff-2026-05-13.md
```

## Current Verified State

- Device: `fedora-top`
- OS: Fedora Linux 44 Workstation Edition
- Current LAN IP: `192.168.0.206/24`
- Wi-Fi MAC: `66:B5:8C:F5:45:74`
- MacBook public-key SSH as `verlyn13`: verified
- Selected approved key fingerprint:
  `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`
- `verlyn13` currently has non-interactive sudo capability.
- SSH is usable but not hardened.
- `firewalld` posture is broad.
- `wyn`, `axel`, `ila`, and `mesh-ops` still have elevated groups.
- Infisical and Redis are still published on all LAN interfaces.

## Mission

Produce a repo-safe report that lets `system-config` split the next work into
small approval-gated implementation packets:

1. HomeNetOps static DHCP/local DNS handoff.
2. SSH hardening packet.
3. `firewalld` narrowing packet.
4. Privilege cleanup packet.
5. Infisical/Redis retirement packet.
6. Power/LUKS remote-administration packet.

Your job is to collect facts and report. Do not implement those packets.

## Hard Stops

Stop and ask before doing any of the following:

- Editing `/etc/ssh/sshd_config` or files under `/etc/ssh/sshd_config.d/`.
- Reloading or restarting `sshd`.
- Disabling password SSH.
- Changing `firewalld` zones, services, ports, rich rules, or direct rules.
- Adding, deleting, disabling, or modifying users.
- Changing group membership, sudoers, PAM, polkit, Docker permissions, or
  service ownership.
- Stopping, restarting, rebinding, deleting, or modifying Docker containers,
  compose files, volumes, or images.
- Accepting DNF/GPG prompts for Infisical, Tailscale, or any external repo.
- Installing, enrolling, logging in, logging out, or changing Tailscale, WARP,
  `cloudflared`, Cockpit, VPN, or remote management agents.
- Changing sleep, hibernate, power, LUKS, TPM, Secure Boot, firmware, AMT, or
  reboot behavior.
- Rebooting, shutting down, suspending, or hibernating the laptop.
- Reading, printing, copying, or exporting passwords, private keys, recovery
  keys, tokens, login URLs, browser secrets, shell history, `.env` secret
  values, or credential stores.

Allowed change in this packet:

- Write your non-secret report under:

```text
/home/verlyn13/device-admin-prep/fedora-top-prehardening-report-2026-05-13.md
```

## Report Rules

- Summarize facts; do not paste huge raw logs.
- Redact machine ID, boot ID, disk UUIDs, token-like values, login URLs, and
  private paths that are not needed for administration.
- Do not include raw `.env` files or Docker environment variables.
- Do not include raw `authorized_keys`; fingerprints only.
- Record commands/sources for every important finding.
- Separate verified current state from planned changes and approvals needed.

## Step 1 - Confirm Host And SSH Foothold

Run:

```bash
date -Iseconds
hostname
cat /etc/fedora-release
uname -r
whoami
id
sudo -n true && echo 'sudo-noninteractive=yes' || echo 'sudo-noninteractive=no'
systemctl is-active sshd
```

Report:

- timestamp;
- hostname;
- Fedora version;
- kernel;
- current user;
- whether `sudo -n true` succeeds;
- `sshd` state.

## Step 2 - Network And HomeNetOps Facts

Run:

```bash
ip -brief addr
ip route
nmcli -t -f NAME,TYPE,DEVICE,STATE connection show --active
nmcli -t -f GENERAL.DEVICE,GENERAL.HWADDR,GENERAL.TYPE,GENERAL.STATE device show wlp0s20f3
```

Report:

- active admin interface;
- current LAN IPv4;
- default gateway;
- Wi-Fi MAC;
- active Wi-Fi connection name;
- whether `tailscale0` has an IPv4 address.

Do not dump saved Wi-Fi profiles or Wi-Fi PSKs.

## Step 3 - SSH Read-Only Detail

Run:

```bash
sudo -n sshd -T |
  grep -Ei '^(permitrootlogin|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|authorizedkeysfile|allowusers|x11forwarding|allowtcpforwarding|allowagentforwarding|permitopen|authenticationmethods) '

sudo -n find /etc/ssh/sshd_config.d -maxdepth 1 -type f -print 2>/dev/null |
  sort

sudo -n sshd -t && echo 'sshd-config-syntax=ok'

sudo -n ssh-keygen -lf /home/verlyn13/.ssh/authorized_keys -E sha256 |
  sort -u
```

Report:

- effective SSH auth and forwarding posture;
- whether any drop-in files already exist;
- whether `sshd -t` passes;
- authorized key fingerprints only.

Do not edit SSH config. Do not paste raw public key lines.

## Step 4 - Firewall Read-Only Detail

Run:

```bash
firewall-cmd --state
firewall-cmd --get-active-zones
firewall-cmd --zone=FedoraWorkstation --list-all
firewall-cmd --zone=docker --list-all 2>/dev/null || true
sudo -n firewall-cmd --direct --get-all-rules 2>/dev/null || true
sudo -n firewall-cmd --direct --get-all-passthroughs 2>/dev/null || true
```

Report:

- active zones and attached interfaces;
- services and ports allowed on `FedoraWorkstation`;
- Docker zone summary;
- any direct rules or passthroughs.

Do not change firewall state.

## Step 5 - Users, Groups, And Sudoers Read-Only Detail

Run:

```bash
getent group wheel docker systemd-journal dialout plugdev
for user in verlyn13 wyn axel ila mesh-ops; do
  id "$user" 2>/dev/null || true
done

sudo -n visudo -c
for user in verlyn13 wyn axel ila mesh-ops; do
  sudo -n -l -U "$user" 2>/dev/null || true
done

sudo -n grep -RInE 'verlyn13|wyn|axel|ila|mesh-ops|%wheel|%docker' \
  /etc/sudoers /etc/sudoers.d 2>/dev/null || true
```

Report:

- `wheel`, `docker`, and service-impacting group members;
- sudo grants by user;
- sudoers files that mention these users or groups;
- which users should be removed from elevated paths in a later approval packet.

Do not change users, groups, or sudoers.

## Step 6 - Docker, Infisical, Redis, And Service Exposure

Run:

```bash
systemctl is-enabled docker 2>/dev/null || true
systemctl is-active docker 2>/dev/null || true

docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'

docker inspect --format \
  '{{.Name}} project={{ index .Config.Labels "com.docker.compose.project" }} dir={{ index .Config.Labels "com.docker.compose.project.working_dir" }} files={{ index .Config.Labels "com.docker.compose.project.config_files" }}' \
  $(docker ps -q) 2>/dev/null || true

ss -tulpn | grep -E ':(22|6379|18080|3000|8000|8080|9090)([[:space:]]|$)' || true
```

Report:

- running containers;
- published ports;
- compose project name and working directory, if available;
- listener summary;
- the safest proposed retirement sequence for laptop-hosted Infisical/Redis.

Do not run `docker inspect` formats that print environment variables. Do not
read `.env` files. Do not stop containers.

## Step 7 - Updates, External Repos, Tailscale, WARP, Cloudflared

Run:

```bash
dnf repolist --enabled
dnf check-update --refresh --assumeno

command -v tailscale || true
systemctl is-enabled tailscaled 2>/dev/null || true
systemctl is-active tailscaled 2>/dev/null || true
tailscale status 2>/dev/null || true

command -v warp-cli || true
command -v cloudflared || true
systemctl list-unit-files 2>/dev/null |
  grep -Ei 'cloudflare|warp|tailscale|cockpit' || true
```

Rules:

- If DNF asks to import a signing key, answer no or interrupt. Do not accept
  any signing key.
- If Tailscale prints a login URL, redact it.
- Do not log in or enroll any agent.

Report:

- enabled repos;
- update/GPG prompt blockers;
- Tailscale installed/running/login state without login URLs;
- WARP/cloudflared/Cockpit presence or absence.

## Step 8 - Power, Sleep, And LUKS Read-Only Detail

Run:

```bash
upower -d | grep -E 'line_power|online:|state:|percentage:|time to empty|time to full' || true
systemctl status sleep.target suspend.target hibernate.target hybrid-sleep.target --no-pager
systemctl list-timers --all | grep -Ei 'sleep|suspend|hibernate|dnf|fwupd' || true
findmnt /
lsblk -o NAME,FSTYPE,FSVER,LABEL,MOUNTPOINTS,SIZE,TYPE
bootctl status 2>/dev/null || true
```

Report:

- AC/battery state;
- sleep/suspend/hibernate target state;
- whether any obvious timers might affect availability;
- filesystem/encryption summary without UUIDs;
- boot mode summary if available.

Do not reboot. Do not change LUKS, TPM, FIDO2, initramfs, sleep, or power
policy.

## Report Format

Write your report to:

```text
/home/verlyn13/device-admin-prep/fedora-top-prehardening-report-2026-05-13.md
```

Use this shape:

```text
# fedora-top Pre-Hardening Detail Report

Device:
Timestamp:
Local operator:
Scope:

Summary:
- ...

Verified current state:
- SSH:
- Firewall:
- Users/groups/sudoers:
- Docker/Infisical/Redis:
- Updates/repos:
- Tailscale/WARP/cloudflared:
- Power/LUKS:
- HomeNetOps facts:

Changed:
- Report file only.

Not changed:
- sshd config:
- password SSH:
- firewall:
- users/groups/sudoers:
- Docker/Infisical/Redis:
- WARP/Cloudflare/Tailscale:
- power/LUKS/reboot:

Recommended next approval packets:
1. ...
2. ...

Blocked or needs human decision:
- ...

Repo-safe evidence:
- Command/source:
  Observation:
  Redaction:
```

End your work after the report is written. Wait for `system-config` to decide
which implementation packet is approved next.
