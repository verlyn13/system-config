---
title: ADB WiFi Investigation Archive
category: archive
component: adb_wifi_debug
status: archived
version: 1.0.0
last_updated: 2026-04-08
tags: [adb, android, wifi, archive]
priority: low
---

# ADB WiFi Investigation Archive

These files are archived incident notes from the 2026-04-04 ADB-over-WiFi investigation. They are useful as evidence and troubleshooting history, but they are not active setup docs for this repo.

Operational takeaway:
- On the home network, the reliable workaround was IPv6 link-local ADB.
- On the work network, IPv4 ADB worked normally.
- The issue was narrowed to network-specific behavior, not a general Pixel or Android 16 failure.

Files:
- `adb-wifi-debug-report.md`
- `adb-wifi-debug-followup-2026-04-04.md`
- `adb-wifi-debug-network-test-2026-04-04.md`
