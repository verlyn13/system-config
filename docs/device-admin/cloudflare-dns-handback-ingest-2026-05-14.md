---
title: cloudflare-dns Handback Ingest - 2026-05-14
category: operations
component: device_admin
status: ingested
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, cloudflare, zero-trust, warp, access, tunnel, handback, ingest]
priority: high
---

# cloudflare-dns Handback Ingest - 2026-05-14

This record ingests the `cloudflare-dns` repo's authoritative
non-mutating handback to system-config in response to
[handback-request-cloudflare-dns-2026-05-13.md](./handback-request-cloudflare-dns-2026-05-13.md).
It is a repo-safe summary; the cloudflare-dns reply is the source
of truth.

No live Cloudflare, system-config host, HomeNetOps, OPNsense, DNS,
DHCP, WARP, Tailscale, 1Password, RDP, or SSH state was changed
by this ingest.

## Source

| Field | Value |
|---|---|
| Source repo | `/Users/verlyn13/Repos/local/cloudflare-dns` |
| Source doc | `docs/handback-system-config-2026-05-13.md` |
| Source commit | `b5b9460` (file introduction) |
| Parent context commit | `9e4458a` (`fix(state): correct stale enabled flag for 05-adult-identity-bypass`) |
| Stack | Pulumi project `cloudflare-dns-infra`, stack `dev`, 38 resources |
| Source inspection mode | Repo-only by cloudflare-dns; no live Cloudflare API call, dashboard read, or audit log read was performed for that reply |

The earlier system-config-side text that was mistakenly circulated as
if it were a cloudflare-dns reply is **superseded** by this authoritative
reply.

## Org Structure (Authoritative)

```text
Cloudflare account:           single account; owner
                              jeffreyverlynjohnson@gmail.com
Zero Trust separation:        same account; team name "homezerotrust";
                              team domain
                              homezerotrust.cloudflareaccess.com
Machine identity for IaC:     iac-automation@jefahnierocks.com
API token storage:            gopass under cloudflare/cloudflare-dns/*
                              (NOT 1Password; this is a correction
                              relative to system-config's prior
                              assumption)
IaC stack:                    Pulumi (TypeScript); NOT OpenTofu.
                              No OpenTofu/Terraform migration is
                              planned. Wrangler owns Worker code and
                              cron triggers; Pulumi owns everything
                              else.
Dashboard-managed surfaces:   Identity providers (Google OAuth + email
                              one-time PIN), Log Explorer dataset
                              enablement, legacy "Cert Pinning"
                              (precedence 0), legacy "Block Malware"
                              (precedence 9000). These remain
                              dashboard-only and are not Pulumi-tracked.
```

Citation: system-config follow-up packets that touch Cloudflare
should cite cloudflare-dns commit `b5b9460` (or a later commit if
the source advances).

## 2026-05-15 Windows Multi-User Addendum

The original handback below treated MAMAWORK as a single-registration
Windows WARP device. That is superseded for the MAMAWORK target by
[Cloudflare Windows multi-user WARP addendum (2026-05-15)](./cloudflare-windows-multi-user-ingest-2026-05-15.md).

For MAMAWORK, the current target is Windows multi-user mode:
administrative/adult accounts should register into Adults or a future
Admin profile, Mama / Litecky should register into an adult/work
profile, and kid accounts should register into Kids. The previous
"pick one kid email for the whole machine" model is retained only as
historical context or fallback if Windows multi-user mode is not
available.

## WARP / Device Enrollment Posture

```text
WARP active in fleet:         yes - 7 devices enrolled today
                              (3 adult + 4 kid + 1 Pixel Private Space)
fedora-top WARP-enrolled:     no
MAMAWORK WARP-enrolled:       no
Cloudflare One Agent (mobile): replaces 1.1.1.1 for Zero Trust on
                              iOS/Android as of 2026-04
Identity providers in use:    Google OAuth (primary); email OTP
                              (built-in fallback); no
                              Microsoft/SAML/OIDC/Okta configured

Access app for enrollment:    "WARP Device Enrollment" (type warp;
                              session 720h)
Enrollment Access policies:
  - WARP enrollment - owner devices    (allow; identity-based; spreads
                                        kids.emails + adults.emails)
  - WARP enrollment - MDM service token (non_identity; service-token)
```

### WARP Profiles (4)

| Profile | Precedence | Match | Mode | Lock posture |
|---|---|---|---|---|
| Default | (singleton fallback) | catch-all | - | imported from account default; not deleted/recreated |
| Kids | 10 | `identity.email in {kid emails}` | full tunnel | switchLocked=true, allowedToLeave=false, allowModeSwitch=false, autoConnect=0 (instant reconnect), captive 180s |
| Adults | 20 | `identity.email in {adult emails}` | full tunnel | switchLocked=false, allowedToLeave=true, allowModeSwitch=true, autoConnect=0, captive 300s |
| Headless (MDM) | 30 | `identity.service_token_uuid == "<MDM>"` | warp | locked (same posture as Kids) |

Kid emails today: `axelptjohnson@gmail.com`,
`ilagenevievemary@gmail.com`, `wynrjohnson@gmail.com`.
Adult emails: `jeffreyverlynjohnson@gmail.com`,
`jakeshamus51@gmail.com`.

All custom profiles include `192.168.0.0/24` (home LAN) in
split-tunnel excludes and resolve `.local` + `.home.arpa` via
`192.168.0.1` (OPNsense Unbound) by local-domain-fallback. **The
existing fedora-top.home.arpa SSH admin path is unaffected by WARP
enrollment.**

### Prior Assumption: Single-Registration WARP

The original handback described WARP enrollment as one identity per
machine across macOS/Windows/Linux. Keep that as the default
single-registration model and for platforms that do not support
Cloudflare One Client multi-user mode.

For the MAMAWORK Windows target, do not use this as the desired
cutover model without first ruling out Windows multi-user mode. The
2026-05-15 addendum supersedes this section for MAMAWORK.

## Access Policy Posture

```text
Access apps for SSH today:    NONE. Only "WARP Device Enrollment"
                              exists in this account.
IdPs available for SSH SSO:   Google OAuth + email OTP
                              (account-wide)
Naming convention for SSH
  Access apps:                TBD in cloudflare-dns. Working
                              candidates (will be authoritative
                              once cloudflare-dns adopts them):
                                logical name:  access-app-ssh-<host>
                                dashboard label: SSH - <host>
                                hostname:      ssh-<host>.homezerotrust.cloudflareaccess.com
                              No custom domain is registered for
                              Access today.
Default session duration:     TBD. Recommended 8h (or 24h for
                              low-friction admin lanes).
Default device posture:       TBD. Recommended WARP-enrolled
                              + managed-network=home (TLS beacon).
Default country policy:       TBD. Recommended allow US (or US+AU).
```

## Tunnel Posture

```text
cloudflared connector
  tokens issued today:        NONE. No Cloudflare Tunnel exists.
Tunnel-name convention:       TBD. Working candidate (Pulumi
                              logical): tunnel-<host>
Per-tunnel hostname
  convention:                 TBD. Working candidate:
                              ssh-<host>.homezerotrust.cloudflareaccess.com
                              (paired 1:1 with the Access app)
Managed vs config.yml:        Recommendation: managed-tunnel
                              (dashboard + Pulumi); config.yml on
                              the host re-introduces the drift
                              surface Pulumi was adopted to remove.
Default ingress:              Recommendation: strict deny-by-default
                              with one explicit ingress per service.
                              ssh-only by default; no HTTP/HTTPS
                              unless a separate Access app + hostname
                              is authorized.
```

## Per-Device Zero Trust Profile Recommendation

Both devices: **Kids profile**, consistent with the household stance.
The administrator (verlyn13) reaches each device over a separate
admin path (SSH on the LAN today, an Access+Tunnel path in the
future) that does NOT depend on the device's WARP identity. WARP
profile placement is decided by who uses the device day-to-day, not
by who administers it.

### fedora-top -> Kids

```text
Device user:              Wyn (summer-use laptop; family member)
Administrator:            verlyn13 (separate SSH admin path)
WARP enrollment identity: wynrjohnson@gmail.com (already in
                          policy-inputs.yaml kids.emails)
Profile match:            existing Kids profile (no Pulumi change
                          needed)
Effects of Kids placement:
  - WARP locked: Wyn cannot disconnect, cannot switch modes,
    cannot leave Zero Trust; reconnect is instant.
  - All kids-controls Gateway DNS policies apply
    (06-adult-themes, 07-ytrestricted, 08-safesearch,
    09-content-block, 13-kids-social-block).
  - Home LAN (192.168.0.0/24) and .local / .home.arpa are
    split-tunnel + local-fallback; existing
    fedora-top.home.arpa SSH admin path is unaffected.
First Linux enrollment:   yes (no prior Linux WARP enrollment
                          in this fleet). Enrollment recipe:
                          dnf install cloudflare-warp;
                          warp-cli registration new homezerotrust;
                          browser OAuth as wynrjohnson@gmail.com.
```

### MAMAWORK -> Windows Multi-User Profile Separation

```text
Supersedes:               The original single-registration
                          recommendation to choose one kid identity
                          for the whole Windows device.
Target mode:              Windows multi-user mode via MDM
                          multi_user=true.
Device users (shared):    Mama (primary owner, Litecky Editing
                          Services workload), Axel/Wyn/Ila
                          (school + learning workloads), and
                          intentional admin/operator accounts.
Administrator:            verlyn13 (via DadAdmin path today;
                          1Password-managed replacement planned)
Profile match:            Per Windows user registration:
                          - admin/operator accounts -> Adults or
                            future Admin profile
                          - Mama / ahnie / Litecky -> Adults,
                            Litecky, or another adult-work profile
                          - kid accounts -> Kids profile
                          - optional pre-login -> Headless/MDM or
                            pre-login profile
Trade-off now tracked:
  - The old Kids-for-whole-machine trade-off should not be accepted
    unless multi-user mode is unavailable.
  - Litecky allow-listing remains relevant only for Litecky domains
    that must work from a Kids-profile session; Mama's normal
    Litecky workload should run under an adult/work profile.
  - Fast user switching and pre-login registration need explicit
    cloudflare-dns guidance because attribution follows the active
    interactive Windows desktop when multiple users are logged in.
Future migration:         MAMAWORK may migrate to a separate
                          Litecky Cloudflare org later. When that
                          happens, profile placement revisits: a
                          Litecky org would let Mama run an
                          "adults-equivalent" profile under
                          Litecky's Zero Trust posture without
                          forcing kids onto an adult-DNS lane in
                          the Jefahnierocks org.
First Windows enrollment: yes (no prior Windows WARP enrollment
                          in this fleet). Enrollment recipe is now
                          blocked on the cloudflare-dns Windows
                          multi-user rebaseline.
```

## 1Password Item Naming

```text
Per-device local admin items:   cloudflare-dns does not own these.
                                Working candidates from system-config
                                (no conflict; use as-is):
                                  jefahnierocks-device-fedora-top-local-admin
                                  jefahnierocks-device-mamawork-local-admin
                                  jefahnierocks-device-fedora-top-admin-backup-verlyn13

WARP service token (MDM):       Currently in Pulumi state + Cloudflare
                                Access service-tokens UI only; no
                                1Password mirror.
                                If system-config wants a 1Password
                                break-glass copy, suggested name:
                                  jefahnierocks-cloudflare-warp-mdm-service-token

cloudflared Tunnel-token items: None today (no Tunnel exists).
                                Suggested per-host naming when adopted:
                                  jefahnierocks-cloudflared-tunnel-<host>-token
                                  e.g.
                                  jefahnierocks-cloudflared-tunnel-fedora-top-token
                                  jefahnierocks-cloudflared-tunnel-mamawork-token

Pre-existing items system-config
  should reference rather than
  create:                       None. cloudflare-dns does not own any
                                household per-device 1Password items.
                                Its own API tokens are in gopass
                                (cloudflare/cloudflare-dns/*), scoped
                                to iac-automation@jefahnierocks.com.
```

## TBD Items Now Tracked

| TBD item | Owner | Notes |
|---|---|---|
| Tunnel naming convention | cloudflare-dns | Working candidate `tunnel-<host>` recorded; authoritative when cloudflare-dns lands the first Tunnel via Pulumi |
| Access app naming convention for SSH | cloudflare-dns | Working candidate `access-app-ssh-<host>` recorded; authoritative when cloudflare-dns lands the first SSH Access app |
| Default Access session duration / posture / country | cloudflare-dns | Working candidates 8h / WARP+home-network / US recorded; authoritative when the first SSH Access app is authored |
| MAMAWORK migration to a separate Litecky Cloudflare org | human + cloudflare-dns | If migration happens, MAMAWORK profile placement revisits; kids on Jefahnierocks org, Mama's Litecky workload on the Litecky org with its own profile separation |
| MAMAWORK Windows multi-user WARP rebaseline | cloudflare-dns | Required before any MAMAWORK WARP cutover. Confirm MDM `multi_user=true`, pre-login posture, profile map, and per-user enrollment recipe |
| MAMAWORK Litecky-required domain allow-list | human + cloudflare-dns | No longer a hard prerequisite for Mama's normal Litecky account if Windows multi-user mode places her in an adult/work profile. Still required for any Litecky domains that must work from a Kids-profile session |
| 1Password mirror for WARP MDM service token | human | Optional; only if system-config wants a break-glass copy outside Pulumi state |

## Implications For system-config Next Packets

What this handback unlocks:

- system-config can now author cutover packets that cite
  cloudflare-dns commit `b5b9460` (or later).
- **Two distinct cutover lanes** become drafteable, each with
  different cloudflare-dns dependencies:

  | Lane | system-config side | cloudflare-dns side | What it unlocks |
  |---|---|---|---|
  | **Windows multi-user WARP** | install Cloudflare One Client / WARP on MAMAWORK after cloudflare-dns confirms the MDM and enrollment recipe; register each Windows account with its intended identity | cloudflare-dns rebaseline required for `multi_user=true`, profile policy, optional pre-login registration, and validation evidence | Admin/adult accounts avoid Kids controls; kid accounts keep Kids controls; does NOT add an off-LAN SSH admin path |
  | **WARP + cloudflared Tunnel + Access** | install + start `cloudflared`; verify outbound 443 to Cloudflare edge | Pulumi commit adding the SSH Access application + the Tunnel + connector token | Off-LAN SSH admin path (`ssh ssh-<host>.homezerotrust.cloudflareaccess.com`); supersedes any need for Tailscale break-glass once verified |

- **Tailscale retain decision can be reaffirmed**: the cloudflare-dns
  handback confirms there is no Cloudflare-side conflict with the
  retained-logged-out posture. Tailscale stays transition/
  break-glass; do not log it in.
- **fedora-top remote-admin-routing-design** is unchanged in
  conclusion (LAN current / Tailscale transition / WARP+cloudflared
  target / direct WAN rejected) but now has authoritative evidence
  from cloudflare-dns to cite. The design can stay as is; the
  cutover packets are the next layer.

What this handback does NOT change:

- LAN admin readiness is separate from Cloudflare. Fedora and
  MAMAWORK SSH are now operational on the LAN; MAMAWORK's next local
  admin step is the read-only terminal-admin baseline, not WARP.
- The MAMAWORK DHCP source-of-truth packet remains optional and
  deferred until the operator wants the brief reconnect window.
- SSH-over-Tunnel remains future work after WARP/profile placement
  is correct and local SSH is already proven.

## Decisions System-Config Needs From The Operator Now

These are the small repo-side decisions that gate the next set of
cutover packets. None of them require live changes.

1. **Confirm Kids profile placement for fedora-top.** (Default per
   household stance; the cloudflare-dns recommendation matches.)
2. **Confirm MAMAWORK Windows multi-user mode** as the target rather
   than the old one-identity device model. Default recommendation:
   yes.
3. **Supply Mama / Litecky Cloudflare registration identity** so
   cloudflare-dns can place `MAMAWORK\ahnie` in an adult/work
   profile instead of Kids.
4. **Decide whether to mirror the WARP MDM service token to
   1Password** (`jefahnierocks-cloudflare-warp-mdm-service-token`)
   for break-glass.
5. **Sequencing**: MAMAWORK Windows multi-user WARP cutover first
   after cloudflare-dns answers, vs. waiting for the SSH-over-Tunnel
   cutover. Recommendation: finish LAN SSH first, ask cloudflare-dns
   for the multi-user rebaseline, then draft the WARP cutover as a
   separate packet before any Tunnel/Access work.

Once these are answered, system-config can draft:

- `fedora-top-warp-enrollment-cutover-packet-2026-05-15.md`
- `mamawork-warp-enrollment-cutover-packet-2026-05-15.md`
  (with the Litecky allow-list inbound request to cloudflare-dns
   recorded as a hard prerequisite)

The SSH-over-Tunnel cutover packets are deferred to a separate
later turn because they need cloudflare-dns Pulumi commits first.

## Boundary Assertions

- `cloudflare-dns` is the authority for everything in this ingest.
  System-config quotes commit `b5b9460` but does not own the
  underlying policy.
- No live Cloudflare change happened. No system-config host change
  happened. No HomeNetOps change. No 1Password change.
- The earlier "draft cloudflare-dns response" that was accidentally
  circulated is **superseded** by this authoritative ingest and
  should be ignored.

## Related

- Source: `/Users/verlyn13/Repos/local/cloudflare-dns/docs/handback-system-config-2026-05-13.md` at commit `b5b9460`
- [handback-request-cloudflare-dns-2026-05-13.md](./handback-request-cloudflare-dns-2026-05-13.md) -
  the outbound request this answers
- [hetzner-cloudflare-management-status-ingest-2026-05-14.md](./hetzner-cloudflare-management-status-ingest-2026-05-14.md) -
  the prior Hetzner advisory ingest (now superseded by this
  authoritative cloudflare-dns evidence on Cloudflare-policy
  questions)
- [fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md) -
  the system-config-side design this handback unlocks
- [fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md) -
  the Tailscale retain decision, reaffirmed by this handback
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)
- [../ssh.md](../ssh.md)
