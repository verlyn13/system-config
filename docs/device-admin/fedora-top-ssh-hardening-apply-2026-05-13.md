---
title: Fedora Top SSH Hardening Apply - 2026-05-13
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, hardening, evidence]
priority: high
---

# Fedora Top SSH Hardening Apply - 2026-05-13

This record captures the live apply of the SSH hardening packet recorded in
[fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md).

Scope was the prepared packet only. No `firewalld`, sudoers, users, groups,
Docker, Infisical, Redis, Tailscale, WARP, `cloudflared`, Cloudflare, DNS,
DHCP, OPNsense, LUKS, TPM, Secure Boot, firmware, power, reboot, or 1Password
state was touched.

## Approval

Guardian/operator approval was given in the live session and matches the
directive template in
[fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md).
Approved key to retain: `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`.
Expected removals: WSL key
`SHA256:xHbcJoWrOxffuoiu+jS+8i9rUovVeUFeO6Y9A5WMpS4` and both duplicate
`ansible@hetzner.hq` entries
`SHA256:V3oZ/zOfm/IHLHF0i+nT7R6OItQbw/2N2CZq7iS3pNg`.

## Deviation From Packet

One minimal adjustment was made to the `authorized_keys` cleanup script. The
on-disk outcome is identical to the packet; only the intermediate tempfile
handling differs.

What changed:

- Dropped the early `chown verlyn13:verlyn13 "$TMP"` line in the cleanup
  heredoc. The subsequent
  `install -m 600 -o verlyn13 -g verlyn13 "$TMP" "$AUTHORIZED_KEYS"` already
  sets destination ownership, so the early chown was functionally redundant.

Why the original line failed in this environment:

- Fedora 44 ships with kernel hardening that enables `fs.protected_regular`
  by default. Under that sysctl, when `/tmp` is sticky and world-writable
  (`1777`), the kernel refuses `O_CREAT`-style opens on a regular file whose
  owner differs from both the directory owner and the calling fsuid - even
  for root. After `chown verlyn13:verlyn13`, the tmpfile in `/tmp` was owned
  by `verlyn13` but the script was executing as `root` (via `sudo -n bash`),
  so the subsequent append redirect failed with `Permission denied`.
- Proved in-place: identical sequence succeeds with `mktemp -p /root`
  (non-sticky), fails in `/tmp`. SELinux audit had no AVC for this event
  (the deny is a vanilla VFS protection, not a MAC denial).

State at the moment of failure: backup file was already created (`cp -a`
succeeded before the failing line). Original `authorized_keys` was
byte-identical to the backup, untouched. SSH daemon and drop-in state were
unchanged. The apply was paused before any persistent change.

The guardian explicitly approved running the minimally-adjusted script. The
fix is preserved for the packet doc itself in a separate update so future
reuse on hardened Fedora kernels does not retrigger the same VFS deny.

## Apply Sequence (Actual)

1. Preflight: `nc -vz` to `fedora-top.home.arpa:22` succeeded; read-only SSH
   smoke (`hostname`, `whoami`, `sudo -n true && sudo -n sshd -t`)
   succeeded.
2. Held-open control SSH session opened in background using
   `HostKeyAlias=192.168.0.206`, with `sleep 3600` payload and
   `ServerAliveInterval=30`. Confirmed alive immediately before sshd reload.
3. `authorized_keys` cleanup (adjusted script): backup created, exactly one
   approved key kept, `install -m 600 -o verlyn13 -g verlyn13` placed the
   file, `restorecon -Rv /home/verlyn13/.ssh` ran.
4. Fingerprint verification confirmed one key only:
   `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`.
5. `/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf` written via
   `install -m 600 -o root -g root /dev/null` followed by a quoted heredoc
   `tee`, then re-asserted `chown root:root` and `chmod 600`.
6. `sshd -t` passed; `systemctl reload sshd` returned success.
7. Second-session verification ran from a fresh SSH process and returned
   the nine target effective settings.
8. Negative password-auth check (`PreferredAuthentications=password`,
   `PubkeyAuthentication=no`, `BatchMode=yes`) was refused with
   `Permission denied (publickey)`.
9. Held-open control session closed via `SIGTERM`.
10. Read-only consolidated evidence collection (this record).

## Evidence

### Timestamp And Identity

```text
timestamp_utc:  2026-05-13T20:58:27Z
hostname:       fedora-top
operator:       verlyn13 (human-supervised agent session in system-config)
fqdn_target:    fedora-top.home.arpa
ip:             192.168.0.206
host_key:       SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w (unchanged)
```

### Held-Open Session

```text
held_open_session_used: yes
mechanism:              background ssh with sleep 3600, ControlMaster=no,
                        HostKeyAlias=192.168.0.206, ServerAliveInterval=30
closed_after:           second-session verification passed and negative
                        password-auth check passed
```

### authorized_keys

```text
authorized_keys:
  path:    /home/verlyn13/.ssh/authorized_keys
  owner:   verlyn13:verlyn13
  mode:    0600
  size:    81 bytes
  mtime:   2026-05-13T12:57:01-08:00
  active_lines: 1
  fingerprint: SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8 (ED25519)

backups (both byte-identical to the pre-apply file; second is the active
backup written by the successful cleanup run):
  - /home/verlyn13/.ssh/authorized_keys.pre-jefahnierocks-ssh-hardening-20260513T205340Z
    (created by the aborted first attempt; same 402 bytes as the pre-apply file)
  - /home/verlyn13/.ssh/authorized_keys.pre-jefahnierocks-ssh-hardening-20260513T205701Z
    (created by the successful cleanup run; active rollback target)
```

The two backup files exist because the first cleanup run failed at the
tempfile write step (before any modification of `authorized_keys`); its
backup was retained intact and matches the original. The second backup is
the one paired with the successful cleanup and is the rollback target if
ever needed.

### Drop-In

```text
path:    /etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf
owner:   root:root
mode:    0600
size:    217 bytes
context: system_u:object_r:etc_t:s0
content (verbatim):
  PermitRootLogin no
  PubkeyAuthentication yes
  PasswordAuthentication no
  KbdInteractiveAuthentication no
  AuthenticationMethods publickey
  AllowUsers verlyn13
  X11Forwarding no
  AllowAgentForwarding no
  AllowTcpForwarding no
sshd_config.d listing post-apply:
  -rw------- root:root 20-jefahnierocks-admin.conf
  -rw------- root:root 40-redhat-crypto-policies.conf
  -rw------- root:root 50-redhat.conf
```

The Jefahnierocks drop-in sorts before `50-redhat.conf`, so its values win
on the first-occurrence sshd_config precedence model.

### Validation And Reload

```text
sshd_t_result:                 ok
systemctl_reload_sshd_result:  ok
sshd_active_state:             active (running)
sshd_enabled:                  enabled
reload_event_in_journal:       "Reloaded sshd.service - OpenSSH server daemon"
listeners_post_reload:         0.0.0.0:22, [::]:22
```

### Second-Session Verification

```text
hostname:                  fedora-top
whoami:                    verlyn13
permitrootlogin:           no
pubkeyauthentication:      yes
passwordauthentication:    no
kbdinteractiveauthentication: no
x11forwarding:             no
allowtcpforwarding:        no
allowagentforwarding:      no
allowusers:                verlyn13
authenticationmethods:     publickey
```

All nine target effective settings match exactly.

### Negative Password-Auth Check

```text
client_options:    PreferredAuthentications=password, PubkeyAuthentication=no,
                   BatchMode=yes, HostKeyAlias=192.168.0.206
server_response:   Permission denied (publickey).
ssh_exit_code:     255
result:            PASS (login refused as expected; server requires publickey)
```

### Rollback

```text
rollback_used:  no
rollback_path:  remains available; rm of drop-in plus install of
                authorized_keys backup, per packet section "Rollback"
```

## Boundary Assertions

The following surfaces were intentionally not touched and remain in their
pre-apply state:

- `firewalld` zones, services, rules
- sudoers files, `wheel` membership, user accounts, group memberships,
  Docker group
- Docker engine, compose stacks, containers, images, volumes (Infisical,
  Redis, Postgres in `happy-secrets` remain as previously documented)
- Tailscale, `tailscaled`, WARP, `cloudflared`
- Cloudflare DNS, Tunnel, Access, Gateway, device enrollment
- OPNsense, ISC DHCP scopes, Unbound host overrides, NAT, HAProxy, WoL
- LUKS, TPM, Secure Boot, firmware, sleep/power, reboot behavior
- 1Password items, vaults, fields

## Remaining Blockers

The host is not fully managed after SSH hardening. The directive's
follow-on packets remain pending:

- Privilege cleanup: `wheel`, `docker`, sudoers anomalies, `mesh-ops`
  wildcards, duplicate `wyn ALL=(ALL) ALL`, `verlyn13` `NOPASSWD: ALL`,
  `50-mesh-ops` mode.
- Infisical/Redis retirement from this laptop (Hetzner-only Infisical).
- `firewalld` narrowing after the above is settled.
- Tailscale retain/remove decision.
- WARP and `cloudflared` design packet for off-LAN access.
- Power/LUKS remote-reboot strategy.
- Fedora repo trust path repairs (Tailscale, Infisical signing keys).

The MacBook `known_hosts` reconciliation for `fedora-top.home.arpa` is also
still pending; all SSH commands in this apply used
`HostKeyAlias=192.168.0.206` to reuse the verified IP host key without
modifying local SSH trust files.

## Related

- [fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md)
- [fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [fedora-top-homenetops-lan-identity-2026-05-13.md](./fedora-top-homenetops-lan-identity-2026-05-13.md)
- [fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
