---
title: Device Agent Handoff - fedora-top
category: operations
component: device_admin
status: draft
version: 0.2.0
last_updated: 2026-05-13
tags: [device-admin, handoff, fedora, ssh, luks, cloudflare, warp]
priority: high
---

# Device Agent Handoff - fedora-top

This is the handoff for an agent running locally on the Fedora laptop
`fedora-top`.

## Mission

Prepare a minimal SSH foothold for Jefahnierocks device administration, then
return a repo-safe readiness report. This is not the full hardening pass.
Once the MacBook can SSH in as `verlyn13`, the remaining management should be
done remotely from `system-config`.

The local Fedora report contains useful facts, but it is not authoritative.
Jefahnierocks owns device administration from `system-config`, with
`cloudflare-dns` owning Cloudflare/WARP policy semantics and HomeNetOps owning
OPNsense/LAN/router changes.

## Authority

Follow these rules:

- Treat this handoff as the active directive.
- Treat any older Fedora-local plan as evidence only.
- Do not execute setup phases from older plans without new explicit approval.
- Preserve the local fact that human/kid WARP policy must resolve to
  `identity.email`; do not substitute headless/service-token enrollment for
  human laptop users.
- Treat Jefahnierocks as the device owner/administrator.
- Treat `verlyn13` as the only intended mission-critical admin/service owner.
  Other accounts, including `wyn`, may remain usable for exploration but should
  not retain sudo, Docker, or service-management authority without explicit
  approval.
- Treat laptop-hosted Infisical as not needed. The current Infisical authority
  is the Hetzner server only.
- Return redacted evidence and recommended next steps to the Jefahnierocks
  `system-config` operator.

## Hard Stops

Stop and ask before any of these:

- Creating, editing, reading broadly, or reorganizing 1Password items.
- Printing passwords, private keys, recovery keys, bearer tokens, tunnel
  credentials, OAuth credentials, shell history, or sensitive environment
  variables.
- Changing users, groups, sudoers, passwords, or PAM.
- Changing SSH daemon configuration or disabling password SSH.
- Installing, removing, enabling, or enrolling WARP, `cloudflared`, Tailscale,
  Cockpit, or other management agents.
- Changing Cloudflare Tunnel, Access, Gateway, WARP, DNS, or device profile
  state.
- Changing OPNsense, DHCP, DNS, router, or firewall state.
- Creating static IP, static DHCP, or DNS records.
- Changing `firewalld` policy or Docker port bindings.
- Changing power, sleep, LUKS, TPM, Secure Boot, AMT/vPro, or firmware state.
- Running destructive cleanup commands.

## Allowed Prep Work

You may perform read-only inventory and produce a non-secret report. If you
need to save a local artifact, use a user-local path such as:

```text
/home/verlyn13/device-admin-prep/
```

Do not include raw logs that contain secrets. Prefer short command summaries
and redacted outputs.

## Allowed SSH Foothold Work

Do this only when the human explicitly says this is the SSH foothold phase.

Goal: prove MacBook-to-Fedora SSH as `verlyn13` over the trusted LAN. Do not
try to finish all hardening locally.

Allowed changes:

- Create `/home/verlyn13/.ssh/` if it is missing.
- Install one human-approved public key for `verlyn13` in
  `/home/verlyn13/.ssh/authorized_keys`.
- Correct ownership and permissions on `/home/verlyn13/.ssh` and
  `authorized_keys`.
- Run `restorecon` on `/home/verlyn13/.ssh` if SELinux tooling is available.
- Start `sshd` only if it is installed but not running and the human approves
  that start in the local session.

Still not allowed in this foothold phase:

- Do not disable password SSH yet.
- Do not remove `wyn`, `axel`, `ila`, or `mesh-ops` from groups yet.
- Do not edit `/etc/ssh/sshd_config` or files under `/etc/ssh/sshd_config.d/`.
- Do not change `firewalld` unless SSH is blocked and the human approves a
  LAN-only temporary allow rule.
- Do not install WARP, `cloudflared`, Cockpit, Tailscale enrollment, or any
  management agent.
- Do not stop Infisical, Redis, Docker, or user services yet.

Safe key install pattern, using only a public key, if the local session is
already running as `verlyn13`:

```bash
APPROVED_PUBLIC_KEY='<paste one approved public key line here>'

install -d -m 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
grep -qxF "$APPROVED_PUBLIC_KEY" "$HOME/.ssh/authorized_keys" ||
  printf '%s\n' "$APPROVED_PUBLIC_KEY" >> "$HOME/.ssh/authorized_keys"
command -v restorecon >/dev/null 2>&1 &&
  restorecon -Rv "$HOME/.ssh"
```

If the local session is not `verlyn13`, ask the human before using `sudo`, then
write only to `/home/verlyn13/.ssh/authorized_keys` and set owner
`verlyn13:verlyn13`, directory mode `700`, file mode `600`.

Do not paste a private key. If the approved public key is not available,
report that as blocked instead of generating or guessing one.

MacBook-side smoke test to request from the operator:

```bash
nc -vz -G 3 <fedora-lan-ip> 22
ssh verlyn13@<fedora-lan-ip> 'hostname; whoami; id; sudo -n true || echo sudo-needs-human'
```

Keep password SSH enabled until this test succeeds with public-key auth and a
local fallback path is still available.

## Read-Only Checks

Run these from a normal shell. If a command requires sudo, first try the
read-only non-sudo equivalent. If sudo is required, ask the human before using
it and do not expose passwords.

```bash
# Identity and OS
hostnamectl
cat /etc/fedora-release
uname -a
timedatectl

# Users, groups, and sudo posture
getent passwd verlyn13 wyn axel ila mesh-ops
id verlyn13
id wyn
id axel
id ila
id mesh-ops
getent group wheel docker
sudo -l -U wyn
sudo -l -U verlyn13

# Network
ip -brief addr
ip route
resolvectl status
nmcli -t -f NAME,TYPE,DEVICE,STATE connection show --active

# Listening services and firewall
ss -tulpn
systemctl is-active firewalld
firewall-cmd --get-active-zones
firewall-cmd --list-all
systemctl status sshd --no-pager
sshd -T | grep -E 'passwordauthentication|kbdinteractiveauthentication|permitrootlogin|allowusers|x11forwarding|allowagentforwarding|allowtcpforwarding'

# Cloudflare and Tailscale binaries/services
command -v warp-cli || true
command -v cloudflared || true
command -v tailscale || true
systemctl status warp-svc --no-pager 2>/dev/null || true
systemctl status cloudflared --no-pager 2>/dev/null || true
systemctl status tailscaled --no-pager 2>/dev/null || true
tailscale status 2>/dev/null || true
tailscale ip -4 2>/dev/null || true

# Disk encryption and boot posture; do not print passphrases or recovery keys
lsblk -f
findmnt /
systemd-cryptenroll --dump /dev/nvme0n1p3 2>/dev/null || true
bootctl status 2>/dev/null || true

# Power and availability
upower -d
systemctl status sleep.target suspend.target hibernate.target hybrid-sleep.target --no-pager
loginctl show-user "$(id -un)" -p Linger
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null || true
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 2>/dev/null || true

# Package/update posture
dnf repolist --enabled
dnf check-update --refresh

# Docker/local admin surfaces
systemctl status docker --no-pager 2>/dev/null || true
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' 2>/dev/null || true
ss -tulpn | grep -E ':22|:6379|:18080|:9090|:41641' || true

# Service ownership review
systemctl list-units --type=service --state=running --no-pager
ps -eo user,pid,comm,args --sort=user |
  grep -E 'redis|infisical|docker|podman|node|python|systemd' |
  grep -v grep || true
```

## Expected Findings To Reconcile

Confirm whether these are still true:

- Hostname is `fedora-top`.
- OS is Fedora Linux 44 Workstation.
- Jefahnierocks owns administration of the laptop.
- `verlyn13` remains a working local admin and is the only intended
  mission-critical service owner.
- `wyn` is still in `wheel` and has an explicit sudoers grant, or report if
  that has already changed.
- `axel`, `ila`, `mesh-ops`, and any other non-`verlyn13` account should not
  retain sudo, Docker, or mission-critical service authority without explicit
  justification.
- SSH is active, listening broadly, and permits password authentication.
- WARP and `cloudflared` are absent.
- Tailscale is installed but logged out.
- Root/home storage is LUKS2 encrypted.
- Remote reboot is unsafe until a LUKS unlock strategy is chosen and tested.
- `firewalld` uses the permissive FedoraWorkstation posture on Wi-Fi.
- Redis is published on `0.0.0.0:6379` and Infisical on `0.0.0.0:18080`, or
  report if that has changed. Infisical should be retired from this laptop
  because Hetzner is the only needed Infisical location.
- Laptop is on AC power before any remote-administration reliance.

## Evidence Return Format

Return a concise report with these sections:

```text
Device:
Timestamp:
Operator/agent:
Scope:

Verified current state:
- ...

Changed nothing confirmation:
- ...

Findings that differ from Jefahnierocks expectations:
- ...

Remote-admin readiness:
- SSH:
- WARP:
- cloudflared:
- Tailscale:
- Firewall:
- LUKS/reboot:
- Power:
- Docker/admin surfaces:

Approval-needed actions:
- ...

Blocked because sudo/human/provider access is needed:
- ...

Redacted evidence:
- Command/source:
  Observation:
  Redaction note:
```

## Recommended Next Request Back To Jefahnierocks

Ask the Jefahnierocks operator to decide:

- Whether the MacBook-side SSH smoke test succeeded as `verlyn13`.
- Whether to request a HomeNetOps static DHCP/local DNS record now that the
  Wi-Fi MAC and LAN IP are known.
- Whether to proceed with the remote hardening phase from `system-config`.
- Whether Tailscale should be retained as ACL-restricted break-glass or
  removed.
- Which LUKS strategy to use before any unattended reboot is attempted.
- Whether Cockpit is needed behind Cloudflare Access.
- Whether a HomeNetOps-managed static DHCP mapping or local DNS record is
  needed.
- Whether Redis is needed after laptop-hosted Infisical is retired, and whether
  remaining Docker/admin surfaces should be stopped or rebound to localhost.
- Whether to proceed with a privilege/SSH/firewall implementation phase.
