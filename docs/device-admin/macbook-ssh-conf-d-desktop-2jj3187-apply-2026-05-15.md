---
title: MacBook SSH conf.d Apply for DESKTOP-2JJ3187 - 2026-05-15
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, macbook, chezmoi, ssh-client, 1password, apply]
priority: high
---

# MacBook SSH conf.d Apply for DESKTOP-2JJ3187 - 2026-05-15

Apply record for
[macbook-ssh-conf-d-desktop-2jj3187-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-2026-05-15.md).
MacBook-side `workstation-config-change` only; no Windows-side
mutation. SSH reachability awaits the Phase 3
[desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
packet applying on the host.

## Prereq Mint

The 1Password admin key item was created in-place on 2026-05-14
19:05:13 AKDT via `op item create --category "SSH Key"
--ssh-generate-key=ed25519`. No on-disk private key existed at any
point; 1Password generated the keypair inside the vault.

```text
item:          op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13
id:            rld3rxqcg5dvjz6mrwthg2cgoi
account:       my.1password.com
vault:         Dev
category:      SSH_KEY
key type:      ed25519 (1P-generated)
fingerprint:   SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s
public key:    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRgw1xN2rjmlIFbAPsp7cc6SJcm0h5IMvrL8o6CyLh9
tags:          admin, desktop-2jj3187, device-admin, jefahnierocks, ssh, verlyn13, windows
created at:    2026-05-14T19:05:13-08:00
```

The public key body matches the value pinned in the install packet
v0.2.0 §S5.

## Live Changes Made (MacBook side)

Two paths under chezmoi:

1. **Modified** `home/dot_ssh/conf.d/windows.conf.tmpl` — header
   rewritten to scope the file to the Windows fleet (not MAMAWORK
   alone); MAMAWORK descriptive comments moved under a `# MAMAWORK`
   subheading; new `# DESKTOP-2JJ3187` subheading + Host stanza added.
2. **Added** `home/dot_ssh/id_ed25519_desktop_2jj3187_admin.1password.pub.tmpl`
   — single-line chezmoi template:
   ```text
   {{ onepasswordRead "op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13/public key" -}}
   ```

Applied via target-scoped chezmoi:

```bash
chezmoi diff \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub

chezmoi apply --dry-run \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub

chezmoi apply \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub
```

Applied at: 2026-05-15T03:08:00Z.

## Post-Apply Verification

```text
$ ssh -G desktop-2jj3187 | grep -iE '^(user|hostname|identityfile|identityagent|identitiesonly|hostkeyalias)'
user jeffr
hostname 192.168.0.217
identitiesonly yes
hostkeyalias 192.168.0.217
identityagent /Users/verlyn13/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
identityfile ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub

$ ls -l ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub
-rw-r--r--@ 1 verlyn13 staff 80 May 14 19:08 ...

$ ssh-keygen -lf ~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub
256 SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s no comment (ED25519)
```

Match: on-disk fingerprint equals the 1Password-source fingerprint
end-to-end.

## Not Yet Reachable

Real-auth `ssh desktop-2jj3187 'cmd /c "hostname && whoami"'` will
fail until the Windows-side
[desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
packet applies and the public-key body above is authorized in
`C:\ProgramData\ssh\administrators_authorized_keys`.

LAN probe state (informational, not a problem):

```text
TCP/22:   timeout (no listener on host yet)
TCP/3389: reachable (RDP lane unchanged)
```

## Out-of-Scope (not touched by this apply)

- Any Windows-host state on DESKTOP-2JJ3187.
- MAMAWORK's existing Host stanza (untouched).
- Any other chezmoi-managed path; broad `chezmoi apply` deliberately
  NOT run.
- DNS, DHCP, OPNsense, Cloudflare, WARP, Tailscale, 1Password fields
  beyond the just-created SSH key item.

## Boundaries

- No private-key material moved. 1P-generated key never left the
  vault.
- No secret values in tracked files. Public key body is non-secret;
  fingerprint is non-secret.
- The chezmoi template renders the public key at apply time from
  1Password; rotating the 1P item rotates the on-disk public key on
  the next chezmoi apply.

## Stop-Rule Outcomes

All preflight stop-rules passed:

- `op read` resolved the public key to a valid `ssh-ed25519` body.
- `chezmoi diff` showed only the two target paths.
- `chezmoi apply` did not warn about unrelated drift.
- `ssh -G desktop-2jj3187` resolved to the intended user, hostname,
  identity, and HostKeyAlias.

## After This Apply

Update `docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- Move `macbook-ssh-conf-d-desktop-2jj3187` from `prepared_packets[]`
  to `applied_packets[]`.
- Remove the `desktop-2jj3187-1password-admin-key-item-pending`
  blocked_item (key now exists).
- Note the on-disk fingerprint matches the 1P-source fingerprint.

Next operator-side step is the Windows-host
`desktop-2jj3187-ssh-lane-install` packet. Hand-off directive
composed separately for the DESKTOP-2JJ3187 agent.
