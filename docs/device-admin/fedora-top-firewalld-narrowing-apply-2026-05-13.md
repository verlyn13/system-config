---
title: Fedora Top firewalld Narrowing Apply - 2026-05-13
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, firewalld, hardening, evidence]
priority: high
---

# Fedora Top firewalld Narrowing Apply - 2026-05-13

This record captures the live apply of the `firewalld` narrowing packet
recorded in
[fedora-top-firewalld-narrowing-packet-2026-05-13.md](./fedora-top-firewalld-narrowing-packet-2026-05-13.md).

Scope was exactly the prepared default path: remove the
`FedoraWorkstation` zone's broad `1025-65535/tcp` and `1025-65535/udp`
port allowances. No SSH daemon, sudoers/users/groups, Docker zone or
engine, Tailscale, WARP, `cloudflared`, Cloudflare, OPNsense, DNS, DHCP,
LUKS, TPM, firmware, power, reboot, or 1Password state was touched. The
optional LAN source restriction on `ssh` was not opted into.

## Approval

Guardian/operator approval matches the directive template recorded in
the packet.

## Apply Sequence (Actual)

1. Drift re-verification at `2026-05-13T23:01:58Z`: confirmed
   `FedoraWorkstation` still active on `wlp0s20f3` as default zone with
   runtime + permanent ports `1025-65535/tcp,udp` and services
   `dhcpv6-client mdns samba-client ssh`; `sshd allowusers verlyn13`
   unchanged; `/etc/firewalld/zones/` contains
   `FedoraWorkstation.xml`, `FedoraWorkstation.xml.old` (Fedora's own
   pre-edit backup), and `docker.xml`.
2. Held-open control SSH session opened in background with
   `HostKeyAlias=192.168.0.206`, `ServerAliveInterval=30`,
   `ControlMaster=no`, payload `sleep 3600`. Confirmed alive before any
   change.
3. Pre-apply snapshot written to
   `/var/backups/jefahnierocks-firewalld-narrowing-20260513T230224Z`
   with `state.txt`, `default-zone.txt`, `active-zones.txt`,
   `zones-runtime.txt`, `zones-permanent.txt`, `direct-rules.txt`,
   `direct-passthroughs.txt`, `zones-xml/{FedoraWorkstation,docker}.xml`,
   `listeners-before.txt`, and `manifest.sha256`. Empty direct-rules
   and direct-passthroughs files are recorded as evidence-of-absence.
4. Apply (permanent edits first, then reload):
   - `firewall-cmd --permanent --zone=FedoraWorkstation
     --remove-port=1025-65535/tcp` -> success
   - `firewall-cmd --permanent --zone=FedoraWorkstation
     --remove-port=1025-65535/udp` -> success
   - `firewall-cmd --reload` -> success
5. Comprehensive post-apply validation from a fresh SSH process: all
   eleven target post-state checks passed. Positive SSH check from the
   MacBook (`nc -vz` + interactive command run) succeeded.
6. Held-open control session closed via `SIGTERM`.

No deviation from packet.

## Evidence

### Timestamps And Identity

```text
drift_check_utc:           2026-05-13T23:01:58Z
snapshot_created_utc:      2026-05-13T23:02:24Z
post_apply_validation_utc: 2026-05-13T23:03:01Z
hostname:                  fedora-top
operator:                  verlyn13 (human-supervised agent session in system-config)
ssh_path:                  fedora-top.home.arpa via HostKeyAlias=192.168.0.206
```

### Snapshot

```text
snapshot_path: /var/backups/jefahnierocks-firewalld-narrowing-20260513T230224Z
permissions:   0700 root:root
contents:
  state.txt                 (firewall-cmd --state output)
  default-zone.txt          (FedoraWorkstation)
  active-zones.txt          (FedoraWorkstation + docker with interfaces)
  zones-runtime.txt         (firewall-cmd --list-all-zones runtime)
  zones-permanent.txt       (firewall-cmd --permanent --list-all-zones)
  direct-rules.txt          (empty - no direct rules)
  direct-passthroughs.txt   (empty - no passthroughs)
  listeners-before.txt      (ss -tulpnH output captured pre-apply)
  zones-xml/
    FedoraWorkstation.xml   (4231 B equivalent of zone runtime listing
                             plus full pre-narrowing XML, including the
                             1025-65535/tcp,udp port stanzas)
    docker.xml              (docker zone XML, untouched)
  manifest.sha256           (10 sha256 entries)
```

The snapshot is the documented rollback target. Pre-apply XML for
`FedoraWorkstation.xml` is preserved so even an unattended firewalld
re-install would not lose the prior policy text.

### Apply Output

```text
runtime ports (pre-apply):     1025-65535/tcp 1025-65535/udp
permanent ports (pre-apply):   1025-65535/tcp 1025-65535/udp

firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/tcp
  -> success
firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/udp
  -> success
firewall-cmd --reload
  -> success

runtime ports (post-apply):    (empty)
permanent ports (post-apply):  (empty)
```

### Post-Apply Zone State

`FedoraWorkstation` (runtime):

```text
target: default
interfaces (runtime): wlp0s20f3
sources: (none)
services: dhcpv6-client mdns samba-client ssh
ports:    (none)
protocols: (none)
forward: yes
masquerade: no
rich rules: (none)
```

`FedoraWorkstation` (permanent): same as runtime except no `active`
flag and no interfaces (NetworkManager attaches `wlp0s20f3` at runtime
because `connection.zone` is unset, so the default zone applies).

`docker` zone (runtime): unchanged from pre-apply:

```text
target: ACCEPT
interfaces (runtime): docker0, br-02dbd2263acc, br-3830700d1415,
                      br-391335bed81e, br-c3c9141380d2, br-d1c294f41258,
                      br-f7751351cedc
services/ports/rich-rules: (none)
forward: yes
masquerade: no
```

Active zones:

```text
FedoraWorkstation (default) on wlp0s20f3
docker on 7 bridge interfaces
```

Runtime-vs-permanent diff (only expected delta - active flag and
interface bindings):

```text
< FedoraWorkstation (default, active)
> FedoraWorkstation (default)

<   interfaces: wlp0s20f3
>   interfaces:

< docker (active)
> docker

<   interfaces: br-02dbd2263acc br-3830700d1415 ...
>   interfaces:
```

No content drift. No new rich rules. No direct rules added.

### SSH Reachability

Positive check from MacBook:

```text
nc -vz -G 3 fedora-top.home.arpa 22   -> "Connection ... succeeded!"

ssh ... verlyn13@fedora-top.home.arpa 'hostname; whoami; sudo -n true && echo verlyn13_sudo_n=ok'
  hostname:        fedora-top
  whoami:          verlyn13
  sudo -n true:    verlyn13_sudo_n=ok
```

`sshd -T` on the host still reports `allowusers verlyn13`.

### Negative Reachability

A targeted negative check for `wsdd` on `3702/udp` from the MacBook
using `nc -vzu -G 3` returned a macOS tooling error (`nc -G` is not
compatible with `-u`); the absence of an explicit success is consistent
with the expected post-narrowing posture but is not a strong signal on
its own. The conclusive evidence is the empty `ports` listing on
`FedoraWorkstation` plus an unchanged service set; with no
`1025-65535/tcp,udp` allowance and no rich rule referencing the wsdd
ports, the firewall now drops external traffic to those listeners.

### Rollback

```text
rollback_used:  no
rollback_path:  remains available; the snapshot at
                /var/backups/jefahnierocks-firewalld-narrowing-20260513T230224Z
                contains the pre-apply XML. The packet's "Rollback"
                section also documents a quick reversal:
                  firewall-cmd --permanent --zone=FedoraWorkstation \
                    --add-port=1025-65535/tcp
                  firewall-cmd --permanent --zone=FedoraWorkstation \
                    --add-port=1025-65535/udp
                  firewall-cmd --reload
```

## Boundary Assertions

Surfaces intentionally not touched (matches the approval phrase):

- SSH daemon, `authorized_keys`, host keys (hardened per the 2026-05-13
  SSH apply record).
- sudoers, users, groups, Docker group membership (cleaned per the
  2026-05-13 privilege cleanup apply record).
- Docker zone, Docker engine, daemon config, daemon socket. Docker zone
  still `target: ACCEPT`; deliberately out of scope for this packet.
- Tailscale, `tailscaled`, the Tailscale stable DNF repo (separate
  decision packet).
- WARP, `cloudflared`, Cloudflare DNS/Tunnel/Access/Gateway/device
  enrollment.
- OPNsense, ISC DHCP scopes, Unbound host overrides, NAT, HAProxy, WoL.
- LUKS, TPM, Secure Boot, firmware, sleep/power, reboot behavior.
- 1Password items, vaults, fields.

## Remaining Blockers

The host remains not fully managed. Follow-on packets pending:

- Tailscale retain/remove decision (the `tailscale-stable` DNF repo is
  still enabled; `tailscaled` is still logged out and now its random
  WireGuard UDP port has no firewalld passage).
- WARP and `cloudflared` design packet for off-LAN access.
- Future narrow review of `verlyn13 NOPASSWD: ALL` (still retained
  pending separate review).
- LUKS/remote-reboot strategy and AC/no-sleep policy.
- 1Password device-admin and recovery items for `fedora-top`.
- Account-lifecycle decision for `mesh-ops` (lock, delete, or leave as
  standard-only).
- General Docker hygiene packet to address `docker` zone `target:
  ACCEPT`, exited containers, reclaimable images and build cache.
- Optional `wsdd` retention follow-up if Windows-side discovery becomes
  a stated need.
- MacBook `known_hosts` reconciliation for `fedora-top.home.arpa` so
  the `HostKeyAlias=192.168.0.206` workaround is no longer needed.

## Related

- [fedora-top-firewalld-narrowing-packet-2026-05-13.md](./fedora-top-firewalld-narrowing-packet-2026-05-13.md)
- [fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md)
- [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
