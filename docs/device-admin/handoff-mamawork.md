---
title: MAMAWORK Operator Handoff
category: operations
component: device_admin
status: active
version: 0.2.0
last_updated: 2026-05-15
tags: [device-admin, handoff, windows, mamawork, openssh]
priority: high
---

# MAMAWORK Operator Handoff

MAMAWORK is reachable from the MacBook by SSH and RDP. This handoff
only tracks unresolved decisions and the next packets. It does not
authorize live changes by itself.

## Current Admin Path

```bash
ssh mamawork 'cmd /c "hostname && whoami"'
```

Expected:

```text
MamaWork
mamawork\jeffr
```

Use explicit PowerShell commands over SSH for terminal admin. Keep RDP
as GUI fallback because it can displace Mama's active console session.

## Resolved Decisions

| Topic | Decision |
|---|---|
| Admin source | MacBook is the admin client. 1Password is not installed on MAMAWORK or fedora-top. |
| Admin key | MAMAWORK uses the device-scoped 1Password SSH key `SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY`. |
| Legacy `DadAdmin_WinNet` key | Private half is not on fedora-top; public line removed from `administrators_authorized_keys`. |
| SSH auth blocker | Fixed by restoring Windows OpenSSH `Match Group administrators` -> `AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`. |
| `ahnie` | Mama / Litecky work account; intentional local Administrator; do not modify without explicit approval. |
| RDP | Works on LAN via Windows App; secondary to SSH because Windows 11 Pro permits only one interactive user session. |
| Cloudflare profile model | MAMAWORK should use Windows multi-user WARP so admin/adult, Mama/Litecky, and kid accounts land in separate profiles. |

## Operator Decisions Still Needed

| Decision | Why it matters |
|---|---|
| MAMAWORK room / physical context | Helps set wake, RDP, and outage expectations. |
| Stay-awake vs sleep-with-WoL | Drives power policy and WoL testing. |
| Ethernet-only vs future Wi-Fi | Wi-Fi could change IP/DNS assumptions. |
| Wake from shutdown, sleep, or both | Determines WoL scope. |
| BitLocker off | Decide intentional, defer, or future-enable. |
| Secure Boot off | Decide intentional, defer, or future-enable. |
| Windows Hello / PIN | Sign-in and recovery assumptions. |
| `DadAdmin` OneDrive tasks | Choose re-register tasks, unregister tasks, or keep account with reduced privilege. |
| `CodexSandboxOnline`, `CodexSandboxOffline`, `WsiAccount` | Needed before privilege cleanup. |
| Defender exclusions | Operator should review values before any cleanup. |
| Backup plan | Current state has no backup. |
| Mama / Litecky Cloudflare identity | Needed before WARP multi-user profile mapping. |

## Next Packets

| Packet | Status | Scope |
|---|---|---|
| `mamawork-terminal-admin-baseline` | next recommended | Read-only over `ssh mamawork`; capture service/firewall/account/OpenSSH/optional-feature state. |
| `mamawork-ssh-hardening` | planned | Clean stale sshd config, decide `StrictModes` / `AllowGroups`, remove legacy SSH surface if appropriate. |
| `mamawork-powershell-over-ssh-subsystem` | optional | Add native PowerShell SSH subsystem only if `New-PSSession -HostName` is needed. |
| `mamawork-dadadmin-followup` | decision-gated | Handle OneDrive tasks, then disable/delete or reduce `DadAdmin`. |
| `mamawork-known-hosts-reconciliation` | planned | Add trusted `mamawork.home.arpa` known_hosts entry, then remove `HostKeyAlias 192.168.0.101`. |
| `mamawork-cloudflare-warp-cutover` | blocked | Wait for `cloudflare-dns` Windows multi-user rebaseline. |
| `mamawork-backup-plan` | planned | Define backup/restore target before relying on the box for durable work. |
| `mamawork-bitlocker-secureboot` | planned | Separate interactive security-hardening packet. |

## Evidence

Use [windows-pc-mamawork.md](./windows-pc-mamawork.md) for the concise
current-state record and [current-status.yaml](./current-status.yaml) for
packet status. Detailed apply evidence remains in the packet/apply docs
linked from those files.
