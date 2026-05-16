---
title: cloudflare-dns Handback Request - Full Zero Trust Architecture Context
category: handback-request
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, cloudflare, zero-trust, warp, tunnel, access, identity, family, context-only]
priority: high
---

# cloudflare-dns Handback Request — Full Zero Trust Architecture Context

## Request

Please use this document as the **full picture of identity, device,
use-case, and infrastructure context** for designing the
Cloudflare Zero Trust architecture (WARP profiles, Access apps,
Tunnel connectors, Gateway policies, identity provider mappings).

This is a **planning handback request only**. It is purely
informational. **No live Cloudflare / WARP / Gateway / Access /
Tunnel / MDM / Pulumi changes** should be made unless the
operator separately authorizes that work in the `cloudflare-dns`
repo, after this context has been reviewed.

## Why This Exists

The DSJ Phase 3 sequence (this repo, today) and prior work on
MAMAWORK and fedora-top have generated several partial handback
requests scoped to specific devices. The operator now wants the
**whole picture in one place** so the Cloudflare designer can
optimize for:

- Identity boundaries across the family (kids, adult/work, admin)
- Cross-device operator administration from a roaming MacBook
- Network-path resiliency (LAN, residential WAN, Hetzner)
- Per-user WARP profile assignment on shared Windows devices
- Off-LAN SSH lanes via Cloudflare Tunnel + Access (currently
  blocked on cloudflare-dns Pulumi commits)

Prior partial handback requests cover narrower slices and remain
authoritative for their own scope:

- [handback-request-cloudflare-dns-2026-05-13.md](./handback-request-cloudflare-dns-2026-05-13.md)
- [handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md](./handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md)

This document SUPERSETS those — it does not replace them. The
narrower requests are the per-device asks; this is the framing
they all fit inside.

---

## 1. Identity Inventory

Family identities and their intended Cloudflare role. Emails
listed are what the operator currently knows; gaps marked
**TBD-operator** require the operator to fill in before the
Cloudflare designer can finalize assignments.

### Operator / Administrator

| Role | Name | Primary identity (preferred for Cloudflare auth) | Other identities |
|---|---|---|---|
| Operator + family administrator | Jeff (Jefahnierocks) | `jeffrey@happy-patterns.com` (Happy Patterns business email) | `jeffreyverlynjohnson@gmail.com` (personal Google); `jjohnson47@alaska.edu` (academic — likely not appropriate for Cloudflare admin) |

**Notes:**

- Jeff is the sole administrator of every device in this
  inventory.
- Jeff's primary admin device is the MacBook Pro
  (`verlyns-mbp`, LAN IP `192.168.0.10`). 1Password is
  installed only on this MacBook; private SSH key material is
  custody-bound to the MacBook's 1P SSH agent. No managed
  device runs 1Password.
- Jeff needs administrative reach into **every** device in the
  inventory from anywhere (roaming Starlink, hotel WiFi, foreign
  networks). This is the single most-critical use case.

### Adult / Work-Friendly

| Role | Name | Primary identity | Cloudflare profile target |
|---|---|---|---|
| Adult (work-permissive, kid-coexisting) | Ahnie ("Mama", Litecky Editing Services) | `ahnielitecky@gmail.com` (jefahnierocks-managed Google identity) | **Recommend a dedicated `Adults-Ahnie` profile** — see Notes below for why a generic `Adults` profile is the wrong target |

**Notes:**

- Ahnie is intentionally a Windows administrator on MAMAWORK
  (confirmed in the MAMAWORK admin-streamline apply record).
- Ahnie's WARP profile must be **work-friendly and permissive**
  for Litecky Editing Services workflow — generic Adults
  defaults are too restrictive for editing-business browsing,
  and specific Litecky domains may need allow-list bypass (see
  `handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md`).
- **Security caveat the designer must encode**: kids often use
  Ahnie's session unattended (she does not consistently lock
  her screen or sign out). The operator explicitly identifies
  this as the weakest link in the family security posture. The
  practical implication for the Cloudflare design:
  - A generic `Adults` profile (unrestricted) on Ahnie's
    session is **not appropriate** — kid traffic would inherit
    full adult policy when a kid is using her session.
  - The dedicated `Adults-Ahnie` profile should be tuned for
    **kid coexistence**: permissive enough for Litecky workflow
    (and mildly NSFW-tolerant for typical adult internet),
    but with kid-safety guardrails as the floor (no
    unfiltered porn, no gambling, etc.) so a child accidentally
    on her session is not exposed to category-X material.
  - This is a hybrid profile that doesn't fit cleanly into
    Kids / Adults / Headless. The designer should decide
    whether to (a) create the new profile, (b) extend the
    existing Adults profile with kid-coexistence rules and use
    that for Ahnie only, or (c) propose a different mitigation
    (e.g., session-attribution by active Windows user via the
    Windows multi-user rebaseline path, which would route
    kid-session traffic to Kids regardless of who owns the
    Windows account).
- Ahnie's identity is **not** a parent-admin identity for
  Cloudflare purposes. She uses devices; she does not administer
  the fleet. Jeff is the sole fleet administrator.
- **Business-entity scope:** Litecky Editing Services is its
  own business / org (separate entity, `~/Organizations/litecky-editing/`),
  but the operator confirms device management for Ahnie is
  routed through jefahnierocks for now. Ahnie's Cloudflare
  identity is jefahnierocks-managed via `ahnielitecky@gmail.com`.
  Litecky-entity Cloudflare resources (if any) are out of scope
  here.

### Kids (permissive within kid-policy)

Three kids. All current and planned WARP enrollments use Kids
profile (locked, full tunnel) per the cloudflare-dns
2026-05-14 baseline.

| Name | Primary identity | Devices used |
|---|---|---|
| Axel | `axelptjohnson@gmail.com` | TBD-operator (which devices?) |
| Wyn | `wynrjohnson@gmail.com` | fedora-top (Linux multi-user session); possibly DSJ |
| Ila | `ilagenevievemary@gmail.com` | fedora-top (Linux multi-user session); possibly DSJ |

**Notes:**

- The Kids profile in Cloudflare today already matches by
  `identity.email` for at least `wynrjohnson@gmail.com` (per
  cloudflare-dns commit b5b9460 and the system-config
  `cloudflare-dns-handback-ingest-2026-05-14.md` summary). Axel
  and Ila need to be confirmed as already present in the
  cloudflare-dns `policy-inputs.yaml` `kids.emails` list.
- Kids profile is locked, full-tunnel, with Cloudflare
  Gateway DNS filtering. No operator override expected.
- Kids' WARP identity assertion is **device-session-scoped**
  on Windows shared devices: which Cloudflare profile applies
  depends on which Windows user is currently active. That's the
  MAMAWORK / DSJ multi-user case the cloudflare-dns
  Windows-multi-user-rebaseline request covers.

### Identity Provider context

Per the system-config ingest of the cloudflare-dns 2026-05-14
state (current-status.yaml, system-wide section
`answered_summary`) and operator clarification 2026-05-16:

- **Identity providers configured in Cloudflare One:** Google
  OAuth + email OTP.
- **Cloudflare account name:** `The Nash Group`.
- **Cloudflare account ID:** `13eb584192d9cefb730fde0cfd271328`.
- **Cloudflare One team:** `homezerotrust` (team domain
  `homezerotrust.cloudflareaccess.com`).
- **Account ownership scope (important):** the Cloudflare
  account is at the **Nash Group parent level**, not the
  jefahnierocks-entity level. jefahnierocks devices, identities,
  and zones (including `jefahnierocks.com`) are tenants under
  this parent account. See §6 Scope Boundaries below.
- **WARP currently enrolled on 7 devices** (the four planned
  family additions — fedora-top, MAMAWORK, DSJ × multi-user —
  would be new enrollments on top of those 7).

**Operator Cloudflare admin identity — parent-scope, not
jefahnierocks-scope:**

The operator has explicitly flagged that **"Cloudflare admin
identity is not yet fully planned"** — it is part of broader
IAM management and account planning that happens at the Nash
Group parent scope, not at the jefahnierocks scope this
document is otherwise written from.

This means:

- The Cloudflare designer should NOT assume jefahnierocks can
  unilaterally decide who Jeff's Cloudflare admin identity is.
  That decision is upstream.
- For the device-level cutovers this handback unblocks (WARP
  enrollment for fedora-top / MAMAWORK / DSJ; SSH Tunnel +
  Access for off-LAN admin), the design should work with
  whatever operator identity Nash-Group IAM eventually settles
  on, and not bake assumptions in.
- Recommendation either way: design **as if** there will be a
  separate operator-tier profile (call it `Operator` for now)
  distinct from `Adults`. If Nash-Group IAM later resolves
  Jeff's identity to plain `Adults`, the Operator profile can
  be merged or aliased. The reverse (designing only for Adults
  then having to split out later) is worse.

---

## 2. Device Inventory

All physical and virtual devices in scope, with current state
and the lane Jeff administers them through today.

### Operator MacBook (admin origin)

| Field | Value |
|---|---|
| Hostname | `verlyns-mbp` |
| OS | macOS 15 Sequoia (Darwin 25.4.0) |
| LAN IP | `192.168.0.10` (DHCP, sometimes roams) |
| Cloudflare WARP | Enrolled today (one of the 7) |
| 1Password | Installed (only managed device with 1P); SSH agent at `~/.1password-ssh-agent.sock` |
| Role | Sole administration origin for the fleet; runs system-config repo, draft packets, agent sessions |

This is Jeff's source-of-truth admin laptop. **Roaming:**
Starlink RV (mobile), hotel WiFi, foreign networks. SSH
connections from this device must work from any IP-routable
network — the explicit design constraint that drives the
Cloudflare Tunnel + Access lanes.

### Windows fleet

| Device | LAN IP | OS | Local admin | Other accounts | Lifecycle (per system-config) |
|---|---|---|---|---|---|
| `MAMAWORK` | `192.168.0.101` | Windows (mom's "work" PC) | `MAMAWORK\jeffr` (Jeff admin), `MAMAWORK\ahnie` (Ahnie admin, work) | DadAdmin (legacy, retained for OneDrive scheduled tasks) | Phase 3 `reference-ssh-host` |
| `DESKTOP-2JJ3187` (DSJ) | `192.168.0.217` | Windows 11 24H2 (build 26200, OpenSSH 9.5p2) | `DESKTOP-2JJ3187\jeffr` (Jeff admin) | Kid standard users for Axel / Ila / Wyn (TBD which exact accounts) | Phase 2 `rdp-only-host` -> Phase 3 in progress (this session's SSH lane work) |

**Notes on shared-Windows-device WARP attribution:**

Per Cloudflare's Windows multi-user docs and the rebaseline
request:

- Admin/operator account (`*\jeffr`) -> Adults or Admin profile.
- Mama/Litecky account (`*\ahnie`) -> Adults or Adults-Litecky
  profile.
- Kid accounts -> Kids profile.
- Pre-login enrollment (no active user) -> Headless/MDM profile
  (locked policy).

Fast user switching is a real concern on MAMAWORK and DSJ —
Cloudflare attributes traffic to the active interactive desktop
user, so a kid signing into a session while Ahnie is also
logged in needs to apply the Kids profile. This is captured in
`mamawork-warp-active-user-attribution-decision` blocked item.

### Linux fleet

| Device | LAN IP | OS | Admin user | Other accounts | Lifecycle (per system-config) |
|---|---|---|---|---|---|
| `fedora-top` | `192.168.0.206` | Fedora Linux laptop | `verlyn13` (Jeff admin, sudoer) | Multi-user GNOME sessions for `ila` and `wyn` | Phase 3 `reference-ssh-host` (closed 2026-05-15) |

- `fedora-top` is a laptop the kids share (`ila` and `wyn`
  sessions; `axel` may or may not have a session — TBD).
- WARP enrollment is **pending**, blocked on operator profile
  placement confirmation (Kids profile is recommended for the
  whole device per cloudflare-dns b5b9460, with WARP identity
  `wynrjohnson@gmail.com` — but with three kid users on one
  Linux box, Cloudflare's Linux WARP attribution model may need
  re-think similar to Windows multi-user).

### Hetzner fleet

| Device(s) | Role | Cloudflare relevance |
|---|---|---|
| Hetzner servers (count TBD-operator; at least 1 from `has_hetzner=true` in chezmoi data) | TBD-operator (web hosting? infisical? CI?) | Candidate for a stable always-on `cloudflared` Tunnel connector. The operator notes "lots of routing considerations from services running on those servers" — Hetzner cloudflared placement has to coexist with existing Hetzner services. See §4 Network Context. |

The operator has explicitly raised Hetzner as a Cloudflare
Tunnel placement option (see Request statement). The
cloudflare-dns designer should consider Hetzner-side
`cloudflared` as a first-class architectural option, not just
a fallback.

### Home-LAN infrastructure (not user devices, but network-relevant)

| Device | LAN IP | Role | Cloudflare relevance |
|---|---|---|---|
| OPNsense router/firewall | TBD-operator (default `192.168.0.1`?) | LAN gateway, firewall, Unbound DNS, DHCP, WoL controller | HomeNetOps scope; not Cloudflare-managed. Mentioned for context. |
| Synology NAS | `192.168.0.250` | File storage; **hosts the WARP managed-network TLS beacon on port 7443** (see §4) | Already integrated with Cloudflare: serves the self-signed TLS cert that WARP fingerprints to detect "device is on home LAN". |

The Synology NAS is the **canonical home-LAN reference point**
for Cloudflare's managed-network detection. If the Synology
goes down or its beacon cert changes fingerprint, WARP-enrolled
devices on the LAN can no longer assert "I'm on the managed
home network" for Access posture checks. The cert is
intentionally 10-year self-signed to avoid the operational
cost of ACME-style rotation breaking the fingerprint pin.

### What is NOT in this fleet

- No Apple TVs, iPads, iPhones, or other family iOS devices in
  WARP scope (operator confirms separately if needed).
- No Tailscale-active devices (retired per
  `fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md`).
- No legacy DadAdmin SSH lane (retired per
  `handback-mamawork-admin-streamline-2026-05-14.md`).

---

## 3. Use Cases

The Cloudflare design needs to support these end-to-end flows.
They're listed by criticality.

### UC-1: Roaming-Jeff admin (HIGHEST PRIORITY)

**Actor:** Jeff. **Device:** MacBook Pro. **Network:** Anywhere
(home LAN, Starlink RV, hotel WiFi, foreign country, public
cafe).

**Need:** SSH/RDP/admin reach into every device in §2 from any
IP-routable network, with strong identity-bound auth (1Password
SSH keys via Cloudflare Access posture + SSH Tunnel).

**Today:**

- Home LAN -> works direct (`192.168.0.0/24`).
- Off-LAN -> works only for one device (fedora-top via a partial
  Cloudflare Tunnel design that hasn't landed in IaC yet — per
  `fedora-top-ssh-over-tunnel-cutover-pending` blocked item).
- Off-LAN -> does NOT work for MAMAWORK, DSJ, or Hetzner SSH
  except via fragile workarounds.

**Asks of the Cloudflare designer:**

- Define Access apps for each device's SSH endpoint
  (working names: `access-app-ssh-fedora-top`,
  `access-app-ssh-mamawork`, `access-app-ssh-desktop-2jj3187`,
  `access-app-ssh-hetzner-<role>`).
- Define a per-device Tunnel (working names already accepted:
  `tunnel-fedora-top`; same pattern for the others).
- Define Access policy: who can connect (Operator/Admin profile
  only? Adults? Specific email?), with what posture (WARP
  enrolled + home-managed-network OR roaming-with-WARP + maybe
  US country), and what session length (8h recommended in prior
  partial handback).
- Define DNS surface: are these `ssh-<device>.homezerotrust.cloudflareaccess.com`
  hostnames, or a different domain pattern?
- Decide whether to use Cloudflare's `cloudflared access ssh`
  client wrapper or Access for Infrastructure (Application
  Connector + ssh-over-https) — the latter is newer Cloudflare
  feature.

### UC-2: Kids' general internet use (CONTENT-FILTERED)

**Actors:** Axel, Wyn, Ila. **Devices:** fedora-top (Wyn + Ila
sessions; Axel TBD), shared Windows PCs (DSJ, possibly MAMAWORK
for school-research), kids' personal devices (out of scope here).

**Need:** Cloudflare Gateway DNS filtering, full-tunnel WARP,
locked profile, with kid-appropriate Allow / Block / Warn
policies.

**Today:**

- Kids profile exists in Cloudflare today (locked, full tunnel).
- WARP enrollment per kid identity is the model.
- Active blocker: cloudflare-dns Windows multi-user rebaseline
  for the DSJ + MAMAWORK shared-device case.

**Asks of the Cloudflare designer:**

- Confirm or correct: do all three kids' Google identities
  (Axel, Wyn, Ila) need to be in `policy-inputs.yaml`
  `kids.emails`? (Wyn confirmed; Axel and Ila need confirmation.)
- For shared Windows devices: which profile applies during
  pre-login (DSJ's login screen with no active user)? Headless
  is the standard answer; confirm.
- For fedora-top (Linux multi-user): can the Linux WARP client
  do per-user profile attribution similar to Windows multi-user
  mode? Or is the whole device on one profile (Kids), regardless
  of which Linux session is active?
- For school work that needs sites the Kids profile blocks: is
  there a per-kid override mechanism, or does that go through
  Ahnie's Litecky session on MAMAWORK (which would be Adults
  profile)?

### UC-3: Ahnie work (PERMISSIVE WITHIN ADULT POLICY)

**Actor:** Ahnie. **Device:** MAMAWORK (primary); possibly
fedora-top or DSJ if she ever uses them.

**Need:** Work-friendly WARP profile (Adults). Litecky Editing
Services domains must work without Cloudflare-imposed friction.
No kid policy attached to her sessions. Light DNS filtering
(malware/phishing) is fine; content filtering is not.

**Today:**

- Adults profile exists in Cloudflare (unlocked).
- Ahnie is not yet WARP-enrolled (no email on Adults profile
  list yet).
- Active blocker: same cloudflare-dns Windows multi-user
  rebaseline.

**Asks of the Cloudflare designer:**

- Confirm Adults profile's allow-list is appropriate for
  Litecky's typical workflow (mostly Google Docs / Word / web
  editors / email — confirm with operator if specifics needed).
- Decide whether Ahnie needs a dedicated `Adults-Litecky`
  profile with an explicit Litecky-domain allow-list, or
  Adults' default is fine.
- Confirm Ahnie's Cloudflare identity (email) — currently
  TBD-operator.

### UC-4: Operator MCP + dashboard access (LOW PRIORITY)

**Actor:** Jeff (specifically: Jeff's MCP integrations, Cloudflare
dashboard, AI agents calling the Cloudflare API).

**Need:** Read-only Cloudflare API token scoped to the
`jefahnierocks.com` zone (already exists; see
`docs/secrets.md` — alias
`op://Dev/cloudflare-mcp-jefahnierocks/token`, replacement
staging at
`op://Dev/cloudflare-jefahnierocks-mcp-readonly/credential`).

**Today:**

- Token exists and is referenced by `mcp-cloudflare-server`
  wrapper.
- Runtime hard-disabled per
  `~/.local/state/system-config/mcp-cloudflare.disabled`
  pending the bearer-argv-exposure incident remediation
  (separate from this Cloudflare design).

**Asks of the Cloudflare designer:**

- Not really a design question; just acknowledged so it's not
  forgotten. The current token scope (User Details Read + Zone
  Read + DNS Read on `jefahnierocks.com`) is fine. No action
  needed unless cloudflare-dns wants to change token scope.

### UC-5: jefahnierocks.com public DNS / hosting (OUT OF SCOPE here)

The zone `jefahnierocks.com` is managed by cloudflare-dns
already via Pulumi. Not part of this design ask.

---

## 4. Network Context

### LAN

- **CIDR:** `192.168.0.0/24` (Private network profile on Windows
  and Linux clients).
- **Router/firewall:** OPNsense, owned by `HomeNetOps` repo
  (separate handback flow).
- **DNS:** Unbound (on OPNsense) with static DHCP reservations
  and `.home.arpa` reverse / forward records for the fleet.
- **Wake-on-LAN:** OPNsense `os-wol` configured for cold-to-wake
  on at least DSJ (UUID `93980551-709a-40d3-83e7-a708ee616373`).
- **WAN:** Residential (Alaska, Homer). Likely a cable or DSL
  uplink — operator confirms specifics if relevant.

### Operator roaming WAN paths

- **Home (primary):** residential WAN (above). Stable when
  operator is home.
- **Mobile primary:** Starlink RV / Starlink Roam. Frequent.
- **Mobile secondary:** hotel WiFi, foreign country WiFi,
  public cafe WiFi. Sometimes captive-portal'd; sometimes
  CGNATed.

The Cloudflare Tunnel design must tolerate operator coming from
ANY of these. WARP-enrolled MacBook + Access policy is the
canonical answer.

### WARP managed-network TLS beacon (existing, on LAN)

The operator's "TLS signal on the local LAN" phrasing in the
original request was clarified 2026-05-16 to mean the
**WARP managed-network TLS beacon** already deployed on the
home LAN. This is an existing, working integration with
Cloudflare and is documented here so the designer doesn't
duplicate or break it.

| Setting | Value |
|---|---|
| Endpoint | `192.168.0.250:7443` (Synology NAS) |
| Type | TLS (managed network) |
| Cert CN | `warp-home-beacon` (RSA 2048, self-signed) |
| SHA-256 fingerprint | `32e43ba53bd02cd0adfcc8f96d3ca8690e45a3340a74dd5479463625c942b380` |
| Cert validity | 2026-02-28 → 2036-02-26 (10 years) |
| Pulumi resource ID | `6a79ecfe-a3dc-4a8a-a6bc-216f9b28a881` |

**How it works:** WARP performs a TLS handshake to
`192.168.0.250:7443`, reads the server cert, computes its
SHA-256 fingerprint, and compares it to the value stored in
Cloudflare. Match = device is on the home LAN. Cloudflare
only checks the fingerprint, **not the cert chain** — that's
why a self-signed cert with a 10-year lifetime was chosen over
OPNsense's ACME cert (which would rotate every 90 days and
break detection on every renewal). The operator explicitly
identifies this trade-off as load-bearing.

**Implications for the design:**

- Access policies that require "device is on managed home
  network" rely on this beacon being reachable from the
  WARP-enrolled device's network position. If WARP is on a
  device that's off-LAN (operator MacBook roaming on
  Starlink), this beacon check fails, and the Access policy
  must use a different posture (e.g., WARP enrolled + Operator
  identity, without the managed-network assertion).
- For UC-1 (roaming-Jeff admin), the Access policy on SSH
  apps cannot require `managed-network=home`. It must accept
  Jeff's identity + WARP-enrollment as sufficient.
- For UC-2 / UC-3 (kids and Ahnie), the managed-network
  beacon CAN be a posture input — when a kid or Ahnie is on a
  device at home, applying tighter policy (kids profile
  attribution, Ahnie's kid-coexistence profile) is reasonable.
  But the design must still work off-LAN for those users (kids
  visiting friends' houses, Ahnie taking her laptop
  somewhere); cloudflared / WARP policy fallback when the
  beacon is unreachable must not be more restrictive than the
  managed-network case (or the user is stuck with no access),
  and not more permissive (or the off-LAN state is exploitable).

### Optional: WARP managed-network beacon on Hetzner

The operator has raised whether to run a similar beacon on
Hetzner. The system-config-side reading:

- A Hetzner beacon would let WARP detect "device is on the
  Hetzner network" as a managed network.
- This is **probably not useful** for the family use case:
  Hetzner isn't a place users sit; it's infrastructure.
  Marking Hetzner as a managed network would mostly help if
  the operator (or future automation) is operating from a
  Hetzner-hosted desktop / jump host, which isn't current
  practice.
- The operator's note "will also have lots of routing
  considerations from services running on those servers"
  suggests they're aware running an externally-reachable beacon
  on Hetzner could conflict with existing service exposure.
- **Recommendation pending designer review:** skip the Hetzner
  beacon unless cloudflare-dns identifies a concrete use case.
  The home-LAN beacon on Synology is sufficient for
  managed-network detection of the family fleet at home.

### cloudflared Tunnel connector placement (for SSH-over-Tunnel)

This is a **separate question** from the managed-network
beacon. Tunnel connectors carry traffic from Cloudflare's edge
to the LAN SSH targets. There are three architectural options:

**Option A: cloudflared on LAN (e.g., on the Synology, on
OPNsense, or on a dedicated host).**
- Pros: termination is on the actual subnet the SSH targets
  live on. No double-hop. Lowest latency.
- Cons: residential WAN is the connector's uplink. If the LAN
  is offline, every off-LAN SSH path is down. Asymmetric egress
  for Cloudflare's edge.

**Option B: cloudflared on Hetzner.**
- Pros: stable public uplink, EU-based, decoupled from
  residential connectivity. Cloudflare connector is always
  reachable from Cloudflare's edge.
- Cons: SSH traffic has to traverse Hetzner -> LAN, which means
  Hetzner needs IP reachability to the LAN devices (Tailscale,
  WireGuard, OPNsense WireGuard, or some other transport).
  Adds a hop and a failure point. Hetzner-side service
  coexistence (per the operator's routing caveat) must be
  worked out.

**Option C: cloudflared on BOTH** (redundant connectors).
- Pros: high availability. Cloudflare automatically load-
  balances across connectors of the same tunnel. If LAN
  connector is down, Hetzner connector still answers (assuming
  Hetzner -> LAN transport is up).
- Cons: requires both Option A and Option B's connectivity
  surfaces. More moving parts.

**Open question for the Cloudflare designer:** which option
(A, B, or C) does cloudflare-dns recommend for the operator's
admin SSH use case, given UC-1's requirement that off-LAN admin
must work from anywhere the MacBook is? Note that whichever
host runs cloudflared is **a new managed host** for whichever
repo owns it — system-config will package the operator-side
setup, but the cloudflared connector token + Cloudflare-side
registration is cloudflare-dns scope.

---

## 5. Current Cloudflare State (per system-config's ingest)

From `current-status.yaml` system-wide section answered_summary,
the prior partial handback ingest docs, and operator
clarification 2026-05-16:

### Account / ownership

- **Cloudflare account name:** `The Nash Group`.
- **Cloudflare account ID:** `13eb584192d9cefb730fde0cfd271328`.
- **Cloudflare One team:** `homezerotrust`.
- **Team domain:** `homezerotrust.cloudflareaccess.com`.
- **Account scope:** Nash Group (parent). jefahnierocks devices
  + zones (including `jefahnierocks.com`) are tenants under
  this parent account. See §6 Scope Boundaries.
- **IaC:** Pulumi TypeScript in the `cloudflare-dns` repo.
  NOT OpenTofu, NOT Terraform.
- **Secret storage (today):** gopass (note: system-config is
  migrating away from gopass to 1Password — see
  `project_1password_migration.md`; Cloudflare-side secret
  storage is cloudflare-dns's call, but if a unified custody
  story is in scope at Nash-Group level, gopass -> 1Password
  may matter).
- **Identity providers:** Google OAuth + email OTP.

### WARP profiles (existing)

- `Default` — fallback when no other matches.
- `Kids` — locked, full tunnel.
- `Adults` — unlocked.
- `Headless` — MDM-managed, locked.

### Managed network (existing)

- **Home LAN managed network**, identified by TLS beacon on
  Synology NAS `192.168.0.250:7443`, fingerprint
  `32e43ba53bd02cd0adfcc8f96d3ca8690e45a3340a74dd5479463625c942b380`.
  Pulumi resource ID `6a79ecfe-a3dc-4a8a-a6bc-216f9b28a881`.
  Cert valid 2026-02-28 → 2036-02-26 (deliberately 10-year
  self-signed to avoid ACME rotation breaking the fingerprint
  pin). See §4 Network Context for details.
- No other managed network entries today.

### Enrollment + apps

- **WARP devices enrolled today:** 7 (operator MacBook is one;
  the other 6 are unknown to system-config — likely Jeff's
  iPhone, iPad, Apple TVs, etc.; cloudflare-dns can confirm).
- **Access apps:** None today.
- **Tunnels:** None today.
- Working naming candidates per fedora-top partial handback:
  `tunnel-fedora-top`, `access-app-ssh-fedora-top`,
  `ssh-fedora-top.homezerotrust.cloudflareaccess.com`.
- **Gateway:** Active (DNS filtering on WARP-enrolled devices).
  Kids profile applies Cloudflare's recommended kids policies
  plus any cloudflare-dns customizations.

### What this means for the design

The four-profile model (Default / Kids / Adults / Headless) is
the existing baseline. The design ask of cloudflare-dns is
whether that's sufficient for the family-plus-roaming-admin
context, or whether new profiles are needed. Given the
operator clarifications above, system-config recommends the
designer evaluate **at least these candidate additions**:

- **`Operator`** profile for Jeff (distinct from `Adults`).
  Even if Nash-Group IAM eventually resolves Jeff's identity
  to plain Adults, designing as if Operator-tier exists is
  cheaper than retrofitting.
- **`Adults-Ahnie`** profile (kid-coexistence-aware adult,
  see §1 for rationale). NOT a generic Adults profile —
  the kid-on-Ahnie's-session reality requires kid-safety
  guardrails as the floor even though the user is adult.
- The Windows-shared-device pre-login state stays on
  `Headless`, OR splits into a new `Pre-Login` profile if
  the multi-user rebaseline wants different policy there.

---

## 6. Constraints and Invariants

These are decided. The Cloudflare designer should treat them as
inputs, not as questions.

### Scope boundaries (who owns what)

The operator explicitly asked the designer to "keep in mind
what jefahnierocks is responsible for, and what system-config
is responsible for". The full picture has four scopes the
Cloudflare design touches:

| Scope | Owner repo / entity | What it owns | What it does NOT own |
|---|---|---|---|
| Parent governance | `the-nash-group` (parent entity) | Cloudflare account `The Nash Group` (`13eb584192d9cefb730fde0cfd271328`); cross-entity IAM and identity planning; standards; audit | Day-to-day device admin; per-family-member identity assignment; entity branding |
| Cloudflare IaC | `cloudflare-dns` (managed by parent for all entities) | Pulumi TypeScript for the Nash Group Cloudflare account — WARP profiles, Gateway policies, Access apps, Tunnels, DNS, managed networks, beacon registration | jefahnierocks-side device packets; operator-side WARP enrollment; identity-source decisions (those are IAM-planning scope) |
| Family device admin (this entity) | `jefahnierocks` (entity, `~/Organizations/jefahnierocks/`) | Device inventory and admin packets for family devices; per-device 1Password admin SSH keys; family identity-to-device mapping (Jeff / Ahnie / Axel / Wyn / Ila); fleet lifecycle | Cloudflare account or Pulumi state; Litecky-business resources; HomeNetOps LAN config; The Nash Group standards |
| Operator workspace + chezmoi orchestration | `system-config` (under jefahnierocks, this repo) | The operator MacBook config (chezmoi, mise, direnv, MCP, SSH client conf.d, 1P SSH agent integration); the device-admin packet ceremony (windows-terminal-admin-spec, packet-defect halt rule, etc.); operator-side WARP enrollment procedure | Cloudflare server-side; Pulumi state; Nash-Group IAM; what identities exist; LAN infrastructure |

**Implications for the Cloudflare designer:**

- All Cloudflare-side decisions (WARP profile shape, Gateway
  policy, Access app, Tunnel topology, managed-network
  beacon registration) belong to `cloudflare-dns`.
- jefahnierocks/system-config will package the operator-side
  enrollment procedure as device-admin packets (e.g.,
  `mamawork-warp-enrollment-cutover-packet`,
  `desktop-2jj3187-warp-enrollment-cutover-packet`,
  `fedora-top-warp-enrollment-cutover-packet`), each gated on
  cloudflare-dns answering this handback.
- Operator Cloudflare admin identity is a Nash-Group IAM
  decision (not jefahnierocks scope). Design with that
  separation in mind.
- Litecky Editing Services (Ahnie's business) is a separate
  entity under Nash Group with its own repo
  (`~/Organizations/litecky-editing/`). For now, Ahnie's
  Cloudflare identity is jefahnierocks-managed (`ahnielitecky@gmail.com`)
  because device management is routed through jefahnierocks.
  If Litecky-entity Cloudflare resources are eventually needed
  (e.g., a Litecky-business Access app), that's a separate
  handback from `litecky-editing` to `cloudflare-dns`.

### Custody

- **1Password is MacBook-only.** No managed Windows or Linux
  device runs 1Password. SSH key custody is one-way: 1P agent
  on the MacBook is the source; per-device public keys are
  rendered via chezmoi templates and pushed to each device's
  `authorized_keys` / `administrators_authorized_keys`. The
  MacBook is the SSH client; every managed device is an SSH
  server.
- **Per-device 1Password admin SSH key** is the invariant.
  Each managed device has its own ED25519 keypair in the
  `Dev` vault on `my.1password.com`, e.g.
  `op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13`.
  Public keys are committed to system-config under
  `home/private_dot_ssh/*.1password.pub.tmpl`.
- Cloudflare cannot move SSH key custody. The design must
  accept that operator-side keys live in 1Password and are
  presented via SSH agent forwarding (or `cloudflared access
  ssh` equivalent).

### Identity

- Jeff is the sole administrator. No other family member has
  fleet admin authority.
- Ahnie is a Windows administrator on MAMAWORK only and a
  user-level identity on Cloudflare. She does not administer
  the fleet.
- Kids are end users only.

### Lifecycle

- All fleet additions go through the system-config
  device-admin spec (`windows-terminal-admin-spec.md` for
  Windows; equivalent for Linux). WARP / Cloudflare enrollment
  is part of the Phase 5 work in that spec, gated on
  cloudflare-dns answering this and the prior partial requests.

### Devices that DON'T need new Cloudflare design work

- MacBook (already enrolled).
- The 6 other already-enrolled devices (already enrolled).
- `jefahnierocks.com` zone (already in cloudflare-dns Pulumi).
- Public-internet-facing services on Hetzner (out of scope; if
  any need Cloudflare proxy, that's a separate ask).

### Boundary with HomeNetOps

- OPNsense / LAN / DNS / DHCP / Wake-on-LAN policy is HomeNetOps'
  scope. Cloudflare designer can request HomeNetOps changes
  (e.g., a static reservation, a DNS record), but should not
  assume HomeNetOps will rearchitect the LAN to accommodate
  Cloudflare. The handback for that is via
  `handback-request-homenetops-2026-05-13.md`.

### Boundary with Litecky Editing Services

- Litecky workflow priorities trump Cloudflare friction on
  Ahnie's session. If a Cloudflare Gateway policy would block
  a Litecky-needed domain, the design must accommodate the
  Litecky domain. Litecky's full domain list will be provided
  by the operator (TBD) if cloudflare-dns wants a precise
  allow-list.

---

## 7. Requested Outputs (to cloudflare-dns)

Please produce a non-secret handback document in `cloudflare-dns`
that answers, at minimum:

### Profile architecture

1. Keep the four-profile model (Default / Kids / Adults /
   Headless) OR propose a new model. If new: what profiles, what
   policy each, what's the assignment rule.
2. **Jeff's profile placement** — Adults or a new `Operator` /
   `Admin` profile? Note that the actual Cloudflare admin
   identity for Jeff is a **Nash-Group IAM decision** (not
   jefahnierocks); recommend designing as if a separate
   Operator tier exists, then aliasing if IAM-planning
   collapses it back to Adults.
3. **Ahnie's profile placement** — system-config strongly
   recommends a dedicated `Adults-Ahnie` (or similar) profile,
   NOT generic Adults. Reason: kids regularly use her session
   unattended; generic adult policy would expose kid traffic
   to adult-tier content. The profile needs Litecky-friendly
   permissiveness AS THE CEILING and kid-safety guardrails AS
   THE FLOOR. Confirm whether the designer agrees, proposes
   alternatives (Windows multi-user attribution by active
   user, etc.), or wants more information.
4. How is the Windows pre-login state handled? Headless? New
   Pre-Login?

### Per-device WARP assignment (resolves blocked items)

5. fedora-top WARP enrollment — confirm Kids profile + WARP
   identity assignment (one identity for the whole device? or
   per-Linux-user attribution if available?). Cite the relevant
   Pulumi commit.
6. MAMAWORK WARP enrollment — confirm Windows multi-user MDM
   config (`multi_user=true`), per-Windows-user profile
   attribution (jeffr -> Operator/Adults, ahnie ->
   Adults/Adults-Litecky, kid SIDs -> Kids), and pre-login
   profile.
7. DSJ WARP enrollment — same questions as MAMAWORK (it's
   also a shared Windows device).

### SSH Access lanes

8. Per-device SSH Tunnel + Access app design — for fedora-top,
   MAMAWORK, DSJ, and Hetzner SSH targets. For each: tunnel
   name, Access app name, hostname pattern, who has access
   (profile / email), posture requirements, session length.
9. cloudflared connector placement — LAN, Hetzner, or both?
10. SSH client UX — does the operator use `cloudflared access
    ssh` wrapper, or Access for Infrastructure (the newer
    Cloudflare model), or something else? Each has different
    1Password SSH agent integration implications.

### Identity capture (operator-side, now resolved)

11. The operator-side identity inventory is now complete on
    the jefahnierocks side:
    - Jeff: `jeffrey@happy-patterns.com` (primary work);
      `jeffreyverlynjohnson@gmail.com` (personal).
    - Ahnie: `ahnielitecky@gmail.com` (jefahnierocks-managed
      Google identity).
    - Axel: `axelptjohnson@gmail.com`.
    - Wyn: `wynrjohnson@gmail.com`.
    - Ila: `ilagenevievemary@gmail.com`.

    **Outstanding identity decision is Nash-Group scope, not
    jefahnierocks:** Jeff's actual Cloudflare admin identity
    (Happy Patterns work email vs. personal Gmail vs. some
    other) is part of broader IAM planning at the Nash Group
    parent. cloudflare-dns can either (a) wait for Nash-Group
    IAM to resolve before finalizing operator-tier Access
    policies, or (b) design with a placeholder operator
    identity that can be re-mapped when IAM-planning lands.
    Operator preference: do not block jefahnierocks device
    cutovers on Nash-Group IAM planning; design with a
    placeholder.

### Operator-roaming policy

12. Roaming Jeff needs to admin from Starlink, hotel WiFi,
    foreign country WiFi. Access policy must tolerate that
    (no IP-based allow list pinned to home WAN; possibly a
    posture check like `WARP enrolled + Operator identity`
    instead). The managed-home-network beacon posture
    (Synology TLS beacon, §4) is NOT usable here — it only
    matches when the device is on the home LAN. Confirm the
    Access policy shape for off-LAN-operator-admin.

### Beacon / managed-network architecture

13. Confirm the home-LAN managed-network beacon
    (Synology `192.168.0.250:7443`, fingerprint
    `32e43ba53bd02cd0adfcc8f96d3ca8690e45a3340a74dd5479463625c942b380`)
    is the canonical managed-network for the family fleet. No
    second beacon expected unless designer identifies a
    concrete use case. The operator's Hetzner-beacon offer
    stands but system-config-side recommendation is to skip
    unless Hetzner becomes a user-trust location (it's not
    today).
14. Confirm beacon lifecycle: 10-year self-signed cert chosen
    to avoid ACME-rotation pinning churn (operator explicitly
    flagged this trade-off). When the cert eventually expires
    in 2036, the rotation is a coordinated event between
    Synology config + cloudflare-dns Pulumi update of the
    pinned fingerprint. Operator-side rotation runbook is a
    future system-config concern; cloudflare-dns side is the
    Pulumi update.

---

## 8. Cross-References

### system-config (this repo)

- [current-status.yaml](./current-status.yaml) — full device + WARP-blocker state
- [handback-request-cloudflare-dns-2026-05-13.md](./handback-request-cloudflare-dns-2026-05-13.md) — original cloudflare-dns request (single-Kids-identity model, now obsolete for MAMAWORK)
- [handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md](./handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md) — MAMAWORK / Windows multi-user rebaseline ask
- [cloudflare-dns-handback-ingest-2026-05-14.md](./cloudflare-dns-handback-ingest-2026-05-14.md) — system-config's ingest of cloudflare-dns commit b5b9460
- [cloudflare-windows-multi-user-ingest-2026-05-15.md](./cloudflare-windows-multi-user-ingest-2026-05-15.md) — system-config's ingest of Cloudflare Windows-multi-user docs
- [fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md) — fedora-top admin lane design (LAN SSH + future Tunnel)
- [handback-request-homenetops-2026-05-13.md](./handback-request-homenetops-2026-05-13.md) — HomeNetOps scope boundary
- [../secrets.md](../secrets.md) — secret-storage policy (1Password vault Dev on my.1password.com)
- [../mcp-config.md](../mcp-config.md) — MCP configuration including cloudflare server

### system-config blocked items (Cloudflare-side resolutions needed)

These all close when cloudflare-dns lands the appropriate
Pulumi commits:

- `fedora-top-warp-enrollment-cutover-pending` (Kids profile assignment confirmed; system-config drafts the WARP-enrollment-only packet once cloudflare-dns confirms)
- `fedora-top-ssh-over-tunnel-cutover-pending` (Pulumi commit for SSH Access app + Tunnel + connector token)
- `mamawork-warp-enrollment-cutover-pending` (Pulumi commit for Windows multi-user rebaseline)
- `mamawork-cloudflare-windows-multi-user-rebaseline` (the Pulumi work itself)
- `mamawork-warp-active-user-attribution-decision`
- `mamawork-warp-local-dns-log-privacy`
- `mamawork-litecky-allow-list-required-before-warp`
- `mamawork-litecky-org-migration-future`
- `desktop-2jj3187-warp-enrollment-cutover-pending` (same gate as MAMAWORK)

### cloudflare-dns repo (target of this handback)

- Pulumi TypeScript stacks for Cloudflare One / WARP / Gateway /
  Access / Tunnel.
- `policy-inputs.yaml` (kid emails, profile assignments).
- The cited commit `b5b9460` and any subsequent commits since.

### External (Cloudflare docs)

- WARP multi-user (Windows): https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/deployment/mdm-deployment/windows-multiuser/
- Access for Infrastructure: https://developers.cloudflare.com/cloudflare-one/access-controls/applications/non-http/infrastructure-apps/
- cloudflared access ssh: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflared/configure-cloudflared/cloudflared-binary/

---

## Operator Sign-Off Hooks

Inputs that needed operator confirmation at draft time. Status
as of the 2026-05-16 operator clarification.

### Resolved

- [x] **Ila's Google identity** — `ilagenevievemary@gmail.com`.
- [x] **Ahnie's primary identity** — `ahnielitecky@gmail.com`
  (jefahnierocks-managed).
- [x] **"TLS signal" interpretation** — NOT cloudflared
  connector (system-config's initial guess was wrong). It is
  the WARP managed-network TLS beacon on the Synology NAS
  at `192.168.0.250:7443` with the pinned SHA-256 fingerprint
  `32e43ba53bd02cd0adfcc8f96d3ca8690e45a3340a74dd5479463625c942b380`.
  See §4 for the full spec (cert CN, 10-year validity,
  Pulumi resource ID).
- [x] **Ahnie's profile target** — strong operator preference
  for a dedicated `Adults-Ahnie` profile, NOT generic Adults,
  because kids regularly use her session unattended. Adults-
  Ahnie should be permissive enough for Litecky work (and
  mildly NSFW-tolerant) but with kid-safety guardrails as the
  floor.

### Still TBD (does not block cloudflare-dns starting design,
but cloudflare-dns will need these to finalize)

- [ ] **Jeff's Cloudflare admin identity** — Happy Patterns
  email, personal Gmail, or something else. **This is a
  Nash-Group IAM-planning decision, not a jefahnierocks
  decision.** cloudflare-dns should design with a placeholder
  operator identity and re-map when Nash-Group IAM-planning
  resolves.
- [ ] **Hetzner inventory** — count of servers, role(s), public
  IP(s). Needed only if the designer wants to recommend Option
  B (cloudflared on Hetzner) or Option C (cloudflared on both)
  for SSH Tunnel placement. The operator notes "lots of
  routing considerations from services running on those
  servers" — Hetzner-side service coexistence will need
  thought.
- [ ] **Litecky domain list** (optional; only if cloudflare-dns
  wants a Litecky-specific allow-list rather than relying on
  Adults-Ahnie default).
- [ ] **Confirm Axel's devices and Ila's primary device(s)** —
  Wyn is confirmed on fedora-top; Axel and Ila device usage
  is TBD if cloudflare-dns wants to be precise about per-kid
  per-device WARP enrollment ordering.
