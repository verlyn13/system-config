---
title: Fedora Top Complete Administration Instructions
category: operations
component: device_admin
status: prehardening-report-ingested
version: 0.4.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, hardening, handoff]
priority: high
---

# Fedora Top Complete Administration Instructions

These instructions are for the Fedora 44 laptop currently identified as
`fedora-top`.

The primary MacBook can now SSH into the Fedora laptop as `verlyn13` over the
trusted home LAN. The next work is packetized remote hardening from
`system-config`, not a broad local one-shot change.

## Authority

Use this document as the active Fedora machine instruction set.

Local authority and boundaries:

- Jefahnierocks owns administration of this laptop.
- `system-config` owns the device administration record and workstation SSH
  posture.
- HomeNetOps owns OPNsense, DHCP, DNS, router, and LAN placement changes.
- `cloudflare-dns` owns Cloudflare Zero Trust, WARP, Gateway, and device
  enrollment semantics.
- Downloaded Fedora-local reports are factual inputs, not policy authority.

Current administrative intent:

- `verlyn13` is the only intended mission-critical admin and service owner.
- `wyn` and other exploratory users may remain usable, but should not retain
  sudo, Docker, broad service control, or ownership of critical services
  unless explicitly justified.
- Laptop-hosted Infisical is not needed. Infisical should live on the Hetzner
  server only.
- Off-LAN remote administration is future work. Do not expose SSH, Cockpit,
  VNC, RDP, WinRM, or any admin service to public WAN.

## Stop Rules

Stop and ask before doing any of the following:

- Creating, editing, reading broadly, or reorganizing 1Password items.
- Printing passwords, recovery keys, private keys, bearer tokens, OAuth tokens,
  Tailscale authentication links, Cloudflare tunnel credentials, or shell
  history.
- Disabling password SSH.
- Editing `/etc/ssh/sshd_config` or files under `/etc/ssh/sshd_config.d/`.
- Changing `firewalld` policy, Docker port bindings, users, groups, sudoers,
  PAM, LUKS, TPM, Secure Boot, firmware, sleep, or power settings.
- Installing or enrolling WARP, `cloudflared`, Tailscale, Cockpit, or another
  management agent.
- Changing Cloudflare, OPNsense, DHCP, DNS, static mappings, firewall rules,
  Access apps, Gateway policies, or WARP profiles.
- Rebooting the laptop remotely.
- Claiming the laptop is fully managed before the verified checklist says so.

Exception for this first slice:

- The Fedora-side operator may install one approved public SSH key for
  `verlyn13` and correct ownership/permissions on
  `/home/verlyn13/.ssh/authorized_keys`.
- If `sshd` is installed but stopped, the Fedora-side operator may start it
  only after the human confirms this is the SSH foothold phase.

## Current Known State

This state includes the Phase 1 Fedora-side report, MacBook-side smoke test,
remote baseline, and Fedora-side pre-hardening detail report from 2026-05-13:

| Item | Current known state |
|---|---|
| Hostname | `fedora-top` |
| OS | Fedora Linux 44 Workstation |
| Kernel | `7.0.4-200.fc44.x86_64` |
| Wi-Fi MAC | `66:B5:8C:F5:45:74` |
| Current LAN IP | `192.168.0.206/24` on Wi-Fi |
| Static IP | Not assigned yet |
| SSH | Enabled, active, listening broadly on IPv4/IPv6, not hardened |
| MacBook TCP reachability | TCP `22` reachable from MacBook |
| MacBook SSH login | Verified as `verlyn13` using the selected 1Password-backed key |
| `verlyn13` sudo | `sudo -n true` succeeded during smoke test |
| Effective SSH policy | `PasswordAuthentication yes`, `AllowAgentForwarding yes`, `AllowTcpForwarding yes`, `X11Forwarding yes`, no `AllowUsers`; hardening pending |
| Authorized keys | Three ED25519 public keys present; only the MacBook key fingerprint `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8` is approved for this slice |
| Firewall | `FedoraWorkstation` zone permits broad high TCP/UDP ports plus `ssh`, `mdns`, `samba-client`, and `dhcpv6-client`; Docker zone target is `ACCEPT` |
| WARP | Absent |
| `cloudflared` | Absent |
| Tailscale | Installed and active but logged out |
| Disk encryption | LUKS2 root/home; no remote reboot until unlock strategy is chosen |
| Power | AC connected in Phase 1; battery `80%`, `pending-charge` |
| Containers | Docker project `happy-secrets` exposes Infisical on `18080` and Redis on `6379` on all IPv4/IPv6 interfaces |
| Sudoers | `50-mesh-ops` wrong mode, duplicate `wyn` grant, `verlyn13` `NOPASSWD: ALL`, and broad `mesh-ops` `NOPASSWD` wildcards |
| DNF repo trust | Tailscale and Infisical repo signing-key failures observed; no keys accepted |

Phase status:

- Phase 1 Fedora-side checks are complete.
- `/home/verlyn13/.ssh` and `authorized_keys` have correct ownership and
  permissions.
- The approved MacBook public key was installed for `verlyn13`.
- MacBook-side `nc` to `192.168.0.206:22` succeeds.
- MacBook-side SSH public-key login succeeds.
- Remote baseline confirms SSH, firewall, user privileges, and container
  exposure still need hardening.
- Fedora-side pre-hardening detail report is complete at
  `/home/verlyn13/device-admin-prep/fedora-top-prehardening-report-2026-05-13.md`.

## Latest Pre-Hardening Findings

The latest report confirms SSH is administrable but still permissive. Do not
disable password SSH, reload `sshd`, alter firewall policy, remove keys, edit
sudoers, stop containers, import DNF signing keys, enroll Tailscale, or change
power/LUKS settings without an explicit packet approval.

Decisions needed before implementation:

- Retain, rotate, or remove the `ansible@hetzner.hq` and
  `verlyn13@wsl-fedora42-to-thinkpad-t440s` public keys from
  `verlyn13` `authorized_keys`.
- Decide whether `mesh-ops` remains required after Infisical is retired from
  the laptop.
- Decide whether Tailscale should become ACL-restricted break-glass, be
  removed, or stay installed but logged out for now.
- Decide whether to remove Infisical repos with the service retirement and
  whether to repair Tailscale repo trust only if Tailscale remains in scope.

## Phase 1 - Fedora-Side SSH Foothold

Run this phase on the Fedora laptop with the human present.

Do not do full hardening here. Do only enough to let the MacBook SSH in as
`verlyn13`.

### 1. Connect Power

Connect AC power before relying on the laptop remotely.

Record:

```bash
upower -d | grep -E 'state:|percentage:|time to empty|time to full' || true
```

### 2. Confirm Identity And Network

Run:

```bash
hostnamectl
cat /etc/fedora-release
uname -r
ip -brief addr
ip route
nmcli -t -f NAME,TYPE,DEVICE,STATE connection show --active
nmcli -t -f GENERAL.DEVICE,GENERAL.HWADDR device show
```

Return only non-secret facts:

- Hostname.
- Fedora version.
- Active interface name.
- Current IPv4 LAN address.
- Wi-Fi MAC address.
- Whether AC power is connected.

### 3. Check SSH And Firewall State

Run:

```bash
systemctl is-enabled sshd 2>/dev/null || true
systemctl is-active sshd 2>/dev/null || true
ss -tulpn | grep -E '(^|:)(22)[[:space:]]' || true
firewall-cmd --state 2>/dev/null || true
firewall-cmd --get-active-zones 2>/dev/null || true
firewall-cmd --list-all 2>/dev/null || true
```

If `sshd` is active and TCP `22` is listening, do not change the SSH daemon.

If `sshd` is installed but inactive, ask the human before running:

```bash
sudo systemctl start sshd
```

Do not change firewall policy unless the MacBook cannot reach TCP `22` and
the human approves a narrow temporary LAN allow rule.

### 4. Install The Approved Public Key

Use only an approved public key line. Do not paste a private key.

If the local Fedora session is already `verlyn13`, run:

```bash
APPROVED_PUBLIC_KEY='<paste-one-approved-public-key-line-here>'

install -d -m 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
grep -qxF "$APPROVED_PUBLIC_KEY" "$HOME/.ssh/authorized_keys" ||
  printf '%s\n' "$APPROVED_PUBLIC_KEY" >> "$HOME/.ssh/authorized_keys"
command -v restorecon >/dev/null 2>&1 &&
  restorecon -Rv "$HOME/.ssh"
```

If the local Fedora session is not `verlyn13`, ask the human before using
`sudo`, then run:

```bash
APPROVED_PUBLIC_KEY='<paste-one-approved-public-key-line-here>'

sudo install -d -m 700 -o verlyn13 -g verlyn13 /home/verlyn13/.ssh
sudo touch /home/verlyn13/.ssh/authorized_keys
sudo chown verlyn13:verlyn13 /home/verlyn13/.ssh/authorized_keys
sudo chmod 600 /home/verlyn13/.ssh/authorized_keys
sudo grep -qxF "$APPROVED_PUBLIC_KEY" /home/verlyn13/.ssh/authorized_keys ||
  printf '%s\n' "$APPROVED_PUBLIC_KEY" |
    sudo tee -a /home/verlyn13/.ssh/authorized_keys >/dev/null
command -v restorecon >/dev/null 2>&1 &&
  sudo restorecon -Rv /home/verlyn13/.ssh
```

Do not generate a new private key on the Fedora laptop for this step. The
approved key should come from the MacBook/human side.

### 5. Return Foothold Evidence

Return this exact summary shape to the `system-config` operator:

```text
Device:
Timestamp:
Local operator:
Hostname:
Fedora version:
LAN IP:
Wi-Fi MAC:
AC power:
sshd state:
TCP 22 listener:
firewalld active zone:
authorized_keys state for verlyn13:
Changes made:
Blocked items:
Redaction note:
```

Do not include the full raw `authorized_keys` file. If you need to prove key
presence, say `approved public key present` and provide the public key comment
or a short fingerprint if available.

## Phase 2 - MacBook SSH Smoke Test

Run this from the MacBook after Phase 1.

Replace `<fedora-lan-ip>` with the current Fedora LAN address.

```bash
nc -vz -G 3 <fedora-lan-ip> 22
ssh verlyn13@<fedora-lan-ip> 'hostname; whoami; id; sudo -n true || echo sudo-needs-human'
```

Expected result:

- `nc` reports TCP `22` reachable.
- `ssh` logs in as `verlyn13`.
- `hostname` returns `fedora-top` or the current hostname if it differs.
- `whoami` returns `verlyn13`.
- `sudo -n true` either succeeds or prints `sudo-needs-human`. Either is
  acceptable for the foothold; do not force passwordless sudo.

If SSH fails:

1. Do not disable password SSH.
2. Recheck the LAN IP.
3. Recheck `sshd` state.
4. Recheck authorized key permissions.
5. Recheck whether the MacBook is offering the expected 1Password-backed SSH
   key.

Useful MacBook diagnostics:

```bash
ssh -vvv verlyn13@<fedora-lan-ip> 'true'
ssh-add -L
ssh -G <fedora-lan-ip> | rg '^(identityagent|identityfile|identitiesonly|preferredauthentications) '
```

Do not paste private key material into chat, files, or shell history.

## Phase 3 - Remote Read-Only Baseline

After SSH succeeds, collect a remote baseline from the MacBook before making
hardening changes.

```bash
ssh verlyn13@<fedora-lan-ip> '
set -u
hostnamectl
cat /etc/fedora-release
uname -a
ip -brief addr
ip route
nmcli -t -f NAME,TYPE,DEVICE,STATE connection show --active
systemctl is-active sshd firewalld docker 2>/dev/null || true
ss -tulpn
firewall-cmd --get-active-zones 2>/dev/null || true
firewall-cmd --list-all 2>/dev/null || true
getent group wheel docker
id verlyn13
id wyn 2>/dev/null || true
id axel 2>/dev/null || true
id ila 2>/dev/null || true
id mesh-ops 2>/dev/null || true
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" 2>/dev/null || true
lsblk -f
'
```

Redact before copying into repo docs:

- Serial numbers.
- Full disk UUIDs.
- Login URLs.
- Any token, private key, recovery key, or password material.
- Shell history.

## Phase 4 - Remote Hardening Sequence

Do not run this phase until Phase 2 succeeds.

Each step below should be done as a separate change with a rollback path and
evidence. Do not combine everything into one remote shell session.

### 4.1 SSH Hardening

Preconditions:

- A public-key SSH login from the MacBook to `verlyn13` works.
- A second SSH session can be opened before closing the first.
- The human has a local console fallback.
- The two non-approved existing public keys have an explicit disposition.

Recommended target drop-in:

```text
/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf
```

Candidate contents:

```text
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
AllowUsers verlyn13
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
```

Apply only after explicit approval:

```bash
sudo install -m 600 /dev/null /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf
sudo tee /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf >/dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
AllowUsers verlyn13
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
EOF
sudo sshd -t
sudo systemctl reload sshd
```

Immediately verify from a second MacBook terminal:

```bash
ssh verlyn13@<fedora-lan-ip> 'hostname; whoami'
```

Rollback if needed:

```bash
sudo rm -f /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf
sudo sshd -t
sudo systemctl reload sshd
```

### 4.2 Firewall Narrowing

Preconditions:

- SSH hardening is verified.
- A second SSH session can be opened.
- Current interface and zone are known.

Preferred target:

- SSH allowed from trusted LAN `192.168.0.0/24`.
- No broad high-port `FedoraWorkstation` exposure for remote administration.
- No public WAN path.

Use runtime rules first, verify a second SSH session, then make permanent.
Exact commands depend on the active interface and zone returned by
`firewall-cmd --get-active-zones`. Do not guess.

Candidate pattern after identifying the active Wi-Fi connection:

```bash
ACTIVE_CONNECTION='<nmcli-connection-name>'

sudo firewall-cmd --permanent --new-zone=jefahnierocks-admin 2>/dev/null || true
sudo firewall-cmd --permanent --zone=jefahnierocks-admin --set-target=DROP
sudo firewall-cmd --permanent --zone=jefahnierocks-admin \
  --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" service name="ssh" accept'
sudo nmcli connection modify "$ACTIVE_CONNECTION" connection.zone jefahnierocks-admin
sudo firewall-cmd --reload
firewall-cmd --get-active-zones
firewall-cmd --zone=jefahnierocks-admin --list-all
```

Verify before closing the current SSH session:

```bash
nc -vz -G 3 <fedora-lan-ip> 22
ssh verlyn13@<fedora-lan-ip> 'hostname; whoami'
```

### 4.3 Privilege Cleanup

Goal:

- `verlyn13` remains the only mission-critical admin/service owner.
- Exploratory users remain usable but lose sudo, Docker, and service-control
  authority unless explicitly justified.
- `mesh-ops` is retained only if it has a current documented purpose after
  Infisical is retired from this laptop.

Read-only precheck:

```bash
getent group wheel docker
for user in wyn axel ila mesh-ops; do id "$user" 2>/dev/null || true; done
sudo grep -RInE 'wyn|axel|ila|mesh-ops' /etc/sudoers /etc/sudoers.d 2>/dev/null || true
sudo -l -U wyn 2>/dev/null || true
sudo -l -U axel 2>/dev/null || true
sudo -l -U ila 2>/dev/null || true
sudo -l -U mesh-ops 2>/dev/null || true
```

After explicit approval, remove non-admin users from elevated groups:

```bash
for user in wyn axel ila mesh-ops; do
  sudo gpasswd -d "$user" wheel 2>/dev/null || true
  sudo gpasswd -d "$user" docker 2>/dev/null || true
done
```

Sudoers cleanup should be done only after reading the exact files. Do not
delete sudoers files by pattern without reviewing them. Always validate:

```bash
sudo visudo -c
```

### 4.4 Infisical, Redis, And Docker Surfaces

Goal:

- Infisical should not run on this laptop.
- Redis and admin surfaces should not listen on all LAN interfaces unless
  explicitly needed.

Read-only precheck:

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' 2>/dev/null || true
ss -tulpn | grep -E ':6379|:18080|:9090|:3000|:8000' || true
docker inspect --format '{{.Name}} {{ index .Config.Labels "com.docker.compose.project.working_dir"}}' \
  $(docker ps -q) 2>/dev/null || true
```

After explicit approval, stop or rebind services from their compose owner.
Do not remove volumes until backup/recovery expectations are clear.

### 4.5 Updates And Repository GPG Prompts

Read-only precheck:

```bash
dnf repolist --enabled
dnf check-update --refresh
```

If prompts appear for Infisical or Tailscale repository keys:

- Do not accept automatically.
- If Infisical is being retired from the laptop, disable/remove that repo
  instead of accepting its key by default.
- If Tailscale is retained as break-glass, accept or refresh its repo key only
  after confirming the official Fedora install path.

### 4.6 Power And LUKS

Target:

- AC connected.
- No sleep on AC while the laptop is expected to be remotely administered.
- No remote reboot until LUKS unlock strategy is chosen and tested.

Read-only precheck:

```bash
upower -d
systemctl status sleep.target suspend.target hibernate.target hybrid-sleep.target --no-pager
findmnt /
lsblk -f
bootctl status 2>/dev/null || true
```

Do not reboot remotely. Decide separately between:

- No unattended reboot.
- Human local unlock only.
- TPM2 unlock.
- FIDO2 unlock.
- initramfs SSH unlock.

## Phase 5 - HomeNetOps Static DHCP And Local DNS

After the Wi-Fi MAC is confirmed, request a HomeNetOps change if we want a
stable LAN identity.

Recommended handoff shape:

```text
device: fedora-top
owner: Jefahnierocks
os: Fedora Linux 44 Workstation
interface: Wi-Fi
mac_wifi: <confirmed-wifi-mac>
current_ip: <observed-current-lan-ip>
requested_hostname: fedora-top
requested_fqdn: fedora-top.home.arpa
requested_ip: <either retain-current-ip or HomeNetOps-selected>
purpose: remote SSH administration over trusted LAN/private overlay
notes: no WAN exposure; no public DNS; no Cloudflare/WARP change in this request
```

Do not create the static mapping from `system-config`. HomeNetOps owns that
surface.

## Phase 6 - Future Off-LAN Access

Do not start this until LAN SSH and local hardening are working.

Preferred future path:

- Cloudflare WARP enrollment for human users through browser/manual OAuth so
  `identity.email` policy matching works.
- Cloudflare private routing or Access-protected admin path only after
  `cloudflare-dns` confirms policy shape.
- Cockpit only if useful, and only behind Cloudflare Access or an equivalent
  private path.
- Tailscale only as ACL-restricted break-glass, if retained.

Do not use headless WARP MDM enrollment for this human-operated laptop unless
the policy intent changes.

## Final Readiness Checklist

The Fedora laptop is only ready for routine remote administration when all of
these are true:

- MacBook can SSH in as `verlyn13` using public-key auth.
- Password SSH is disabled after key auth is proven.
- SSH is limited to `verlyn13`.
- SSH is reachable only over trusted LAN/private overlay.
- `firewalld` no longer exposes broad workstation ports.
- `verlyn13` is the only mission-critical admin/service owner.
- Exploratory users are usable but not in `wheel`, `docker`, or sudoers unless
  explicitly justified.
- Infisical is not running on the laptop.
- Redis/admin surfaces are stopped or bound safely.
- AC/no-sleep posture is deliberate.
- LUKS remote reboot risk is documented and accepted or solved.
- HomeNetOps static DHCP/local DNS is complete if stable LAN naming is needed.
- WARP/Cloudflare/Tailscale state is recorded as verified, planned, or absent.

Until then, call the laptop partially onboarded only.

## Evidence Return Format

Use this format after each phase:

```text
Device:
Timestamp:
Phase:
Operator/agent:

Verified:
- ...

Changed:
- ...

Not changed:
- ...

Blocked:
- ...

Approval needed:
- ...

Repo-safe evidence:
- Command/source:
  Observation:
  Redaction:
```

Never include raw logs containing secrets, shell history, private keys,
passwords, recovery keys, tokens, login URLs, or session cookies.
