---
title: cloudflare-dns Handback Request - Windows Multi-User MAMAWORK WARP
category: handback-request
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, cloudflare, zero-trust, warp, windows, multi-user, mamawork]
priority: high
---

# cloudflare-dns Handback Request - Windows Multi-User MAMAWORK WARP

## Request

Please rebaseline the MAMAWORK WARP / Zero Trust target against
Cloudflare's Windows multi-user mode.

This is a planning handback request only. Do not make live
Cloudflare, WARP, Gateway, Access, Tunnel, MDM, or Pulumi changes
unless the operator separately authorizes that work in the
`cloudflare-dns` repo.

## Why This Exists

The 2026-05-14 `cloudflare-dns` handback treated MAMAWORK as a
single WARP identity device and recommended choosing one kid email
for the whole machine. Cloudflare's Windows multi-user documentation
now makes a better MAMAWORK target available:

- MDM `multi_user=true`;
- separate Cloudflare One Client registration per Windows account;
- profile assignment by the active user's Cloudflare identity.

That means the administrative accounts should not be on the same
Cloudflare profile as the kids accounts:

- admin/operator account(s): Adults or future Admin profile;
- Mama / Litecky account (`ahnie`): Adults, Litecky, or another
  adult-work profile;
- kids accounts: Kids profile;
- optional pre-login registration: Headless/MDM or pre-login profile.

## Source Docs To Check

Use the current official Cloudflare docs, not the summary here:

- <https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/windows-multiuser/>
- <https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/parameters/>
- <https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/windows-prelogin/>

system-config has a local planning addendum at
[cloudflare-windows-multi-user-ingest-2026-05-15.md](./cloudflare-windows-multi-user-ingest-2026-05-15.md).

## Requested Output

Please produce a non-secret handback document in `cloudflare-dns`
that answers these questions:

1. Can the current Cloudflare One Client / MDM path deploy
   `multi_user=true` for Windows, or does `cloudflare-dns` need a new
   renderer, template, or manual deployment step?
2. Should MAMAWORK use pre-login registration? If yes, which existing
   or new service token/profile should represent the login-screen
   state?
3. What exact profile-matching changes are needed so:
   - `MAMAWORK\jeffr` and any operator/admin account land in Adults
     or a future Admin profile;
   - `MAMAWORK\ahnie` / Mama / Litecky lands in Adults, Litecky, or
     another adult-work profile;
   - kid accounts land in Kids;
   - no one is accidentally routed through the Default profile?
4. Which identity should Mama / Litecky use for Cloudflare
   registration, and does it need to be added to `policy-inputs.yaml`
   or another cloudflare-dns authority file?
5. Does fast user switching need to be disabled, or is pre-login
   registration plus documented attribution caveat sufficient?
6. Should local DNS query logging be explicitly prohibited on
   MAMAWORK except during a short diagnostic?
7. What is the exact operator enrollment sequence after MDM
   deployment? Include per-user registration, re-registration,
   validation commands, dashboard checks, and expected profile names.
8. If a Pulumi change is required, what are the exact preview/apply
   commands and stop rules?

## Boundaries

- Do not include secret values, service-token secrets, OAuth secrets,
  tunnel tokens, API tokens, or one-time registration artifacts in
  the handback.
- Do not assume MAMAWORK's current SSH/RDP state is solved by WARP.
  system-config is still closing LAN SSH/RDP first.
- Do not mutate MAMAWORK from cloudflare-dns.
- Do not collapse Mama / Litecky workload requirements into Kids
  controls. `ahnie` is an intentional local Administrator and should
  be treated as an adult/work user.

## Desired Handback Shape

Please return:

- current Cloudflare facts checked;
- required repo changes, if any;
- required live dashboard or device steps, if any;
- exact profile map for MAMAWORK Windows users;
- operator-safe enrollment recipe;
- verification commands/evidence;
- stop rules and rollback notes.
