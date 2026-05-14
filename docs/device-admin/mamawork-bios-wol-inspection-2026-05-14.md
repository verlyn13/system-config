---
title: MAMAWORK BIOS / WoL Firmware Inspection Ingest - 2026-05-14
category: operations
component: device_admin
status: ingested
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, bios, wol, s3, power, inspection]
priority: medium
---

# MAMAWORK BIOS / WoL Firmware Inspection Ingest - 2026-05-14

Repo-safe summary of the operator's read-only AMI Aptio BIOS
inspection on MAMAWORK on 2026-05-14. **No firmware changes were
made.** The inspection's purpose was to confirm the firmware
posture relevant to Wake-on-LAN, S3 sleep reliability, and
remote-admin availability.

## Source

| Field | Value |
|---|---|
| Inspected on | 2026-05-14 |
| System | MAMAWORK / AZW SER-family mini-PC |
| BIOS | AMI Aptio Setup |
| CPU | AMD Ryzen 7 5800H |
| NIC | Realtek PCIe GbE, MAC `B0:41:6F:0E:B7:B6` |
| Operator | `MAMAWORK\jeffr` |
| Mode | read-only; no Optimized Defaults restore; no BIOS update; no boot-order edit |

## Confirmed Posture

```text
ACPI Sleep State                    S3 (Suspend to RAM)
ACPI Auto Configuration             Disabled (left unchanged)
Enable Hibernation (firmware)       Enabled (host-side Windows
                                    hibernation is separately
                                    disabled by the RDP packet's
                                    powercfg /hibernate off)
S5 RTC Wake                         Disabled (correct; we don't
                                    want scheduled boot)
AMD PBS S3/Modern Standby Support   S3 Enable
AMD PBS Wake on PME                 Enabled (key signal for PCIe
                                    PME wake including the
                                    onboard Realtek NIC)
Boot Fast Boot                      Disabled (correct for WoL)
Boot mode                           UEFI (unchanged)
Boot order                          Windows Boot Manager first
                                    (unchanged)
```

The firmware is deliberately configured for **classic S3**, not
Modern Standby / S0ix. This matters because Windows-level WoL
behavior, magic-packet processing, and S3 wake reliability depend
on the underlying firmware sleep state.

## Settings Searched For But Not Exposed In This BIOS Revision

```text
ErP / EuP / Energy Star / Deep Power Off              not exposed
Deep Sleep / Deep S5 / S5 Maximum Power Savings        not exposed
Restore on AC Power Loss / AC Back                     not exposed
Onboard LAN Wake on LAN / WoL from S5                  not exposed
Explicit PXE OpROM / network stack WoL dependency      no change
```

These options are commonly present on other BIOS revisions but
were not visible in MAMAWORK's current AMI Aptio menus. Per the
packet's "no-substitution" rule, the operator did not invent
substitutes from unrelated low-level chipset settings.

## Boundaries Preserved

```text
Secure Boot                       left unchanged
TPM / fTPM                        left untouched; not cleared
Boot mode                         UEFI (unchanged)
Boot order                        unchanged
PXE / network boot                not enabled
SVM / IOMMU                       not touched
XMP / DOCP / memory tuning        not touched
BIOS update / flash               not attempted
Optimized defaults                not restored
South Bridge debug settings       not changed
```

## Windows-Side Cross-Check (Post-RDP Apply)

The RDP bootstrap apply (same operator session) captured the
following relevant Windows-side WoL signals:

```text
powercfg /a:
  Available    Standby (S3)
  Not avail.   S1, S2, S0ix (firmware unsupported)
  Not avail.   Hibernate (intentionally disabled by powercfg)
  Not avail.   Hybrid Sleep, Fast Startup (no hibernate)

powercfg /devicequery wake_armed:
  HID Keyboard Device (x4)
  HID-compliant mouse (002)
  (Ethernet 2 NOT listed)

NIC advanced wake properties (Ethernet 2):
  Wake on magic packet when system is in the S0ix power state  Enabled
  Wake on Magic Packet                                         Enabled
  Wake on pattern match                                        Enabled
```

The NIC's **advanced wake properties are Enabled**, which is one
half of the equation. The **per-device wake policy**
(`powercfg /deviceenablewake "<friendly name or InstanceId>"`) is
the other half. Without both, WoL from sleep will not actually
wake the machine, even though the firmware Wake-on-PME setting is
ready.

`Ethernet 2` is **not** in `wake_armed` today. Closing this gap is
the future
`mamawork-nic-wake-enable-packet` (small, scoped, host-side
PowerShell), to be drafted after the LAN-inbound-TCP blackhole
investigation closes (do not stack unrelated host-side changes
while inbound LAN is broken).

## Practical WoL Tests (Deferred)

The BIOS report proposed two practical tests after Windows
post-boot:

1. **Sleep WoL test**: put MAMAWORK to sleep, send magic packet
   from OPNsense, confirm wake, then `powercfg /lastwake`.
2. **Shutdown WoL test**: shut down MAMAWORK, wait 30s, send
   magic packet, confirm wake (requires firmware ErP and
   shutdown-WoL settings; ErP not exposed in this BIOS revision,
   so this test may not pass without an exposed firmware
   control).

Both are deferred until:

- The MAMAWORK LAN inbound TCP blackhole is resolved (so the
  practical test can include verifying SSH/RDP reachability
  immediately after wake; today even a successful wake would not
  produce a usable admin session).
- The NIC per-device wake policy is enabled
  (`powercfg /deviceenablewake "Ethernet 2"` or InstanceId
  equivalent).

## Target WoL Facts (For Future Use)

```text
Hostname:    MAMAWORK
DNS:         mamawork.home.arpa
IPv4:        192.168.0.101
MAC:         B0:41:6F:0E:B7:B6
Broadcast:   192.168.0.255 (LAN broadcast; HomeNetOps owns
                            whether OPNsense can also originate
                            magic packets from outside the LAN
                            broadcast domain)
UDP port:    9 preferred; 7 commonly used
```

## Boundary Assertions

- No BIOS setting was changed during the inspection.
- No Optimized Defaults restore.
- No Secure Boot or TPM mutation.
- No `system-config` host change, HomeNetOps change, Cloudflare
  change, or 1Password change resulted from this inspection.
- The Windows-side Wake_armed gap is documented but not patched
  by this ingest; patching is a separate future packet.

## Related

- [mamawork-lan-rdp-implementation-apply-2026-05-14.md](./mamawork-lan-rdp-implementation-apply-2026-05-14.md) -
  same operator session; cross-references the Windows-side WoL
  signals captured during the RDP apply.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md) - master
  record; the BIOS inspection now provides repo-cited evidence
  for the "Power / wake" row.
- [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md) -
  the prepared inbound investigation, which is the blocking
  next step before any practical WoL test.
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
