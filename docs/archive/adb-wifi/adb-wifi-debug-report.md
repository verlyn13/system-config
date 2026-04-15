---
title: ADB Wireless Debugging — Diagnostic Report
category: archive
component: adb_wifi_debug
date: 2026-04-04
status: archived
device: Pixel 10 Pro XL (mustang)
serial: 57090DLCQ0016F
android: 16 (API 36)
host: verlyn's-mbp (macOS 15 Sequoia, Darwin 25.3.0, arm64)
---

# ADB Wireless Debugging — Diagnostic Report

## Summary

USB debugging works. `adb tcpip 5555` also works, but the behavior is not
"wireless ADB is broken" or "Android 16 blocks adbd on WiFi" as previously
stated.

What is confirmed:

- The Pixel advertises ADB services over mDNS and listens on TCP `5555`
  and the wireless-debugging TLS port.
- IPv4 connections from the Mac to `192.168.0.11:5555` and
  `192.168.0.11:34661` are refused.
- IPv6 link-local connections to the same ADB ports succeed.
- `adb connect '[fe80::a025:5ff:fe37:172c%en0]:5555'` succeeds and creates a
  working network transport.

The actual confirmed problem is narrower: the ADB listeners are reachable
over IPv6 link-local on this LAN, but not over the device's IPv4 address.
The prior report overclaimed a Pixel-side TCP block and an Android 16
eBPF/per-UID policy cause; that is not supported by the evidence below.

## Core Truth

This is the shortest defensible statement of the problem as of 2026-04-04:

- USB ADB works.
- ADB over WiFi also works if the Mac connects to the Pixel's IPv6
  link-local address.
- The failure is specific to IPv4 access to the Pixel's ADB listeners on
  this LAN.
- Same-LAN traffic between `192.168.0.10` and `192.168.0.11` is direct L2
  traffic, not traffic routed through OPNsense.
- In the HomeNetOps design, Cloudflare is a public DNS / ACME control-plane
  component, not a dataplane component for local host-to-host traffic.
- Therefore Cloudflare and the documented OPNsense DNS/firewall setup are
  currently excluded as primary causes of the ADB failure.

## Environment

### Host (Mac)

- macOS 15 Sequoia (Darwin 25.3.0, arm64)
- WiFi interface: en0, IP 192.168.0.10/24 (static)
- ADB (Homebrew): v36.0.2 at `/opt/homebrew/bin/adb` (symlink to Caskroom)
- ADB (SDK): v37.0.0 at `~/Library/Android/sdk/platform-tools/adb`
- Android Studio installed at `/Applications/Android Studio.app`
- Android Studio Preview installed at `/Applications/Android Studio Preview.app`
- macOS Application Firewall: enabled; ADB listed as "Allow incoming connections"
- PF firewall: default macOS anchors only, no custom rules
- `ANDROID_HOME` was not exported in any shell (fixed during this session, not yet applied via chezmoi)

### Device (Pixel)

- Pixel 10 Pro XL, codename `mustang`
- Android 16, API level 36
- WiFi: connected to "Bob's Internet" (5 GHz, Wi-Fi 6 / 802.11ax), IP 192.168.0.11/24 (static)
- RSSI: -54, link speed 390 Mbps
- USB debugging: authorized for this Mac's key
- Wireless debugging (`adb_wifi_enabled`): 1 (enabled)
- No VPN interfaces active (Warp disabled on both devices)
- No Tailscale active on either device

### Network

- Router: OPNsense at 192.168.0.1
- Both devices on same 192.168.0.0/24 subnet, same L2 segment
- ARP resolution: direct (Mac resolves Pixel MAC `e4:38:83:86:01:05` on en0; Pixel resolves Mac MAC `60:3e:5f:89:eb:e0` on wlan0)
- Traceroute: 1 hop (no router in path)
- Traffic between .10 and .11 does NOT traverse OPNsense firewall
- OPNsense exported rules are all on `opt1` (Tailscale interface), with many duplicates from prior agent runs; no LAN rules in export

## Confirmed Connectivity

| Test | Direction | Result |
|------|-----------|--------|
| ICMP ping | Mac → Pixel | Pass (3-55 ms) |
| ICMP ping | Pixel → Mac | Pass (11 ms) |
| TCP port 5555 (adbd) over IPv4 | Mac → Pixel | **Refused** |
| TCP port 34661 (wireless debug TLS) over IPv4 | Mac → Pixel | **Refused** |
| TCP port 5555 (adbd) over IPv6 link-local | Mac → Pixel | Pass |
| TCP port 34661 (wireless debug TLS) over IPv6 link-local | Mac → Pixel | Pass |
| TCP port 23456 (throwaway shell listener) over IPv4 | Mac → Pixel | Pass |
| Raw TCP to Mac listener on port 19998 | Pixel shell → Mac | Pass |
| ADB over USB | USB | Works, authorized |
| ADB over WiFi (`adb connect` to IPv6 link-local) | WiFi | Works |

## HomeNetOps / Cloudflare / OPNsense Findings

### Repo-Backed Architecture Facts

From the HomeNetOps repository:

- `opnsense/docs/02-operations/ROUTING_AND_ACCESS_STRATEGY.md` states:
  "Cloudflare DNS (Public): Used ONLY for ACME DNS-01 challenges, NOT for
  service resolution."
- `opnsense/spec/dns/unbound.yaml` defines split-horizon DNS through
  OPNsense Unbound for internal LAN and Tailscale name resolution.
- `opnsense/spec/firewall/ruleset.yaml` defines Cloudflare ingress as an
  optional WAN rule and marks it disabled by default.
- `opnsense/spec/aliases/aliases.yaml` describes Cloudflare IP ranges as
  optional public web ingress only.
- `opnsense/spec/nat/dns_redirect.yaml` affects DNS port `53` only.
- `opnsense/spec/firewall/lan.yaml` blocks DNS-over-TLS on port `853` but
  does not define any rule relevant to ADB ports `5555` or `34661`.

### Live Host Checks

On the Mac on 2026-04-04:

- `arp -n 192.168.0.11` resolves the Pixel directly on `en0`.
- `traceroute -n 192.168.0.11` reaches the Pixel in one hop.
- `scutil --dns` shows:
  - general DNS via Quad9 (`9.9.9.9`, `149.112.112.112`)
  - `home.arpa` via OPNsense (`192.168.0.1`)
- No `cloudflared`, Cloudflare WARP, or `1.1.1.1` client process was
  found running on the Mac at the time of checking.

### What This Means

- Direct ADB tests to `192.168.0.11` do not consult Cloudflare DNS.
- Direct ADB tests to `192.168.0.11` do not traverse OPNsense routing or
  WAN firewall policy.
- OPNsense DNS redirect / DoT rules are unrelated to raw TCP to ADB ports.
- Cloudflare may matter for public DNS, ACME, or optional future public
  ingress, but it does not fit the observed failure mode for direct LAN
  ADB to a literal IP.

## Confirmed Pixel-Side State

From `adb shell` over USB:

- `ss -tln` shows adbd LISTENING on `*:5555` after `adb tcpip 5555`
- `/proc/net/tcp6` confirms listeners on `[::]:5555` (0x15B3) and
  `[::]:34661` (0x8765), UID 2000
- `/proc/net/tcp` has no matching IPv4 listeners for those ports
- Wireless debugging TLS port also listening (varied: 34499, 34661, 42251 across restarts)
- `service.adb.tcp.port` = 5555 (set by `adb tcpip`)
- `settings get global adb_wifi_enabled` = 1
- mDNS advertises: `adb-57090DLCQ0016F-dKZyvH _adb-tls-connect._tcp 192.168.0.11:34661` and `adb-57090DLCQ0016F _adb._tcp 192.168.0.11:5555`
- `ip route`: `192.168.0.0/24 dev wlan0 proto kernel scope link src 192.168.0.11`
- `ip neigh`: Mac at 192.168.0.10 is REACHABLE in ARP table
- `ip link`: no tun/wg/warp/vpn interfaces
- `wlan0` also has IPv6 link-local `fe80::a025:5ff:fe37:172c/64`
- `ip rule` last entry: `32000: from all unreachable` (default deny)
- A throwaway `toybox nc -L -p 23456 echo ok` listener created from the
  `shell` context is reachable from the Mac
- `iptables -L`: permission denied (not root)
- `nft`: binary not found
- `/proc/net/ip_tables_names`: permission denied
- `dumpsys network_management`: `Firewall enabled: false` at netd level
- `setprop persist.adb.tcp.port 5555`: permission denied (not root)
- `setprop ctl.restart adbd`: permission denied (not root)

## What Was Tried

### 1. CLI `adb pair` (multiple attempts)

```
adb pair 192.168.0.11:<PORT> <CODE>
```

Tried with both Homebrew ADB (v36.0.2) and SDK ADB (v37.0.0). Tried 4
separate pairing codes with different ephemeral ports. All returned:

```
error: protocol fault (couldn't read status message): Undefined error: 0
```

ADB trace (`ADB_TRACE=all`) showed the error occurs between the ADB
client and the local ADB server daemon (localhost:5037) — `readx: fd=3
error 54: Connection reset by peer`. The server resets the client
connection after failing to reach the Pixel's pairing port.

### 2. Android Studio "Pair Devices Using Wi-Fi"

Same failure. Android Studio could not pair with the device wirelessly.

### 3. `adb tcpip 5555` via USB

Command succeeds (`restarting in TCP mode port: 5555`). Pixel confirms
listener on `*:5555`. Port is unreachable from Mac (`nc -z` returns
closed/refused). One early attempt did connect briefly (`connected to
192.168.0.11:5555`) but the connection dropped within seconds and could
not be re-established.

### 4. Rapid-fire connect loop

Ran `adb connect` in a tight loop (0.5s intervals, 20 attempts) immediately
after `adb tcpip 5555`. All 20 attempts returned "Connection refused".

### 5. Toggle wireless debugging via settings API

```
adb shell settings put global adb_wifi_enabled 0
adb shell settings put global adb_wifi_enabled 1
```

After toggle, mDNS began advertising the device (it was not visible before).
New TLS port appeared in `ss -tln`. Port still unreachable from Mac.

### 6. ADB mDNS auto-connect

Restarted ADB server with `ADB_MDNS_AUTO_CONNECT=1`. Server discovered
USB device only; did not auto-connect via mDNS despite the device being
advertised.

### 7. Cleared `~/.android/adb_known_hosts.pb`

Removed stale known hosts file (contained 5 duplicate entries for this
Pixel serial). Restarted ADB server fresh. No effect on pairing.

### 8. ADB server restart with fresh state

Killed all ADB processes, started clean SDK server. Android Studio had
been holding 3 connections to the server. Fresh server made no difference.

### 9. Reverse connectivity test

Started TCP listener on Mac (port 19999), told Pixel to connect outbound
via `adb shell "echo test | nc -w 3 192.168.0.10 19999"`. Result: timeout.
This is **not** sufficient evidence that the Pixel cannot make outbound TCP
connections to the Mac. The test used an HTTP server and `nc`, which can
time out after a successful TCP connect if the application protocol does
not complete.

### 10. Raw TCP connectivity re-check

Started `nc -l 19998` on the Mac, then ran:

```
adb shell 'echo test-from-pixel | toybox nc -w 2 192.168.0.10 19998'
```

This succeeded. The Mac received `test-from-pixel`.

### 11. Throwaway listener from `shell`

Started a temporary listener on the Pixel from `adb shell`:

```
toybox nc -L -p 23456 echo ok
```

The listener appeared in `/proc/net/tcp6` as UID 2000 and was reachable
from the Mac over IPv4 (`nc -vz -w 2 192.168.0.11 23456` succeeded).

### 12. Direct IPv6 ADB connect

The Pixel's `wlan0` link-local address is `fe80::a025:5ff:fe37:172c/64`.
Using that address directly works:

```
adb connect '[fe80::a025:5ff:fe37:172c%en0]:5555'
```

Result:

```
connected to [fe80::a025:5ff:fe37:172c%en0]:5555
```

`adb devices -l` then showed both the USB transport and the WiFi transport.

## Root Cause Analysis

**Supported by current evidence**:

- ADB services are live on the Pixel.
- Those services are reachable from the Mac over IPv6 link-local.
- Those same services are refused over IPv4 at `192.168.0.11`.
- Wireless ADB is functional if the host connects to the device's IPv6
  link-local address.

**Not supported by current evidence**:

- "The Pixel blocks all TCP to/from adbd over WiFi."
- "UID 2000 has no usable network path on wlan0."
- "Android 16 eBPF/per-UID policy is the root cause."

Those claims are contradicted by two live checks:

- A UID-2000 listener started from `adb shell` on port `23456` was
  reachable from the Mac.
- A raw TCP client connection from the Pixel shell to the Mac on port
  `19998` succeeded.

**Most likely interpretation**:

The failure is specific to IPv4 access to the ADB listeners, not a general
WiFi restriction on `adbd` or the `shell` UID. The exact reason the ADB
ports are IPv4-refused while still working over IPv6 is still unconfirmed.

## Current Working State

- **USB ADB**: fully functional, device authorized
- **WiFi ADB**: functional over IPv6 link-local using
  `adb connect '[fe80::a025:5ff:fe37:172c%en0]:5555'`
- **IPv4 WiFi ADB**: still failing at `192.168.0.11:5555` and the
  advertised TLS connect port
- **Shell config**: `ANDROID_HOME` exports added to zsh/bash/fish templates (not yet applied via `chezmoi apply`)
- **Homebrew conflict**: `android-platform-tools` cask (v36.0.2) shadows SDK ADB (v37.0.0) on PATH, but this was not the cause of the IPv4 failure

## Missing Facts

The following items are still unknown and should not be guessed:

1. Why `adbd` accepts IPv6 link-local connections but refuses IPv4 on this device/LAN.
2. Whether the wireless-debugging pairing server would also work if addressed over IPv6 link-local.
3. Why the device UI and `adb mdns services` surface IPv4 endpoints in this environment even though IPv6 connectivity works.
4. Whether this is device-specific, build-specific, router-specific, or an ADB bug in address selection/reporting.
5. Whether IPv4 attempts are failing because `adbd` is returning the reset,
   because the kernel/socket layer is refusing IPv4 for those listeners, or
   because another component on the phone is intervening.

## Excluded Hypotheses

The following are currently excluded or strongly deprioritized by evidence:

- "Cloudflare is in the network path for Mac → Pixel ADB traffic."
- "OPNsense LAN/WAN firewall rules are blocking `.10 -> .11` ADB traffic."
- "DNS mis-resolution is the cause of the ADB failure."
- "Android 16 blocks all WiFi TCP for `adbd` or UID 2000."
- "The Pixel cannot make outbound TCP connections to the Mac."

These should not be treated as working theories unless new evidence appears.

## Research Priorities

Recommended next steps, in order:

1. Capture packets on the Mac during a failing IPv4 attempt:
   `sudo tcpdump -ni en0 'host 192.168.0.11 and tcp port 5555'`
   and repeat for the TLS port.
   Goal: verify whether the RST/refusal is sent directly by `192.168.0.11`.
2. Repeat the IPv4 and IPv6 tests on a different network, ideally a phone
   hotspot with no OPNsense involvement.
3. Test whether `adb pair` can be completed manually against an IPv6
   link-local endpoint if the CLI accepts the address format.
4. Compare behavior with another recent Android device or another Pixel on
   the same LAN.
5. If rooted access becomes available, inspect socket options / listener
   behavior for `adbd` and capture packets on-device.

## Cross-Network Resolution (2026-04-04 evening)

Testing on a university campus network conclusively answered the open
questions. Full details in `adb-wifi-debug-network-test-2026-04-04.md`.

### What was tested

On the campus network (10.147.160.0/21), with the Mac initially wired
(137.229.236.0/26, different subnet, routed) and later on WiFi (same
subnet as Pixel):

| Test | Result |
|------|--------|
| `adb tcpip 5555` + IPv4 connect | **Works** |
| Shell-owned explicit IPv4 listener from Mac | **Works** |
| WiFi ADB transport stability | **Stable** |
| `adb shell` over WiFi transport | **Works** |

### What this means

- **The problem is specific to the home network ("Bob's Internet" /
  OPNsense).** It is not caused by Android 16, the Pixel, adbd, ADB
  versions, or the Mac.
- All prior theories about eBPF, per-UID routing, or Android-side
  filtering are falsified. The same device, OS, and ADB binaries work
  without issue on a different network.
- The home network infrastructure is selectively blocking inbound IPv4
  TCP on non-standard ports between WiFi peers. The exact mechanism
  (AP client isolation, OPNsense WiFi interface config, or AP-level
  port filtering) remains unidentified.

### Corrected open questions

1. ~~Is the IPv4 refusal reproducible on a different network?~~ **No.**
   IPv4 works on the campus network. Home-network-specific.
2. ~~Is this an Android 16 or Pixel issue?~~ **No.** Device is fine.
3. What specifically in the home network blocks inbound IPv4 TCP on
   high ports between WiFi clients while allowing ICMP and
   established-protocol ports?
4. Is the home WiFi AP a separate device from OPNsense, and does it
   have its own client isolation or filtering config?

### Workaround for home network

Use IPv6 link-local (confirmed working):
```
adb connect '[fe80::a025:5ff:fe37:172c%en0]:5555'
```

## Upstream References

- Android Developers: if mDNS discovery does not result in an automatic
  connection after pairing, manual `adb connect ip:port` is the documented
  fallback.
  https://developer.android.com/tools/adb
- AOSP `adb_wifi.md`: `adb mdns services` resolves IPv6 but does not print
  it, and the pairing-code UI presents an IPv4:port to the user.
  https://android.googlesource.com/platform/packages/modules/adb/+/HEAD/docs/dev/adb_wifi.md
