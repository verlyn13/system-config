---
title: Fedora Top Privilege Cleanup Apply - 2026-05-13
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, privilege, sudoers, wheel, docker, evidence]
priority: high
---

# Fedora Top Privilege Cleanup Apply - 2026-05-13

This record captures the live apply of the privilege cleanup packet recorded
in
[fedora-top-privilege-cleanup-packet-2026-05-13.md](./fedora-top-privilege-cleanup-packet-2026-05-13.md).

Scope was the prepared packet's default path only. No SSH daemon, `firewalld`,
Docker engine, Infisical, Redis, Tailscale, WARP, `cloudflared`, Cloudflare,
OPNsense, DNS, DHCP, LUKS, TPM, Secure Boot, firmware, power, reboot, or
1Password state was touched. `verlyn13 NOPASSWD: ALL` was explicitly retained
pending a separate review packet.

## Approval

Guardian/operator approval was given in the live session and matches the
directive template recorded in the packet. The approval expanded slightly on
the packet's phrase to explicitly call out retained groups (`verlyn13` in
`wheel` and `docker`; `axel` in `dialout` and `plugdev`) and to require
drift re-verification before applying.

## Apply Sequence (Actual)

1. Drift re-verification (read-only) at `2026-05-13T21:20:37Z` confirmed
   `wheel`, `docker`, and `systemd-journal` memberships still matched the
   packet baseline; `/etc/sudoers:108` still contained the duplicate
   `wyn ALL=(ALL) ALL`; `/etc/sudoers.d/50-mesh-ops` was still mode `0644`
   with sha256 matching the prior inspection. `visudo -c` still flagged
   only `50-mesh-ops` mode.
2. Held-open control SSH session opened in background using
   `HostKeyAlias=192.168.0.206`, `ServerAliveInterval=30`,
   `ControlMaster=no`, with `sleep 3600` payload. Confirmed alive
   immediately before any privileged write.
3. Pre-apply snapshot to
   `/var/backups/jefahnierocks-priv-cleanup-20260513T212114Z` containing
   `sudoers`, `sudoers.d/50-mesh-ops`, `sudoers.d/ansible-automation`,
   `groups.txt` (`getent group wheel docker systemd-journal dialout
   plugdev`), `sudo-l.txt` (per-user `id` and `sudo -l -U`),
   `selinux-contexts.txt`, and `manifest.sha256` integrity manifest.
4. Group removals (R1-R7) via `gpasswd -d` in a single loop, idempotent
   guard `id -nG | grep -qx`:
   `wyn`, `axel`, `ila`, `mesh-ops` removed from `wheel`;
   `ila` and `mesh-ops` removed from `docker`;
   `mesh-ops` removed from `systemd-journal`. All seven removals
   reported success.
5. R8 (duplicate `wyn` sudoers grant): copied `/etc/sudoers` to
   `/root/sudoers.new.<rand>` (non-sticky directory to avoid the kernel
   `fs.protected_regular` issue documented in the SSH hardening apply
   record), ran the packet's `sed -E -i` against the temp file, captured
   the unified diff against the live file showing only line 108 deletion,
   ran `visudo -c -f` against the temp file (parsed OK), then
   `install -m 0440 -o root -g root` swap-in to `/etc/sudoers`. The
   `install` operation reset the file's SELinux user from `unconfined_u`
   to `system_u` automatically because the policy-default user for files
   matching `etc_t` is `system_u`.
6. R9 (`/etc/sudoers.d/50-mesh-ops`): removed with `rm -v`.
   Post-remove `visudo -c` clean - no `bad permissions` warnings remain.
7. R10 (`restorecon -Rv /etc/sudoers /etc/sudoers.d`): the first pass
   relabeled nothing visible because `restorecon` without `-F` does not
   reset SELinux user. A follow-up `restorecon -RFv` (force) relabeled
   `/etc/sudoers.d/ansible-automation` from `unconfined_u` to `system_u`.
   This deviation from the packet's exact command list is noted below.
8. Comprehensive post-apply validation from a fresh SSH process: all
   nine target post-state checks passed (see Evidence).
9. Held-open control session closed via `SIGTERM`.

## Deviation From Packet

R10 in the packet specified `restorecon -Rv /etc/sudoers /etc/sudoers.d`.
The first run (no `-F`) reset file types as needed but left the SELinux
user (`unconfined_u`) on `/etc/sudoers.d/ansible-automation` unchanged,
because `restorecon` only resets the SELinux user when the `-F` (force)
flag is set. A second run with `restorecon -RFv` was performed to bring
the SELinux user in line with the policy default (`system_u`). The
functional SELinux posture on Fedora is determined by the type
(`etc_t`), not the user, so the deviation is cosmetic in effect, but the
packet's "expected post-apply" stat lines required `system_u`, so the
force pass was added to match the documented target.

This deviation does not change the scope of the apply. The packet should
be updated in a follow-up so reuse on similar hosts records the correct
flag set.

## Evidence

### Timestamp And Identity

```text
drift_check_utc:       2026-05-13T21:20:37Z
apply_start_utc:       ~2026-05-13T21:21:14Z (snapshot timestamp)
post_apply_validation: 2026-05-13T21:22:44Z
hostname:              fedora-top
operator:              verlyn13 (human-supervised agent session in system-config)
ssh_path:              fedora-top.home.arpa via HostKeyAlias=192.168.0.206
```

### Snapshot

```text
snapshot_path:  /var/backups/jefahnierocks-priv-cleanup-20260513T212114Z
contents:
  groups.txt
  sudo-l.txt
  selinux-contexts.txt
  sudoers              (mode 0440, root:root, sha256 9392879a0f2e7b08...)
  sudoers.d/
    50-mesh-ops        (mode 0400 in snapshot, sha256 73ca4f5d5b4f88d3...)
    ansible-automation (mode 0400 in snapshot, sha256 a424a07ead20b466...)
  manifest.sha256
permissions:    /var/backups/jefahnierocks-priv-cleanup-20260513T212114Z 0700 root:root
```

The snapshot is the documented rollback target.

### Group Membership Diff

```text
wheel             before: verlyn13, wyn, axel, ila, mesh-ops
                  after:  verlyn13

docker            before: verlyn13, ila, mesh-ops
                  after:  verlyn13

systemd-journal   before: mesh-ops
                  after:  (empty; gid 190 retained)

dialout           unchanged: axel (hardware group, not admin)
plugdev           unchanged: axel (hardware group, not admin)
```

### Per-User `sudo -l` After Apply

```text
verlyn13   (ALL) ALL                                      via %wheel
           (ALL) NOPASSWD: ALL                            via /etc/sudoers.d/ansible-automation

wyn        User wyn is not allowed to run sudo on fedora-top.
axel       User axel is not allowed to run sudo on fedora-top.
ila        User ila is not allowed to run sudo on fedora-top.
mesh-ops   User mesh-ops is not allowed to run sudo on fedora-top.
```

### Sudoers Files After Apply

```text
/etc/sudoers                       root:root 0440 system_u:object_r:etc_t:s0
/etc/sudoers.d                     root:root 0750 system_u:object_r:etc_t:s0
/etc/sudoers.d/ansible-automation  root:root 0440 system_u:object_r:etc_t:s0

(no /etc/sudoers.d/50-mesh-ops)

visudo -c:
  /etc/sudoers: parsed OK
  /etc/sudoers.d/ansible-automation: parsed OK
```

### `/etc/sudoers:108` Diff

```text
@@ -105,7 +105,6 @@

 ## Allows people in group wheel to run all commands
 %wheel	ALL=(ALL)	ALL
-wyn ALL=(ALL) ALL

 ## Same thing without a password
 # %wheel	ALL=(ALL)	NOPASSWD: ALL
```

Only the single duplicate line was removed. Line numbering after this
edit places the comment "Same thing without a password" at line 109.

### `verlyn13` Sanity Checks

```text
sudo -n true:        ok  (NOPASSWD: ALL still effective)
ssh allowusers:      verlyn13 (SSH posture unchanged)
```

The held-open session model still works because `verlyn13` retains
`NOPASSWD: ALL` via `/etc/sudoers.d/ansible-automation`.

### `mesh-ops` Capability After Apply

The `mesh-ops` account exists and remains usable as a standard account
(uid 2000, /bin/bash, home `/home/mesh-ops`), but has no `wheel`,
`docker`, `systemd-journal`, or sudoers grant. The NOPASSWD wildcards
for `tailscale *`, `dnf install -y *`, `dnf update -y`, `docker *`,
`podman *`, `firewall-cmd *`, and `systemctl ... tailscaled` are all
gone. Any consumer of those wildcards will start failing; the verified
state showed no active automation depending on them.

### Rollback

```text
rollback_used: no
rollback_path: remains available; the snapshot at
               /var/backups/jefahnierocks-priv-cleanup-20260513T212114Z
               contains complete copies of /etc/sudoers and
               /etc/sudoers.d/*, with sha256 manifest, plus pre-apply
               getent group output. The packet's "Rollback" block
               re-adds groups via gpasswd -a and reinstalls the
               snapshot files with install -m 0440 -o root -g root.
```

## Boundary Assertions

The following surfaces were intentionally not touched and remain in their
pre-apply state:

- SSH daemon, drop-ins, `authorized_keys`, host keys (still hardened per
  the 2026-05-13 apply record)
- `firewalld` zones, services, rules
- Docker engine, compose stacks, containers, images, volumes
  (Infisical/Redis/Postgres in `happy-secrets` unchanged)
- Tailscale, `tailscaled`, WARP, `cloudflared`
- Cloudflare DNS, Tunnel, Access, Gateway, device enrollment
- OPNsense, ISC DHCP scopes, Unbound host overrides, NAT, HAProxy, WoL
- LUKS, TPM, Secure Boot, firmware, sleep/power, reboot behavior
- 1Password items, vaults, fields
- Account creation/locking/deletion for `wyn`, `axel`, `ila`,
  `mesh-ops`; their shells, home directories, and GECOS fields are
  unchanged
- `verlyn13` `NOPASSWD: ALL` via `/etc/sudoers.d/ansible-automation`
  (explicitly retained pending separate review)

## Remaining Blockers

The host is not fully managed after privilege cleanup. The following
follow-on packets remain pending:

- Infisical and Redis retirement from this laptop (Hetzner-only
  Infisical). The `happy-secrets` compose stack continues to publish
  Infisical at `0.0.0.0:18080` and Redis at `0.0.0.0:6379`.
- `firewalld` narrowing after service-retirement sequencing is clear.
- Tailscale retain/remove decision; WARP and `cloudflared` design
  packet for off-LAN access.
- LUKS/remote-reboot strategy and AC/no-sleep policy.
- Fedora repo trust path repairs (Tailscale, Infisical signing keys);
  retire Infisical DNF repos.
- 1Password device-admin and recovery items for `fedora-top`.
- Separate review packet for narrowing or removing `verlyn13 NOPASSWD:
  ALL`. The current remote apply pattern depends on `sudo -n` for
  `verlyn13`; any change here must include a working replacement.
- Decision on lifecycle for `mesh-ops` (lock or delete) now that the
  account has no admin authority.
- MacBook `known_hosts` reconciliation for `fedora-top.home.arpa` so
  the `HostKeyAlias=192.168.0.206` workaround is no longer needed for
  routine SSH.

## Related

- [fedora-top-privilege-cleanup-packet-2026-05-13.md](./fedora-top-privilege-cleanup-packet-2026-05-13.md)
- [fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md)
- [fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [../secrets.md](../secrets.md)
