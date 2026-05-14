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

### Critical Fact: WARP Is System-Level

WARP enrollment is system-level on macOS/Windows/Linux: **one
identity per machine**. The OS user account that initiates
`warp-cli registration new` is irrelevant; the WARP daemon
registers the entire host. Shared devices like MAMAWORK (which
has separate Windows user accounts per family member) carry **one
WARP identity for the whole machine**. This is the foundation of
the MAMAWORK trade-off recorded below.

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

### MAMAWORK -> Kids (with explicit trade-off)

```text
Device users (shared):    Mama (primary owner, Litecky Editing
                          Services workload), Axel/Wyn/Ila
                          (school + learning workloads); each
                          family member has their own Windows user
                          account, but WARP is system-level so one
                          identity applies machine-wide.
Administrator:            verlyn13 (via DadAdmin path today;
                          1Password-managed replacement planned)
Recommended WARP identity: primary kid user's Google email
                          (likely axelptjohnson@gmail.com if the
                          school workload is the daily driver;
                          wynrjohnson@gmail.com if Wyn is the
                          most frequent user during school year).
                          Final pick documented in the cutover
                          packet.
Profile match:            existing Kids profile (no Pulumi change
                          needed)
Trade-off (MUST be in
  cutover packet):
  - Kids profile applies kids-controls + compliance band to EVERY
    DNS query on MAMAWORK, including Mama's Litecky work.
  - Litecky-required domains may be incidentally blocked by
    09-content-block / 07-ytrestricted / 08-safesearch and must be
    allow-listed via the cloudflare-dns custom-allow list
    (01-custom-allow, precedence 10) BEFORE the cutover lands.
  - Kids profile is locked; Mama cannot disconnect WARP on her own
    user. The alternative (enroll MAMAWORK with an adult identity
    -> Adults profile, unlocked) loses kids controls for the kids'
    school workload. Choosing kids-locked is the household stance
    default; choosing adults-unlocked requires explicit deviation
    from that stance.
Future migration:         MAMAWORK may migrate to a separate
                          Litecky Cloudflare org later. When that
                          happens, profile placement revisits: a
                          Litecky org would let Mama run an
                          "adults-equivalent" profile under
                          Litecky's Zero Trust posture without
                          forcing kids onto an adult-DNS lane in
                          the Jefahnierocks org.
First Windows enrollment: yes (no prior Windows WARP enrollment
                          in this fleet). Enrollment recipe:
                          Install Cloudflare WARP from 1.1.1.1
                          downloads page; WARP UI -> Settings ->
                          Account -> Login with Cloudflare Zero
                          Trust; team homezerotrust; browser OAuth
                          as the chosen kid Google email.
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
| MAMAWORK Litecky-required domain allow-list | human + cloudflare-dns | Before any MAMAWORK Kids-profile WARP cutover, every Litecky-required domain that gets blocked by kids-controls must be added to `01-custom-allow` (precedence 10) in cloudflare-dns |
| 1Password mirror for WARP MDM service token | human | Optional; only if system-config wants a break-glass copy outside Pulumi state |

## Implications For system-config Next Packets

What this handback unlocks:

- system-config can now author cutover packets that cite
  cloudflare-dns commit `b5b9460` (or later).
- **Two distinct cutover lanes** become drafteable, each with
  different cloudflare-dns dependencies:

  | Lane | system-config side | cloudflare-dns side | What it unlocks |
  |---|---|---|---|
  | **WARP-enrollment-only** | install Cloudflare WARP client on the device; `warp-cli registration new homezerotrust`; browser OAuth as the recommended kid Google email | NONE (no IaC change; the Kids profile already matches by `identity.email`) | Kids-controls / compliance band / DNS protection for the device; does NOT add an off-LAN SSH admin path |
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

- The Fedora admin-backup SSH key strategy packet still depends on
  operator 1Password input. Unrelated to Cloudflare.
- The MAMAWORK SSH investigation packet still depends on the
  operator-run elevated PowerShell on MAMAWORK. The SSH-over-Tunnel
  cutover packet would replace the LAN-only SSH admin path
  eventually, but only after MAMAWORK's local SSH service is
  working (the investigation packet diagnoses why it isn't today).
- The MAMAWORK DHCP source-of-truth packet remains deferred (per
  guardian) until MAMAWORK SSH stabilizes.

## Decisions System-Config Needs From The Operator Now

These are the small repo-side decisions that gate the next set of
cutover packets. None of them require live changes.

1. **Confirm Kids profile placement for fedora-top.** (Default per
   household stance; the cloudflare-dns recommendation matches.)
2. **Confirm Kids profile placement for MAMAWORK** AND acknowledge
   the Mama/Litecky trade-off:
   - Kids-locked WARP means Mama cannot disconnect on her Windows
     account.
   - Litecky-required domains must be allow-listed in
     `01-custom-allow` BEFORE the cutover, via a cloudflare-dns
     commit. system-config can ask cloudflare-dns for that commit
     as a follow-up inbound request.
   - Alternative: enroll MAMAWORK in Adults profile (unlocked),
     losing kids-controls for the kids' school workload. This is an
     explicit deviation from the household stance.
3. **Pick the MAMAWORK WARP enrollment identity** between
   `axelptjohnson@gmail.com` and `wynrjohnson@gmail.com` (whichever
   kid uses the machine most often).
4. **Decide whether to mirror the WARP MDM service token to
   1Password** (`jefahnierocks-cloudflare-warp-mdm-service-token`)
   for break-glass.
5. **Sequencing**: WARP-enrollment-only cutover first (small, no
   cloudflare-dns IaC change, no operator-side prerequisite beyond
   running the WARP client install) vs. waiting for the SSH-over-
   Tunnel cutover (larger, requires cloudflare-dns Pulumi commit
   first). Recommendation: do WARP-enrollment-only first per device;
   then add SSH-over-Tunnel as a separate later packet for each
   device.

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
