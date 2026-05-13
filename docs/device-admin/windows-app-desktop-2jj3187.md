---
title: Windows App Profile - DESKTOP-2JJ3187
category: operations
component: device_admin
status: draft
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, windows, rdp, windows-app, macos]
priority: high
---

# Windows App Profile - DESKTOP-2JJ3187

This record defines the intended Windows App profile on the primary MacBook
M3 Max for GUI administration of `DESKTOP-2JJ3187`.

This is a client profile only. LAN-scoped RDP is now enabled, TCP `3389` has
been verified from the MacBook, and interactive Windows App GUI management is
verified by operator report. Static DHCP and local DNS are now verified.
Account creation, Cloudflare, WARP, OPNsense changes beyond the current WoL
registration, and any broader RDP exposure remain approval-gated in the main
Windows device record.

## Prerequisites Before First Successful Connection

- RDP is enabled on the Windows PC with Network Level Authentication.
- RDP users are limited to the approved admin or device-management account.
- Windows Firewall allows RDP only on the trusted LAN/private-overlay path.
- No RDP, WinRM, VNC, SSH, or admin service is exposed to public WAN.
- The MacBook can reach the Windows PC over the same LAN or an approved private
  overlay path.
- The target endpoint is known. Because no static IP exists yet, any DHCP IP
  profile is temporary.
- The admin credential is stored in 1Password and is not saved into chat, git,
  shell argv, or broad local config.

## Endpoint Naming

Durable profile target:

```text
desktop-2jj3187.home.arpa
```

Fallback same-LAN target options:

- `192.168.0.217`, the static Ethernet IP, if local DNS is unavailable.
- `DESKTOP-2JJ3187.local`, only if it resolves and connects reliably from the
  MacBook on the home LAN.

Do not use a public IP address or a public WAN-exposed DNS record for this
profile.

## Windows App Settings

Use these settings when adding the PC in Windows App on the MacBook.

### Global Header

| Field | Value | Notes |
|---|---|---|
| PC name | `desktop-2jj3187.home.arpa` | Required before the app enables `Add`. Do not use public WAN addressing. |
| Credentials | `Ask when required` | Do not save the admin password in Windows App for this slice. Retrieve it from 1Password when needed. |

### General

| Field | Value | Notes |
|---|---|---|
| Friendly name | `DESKTOP-2JJ3187 - Jefahnierocks Admin` | Makes the profile visibly administrative. |
| Group | `Jefahnierocks Admin` if available; otherwise `Saved PCs` | Use a dedicated group if Windows App allows creating one. |
| Gateway | `No gateway` | Cloudflare WARP/private routing is a network path, not an RD Gateway. |
| Bypass for local addresses | Checked if the app keeps it checked/disabled | Accept the app default. |
| Reconnect if the connection is dropped | Checked | Useful for remote admin over LAN or overlay. |
| Connect to an admin session | Unchecked | Do not use `/admin` semantics by default for a Windows 11 workstation. |
| Swap mouse buttons | Unchecked | Use normal local mouse behavior. |

### Display

| Field | Value | Notes |
|---|---|---|
| Resolution | `Default for this display` | Accept the app default. |
| Use all monitors | Unchecked | Start with a single predictable admin surface. |
| Start session in full screen | Checked | Good default for MacBook-based GUI administration. |
| Fit session to window | Checked if the app keeps it checked/disabled | Accept the app default. |
| Color quality | `High (32 bit)` | Appropriate for LAN/private-overlay GUI admin. |
| Optimize for Retina displays | Checked for the normal admin profile | Windows 11 supports this; turn it off only if latency/bandwidth is poor. |
| Update the session resolution on resize | Checked | Keeps the session usable when moving between windowed/full-screen modes. |

### Devices And Audio

| Field | Value | Notes |
|---|---|---|
| Printers | Unchecked | Printer redirection is not needed for administration. |
| Smart cards | Unchecked unless explicitly needed | Avoid redirecting unused auth devices. |
| Microphone | Unchecked | Not needed for administration. |
| Cameras | Unchecked | Not needed for administration. |
| Clipboard mode | `Bidirectional` only for trusted interactive admin sessions | Do not copy passwords, recovery material, private keys, tokens, or TOTP values over the RDP clipboard. Disable clipboard redirection if working in a higher-risk session. |
| Play sound | `Never` if available; otherwise leave `On this computer` | Audio is not needed for normal administration. |

### Folders

| Field | Value | Notes |
|---|---|---|
| Redirect folders | Unchecked | Do not mount Mac folders into the shared Windows PC by default. |
| Folder list | Empty | If file transfer is needed later, add a temporary non-secret folder and prefer read-only mode where practical. |

## Operational Rules

- Treat this as an admin-only profile on the MacBook, not a family-use profile.
- Do not store passwords, recovery keys, private keys, or token material inside
  the Windows App profile.
- Do not use redirected folders for source repos, secrets folders, Downloads,
  Desktop, or broad home-directory access.
- Use `desktop-2jj3187.home.arpa` for the normal profile target. Keep
  `192.168.0.217` only as a direct-IP fallback while on LAN.
- A successful Windows App connection is evidence of interactive access only.
  It does not prove the device is fully managed.

## Evidence Captured

Mac-side TCP `3389` reachability has been verified against `192.168.0.217`
and the stable FQDN `desktop-2jj3187.home.arpa`. The operator reported
successful Windows App GUI connection and remote management at 2026-05-12
20:49 AKDT, then confirmed the profile was updated to use the stable FQDN on
2026-05-13.

Recorded in `windows-pc.md` as:

```text
timestamp: 2026-05-12 20:49 AKDT
source: Windows App on MacBook M3 Max
observed: RDP GUI connection to DESKTOP-2JJ3187 over LAN worked
proof: operator attestation
repo-safe output: no public WAN path used; no credentials saved in app
private raw evidence: none recorded in repo
status: verified interactive GUI access through stable local FQDN; full
  management still pending
```
