---
title: Fedora Top firewalld Narrowing Packet - 2026-05-13
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, firewalld, hardening]
priority: high
---

# Fedora Top firewalld Narrowing Packet - 2026-05-13

This packet prepares a narrow change to the `FedoraWorkstation` firewalld
zone on `fedora-top`: remove the broad `1025-65535/tcp` and
`1025-65535/udp` port allowances and document the precise replacement
posture. SSH for `verlyn13` over the LAN remains reachable through the
zone's `ssh` service. No WAN exposure is introduced. The Docker zone is
intentionally left alone in this packet.

No live state was changed while preparing this document. All commands in
the "Apply" sections require explicit guardian approval and a fresh
held-open SSH session.

## Scope

In scope:

- `FedoraWorkstation` zone broad port allowances: remove
  `1025-65535/tcp` and `1025-65535/udp` (permanent + reload).
- Confirm no rich rule, direct rule, or NetworkManager
  `connection.zone` change is required to land this narrowing safely.
- Live verification that SSH for `verlyn13` over the LAN survives the
  change.

Out of scope (separate packets):

- `docker` zone `target: ACCEPT`. This packet documents the current
  Docker zone facts but does not propose changing them.
- SSH, sudoers/users/groups (already hardened/cleaned).
- Tailscale (currently logged out; if re-enabled later, a separate
  Tailscale decision packet should also re-open a stable
  WireGuard UDP port in `FedoraWorkstation`).
- WARP, `cloudflared`, Cloudflare DNS/Tunnel/Access/Gateway.
- OPNsense, ISC DHCP scopes, Unbound host overrides, NAT, HAProxy, WoL.
- LUKS, TPM, Secure Boot, firmware, power, reboot.
- 1Password items, vaults, fields.

## Verified Current Live State

Observed via SSH from the MacBook on `2026-05-13T22:06:12Z` using
`HostKeyAlias=192.168.0.206`. Read-only; no state changed.

### firewalld engine

```text
firewalld:        2.4.0
service state:    active, enabled (running since 2026-05-12 12:44:44 AKDT)
backend:          nftables
default zone:     FedoraWorkstation
LogDenied:        off
config file:      /etc/firewalld/firewalld.conf -> firewalld-workstation.conf
```

### Active zones (runtime)

```text
FedoraWorkstation (default)
  interfaces: wlp0s20f3
docker
  interfaces: docker0, br-02dbd2263acc, br-3830700d1415, br-391335bed81e,
              br-c3c9141380d2, br-d1c294f41258, br-f7751351cedc
```

### FedoraWorkstation (runtime and permanent are identical)

```text
target:                 default
ingress/egress priority: 0
icmp-block-inversion:   no
interfaces (runtime):   wlp0s20f3
sources:                (none)
services:               dhcpv6-client mdns samba-client ssh
ports:                  1025-65535/udp  1025-65535/tcp   <-- target of this packet
protocols:              (none)
forward:                yes
masquerade:             no
forward-ports:          (none)
source-ports:           (none)
icmp-blocks:            (none)
rich rules:             (none)
```

The runtime and permanent stanzas for `FedoraWorkstation` differ only in
the `active` flag and the `interfaces` field (NetworkManager attaches
`wlp0s20f3` at runtime). No content drift.

### docker zone (runtime and permanent)

```text
target:                 ACCEPT
ingress/egress priority: 0
icmp-block-inversion:   no
interfaces (runtime):   docker0, br-02dbd2263acc, br-3830700d1415,
                        br-391335bed81e, br-c3c9141380d2, br-d1c294f41258,
                        br-f7751351cedc
sources:                (none)
services:               (none)
ports:                  (none)
protocols:              (none)
forward:                yes
masquerade:             no
forward-ports:          (none)
source-ports:           (none)
icmp-blocks:            (none)
rich rules:             (none)
```

Docker manages its bridges at runtime; the permanent stanza is empty of
interfaces by design. `target: ACCEPT` is the upstream default Docker
posture and is **out of scope** for this packet.

### Rich rules and direct rules across all zones

```text
FedoraWorkstation rich rules: (none)
docker rich rules:            (none)
libvirt rich rules:           rule priority="32767" reject
                              (default behavior for unmanaged libvirt
                              zone; not touched)
nm-shared rich rules:         rule priority="32767" reject
                              (default behavior for NetworkManager
                              shared zone; not touched)
direct rules:                 (none)
direct passthroughs:          (none)
```

### NetworkManager `connection.zone`

```text
Bob's Internet (wlp0s20f3, 802-11-wireless)   connection.zone=<unset>
lo (loopback)                                 connection.zone=<unset>
docker0, br-*                                 connection.zone=<unset>
```

`connection.zone` is unset on every active connection, so firewalld
attaches each interface to the default zone (`FedoraWorkstation`) for
the Wi-Fi, and Docker handles its own bridges via the `docker` zone.
This packet does not need to touch any NetworkManager profile.

### Default route + LAN identity

```text
default via 192.168.0.1 dev wlp0s20f3 proto dhcp src 192.168.0.206 metric 600
```

Administration path stays inside the home LAN (no WAN exposure). HomeNetOps
confirms no port forward, NAT, or HAProxy frontend for this device.

### Active listeners with process names

`ss -tulpn` output filtered to one row per `(addr, port, proc)`. The
listeners that depend on the broad `1025-65535` port allowances are
flagged below; others are loopback-only or covered by an explicit
service.

```text
tcp 0.0.0.0:22         sshd                     ssh service (KEEP)
tcp [::]:22            sshd                     ssh service (KEEP)
tcp 0.0.0.0:5355       systemd-resolve          LLMNR (not in broad range; unaffected)
tcp [::]:5355          systemd-resolve          LLMNR (not in broad range; unaffected)
tcp 127.0.0.1:631      cupsd                    CUPS, loopback only (unaffected)
tcp [::1]:631          cupsd                    CUPS, loopback only (unaffected)
tcp 127.0.0.1:34739    containerd               loopback only (unaffected)
tcp 127.0.0.1:51493    cloud-drive-con          Synology Drive, loopback only
tcp 127.0.0.53%lo:53   systemd-resolve (stub)   loopback only (unaffected)
tcp 127.0.0.54:53      systemd-resolve          loopback only (unaffected)
udp 0.0.0.0:5353       avahi-daemon             mdns service (KEEP)
udp 0.0.0.0:5353       systemd-resolve          mdns service (KEEP)
udp 0.0.0.0:5355       systemd-resolve          LLMNR (not in broad range)
udp 127.0.0.1:323      chronyd                  loopback only
udp 127.0.0.53%lo:53   systemd-resolve (stub)   loopback only
udp 127.0.0.54:53      systemd-resolve          loopback only
udp 224.0.0.251:5353   chromium-browse          mdns service multicast (KEEP)

udp 0.0.0.0:41641      tailscaled               WireGuard ephemeral port
                                                <-- in 1025-65535 range
                                                <-- Tailscale currently
                                                LOGGED OUT (per prior
                                                reports)
udp 0.0.0.0:3702       wsdd                     WS-Discovery (Windows
                                                file-sharing service
                                                discovery)
                                                <-- in 1025-65535 range
udp *:41466, 48054, 35293, 40508, 41235, 42084, 44913, 48171, 51338, 51983
                       wsdd                     WS-Discovery client ephemeral
                                                <-- in 1025-65535 range
udp 172.{17..24}.0.1:3702
udp 192.168.0.206:3702 wsdd                     WS-Discovery on Wi-Fi LAN
                                                <-- in 1025-65535 range
udp 239.255.255.250:3702 (x3)
                       wsdd                     WS-Discovery multicast
                                                <-- in 1025-65535 range
```

In summary: removing `1025-65535/tcp,udp` from `FedoraWorkstation`
affects only `wsdd` (WS-Discovery for Windows file-sharing) and
`tailscaled` incoming UDP. Everything else is either covered by an
explicit service (`ssh`, `mdns`, `dhcpv6-client`, `samba-client`),
loopback-only, or not in the 1025-65535 range.

### sshd allowusers reminder

```text
allowusers verlyn13
```

Unchanged from the 2026-05-13 SSH hardening apply.

## Proposed Target State

| Field | Current | Proposed |
|---|---|---|
| `FedoraWorkstation` services | `dhcpv6-client mdns samba-client ssh` | `dhcpv6-client mdns samba-client ssh` |
| `FedoraWorkstation` ports    | `1025-65535/udp 1025-65535/tcp`      | **(none)** |
| `FedoraWorkstation` rich rules | (none) | (none) by default; see "Decisions Required" for an optional LAN source restriction on `ssh` |
| `wlp0s20f3` zone binding | `FedoraWorkstation` (via default) | `FedoraWorkstation` (unchanged) |
| `docker` zone | `target: ACCEPT`, 7 bridges | unchanged (out of scope) |
| Direct/passthrough rules | none | none |

Effective service set after this packet:

- SSH on `22/tcp` from any LAN source (publickey-only, `allowusers
  verlyn13`).
- mDNS responder/responses on `5353/udp` (Avahi and friends).
- DHCPv6 client for IPv6 SLAAC + DHCPv6.
- Samba client (allows responses from a Samba server when the laptop is
  the client).
- All LLMNR (`5355`) listening continues because it's below the
  removed range.

Behaviors that **stop working** after this packet (intended):

- **wsdd Windows file-sharing discovery (incoming on the LAN)**:
  `wsdd` binds `3702/udp` and several ephemeral high UDP ports. After
  this packet, those listeners cease to accept LAN traffic. Outbound
  mounting/browsing from the laptop to other SMB hosts is unaffected
  because outbound traffic is not restricted. If the laptop needs to be
  *discovered* by Windows hosts (rare on this network), a follow-up
  packet would add specific permissive rules.
- **Tailscale incoming UDP on its random WireGuard ephemeral port**:
  irrelevant today because `tailscaled` is logged out, but it should
  be revisited when the Tailscale retain/remove decision is made. The
  packet flags it as a coordination point with the future
  Tailscale/WARP/Cloudflare packet.

Behaviors that **continue to work**:

- SSH from any LAN host using `verlyn13` publickey.
- mDNS-based discovery (Bonjour, Avahi) - covered by the `mdns`
  service.
- DHCPv6 client.
- LLMNR (uses `5355` which is below the removed range).
- Loopback services (CUPS, chronyd, systemd-resolve stub, containerd,
  Synology Drive bridge).
- Browser-driven mDNS (Chromium on multicast `5353`).
- All outbound connectivity.
- Docker container networking (separate `docker` zone, not touched).
- All host SSH/SMB-client functions where the laptop is the client.

## Decisions Required From Guardian

The packet uses conservative defaults for each. Override in the approval
phrase if needed.

1. **LAN source restriction on `ssh` (optional defense in depth)**
   - Default: do **not** add. The current `ssh` service rule already
     accepts only publickey, `allowusers verlyn13`, and the host has no
     WAN exposure (HomeNetOps confirmed). Adding a rich rule that
     restricts source to `192.168.0.0/24` adds defense in depth but
     also breaks future LAN renumbering or temporary VPN access. The
     existing posture is acceptable.
   - Alternative: replace `services: ssh` with rich rule
     `rule family=ipv4 source address=192.168.0.0/24 service name=ssh
     accept` (and remove the `ssh` service so the rich rule is the only
     SSH path). Document the LAN subnet decision in the apply record if
     chosen.

2. **wsdd retention**
   - Default: remove with the broad port range. Operator has historically
     used the laptop alongside Windows hosts (per the onboarding doc),
     but the laptop being *discovered* by Windows boxes is not in the
     stated administration model.
   - Alternative: add a follow-up packet to expose `3702/udp` (and the
     ephemeral wsdd port range if needed) via explicit rules. Decide
     when there is a concrete need.

3. **Tailscale future-port coordination**
   - Tailscale is currently logged out. The retain/remove decision is a
     separate packet. If Tailscale is retained, that packet should add a
     stable WireGuard UDP port to `FedoraWorkstation` (or use
     `tailscale --tun=...` operating behind the firewall, which the
     Tailscale client already handles by falling back to a DERP relay).
     This packet does NOT pre-open a port for Tailscale.

## Apply Commands

Apply only after explicit guardian approval. Use the same SSH options
documented in the SSH hardening packet, including
`HostKeyAlias=192.168.0.206` until MacBook `known_hosts` is reconciled.

### Held-Open Control Session

Open before any change:

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

### Snapshot pre-apply firewalld state

```bash
sudo -n bash <<'EOF'
set -euo pipefail
SNAP="/var/backups/jefahnierocks-firewalld-narrowing-$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 0700 -o root -g root "$SNAP"

firewall-cmd --state                               > "$SNAP/state.txt"
firewall-cmd --get-default-zone                   > "$SNAP/default-zone.txt"
firewall-cmd --get-active-zones                   > "$SNAP/active-zones.txt"
firewall-cmd --list-all-zones                     > "$SNAP/zones-runtime.txt"
firewall-cmd --permanent --list-all-zones         > "$SNAP/zones-permanent.txt"
firewall-cmd --direct --get-all-rules             > "$SNAP/direct-rules.txt"
firewall-cmd --direct --get-all-passthroughs      > "$SNAP/direct-passthroughs.txt"

# Optional XML backup (firewalld stores per-zone XML under /etc/firewalld/zones/).
# Only stock zones may exist there; copy whatever is present.
install -d -m 0700 -o root -g root "$SNAP/zones-xml"
if compgen -G "/etc/firewalld/zones/*.xml" > /dev/null; then
  cp -a /etc/firewalld/zones/*.xml "$SNAP/zones-xml/"
fi

ss -tulpnH > "$SNAP/listeners-before.txt"

( cd "$SNAP" && sha256sum -- *.txt zones-xml/*.xml > manifest.sha256 2>/dev/null || \
                  sha256sum -- *.txt > manifest.sha256 )

echo "snapshot_path=$SNAP"
ls -la "$SNAP"
EOF
```

Record the printed `snapshot_path=...` value.

### Remove broad port ranges (permanent + reload)

```bash
sudo -n bash <<'EOF'
set -euo pipefail
echo "--- pre-apply listing ---"
firewall-cmd --zone=FedoraWorkstation --list-ports
firewall-cmd --permanent --zone=FedoraWorkstation --list-ports

echo "--- remove 1025-65535/tcp (permanent) ---"
firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/tcp

echo "--- remove 1025-65535/udp (permanent) ---"
firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/udp

echo "--- reload ---"
firewall-cmd --reload

echo "--- post-reload zone state ---"
firewall-cmd --zone=FedoraWorkstation --list-all
EOF
```

The order is "permanent change first, then reload". This avoids leaving a
runtime-only delta between firewalld restarts.

## Validation

Validation runs from a fresh SSH process while the held-open session
remains open. All checks must pass before closing the held-open session.

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n bash -s' <<'EOF'
set -u
echo "===== TIMESTAMP ====="
date -u +%Y-%m-%dT%H:%M:%SZ

echo "===== FedoraWorkstation (runtime) ====="
firewall-cmd --zone=FedoraWorkstation --list-all

echo "===== FedoraWorkstation (permanent) ====="
firewall-cmd --permanent --zone=FedoraWorkstation --list-all

echo "===== ports must be empty in both ====="
firewall-cmd --zone=FedoraWorkstation --list-ports          | xargs -r echo "runtime ports:"
firewall-cmd --permanent --zone=FedoraWorkstation --list-ports | xargs -r echo "permanent ports:"

echo "===== services must still include ssh, mdns, dhcpv6-client, samba-client ====="
firewall-cmd --zone=FedoraWorkstation --list-services
firewall-cmd --permanent --zone=FedoraWorkstation --list-services

echo "===== active zones still have wlp0s20f3 in FedoraWorkstation ====="
firewall-cmd --get-active-zones

echo "===== runtime-vs-permanent diff (only 'active'/interfaces lines expected) ====="
diff <(firewall-cmd --list-all-zones) <(firewall-cmd --permanent --list-all-zones) | head -40 || true

echo "===== docker zone untouched ====="
firewall-cmd --zone=docker --list-all

echo "===== rich rules (must remain empty on FedoraWorkstation) ====="
firewall-cmd --zone=FedoraWorkstation --list-rich-rules
firewall-cmd --permanent --zone=FedoraWorkstation --list-rich-rules

echo "===== sshd allowusers (sanity, must remain verlyn13) ====="
sshd -T 2>/dev/null | grep -E '^allowusers '

echo "===== listeners that should NO LONGER appear reachable from LAN ====="
ss -tulpnH | awk '
  /:3702 / || /tailscaled/ {print}
'

echo "===== END ====="
EOF
```

A second positive check from the MacBook confirms SSH still works:

```bash
nc -vz -G 3 fedora-top.home.arpa 22
ssh ... verlyn13@fedora-top.home.arpa 'hostname; whoami; sudo -n true && echo verlyn13_sudo_n=ok'
```

Expected results:

```text
runtime ports:    (empty)
permanent ports:  (empty)
services:         dhcpv6-client mdns samba-client ssh    (unchanged)
active zones:     FedoraWorkstation on wlp0s20f3 (still default)
docker zone:      still target=ACCEPT, 7 bridges (untouched)
rich rules:       empty (unless guardian opted into LAN source restriction)
sshd allowusers:  verlyn13 (untouched)
nc -vz:           succeeds (SSH reachable)
remote whoami:    verlyn13
sudo -n true:     ok
```

A negative-side observation will also be visible after the apply:
`ss -tulpn` will still SHOW `wsdd` and `tailscaled` binding to their
ephemeral ports (that's a userspace process binding, the kernel allows
the bind itself); what changes is that firewalld will now drop external
packets to those ports. Tests from another LAN host (e.g., MacBook):

```bash
nc -vz -G 3 fedora-top.home.arpa 3702
# expected: connection refused or timeout (firewalld blocks)
```

## Rollback

Use the held-open session if SSH from a fresh session fails after the
reload. Quick rollback:

```bash
sudo -n bash <<'EOF'
set -euo pipefail
firewall-cmd --permanent --zone=FedoraWorkstation --add-port=1025-65535/tcp
firewall-cmd --permanent --zone=FedoraWorkstation --add-port=1025-65535/udp
firewall-cmd --reload
firewall-cmd --zone=FedoraWorkstation --list-all
EOF
```

If a deeper rollback is needed, the pre-apply snapshot can restore the
XML zone definitions:

```bash
sudo -n bash <<'EOF'
set -euo pipefail
SNAP="<snapshot-path>"
# Restore zone XML if anything got modified
for f in "$SNAP"/zones-xml/*.xml; do
  [ -f "$f" ] || continue
  install -m 0640 -o root -g firewalld "$f" "/etc/firewalld/zones/$(basename "$f")"
done
firewall-cmd --reload
firewall-cmd --zone=FedoraWorkstation --list-all
EOF
```

The `firewalld` group owns `/etc/firewalld/zones/*.xml`; install with
`-g firewalld` to match the on-disk owner that ships with the package
on Fedora 44. If `firewalld` group is not present, fall back to
`root:root` and `firewall-cmd --reload` will still pick the files up.

If SSH is irrecoverable through the LAN after both rollbacks, fall back
to the held-open session and use that channel to repair. Volume-style
data destruction is **not** a concern in this packet because nothing
was destroyed - firewalld port deltas are fully reversible.

## Risks

- **wsdd Windows file-sharing discovery breaks**: described above. This
  is intentional and aligned with operator policy. Restore is a
  follow-up packet.
- **Tailscale (when re-enabled) loses direct UDP path**: described
  above. Today Tailscale is logged out; this packet does not affect
  current behavior. The Tailscale retain/remove packet should address
  the WireGuard port either by opening a known port in
  `FedoraWorkstation` or by accepting DERP-relay-only performance.
- **No SSH lockout risk**: the packet keeps the `ssh` service intact
  in `FedoraWorkstation` and does not change `sshd` config. The
  held-open session plus the snapshot-backed rollback provide two
  independent recovery paths.
- **No effect on Docker, container networking, or LAN-internal Docker
  service exposure**: Docker zone is not touched. The previously
  Docker-published Infisical/Redis listeners are already gone per the
  retirement apply.
- **NetworkManager re-attach**: after `firewall-cmd --reload`,
  NetworkManager re-attaches `wlp0s20f3` to the default zone
  (`FedoraWorkstation`) because `connection.zone` is unset. No
  intervention needed.
- **`docker` zone still `target: ACCEPT`**: this remains a known posture
  defect, called out for a future Docker hygiene packet. The current
  Docker bridges have no LAN-published service after the
  Infisical/Redis retirement, so the broad `ACCEPT` on the Docker zone
  affects only inter-container traffic.
- **wsdd may auto-restart and re-bind**: that is fine; the binding
  itself is permitted, but inbound traffic from the LAN to those
  bindings is dropped by firewalld.
- **mDNS-driven SMB/Bonjour browsing the laptop performs as a client**
  is unaffected: outbound traffic and reply paths are not restricted by
  these zone changes.

## Required Approval Phrase

Live apply requires guardian approval substantially equivalent to:

```text
I approve applying the Fedora firewalld narrowing packet live now:
snapshot the pre-apply firewalld state and listeners to
/var/backups/jefahnierocks-firewalld-narrowing-<timestamp>;
firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/tcp;
firewall-cmd --permanent --zone=FedoraWorkstation --remove-port=1025-65535/udp;
firewall-cmd --reload; verify runtime and permanent ports are empty,
services unchanged (dhcpv6-client, mdns, samba-client, ssh), active
zone bindings unchanged, no rich rules, docker zone untouched,
sshd allowusers verlyn13 unchanged, and SSH from a fresh MacBook
session still succeeds; rollback by re-adding the two port ranges if
verification fails. Do not touch the docker zone, SSH config,
sudoers/users/groups, Tailscale, WARP, cloudflared, Cloudflare,
OPNsense, DNS, DHCP, LUKS, power, reboot, or 1Password.
```

Amend the phrase if the guardian opts into the LAN source restriction
on `ssh` (decision 1) or wants a specific port preserved.

## Evidence To Record After Apply

```text
timestamp:
operator:
held-open session used:
snapshot path:
firewall-cmd --reload result:
FedoraWorkstation runtime ports (must be empty):
FedoraWorkstation permanent ports (must be empty):
FedoraWorkstation services (must remain dhcpv6-client mdns samba-client ssh):
active zones (must remain FedoraWorkstation on wlp0s20f3 + docker):
docker zone state (must be unchanged):
rich rules (must remain empty on FedoraWorkstation):
sshd allowusers (must remain verlyn13):
ssh from fresh MacBook session: pass/fail
negative wsdd reachability check from MacBook (3702/udp): pass/fail
rollback used: yes/no
remaining blockers:
```

Do not copy private keys, passwords, the held-open SSH session's
control characters, or raw audit logs containing secrets into the repo.

## Related

- [fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md)
- [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md)
- [fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
