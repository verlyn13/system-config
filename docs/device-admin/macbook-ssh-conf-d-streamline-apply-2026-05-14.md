---
title: MacBook SSH conf.d Streamline Apply - 2026-05-14
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, macbook, chezmoi, ssh, conf-d, mamawork, fedora-top]
priority: high
---

# MacBook SSH conf.d Streamline Apply - 2026-05-14

This records the approved MacBook-side apply of
[macbook-ssh-conf-d-streamline-packet-2026-05-14.md](./macbook-ssh-conf-d-streamline-packet-2026-05-14.md).

```text
applied_at_utc:   2026-05-15T01:16:03Z
applied_at_local: 2026-05-14T17:16:03-08:00
operator_context: system-config agent from MacBook terminal
scope_class:      workstation-config-change
```

## Scope

Applied only these chezmoi targets on the MacBook:

```text
~/.ssh/conf.d/windows.conf
~/.ssh/conf.d/fedora-top.conf
~/.ssh/id_ed25519_mamawork_admin.1password.pub
```

No managed Windows or Fedora host was changed.

## Commands

Dry-run:

```bash
chezmoi apply --dry-run \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/conf.d/fedora-top.conf \
  ~/.ssh/id_ed25519_mamawork_admin.1password.pub
```

Result: exit 0, no output.

Apply:

```bash
chezmoi apply \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/conf.d/fedora-top.conf \
  ~/.ssh/id_ed25519_mamawork_admin.1password.pub
```

Result: exit 0, no output.

## Verification

MAMAWORK client parse:

```text
user jeffr
hostname 192.168.0.101
identitiesonly yes
hostkeyalias 192.168.0.101
identityagent /Users/verlyn13/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
identityfile ~/.ssh/id_ed25519_mamawork_admin.1password.pub
```

fedora-top client parse:

```text
user verlyn13
hostname 192.168.0.206
identitiesonly yes
hostkeyalias 192.168.0.206
identityagent /Users/verlyn13/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
identityfile ~/.ssh/id_ed25519_personal.1password.pub
```

MAMAWORK admin public-key fingerprint:

```text
256 SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY no comment (ED25519)
```

Short-alias MAMAWORK auth proof:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 mamawork 'cmd /c "hostname && whoami"'
```

Returned:

```text
MamaWork
mamawork\jeffr
```

PowerShell 7 proof over the same short alias:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 mamawork \
  'pwsh -NoLogo -NoProfile -NonInteractive -Command "$PSVersionTable.PSVersion.ToString(); hostname; whoami"'
```

Returned:

```text
7.6.1
MamaWork
mamawork\jeffr
```

## Boundaries

The apply did not touch:

```text
~/.ssh/known_hosts
~/.ssh/config
other ~/.ssh/conf.d entries
allowed_signers
1Password items
MAMAWORK
fedora-top
Cloudflare / WARP / DNS / DHCP / OPNsense
Windows accounts or groups
```

Broad `chezmoi apply` was intentionally not used because broad
`chezmoi diff` currently includes unrelated workstation drift outside
this device-admin packet.

## Result

PASS. The short `ssh mamawork` path is now operational from the MacBook
and uses the intended streamlined identity, host, key, and host-key alias.
The `fedora-top` short alias now parses to the intended client config;
no live `fedora-top` connection was required by this packet.

Remaining related follow-ups:

- MAMAWORK known_hosts FQDN reconciliation, so `HostKeyAlias 192.168.0.101`
  can eventually be removed.
- fedora-top known_hosts FQDN reconciliation, already tracked by the
  prepared fedora-top known_hosts packet.
- Optional chezmoi management for
  `~/.ssh/id_ed25519_personal.1password.pub`, once the exact 1Password
  item path is confirmed.
