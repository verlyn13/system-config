---
title: Fedora Top Privilege Cleanup Packet - 2026-05-13
category: operations
component: device_admin
status: applied
version: 0.2.0
last_updated: 2026-05-13
tags: [device-admin, fedora, privilege, sudoers, wheel, docker]
priority: high
---

# Fedora Top Privilege Cleanup Packet - 2026-05-13

This packet defines the narrow privilege cleanup on `fedora-top`. It was
applied live on 2026-05-13 along the default path; redacted apply evidence is
recorded in
[fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md).

The target posture is: `verlyn13` is the only mission-critical admin/service
owner; `wyn`, `axel`, and `ila` remain usable as standard accounts without
`wheel`, sudo, Docker, or service-management authority; `mesh-ops` is treated
as suspect/possibly obsolete because Jefahnierocks Infisical is moving to the
Hetzner server only.

The original text below is preserved for reuse and audit. One minor command-
flag adjustment to R10 (`restorecon`) was needed at apply time - see
"Apply-Time Deviation" near the R10 section.

## Scope

In scope:

- `/etc/group` membership for `wheel`, `docker`, and (optionally)
  `systemd-journal` for the non-`verlyn13` accounts listed in the verified
  state.
- `/etc/sudoers` cleanup of one duplicate explicit grant.
- `/etc/sudoers.d/50-mesh-ops` retain-or-remove decision and mode fix.
- `restorecon` on `/etc/sudoers` and `/etc/sudoers.d/` to reset SELinux
  contexts that drifted from `system_u`.
- `visudo -c` validation pre and post.

Out of scope (intentionally not touched, requires separate packets):

- `firewalld`
- `verlyn13` `NOPASSWD: ALL` removal or narrowing (see "Decisions Required")
- Account locking, shell changes, or user deletion for `wyn`, `axel`,
  `ila`, or `mesh-ops`
- Docker Engine, compose stacks, Infisical/Redis containers
- Tailscale, WARP, `cloudflared`, Cloudflare, DNS, DHCP, OPNsense
- LUKS, TPM, Secure Boot, firmware, power, reboot
- 1Password items, vaults, fields
- SSH daemon config (already hardened on 2026-05-13)

## Verified Current Live State

Observed via SSH from the MacBook on `2026-05-13T21:11:41Z` using
`HostKeyAlias=192.168.0.206`. Read-only; no state changed.

### Groups

```text
wheel:           verlyn13, wyn, axel, ila, mesh-ops    (gid 10)
docker:          verlyn13, ila, mesh-ops               (gid 973)
systemd-journal: mesh-ops                              (gid 190)
dialout:         axel                                  (gid 18)
plugdev:         axel                                  (gid 968)
```

### Users (login, uid, primary gid, shell)

```text
verlyn13   uid=1000  gid=1000  shell=/bin/zsh
wyn        uid=1002  gid=1002  shell=/bin/bash
axel       uid=1001  gid=1001  shell=/bin/bash
ila        uid=1003  gid=1003  shell=/bin/bash
mesh-ops   uid=2000  gid=2000  shell=/bin/bash  (description: "Mesh
                                                  Infrastructure Operations")
```

`verlyn13` runs `zsh`; the others run `bash`. No system shells (`nologin`)
are in use for these accounts.

### Effective Sudo (`sudo -l -U <user>`)

```text
verlyn13   (ALL) ALL
           (ALL) NOPASSWD: ALL                  via /etc/sudoers.d/ansible-automation

wyn        (ALL) ALL                            via %wheel
           (ALL) ALL                            via /etc/sudoers:108 (duplicate)

axel       (ALL) ALL                            via %wheel

ila        (ALL) ALL                            via %wheel

mesh-ops   (ALL) ALL                            via %wheel
           (ALL) NOPASSWD: /usr/bin/systemctl restart tailscaled
           (ALL) NOPASSWD: /usr/bin/systemctl status tailscaled
           (ALL) NOPASSWD: /usr/bin/systemctl start tailscaled
           (ALL) NOPASSWD: /usr/bin/systemctl stop tailscaled
           (ALL) NOPASSWD: /usr/bin/tailscale *
           (ALL) NOPASSWD: /usr/bin/dnf install -y *
           (ALL) NOPASSWD: /usr/bin/dnf update -y
           (ALL) NOPASSWD: /usr/bin/docker *
           (ALL) NOPASSWD: /usr/bin/podman *
           (ALL) NOPASSWD: /usr/bin/firewall-cmd *
                                                via /etc/sudoers.d/50-mesh-ops
```

Note: because `mesh-ops` is also in `wheel`, the `(ALL) ALL` grant already
covers the NOPASSWD wildcard list as a superset; the wildcards only add
"may run without password prompt" semantics on top of the base grant.

### Sudoers Files

```text
/etc/sudoers                    root:root 0440  system_u:object_r:etc_t:s0
/etc/sudoers.d/ansible-automation
                                root:root 0440  unconfined_u:object_r:etc_t:s0
/etc/sudoers.d/50-mesh-ops      root:root 0644  unconfined_u:object_r:etc_t:s0
```

`visudo -c` result:

```text
/etc/sudoers.d/50-mesh-ops: bad permissions, should be mode 0440
/etc/sudoers: parsed OK
/etc/sudoers.d/ansible-automation: parsed OK
```

`/etc/sudoers.d/50-mesh-ops` has mode `0644` instead of the required
`0440`. Currently the policy is still effective (live `sudo -l -U mesh-ops`
returns the wildcards), but `visudo -c` flags this as a posture defect that
can silently break on stricter sudo defaults. Both drop-ins also carry
`unconfined_u` SELinux user instead of the expected `system_u`, indicating
the files were created interactively rather than provisioned by policy.

### `/etc/sudoers` Duplicate (Line Context)

```text
106: ## Allows people in group wheel to run all commands
107: %wheel	ALL=(ALL)	ALL
108: wyn ALL=(ALL) ALL
109:
110: ## Same thing without a password
111: # %wheel	ALL=(ALL)	NOPASSWD: ALL
```

Line 108 grants `wyn` an explicit `(ALL) ALL` that is already implied by
the `%wheel` line above. Harmless duplicate today; cleanup is for hygiene
and to avoid surviving a `wyn` removal from `wheel`.

### Sessions, Lingers, And User Units

- Active sessions: `verlyn13` only (six sessions, including seat0 user
  session and several `manager`/`user` sessions).
- `loginctl` `Linger`: `verlyn13=yes`, others not enabled.
- Enabled systemd user units for `wyn`, `axel`, `ila`, `mesh-ops` are
  identical and match the default desktop-session set
  (`dbus-broker`, `obex`, `pipewire`, `wireplumber`, `systemd-tmpfiles`,
  `grub-boot-success.timer`). None of these is a custom unattended
  automation. Removing sudo/Docker authority will not break any documented
  custom user-service.
- Process counts: `verlyn13=159` (interactive session), `wyn=4`, `axel=5`,
  `ila=4`, `mesh-ops=4` - the non-`verlyn13` processes are residual
  user-manager / dbus, not active admin work.

### Docker Surface

```text
/var/run/docker.sock   srw-rw---- root:docker
                       SELinux: system_u:object_r:container_var_run_t:s0
```

Docker socket is group-owned by `docker`. Membership controls Docker admin
access. Infisical/Redis compose project remains under
`/home/verlyn13/Projects/happy-secrets/`; it does not depend on `ila`,
`mesh-ops`, or any non-`verlyn13` user.

### SSH Reminder

`sshd -T` still shows `allowusers verlyn13`, so SSH access is restricted to
`verlyn13` regardless of these other users' sudo capabilities. Non-`verlyn13`
admin capability is only reachable from the local console.

## Proposed Changes

### Removals

| # | Change | Rationale |
|---|---|---|
| R1 | `gpasswd -d wyn wheel` | `wyn` is an exploratory account; operator policy says exploratory accounts should not retain `wheel` |
| R2 | `gpasswd -d axel wheel` | Same rationale as R1 |
| R3 | `gpasswd -d ila wheel` | Same rationale as R1 |
| R4 | `gpasswd -d mesh-ops wheel` | `mesh-ops` is suspect after Infisical retirement; remove the broadest grant first |
| R5 | `gpasswd -d ila docker` | No documented Docker admin purpose for `ila`; `verlyn13` retains Docker authority |
| R6 | `gpasswd -d mesh-ops docker` | Same rationale as R5 |
| R7 | `gpasswd -d mesh-ops systemd-journal` | Same rationale as R4/R5; removes one more elevated group attached to a suspect account |
| R8 | Remove duplicate explicit `wyn ALL=(ALL) ALL` at `/etc/sudoers:108` | Hygiene; redundant with `%wheel` and becomes a stale exception after R1 |
| R9 | Remove `/etc/sudoers.d/50-mesh-ops` (default recommendation) | After R4 the `(ALL) ALL` from `%wheel` is gone, and the NOPASSWD wildcards (dnf, docker, podman, firewall-cmd, tailscale) are exactly the unattended-automation surface that should disappear when `mesh-ops`'s purpose is no longer documented |
| R10 | `restorecon -Rv /etc/sudoers /etc/sudoers.d` | Restores `system_u` SELinux user on touched files (housekeeping) |

R9 is the only removal that depends on a separate decision below. If the
guardian retains `mesh-ops` for any reason, R9 changes to "fix mode of
`50-mesh-ops` to `0440` and narrow grants" (see "Alternate Retain Path"
near the end of this packet).

### Retentions

| # | Retained | Rationale |
|---|---|---|
| K1 | `verlyn13` in `wheel` | Primary admin |
| K2 | `verlyn13` in `docker` | Primary Docker operator |
| K3 | `axel` in `dialout` | Standard hardware access for serial devices; not an admin grant |
| K4 | `axel` in `plugdev` | Standard hardware access for removable devices; not an admin grant |
| K5 | `verlyn13` `NOPASSWD: ALL` via `/etc/sudoers.d/ansible-automation` | See "Decisions Required From Guardian" below; retained pending a separate narrow review packet |
| K6 | All accounts remain usable with their current shells, home dirs, and PII | Operator policy: exploratory accounts stay usable |

## Decisions Required From Guardian

The packet treats these as live questions; the apply commands below assume
the default answer in each case. Override in the approval phrase if needed.

1. **`mesh-ops` account fate** (separate from R4-R7 above)
   - Default: keep account, drop privileges (R4/R5/R7 + R9 remove file).
   - Alternative A: lock account (`usermod -L mesh-ops`) - this is
     out of scope for this packet and would belong in a separate account-
     lifecycle packet.
   - Alternative B: delete account and home (out of scope here).
   - Alternative C: retain `mesh-ops` admin posture for a documented
     reason. If chosen, the apply path changes - see "Alternate Retain
     Path".

2. **`verlyn13` `NOPASSWD: ALL` via `/etc/sudoers.d/ansible-automation`**
   - Default: retain temporarily. The current MacBook-driven admin
     pattern depends on `sudo -n` succeeding for `verlyn13`. Removing
     `NOPASSWD: ALL` would force interactive sudo and break the
     held-open-session / second-terminal apply model used by the SSH
     hardening packet and this packet.
   - Recommendation: defer the decision to a later narrow review packet
     once a non-`NOPASSWD` admin path is designed (for example, a Polkit
     rule, a narrower sudoers grant for the specific commands used during
     remote apply, or an alternate operator account).
   - If the guardian wants to remove `NOPASSWD: ALL` in this packet, all
     future apply runs (including this one's apply) must be re-planned
     for interactive sudo or a different escalation path.

3. **`%wheel` policy in `/etc/sudoers`**
   - Default: leave `%wheel ALL=(ALL) ALL` intact. After R1-R4, only
     `verlyn13` remains in `wheel`, so the policy effectively grants only
     `verlyn13`.
   - Alternative: comment out the `%wheel` line and grant `verlyn13`
     explicitly. This is more explicit but less idiomatic on Fedora; it
     also means future additions to `wheel` would silently grant nothing
     until the line is re-enabled. Recommendation: keep the default; do
     not edit the `%wheel` directive.

## Apply Commands

Apply only after explicit guardian approval. Use the same SSH options
documented in the SSH hardening packet, including
`HostKeyAlias=192.168.0.206` until MacBook `known_hosts` is reconciled.

### Held-Open Control Session

Open before any change, mirror the SSH hardening pattern, do not close
until validation passes:

```bash
ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  -o ControlMaster=no \
  -o ControlPath=none \
  verlyn13@fedora-top.home.arpa
```

### Snapshot Pre-Apply State

```bash
sudo -n bash <<'EOF'
set -euo pipefail
SNAP="/var/backups/jefahnierocks-priv-cleanup-$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 0700 -o root -g root "$SNAP"

getent group wheel docker systemd-journal dialout plugdev > "$SNAP/groups.txt"
for u in verlyn13 wyn axel ila mesh-ops; do
  echo "--- $u ---"; id "$u"; sudo -l -U "$u"
done > "$SNAP/sudo-l.txt" 2>&1

install -m 0440 -o root -g root /etc/sudoers "$SNAP/sudoers"
if [ -d /etc/sudoers.d ]; then
  install -d -m 0700 -o root -g root "$SNAP/sudoers.d"
  for f in /etc/sudoers.d/*; do
    [ -f "$f" ] || continue
    install -m 0400 -o root -g root "$f" "$SNAP/sudoers.d/$(basename "$f")"
  done
fi
echo "snapshot=$SNAP"
EOF
```

Record the printed `snapshot=...` path for rollback.

### Group Removals (R1-R7)

```bash
sudo -n bash <<'EOF'
set -euo pipefail
for pair in \
  "wyn wheel" \
  "axel wheel" \
  "ila wheel" \
  "mesh-ops wheel" \
  "ila docker" \
  "mesh-ops docker" \
  "mesh-ops systemd-journal"; do
  u="${pair% *}"; g="${pair#* }"
  if id -nG "$u" 2>/dev/null | tr ' ' '\n' | grep -qx "$g"; then
    gpasswd -d "$u" "$g"
  else
    echo "skip: $u already not in $g"
  fi
done
EOF
```

### Sudoers Edits (R8, R9, R10)

R8 - remove duplicate `wyn ALL=(ALL) ALL` from `/etc/sudoers` line 108.
Use `EDITOR=/usr/bin/sed -i ...` via `visudo` so the file is validated
before being swapped in:

```bash
sudo -n bash <<'EOF'
set -euo pipefail
TMP="$(mktemp -p /root sudoers.new.XXXXXX)"
install -m 0440 -o root -g root /etc/sudoers "$TMP"
sed -i -E '/^[[:space:]]*wyn[[:space:]]+ALL=\(ALL\)[[:space:]]+ALL[[:space:]]*$/d' "$TMP"
visudo -c -f "$TMP"
install -m 0440 -o root -g root "$TMP" /etc/sudoers
rm -f "$TMP"
EOF
```

R9 - remove `/etc/sudoers.d/50-mesh-ops` (default path):

```bash
sudo -n rm -f /etc/sudoers.d/50-mesh-ops
sudo -n visudo -c
```

R10 - restore SELinux contexts:

```bash
sudo -n restorecon -Rv /etc/sudoers /etc/sudoers.d
```

### Apply-Time Deviation (R10 flag)

The 2026-05-13 apply found that `restorecon -Rv` (no `-F`) only resets
SELinux type, not SELinux user. The `unconfined_u` SELinux user on the
existing `ansible-automation` drop-in stayed unchanged. A follow-up
`restorecon -RFv /etc/sudoers /etc/sudoers.d` (force) reset the user to
the policy-default `system_u`. Functional SELinux behavior is governed by
type (`etc_t`) and is correct either way; the `-F` pass is cosmetic and
matches the "expected post-apply" stat lines in the validation section.
For future reuse on similar hosts, run R10 as
`restorecon -RFv /etc/sudoers /etc/sudoers.d` directly.

## Validation

Run from a fresh SSH process while the held-open session remains open.
All checks must pass before closing the held-open session.

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n bash -s' <<'EOF'
set -u
echo "--- visudo -c ---"
visudo -c
echo "--- groups after cleanup ---"
getent group wheel
getent group docker
getent group systemd-journal
echo "--- per-user sudo -l ---"
for u in verlyn13 wyn axel ila mesh-ops; do
  echo "--- $u ---"
  sudo -l -U "$u" 2>&1 || true
done
echo "--- sudoers.d listing ---"
ls -lZ /etc/sudoers.d/
echo "--- mode/context per file ---"
stat -c '%U:%G %a %C %n' /etc/sudoers
for f in /etc/sudoers.d/*; do stat -c '%U:%G %a %C %n' "$f"; done
EOF
```

Expected post-apply:

```text
wheel:           verlyn13
docker:          verlyn13
systemd-journal: <empty> (gid 190 retained, no human members)

sudo -l -U verlyn13   -> still (ALL) ALL and (ALL) NOPASSWD: ALL
sudo -l -U wyn        -> "User wyn is not allowed to run sudo on fedora-top."
sudo -l -U axel       -> "User axel is not allowed to run sudo on fedora-top."
sudo -l -U ila        -> "User ila is not allowed to run sudo on fedora-top."
sudo -l -U mesh-ops   -> "User mesh-ops is not allowed to run sudo on fedora-top."

ls /etc/sudoers.d/    -> only ansible-automation

visudo -c             -> clean (no "bad permissions" warnings)

stat /etc/sudoers     -> root:root 0440  system_u:object_r:etc_t:s0
stat .../ansible-automation
                      -> root:root 0440  system_u:object_r:etc_t:s0
                         (was unconfined_u; restorecon should reset to system_u)
```

Optional sanity from the MacBook:

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n true && echo verlyn13-sudo=ok'
```

## Rollback

Use the held-open session if validation fails. Replace `<snapshot-path>`
with the value captured by the pre-apply snapshot step.

```bash
sudo -n bash <<'EOF'
set -euo pipefail
SNAP="<snapshot-path>"

# 1. Restore /etc/sudoers from snapshot
install -m 0440 -o root -g root "$SNAP/sudoers" /etc/sudoers

# 2. Restore /etc/sudoers.d contents from snapshot
for f in "$SNAP"/sudoers.d/*; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  install -m 0440 -o root -g root "$f" "/etc/sudoers.d/$base"
done

# 3. Re-add groups (idempotent)
gpasswd -a wyn      wheel
gpasswd -a axel     wheel
gpasswd -a ila      wheel
gpasswd -a mesh-ops wheel
gpasswd -a ila      docker
gpasswd -a mesh-ops docker
gpasswd -a mesh-ops systemd-journal

# 4. Validate
visudo -c
restorecon -Rv /etc/sudoers /etc/sudoers.d
EOF
```

Then re-run the validation block in a fresh SSH session.

If `visudo -c` fails before the swap-in step (for example because the new
`/etc/sudoers` would be invalid), the apply already aborts there; no
rollback is needed - the live `/etc/sudoers` was never replaced.

## Risks

- **Polkit / desktop authentication for `wyn`, `axel`, `ila`**: removing
  these accounts from `wheel` also removes their default GUI Polkit
  administrator path (`@wheel` rules). Routine desktop tasks (installing
  software via `gnome-software`, mounting unprivileged disks, etc.) will
  prompt for administrator credentials that they will no longer have.
  This is the intended policy outcome ("usable as standard accounts"),
  but the operator should know it changes the desktop experience for
  those accounts.
- **Tailscale and firewall workflows via `mesh-ops`**: R9 removes the
  NOPASSWD wildcards for `systemctl ... tailscaled`, `tailscale *`,
  `firewall-cmd *`, and `dnf install -y *`. If any unobserved automation
  on this host depends on those grants (cron, systemd-user timer, ssh
  command directive), it will start failing. The verified state shows no
  such automation, but the operator may have undocumented uses.
- **`ila` losing Docker**: container access for `ila` ends. Infisical/
  Redis containers run under `verlyn13`'s compose project and continue
  unaffected.
- **`%wheel` policy intact**: after this packet, `wheel` membership alone
  is the route to root for `verlyn13`. Any future addition to `wheel`
  immediately grants root. This is the current Fedora default; the packet
  does not change it but the operator should know it.
- **SELinux drift on `/etc/sudoers.d/`**: `restorecon` resets to default
  `system_u` SELinux user. If a future operator drops new files into
  `/etc/sudoers.d/` interactively (e.g., `sudo cp` from a logged-in
  unconfined shell), the same drift will reappear and `visudo -c` may
  warn about it. This is a recurring housekeeping concern, not a one-time
  fix.
- **`verlyn13` `NOPASSWD: ALL` remains**: any code path running as
  `verlyn13` retains the ability to escalate without prompting. This is
  documented as a known retained exception pending a separate review
  packet (see "Decisions Required").
- **No lockout risk for `verlyn13`**: `verlyn13` retains `(ALL) ALL` via
  `%wheel` and `NOPASSWD: ALL` via the ansible-automation drop-in. Even
  if one path were broken, the other remains. Apply commands always use
  `gpasswd -d` (single-user remove), never `groupmod -U <list>`, so a
  typo cannot mass-remove members.

## Alternate Retain Path (mesh-ops)

If the guardian retains `mesh-ops` admin posture, R4/R5/R7/R9 are
replaced by:

```bash
sudo -n bash <<'EOF'
set -euo pipefail
# Keep wheel + docker + systemd-journal memberships for mesh-ops; fix mode + content
chown root:root /etc/sudoers.d/50-mesh-ops
chmod 0440 /etc/sudoers.d/50-mesh-ops
visudo -c -f /etc/sudoers.d/50-mesh-ops
restorecon -Rv /etc/sudoers.d/50-mesh-ops
EOF
```

If `mesh-ops` is retained but its NOPASSWD grants should be narrowed,
that requires a separate decision listing which commands stay; do not
hand-edit `/etc/sudoers.d/50-mesh-ops` without that explicit list.

## Required Approval Phrase

Live apply requires guardian approval substantially equivalent to:

```text
I approve applying the Fedora privilege cleanup packet live now: snapshot
current /etc/sudoers, /etc/sudoers.d, and group memberships to
/var/backups/jefahnierocks-priv-cleanup-<timestamp>; remove wyn, axel, ila,
and mesh-ops from wheel; remove ila and mesh-ops from docker; remove
mesh-ops from systemd-journal; remove duplicate wyn ALL=(ALL) ALL from
/etc/sudoers line 108 with visudo validation; remove
/etc/sudoers.d/50-mesh-ops; run restorecon on /etc/sudoers and
/etc/sudoers.d; validate with visudo -c and per-user sudo -l; rollback if
verification fails. Retain verlyn13 NOPASSWD: ALL via
/etc/sudoers.d/ansible-automation pending a separate review packet.
```

Adjust the phrase if the guardian wants the Alternate Retain Path for
`mesh-ops` or wants to keep the duplicate `wyn` line for any reason.

## Evidence To Record After Apply

```text
timestamp:
operator:
held-open session used:
snapshot path:
group membership diff (pre -> post):
sudo -l -U <user> result per user:
visudo -c result:
sudoers.d listing post-apply:
selinux context post-restorecon:
verlyn13 sudo -n true check:
rollback used: yes/no
remaining blockers:
```

Do not copy private keys, passwords, recovery keys, or raw audit logs
containing secrets into the repo. Do not copy the GECOS full names of
exploratory accounts beyond their existing login-name references.

## Related

- [fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md)
- [fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [../secrets.md](../secrets.md)
