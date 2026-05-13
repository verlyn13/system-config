---
title: Fedora Top SSH Hardening Packet - 2026-05-13
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, hardening, authorized-keys]
priority: high
---

# Fedora Top SSH Hardening Packet - 2026-05-13

This packet prepares the live SSH hardening change for `fedora-top`.

No SSH daemon reload, SSH configuration change, or `authorized_keys` edit was
performed while preparing this document. This is the approval-ready packet for
the next live step.

## Scope

In scope:

- `fedora-top` SSH daemon hardening only.
- `verlyn13` `authorized_keys` cleanup only.
- MacBook-to-Fedora validation over the trusted LAN.
- Redacted evidence capture into `system-config`.

Out of scope:

- `firewalld`
- sudoers, users, groups, or Docker membership
- Docker, Infisical, Redis, or compose files
- Tailscale, WARP, `cloudflared`, Cloudflare, DNS, DHCP, or OPNsense
- LUKS, TPM, Secure Boot, firmware, power, or reboot behavior
- 1Password item creation or secret value changes

## Current Live Read-Only Verification

Observed from the MacBook over `fedora-top.home.arpa` on
`2026-05-13T12:00:37-08:00`.

Direct SSH to `fedora-top.home.arpa` failed host-key verification because the
stable FQDN is not yet present in the MacBook `known_hosts` trust state. The
read-only verification used `HostKeyAlias=192.168.0.206`, reusing the already
known IP host key without modifying local SSH trust files.

MacBook client host-key check:

```text
ssh-keygen -F fedora-top.home.arpa -> no entry
ssh-keygen -F 192.168.0.206 -l -> ED25519 SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w
```

Live facts:

```text
hostname=fedora-top
whoami=verlyn13
sudo_noninteractive=ok
sshd_active=active
sshd_enabled=enabled
sshd_test=ok
```

Effective SSH settings:

```text
permitrootlogin prohibit-password
pubkeyauthentication yes
passwordauthentication yes
kbdinteractiveauthentication no
x11forwarding yes
allowtcpforwarding yes
allowagentforwarding yes
authorizedkeysfile .ssh/authorized_keys
authenticationmethods any
permitopen any
```

Config include order:

```text
/etc/ssh/sshd_config:15:Include /etc/ssh/sshd_config.d/*.conf
/etc/ssh/sshd_config:49:AuthorizedKeysFile .ssh/authorized_keys
/etc/ssh/sshd_config.d/40-redhat-crypto-policies.conf
/etc/ssh/sshd_config.d/50-redhat.conf:KbdInteractiveAuthentication no
/etc/ssh/sshd_config.d/50-redhat.conf:X11Forwarding yes
```

Use `/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf` so the
Jefahnierocks policy values are included before Fedora's `50-redhat.conf`.

## Authorized Key Disposition

Live `authorized_keys` fingerprint check found four active key lines:

```text
SHA256:xHbcJoWrOxffuoiu+jS+8i9rUovVeUFeO6Y9A5WMpS4 verlyn13@wsl-fedora42-to-thinkpad-t440s
SHA256:V3oZ/zOfm/IHLHF0i+nT7R6OItQbw/2N2CZq7iS3pNg ansible@hetzner.hq
SHA256:V3oZ/zOfm/IHLHF0i+nT7R6OItQbw/2N2CZq7iS3pNg ansible@hetzner.hq
SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8 no comment
```

Recommended disposition for this packet:

- Retain only the approved MacBook human-interactive key:
  `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`.
- Remove the WSL key from `fedora-top`:
  `SHA256:xHbcJoWrOxffuoiu+jS+8i9rUovVeUFeO6Y9A5WMpS4`.
- Remove both duplicate `ansible@hetzner.hq` entries:
  `SHA256:V3oZ/zOfm/IHLHF0i+nT7R6OItQbw/2N2CZq7iS3pNg`.

Rationale:

- This slice approves the MacBook human-interactive key only.
- Human workstation keys must not become unattended automation identities.
- The `ansible@hetzner.hq` key has no current documented laptop-management
  purpose in this onboarding slice.
- Duplicated key entries are configuration drift.

## Target SSH Policy

Target effective SSH settings after this packet:

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
AllowUsers verlyn13
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
```

This does not claim the host is fully managed. Firewall, sudoers, Docker,
Infisical/Redis, package repo trust, and power/LUKS remain separate packets.

## Preflight

Run from the MacBook before live changes:

```bash
nc -vz -G 3 fedora-top.home.arpa 22

ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  verlyn13@fedora-top.home.arpa \
  'hostname; whoami; sudo -n true && sudo -n sshd -t'
```

Open and keep one live control session before applying changes:

```bash
ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  verlyn13@fedora-top.home.arpa
```

Do not close that session until the post-reload verification succeeds from a
second terminal.

## Apply Authorized Keys Cleanup

Apply only after explicit approval.

This command keeps the approved fingerprint only, writes a timestamped backup
beside the original file, and fails closed if it does not keep exactly one key.

```bash
sudo -n bash <<'EOF'
set -euo pipefail

AUTHORIZED_KEYS=/home/verlyn13/.ssh/authorized_keys
APPROVED_FP=SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8
BACKUP="${AUTHORIZED_KEYS}.pre-jefahnierocks-ssh-hardening-$(date -u +%Y%m%dT%H%M%SZ)"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

cp -a "$AUTHORIZED_KEYS" "$BACKUP"
chmod 600 "$TMP"
chown verlyn13:verlyn13 "$TMP"

while IFS= read -r key; do
  [ -n "$key" ] || continue
  case "$key" in \#*) continue ;; esac
  fp="$(printf '%s\n' "$key" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}')"
  if [ "$fp" = "$APPROVED_FP" ]; then
    printf '%s\n' "$key" >> "$TMP"
  fi
done < "$AUTHORIZED_KEYS"

kept="$(wc -l < "$TMP" | tr -d ' ')"
[ "$kept" = "1" ] || {
  echo "expected exactly one approved key, kept $kept"
  exit 1
}

install -m 600 -o verlyn13 -g verlyn13 "$TMP" "$AUTHORIZED_KEYS"
command -v restorecon >/dev/null 2>&1 &&
  restorecon -Rv /home/verlyn13/.ssh >/dev/null

echo "authorized_keys_backup=$BACKUP"
echo "authorized_keys_kept=$kept"
EOF
```

Verify fingerprints:

```bash
awk 'NF && $1 !~ /^#/ {print}' /home/verlyn13/.ssh/authorized_keys |
  while IFS= read -r key; do
    printf '%s\n' "$key" | ssh-keygen -lf -
  done
```

Expected result: only
`SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`.

## Apply SSHD Drop-In

Apply only after key cleanup succeeds and the held-open session remains active.

```bash
sudo install -m 600 -o root -g root /dev/null \
  /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf

sudo tee /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf >/dev/null <<'EOF'
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
AllowUsers verlyn13
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
EOF

sudo chown root:root /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf
sudo chmod 600 /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf
sudo sshd -t
sudo systemctl reload sshd
```

## Post-Reload Verification

Run from a second MacBook terminal before closing the held-open session:

```bash
ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  verlyn13@fedora-top.home.arpa \
  'hostname; whoami; sudo -n sshd -T | grep -E "^(permitrootlogin|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|authenticationmethods|allowusers|x11forwarding|allowtcpforwarding|allowagentforwarding) "'
```

Expected effective output:

```text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
x11forwarding no
allowtcpforwarding no
allowagentforwarding no
authenticationmethods publickey
allowusers verlyn13
```

Optional negative check:

```bash
ssh \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  -o BatchMode=yes \
  -o HostKeyAlias=192.168.0.206 \
  verlyn13@fedora-top.home.arpa true
```

Expected result: login fails.

## Rollback

Use the held-open session if post-reload verification fails.

Rollback SSH daemon policy:

```bash
sudo rm -f /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf
sudo sshd -t
sudo systemctl reload sshd
```

Rollback `authorized_keys` only if needed, replacing `<backup-path>` with the
backup path printed by the cleanup command:

```bash
sudo install -m 600 -o verlyn13 -g verlyn13 \
  <backup-path> /home/verlyn13/.ssh/authorized_keys
command -v restorecon >/dev/null 2>&1 &&
  sudo restorecon -Rv /home/verlyn13/.ssh
```

Then re-test login from a second terminal before closing the held-open session.

## Evidence To Record After Apply

Capture only redacted/non-secret evidence:

```text
timestamp:
operator:
held-open session used:
authorized_keys backup path:
authorized key fingerprints after cleanup:
drop-in path and mode:
sshd -t result:
systemctl reload sshd result:
post-reload public-key login result:
effective sshd -T settings:
negative password-auth check result:
rollback used: yes/no
remaining blockers:
```

Do not copy private keys, login URLs, passwords, shell history, or raw logs
containing secrets into the repo.
