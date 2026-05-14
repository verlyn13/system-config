---
title: Fedora Top Admin-Backup SSH Key Strategy Packet - 2026-05-14
category: operations
component: device_admin
status: applied
version: 0.2.0
last_updated: 2026-05-14
tags: [device-admin, fedora, ssh, admin-backup, 1password, hardening]
priority: high
---

# Fedora Top Admin-Backup SSH Key Strategy Packet - 2026-05-14

`verlyn13` is the sole administrator path on `fedora-top` today, with
a single approved MacBook ED25519 key
(`SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`) in
`/home/verlyn13/.ssh/authorized_keys`. If that MacBook is unavailable
- lost, broken, offline, in transit, or in any state that prevents
using the 1Password SSH agent on it - `verlyn13` loses remote-admin
access to `fedora-top`.

This packet defines the addition of **a second `verlyn13` admin
public key path**, backed by 1Password, so that one independent
device failure does not sever administration. It was applied live on
2026-05-14T02:42:25Z. Redacted apply evidence is recorded in
[fedora-top-admin-backup-ssh-key-strategy-apply-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-apply-2026-05-14.md).

The original text below is preserved for reuse and audit.

## Scope

In scope:

- Add **one additional `verlyn13` public key line** to
  `/home/verlyn13/.ssh/authorized_keys` on `fedora-top`.
- The new key's private half lives only in an approved 1Password
  item (preferred: a 1Password-managed SSH Key item served via the
  1Password SSH agent on a different operator device or in a sealed
  recovery context).
- Verification using the existing primary path (MacBook) and, if a
  second client device is available at apply time, a fresh login
  using the backup path.
- Pre-apply snapshot of `authorized_keys` and the existing sshd
  effective settings; rollback plan that removes the added line
  cleanly.

Out of scope (separate packets):

- Reopening `PasswordAuthentication`. Stays `no`.
- Loosening `AllowUsers verlyn13`. Stays `verlyn13` only.
- Adding any second admin **user** account. Stays `verlyn13` only.
- Reusing the legacy MAMAWORK `DadAdmin_WinNet` key
  (`SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`) as the
  Fedora backup key. That key is legacy / bootstrap context for
  prior Fedora-to-MAMAWORK remote development and is **not** the
  right backup-admin path here. See
  [windows-pc-mamawork.md](./windows-pc-mamawork.md) and
  [handoff-mamawork.md](./handoff-mamawork.md) for the
  classification.
- Tailscale activation, WARP, `cloudflared`, Cloudflare Access, or
  any other off-LAN routing.
- LUKS unlock or remote-reboot strategy. The backup admin key
  helps once the host is up; it does not solve disk-encryption
  recovery.
- The fedora-top known_hosts reconciliation packet
  ([fedora-top-known-hosts-reconciliation-packet-2026-05-13.md](./fedora-top-known-hosts-reconciliation-packet-2026-05-13.md));
  that is a MacBook-side cleanup, independent of this packet.

## Verified Current State

| Field | Value | Source |
|---|---|---|
| `fedora-top` SSH posture | publickey-only; AllowUsers verlyn13; AuthenticationMethods publickey | [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md) |
| `/home/verlyn13/.ssh/authorized_keys` | one key line, fingerprint `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`, mode 0600, owner verlyn13:verlyn13, SELinux context per restorecon | same |
| Listening interface | `0.0.0.0:22` and `[::]:22` (post-firewalld-narrowing baseline) | [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md) |
| MacBook key serving | 1Password SSH agent on the MacBook serves the matching private key for the existing `authorized_keys` entry | [../ssh.md](../ssh.md) |
| Number of admin clients today | one (the MacBook) | this packet |

The single-MacBook dependency is the gap this packet closes.

## Design

| Decision | Choice | Reason |
|---|---|---|
| Add a second admin user? | **No.** Stay `AllowUsers verlyn13`. | One operator-identity, one admin user. Multiple admin users widen the audit and revocation surface. |
| Re-enable password SSH? | **No.** Stay `PasswordAuthentication no`. | Publickey is the policy floor. |
| Add a second public key for `verlyn13`? | **Yes.** | Closes the single-MacBook dependency without expanding identity surface. |
| Where does the private half live? | A 1Password-managed SSH Key item in the approved `Dev` vault on `my.1password.com`, served via the 1Password SSH agent on a backup operator device. Alternative approved storage: a sealed offline backup of the private key kept solely in 1Password. | 1Password SSH agent is the approved workstation human-identity UX per [../ssh.md](../ssh.md). |
| Key algorithm | `ed25519` | Matches `fedora-top`'s host key class and the existing primary admin key; smallest correct key for SSH. |
| Key location on the backup operator device | Public key materialised under `~/.ssh/` only when needed; private key stays in 1Password. | Matches the system-config baseline of public-key `IdentityFile` paths ending in `.pub` for 1Password-backed identities. |
| 1Password item name | `jefahnierocks-device-fedora-top-admin-backup-verlyn13` (proposed; final name comes from a [secret-records](../secret-records.md) entry created by the human) | Keeps naming aligned with the existing `jefahnierocks-device-fedora-top-local-admin` placeholder pattern. |
| `authorized_keys` ordering | Append the new line **after** the existing approved MacBook key. | Avoids reordering or rewriting the existing line; restorecon stays clean. |
| Comment / label on the new key line | `verlyn13@fedora-top-admin-backup`, no PII, no host serial | Future SSH server logs reference the comment for triage. |
| What gets recorded in repo | Public-key fingerprint and 1Password item name only. Never the public key body, never the private key, never the 1Password secret reference URL with field. | Matches the [../secrets.md](../secrets.md) policy. |

## What Approving This Packet Does Not Do

The approved live packet, when later run, **does not**:

- Create or rotate any 1Password item from `system-config` (human
  creates the item; agent reads its public fingerprint for
  recording).
- Touch the existing MacBook key's `authorized_keys` line. The
  existing primary path keeps working unchanged.
- Touch `sshd_config` or `sshd_config.d/`. Effective settings stay
  exactly as recorded in the 2026-05-13 SSH hardening apply.
- Touch the docker zone, firewalld services, ports, or rich rules.
- Touch Tailscale, WARP, `cloudflared`, Cloudflare, DNS, DHCP,
  HomeNetOps, OPNsense, LUKS, power, or reboot state.

## Apply Sequence (proposed; not authorised by this preparation)

Live apply requires its own explicit approval phrase (see "Required
Approval Phrase" below). The apply sequence below is what the
**future** live packet would do. Each step assumes the standard
held-open SSH session pattern from
[fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md).

### 1. Human creates the 1Password backup key item

Out of agent scope. Steps:

1. Human creates a new SSH Key item in `op://Dev/jefahnierocks-device-fedora-top-admin-backup-verlyn13` (or whatever final name the human chooses).
2. 1Password generates the ed25519 keypair locally.
3. Human enables the 1Password SSH agent integration on whatever device will hold the backup path (the approved option is a different operator device than the MacBook).
4. Human captures the **public-key fingerprint** (only) and returns it via the handback so this packet can record it.

### 2. Pre-apply snapshot

```bash
ssh -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  -o ControlMaster=no \
  -o ControlPath=none \
  verlyn13@fedora-top.home.arpa 'sudo -n bash' <<'EOF'
set -euo pipefail
SNAP="/var/backups/jefahnierocks-fedora-top-admin-backup-key-$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 0700 -o root -g root "$SNAP"
install -m 0600 -o root -g root /home/verlyn13/.ssh/authorized_keys "$SNAP/authorized_keys"
awk 'NF && $1 !~ /^#/' /home/verlyn13/.ssh/authorized_keys |
  while IFS= read -r key; do printf '%s\n' "$key" | ssh-keygen -lf -; done \
  > "$SNAP/fingerprints-before.txt"
sshd -T 2>/dev/null | grep -E '^(permitrootlogin|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|authenticationmethods|allowusers|x11forwarding|allowtcpforwarding|allowagentforwarding) ' \
  > "$SNAP/sshd-effective-before.txt"
( cd "$SNAP" && sha256sum -- *.txt authorized_keys > manifest.sha256 )
echo "snapshot_path=$SNAP"
ls -la "$SNAP"
EOF
```

### 3. Append the new public-key line

The agent does **not** read the new public key from any operator-side
file. The human pastes the public-key body into the heredoc when the
live apply runs. This packet shows only the structural shape:

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n bash' <<'EOF'
set -euo pipefail
# NEW_PUBKEY_LINE is the single-line OpenSSH public-key value
# operator-provided at apply time, with the trailing comment
# "verlyn13@fedora-top-admin-backup". The expected fingerprint
# FP is operator-provided too (see step 1).
NEW_PUBKEY_LINE='<operator-supplied; full ed25519 public-key line>'
EXPECTED_FP='<operator-supplied; SHA256:... ED25519 fingerprint>'

AK=/home/verlyn13/.ssh/authorized_keys
TMP="$(mktemp -p /root authorized_keys.new.XXXXXX)"
trap 'rm -f "$TMP"' EXIT
install -m 0600 -o root -g root "$AK" "$TMP"

# Verify the line is well-formed and matches the expected fingerprint
# before mutating the live file.
line_fp="$(printf '%s\n' "$NEW_PUBKEY_LINE" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}')"
[ "$line_fp" = "$EXPECTED_FP" ] || { echo "FAIL: pubkey line fingerprint mismatch ($line_fp != $EXPECTED_FP)"; exit 1; }

# Refuse to add a duplicate.
if printf '%s\n' "$NEW_PUBKEY_LINE" | grep -Fxqf - "$TMP"; then
  echo "FAIL: identical public-key line already present in authorized_keys"
  exit 1
fi

# Append.
printf '%s\n' "$NEW_PUBKEY_LINE" >> "$TMP"

# Restore final ownership/mode and SELinux context.
install -m 0600 -o verlyn13 -g verlyn13 "$TMP" "$AK"
command -v restorecon >/dev/null 2>&1 && restorecon -Rv /home/verlyn13/.ssh >/dev/null

echo "--- post-append fingerprints ---"
awk 'NF && $1 !~ /^#/' "$AK" |
  while IFS= read -r k; do printf '%s\n' "$k" | ssh-keygen -lf -; done
EOF
```

### 4. Validate

Two checks. Both must pass.

#### Primary path (existing MacBook key) still works

```bash
ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  -o ControlMaster=no \
  -o ControlPath=none \
  verlyn13@fedora-top.home.arpa 'hostname; whoami'
# Expected: fedora-top / verlyn13
```

#### Backup path works (if a second client device is available at apply time)

Run from the backup operator device using its 1Password SSH agent +
the new public-key file:

```bash
ssh \
  -i "$HOME/.ssh/<backup-public-key-file>.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  -o ControlMaster=no \
  -o ControlPath=none \
  verlyn13@fedora-top.home.arpa 'hostname; whoami'
# Expected: fedora-top / verlyn13
```

If the backup device is not present at apply time, defer this
verification but capture the fingerprint in the apply record so a
future verification packet can run it.

#### sshd effective settings unchanged

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n sshd -T 2>/dev/null | grep -E "^(permitrootlogin|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|authenticationmethods|allowusers|x11forwarding|allowtcpforwarding|allowagentforwarding) "'
```

Must match the snapshot taken in step 2 exactly. Hardening posture
does not change.

### 5. Rollback

If either MacBook verification fails or the backup verification
fails in a way that suggests the new line is wrong:

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n bash' <<'EOF'
set -euo pipefail
AK=/home/verlyn13/.ssh/authorized_keys
SNAP="<snapshot-path>"
install -m 0600 -o verlyn13 -g verlyn13 "$SNAP/authorized_keys" "$AK"
command -v restorecon >/dev/null 2>&1 && restorecon -Rv /home/verlyn13/.ssh >/dev/null
awk 'NF && $1 !~ /^#/' "$AK" |
  while IFS= read -r k; do printf '%s\n' "$k" | ssh-keygen -lf -; done
EOF
```

Then re-run the primary-path validation. The MacBook should still
authenticate.

## Required Approval Phrase

Live apply requires guardian approval substantially equivalent to:

```text
I approve applying the Fedora Top admin-backup SSH key strategy
packet live now. Append one additional verlyn13 public key line to
/home/verlyn13/.ssh/authorized_keys on fedora-top, with the
operator-supplied public-key body and expected fingerprint, comment
"verlyn13@fedora-top-admin-backup", after a pre-apply snapshot to
/var/backups/jefahnierocks-fedora-top-admin-backup-key-<timestamp>.
Refuse to append if the line's fingerprint does not match the
operator-supplied expected fingerprint, or if a duplicate line is
already present. Verify the existing MacBook primary path still
works, the backup path works if a second client device is
available, and sshd effective settings (PermitRootLogin no,
PubkeyAuthentication yes, PasswordAuthentication no,
KbdInteractiveAuthentication no, AuthenticationMethods publickey,
AllowUsers verlyn13, X11Forwarding no, AllowTcpForwarding no,
AllowAgentForwarding no) are unchanged. Roll back from the snapshot
if any verification fails. Do not touch sshd config or drop-ins,
docker zone, firewalld services/ports/rich-rules, sudoers,
users/groups, Tailscale, WARP, cloudflared, Cloudflare, OPNsense,
DNS, DHCP, LUKS, TPM, firmware, power, reboot, or any 1Password
item from the system-config side. Do not reuse the MAMAWORK
DadAdmin_WinNet key. Do not add any other admin user.
```

## Evidence Template

```text
timestamp:
operator:
held-open session used:
snapshot path:
existing authorized_keys fingerprint(s) before:
expected new fingerprint (operator-supplied):
appended: yes/no
new authorized_keys fingerprint(s) after (must include both):
sshd -T effective settings (must match snapshot):
primary path verification (MacBook):
backup path verification (or DEFERRED if no second device):
rollback used: yes/no
remaining blockers:
```

Do not paste private keys, agent socket paths, full public-key
bodies (the public key value is recordable but the apply record can
satisfy with fingerprint + 1Password item name), 1Password item
IDs, item UUIDs, secret-reference URIs, or shell history.

## Related

- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-known-hosts-reconciliation-packet-2026-05-13.md](./fedora-top-known-hosts-reconciliation-packet-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [windows-pc-mamawork.md](./windows-pc-mamawork.md) and
  [handoff-mamawork.md](./handoff-mamawork.md) - DadAdmin_WinNet
  classification note (legacy/bootstrap, NOT the Fedora backup key).
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
