---
title: MAMAWORK HomeNetOps LAN Identity Hand-Back - 2026-05-14
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, homenetops, opnsense, dhcp, dns, ssh, ingest]
priority: high
---

# MAMAWORK HomeNetOps LAN Identity Hand-Back - 2026-05-14

This record ingests the HomeNetOps hand-back for `MAMAWORK` static LAN
identity in response to the outbound request at
[handback-request-homenetops-2026-05-13.md](./handback-request-homenetops-2026-05-13.md).

No `system-config` live network, host, firewall, Cloudflare,
Tailscale, or 1Password change was made by this ingest. The
HomeNetOps packet completed LAN-only DHCP/DNS work in the HomeNetOps /
OPNsense authority surface.

## Source

Hand-back source: operator-provided HomeNetOps report relayed
2026-05-14. The hand-back is from the HomeNetOps repo
(`~/Repos/verlyn13/HomeNetOps`); commit SHA was not included in the
relay and is requested in any follow-up handback. Mirrors the prior
[fedora-top-homenetops-lan-identity-2026-05-13.md](./fedora-top-homenetops-lan-identity-2026-05-13.md)
ingest pattern.

## Result Summary

```text
homenetops-scope:  PASS
appliance:         OPNsense; static DHCP reservation bound;
                   Unbound host override present.
device:            MAMAWORK
owner:             Jefahnierocks
mac_wired:         b0:41:6f:0e:b7:b6
ip:                192.168.0.101  (LAN/igc1 ARP confirmed
                                   192.168.0.101 <-> b0:41:6f:0e:b7:b6)
fqdn:              mamawork.home.arpa
ssh:               22/tcp times out from fedora-top across LAN.
                   This is a Windows-side issue, not a HomeNetOps
                   gate; OPNsense is not blocking same-subnet
                   TCP/22.
icmp-echo:         loss is not authoritative because Windows ICMP
                   default may drop echo replies.
arp-permanent:     false on the LAN/igc1 binding because MAMAWORK
                   is currently using a host-side static IP,
                   which means ISC's static-ARP defense layer
                   does not activate.
wol:               not registered in OPNsense for MAMAWORK in
                   this packet (matches the original request).
```

## Verification (HomeNetOps-reported)

```text
$ dig @192.168.0.1 mamawork.home.arpa +short
192.168.0.101

$ dig mamawork.home.arpa +short
192.168.0.101

$ nc -vz -G 3 mamawork.home.arpa 22
(timeout)

$ nc -vz -G 3 192.168.0.101 22
(timeout)
```

The TCP/22 timeouts are repeatable from `fedora-top` over LAN. They
fail at the MAMAWORK end, not at OPNsense or at any LAN-layer
device. The next packet that addresses this is the Windows-side SSH
investigation packet, not a HomeNetOps change.

## Exposure Confirmation

HomeNetOps reported no exposure changes:

- no WAN port forward, NAT, or HAProxy frontend for MAMAWORK
- no public DNS record
- no Cloudflare Tunnel, WARP, Access, or Gateway change
- no Tailscale enrollment or DNS change
- no OPNsense firewall rule change beyond the static reservation +
  Unbound override
- no WoL-from-WAN configuration

Remote administration for MAMAWORK remains LAN / private-path only.

## ARP-Permanent And Host-Static vs DHCP

The OPNsense static reservation exists but `arp permanent=false`
because MAMAWORK currently assigns `192.168.0.101` from the Windows
side (manual static config), not from the OPNsense ISC DHCP server.
The reservation is therefore advisory until the host actually
DHCP-leases the address.

Implications:

- **Today** the host-side static IP still works. DNS, ARP, and LAN
  routing are all consistent for everyday use.
- **The OPNsense ISC static-ARP defense layer does not activate** in
  this state. That layer normally hardens the L2 binding so a rogue
  host on the same LAN cannot impersonate `192.168.0.101`. The
  defense is only effective when OPNsense itself issued the address.
- **Long-term preferred correction**: switch MAMAWORK from
  host-side static to DHCP so OPNsense owns the source of truth for
  the address. That switch is a Windows-side change with a small
  reconnect risk, and belongs in its own packet -
  [mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md) -
  separate from any SSH remediation packet so connectivity
  disruptions are not bundled.

## Hand-Back Values For system-config

```text
device:    MAMAWORK
owner:     Jefahnierocks
mac_wired: b0:41:6f:0e:b7:b6
ip:        192.168.0.101
fqdn:      mamawork.home.arpa
ssh:       22/tcp - Windows-side block; LAN-only, no WAN exposure
wol:       not registered
notes:     OPNsense reservation present; ARP permanent=false until
           MAMAWORK switches to DHCP; same-subnet routing PASS;
           TCP/22 timeout is a host-side investigation target.
```

## Related

- [handback-request-homenetops-2026-05-13.md](./handback-request-homenetops-2026-05-13.md)
- [fedora-top-homenetops-lan-identity-2026-05-13.md](./fedora-top-homenetops-lan-identity-2026-05-13.md) -
  the precedent pattern for HomeNetOps LAN identity ingest.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md) -
  the planned Windows-side SSH packet that consumes this PASS.
- [mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md) -
  the optional planned packet that addresses the host-static vs
  DHCP source-of-truth question.
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)
