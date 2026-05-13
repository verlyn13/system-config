---
title: Device Agent Handoff - DESKTOP-2JJ3187
category: operations
component: device_admin
status: draft
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, handoff, windows, rdp, ssh, cloudflare, warp]
priority: high
---

# Device Agent Handoff - DESKTOP-2JJ3187

This is the handoff for an agent running locally on the Windows PC
`DESKTOP-2JJ3187`.

## Mission

Prepare a fresh, repo-safe readiness report for Jefahnierocks device
administration. This is a prep pass, not an implementation pass.

The local source plan on this Windows machine contains useful facts, but it is
not authoritative. Jefahnierocks owns device administration from
`system-config`, with `cloudflare-dns` owning Cloudflare/WARP policy semantics
and HomeNetOps owning OPNsense/LAN/router changes.

## Authority

Follow these rules:

- Treat this handoff as the active directive.
- Treat any older Windows-local plan as evidence only.
- Do not execute setup phases from older plans without new explicit approval.
- Preserve the local fact that human/kid WARP policy must resolve to
  `identity.email`; do not substitute headless/service-token enrollment for
  human desktop users.
- Treat Jefahnierocks as the device owner/administrator. Device-specific
  management accounts may be created only if the approved implementation phase
  requires them.
- Treat BitLocker as intentionally out of target state for this slice. Verify
  status if asked, but do not enable it or create recovery material.
- Return redacted evidence and recommended next steps to the Jefahnierocks
  `system-config` operator.

## Hard Stops

Stop and ask before any of these:

- Creating, editing, reading broadly, or reorganizing 1Password items.
- Printing passwords, private keys, recovery keys, bearer tokens, tunnel
  credential JSON, OAuth credentials, or sensitive environment variables.
- Installing or enabling OpenSSH Server.
- Enabling RDP.
- Changing Windows Firewall rules.
- Installing or enrolling WARP.
- Creating, deleting, or reconfiguring Cloudflare Tunnel, Access, Gateway,
  WARP, or DNS state.
- Changing OPNsense, Wake-on-LAN, DHCP, DNS, or firewall state.
- Changing static IP, static DHCP, or DNS records.
- Changing local users, groups, passwords, or UAC policy.
- Modifying Codex sandbox accounts:
  `CodexSandboxOnline`, `CodexSandboxOffline`, or `WsiAccount`.
- Running destructive cleanup commands or uninstalling software.

## Allowed Prep Work

You may perform read-only inventory and produce a non-secret report. If you
need to save a local artifact, use a user-local path such as:

```text
C:\Users\jeffr\Documents\device-admin-prep\
```

Do not include raw logs that contain secrets. Prefer short command summaries
and redacted outputs.

## Read-Only Checks

Run from PowerShell. If a command requires elevation, record that it is
blocked pending an elevated session; do not force escalation unless the human
explicitly opens an Administrator PowerShell for you.

```powershell
# Identity and OS
hostname
Get-ComputerInfo | Select-Object OsName, OsDisplayVersion, OsBuildNumber, WindowsVersion, CsName, CsDomain, TimeZone

# Users and groups
Get-LocalUser | Select-Object Name, Enabled, PrincipalSource, LastLogon
Get-LocalGroupMember Administrators
Get-LocalGroupMember 'Remote Desktop Users'
Get-LocalGroupMember 'docker-users' -ErrorAction SilentlyContinue

# Network
Get-NetAdapter -Physical | Select-Object Name, Status, LinkSpeed, MacAddress
Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv6Address, DNSServer
Get-NetConnectionProfile

# Listening admin ports
Get-NetTCPConnection -State Listen |
  Where-Object LocalPort -in 22,3389,5985,5986 |
  Select-Object LocalAddress, LocalPort, OwningProcess

# Firewall and remote access state
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue |
  Select-Object DisplayName, Enabled, Direction, Action
(Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
(Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').UserAuthentication

# Services
Get-Service sshd, ssh-agent, cloudflared, Cloudflared, CloudflareWARP -ErrorAction SilentlyContinue |
  Select-Object Name, Status, StartType

# Cloudflare/WARP binaries only; do not read credential JSON
Get-Command cloudflared -ErrorAction SilentlyContinue
Get-Command warp-cli -ErrorAction SilentlyContinue
if (Get-Command cloudflared -ErrorAction SilentlyContinue) { cloudflared --version }
if (Get-Command warp-cli -ErrorAction SilentlyContinue) { warp-cli status }

# Power and wake posture
powercfg /a
powercfg /devicequery wake_armed
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' |
  Select-Object HiberbootEnabled
Get-NetAdapterAdvancedProperty -Name 'Ethernet' -ErrorAction SilentlyContinue |
  Where-Object DisplayName -match 'Wake|PME|Magic' |
  Select-Object DisplayName, DisplayValue

# Disk encryption posture; redact recovery identifiers and never print keys
manage-bde -status C:

# Compute/GPU posture
Get-Command nvidia-smi -ErrorAction SilentlyContinue
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) { nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv }
```

## Expected Findings To Reconcile

Confirm whether these are still true:

- Hostname is `DESKTOP-2JJ3187`.
- Windows is Windows 11 Pro 24H2 build 26100.
- Jefahnierocks owns administration of the device; `jeffr` is the current local
  administrator unless an approved device-specific management account is later
  created.
- Kid accounts are standard users.
- RDP is LAN-enabled after the approved 2026-05-12 apply pass, and MacBook
  Windows App GUI management is verified; report if that has changed.
- OpenSSH Server is not installed or not active.
- WARP is not installed.
- `cloudflared` has duplicate/stopped services and no approved local config.
- Ethernet is connected at 1 Gbps on the home LAN; wired MAC
  `18:C0:4D:39:7F:49` has static DHCP IP `192.168.0.217` and FQDN
  `desktop-2jj3187.home.arpa`.
- BIOS-side Wake-on-LAN and AC recovery were reported complete, but
  Windows-side Fast Startup, hibernate, hybrid sleep, and `Enable PME` were
  handled during the LAN RDP phase; HomeNetOps verified cold-to-wake-to-RDP
  WoL using OPNsense `os-wol` UUID
  `93980551-709a-40d3-83e7-a708ee616373`.
- BitLocker is off by operator attestation and is not in the target state for
  this slice.

## Evidence Return Format

Return a concise report with these sections:

```text
Device:
Timestamp:
Operator/agent:
Scope:

Verified current state:
- ...

Changed nothing confirmation:
- ...

Findings that differ from Jefahnierocks expectations:
- ...

Remote-admin readiness:
- RDP:
- SSH:
- WARP:
- cloudflared:
- Firewall:
- Power/WoL:
- Disk encryption:

Approval-needed actions:
- ...

Blocked because elevation or human/provider access is needed:
- ...

Redacted evidence:
- Command/source:
  Observation:
  Redaction note:
```

## Recommended Next Request Back To Jefahnierocks

Ask the Jefahnierocks operator to decide:

- Which Google identity should be the admin WARP identity.
- Which Google identities belong to each kid account.
- Whether remote access must stay Private Network only, or whether
  Access-protected hostnames are allowed later.
- Whether to retain the existing named tunnel or migrate to a dashboard-managed
  connector.
- Whether to create a local device-management or break-glass Administrator
  credential in 1Password.
- Whether to update or change the existing HomeNetOps static DHCP/local DNS
  record.
- Whether to proceed with an elevated Windows implementation phase.
