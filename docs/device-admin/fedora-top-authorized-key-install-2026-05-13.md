---
title: Fedora Top Authorized Key Install Handoff - 2026-05-13
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, authorized-keys, handoff]
priority: high
---

# Fedora Top Authorized Key Install Handoff - 2026-05-13

Use this document for the Fedora-side agent running locally on `fedora-top`.

The purpose is narrow: install one approved MacBook public SSH key for
`verlyn13`, verify that Fedora can see the key, and return enough evidence for
the MacBook-side SSH smoke test to be retried.

Do not use this handoff for broader hardening.

## Current State

Known facts before this handoff:

- Device: `fedora-top`
- OS: Fedora Linux 44 Workstation
- Current LAN IP: `192.168.0.206/24`
- Wi-Fi MAC: `66:B5:8C:F5:45:74`
- `sshd`: enabled, active, listening on TCP `22`
- MacBook TCP reachability to `192.168.0.206:22`: verified
- MacBook SSH login as `verlyn13`: failing
- MacBook debug confirms the correct selected key is being offered
- Fedora currently does not accept that key

Selected MacBook public key fingerprint:

```text
SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8
```

Selected MacBook public key line:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBczPPwNqvFRMogYz0QX3S/e0bXVCIFi81lmaunkDQwX
```

This is a public key, not a private key. Do not request, print, copy, or store
any private key material.

## Hard Stops

Stop and ask before doing any of the following:

- Editing `/etc/ssh/sshd_config` or files under `/etc/ssh/sshd_config.d/`.
- Disabling password SSH.
- Restarting or reloading `sshd`.
- Changing firewall or `firewalld` rules.
- Removing existing entries from `/home/verlyn13/.ssh/authorized_keys`.
- Changing users, groups, sudoers, PAM, Docker, Tailscale, WARP, Cloudflare,
  power, sleep, LUKS, TPM, firmware, OPNsense, DHCP, DNS, or router state.
- Rebooting, shutting down, suspending, or hibernating the laptop.
- Printing full raw `authorized_keys` content in the return report.

Allowed change in this handoff:

- Add the selected public key above to
  `/home/verlyn13/.ssh/authorized_keys` for user `verlyn13`.
- Correct ownership, permissions, and SELinux context for
  `/home/verlyn13/.ssh` and `authorized_keys`.

## Step 1 - Confirm You Are On The Right Machine

Run:

```bash
hostname
cat /etc/fedora-release
ip -brief addr
systemctl is-active sshd
```

Expected:

- Hostname is `fedora-top`.
- Fedora release is Fedora Linux 44 Workstation.
- Wi-Fi has current LAN IP `192.168.0.206/24`, unless DHCP has changed since
  the prior report.
- `sshd` is `active`.

If the hostname is not `fedora-top`, stop.

## Step 2 - Install The Approved Public Key

Run this from the Fedora local session:

```bash
APPROVED_PUBLIC_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBczPPwNqvFRMogYz0QX3S/e0bXVCIFi81lmaunkDQwX'

printf '%s\n' "$APPROVED_PUBLIC_KEY" | ssh-keygen -lf - -E sha256

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

The first `ssh-keygen` line should show:

```text
SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8
```

## Step 3 - Verify Key, Ownership, Permissions, And Context

Run:

```bash
sudo stat -c '%a %U:%G %n' \
  /home/verlyn13 \
  /home/verlyn13/.ssh \
  /home/verlyn13/.ssh/authorized_keys

sudo ssh-keygen -lf /home/verlyn13/.ssh/authorized_keys -E sha256 |
  grep 'SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8'

namei -l /home/verlyn13/.ssh/authorized_keys

if command -v ls >/dev/null 2>&1; then
  ls -Zd /home/verlyn13 /home/verlyn13/.ssh /home/verlyn13/.ssh/authorized_keys 2>/dev/null || true
fi
```

Expected:

- `/home/verlyn13/.ssh` is mode `700`, owner/group `verlyn13:verlyn13`.
- `/home/verlyn13/.ssh/authorized_keys` is mode `600`, owner/group
  `verlyn13:verlyn13`.
- The selected fingerprint is present in `authorized_keys`.
- Parent directories are not group-writable or world-writable in a way that
  would make OpenSSH reject the file.

Do not paste the raw `authorized_keys` file into the return report.

## Step 4 - Wait For The MacBook Retry

After Steps 1-3 are complete, return a short confirmation to the
`system-config` operator and wait for the MacBook-side retry.

The MacBook-side retry command is:

```bash
ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  verlyn13@192.168.0.206
```

The MacBook debug already showed it offers the selected key:

```text
SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8
```

If login succeeds, do not continue to hardening yet. Report success and wait
for the next `system-config` instruction.

## Step 5 - If The MacBook Retry Still Fails

If the MacBook still gets `Permission denied`, do not edit SSH configuration.
Run these read-only checks and return redacted evidence:

```bash
sudo sshd -T | grep -i '^authorizedkeysfile'

sudo journalctl -u sshd -S -15min --no-pager |
  grep -Ei 'verlyn13|authorized|permission|failed|refused|key' || true

sudo stat -c '%a %U:%G %n' \
  /home/verlyn13 \
  /home/verlyn13/.ssh \
  /home/verlyn13/.ssh/authorized_keys

namei -l /home/verlyn13/.ssh/authorized_keys
ls -Zd /home/verlyn13 /home/verlyn13/.ssh /home/verlyn13/.ssh/authorized_keys 2>/dev/null || true

sudo ssh-keygen -lf /home/verlyn13/.ssh/authorized_keys -E sha256 |
  grep 'SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8'
```

If the logs mention `Authentication refused`, `bad ownership`, `bad modes`, or
SELinux denial symptoms, report that exact redacted line. Do not change SSH
daemon config without explicit approval.

## Return Report Format

Return this report shape:

```text
Device:
Timestamp:
Local operator:
Scope:

Confirmed host:
- hostname:
- Fedora version:
- LAN IP:
- sshd state:

Changed:
- Added approved public key fingerprint:
- Corrected /home/verlyn13/.ssh ownership/permissions:
- Ran restorecon:

Verified:
- .ssh mode/owner:
- authorized_keys mode/owner:
- selected fingerprint present:
- SELinux context summary:

Not changed:
- sshd config:
- password SSH:
- firewall:
- users/groups/sudoers:
- Docker/Infisical:
- WARP/Cloudflare/Tailscale:
- reboot/power state:

Blocked or failed:
- ...

Repo-safe evidence:
- Command/source:
  Observation:
  Redaction:
```

Do not include passwords, private keys, full raw `authorized_keys`, shell
history, recovery keys, tokens, login URLs, or session cookies.
