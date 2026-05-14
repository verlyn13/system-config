---
title: Outbound Handback Request - cloudflare-dns - 2026-05-13
category: operations
component: device_admin
status: outbound-request
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, cloudflare, zero-trust, warp, access, tunnel, handback-request]
priority: high
---

# Outbound Handback Request - `cloudflare-dns` - 2026-05-13

This document is a **request** from `system-config` to `cloudflare-dns`
(`/Users/verlyn13/Repos/local/cloudflare-dns`). It is not a directive
and does not authorize any change. It enumerates the non-secret
evidence that `system-config` needs in order to author the Cloudflare
WARP + `cloudflared` cutover packets for the household fleet.

`cloudflare-dns` remains the sole authority for Cloudflare Zero Trust
org structure, WARP/device-enrollment policy, Access policy, Gateway
policy, Tunnel configuration, and Zero Trust profile assignment. No
Cloudflare-side assertion in `system-config` is authoritative until a
`cloudflare-dns` handback supplies it; that handback should cite a
specific commit SHA in `cloudflare-dns` so `system-config` can pin its
references.

## Why This Request Exists

Two prepared `system-config` packets enumerate the Cloudflare path as
the long-term remote-admin target:

- [`fedora-top-remote-admin-routing-design-2026-05-13.md`](./fedora-top-remote-admin-routing-design-2026-05-13.md)
  for `fedora-top`.
- [`windows-pc-mamawork.md`](./windows-pc-mamawork.md) for MAMAWORK.

Both packets are explicit that no live Cloudflare change happens from
`system-config`. The cutover packets cannot be drafted in this repo
without the handback content below.

## Scope

In scope for the request:

- Non-secret org structure for the Jefahnierocks Cloudflare account(s).
- Posture (not values) of WARP, Access, Gateway, and Tunnel
  configuration as it stands today.
- Recommendation on Zero Trust profile assignment for two devices
  (`fedora-top`, MAMAWORK).
- Naming conventions `cloudflare-dns` prefers for new Tunnel
  hostnames, Access applications, and 1Password items.

Out of scope for the request:

- Any Cloudflare API token, account ID, organization ID, tunnel
  credential JSON, or other secret value. Those stay in
  `cloudflare-dns`, 1Password, and provider state only.
- Any change to live Cloudflare state. The request is non-mutating.
- Any policy decision that `cloudflare-dns` has already published in
  its own repo and is willing to cite by commit SHA - in that case
  the handback can simply point to those repo paths plus commit.

## Requested Handback Content

A reply that follows
[`handback-format.md`](./handback-format.md) (handback template) and
fills the items below would be the simplest path.

### 1. Org Structure

```text
- Cloudflare account name(s) and their relation to Jefahnierocks
- Whether Zero Trust is on the same Cloudflare account or a separate
  org/account
- The cloudflare-dns repo path and the latest commit that should be
  cited by system-config follow-up packets
- Whether IaC migration (OpenTofu) is already underway for any
  Cloudflare surface; if so, which surfaces are managed by IaC today
  and which remain dashboard-managed
```

### 2. WARP / Device Enrollment Posture

```text
- Whether WARP is in use today on any household device
- Active device-enrollment policies, by name (not body)
- Which identity providers are enabled in Zero Trust
  (Google / Microsoft / email OTP / SAML / etc.)
- Whether adult vs kids' Zero Trust profile separation is already
  implemented; if so:
    - profile names
    - membership criteria (user-based, device-based, posture-based)
    - network / route / split-tunnel policies attached to each
- Expected enrollment flow on macOS (Cloudflare-supplied link,
  managed enrollment via MDM, manual via the WARP client UI, etc.)
- Expected enrollment flow on Windows (same)
- Expected enrollment flow on Fedora Linux (same; covers fedora-top)
```

### 3. Access Policy Posture

```text
- Whether any Access application exists today for SSH
- Identity providers available for Access SSO
- Naming convention cloudflare-dns prefers for Access applications
  that protect host SSH (so future system-config packets create the
  right hostnames; e.g. ssh.<host>.<chosen-domain>)
- Whether session duration, device posture, or country policies are
  expected on those Access apps by default
```

### 4. Tunnel Posture

```text
- Whether any cloudflared connector tokens are already issued for
  household devices; if so, where they live in 1Password (item
  naming convention only - no token values)
- Naming convention for Tunnel names
- Naming convention for per-tunnel hostnames
- cloudflare-dns preference: managed-tunnel (dashboard) vs locally
  configured (config.yml on the host)
- Any required Tunnel ingress rules (for example: SSH-only, or
  HTTP/HTTPS-permitted, or strict deny-by-default)
```

### 5. Per-Device Profile Recommendation

```text
For each device, recommend the Zero Trust profile assignment given
the household stance:
- verlyn13 has full admin
- family accounts are regular users
- kids' / home personal devices belong on the kids' Zero Trust profile
- adult profiles only on adult devices
- the device-user vs the device-administrator can differ; both
  matter to profile placement

Devices:

- fedora-top
    user:           Wyn (summer-use laptop; family member)
    administrator:  verlyn13
    current state:  Fedora 44, SSH-hardened, privilege-cleaned,
                    firewall-narrowed, Tailscale retained logged-out
    LAN identity:   192.168.0.206, fedora-top.home.arpa (Unbound)
    question:       which Zero Trust profile applies; how to model
                    "kids'-device administered by adult"

- MAMAWORK
    user:           secondary dev + kids' learning workstation
                    (mini-PC; AZW SER; Ryzen 7 5800H)
    administrator:  verlyn13 (via DadAdmin admin path today;
                    1Password-managed replacement planned)
    current state:  Windows 11 Pro 25H2, OpenSSH running but not yet
                    hardened from system-config, RDP disabled,
                    BitLocker off, Secure Boot off
    LAN identity:   192.168.0.101 (host-side static today;
                    HomeNetOps reservation pending)
    question:       same profile question as fedora-top
```

### 6. Item-Naming Plan For 1Password

```text
- Per-device admin credential item naming convention that
  cloudflare-dns / Jefahnierocks expects, so system-config can use
  the same convention. Working candidates from this repo:
    jefahnierocks-device-fedora-top-local-admin
    jefahnierocks-device-mamawork-local-admin
- WARP / cloudflared / Tunnel-token item naming convention
- Whether any item already exists for the household that
  system-config should reference rather than create
```

## How To Reply

A short markdown reply pasted into chat (or a short doc inside
`cloudflare-dns` whose path system-config can cite) is enough.
Preferred shape: the agent handback template from
[`handback-format.md`](./handback-format.md), populated with the
items above, plus the cloudflare-dns repo commit SHA at the top.

If any field is **not yet decided** in `cloudflare-dns`, mark it as
`TBD` and (if relevant) state which separate
`cloudflare-dns`-internal task is gating it. `system-config` will
hold the WARP/cloudflared cutover packets in `planned` state on
those items.

## Stop Rules For This Request

- Do not paste any Cloudflare API token, account ID, organization
  ID, or tunnel credential JSON into the reply.
- Do not change live Cloudflare state in order to answer this
  request - it asks only about the posture as it stands.
- Do not assume `system-config` will take ownership of any
  Cloudflare surface in response to the reply; ownership remains in
  `cloudflare-dns`.
- Do not ingest this request as a directive; treat it as one repo
  asking another for non-secret evidence.

## Related

- [`fedora-top-remote-admin-routing-design-2026-05-13.md`](./fedora-top-remote-admin-routing-design-2026-05-13.md)
- [`windows-pc-mamawork.md`](./windows-pc-mamawork.md)
- [`current-status.yaml`](./current-status.yaml)
- [`handback-format.md`](./handback-format.md)
- [`../secrets.md`](../secrets.md)
