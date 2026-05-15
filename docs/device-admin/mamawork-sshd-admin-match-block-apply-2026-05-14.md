---
title: MAMAWORK sshd Admin Match Block Apply - 2026-05-14
category: apply-record
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, mamawork, windows, openssh, sshd-config, match-block, verification]
priority: high
---

# MAMAWORK sshd Admin Match Block Apply - 2026-05-14

This records the operator-applied
[mamawork-sshd-admin-match-block packet](./mamawork-sshd-admin-match-block-packet-2026-05-14.md)
and the MacBook-side real authentication verification.

No Cloudflare, WARP, `cloudflared`, Tailscale, OPNsense, DNS, DHCP,
RDP, WinRM, account, BitLocker, Defender, 1Password item, or
per-user `.ssh` file was changed by this packet.

## Source Handback

Operator handback:
[handback-mamawork-sshd-admin-match-block-2026-05-14.md](./handback-mamawork-sshd-admin-match-block-2026-05-14.md)

```text
timestamp:                    2026-05-14T16:12:32.9515181-08:00
operator:                     MAMAWORK\jeffr
elevation:                    True
evidence slot:                C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-sshd-admin-match-block-20260514-161232\
status:                       completed
sshd restart:                 completed; service Running afterward
listener TCP/22 after restart: 0.0.0.0:22 and [::]:22
```

## What Changed

The packet appended the standard Windows OpenSSH admin Match block to
`C:\ProgramData\ssh\sshd_config`:

```text
Match Group administrators
    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

The pre-existing commented sample block remained commented. The new
active block is the appended block.

## Server-Side Verification

The operator ran the conditional OpenSSH configuration check after
the apply:

```powershell
C:\Windows\System32\OpenSSH\sshd.exe -T -C user=jeffr,host=mamawork.home.arpa,addr=127.0.0.1
```

Relevant result:

```text
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication yes
strictmodes no
authorizedkeyscommand none
authorizedkeyscommanduser none
loglevel DEBUG3
authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

This proves the active Match block applies to `MAMAWORK\jeffr` and
points sshd at `C:\ProgramData\ssh\administrators_authorized_keys`.

## MacBook Real Auth Verification

The original packet's closing probe used `hostname; whoami`. On this
Windows host that form triggered a shell-specific `hostname` error,
but it still proved the remote command executed rather than returning
`Permission denied`.

The clean Windows-compatible verification was:

```bash
ssh -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o BatchMode=yes \
  -o ConnectTimeout=5 \
  -o ControlMaster=no \
  -o ControlPath=none \
  -o HostKeyAlias=192.168.0.101 \
  jeffr@mamawork.home.arpa 'cmd /c "hostname && whoami"'
```

Result:

```text
MamaWork
mamawork\jeffr
```

Verdict: **PASS**. MAMAWORK SSH pubkey auth from the MacBook using
the 1Password-backed admin key is operational for `jeffr`.

## Notes

- The prior ACL/owner/BOM hypothesis remains closed. The actual root
  cause was the missing active `Match Group administrators` block.
- `sshd -t` emitted a non-fatal stale DSA host-key warning:
  `Unable to load host key: __PROGRAMDATA__/ssh/ssh_host_dsa_key`.
  Defer that to `mamawork-ssh-hardening`.
- `DadAdmin` SSH behavior is not part of the success criterion.
  `DadAdmin` remains enabled only because the streamline found two
  OneDrive scheduled tasks still running under its SID.
- The active concurrent-admin lane is now MacBook SSH as
  `MAMAWORK\jeffr`; this avoids the RDP single-interactive-session
  conflict with Mama's console session.

## Boundaries Held

Unchanged by this packet:

```text
administrators_authorized_keys content
per-user C:\Users\*\.ssh files
ahnie account
DadAdmin account
kid accounts
jeffr Microsoft Account
built-in Administrator
RDP rules and RDP service state
WinRM / PSRemoting
BitLocker / Secure Boot / TPM
Defender / ASR
powercfg / NIC wake
HKLM NetworkList registry
Cloudflare / WARP / cloudflared / Tailscale / OPNsense / DNS / DHCP
1Password items or secrets
```
