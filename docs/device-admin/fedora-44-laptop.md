---
title: Fedora 44 Laptop Device Administration Record
category: operations
component: device_admin
status: tailscale-retained-logged-out
version: 0.16.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, luks, firewalld, 1password, privilege, docker, infisical, tailscale]
priority: high
---

# Fedora 44 Laptop Device Administration Record

This record captures non-secret administration posture for the Fedora 44
laptop. MacBook-to-Fedora public-key SSH as `verlyn13` is verified, a stable
HomeNetOps LAN identity is verified, the SSH hardening packet has been applied
live (drop-in installed, `authorized_keys` cleaned to one approved key, `sshd`
reloaded and verified), the privilege cleanup packet has been applied live
(`wheel` and `docker` are now `verlyn13` only, `systemd-journal` is empty, the
duplicate `wyn` sudoers grant is gone, `/etc/sudoers.d/50-mesh-ops` is
removed, and all sudoers files carry policy-default SELinux user `system_u`),
and the Infisical/Redis retirement packet has been applied live (the
`happy-secrets` compose project is fully removed: three containers, two
volumes, and one network gone; three project-only images removed; the three
Infisical Cloudsmith DNF repo entries removed; no listeners remain on
`18080`/`6379`/`5432`). The device is not fully hardened or fully managed
yet - firewall narrowing, Tailscale/WARP/Cloudflare decisions, LUKS/power
posture, a future review of `verlyn13 NOPASSWD: ALL`, and a general Docker
hygiene pass over the remaining exited containers and unrelated images
remain.

## Source Input

Ingested source:
`/Users/verlyn13/Downloads/fedora-top-remote-admin-report-2026-05-12.md`.

The source report was captured locally from `fedora-top` on 2026-05-12 AKDT /
2026-05-13 UTC. Treat its current-state observations as planning evidence that
still needs targeted re-verification during execution.

The source report's build plan is not authoritative for Jefahnierocks
administration. Access setup, WARP enrollment, Cloudflare routing, Tailscale
break-glass, 1Password records, and device-side changes must be translated into
the local `system-config`, `cloudflare-dns`, and HomeNetOps standards before
execution.

## Returned Readiness Update

External evidence ingested from:

- `/Users/verlyn13/Documents/temp/fedora-top-readiness-report-2026-05-12.md`
- `/Users/verlyn13/Downloads/fedora-top-phase-1-ssh-foothold-report-2026-05-13.md`
- [fedora-top-phase-1-ssh-foothold-2026-05-13.md](./fedora-top-phase-1-ssh-foothold-2026-05-13.md)
  for the repo-safe Phase 1 ingestion and MacBook-side smoke test result.
- `/Users/verlyn13/Downloads/fedora-top-authorized-key-install-report-2026-05-13.md`
- [fedora-top-ssh-login-and-baseline-2026-05-13.md](./fedora-top-ssh-login-and-baseline-2026-05-13.md)
  for the repo-safe key-install result, successful MacBook SSH test, and
  remote read-only baseline.
- `/home/verlyn13/device-admin-prep/fedora-top-prehardening-report-2026-05-13.md`
  on `fedora-top`
- [fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md)
  for the repo-safe pre-hardening detail ingest.
- HomeNetOps hand-back from 2026-05-13
- [fedora-top-homenetops-lan-identity-2026-05-13.md](./fedora-top-homenetops-lan-identity-2026-05-13.md)
  for the repo-safe static DHCP/local DNS ingest.
- [fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md)
  for the prepared SSH hardening commands, rollback, and live read-only
  verification.
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
  for the live apply evidence, including the kernel `fs.protected_regular`
  deviation note for the tempfile handling in the cleanup script.
- [fedora-top-privilege-cleanup-packet-2026-05-13.md](./fedora-top-privilege-cleanup-packet-2026-05-13.md)
  for the privilege cleanup packet (group memberships, sudoers duplicate,
  `/etc/sudoers.d/50-mesh-ops` decision, restorecon, validation, and
  rollback).
- [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md)
  for the live apply evidence including snapshot path, group-membership
  diff, post-apply `sudo -l` per user, and the R10 `restorecon -F`
  deviation note.
- [fedora-top-infisical-redis-retirement-packet-2026-05-13.md](./fedora-top-infisical-redis-retirement-packet-2026-05-13.md)
  for the Infisical/Redis retirement packet covering the `happy-secrets`
  compose project (three containers, two volumes, one network), the three
  Infisical Cloudsmith DNF repo entries, and the three project-only Docker
  images.
- [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md)
  for the live apply evidence including the forensic-only snapshot path,
  the redacted env-key list per container, the compose down sequence, the
  image-layer removal log, the DNF metadata cleanup report, and the
  comprehensive boundary-sanity validation that confirmed SSH, sudoers,
  firewalld, Tailscale, and unrelated Docker projects were untouched.
- [fedora-top-firewalld-narrowing-packet-2026-05-13.md](./fedora-top-firewalld-narrowing-packet-2026-05-13.md)
  for the `firewalld` narrowing packet that removes the
  `FedoraWorkstation` zone's broad `1025-65535/tcp,udp` allowances while
  keeping `ssh`, `mdns`, `samba-client`, and `dhcpv6-client` services
  intact, plus snapshot-backed rollback.
- [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md)
  for the live apply evidence including snapshot path, the empty
  post-apply `ports` listing in both runtime and permanent, and the
  positive fresh-session SSH check.
- [current-status.yaml](./current-status.yaml) plus
  [handback-format.md](./handback-format.md) for the machine-readable
  per-device current state and the agent handback template. Update
  `current-status.yaml` in the same commit that lands any new
  `*-packet-*.md` or `*-apply-*.md` so the YAML stays the
  authoritative summary.
- [fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md)
  for the Tailscale decision packet (two options with their own
  approval phrases).
- [fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md)
  for the decision record. Guardian chose **Option B - Retain
  logged-out**; documentation-only apply, no live host change.
  Tailscale package, daemon, repo, GPG key, listener posture all
  unchanged. Further Tailscale operating work is blocked on the
  remote-admin routing design packet.
- [fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md)
  for the prepared remote-admin routing design. Compares LAN-only
  SSH (current), Tailscale (transition / break-glass, retained
  logged-out), and Cloudflare WARP + `cloudflared` (target).
  Categorizes direct WAN SSH as rejected. Enumerates evidence
  needed from `cloudflare-dns` and from HomeNetOps. Records
  household admin / family-account stance.
- [cloudflare-dns-handback-ingest-2026-05-14.md](./cloudflare-dns-handback-ingest-2026-05-14.md)
  for the authoritative `cloudflare-dns` handback (commit
  `b5b9460`, path `docs/handback-system-config-2026-05-13.md` in
  the cloudflare-dns repo). Cloudflare account is a single account
  with team `homezerotrust`; IaC is **Pulumi (TypeScript)**, NOT
  OpenTofu; tokens live in **gopass** under
  `cloudflare/cloudflare-dns/*`. Profile recommendation for
  fedora-top: **Kids profile**, WARP identity
  `wynrjohnson@gmail.com` (already in `policy-inputs.yaml`
  kids.emails); no Pulumi change needed for WARP-only enrollment.
  Off-LAN SSH path requires a future cloudflare-dns Pulumi commit
  adding the SSH Access app + Tunnel + connector token (naming
  candidates `access-app-ssh-fedora-top` and `tunnel-fedora-top`;
  hostname `ssh-fedora-top.homezerotrust.cloudflareaccess.com`).

Repo-safe current facts from these updates:

- Fresh read-only pass confirms `fedora-top`, Fedora 44 Workstation, kernel
  `7.0.4-200.fc44.x86_64`, and Wi-Fi `192.168.0.206/24`.
- `wyn` remains in `wheel`; `sudo -l -U wyn` reports two `(ALL) ALL` grants.
- `axel`, `ila`, and `mesh-ops` remain in `wheel`; `ila` and `mesh-ops` are in
  `docker`.
- `sshd` is enabled and active, listening on all IPv4/IPv6 interfaces.
- The handoff did not freshly verify effective SSH password-auth settings
  because non-root `sshd -T` could not read the full config.
- `firewalld` is active with the permissive `FedoraWorkstation` zone on Wi-Fi,
  allowing `ssh`, `mdns`, `samba-client`, and broad high TCP/UDP ports.
- WARP and `cloudflared` are absent.
- Tailscale is installed and active but logged out; login URL was intentionally
  omitted.
- LUKS2 root/home encryption remains confirmed; TPM2 exists; Secure Boot is
  disabled.
- Laptop was on battery, not AC, and recent suspend activity was observed.
- Docker publishes Redis on all interfaces at `6379` and Infisical on all
  interfaces at `18080`.
- `dnf check-update --refresh` prompted for Infisical/Tailscale signing-key
  imports; prompts were not accepted.
- Human operator clarified that Jefahnierocks owns the device, `verlyn13`
  should be the only account running mission-critical services, exploratory
  accounts should stay usable without dangerous privileges, and Infisical
  belongs on the Hetzner server only.
- Phase 1 Fedora-side SSH foothold report confirms AC power connected, Wi-Fi
  MAC `66:B5:8C:F5:45:74`, current LAN IP `192.168.0.206/24`, `sshd` enabled
  and active, TCP `22` listening on IPv4/IPv6, and
  `/home/verlyn13/.ssh/authorized_keys` present with correct ownership and
  permissions.
- MacBook-side smoke test initially confirmed TCP `22` reachability but failed
  public-key SSH before the approved MacBook key was installed.
- Authorized-key install report confirms approved key fingerprint
  `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8` was installed with
  correct permissions and SELinux context.
- MacBook-side public-key SSH as `verlyn13` now succeeds using the selected
  1Password-backed human interactive key. `sudo -n true` succeeded during the
  smoke test.
- Remote baseline confirms effective SSH still has `PasswordAuthentication
  yes`, `X11Forwarding yes`, `AllowTcpForwarding yes`, and
  `AllowAgentForwarding yes`; SSH is usable but not hardened.
- Pre-hardening detail report confirms `/home/verlyn13/.ssh/authorized_keys`
  contains three ED25519 public keys. Only the MacBook key fingerprint
  `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8` is approved for this
  slice; the `ansible@hetzner.hq` and
  `verlyn13@wsl-fedora42-to-thinkpad-t440s` keys need a retain/rotate/remove
  decision before SSH hardening.
- Pre-hardening detail report verifies `FedoraWorkstation` permits
  `1025-65535/tcp`, `1025-65535/udp`, `ssh`, `mdns`, `samba-client`, and
  `dhcpv6-client`; the Docker zone is active with target `ACCEPT`.
- Pre-hardening detail report verifies `verlyn13`, `wyn`, `axel`, `ila`, and
  `mesh-ops` remain in `wheel`; `verlyn13`, `ila`, and `mesh-ops` remain in
  `docker`.
- Pre-hardening detail report flags sudoers issues: wrong mode on
  `/etc/sudoers.d/50-mesh-ops`, duplicate explicit `wyn ALL=(ALL) ALL`,
  `verlyn13` `NOPASSWD: ALL`, and broad `mesh-ops` `NOPASSWD` wildcards.
- Pre-hardening detail report verifies Docker project `happy-secrets` still
  publishes Infisical on `18080` and Redis on `6379` on all IPv4/IPv6
  interfaces.
- Pre-hardening detail report verifies DNF signing-key failures for Tailscale
  and Infisical repos; no signing keys were accepted.
- Pre-hardening detail report verifies Tailscale is installed and `tailscaled`
  is active but logged out; WARP and `cloudflared` are absent; Cockpit socket
  is disabled.
- Pre-hardening detail report verifies AC online, Btrfs on LUKS2, TPM2
  support, Secure Boot disabled, and dual boot with Windows Boot Manager.
- HomeNetOps hand-back confirms static DHCP already in place for Wi-Fi MAC
  `66:b5:8c:f5:45:74`, retaining `192.168.0.206`.
- HomeNetOps hand-back confirms Unbound local DNS
  `fedora-top.home.arpa -> 192.168.0.206`, UUID
  `ce8c9be1-7b03-4965-8f40-d3adc8a079ac`.
- HomeNetOps hand-back verifies `dig fedora-top.home.arpa +short` resolves to
  `192.168.0.206` and `nc -vz -G 3 fedora-top.home.arpa 22` succeeds.
- HomeNetOps hand-back confirms no WAN, public DNS, Cloudflare, WARP,
  Tailscale, firewall, or Wi-Fi WoL changes were made.
- SSH hardening packet live read-only check on `2026-05-13T12:00:37-08:00`
  confirms `sshd` is active/enabled, `sshd -t` passes, and sudo
  non-interactive access is available for `verlyn13`.
- Direct SSH to `fedora-top.home.arpa` from the MacBook failed host-key
  verification because the FQDN is not yet in local `known_hosts`; read-only
  verification used `HostKeyAlias=192.168.0.206` without changing local trust
  files. The known IP host-key fingerprint is
  `SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w`.
- Live key check now shows four active `authorized_keys` lines: the approved
  MacBook key, the WSL key, and two duplicate `ansible@hetzner.hq` entries.
- SSH hardening packet was applied live on `2026-05-13T20:58:27Z` (see the
  apply record). `authorized_keys` now contains exactly one key, the approved
  MacBook fingerprint. The drop-in
  `/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf` is in place
  (`root:root`, `0600`), `sshd -t` passed, `systemctl reload sshd` succeeded,
  the second-session verification returned the nine target effective settings,
  and a negative password-auth check confirmed the server refuses
  non-publickey authentication. Rollback was not used.
- The cleanup script's early `chown verlyn13:verlyn13 "$TMP"` line was
  dropped at apply time because the Fedora 44 kernel's `fs.protected_regular`
  protection refuses writes from a different fsuid into a sticky/world-writable
  directory like `/tmp`, even for root. The final
  `install -m 600 -o verlyn13 -g verlyn13` still sets destination ownership,
  so on-disk outcome is unchanged from the prepared packet.
- 2026-05-13 privilege-state read-only verification (via the hardened SSH
  channel) confirms `wheel` = `verlyn13, wyn, axel, ila, mesh-ops`,
  `docker` = `verlyn13, ila, mesh-ops`, `systemd-journal` includes
  `mesh-ops`, `dialout`/`plugdev` include `axel`; per-user `sudo -l`
  matches the pre-hardening report (duplicate `wyn` grant at
  `/etc/sudoers:108` and broad `mesh-ops` NOPASSWD wildcards remain); the
  effective sshd `allowusers` is still `verlyn13` only.
- `visudo -c` flagged `/etc/sudoers.d/50-mesh-ops: bad permissions, should
  be mode 0440`. The file was mode `0644` and still effective at the time
  of verification; both sudoers drop-ins also carried `unconfined_u`
  SELinux user rather than `system_u`. These observations drove the
  privilege cleanup packet contents.
- Privilege cleanup packet was applied live on `2026-05-13T21:22:44Z` (see
  the apply record). Post-apply state: `wheel` = `verlyn13` only, `docker`
  = `verlyn13` only, `systemd-journal` empty; per-user `sudo -l` returns
  "not allowed to run sudo" for `wyn`, `axel`, `ila`, `mesh-ops`;
  `verlyn13` retains `(ALL) ALL` via `%wheel` and `NOPASSWD: ALL` via
  `/etc/sudoers.d/ansible-automation`; `/etc/sudoers.d/50-mesh-ops` is
  removed; the duplicate `wyn ALL=(ALL) ALL` line is gone from
  `/etc/sudoers`; all sudoers files carry policy-default
  `system_u:object_r:etc_t:s0`; `visudo -c` is fully clean; `sshd -T`
  `allowusers` remains `verlyn13`; pre-apply snapshot kept at
  `/var/backups/jefahnierocks-priv-cleanup-20260513T212114Z`. Rollback was
  not used.
- 2026-05-13 service-state read-only verification (via the hardened SSH
  channel) confirmed compose project `happy-secrets` had three running
  containers (`infisical-app`, `infisical-redis`, `infisical-postgres`)
  publishing `18080/tcp` and `6379/tcp` to all interfaces with restart
  policies `unless-stopped`/`always`; two named volumes
  (`happy-secrets_pg_data` ~74M, `happy-secrets_redis_data` ~353K); one
  bridge network (`happy-secrets_infisical`); and a compose label that
  referenced `/home/verlyn13/Projects/happy-secrets/docker-compose.yml`
  even though that directory and file had already been removed (compose
  commands worked against labels alone). Three project-only images
  totaled ~1.95 GB. Three Infisical Cloudsmith DNF repo entries were
  enabled. The Postgres DB password was visible in the running container's
  env at that point.
- Infisical/Redis retirement packet was applied live on
  `2026-05-13T21:50:17Z` (see the apply record). Post-apply state: no
  `happy-secrets`-labelled containers, volumes, or networks; no
  `infisical-*` containers by name; no listeners on `18080`/`6379`/`5432`;
  the three project-only images (`infisical/infisical:latest-postgres`,
  `postgres:14-alpine`, `redis:7`) are gone (~1.95 GB reclaimed plus 221
  MiB of DNF metadata cache); the file
  `/etc/yum.repos.d/infisical-infisical-cli.repo` is gone and the three
  Infisical Cloudsmith repos no longer appear in `dnf repolist
  --enabled`; Tailscale stable repo intact; `sshd allowusers verlyn13`,
  `visudo -c` clean, `firewalld` running with the same service set as
  before, Docker engine `29.4.2` still active. Forensic-only snapshot kept
  at `/var/backups/jefahnierocks-infisical-redis-retirement-20260513T214856Z`;
  rollback was not used and is not applicable (volume destruction is
  intentional and irreversible per the approved phrase).
- 2026-05-13 firewalld read-only verification (via the hardened SSH
  channel) confirmed firewalld `2.4.0` active and enabled, nftables
  backend, default zone `FedoraWorkstation`, runtime and permanent
  configurations identical in content, no rich rules / direct rules /
  passthroughs on `FedoraWorkstation`, NetworkManager `connection.zone`
  unset on all active connections. `FedoraWorkstation` permitted
  `1025-65535/tcp,udp` plus services `dhcpv6-client mdns samba-client
  ssh`. The `docker` zone retained `target: ACCEPT` with all Docker
  bridges attached at runtime.
- firewalld narrowing packet was applied live on `2026-05-13T23:03:01Z`
  (see the apply record). Post-apply state: `FedoraWorkstation` ports
  are empty in both runtime and permanent; services unchanged
  (`dhcpv6-client mdns samba-client ssh`); rich rules still empty;
  active zone bindings unchanged (`FedoraWorkstation` on `wlp0s20f3`,
  `docker` on the seven Docker bridges); `docker` zone unchanged
  (`target: ACCEPT`, out of scope); `sshd -T allowusers verlyn13`
  unchanged; positive SSH from a fresh MacBook session succeeded
  (`nc -vz` + interactive command). Pre-apply snapshot retained at
  `/var/backups/jefahnierocks-firewalld-narrowing-20260513T230224Z`;
  rollback unused.
- 2026-05-13 Tailscale read-only verification (via the hardened SSH
  channel) confirms `tailscale-1.96.4-1` installed, `tailscaled`
  active and enabled, logged out, UDP `41641` listener bound by
  `tailscaled` but blocked by the post-narrowing firewall; `tailscale
  netcheck` shows DERP-relay reachability (Seattle ~54 ms) without
  any open inbound UDP; `tailscale-stable` DNF repo healthy and
  `gpg-pubkey-957f5868-5e5499b8` imported, with `tailscale 1.98.1-1`
  pending as an available upgrade (not applied); no host systemd
  unit, cron, or firewalld rule otherwise references Tailscale; no
  account retains a NOPASSWD sudoers grant over `tailscale *` or
  `systemctl ... tailscaled` after the privilege cleanup. A
  node-bound enrollment URL is emitted by `tailscale status` while
  the host is logged out; treat that URL as a sensitive artifact
  and do not record it in this repo.
- 2026-05-13 Tailscale retain-or-remove decision was recorded as
  documentation-only (Option B from the prepared packet). The
  guardian chose to keep Tailscale installed and logged out as
  transitional / break-glass design space, explicitly prohibiting
  login, enrollment, auth-key creation, firewalld passage, package
  upgrade, and any daemon restart in this packet's scope. The
  current Tailscale posture is unchanged from the verification above.
  Further Tailscale operating work is blocked on the remote-admin
  routing design packet.

## Identity

| Field | Value |
|---|---|
| Device label | Lenovo ThinkPad X1 Carbon Gen 10 |
| Proposed hostname | `fedora-top` |
| OS version/build | Fedora Linux 44 Workstation Edition; kernel `7.0.4-200.fc44.x86_64`, from source report |
| Intended user/owner | Jefahnierocks-owned Wyn summer-use laptop; `verlyn13` is the sole mission-critical admin/service owner |
| Physical location / administrative context | Home LAN behind OPNsense, same LAN context as `nas.jefahnierocks.com` and `opnsense.jefahnierocks.com`; laptop currently on home Wi-Fi; remote administration requires AC power and no unattended reboot unless LUKS unlock is solved |
| Serial/service tag | Recorded in source report; omitted from this repo record unless needed for support workflow |

## Network Identity

| Field | Value |
|---|---|
| Wired MAC | Pending device access |
| Wi-Fi MAC | `66:B5:8C:F5:45:74`, verified in Phase 1 report |
| Current LAN IP | `192.168.0.206/24` on Wi-Fi; static via OPNsense ISC DHCPv4 reservation |
| Tailscale identity | Tailscale installed and service active but logged out; no Tailscale IP in source report |
| WARP identity | WARP not installed in source report |
| DNS / hostname record | `fedora-top.home.arpa -> 192.168.0.206`, verified by HomeNetOps |
| HomeNetOps DNS UUID | `ce8c9be1-7b03-4965-8f40-d3adc8a079ac` |
| WoL | Not configured; Wi-Fi laptop and no HomeNetOps policy for this device class |

## Administration Model

| Control | Target | Current status |
|---|---|---|
| Local admin credential | Unique per-device admin credential stored in 1Password only. Device-specific management account may be created if the implementation needs it. | Planned; item/account not created. |
| 1Password local admin item | `jefahnierocks-device-fedora-top-local-admin` | Planned; secret value not created here. |
| Recovery key item | `jefahnierocks-device-fedora-top-recovery-key` | Planned for LUKS recovery material. |
| Administrative SSH | Use verified `verlyn13` SSH from the MacBook over trusted LAN; finish hardening remotely from `system-config` in small approval-gated packets. | Verified from MacBook to `192.168.0.206` using the selected 1Password-backed human interactive key. |
| SSH identity | Device-specific or explicitly approved human-interactive key use only; no unattended automation with a human workstation key. | Applied: `authorized_keys` contains exactly one key, the approved MacBook fingerprint `SHA256:ofocO0zOCEVFg7bAP6ElZLe7cfjBMi53zXMc5Y4sPa8`. WSL and duplicate `ansible@hetzner.hq` lines were removed. Pre-apply backup retained on host. |
| Password SSH | Disable after key-based access is confirmed and local fallback remains open. | Applied: `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `AuthenticationMethods publickey`, `AllowUsers verlyn13`. Negative password-auth check confirms the server refuses non-publickey login. |
| Mission-critical service owner | `verlyn13` is the only account that should own or run mission-critical services. | Applied (privilege cleanup): `wheel` and `docker` are now `verlyn13` only; `systemd-journal` empty; `mesh-ops` lost its NOPASSWD wildcards. `verlyn13 NOPASSWD: ALL` via `/etc/sudoers.d/ansible-automation` retained pending separate review. |
| Exploratory users | `wyn`, `axel`, `ila`, and other human exploratory accounts may remain usable, but should not have `wheel`, sudo, Docker, or service-management authority by default. | Applied: `wyn`, `axel`, `ila`, `mesh-ops` no longer in `wheel`; `ila` and `mesh-ops` no longer in `docker`; `mesh-ops` no longer in `systemd-journal`; all four return "not allowed to run sudo" on `sudo -l`. `axel` retains `dialout` and `plugdev` (hardware-only groups, not admin). Accounts remain usable as standard users. |

## Remote Access

Preferred path:

- SSH over trusted LAN first, then Cloudflare private routing or
  Access-protected hostname later if needed.
- Public-key authentication first; keep password SSH temporarily until
  MacBook-to-Fedora public-key access is verified.
- Do not expose SSH on public WAN.
- Do not use the human workstation SSH identity as unattended automation.
- Follow the existing `system-config` 1Password SSH-agent posture for human
  interactive access.

Current state:

- Phase 1 confirms OpenSSH server is enabled, active, and listening on all
  IPv4/IPv6 interfaces.
- MacBook TCP reachability to `fedora-top.home.arpa:22` and
  `192.168.0.206:22` is verified.
- MacBook public-key SSH as `verlyn13` is verified.
- `verlyn13` currently has non-interactive sudo capability.
- Pre-hardening detail report observed password authentication, agent
  forwarding, TCP forwarding, and X11 forwarding still enabled with no
  `AllowUsers` rule active. After the 2026-05-13 apply, effective settings
  are now `PermitRootLogin no`, `PubkeyAuthentication yes`,
  `PasswordAuthentication no`, `KbdInteractiveAuthentication no`,
  `AuthenticationMethods publickey`, `AllowUsers verlyn13`, and all three
  forwarding directives are `no`.
- Pre-hardening detail report verifies WARP and `cloudflared` are absent and
  Tailscale is installed but logged out.
- Do not claim this Fedora laptop is fully managed until SSH hardening,
  firewall narrowing, privilege cleanup, service exposure cleanup, and
  recovery/power posture are completed and verified.

## SSH Foothold Phase

The SSH foothold is complete. Most remaining administration can now be done
remotely from here, but hardening still needs explicit approval and should be
split into small packets.

Phase 1 current result:

- Fedora-side checks are complete.
- AC power is connected.
- TCP `22` is reachable from the MacBook by stable FQDN and IP.
- Public-key SSH from the MacBook succeeds as `verlyn13`.
- Remote read-only baseline has been collected.
- Fedora-side pre-hardening detail report has been collected.
- HomeNetOps static DHCP/local DNS is complete.

Next work should do the larger hardening remotely from the MacBook:

- SSH drop-in hardening and password-SSH disablement after a rollback path is
  ready and the two non-approved public keys have a disposition. Completed on
  2026-05-13; see
  [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md).
- Privilege cleanup so `verlyn13` is the only mission-critical
  admin/service owner.
- Retirement of laptop-hosted Infisical and rebinding/stopping broad Redis or
  Docker-published admin surfaces. Applied on 2026-05-13; see
  [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md).
- `firewalld` narrowing for SSH and removal of broad workstation-zone
  exposure after SSH and service-retirement sequencing is clear.
- Fedora update/GPG-key decisions.
- LUKS/reboot strategy and AC/no-sleep policy.

## Security Posture

| Area | Target | Current status |
|---|---|---|
| Disk encryption | LUKS/FDE status verified; recovery material stored in 1Password only if applicable. | Source report says root/home volume is LUKS2. Remote reboot is blocked unless TPM2/FIDO2/initramfs/local unlock strategy is chosen. |
| SSH daemon | Enabled only with key-only admin access and private routing constraints. | Enabled, active, all-interface listen. Effective config is hardened by `20-jefahnierocks-admin.conf` (drop-in `root:root`, `0600`); SSH remains LAN-only and is not exposed on WAN. |
| SSH auth | Public-key auth confirmed before disabling password SSH. | Public-key login from MacBook succeeds. Effective config now has `PasswordAuthentication no`, `AuthenticationMethods publickey`, `AllowUsers verlyn13`; negative password-auth check confirms server refuses non-publickey login. |
| Firewall | `firewalld` or equivalent active; SSH limited to Cloudflare/Tailscale/trusted path. | Applied (narrowing): `FedoraWorkstation` ports are empty; services `dhcpv6-client mdns samba-client ssh` unchanged; rich rules empty; SSH for `verlyn13` reachable over LAN only; no WAN exposure. `docker` zone still `target: ACCEPT` (separate hygiene packet remains). Off-LAN/private routing for SSH is a separate Tailscale/WARP/Cloudflare decision. |
| Updates | Fedora updates current or scheduled; repo GPG prompts resolved deliberately. | Latest report says DNF refresh found a pending VS Code update and signing-key failures for Infisical/Tailscale repos; prompts were not accepted. |
| Containers | No Redis or admin surface exposed broadly on LAN. Infisical should not run on this laptop; current needed Infisical location is Hetzner only. | Applied: `happy-secrets` compose project fully removed (3 containers, 2 volumes, 1 network); three project-only images gone; three Infisical DNF repos retired; no listeners on `18080`/`6379`/`5432`. Other unrelated exited containers (`api`, `maat-framework`, `scanner`, `act-*`) remain pending a general Docker hygiene packet. |
| Power/recovery | AC connected; no sleep/hibernate on AC; no remote reboot until LUKS strategy is proven. | Latest report says AC is online and battery is `80%`, `pending-charge`; prior suspend/resume is recorded, so AC/no-sleep policy still needs deliberate verification before relying on remote availability. |

## Approval-Gated Build Phases

Do not execute these without explicit approval:

0. Establish the LAN SSH foothold for `verlyn13` from the MacBook.
   Completed on 2026-05-13; remote management can now continue from here.
1. Request HomeNetOps static DHCP/local DNS using the verified Wi-Fi MAC,
   current IP, and hostname.
   Completed on 2026-05-13; `fedora-top.home.arpa` resolves to
   `192.168.0.206` and SSH on TCP `22` is reachable through the FQDN.
2. Confirm the disposition for the two non-approved public keys in
   `authorized_keys`, then harden `sshd` with a drop-in and rollback path.
   Packet prepared in
   [fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md);
   applied on 2026-05-13 with redacted evidence in
   [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md).
   `authorized_keys` now retains only the approved MacBook key; drop-in
   `/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf` is in place;
   second-session verification and negative password-auth check both passed.
3. Remove non-`verlyn13` accounts from `wheel`, sudoers, Docker, and
   service-management paths unless an account has a documented administrative
   purpose. Packet prepared in
   [fedora-top-privilege-cleanup-packet-2026-05-13.md](./fedora-top-privilege-cleanup-packet-2026-05-13.md);
   applied on 2026-05-13 with redacted evidence in
   [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md).
   `wheel` and `docker` are now `verlyn13` only; `systemd-journal` empty;
   duplicate `wyn` sudoers line removed; `/etc/sudoers.d/50-mesh-ops` removed;
   SELinux contexts on sudoers files normalized to `system_u`.
4. Retire Infisical from the laptop and stop or rebind Docker-published Redis
   and admin surfaces so they are not exposed on the LAN. Packet prepared in
   [fedora-top-infisical-redis-retirement-packet-2026-05-13.md](./fedora-top-infisical-redis-retirement-packet-2026-05-13.md);
   applied on 2026-05-13 with redacted evidence in
   [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md).
   `happy-secrets` compose project, the three project-only images, and the
   three Infisical Cloudsmith DNF repos are gone. Forensic-only snapshot
   retained at `/var/backups/jefahnierocks-infisical-redis-retirement-20260513T214856Z`.
5. Tighten `firewalld` after SSH and service-retirement sequencing is clear.
   Packet prepared in
   [fedora-top-firewalld-narrowing-packet-2026-05-13.md](./fedora-top-firewalld-narrowing-packet-2026-05-13.md);
   applied on 2026-05-13 with redacted evidence in
   [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md).
   `FedoraWorkstation` ports are now empty in both runtime and permanent;
   services unchanged; SSH continues to work for `verlyn13` over LAN.
   Docker zone remains untouched and is a separate hygiene packet.
6. Decide whether to retain Tailscale as ACL-restricted break-glass, remove it,
   or leave it installed but logged out temporarily. Packet prepared in
   [fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md);
   guardian chose Option B (Retain logged-out) on 2026-05-13 as
   transitional / break-glass design space (see
   [fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md)).
   Documentation-only; live state unchanged. Further Tailscale work is
   blocked on the remote-admin routing design packet.
7. Install/enroll Cloudflare WARP and install/configure `cloudflared` only
   after the Cloudflare design packet is approved.
8. Create Cloudflare Access/private routing for SSH and optional Cockpit only
   after WARP/Cloudflare policy is approved.
9. Configure AC/no-sleep/no-hibernate policy for the summer period.
10. Choose and test the LUKS remote-reboot strategy.
11. Optionally investigate AMT/vPro in BIOS, but do not assume it is live.

## Evidence

Source evidence has been ingested from the downloaded Fedora reports.
MacBook-side TCP and SSH checks plus the remote read-only baseline were run
from this repo session and recorded in
[fedora-top-ssh-login-and-baseline-2026-05-13.md](./fedora-top-ssh-login-and-baseline-2026-05-13.md).
The Fedora-side pre-hardening detail report is summarized in
[fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md).
HomeNetOps static DHCP/local DNS is summarized in
[fedora-top-homenetops-lan-identity-2026-05-13.md](./fedora-top-homenetops-lan-identity-2026-05-13.md).
The prepared SSH hardening packet is recorded in
[fedora-top-ssh-hardening-packet-2026-05-13.md](./fedora-top-ssh-hardening-packet-2026-05-13.md).
The live apply on 2026-05-13 is recorded in
[fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md).

Future entries should use this shape:

```text
timestamp:
source:
observed:
proof:
repo-safe output:
private raw evidence:
status:
```

Useful non-secret proof sources once the human has access:

- `hostnamectl`
- `cat /etc/fedora-release`
- `nmcli device show` with private data redacted before copying into repo docs.
- `lsblk -f` or `cryptsetup status <name>` with identifiers redacted as needed.
- `systemctl status sshd --no-pager`
- `ss -tulpn` with attention to SSH binding.
- `firewall-cmd --state` and `firewall-cmd --list-all`
- Tailscale or WARP client status, if installed.

## Checklist

### Verified Current State

- Source report identifies the host as `fedora-top`, Fedora Linux 44
  Workstation Edition on a ThinkPad X1 Carbon Gen 10.
- Source report says LUKS2 protects the root/home volume.
- Latest readiness report freshly verifies `wyn` has admin rights through
  `wheel` and duplicate `(ALL) ALL` sudo grants.
- Latest readiness report confirms SSH is enabled with broad listen scope.
  Pre-hardening report verifies effective SSH settings are permissive:
  password auth, agent forwarding, TCP forwarding, and X11 forwarding are
  enabled, and no `AllowUsers` constraint is active.
- Latest readiness report confirms WARP and `cloudflared` are absent; Tailscale
  is installed but logged out.
- Latest readiness report confirms AC/power readiness is not met and Docker
  exposes Redis/Infisical broadly on LAN.
- Phase 1 Fedora-side report confirms AC is now connected, Wi-Fi MAC is
  `66:B5:8C:F5:45:74`, TCP `22` is listening, and
  `/home/verlyn13/.ssh/authorized_keys` permissions are correct.
- HomeNetOps hand-back confirms static DHCP for Wi-Fi MAC
  `66:b5:8c:f5:45:74`, IP `192.168.0.206`, and local FQDN
  `fedora-top.home.arpa`.
- HomeNetOps hand-back verifies FQDN resolution and TCP `22` reachability.
- Authorized-key install report confirms the selected MacBook public key is
  present with correct ownership, permissions, and SELinux context.
- MacBook-side check confirms public-key SSH login as `verlyn13` succeeds.
- Remote baseline confirms `verlyn13` currently has non-interactive sudo and
  Docker group membership.
- Pre-hardening report confirms three public keys are present for `verlyn13`;
  only the MacBook key is approved for this slice.
- Live SSH packet preparation check now shows four active `authorized_keys`
  lines because the `ansible@hetzner.hq` key is duplicated.
- Live SSH packet preparation check confirms `/etc/ssh/sshd_config` includes
  `/etc/ssh/sshd_config.d/*.conf` at line 15; the prepared drop-in uses
  `20-jefahnierocks-admin.conf` so it wins before `50-redhat.conf`.
- Pre-hardening report confirms broad `firewalld` workstation-zone exposure and
  Docker zone target `ACCEPT`.
- Pre-hardening report confirms sudoers issues that need cleanup:
  `50-mesh-ops` mode, duplicate `wyn` grant, `verlyn13` `NOPASSWD: ALL`, and
  broad `mesh-ops` wildcards.
- Pre-hardening report confirms Infisical and Redis remain published on all
  IPv4/IPv6 interfaces.
- Pre-hardening report confirms Tailscale/Infisical repo signing-key failures
  were observed and no keys were accepted.
- 2026-05-13 apply record confirms `authorized_keys` now contains exactly
  one key (approved MacBook fingerprint), the drop-in
  `/etc/ssh/sshd_config.d/20-jefahnierocks-admin.conf` is in place
  (`root:root`, `0600`), `sshd -t` passed, `systemctl reload sshd` succeeded,
  and the nine target effective settings are active. Negative password-auth
  check refused login as expected.

### Safe Next Manual Step

- Treat the SSH foothold and SSH hardening as verified. Do not perform broad
  hardening in one batch.
- Use `fedora-top.home.arpa` as the stable LAN administration target.
- Reconcile the MacBook `known_hosts` entry for `fedora-top.home.arpa` so
  the `HostKeyAlias=192.168.0.206` workaround is no longer needed.
- Privilege cleanup default path applied on 2026-05-13; see
  [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md).
  Snapshot rollback target kept at
  `/var/backups/jefahnierocks-priv-cleanup-20260513T212114Z` on the host.
  Next privilege-related decisions: `mesh-ops` account lifecycle (lock or
  delete), a future narrow review of `verlyn13 NOPASSWD: ALL`, and an
  account-shell decision for any exploratory account that should not retain
  interactive login.
- Infisical/Redis retirement is applied; see
  [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md).
  `firewalld` narrowing is now safe to plan because no `happy-secrets`
  listener remains; the `FedoraWorkstation` zone's broad
  `1025-65535/tcp,udp` allowances now have nothing of ours bound on those
  ports.
- firewalld narrowing applied on 2026-05-13; see
  [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md).
  Snapshot rollback target kept at
  `/var/backups/jefahnierocks-firewalld-narrowing-20260513T230224Z`.
- Use Wi-Fi MAC `66:B5:8C:F5:45:74` and current IP `192.168.0.206` if
  HomeNetOps static DHCP/local DNS planning is requested.
- Live read-only review of users, groups, sudoers, lingering user services,
  and Docker access completed on 2026-05-13; results drive the privilege
  cleanup packet referenced above. Re-run before any future live apply to
  detect drift since this verification.
- Keep exploratory accounts, including `wyn`, usable as standard accounts
  without sudo, Docker, broad service control, or ownership of critical
  services.
- Confirm whether Tailscale should be retained as break-glass or removed.
- Choose LUKS strategy before remote reboot is relied on.
- Decide whether Cockpit is useful enough to enable behind Cloudflare Access.
- Laptop-hosted Infisical surface and broadly exposed Redis are retired
  (see retirement apply linked above); current Infisical authority is the
  Hetzner server only.
- Decide whether a static DHCP mapping or local DNS record should be requested
  through HomeNetOps only if future network identity changes are needed.
- Connect AC power before relying on this device remotely.

### Blocked Pending Human/Device Access

- Approval for firewall narrowing implementation.
- Future narrow review of `verlyn13 NOPASSWD: ALL` once a non-NOPASSWD admin
  path is designed (current remote apply pattern depends on `sudo -n`).
- Account-lifecycle decision for `mesh-ops` (lock, delete, or leave as
  standard-only) now that privileges are gone.
- Decision on whether to remove or repair Infisical and Tailscale DNF repo
  trust paths.
- Cloudflare package repo setup and WARP/cloudflared installation.
- Firewall changes after an alternate admin path is proven.
- 1Password recovery/admin credential item creation or update.
- Repository signing-key decisions for Infisical and Tailscale package sources.

### Requires Explicit Approval

- Creating or editing any 1Password item containing a password, private key, or
  recovery key.
- Changing local users, groups, or sudoers.
- Reloading or changing SSH configuration.
- Disabling password SSH.
- Opening or changing firewall rules.
- Creating static DHCP or DNS records.
- Enrolling in Tailscale, WARP, or any management agent.
- Changing Cloudflare tunnel, private route, Access, Gateway, or device profile
  state.
- Changing Docker compose/port bindings for Infisical or Redis, including
  retiring laptop-hosted Infisical.
- Changing power/sleep/LUKS/TPM/AMT behavior.
