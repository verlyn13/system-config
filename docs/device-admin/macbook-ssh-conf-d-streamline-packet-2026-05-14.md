---
title: MacBook SSH conf.d Streamline Packet - 2026-05-14
category: operations
component: device_admin
status: applied
version: 0.3.0
last_updated: 2026-05-15
tags: [device-admin, macbook, chezmoi, ssh, conf-d, streamline]
priority: medium
---

# MacBook SSH conf.d Streamline Packet - 2026-05-14

Applied 2026-05-15T01:16:03Z. See
[macbook-ssh-conf-d-streamline-apply-2026-05-14.md](./macbook-ssh-conf-d-streamline-apply-2026-05-14.md).

Brings the operator MacBook's `~/.ssh/conf.d/` host modules in line
with the streamlined admin model:

- **One operator admin identity per device** (`jeffr` on MAMAWORK,
  `verlyn13` on fedora-top).
- **One operator admin key per device**, served by the MacBook's 1P
  SSH agent (1Password is installed on the MacBook only).
- **One named Host stanza per device**, with the short alias, the
  FQDN, and the IP all matched in a single stanza; `HostKeyAlias`
  retained for the IP form until `known_hosts` is reconciled for
  the FQDN.

Doc-only `system-config` change in this repo. The live action on
the MacBook is `chezmoi apply` which copies the rendered files
into `~/.ssh/`. No `MAMAWORK` or `fedora-top` host change. No
secrets pasted; the only operator side input is the 1Password
session that lets `chezmoi apply` resolve the `onepasswordRead`
template at apply time.

## Scope

In scope:

1. **Replace** `home/dot_ssh/conf.d/windows.conf.tmpl` with a
   minimal MAMAWORK-only stanza:
   - `Host mamawork mamawork.home.arpa 192.168.0.101`
   - `HostName 192.168.0.101`
   - `User jeffr`
   - `IdentityFile ~/.ssh/id_ed25519_mamawork_admin.1password.pub`
   - `HostKeyAlias 192.168.0.101`
   - Removes the five dead placeholder Host stanzas (`wyn-pc`,
     `ila-pc`, `axel-pc`, `bedroom-tv`, `ahnie-laptop`), all of
     which pointed at `HostName 0.0.0.0` with `IdentityFile
     ~/.ssh/dad_admin` (no live target; no working private key).
   - Replaces `User DadAdmin` + the migration-template indirection
     on `~/.ssh/dad_admin` with the streamlined `User jeffr` +
     the new 1P-backed identity file.
2. **Add** new file
   `home/dot_ssh/conf.d/fedora-top.conf.tmpl`:
   - `Host fedora-top fedora-top.home.arpa 192.168.0.206`
   - `HostName 192.168.0.206`
   - `User verlyn13`
   - `IdentityFile ~/.ssh/id_ed25519_personal.1password.pub`
   - `HostKeyAlias 192.168.0.206`
3. **Add** new file
   `home/dot_ssh/id_ed25519_mamawork_admin.1password.pub.tmpl`:
   - Single-line chezmoi template:
     `{{ onepasswordRead "op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13/public key" -}}`
   - Renders to `~/.ssh/id_ed25519_mamawork_admin.1password.pub`,
     mode `0644`, public-key body identical to the agent-served
     key (`SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY`).
   - Brings the existing on-disk artifact created during
     2026-05-15 probing under chezmoi management.

Out of scope:

- **`~/.ssh/known_hosts` reconciliation** for the FQDN forms
  (`mamawork.home.arpa`, `fedora-top.home.arpa`). Per
  [docs/ssh.md](../ssh.md), `system-config` does not own
  `known_hosts`. The existing
  [fedora-top-known-hosts-reconciliation-packet-2026-05-13.md](./fedora-top-known-hosts-reconciliation-packet-2026-05-13.md)
  covers the fedora-top side; a parallel small packet for
  MAMAWORK can follow. `HostKeyAlias` works in the interim.
- **Bringing `~/.ssh/id_ed25519_personal.1password.pub` under
  chezmoi management.** The file exists on disk
  (`SHA256:ofocO0z...`, used by both GitHub and fedora-top admin)
  but is currently unmanaged. Adding it requires knowing the
  exact `op://` path for its 1P item, which the operator should
  confirm before authoring. Future small packet.
- **Any change to managed devices** (MAMAWORK, fedora-top).
  Chezmoi apply only writes to `~/.ssh/` on the MacBook.
- **Any change to `home/dot_ssh/config.tmpl`** (the base SSH
  config). The global `Host *` block with `IdentityAgent` +
  `IdentitiesOnly yes` is unchanged. Both new host entries
  inherit that posture.
- **`home/.chezmoidata.yaml`** `host_migrations` dict. The new
  entries hardcode the IdentityFile paths rather than using the
  migration-template indirection because both 1P-backed pub
  files always exist post-apply (no legacy fallback path needed).

## Verified Current State

### Chezmoi source before this packet

```text
home/dot_ssh/
├── allowed_signers.tmpl
├── conf.d/
│   ├── github.conf.tmpl
│   ├── hetzner.conf.tmpl
│   ├── mesh.conf.tmpl
│   ├── opnsense.conf.tmpl
│   ├── proxmox.conf.tmpl
│   ├── runpod.conf.tmpl
│   └── windows.conf.tmpl     <- pre-streamline; 6 Host stanzas, 5 of them dead
├── config.tmpl
├── id_ed25519_happy_patterns.1password.pub.tmpl
└── runpod-inference.1password.pub.tmpl
```

### MacBook live state before this packet

```text
~/.ssh/conf.d/
├── github.conf
├── hetzner.conf
├── mesh.conf
├── opnsense.conf
├── proxmox.conf
├── runpod-pods.local.conf    <- local-only, off-chezmoi (preserved)
├── runpod.conf
└── windows.conf              <- pre-streamline rendered output

~/.ssh/
├── id_ed25519_personal.1password.pub        <- unmanaged; not in chezmoi source
├── id_ed25519_happy_patterns.1password.pub  <- chezmoi-managed
├── id_ed25519_mamawork_admin.1password.pub  <- created 2026-05-15 during probing; not chezmoi-managed (this packet adds it)
├── (other identity files)
└── known_hosts                              <- not chezmoi-managed, has IP entries for both 192.168.0.101 and 192.168.0.206
```

### After `chezmoi apply`

```text
home/dot_ssh/                                <- new
├── allowed_signers.tmpl
├── conf.d/
│   ├── fedora-top.conf.tmpl                 <- new
│   ├── github.conf.tmpl
│   ├── hetzner.conf.tmpl
│   ├── mesh.conf.tmpl
│   ├── opnsense.conf.tmpl
│   ├── proxmox.conf.tmpl
│   ├── runpod.conf.tmpl
│   └── windows.conf.tmpl                    <- rewritten; one stanza only
├── config.tmpl
├── id_ed25519_happy_patterns.1password.pub.tmpl
├── id_ed25519_mamawork_admin.1password.pub.tmpl    <- new
└── runpod-inference.1password.pub.tmpl

~/.ssh/conf.d/
├── fedora-top.conf                          <- new
├── ... (others unchanged) ...
├── runpod-pods.local.conf                   <- preserved (off-chezmoi)
└── windows.conf                             <- rewritten

~/.ssh/id_ed25519_mamawork_admin.1password.pub    <- chezmoi-managed; content from 1P
```

## Source Files (for review before `chezmoi apply`)

### `home/dot_ssh/conf.d/fedora-top.conf.tmpl`

```text
# fedora-top remote administration
# Managed by chezmoi
...
Host fedora-top fedora-top.home.arpa 192.168.0.206
  HostName 192.168.0.206
  User verlyn13
  IdentityFile ~/.ssh/id_ed25519_personal.1password.pub
  HostKeyAlias 192.168.0.206
```

### `home/dot_ssh/conf.d/windows.conf.tmpl` (rewritten)

```text
# MAMAWORK Windows PC remote administration
# Managed by chezmoi
...
Host mamawork mamawork.home.arpa 192.168.0.101
  HostName 192.168.0.101
  User jeffr
  IdentityFile ~/.ssh/id_ed25519_mamawork_admin.1password.pub
  HostKeyAlias 192.168.0.101
```

### `home/dot_ssh/id_ed25519_mamawork_admin.1password.pub.tmpl`

```text
{{ onepasswordRead "op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13/public key" -}}
```

## Apply Procedure

Operator runs from the MacBook with 1Password CLI signed in
(`op vault get Dev --account my.1password.com` must succeed):

```bash
# 1. From the system-config worktree, confirm working tree state
cd /Users/verlyn13/Organizations/jefahnierocks/system-config
git status

# 2. Preview ONLY this packet's target paths.
chezmoi diff \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/conf.d/fedora-top.conf \
  ~/.ssh/id_ed25519_mamawork_admin.1password.pub

# 3. Dry-run ONLY this packet's target paths.
chezmoi apply --dry-run \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/conf.d/fedora-top.conf \
  ~/.ssh/id_ed25519_mamawork_admin.1password.pub

# 4. Apply ONLY this packet's target paths if the diff and dry-run
#    match expectations.
chezmoi apply \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/conf.d/fedora-top.conf \
  ~/.ssh/id_ed25519_mamawork_admin.1password.pub

# 5. Confirm the rendered output
cat ~/.ssh/conf.d/fedora-top.conf
cat ~/.ssh/conf.d/windows.conf
ssh-keygen -lf ~/.ssh/id_ed25519_mamawork_admin.1password.pub

# 6. Smoke test: ssh client config parsing
ssh -G mamawork | grep -iE '^(user|identityfile|hostname|hostkeyalias)'
ssh -G fedora-top | grep -iE '^(user|identityfile|hostname|hostkeyalias)'
```

Do not use broad `chezmoi apply` for this packet unless the unrelated
workstation drift has been separately reviewed and approved. A
2026-05-14 terminal trial showed broad `chezmoi diff` also includes
unrelated changes under `.config/mcp/common.env`,
`.config/mise/config.toml`, `.config/rstudio/rstudio-prefs.json`, and
`.config/system-update/config`.

### Expected scoped `chezmoi diff` summary

```text
add    ~/.ssh/conf.d/fedora-top.conf
update ~/.ssh/conf.d/windows.conf
update ~/.ssh/id_ed25519_mamawork_admin.1password.pub
```

### Expected `ssh -G mamawork` (relevant lines)

```text
user jeffr
identityfile ~/.ssh/id_ed25519_mamawork_admin.1password.pub
hostname 192.168.0.101
hostkeyalias 192.168.0.101
```

### Expected `ssh -G fedora-top` (relevant lines)

```text
user verlyn13
identityfile ~/.ssh/id_ed25519_personal.1password.pub
hostname 192.168.0.206
hostkeyalias 192.168.0.206
```

## Verification

After `chezmoi apply`, no actual SSH connection is required to
prove the chezmoi-managed state is correct. Functional verification
is gated on:

- For MAMAWORK: the admin-streamline, sshd Match-block, and MacBook
  conf.d applies have all landed. Current proof is
  `ssh mamawork 'cmd /c "hostname && whoami"'`, expected to return
  `MamaWork` / `mamawork\jeffr`.
- For fedora-top: existing path is already operational
  (`ssh fedora-top 'hostname; whoami'` already works; this packet
  just brings the conf.d entry under chezmoi management).

## Rollback

```bash
# 1. Git revert the system-config commit that landed these source
#    changes (or git restore the three files individually).
cd /Users/verlyn13/Organizations/jefahnierocks/system-config
git restore home/dot_ssh/conf.d/windows.conf.tmpl
rm -f home/dot_ssh/conf.d/fedora-top.conf.tmpl
rm -f home/dot_ssh/id_ed25519_mamawork_admin.1password.pub.tmpl

# 2. Re-apply chezmoi (writes the pre-streamline windows.conf and
#    removes the unmanaged fedora-top.conf + .pub file).
chezmoi apply

# 3. Confirm pre-streamline state restored
diff <(cat ~/.ssh/conf.d/windows.conf) <(git show HEAD~1:home/dot_ssh/conf.d/windows.conf.tmpl | sed -n '8,$p')
```

The on-disk `~/.ssh/id_ed25519_mamawork_admin.1password.pub` may
or may not be removed by `chezmoi apply` depending on whether
chezmoi considers it newly-managed. If it persists post-rollback,
remove it manually with `rm ~/.ssh/id_ed25519_mamawork_admin.1password.pub`.

## Required Approval Phrase

```text
I approve applying the MacBook SSH conf.d Streamline packet live
now on the MacBook via chezmoi apply. The source changes
(home/dot_ssh/conf.d/fedora-top.conf.tmpl new;
home/dot_ssh/conf.d/windows.conf.tmpl rewritten to a single
mamawork stanza using User jeffr +
~/.ssh/id_ed25519_mamawork_admin.1password.pub +
HostKeyAlias 192.168.0.101, with the prior 6 placeholder Host
stanzas removed; home/dot_ssh/id_ed25519_mamawork_admin.1password.pub.tmpl
new, content from onepasswordRead op://Dev/jefahnierocks-device-mamawork-admin-ssh-verlyn13/public key)
are committed to system-config. From the MacBook, run chezmoi diff
to preview, confirm only the three documented files change, then
chezmoi apply. Do NOT modify ~/.ssh/known_hosts. Do NOT modify
~/.ssh/config base file. Do NOT modify other conf.d entries
(github.conf, hetzner.conf, mesh.conf, opnsense.conf, proxmox.conf,
runpod.conf, runpod-pods.local.conf). Do NOT modify any 1Password
item. Do NOT touch fedora-top or MAMAWORK from this apply. Verify
post-apply with ssh -G mamawork and ssh -G fedora-top showing the
documented User / IdentityFile / HostName / HostKeyAlias values.
End-to-end SSH probe to mamawork.home.arpa remains gated on the
mamawork-admin-streamline packet closing the
administrators_authorized_keys ACL/BOM issue.
```

## Evidence Template

```text
timestamp:
operator:
chezmoi diff (one line per file change):
chezmoi apply exit code:
ssh -G mamawork relevant lines:
  user jeffr
  identityfile ~/.ssh/id_ed25519_mamawork_admin.1password.pub
  hostname 192.168.0.101
  hostkeyalias 192.168.0.101
ssh -G fedora-top relevant lines:
  user verlyn13
  identityfile ~/.ssh/id_ed25519_personal.1password.pub
  hostname 192.168.0.206
  hostkeyalias 192.168.0.206
ssh-keygen -lf ~/.ssh/id_ed25519_mamawork_admin.1password.pub:
  256 SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY ...
sanity ssh fedora-top 'hostname':
  fedora-top (or: not run because fedora-top offline)
remaining blockers:
  end-to-end ssh mamawork gated on mamawork-admin-streamline applying
```

Do NOT paste private keys, 1Password item UUIDs, secret-reference
URIs with field paths (the template's `op://...` reference is
fine since it has no secret material), or any other sensitive
content.

## Boundary Assertions

After this packet applies, the following are **unchanged**:

- `~/.ssh/config` base file (chezmoi-managed `config.tmpl`).
- `~/.ssh/conf.d/github.conf`, `hetzner.conf`, `mesh.conf`,
  `opnsense.conf`, `proxmox.conf`, `runpod.conf`,
  `runpod-pods.local.conf`.
- `~/.ssh/known_hosts` (not chezmoi-managed; FQDN reconciliation
  is a separate packet).
- `~/.ssh/allowed_signers` (chezmoi-managed; unrelated to this
  packet).
- `~/.ssh/id_ed25519_personal.1password.pub` (on disk, unmanaged;
  this packet references it but does not manage it; future small
  packet brings it under chezmoi management).
- Any other identity file in `~/.ssh/`.
- All 1Password items.
- MAMAWORK, fedora-top, OPNsense, Cloudflare, Tailscale, DNS,
  DHCP — no `chezmoi apply` change touches any managed device.

## Sequencing With Other Packets

- **Parallel-safe** with
  [`mamawork-admin-streamline`](./mamawork-admin-streamline-packet-2026-05-14.md):
  the MacBook chezmoi apply and the MAMAWORK PowerShell apply
  affect different surfaces. Either order works. End-to-end SSH
  verification requires both.
- **Builds on** the
  [`mamawork-ssh-key-bootstrap-apply-2026-05-14.md`](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md)
  (which put the matching public key into
  `administrators_authorized_keys` on MAMAWORK).
- **Supersedes the dead `~/.ssh/dad_admin` IdentityFile path**
  in `windows.conf.tmpl`. The `dad_admin` file remains on disk
  for now (Dec 7 2025 last-modified); a future cleanup packet
  can decide its fate (likely delete; no matching private half
  in 1P agent).
- **Unblocks** the planned chezmoi-managed
  `~/.ssh/conf.d/known_hosts.d/*.conf` or analogous FQDN
  reconciliation packets for both MAMAWORK and fedora-top.

## Related

- [mamawork-admin-streamline-packet-2026-05-14.md](./mamawork-admin-streamline-packet-2026-05-14.md) -
  the MAMAWORK-side companion. Together they unblock MacBook ->
  MAMAWORK SSH end-to-end.
- [mamawork-ssh-key-bootstrap-apply-2026-05-14.md](./mamawork-ssh-key-bootstrap-apply-2026-05-14.md) -
  the bootstrap that installed the public key on MAMAWORK.
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [fedora-top-known-hosts-reconciliation-packet-2026-05-13.md](./fedora-top-known-hosts-reconciliation-packet-2026-05-13.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
