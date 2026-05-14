---
title: Outbound Handback Request - HomeNetOps - 2026-05-13
category: operations
component: device_admin
status: outbound-request
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, homenetops, opnsense, dhcp, dns, wol, handback-request]
priority: high
---

# Outbound Handback Request - HomeNetOps - 2026-05-13

This document is a **request** from `system-config` to HomeNetOps
(`~/Repos/verlyn13/HomeNetOps`). It is not a directive and does not
authorize any change. It contains two items: a small posture
confirmation for `fedora-top` (no new HomeNetOps rule requested), and
a new static-DHCP + local-DNS request for `MAMAWORK`.

HomeNetOps remains the sole authority for OPNsense, ISC DHCP, Unbound
DNS, NAT, HAProxy, WoL registration, router/firewall state, and any
LAN policy. No HomeNetOps-side assertion in `system-config` is
authoritative until a HomeNetOps handback supplies it.

## Item 1 - Fedora Top Posture Confirmation (no rule change requested)

The
[`fedora-top-remote-admin-routing-design-2026-05-13.md`](./fedora-top-remote-admin-routing-design-2026-05-13.md)
packet records that **no new HomeNetOps work is required** to land the
Cloudflare-side cutover later. This request asks HomeNetOps to confirm
that the current LAN posture supports both paths:

```text
- OPNsense egress permits outbound TCP/443 from 192.168.0.206
  (cloudflared, when later installed on fedora-top)
- OPNsense egress permits outbound TCP/443 from the MacBook
  192.168.0.<MacBook-IP> (WARP, when later installed)
- The LAN admin path remains intact:
    fedora-top.home.arpa Unbound override -> 192.168.0.206 still
    serves the LAN;
    TCP/22 to fedora-top.home.arpa from the LAN remains reachable
    after the firewalld narrowing applied on 2026-05-13.
- No new HomeNetOps rule is requested for fedora-top by this packet.
- No WAN exposure, no port forward, no HAProxy frontend, no public
  DNS for fedora-top.
```

A short confirmation reply ("posture unchanged; outbound TCP/443 is
permitted by default; LAN path verified intact") is enough.

## Item 2 - MAMAWORK Static-DHCP + Local-DNS Request

`MAMAWORK` (Windows 11 Pro 25H2 mini-PC) currently runs with a
**host-side static IP**. There is no OPNsense reservation. Adding the
reservation gives the household fleet a stable, conflict-safe address
and gives `fedora-top` a stable FQDN to SSH to.

### Non-secret facts to bind

```text
Device:                MAMAWORK
Owner:                 Jefahnierocks
Role:                  secondary dev + kids' learning workstation
                       (primary dev is fedora-top)
OS:                    Windows 11 Pro 25H2 (build 10.0.26200.8457)
Wired MAC:             B0-41-6F-0E-B7-B6   <-- preferred admin path
Wi-Fi MAC:             48-AD-9A-82-15-81   (Intel AX200; disconnected
                                            at intake time)
Current LAN IP:        192.168.0.101/24    (host-side static today)
Current gateway:       192.168.0.1
Current DNS:           8.8.8.8, 8.8.4.4    (host-side manual)
Connection DNS suffix: home.arpa
Network category:      Private (Windows-side)
Default route:         single path, Ethernet 2 -> 192.168.0.1
                       (no VPN/tunnel default route)
SSH (LAN admin path):  22/tcp reachable on the LAN today
                       (no WAN exposure)
```

The same MAC has been seen on the LAN as an active 1 Gbps Ethernet
client during the 2026-05-13 elevated intake (see
[`windows-pc-mamawork.md`](./windows-pc-mamawork.md) section "Network
Identity"). This is not a Wi-Fi laptop; the wired NIC is the primary
admin path.

### What is being asked

Mirrors the 2026-05-13
[`fedora-top-homenetops-lan-identity-2026-05-13.md`](./fedora-top-homenetops-lan-identity-2026-05-13.md)
pattern:

```text
1. Add an OPNsense ISC DHCPv4 static reservation:
     Interface: LAN
     MAC:       B0-41-6F-0E-B7-B6
     IP:        192.168.0.101
     Hostname:  mamawork
     Description: Jefahnierocks-owned MAMAWORK mini-PC

   When Kea replaces ISC dhcpd, this reservation should migrate
   alongside the fedora-top and desktop-2jj3187 reservations.

2. Add an Unbound host override under Core Infrastructure:
     Host:       mamawork
     Domain:     home.arpa
     IP:         192.168.0.101

3. Verify LAN-side:
     dig @192.168.0.1 mamawork.home.arpa +short   -> 192.168.0.101
     dig          mamawork.home.arpa +short      -> 192.168.0.101
     nc -vz -G 3 mamawork.home.arpa 22            -> succeeded

   ICMP echo may or may not return depending on Windows firewall
   posture; do not depend on ping for liveness. TCP/22 is the
   authoritative liveness check from the LAN side.

4. No firewall, NAT, HAProxy, public DNS, WAN port-forward, Cloudflare,
   Tailscale, WARP, cloudflared, or WoL-from-WAN change is requested.

5. No WoL registration is requested for MAMAWORK yet. WoL armed on
   the NIC (Magic Packet, Pattern Match, Shutdown WoL all enabled)
   is acknowledged in the device record; whether to register the
   host with OPNsense `os-wol` is a later decision once the
   stay-awake-vs-WoL-wakeup posture (Q5 in the operator-questions
   list in handoff-mamawork.md) is resolved.
```

### Repo-side facts to return

A handback in
[`handback-format.md`](./handback-format.md) style is preferred. The
fields `system-config` will use are:

```text
- HomeNetOps repo commit SHA that lands the reservation + Unbound entry
- The Unbound host-override UUID (so the device record can cite it
  the way the fedora-top record cites
  ce8c9be1-7b03-4965-8f40-d3adc8a079ac)
- Verification results from steps 3 above
- Explicit confirmation: no WAN, no public DNS, no Cloudflare/WARP/
  Tailscale, no firewall rule, no HAProxy, no WoL-from-WAN change
- Confirmation that Kea-migration plans still cover this MAC when
  the migration happens
```

## Stop Rules For This Request

- Do not change OPNsense WAN, NAT, HAProxy, or public-DNS state.
- Do not add any Cloudflare or Tailscale binding for MAMAWORK as
  part of this work; those decisions live elsewhere.
- Do not assume `system-config` will take ownership of any
  HomeNetOps surface in response to the reply; ownership stays in
  HomeNetOps.
- Do not ingest this request as a directive; treat it as one repo
  asking another to extend an existing static-DHCP + local-DNS
  pattern.
- Do not paste Wi-Fi PSKs, OPNsense admin credentials, API tokens,
  or any other secret value into the reply. Posture facts and
  non-secret identifiers (MAC, IP, UUID, commit SHA) only.

## Related

- [`fedora-top-remote-admin-routing-design-2026-05-13.md`](./fedora-top-remote-admin-routing-design-2026-05-13.md)
- [`fedora-top-homenetops-lan-identity-2026-05-13.md`](./fedora-top-homenetops-lan-identity-2026-05-13.md) -
  the pattern this MAMAWORK request mirrors.
- [`windows-pc-mamawork.md`](./windows-pc-mamawork.md)
- [`handoff-mamawork.md`](./handoff-mamawork.md)
- [`current-status.yaml`](./current-status.yaml)
- [`handback-format.md`](./handback-format.md)
- [`../secrets.md`](../secrets.md)
