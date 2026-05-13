---
title: Fedora Top System-Config Agent Directive - 2026-05-13
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, hardening, directive]
priority: high
---

# Fedora Top System-Config Agent Directive - 2026-05-13

This directive is for the agent currently operating in:

```text
/Users/verlyn13/Organizations/jefahnierocks/system-config
```

Scope is `fedora-top` only.

## Authority

`system-config` is the canonical Jefahnierocks repo for this device-admin
record set and the Fedora SSH hardening packet.

Do not move records to the workspace shell. The Jefahnierocks shell only
orchestrates repo ownership and handoffs.

Other repo boundaries:

- HomeNetOps owns OPNsense, DHCP, local DNS, LAN placement, router/firewall,
  and WoL.
- `cloudflare-dns` owns Cloudflare DNS, WARP, Access, Gateway, and device
  enrollment semantics.
- Device-local agents are fallback or evidence collectors unless explicitly
  activated.

## Required First Read

Read these before acting:

```text
docs/device-admin/fedora-44-laptop.md
docs/device-admin/fedora-top-ssh-hardening-packet-2026-05-13.md
docs/device-admin/fedora-top-homenetops-lan-identity-2026-05-13.md
docs/device-admin/fedora-top-prehardening-ingest-2026-05-13.md
docs/ssh.md
docs/secrets.md
```

Also check:

```bash
git status --short --branch
```

If there are uncommitted changes you did not make, preserve them and work
around them. Do not revert another agent's work.

## Current Verified State

Stable LAN target:

```text
hostname: fedora-top
fqdn:     fedora-top.home.arpa
ip:       192.168.0.206
ssh:      22/tcp LAN-only
mac_wifi: 66:b5:8c:f5:45:74
```

Current facts:

- MacBook public-key SSH as `verlyn13` works.
- Static DHCP and local DNS are verified through HomeNetOps.
- SSH hardening packet is prepared but not applied.
- Direct `ssh fedora-top.home.arpa` may fail host-key verification until the
  MacBook trust entry is reconciled.
- The prepared packet uses `HostKeyAlias=192.168.0.206` to reuse the known IP
  host key without changing local `known_hosts`.
- `sshd` is active/enabled and `sshd -t` passed in the read-only precheck.
- Effective SSH is still permissive: password auth, agent forwarding, TCP
  forwarding, and X11 forwarding remain enabled.
- `authorized_keys` has four active lines:
  - approved MacBook key
    `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`
  - WSL key
    `SHA256:xHbcJoWrOxffuoiu+jS+8i9rUovVeUFeO6Y9A5WMpS4`
  - duplicated `ansible@hetzner.hq` key
    `SHA256:V3oZ/zOfm/IHLHF0i+nT7R6OItQbw/2N2CZq7iS3pNg`

## Next Task

Prepare to apply the Fedora SSH hardening packet exactly as recorded in:

```text
docs/device-admin/fedora-top-ssh-hardening-packet-2026-05-13.md
```

If explicit guardian approval is present, apply the packet live.

The approval should be equivalent to:

```text
I approve applying the Fedora SSH hardening packet live now: clean
authorized_keys to the approved MacBook key only, add
/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf, validate/reload sshd,
verify a second SSH session, and rollback if verification fails.
```

If that approval is not present, do not reload SSH and do not edit
`authorized_keys`. Stop after preparing and reporting readiness.

## Live Apply Scope

If approved, this packet may do only:

- keep a live SSH control session open
- clean `/home/verlyn13/.ssh/authorized_keys` to the approved MacBook key only
- create `/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf`
- run `sshd -t`
- reload `sshd`
- verify a second SSH session over `fedora-top.home.arpa`
- run the packet rollback if verification fails
- update repo-safe `system-config` evidence after completion

Do not change:

- `firewalld`
- sudoers, users, groups, Docker membership, or service ownership
- Docker, Infisical, Redis, compose files, images, or volumes
- Tailscale, WARP, `cloudflared`, Cloudflare, Gateway, Access, or DNS policy
- OPNsense, DHCP, local DNS, NAT, HAProxy, router/firewall state, or WoL
- LUKS, TPM, Secure Boot, firmware, sleep, power, or reboot behavior
- 1Password items or secret values

## Required Safety Shape

For live apply:

1. Open and keep a control SSH session.
2. Do not close that session until a second post-reload SSH session succeeds.
3. Back up `authorized_keys` before modifying it.
4. Keep exactly one approved key after cleanup.
5. Write the SSH drop-in with root ownership and mode `0600`.
6. Run `sshd -t` before reload.
7. Reload, do not restart, `sshd`.
8. Verify public-key login from a second terminal.
9. Verify effective settings with `sshd -T`.
10. Roll back immediately if second-session verification fails.

Expected target effective SSH settings:

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

## Evidence To Return

Return this hand-back:

```text
repo:
branch:
status:
commit:
live changes made:
held-open session used:
authorized_keys backup path:
authorized key fingerprints after cleanup:
drop-in path/mode/owner:
sshd -t result:
reload result:
second-session verification:
effective sshd -T settings:
negative password-auth check:
rollback used:
files changed in repo:
validation run:
remaining blockers:
```

Do not include private keys, passwords, recovery keys, Tailscale auth links,
Cloudflare tokens, shell history, or raw logs containing secrets.

## Expected Repo Updates After Apply

If live apply succeeds, update the relevant `system-config` docs:

- `docs/device-admin/fedora-44-laptop.md`
- `docs/device-admin/onboarding-2026-05-12.md`
- `docs/device-admin/fedora-top-ssh-hardening-packet-2026-05-13.md`

Create a small evidence record if needed, for example:

```text
docs/device-admin/fedora-top-ssh-hardening-apply-2026-05-13.md
```

Keep the status honest: after SSH hardening, `fedora-top` is still not fully
managed. Firewall, privilege cleanup, Infisical/Redis retirement, repo trust,
Tailscale/WARP/Cloudflare, and LUKS/power remain separate packets.
