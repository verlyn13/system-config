---
title: Fedora Top HomeNetOps LAN Identity Hand-Back - 2026-05-13
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, homenetops, opnsense, dhcp, dns, ssh]
priority: high
---

# Fedora Top HomeNetOps LAN Identity Hand-Back - 2026-05-13

This record ingests the HomeNetOps hand-back for `fedora-top` static LAN
identity.

No `system-config` live network, provider, firewall, WARP, Tailscale, or
1Password changes were made by this ingest. The HomeNetOps packet completed
LAN-only DHCP/DNS work in the HomeNetOps/OPNsense authority surface.

## Source

Hand-back source: operator-provided HomeNetOps report in chat on 2026-05-13.

HomeNetOps repo state reported by the operator:

- Repo: `/Users/verlyn13/Repos/verlyn13/HomeNetOps`
- Branch: `main`
- Status: dirty, with prior handoff work plus this Fedora DNS edit uncommitted
- Directive diff: `opnsense/spec/dns/unbound.yaml` added
  `fedora-top.home.arpa` host override under Core Infrastructure

This record does not claim the HomeNetOps repo changes are committed or pushed.

## Network Result

| Field | Value |
|---|---|
| Device | `fedora-top` |
| Owner | Jefahnierocks |
| Interface | Wi-Fi |
| Wi-Fi MAC | `66:b5:8c:f5:45:74` |
| Static IP | `192.168.0.206` |
| FQDN | `fedora-top.home.arpa` |
| DHCP mechanism | OPNsense ISC DHCPv4 static reservation |
| DNS mechanism | OPNsense Unbound host override |
| Unbound host override UUID | `ce8c9be1-7b03-4965-8f40-d3adc8a079ac` |
| SSH liveness target | `fedora-top.home.arpa:22` |
| WoL | Not configured; Wi-Fi laptop, no HomeNetOps policy for this device class |

The DHCP static mapping was already in place and required no change in this
packet. Live lease reported by HomeNetOps:

```json
{
  "mac": "66:b5:8c:f5:45:74",
  "address": "192.168.0.206",
  "hostname": "fedora-top",
  "type": "static",
  "status": "online",
  "state": "active",
  "if_descr": "LAN",
  "starts": "",
  "ends": ""
}
```

HomeNetOps reported the static DHCP spec entry already exists at:

```text
opnsense/spec/dhcp/scopes.yaml:57-62
```

## Verification

HomeNetOps reported these LAN verification results:

```text
$ dig @192.168.0.1 fedora-top.home.arpa +short
192.168.0.206

$ dig fedora-top.home.arpa +short
192.168.0.206

$ nc -vz -G 3 fedora-top.home.arpa 22
Connection to fedora-top.home.arpa port 22 [tcp/ssh] succeeded!

$ nc -vz -G 3 192.168.0.206 22
Connection to 192.168.0.206 port 22 [tcp/ssh] succeeded!

$ ping -c 2 fedora-top.home.arpa
2 packets transmitted, 2 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 4.842/95.818/186.794/90.976 ms
```

Ping is expected to work because Fedora Linux responds to ICMP echo by default.
SSH TCP reachability through the FQDN remains the authoritative liveness check
for administration.

## Exposure Confirmation

HomeNetOps reported no exposure changes:

- no WAN port forward, NAT, or HAProxy frontend
- no public DNS
- no Cloudflare Tunnel, WARP, Access, or Gateway changes
- no Tailscale enrollment or DNS changes
- no OPNsense firewall rule changes
- no Wi-Fi WoL configuration

Remote administration remains LAN/private-path only.

## Kea Transition Note

HomeNetOps reported ISC `dhcpd` remains the active DHCP server for the LAN
scope `192.168.0.10-245`.

Kea is staged in a config skeleton, but the plugin is not installed. No Kea
migration was performed in this packet.

When formal Jefahnierocks management migrates DHCP to Kea, the
`fedora-top` and `desktop-2jj3187` reservations should migrate as part of that
change. HomeNetOps notes Kea exposes reservation REST APIs under
`/api/kea/dhcpv4/reservation/*`, enabling future spec-apply for DHCP.

This is a future-state note only.

## Hand-Back Values For System-Config

```text
device:    fedora-top
owner:     Jefahnierocks
mac_wifi:  66:b5:8c:f5:45:74
ip:        192.168.0.206
fqdn:      fedora-top.home.arpa
ssh:       22/tcp - LAN-only; no OPNsense firewall rule added
wol:       not configured
notes:     no WAN exposure, no public DNS, no Cloudflare/WARP/Tailscale changes
```
