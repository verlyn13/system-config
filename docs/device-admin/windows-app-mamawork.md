---
title: MacBook Windows App Profile - MAMAWORK
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows-app, rdp, macbook, lan]
priority: high
---

# MacBook Windows App Profile - MAMAWORK

This document captures the Windows App (Microsoft Remote Desktop)
profile settings the operator uses on the MacBook to administer
MAMAWORK over LAN RDP. It pairs with the
[mamawork-lan-rdp-implementation packet (2026-05-14)](./mamawork-lan-rdp-implementation-2026-05-14.md)
and mirrors the
[windows-app-desktop-2jj3187.md](./windows-app-desktop-2jj3187.md)
pattern for the first Windows PC.

This is documentation only. No live `system-config` host change or
MAMAWORK change is authorized by this file; the operator configures
the Windows App profile interactively on the MacBook.

## Profile Settings

Add a new PC entry in **Windows App** (Mac) with the values below.
The Windows App UI may label fields slightly differently across
versions; the names below match Windows App 11.x.

| Field | Value | Why |
|---|---|---|
| PC name | `mamawork.home.arpa` | LAN-stable FQDN from the 2026-05-14 HomeNetOps PASS; resolves to `192.168.0.101` on the home LAN. Avoid using the raw IP so the profile keeps working if the IP changes through a future OPNsense reservation update. |
| Friendly name | `MAMAWORK - Jefahnierocks Admin` | Distinguishes from the existing DESKTOP-2JJ3187 entry. |
| Credentials | `Ask when required` | Never save admin credentials in Windows App. Operator enters the username + password at connect time. |
| Gateway | `No gateway` | LAN-only path. No RD Gateway, no Cloudflare Access tunnel - those are separate future packets. |
| Reconnect if connection is dropped | **checked** | Mini-PC stays on AC; reconnect handles brief network blips. |
| Connect to an admin session | **unchecked** | Use a standard interactive session. The admin-session toggle (`/admin`) is for connecting to Windows Server console; it is irrelevant on a Windows 11 Pro client and can cause unexpected behavior. |
| Redirected folders | **none** | No file-redirection across the Windows App boundary. |
| Redirected devices (printers, smart cards, clipboard, etc.) | minimum needed (default off; enable clipboard only if needed) | Reduce the data crossing into the MacBook. |
| Display resolution | `Match the client` (or pick a specific resolution as preferred) | No security implication; operator preference. |
| Sound | Mute or Play on this Mac | No security implication. |
| Sound recording (microphone) | **unchecked** | Disable mic redirection by default. |

## Credentials At Connect Time

Two practical choices for the username form when prompted:

| Username form | Account | Notes |
|---|---|---|
| `MAMAWORK\DadAdmin` | Local Windows administrator account | Matches the intake's existing administrator path. Password is operator memory / 1Password (separate item; `system-config` does not create or read it). |
| `MAMAWORK\jeffr` or `jeffr@<MS-tenant>` | Microsoft Account `jeffr` (administrator) | Uses Microsoft Account sign-in. May trigger MS Account MFA depending on tenant policy. |

Either works for the first RDP test. The packet does **not** add
anyone to `Remote Desktop Users` because both accounts above are
already members of `Administrators`, which inherits RDP rights.

## What Must Not Be Saved Or Configured

- **No saved password / credential.** Windows App's "remember
  credentials" option must stay **off** for this profile. The
  operator types or pastes-from-1Password at connect time.
- **No public IP or DNS** as the `PC name`. LAN-only paths
  (`mamawork.home.arpa` or `192.168.0.101`) only. If a future
  Cloudflare Access path is approved, that is a separate Windows
  App profile (or a separate Cloudflare WARP-routed profile),
  not an edit to this one.
- **No RD Gateway**, no jump host, no SSH tunnel.
- **No credential prompt for the kid Windows accounts.** The
  kids (`ahnie`, `axelp`, `ilage`, `wynst`) continue to sign in
  locally on MAMAWORK with their own Microsoft Accounts; the
  MacBook Windows App profile is the operator's administrative
  path, not a family-shared profile.

## First-Connection Test Plan

1. Confirm the
   [mamawork-lan-rdp-implementation-2026-05-14.md](./mamawork-lan-rdp-implementation-2026-05-14.md)
   script has been applied on MAMAWORK and the evidence file shows
   `TcpTestSucceeded=True` for `127.0.0.1:3389`.
2. From the MacBook, verify reachability:
   ```bash
   nc -vz -G 3 mamawork.home.arpa 3389
   nc -vz -G 3 192.168.0.101 3389
   ```
   Both must succeed.
3. Open Windows App, select the `MAMAWORK - Jefahnierocks Admin`
   profile, and connect.
4. Enter the chosen username form (`MAMAWORK\DadAdmin` or
   `MAMAWORK\jeffr`). Provide the password at the prompt; do not
   tick "remember credentials".
5. Confirm the interactive session lands on MAMAWORK and the
   administrator desktop is usable.
6. Disconnect; do not save credentials.

## Evidence To Capture After First Successful Connection

In a repo-safe summary block (for ingest into
[windows-pc-mamawork.md](./windows-pc-mamawork.md) and an apply
record at `mamawork-lan-rdp-implementation-apply-2026-05-14.md`):

```text
timestamp:
operator:
profile name:                 MAMAWORK - Jefahnierocks Admin
PC name in profile:           mamawork.home.arpa
credentials policy:           Ask when required (no saved credentials)
gateway:                      No gateway
admin session toggle:         unchecked
nc -vz mamawork.home.arpa:3389:        Succeeded
nc -vz 192.168.0.101:3389:             Succeeded
Windows App GUI connection:            Succeeded
username form used:                    MAMAWORK\DadAdmin  | MAMAWORK\jeffr
credentials saved in Windows App:      no
public WAN path used:                  no
credentials in repo/chat/shell argv:   no
remaining blockers:
```

Do NOT paste passwords, RDP credential blobs, or any secret value
into the evidence block.

## Related

- [mamawork-lan-rdp-implementation-2026-05-14.md](./mamawork-lan-rdp-implementation-2026-05-14.md) -
  the Windows-side RDP enablement packet this profile depends on.
- [windows-app-desktop-2jj3187.md](./windows-app-desktop-2jj3187.md) -
  the precedent profile for the first Windows PC.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md) -
  the HomeNetOps PASS that established `mamawork.home.arpa`.
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
