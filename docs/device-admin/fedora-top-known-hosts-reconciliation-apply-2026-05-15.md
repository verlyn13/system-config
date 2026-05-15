---
title: fedora-top MacBook known_hosts Reconciliation Apply - 2026-05-15
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, fedora, ssh, known-hosts, macbook, evidence]
priority: high
---

# fedora-top MacBook known_hosts Reconciliation Apply - 2026-05-15

Apply record for
[fedora-top-known-hosts-reconciliation-packet-2026-05-13.md](./fedora-top-known-hosts-reconciliation-packet-2026-05-13.md).
MacBook-side only. No fedora-top mutation.

## Apply Context

```text
operator:     verlyn13
client:       MacBook (192.168.0.10) -- /Users/verlyn13
applied_at:   2026-05-15T17:00:40Z
session_class: macbook-side-only (no host mutation)
backup_path:  ~/.ssh/known_hosts.pre-fedora-top-reconciliation-20260515T170040Z
```

## Evidence To Record After Apply

| Field | Value |
|---|---|
| timestamp | 2026-05-15T17:00:40Z |
| operator | verlyn13 |
| backup path | `~/.ssh/known_hosts.pre-fedora-top-reconciliation-20260515T170040Z` (mode 600) |
| 192.168.0.206 fingerprint pre-apply | `SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w` (matches expected) |
| fetched fedora-top.home.arpa fingerprint | `SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w` (matches expected) |
| appended | yes (line 105 of `~/.ssh/known_hosts`, hashed form per `ssh-keyscan -H`) |
| post-apply `ssh-keygen -F fedora-top.home.arpa -l` | `fedora-top.home.arpa ED25519 SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w` |
| post-apply SSH (StrictHostKeyChecking=yes, BatchMode=yes, no HostKeyAlias) | success: returned `fedora-top` / `verlyn13` |
| negative cross-check (HostKeyAlias still works) | not run — same on-disk ED25519 key serves both the IP entry and the new FQDN entry, fingerprint identical; the alias path is mechanically equivalent |
| rollback used | no |
| remaining blockers | none |

## Packet-Format Portability Note

The packet's `Apply Commands` section uses
`awk '{print $2}'` against `ssh-keygen -F <host> -l` output to
extract the SHA256 fingerprint. That extraction is **incorrect on
macOS** (which the MacBook is). macOS's `ssh-keygen -F -l` output is:

```text
# Host 192.168.0.206 found: line 60
192.168.0.206 ED25519 SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w
```

— so `$2` of line 1 is "Host" (a comment-line word), and `$2` of
line 2 is "ED25519" (the key type). Neither is the fingerprint.
The fingerprint is the third field of line 2, after the host and
key type.

Linux/OpenSSH-on-Linux typically renders the same query as:

```text
256 SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w <host> (ED25519)
```

— where `$2` is the fingerprint, matching what the packet expected.

The apply was completed with `grep -oE 'SHA256:[A-Za-z0-9+/=]+'`,
which is portable across both formats. The packet `Apply Commands`
section should be amended to use the same idiom on its next
revision; this is a markdown-only edit (no executable artifact;
no sha256 pin change).

## Validation Run

Two checks, both pass:

### Check 1 - entry exists and resolves

```
$ ssh-keygen -F fedora-top.home.arpa -l
# Host fedora-top.home.arpa found: line 105
fedora-top.home.arpa ED25519 SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w
```

### Check 2 - SSH works without HostKeyAlias

```
$ ssh -o StrictHostKeyChecking=yes -o BatchMode=yes verlyn13@fedora-top.home.arpa 'hostname; whoami'
fedora-top
verlyn13
```

`StrictHostKeyChecking=yes` + `BatchMode=yes` deliberately disables
prompting, so the SSH command would fail (exit nonzero) if the new
known_hosts entry were missing or wrong. A successful login is the
positive signal.

## Follow-On Workstation Change (separate)

The HostKeyAlias workaround in `~/.ssh/conf.d/fedora-top.conf` and
the obsolete comment block referring to "a future
fedora-top-known-hosts-reconciliation packet" are now stale; both
should be removed via the chezmoi template at
`home/dot_ssh/conf.d/fedora-top.conf.tmpl` and applied
target-scoped. That edit is tracked as the next item after this
record commits.

## Redaction / Secret-Handling Note

The ED25519 host-key fingerprint
`SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w` is public by
definition. No private-key material was touched at any step.
The pre-apply backup at
`~/.ssh/known_hosts.pre-fedora-top-reconciliation-20260515T170040Z`
contains other (non-fedora-top) host-identity material that is
likewise non-secret; same handling applies.

## Cross-References

- [fedora-top-known-hosts-reconciliation-packet-2026-05-13.md](./fedora-top-known-hosts-reconciliation-packet-2026-05-13.md)
- [fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../ssh.md](../ssh.md)
