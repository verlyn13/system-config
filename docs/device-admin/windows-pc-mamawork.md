---
title: MAMAWORK Device Administration Record
category: operations
component: device_admin
status: active
version: 0.2.0
last_updated: 2026-05-15
tags: [device-admin, windows, mamawork, openssh, rdp, powershell, cloudflare]
priority: high
---

# MAMAWORK Device Administration Record

MAMAWORK is a Jefahnierocks-managed Windows 11 Pro mini-PC used by
Mama / Litecky and the kids. This record is current state only. Packet
and apply documents hold the detailed evidence trail.

Read first:

- [current-status.yaml](./current-status.yaml) - machine-readable state
  and next action.
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) -
  shared Windows fleet terminal-admin procedure.
- [handoff-mamawork.md](./handoff-mamawork.md) - short operator
  decisions and next packet list.

## Current Posture

| Surface | Current state |
|---|---|
| Hostname / DNS / IP | `MAMAWORK`, `mamawork.home.arpa`, `192.168.0.101` |
| Network | Wired `Ethernet 2`, Realtek GbE, host-static IPv4. OPNsense reservation and Unbound override exist; `permanent=false` until the host switches to DHCP. |
| Primary admin lane | MacBook -> MAMAWORK OpenSSH over LAN as `MAMAWORK\jeffr`. |
| SSH key | 1Password-backed ED25519 admin key `SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY`, item `op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13`. Private half stays on the MacBook 1Password SSH agent. |
| SSH server | `sshd` running on TCP/22. `PasswordAuthentication no`. Admin users are mapped to `C:\ProgramData\ssh\administrators_authorized_keys` by the standard Windows OpenSSH `Match Group administrators` block. |
| SSH firewall | `Jefahnierocks SSH LAN TCP 22`, Private profile, `192.168.0.0/24`. Legacy `Dad Remote Management` is disabled. |
| RDP | LAN-only fallback via MacBook Windows App, NLA on, custom TCP/UDP 3389 Private-profile rules scoped to `192.168.0.0/24`. Works, but prompts the active console user to log out; use SSH for concurrent admin. |
| PowerShell | Explicit PowerShell over SSH is ready. Native `New-PSSession -HostName` is not configured; no PowerShell SSH subsystem yet. |
| WinRM / PSRemoting | Stopped and firewall-disabled by design. |
| Cloudflare / WARP | Not installed/enrolled. Target is Windows multi-user WARP, not one Kids identity for the whole machine. |
| Security deferred | BitLocker off, Secure Boot off, backup not configured, Defender exclusions not yet reviewed. |

## Verified Terminal Path

Use the short alias from the MacBook:

```bash
ssh mamawork 'cmd /c "hostname && whoami"'
```

Expected:

```text
MamaWork
mamawork\jeffr
```

PowerShell 7 is also callable:

```bash
ssh mamawork 'pwsh -NoLogo -NoProfile -NonInteractive -Command "$PSVersionTable.PSVersion.ToString(); hostname; whoami"'
```

Expected:

```text
7.6.1
MamaWork
mamawork\jeffr
```

For management commands, invoke the Windows shell explicitly:

```bash
ssh mamawork 'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Service sshd,TermService,WinRM"'
```

Do not assume Windows OpenSSH parses POSIX shell syntax.

## Account Posture

| Account / group | Current decision |
|---|---|
| `jeffr` | Operator admin account and primary SSH admin identity. |
| `ahnie` | Mama / Litecky work account. Intentional local Administrator; do not modify unless explicitly authorized. |
| `DadAdmin` | Legacy local admin. Still enabled because two OneDrive scheduled tasks run as its SID. Future decision: re-register tasks, unregister tasks, or keep the account but reduce privilege. |
| `Administrator` | Built-in account, disabled. |
| `axelp`, `ilage`, `wynst` | Kid accounts; not admin accounts per current intake. Specific kid-to-account mapping is only needed if a future packet acts per-user. |
| `CodexSandboxOnline`, `CodexSandboxOffline`, `WsiAccount` | Purpose still needs operator confirmation before privilege cleanup. |

## Next Work

1. **Read-only terminal-admin baseline** over `ssh mamawork`.
   Capture service, firewall, account, OpenSSH, and optional-feature
   state. Use Windows PowerShell 5.1 for
   `Get-WindowsCapability -Online` and
   `Get-WindowsOptionalFeature -Online`; the previous PowerShell 7
   intake hit `Class not registered`.
2. **SSH hardening packet** after the baseline:
   remove stale DSA host-key reference, lower `LogLevel DEBUG3`,
   decide `StrictModes`, decide `AllowGroups`, reconcile
   `C:\Users\jeffr\.ssh\authorized_keys.txt`, and decide whether to
   delete the disabled `Dad Remote Management` rule.
3. **DadAdmin / OneDrive decision** before disabling or deleting the
   account.
4. **Known-hosts reconciliation** for `mamawork.home.arpa`, then drop
   temporary `HostKeyAlias 192.168.0.101` from the MacBook SSH stanza.
5. **Cloudflare WARP rebaseline** in `cloudflare-dns` before any WARP
   install: admin/adult, Mama/Litecky, and kid Windows users must land
   in separate Zero Trust profiles under Windows multi-user mode.
6. **Backup, BitLocker, Secure Boot, Defender exclusions** remain
   separate future packets.

## Boundaries

- No public WAN exposure.
- No WinRM unless a future exception packet names the need and rollback.
- No changes to `ahnie` without explicit approval.
- No Cloudflare, WARP, DNS, DHCP, OPNsense, or 1Password secret changes
  from this record.
- No broad `chezmoi apply` for device-admin work when unrelated drift is
  present; use target-scoped commands.

## Evidence Links

Primary current-state evidence:

- [mamawork-ssh-key-bootstrap-apply-2026-05-14.md](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md)
- [mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md)
- [mamawork-admin-streamline-apply-2026-05-14.md](./mamawork-admin-streamline-apply-2026-05-14.md)
- [mamawork-sshd-admin-match-block-apply-2026-05-14.md](./mamawork-sshd-admin-match-block-apply-2026-05-14.md)
- [macbook-ssh-conf-d-streamline-apply-2026-05-14.md](./macbook-ssh-conf-d-streamline-apply-2026-05-14.md)
- [mamawork-lan-rdp-implementation-apply-2026-05-14.md](./mamawork-lan-rdp-implementation-apply-2026-05-14.md)
- [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md)
- [cloudflare-windows-multi-user-ingest-2026-05-15.md](./cloudflare-windows-multi-user-ingest-2026-05-15.md)

Raw intake bundles remain local-only and are not committed:

```text
/Users/verlyn13/Downloads/mamaworkpc/
```
