---
title: Fedora Top Admin-Backup SSH Key Strategy Apply - 2026-05-14
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, fedora, ssh, admin-backup, 1password, evidence]
priority: high
---

# Fedora Top Admin-Backup SSH Key Strategy Apply - 2026-05-14

This record captures the live apply of the admin-backup SSH key
strategy packet at
[fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md).

Scope was exactly the prepared default path: append one additional
`verlyn13` ED25519 public-key line to
`/home/verlyn13/.ssh/authorized_keys` on `fedora-top`. No SSH daemon
config, no `sshd_config.d` drop-in, no `firewalld`, no Docker, no
sudoers, no users/groups, no Tailscale, no WARP, no `cloudflared`,
no Cloudflare, no OPNsense, no DNS, no DHCP, no LUKS, no TPM, no
firmware, no power, no reboot, and no 1Password item was touched.

## Approval

Guardian approval matches the packet's "Required Approval Phrase"
section, with operator-provided public-key material:

```text
1Password item:   op://Dev/jefahnierocks-device-fedora-top-admin-backup-verlyn13
Expected fingerprint:
                  SHA256:VUu4nr5J+JjTpwFzRw+l2WQoKbfLhQhXAwGQmdlL6qU
Public-key line:  ssh-ed25519 AAAAC3...D4RZ verlyn13@fedora-top-admin-backup
                  (single OpenSSH line; full body recorded in
                   authorized_keys; not duplicated here)
```

The agent computed the public key's fingerprint locally on the
MacBook and confirmed it matched the operator-supplied expected
value before any remote command was issued.

## Apply Sequence (Actual)

1. **Local pre-flight** at `2026-05-14T02:41:44Z`: piped the
   operator-supplied public-key line through `ssh-keygen -lf -`
   on the MacBook; result
   `256 SHA256:VUu4nr5J+JjTpwFzRw+l2WQoKbfLhQhXAwGQmdlL6qU verlyn13@fedora-top-admin-backup (ED25519)`
   matched the expected fingerprint.
2. **Drift recheck** over SSH at the same timestamp confirmed
   `fedora-top` authorized_keys had exactly one entry
   (`SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`, the
   approved MacBook key) and `sshd -T` effective settings matched
   the 2026-05-13 hardening baseline.
3. **Held-open control SSH session** opened in background with
   `HostKeyAlias=192.168.0.206`, `ServerAliveInterval=30`,
   `ControlMaster=no`, payload `sleep 3600`. Confirmed alive
   before any change.
4. **Pre-apply snapshot** to
   `/var/backups/jefahnierocks-fedora-top-admin-backup-key-20260514T024225Z`
   with `authorized_keys`, `fingerprints-before.txt`,
   `sshd-effective-before.txt`, and `manifest.sha256`.
5. **Append** with fingerprint-match gate: copied
   `authorized_keys` to a `/root`-located tempfile (avoids the
   Fedora 44 `fs.protected_regular` gotcha already documented in
   the SSH hardening apply record), computed the supplied line's
   fingerprint, gated on string equality against the expected
   value, refused duplicate, appended, then
   `install -m 0600 -o verlyn13 -g verlyn13` back over the live
   file. `restorecon -Rv /home/verlyn13/.ssh` ran successfully.
6. **Verify primary path** from a fresh SSH process (no
   `ControlMaster` multiplex) using the existing MacBook key:
   `ssh ... verlyn13@fedora-top.home.arpa 'hostname; whoami;
   echo verlyn13_primary_path_ok'` returned all three values.
7. **Verify sshd effective settings unchanged**: `sudo -n sshd
   -T | grep -E '^(permitrootlogin|pubkeyauthentication|
   passwordauthentication|kbdinteractiveauthentication|
   authenticationmethods|allowusers|x11forwarding|
   allowtcpforwarding|allowagentforwarding) '` returned the same
   nine values recorded in the snapshot.
8. **Held-open session** closed via `SIGTERM`. Exit code 144 as
   expected for a sleep-killed background process.

No deviation from packet. The backup path itself (logging in with
the new key from a backup operator device) was **not** verified at
apply time because no separate operator device was wired up to the
1Password SSH agent during this window; that verification is
deferred to the first time the operator uses the backup path from
a non-MacBook context.

## Evidence

### Timestamps And Identity

```text
local_preflight_utc:           2026-05-14T02:41:44Z (approx)
drift_recheck_utc:             2026-05-14T02:41:44Z
snapshot_created_utc:          2026-05-14T02:42:25Z
post_apply_validation_utc:     2026-05-14T02:42:30Z (approx)
hostname:                      fedora-top
operator:                      verlyn13 (human-supervised agent
                               session in system-config)
ssh_path:                      fedora-top.home.arpa via
                               HostKeyAlias=192.168.0.206
```

### Snapshot

```text
snapshot_path:   /var/backups/jefahnierocks-fedora-top-admin-backup-key-20260514T024225Z
permissions:     0700 root:root
contents:
  authorized_keys              81 B  (pre-apply copy; mode 0600 root:root)
  fingerprints-before.txt      76 B  (the single pre-apply fingerprint)
  sshd-effective-before.txt   217 B  (the nine effective settings)
  manifest.sha256             264 B  (sha256 manifest of the three files)
```

### authorized_keys Diff

```text
Before:
  256 SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8 no comment (ED25519)

After:
  256 SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8 no comment (ED25519)
  256 SHA256:VUu4nr5J+JjTpwFzRw+l2WQoKbfLhQhXAwGQmdlL6qU verlyn13@fedora-top-admin-backup (ED25519)
```

File post-apply: `verlyn13:verlyn13 0600 195 bytes` (was 81 bytes;
the increment is one new OpenSSH ed25519 line plus newline). SELinux
context `unconfined_u:object_r:ssh_home_t:s0` (matches the canonical
context for `~/.ssh` content; the SELinux user is `unconfined_u`
because the file was rewritten by an unconfined login session; the
**type** `ssh_home_t` is the value SELinux policy actually keys on).

### Primary-Path Verification (MacBook key)

```text
ssh ... verlyn13@fedora-top.home.arpa 'hostname; whoami; echo verlyn13_primary_path_ok'
  fedora-top
  verlyn13
  verlyn13_primary_path_ok
```

### sshd Effective Settings (must equal snapshot)

```text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
x11forwarding no
allowtcpforwarding no
allowagentforwarding no
allowusers verlyn13
authenticationmethods publickey
```

Exactly matches the pre-apply snapshot. No drift.

### Backup-Path Verification

```text
backup_path_verified:          DEFERRED. No second operator device
                               was attached to the
                               op://Dev/jefahnierocks-device-fedora-top-admin-backup-verlyn13
                               1Password SSH agent at apply time.
                               First-use verification will be the
                               operator's first SSH attempt from a
                               non-MacBook context; record the
                               result in a follow-up evidence
                               note.
```

The backup path is enabled at the server side; verification just
moves to first-use rather than being completed during this apply
window.

### Rollback

```text
rollback_used:  no
rollback_path:  available; snapshot at
                /var/backups/jefahnierocks-fedora-top-admin-backup-key-20260514T024225Z
                contains the pre-apply authorized_keys. To revert:
                  install -m 0600 -o verlyn13 -g verlyn13 \
                    "<snapshot>/authorized_keys" \
                    /home/verlyn13/.ssh/authorized_keys
                  restorecon -Rv /home/verlyn13/.ssh
                followed by a fresh primary-path SSH check.
```

## Boundary Assertions

Surfaces intentionally not touched (match the approval phrase):

- `sshd_config`, `sshd_config.d/`, the existing
  `20-jefahnierocks-admin.conf` drop-in.
- `firewalld` zones, services, ports, rich rules.
- `docker` zone, Docker engine, daemon, containers.
- `sudoers`, users, groups, Docker group membership.
- Tailscale, `tailscaled`, the Tailscale stable DNF repo.
- WARP, `cloudflared`, Cloudflare DNS / Tunnel / Access /
  Gateway / device enrollment.
- OPNsense, ISC DHCP, Unbound, NAT, HAProxy, WoL.
- LUKS, TPM, Secure Boot, firmware, sleep/power, reboot.
- 1Password items, vaults, fields (the operator created the
  `op://Dev/jefahnierocks-device-fedora-top-admin-backup-verlyn13`
  item out-of-band, before this apply window).
- The MAMAWORK fingerprint
  `SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`
  (DadAdmin_WinNet) was **not** reused for this Fedora backup,
  per packet rule.

## Remaining Blockers

For `fedora-top` specifically:

- First-use verification of the backup path (operator logs in
  from a non-MacBook context that holds the backup key in the
  1Password SSH agent).
- MacBook `known_hosts` reconciliation for `fedora-top.home.arpa`
  (still prepared, still approval-required, separate packet).
- WARP / cloudflared cutover packets (drafteable now per the
  cloudflare-dns handback at commit `b5b9460`).
- The privilege-cleanup follow-ups in the broader fedora-top
  blocked-items list are unchanged.

## Related

- [fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-known-hosts-reconciliation-packet-2026-05-13.md](./fedora-top-known-hosts-reconciliation-packet-2026-05-13.md)
- [cloudflare-dns-handback-ingest-2026-05-14.md](./cloudflare-dns-handback-ingest-2026-05-14.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
