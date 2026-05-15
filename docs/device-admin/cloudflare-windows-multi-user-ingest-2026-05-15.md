---
title: Cloudflare Windows Multi-User WARP Addendum - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, cloudflare, zero-trust, warp, windows, multi-user, mamawork]
priority: high
---

# Cloudflare Windows Multi-User WARP Addendum - 2026-05-15

This addendum corrects the MAMAWORK WARP cutover model after review
of Cloudflare's Windows multi-user documentation. It does not change
live Cloudflare, MAMAWORK, HomeNetOps, OPNsense, DNS, DHCP, WARP,
Tailscale, SSH, RDP, or 1Password state.

## Source

Official Cloudflare documentation:

- <https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/windows-multiuser/>
- <https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/parameters/>
- <https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/windows-prelogin/>

Relevant facts from the docs:

- Windows supports Cloudflare One Client multi-user mode starting with
  WARP version `2025.6.1400.0`.
- Multi-user mode is enabled by deploying a Windows MDM file with
  `multi_user` set to `true`; `configs` is required when using the
  top-level `multi_user` key.
- In multi-user mode, each Windows user has a separate device
  registration and the client switches registrations when the user
  logs in.
- Enabling multi-user mode for the first time requires users to
  re-register, even if the device already had a prior registration.
- Fast user switching has an attribution caveat: when multiple users
  are logged in, Cloudflare attributes traffic to the user with the
  active interactive Windows desktop. Cloudflare recommends disabling
  fast user switching or configuring pre-login registration for more
  accurate attribution.
- Local DNS query logging is a shared-device privacy concern: if DNS
  logging is enabled on the device, users on the device can inspect
  DNS queries from other users.

## Correction

The prior `cloudflare-dns` handback ingest correctly captured the
default single-registration model, but it is no longer the right
target posture for MAMAWORK if Windows multi-user mode is enabled.

For MAMAWORK, do not keep the old "pick one kid identity for the
whole Windows device" target. The better target is:

```text
MAMAWORK WARP mode:       Windows multi-user mode
MDM top-level key:        multi_user = true
Registration model:       one Cloudflare One Client registration per
                          Windows account
Profile separation:       profile selected by each signed-in user's
                          Cloudflare identity, not by one machine-wide
                          enrollment identity
```

The old one-identity assumption remains relevant only if
`multi_user=false`, if the Windows client version is too old, or for
platforms that do not support multi-user mode.

## Target Profile Separation

MAMAWORK should separate administrative, adult/Litecky, and kid
traffic by identity:

| Windows account family | Registration identity | Target profile | Notes |
|---|---|---|---|
| `MAMAWORK\jeffr` and any intentional operator/admin account | Admin/adult identity, currently expected to be `jeffreyverlynjohnson@gmail.com` unless cloudflare-dns says otherwise | Adults or a future Admin profile | Admin activity should not inherit Kids lock posture or kids-content controls. |
| `MAMAWORK\ahnie` / Mama / Litecky Editing Services operator | Mama/Litecky identity, TBD | Adults, Litecky, or another adult-work profile | `ahnie` is an intentional local Administrator and must not be forced into Kids profile by the WARP cutover. cloudflare-dns may need a policy-inputs update if the identity is not already in an adult/work group. |
| Kid accounts (`axelp`, `ilage`, `wynst`, or corrected account names after operator confirmation) | Each kid's own Cloudflare identity | Kids profile | Kids profile remains locked and should continue to apply to the kids' school/learning sessions. |
| Windows pre-login / no active user | Service-token registration if enabled | Headless/MDM or pre-login profile | Recommended for accurate baseline connectivity and to avoid stale previous-user attribution at the login screen. |

## Design Consequences

- The MAMAWORK cutover is no longer an enrollment-only packet with a
  single choice between `axelptjohnson@gmail.com` and
  `wynrjohnson@gmail.com`.
- The cutover packet needs a per-user registration sequence:
  operator/admin first, Mama/Litecky account second, kid accounts
  last, with each account verified against the intended Zero Trust
  profile.
- The previous Litecky allow-list prerequisite is softened. It is
  still needed for any Litecky-required domains that must work from
  a Kids-profile session, but Mama's normal Litecky workload should
  instead run under an adult/work profile in multi-user mode.
- Fast user switching becomes a policy decision. If it remains
  enabled, Cloudflare attribution follows the active desktop user,
  not necessarily the background process owner. For MAMAWORK, the
  safer target is to configure pre-login registration and document
  the remaining attribution caveat.
- `warp-cli dns log enable` and the Cloudflare One Client GUI DNS
  logging toggle should stay off by default on MAMAWORK unless a
  short diagnostic packet explicitly enables and then disables it.

## Needed From cloudflare-dns

`system-config` does not own the Cloudflare profile, Gateway, Access,
MDM, or Pulumi surfaces. A follow-up request is prepared in
[handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md](./handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md).

That request asks `cloudflare-dns` to rebaseline the MAMAWORK target
against Windows multi-user mode, including:

- whether the current MDM renderer can deploy `multi_user=true`;
- whether pre-login registration should be enabled for MAMAWORK;
- the exact profile policy changes needed for admin/adult, Mama or
  Litecky, and kid identities;
- the per-user enrollment recipe and validation checks;
- the DNS logging privacy default;
- the Pulumi preview/apply boundary and stop rules.

## Current Status

This addendum changes planning only:

- MAMAWORK SSH/RDP/LAN work remains the active priority.
- MAMAWORK SSH is now operational from the MacBook after
  `mamawork-sshd-admin-match-block` and
  `macbook-ssh-conf-d-streamline`.
- The next MAMAWORK terminal-admin step is the read-only baseline
  tracked in `current-status.yaml`, not WARP enrollment.
- MAMAWORK WARP/Cloudflare work remains blocked until cloudflare-dns
  answers the Windows multi-user rebaseline and the operator supplies
  the Mama/Litecky registration identity.
