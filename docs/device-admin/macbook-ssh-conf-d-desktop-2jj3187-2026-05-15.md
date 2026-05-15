---
title: MacBook SSH conf.d Packet for DESKTOP-2JJ3187 - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, macbook, chezmoi, ssh-client, 1password, phase-3]
priority: high
---

# MacBook SSH conf.d Packet for DESKTOP-2JJ3187 - 2026-05-15

This packet adds a MacBook-side SSH client alias for DESKTOP-2JJ3187,
using the same shape as the MAMAWORK conf.d streamline applied on
2026-05-15 (`acc0442`).

## Scope

`workstation-config-change`. Two paths in the system-config chezmoi
source:

1. **Modify** `home/dot_ssh/conf.d/windows.conf.tmpl` — add a `Host`
   stanza for `desktop-2jj3187` alongside the existing MAMAWORK stanza.
2. **Add** `home/dot_ssh/id_ed25519_desktop_2jj3187_admin.1password.pub.tmpl`
   — chezmoi template that fetches the public key body from 1Password
   item `op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13`.

Out of scope: any Windows host change, any 1Password item creation,
any Cloudflare/WARP/DNS/DHCP/OPNsense state, the broad chezmoi state
(target-scoped commands only).

## Prerequisites

1. The 1Password item must exist with both private and public key
   fields:
   ```text
   op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13
     fields: private key, public key, fingerprint, comment
   ```
   This is the same prerequisite recorded by
   [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md).
2. The MacBook 1Password app and 1Password SSH agent are running and
   the agent socket is reachable at
   `~/.1password-ssh-agent.sock` (chezmoi-managed; existing MAMAWORK
   path uses this).

This packet can be applied **before or after** the Windows-side install
packet. SSH reachability requires both to be in place; the workstation
config alone simply means `ssh desktop-2jj3187` will resolve to the
intended user/host/key combination but fail at connect time until the
Windows host has the corresponding public key authorized.

## Approval Phrase

> Apply the `macbook-ssh-conf-d-desktop-2jj3187` packet from the
> system-config branch. Target-scoped `chezmoi diff` →
> `chezmoi apply --dry-run` → `chezmoi apply` for exactly these three
> paths (note: the public key template render is a single rendered
> file): `~/.ssh/conf.d/windows.conf` and
> `~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub`. Do not run
> a broad `chezmoi apply` while other workstation drift is present.

## Source Change: `home/dot_ssh/conf.d/windows.conf.tmpl`

Add a second `Host` stanza below the MAMAWORK stanza. The existing
file (post-2026-05-14 streamline) ends with the MAMAWORK stanza only.

New stanza to add:

```sshconfig

Host desktop-2jj3187 desktop-2jj3187.home.arpa 192.168.0.217
  HostName 192.168.0.217
  User jeffr
  IdentityFile ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub
  HostKeyAlias 192.168.0.217
```

Existing header comment block should be updated minimally to mention
both managed hosts. Suggested edit to the top-of-file comment:

```diff
-# MAMAWORK Windows PC remote administration
-# Managed by chezmoi
+# Windows fleet remote administration (MacBook side)
+# Managed by chezmoi
```

And add a paragraph after the MAMAWORK paragraph:

```text
# DESKTOP-2JJ3187 admin path: MacBook -> desktop-2jj3187.home.arpa
# over LAN SSH or RDP. 1Password item
# op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13
# holds the keypair; the public-key template
# id_ed25519_desktop_2jj3187_admin.1password.pub.tmpl renders to a
# file the SSH client points at.
#
# HostKeyAlias 192.168.0.217 is kept while desktop-2jj3187.home.arpa
# has no known_hosts entry. A future
# desktop-2jj3187-known-hosts-reconciliation packet adds the FQDN
# form, at which point this directive can be dropped.
```

## New Source File: `home/dot_ssh/id_ed25519_desktop_2jj3187_admin.1password.pub.tmpl`

Single-line chezmoi template:

```text
{{ onepasswordRead "op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13/public key" -}}
```

This pulls only the public-key field. The private half stays in
1Password and is served at SSH client time by the 1Password agent.

## Apply Procedure (operator MacBook)

```bash
# 1. Verify the 1Password item resolves before chezmoi rendering.
op read 'op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13/public key' | head -c 200
# Expected: starts with `ssh-ed25519 AAAA...` and ends with
# `verlyn13@desktop-2jj3187-admin`.

# 2. Target-scoped diff.
chezmoi diff \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub

# 3. Target-scoped dry-run.
chezmoi apply --dry-run \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub

# 4. Target-scoped apply.
chezmoi apply \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub

# 5. Verify ssh -G resolution.
ssh -G desktop-2jj3187 | grep -iE '^(user|hostname|identityfile|identityagent|identitiesonly|hostkeyalias)'
```

Expected `ssh -G desktop-2jj3187` output (after apply):

```text
user jeffr
hostname 192.168.0.217
identityfile /Users/verlyn13/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub
identityagent /Users/verlyn13/.1password-ssh-agent.sock
identitiesonly yes
hostkeyalias 192.168.0.217
```

If any field is wrong, stop and re-read the template files — do NOT
run a broad `chezmoi apply` to "fix" it.

## Validation (post-apply, on MacBook)

```bash
# 1. Public key file exists and parses.
ls -l ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub
ssh-keygen -lf ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub

# 2. ssh -G resolves to the intended target.
ssh -G desktop-2jj3187 | grep -iE '^(user|hostname|identityfile|hostkeyalias)'

# 3. Real-auth probe — succeeds only after the Windows-side install
#    packet has authorized the public key.
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

Expected from step 3 once the host side is also applied:

```text
DESKTOP-2JJ3187
desktop-2jj3187\jeffr
```

If step 3 fails with `Permission denied (publickey)`:

- Verify the Windows-side
  `desktop-2jj3187-ssh-lane-install-2026-05-15` packet apply record
  is complete.
- Verify the public-key fingerprint matches between the 1P item and
  `C:\ProgramData\ssh\administrators_authorized_keys` on the Windows
  host.

If step 3 fails with TCP timeout, the Windows-side install hasn't
opened the firewall yet.

## Stop Rules

Stop and surface to system-config rather than improvising if:

- `op read` of the public key field returns empty or a non-public-key
  string.
- `chezmoi diff` shows unrelated drift in the two target paths.
- `chezmoi apply` without targets is suggested as a "fix" — do not
  run that without a fresh decision.
- `ssh -G desktop-2jj3187` resolves to defaults (no Host alias
  matched) after apply — the template path is wrong.

## Rollback

Revert is a normal git revert of this packet's chezmoi-source commit
plus a target-scoped `chezmoi apply` of the reverted file paths. No
Windows-side state is touched by this packet's rollback.

## After Apply

Update `docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- Add this packet to `applied_packets[]` with packet_commit,
  apply_commit, applied_at, outcome.

The companion install packet's apply record records the Windows-side
state; this packet's apply record records the MacBook-side state.

The combination promotes DESKTOP-2JJ3187 to
`classification: reference-ssh-host` and `lifecycle_phase: 3`.
