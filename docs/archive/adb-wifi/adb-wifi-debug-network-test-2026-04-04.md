---
title: ADB Wireless Debugging — Cross-Network Comparison
category: archive
component: adb_wifi_debug
date: 2026-04-04
captured_at: 2026-04-04T19:15:00-08:00
status: archived
device: Pixel 10 Pro XL (mustang)
serial: 57090DLCQ0016F
android: 16 (API 36)
host: verlyn's-mbp (macOS 15 Sequoia, Darwin 25.3.0, arm64)
prior_reports:
  - ./adb-wifi-debug-report.md
  - ./adb-wifi-debug-followup-2026-04-04.md
---


# ADB Wireless Debugging — Cross-Network Comparison

## Purpose

Determine whether the IPv4 ADB inbound failure observed on the home
network ("Bob's Internet" / OPNsense) is intrinsic to the Pixel or
Android 16, or specific to that network. Tested on a second, unrelated
network (university campus wired + WiFi).

## Key Finding

**The problem is specific to the home network. ADB over WiFi works
correctly on the work network over IPv4.**

All prior theories attributing the failure to Android 16 eBPF policy,
per-UID network restrictions, or adbd-specific behavior are falsified.
The Pixel accepts inbound IPv4 TCP to adbd and shell-owned listeners
without issue on a different network.

## Test Environment — Work Network

### Host (Mac)

- Initially wired via USB Ethernet adapter on `en9`: `137.229.236.154/26`
- Later switched to WiFi on `en0`: `10.147.160.16/21`
- Same ADB versions as prior reports (Homebrew v36.0.2, SDK v37.0.0)

### Device (Pixel)

- WiFi: `10.147.160.14/21`
- IPv6 link-local: `fe80::44f6:81ff:feea:499e/64` (no routable IPv6)
- Same Android 16 (API 36) build as home network tests

### Network

- University campus network
- Mac wired and Pixel WiFi initially on different subnets
  (`137.229.236.0/26` vs `10.147.160.0/21`) — traffic routed through
  infrastructure
- After Mac switched to WiFi, both on `10.147.160.0/21`
- Ping latency: ~215 ms (wired-to-WiFi cross-subnet), lower same-subnet

## Live Tests

### 1. ADB tcpip 5555 — IPv4 from Mac (wired) to Pixel (WiFi)

```sh
adb tcpip 5555
# waited 3 seconds for adbd restart
nc -z -w 3 10.147.160.14 5555
adb connect 10.147.160.14:5555
```

Results:

- `nc -z`: **succeeded** (port open)
- `adb connect 10.147.160.14:5555`: **connected**
- `adb -s 10.147.160.14:5555 shell 'echo test'`: **returned "test"**

### 2. Explicit IPv4 shell listener

```sh
adb shell 'toybox nc -4 -L -p 23470 echo ok >/dev/null 2>&1 &'
nc -z -w 3 10.147.160.14 23470
```

Results:

- `nc -z`: **succeeded** (port open)

### 3. Mac switched to WiFi (same subnet as Pixel)

```
Mac: 10.147.160.16/21
Pixel: 10.147.160.14/21
```

- WiFi ADB transport remained connected and functional
- `adb -s 10.147.160.14:5555 shell 'echo wifi-still-works'`: **succeeded**

### 4. Stability

Both USB and WiFi transports remained active and usable throughout
testing. No dropped connections, no `offline` transports, no protocol
errors.

## Comparison Table

| Test | Home Network (Bob's Internet) | Work Network (Campus) |
|------|-------------------------------|----------------------|
| Network | 192.168.0.0/24, OPNsense router | 10.147.160.0/21, campus infra |
| Mac-to-Pixel ICMP | Pass | Pass |
| Pixel-to-Mac ICMP | Pass | Not tested (not needed) |
| `adb tcpip 5555` IPv4 connect | **Refused** | **Works** |
| Shell listener IPv4 from Mac | **Refused** | **Works** |
| `adb tcpip 5555` IPv6 link-local | Works | Not tested (not needed) |
| WiFi ADB transport stability | Drops within seconds | Stable |
| `adb pair` (wireless debugging) | Protocol fault error | Not tested |
| Explicit `-4` shell listener | Refused from Mac, self-connect OK | Works from Mac |

## What This Rules Out

### Definitively ruled out

- **Android 16 eBPF/per-UID network policy blocking adbd over WiFi**:
  adbd accepts IPv4 inbound on the work network without issue.
- **Android 16 restricting `adb tcpip` as deprecated**: works fine.
- **Pixel hardware or firmware issue**: same device, same build, works.
- **ADB version mismatch (Homebrew v36 vs SDK v37)**: same ADB
  binaries used on both networks.
- **macOS firewall blocking ADB**: same Mac firewall config on both
  networks.

### Still open (home network only)

- **Why inbound IPv4 TCP to the Pixel is refused on the home LAN**:
  The failure is reproducible and specific to that network.
  Possible causes:
  1. **WiFi AP client isolation or filtering** — The home AP may filter
     certain inbound traffic between WiFi clients, even though both
     devices are on the same L2 segment. This could be selective
     (allowing established/known protocols like SSH but blocking
     unknown high ports).
  2. **OPNsense WiFi-specific rules or interface config** — If the AP
     is managed by OPNsense or traffic passes through it for WiFi
     clients, there may be interface-level filtering not captured in
     the exported `opt1` rules.
  3. **BSSID-specific behavior** — The `dumpsys adb` output from the
     home network showed multiple BSSIDs for "Bob's Internet." Roaming
     or BSSID-specific AP policies could affect connectivity.
  4. **ARP/MAC filtering on the home AP** — The AP might have rules
     filtering traffic by MAC address or port for WiFi clients
     specifically.

## Corrected Understanding

The original report (2026-04-04 initial) attributed the failure to
Android 16's network stack. The follow-up report narrowed the claim but
still treated it as a device-side issue. This cross-network test
confirms:

- The device and OS are not the cause.
- The home network infrastructure is the cause.
- The specific mechanism on the home network remains unidentified but
  is constrained to: something between the WiFi AP and the Pixel that
  selectively blocks inbound IPv4 TCP on non-standard ports from peer
  devices.

## Current Working State

- **USB ADB**: works on all networks
- **WiFi ADB over IPv4**: works on work network; blocked on home network
- **WiFi ADB over IPv6 link-local**: works on home network (workaround)
- **Recommended for home network**: Use IPv6 link-local as documented in
  the follow-up report:
  ```
  adb connect '[fe80::a025:5ff:fe37:172c%en0]:5555'
  ```

## Next Steps (Home Network Investigation)

1. Check home WiFi AP configuration for client isolation, port
   filtering, or traffic inspection settings.
2. If the AP is a separate device from OPNsense, check its admin panel
   directly.
3. If the AP is integrated with OPNsense, check the WiFi interface
   config (not just firewall rules).
4. Packet capture (`tcpdump -i en0`) on the Mac during a failed IPv4
   connect to see whether SYN packets leave the Mac and whether RST
   comes from the Pixel or is fabricated by the AP.
5. Test from a third device on the home WiFi to rule out Mac-specific
   AP behavior.
