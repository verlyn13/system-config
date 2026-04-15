---
title: ADB Wireless Debugging — Follow-Up Test Report
category: archive
component: adb_wifi_debug
date: 2026-04-04
captured_at: 2026-04-04 17:50:02 AKDT
status: archived
device: Pixel 10 Pro XL (mustang)
serial: 57090DLCQ0016F
android: 16 (API 36)
host: verlyn's-mbp (macOS 15 Sequoia, Darwin 25.3.0, arm64)
prior_report: ./adb-wifi-debug-report.md
---

# ADB Wireless Debugging — Follow-Up Test Report

## Purpose

Run a fresh live test pass with the phone physically connected over USB,
confirm or falsify the main theories from the earlier report, and record
only the results that were actually reproduced in this session.

## Executive Summary

This follow-up changes the understanding of the problem in four important
ways:

1. `bindv6only` is **not** the system-wide cause. On the device,
   `/proc/sys/net/ipv6/bindv6only` is `0`.
2. Plain `adb tcpip 5555` is still effectively **IPv6-only from the Mac**:
   IPv4 to `192.168.0.11:5555` is refused, while IPv6 link-local works.
3. The problem is **not limited to adbd**. In this session, even a
   shell-owned explicit IPv4 listener (`toybox nc -4 -L -p 23459`) accepted
   self-connections from the phone itself but refused connections from the
   Mac.
4. Wireless debugging TLS behaved differently from plain `tcpip 5555`:
   the TLS connect port (`34631`) was reachable over both IPv4 and IPv6 at
   least initially, but only the IPv6 transport was stably usable by `adb`.

The most defensible current statement is:

- Plain `adb tcpip 5555` works over IPv6 link-local and fails over IPv4.
- Wireless debugging TLS is partially functional:
  - IPv6 transport works end-to-end.
  - IPv4 transport is unstable or incomplete: TCP reached the port, but the
    resulting ADB transport was `offline`, and later retries were refused.
- The behavior is not explained by Cloudflare, OPNsense routing, or a
  system-wide `bindv6only=1` setting.

## Test Environment

- Host `adb` default on `PATH`: Homebrew `36.0.2`
- SDK `adb` also installed: `37.0.0`
- Device connected over USB and authorized at session start
- Device Wi-Fi:
  - IPv4: `192.168.0.11/24`
  - IPv6 link-local: `fe80::a025:5ff:fe37:172c/64`

## Live Evidence

### 1. Baseline device state after `adb tcpip 5555`

Commands:

```sh
adb -s 57090DLCQ0016F tcpip 5555
adb -s 57090DLCQ0016F shell 'settings get global adb_wifi_enabled; getprop service.adb.tcp.port; cat /proc/sys/net/ipv6/bindv6only'
adb mdns services
```

Observed:

- `adb tcpip 5555` succeeded.
- `settings get global adb_wifi_enabled` returned `0`.
- `getprop service.adb.tcp.port` returned `5555`.
- `cat /proc/sys/net/ipv6/bindv6only` returned `0`.
- mDNS advertised only:

```text
adb-57090DLCQ0016F  _adb._tcp  192.168.0.11:5555
```

### 2. Plain `tcpip 5555` listener state and reachability

Commands:

```sh
adb -s 57090DLCQ0016F shell 'ss -tln; cat /proc/net/tcp; cat /proc/net/tcp6'
nc -vz -w 2 192.168.0.11 5555
nc -6 -vz -w 2 'fe80::a025:5ff:fe37:172c%en0' 5555
adb connect 192.168.0.11:5555
adb connect '[fe80::a025:5ff:fe37:172c%en0]:5555'
```

Observed:

- Port `5555` appeared in `/proc/net/tcp6`, not `/proc/net/tcp`.
- IPv4 from Mac to `192.168.0.11:5555` was refused.
- IPv6 from Mac to `fe80::...:5555` succeeded.
- `adb connect 192.168.0.11:5555` failed with `Connection refused`.
- `adb connect '[fe80::...%en0]:5555'` succeeded and produced a usable
  transport.

Conclusion:

- Plain `tcpip 5555` remains reproducibly usable over IPv6 link-local and
  unusable over IPv4 in this environment.

### 3. Explicit shell listeners: wildcard, `-4`, and `-6`

Commands:

```sh
adb -s 57090DLCQ0016F shell 'toybox nc -L -p 23457 echo ok >/dev/null 2>&1 &'
adb -s 57090DLCQ0016F shell 'toybox nc -4 -L -p 23459 echo ok >/dev/null 2>&1 &'
adb -s 57090DLCQ0016F shell 'toybox nc -6 -L -p 23460 echo ok >/dev/null 2>&1 &'
```

Observed socket tables:

- `23457` appeared in `/proc/net/tcp6`
- `23459` appeared in `/proc/net/tcp`
- `23460` appeared in `/proc/net/tcp6`

Reachability from the Mac:

```text
192.168.0.11:23457    refused
fe80::...:23457       succeeded
192.168.0.11:23459    refused
fe80::...:23459       refused
192.168.0.11:23460    refused
fe80::...:23460       succeeded
```

Self-connect tests from the phone:

```sh
adb -s 57090DLCQ0016F shell 'toybox nc -w 2 192.168.0.11 23459 </dev/null; echo SELF_IPV4_EXIT:$?'
adb -s 57090DLCQ0016F shell 'toybox nc -6 -w 2 fe80::a025:5ff:fe37:172c%wlan0 23460 </dev/null; echo SELF_IPV6_EXIT:$?'
```

Observed:

- Self-connect to `192.168.0.11:23459` succeeded and returned `ok`.
- Self-connect to `fe80::...%wlan0:23460` succeeded and returned `ok`.

Conclusion:

- A shell-owned explicit IPv4 listener can bind and accept local IPv4
  connections from the phone itself.
- The same explicit IPv4 listener is refused from the Mac.
- Therefore the current failure is not just "the socket was never IPv4" or
  "the listener was not running."
- Something about inbound peer-to-peer IPv4 traffic from the Mac to at least
  shell-owned listeners is being rejected.

### 4. Outbound IPv4 from the phone still works

Command sequence:

```sh
# On Mac
nc -l 19998

# On phone via adb shell
echo from-pixel-ipv4 | toybox nc -w 2 192.168.0.10 19998
```

Observed:

- The Mac received `from-pixel-ipv4`.

Conclusion:

- The phone can still open outbound IPv4 TCP connections to the Mac.
- This is not a blanket "phone IPv4 TCP is broken" condition.

### 5. Wireless debugging TLS mode behaves differently

Commands:

```sh
adb -s 57090DLCQ0016F shell 'settings put global adb_wifi_enabled 1'
adb mdns services
adb -s 57090DLCQ0016F shell 'ss -tln; cat /proc/net/tcp; cat /proc/net/tcp6'
```

Observed:

- `settings get global adb_wifi_enabled` returned `1`.
- mDNS advertised:

```text
adb-57090DLCQ0016F-dKZyvH  _adb-tls-connect._tcp  192.168.0.11:34631
adb-57090DLCQ0016F         _adb._tcp              192.168.0.11:5555
```

- Port `34631` appeared as a listener in `/proc/net/tcp6`.

Initial reachability and connection tests:

```sh
nc -vz -w 2 192.168.0.11 34631
nc -6 -vz -w 2 'fe80::a025:5ff:fe37:172c%en0' 34631
adb connect 192.168.0.11:34631
adb connect '[fe80::a025:5ff:fe37:172c%en0]:34631'
adb devices -l
```

Observed:

- TCP to `192.168.0.11:34631` succeeded.
- TCP to `fe80::...:34631` succeeded.
- `adb connect 192.168.0.11:34631` reported `connected to 192.168.0.11:34631`.
- `adb connect '[fe80::...%en0]:34631'` reported success.
- `adb devices -l` then showed:
  - `192.168.0.11:34631` as `offline`
  - `[fe80::...%en0]:34631` as `device`
  - `[fe80::...%en0]:5555` as `device`

Usability tests:

```sh
adb -s 192.168.0.11:34631 shell 'echo tls-ipv4-ok'
adb -s '[fe80::a025:5ff:fe37:172c%en0]:34631' shell 'echo tls-ipv6-ok'
```

Observed:

- IPv4 TLS transport: `adb: device offline`
- IPv6 TLS transport: succeeded and returned `tls-ipv6-ok`

Later state after disconnecting the IPv4 TLS transport:

```sh
adb disconnect 192.168.0.11:34631
nc -vz -w 2 192.168.0.11 34631
adb -s 57090DLCQ0016F shell 'cat /proc/net/tcp6 | grep -i :8747'
```

Observed:

- New IPv4 TCP attempts to `34631` were then refused.
- `/proc/net/tcp6` still showed:
  - the `34631` listener
  - an established IPv4-mapped connection
  - an established IPv6 connection

Conclusion:

- Wireless debugging TLS is not identical to plain `tcpip 5555`.
- In this session, the TLS connect port accepted IPv4 TCP at least once.
- However, the resulting IPv4 ADB transport was not stably usable.
- IPv6 TLS was fully usable.
- The IPv4 TLS behavior appears unstable or stateful rather than cleanly
  "works" or cleanly "blocked."

## What Is Ruled Out

The following are ruled out or strongly deprioritized by this session:

- **System-wide `bindv6only=1`**
  - Tested directly.
  - Actual value: `0`.

- **Cloudflare as the cause**
  - Direct `192.168.0.10 -> 192.168.0.11` tests do not traverse Cloudflare.
  - See prior report and HomeNetOps architecture notes.

- **OPNsense LAN/WAN firewall policy as the cause**
  - Same-LAN peer traffic is direct L2 traffic, not routed through OPNsense.

- **"adbd is the only thing affected"**
  - In this session, a shell-owned explicit IPv4 listener was also refused
    from the Mac.

- **"the phone cannot do IPv4 TCP at all"**
  - Outbound IPv4 from phone to Mac succeeded.
  - Wireless TLS accepted an IPv4 TCP connection at least once.

- **"the only problem is that sockets are IPv6 wildcard listeners"**
  - Explicit `-4` shell listener on `0.0.0.0:23459` was still refused from
    the Mac.

## Important Context and Session Caveats

- A previous session had an observation that a shell-owned listener on
  `23456` accepted IPv4 from the Mac. That did **not** reproduce here.
  The current session showed the opposite result repeatedly.
- Ports `22` and `8080` briefly appeared reachable in an earlier round of
  testing but were not stable and were not present in the socket tables when
  checked again. They should not be used as strong evidence.
- The default `adb` on `PATH` is Homebrew `36.0.2`, while SDK `37.0.0` is
  also installed. This session did not cleanly isolate whether the `offline`
  IPv4 TLS transport is a host ADB-server bug, a device behavior, or both.

## Best Current Theory

The strongest current theory is:

- There is a policy or implementation difference affecting inbound peer IPv4
  connections from the Mac to certain listeners on the phone, including:
  - `adbd` plain `tcpip 5555`
  - shell-owned test listeners on UID `2000`
- That policy is **not** explained by:
  - Cloudflare
  - OPNsense routing
  - global `bindv6only`
- Wireless debugging TLS uses a different path and can accept IPv4 TCP, but
  the resulting IPv4 ADB transport is unstable or incomplete in this host /
  device combination.

That means the problem may involve one or more of:

- inbound peer IPv4 policy for selected UIDs / daemons
- Android-side handling of externally-originated IPv4 to local listeners
- ADB host/server transport handling differences between IPv4 and IPv6 TLS

## Next Tests That Matter

1. Capture packets on the Mac during:
   - failed connect to `192.168.0.11:23459`
   - failed connect to `192.168.0.11:5555`
   - first successful TCP connect to `192.168.0.11:34631`
   Goal: determine whether the refusal/RST is being sent by the phone and
   whether the TLS port's behavior changes after the first connect.

2. Repeat the explicit `-4` shell-listener test from a second LAN peer, not
   just the Mac.
   Goal: determine whether the rejection is Mac-specific or general to
   external peers.

3. Reproduce the TLS IPv4 `offline` transport with a clean ADB 37-only
   server after killing the Homebrew server completely.
   Goal: determine whether the offline IPv4 TLS transport is an ADB host
   version issue.

4. If root becomes available, inspect:
   - `iptables` / `nft`
   - cgroup / eBPF network policy
   - SELinux denials
   - socket options on the actual listener fds

5. Test the same device on a different network or hotspot.
   Goal: determine whether the peer IPv4 inbound behavior is network-specific
   or intrinsic to the phone/build.

## Bottom Line

The earlier problem statement was too simple.

As of this follow-up session:

- Plain `adb tcpip 5555` is still only usable over IPv6 link-local.
- A shell-owned explicit IPv4 listener can bind and accept local self-connect
  traffic, but is refused from the Mac.
- Wireless debugging TLS is the one path that partially crosses back into
  IPv4, but its IPv4 ADB transport is not reliable enough to call fixed.

This is now best treated as a mixed Android networking / ADB transport issue,
not a single-root-cause Cloudflare, OPNsense, or `bindv6only` issue.
