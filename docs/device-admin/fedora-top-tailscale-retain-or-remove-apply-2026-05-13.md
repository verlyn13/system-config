---
title: Fedora Top Tailscale Retain-or-Remove Decision Record - 2026-05-13
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, tailscale, decision]
priority: high
---

# Fedora Top Tailscale Retain-or-Remove Decision Record - 2026-05-13

This record applies **Option B - Retain (logged-out)** from the prepared
packet
[fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md).
The "apply" here is documentation-only. No live state on `fedora-top`
was changed.

## Decision

Tailscale is **retained** on `fedora-top` in its current logged-out
posture as transitional / possible break-glass design space. It is
**not** the default remote-admin routing layer; that role is reserved
for the broader Jefahnierocks design currently being authored in
parallel.

## Approval

Guardian approval matches the prepared packet's Option B approval
phrase. Operator additionally constrained the retain decision with the
following stop rules, all of which are observed here:

- Do not log in, enroll, create auth keys, or otherwise join any tailnet.
- Do not open `firewalld` for Tailscale.
- Do not upgrade the Tailscale package.
- Do not restart `tailscaled` (and therefore do not pre-emptively rotate
  the auth URL) without a separate explicit live approval.
- Continue to treat any printed `https://login.tailscale.com/a/<token>`
  URL as sensitive and never record it in the repo.

## What Did Not Change (Live State)

Verified live posture from the read-only inspection on
`2026-05-13T23:18:14Z` remains current:

```text
package:                tailscale-1.96.4-1.x86_64
tailscaled service:     active, enabled, UnitFileState=enabled
login state:            Logged out
tailscale0:             link-local IPv6 only (no tailnet IP)
udp/41641 listener:     bound by tailscaled, blocked at firewall
tailscale-stable DNF:   enabled, healthy
Tailscale GPG key:      gpg-pubkey-957f5868-5e5499b8 imported
upgrade pending:        tailscale.x86_64 1.98.1-1 (not applied)
firewalld:              FedoraWorkstation post-narrowing baseline
                        (services: dhcpv6-client mdns samba-client ssh;
                        ports: empty)
sshd allowusers:        verlyn13
```

No `systemctl`, `dnf`, `tailscale`, `firewall-cmd`, `rm`, or daemon
restart was run for this apply. The recorded "apply" was repo-only.

## What Did Change (Repo State)

- `docs/device-admin/fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md`
  status flipped from `prepared` to `applied` (Option B path).
- `docs/device-admin/current-status.yaml`:
  - `tailscale-retain-or-remove` moves from `prepared_packets[]`
    to `applied_packets[]` with `state: retained-logged-out` and
    `applied_at: 2026-05-13T23:30:00Z`.
  - `blocked_items[].tailscale-retain-or-remove-decision` resolved
    and removed; replaced by
    `remote-admin-routing-design-pending` and
    `tailscale-login-with-acl-pending` entries that point to the
    upcoming routing design packet (the gate before any further
    Tailscale live work).
  - `next_recommended_action` shifted to
    `remote-admin-routing-design` (planned, to be authored next).
- `docs/device-admin/fedora-44-laptop.md` and
  `docs/device-admin/onboarding-2026-05-12.md` reflect the
  retain-logged-out decision in their state rows and tables.

## Security Note Carried Forward

The prepared packet's "Security Note On Auth-URL Exposure" remains
authoritative. Specifically:

- The auth URL emitted by `tailscale status` while the host is logged
  out is treated as a short-lived secret and is **not** in the repo.
- The URL was visible in the operator's session transcript during the
  packet preparation (and only during preparation). The operator
  declined the optional `systemctl restart tailscaled` rotation in this
  decision; rotation requires a separate explicit live approval and is
  not performed here.
- If the URL is suspected to have been shared beyond the session
  transcript, the operator may at any time issue a narrow live
  approval to restart `tailscaled` and force a fresh URL. That step is
  out of scope here.

## Next Gate

Further Tailscale operating work (login, ACL design, tailnet
membership, firewall passage) is **blocked** until the
remote-admin routing design packet is prepared and reviewed:

```text
next packet:                 docs/device-admin/fedora-top-remote-admin-routing-design-2026-05-13.md
state:                       planned (authoring follows this record in the
                             same change set)
must answer:                 whether Tailscale becomes the transition /
                             break-glass overlay or is later removed in
                             favor of Cloudflare WARP/cloudflared
                             exclusively; which evidence is needed from
                             cloudflare-dns and HomeNetOps before any
                             live cutover.
```

Until that design packet is prepared and approved, no further Tailscale
changes are authorized.

## Boundary Assertions

- SSH, sudoers/users/groups, `firewalld`, Docker, Cloudflare, WARP,
  `cloudflared`, OPNsense, DNS, DHCP, LUKS, TPM, firmware, power,
  reboot, and 1Password state are all unchanged.
- No upgrades, no service restarts, no provider/dashboard touches, no
  package additions or removals.

## Related

- [fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md)
- [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md)
- [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)
