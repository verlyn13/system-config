---
title: Fedora Top Infisical/Redis Retirement Apply - 2026-05-13
category: operations
component: device_admin
status: applied
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, docker, infisical, redis, retirement, evidence]
priority: high
---

# Fedora Top Infisical/Redis Retirement Apply - 2026-05-13

This record captures the live apply of the Infisical/Redis retirement
packet recorded in
[fedora-top-infisical-redis-retirement-packet-2026-05-13.md](./fedora-top-infisical-redis-retirement-packet-2026-05-13.md).

Scope was the prepared packet plus the optional S4 image-removal step,
exactly per the guardian approval phrase. No SSH daemon, `firewalld`,
sudoers/users/groups, Docker engine itself, Tailscale, WARP, `cloudflared`,
Cloudflare, OPNsense, DNS, DHCP, LUKS, TPM, Secure Boot, firmware, power,
reboot, or 1Password state was touched. Volume destruction in S2 was
intentional and is not recoverable, per the operator's prior confirmation
that `happy-secrets` is a retired project that may be removed completely.

## Approval

Guardian/operator approval matches the directive template recorded in the
packet, with S4 (project-image removal) explicitly approved.

## Apply Sequence (Actual)

1. Drift re-verification at `2026-05-13T21:48:30Z`: confirmed three running
   project containers, both named volumes, the project network, listeners
   on `0.0.0.0:18080` and `0.0.0.0:6379` (plus their IPv6 counterparts),
   all three project images present with the same sha256 IDs as the
   prepared inspection, and
   `/etc/yum.repos.d/infisical-infisical-cli.repo` with sha256
   `7ad68a81d9eaa60741f0a6a15939413bffe1168a3f08e992979f2a40f513e126`.
   `python3 --version` confirmed `Python 3.14.4` available at
   `/usr/sbin/python3` for the snapshot's redaction step.
2. Held-open control SSH session opened in background using
   `HostKeyAlias=192.168.0.206`, `ServerAliveInterval=30`,
   `ControlMaster=no`, with `sleep 3600` payload. Confirmed alive before
   any state change.
3. S1 - forensic snapshot written to
   `/var/backups/jefahnierocks-infisical-redis-retirement-20260513T214856Z`
   with `docker-compose-ps.txt`, `containers.json` (env redacted for
   keys matching `KEY|SECRET|PASSWORD|TOKEN|JWT|AUTH|CONNECTION_URI`),
   `volumes.json`, `network.json`, `images.txt`, `ports-before.txt`,
   `repo-files/infisical-infisical-cli.repo`, and `manifest.sha256`.
   A grep for the known Postgres DB password string confirmed the
   snapshot does not contain its value.
4. S2 - `sudo -n docker compose -p happy-secrets down --volumes
   --remove-orphans`. The compose CLI worked against the project label
   even though the original compose file no longer exists at
   `/home/verlyn13/Projects/happy-secrets/docker-compose.yml`. Reported
   sequence: three containers stopped + removed, two volumes removed,
   project network removed.
5. S3 - verified no remnants. All three label filters returned empty;
   all six by-name inspections returned absent (three containers, two
   volumes, one network); both volume mountpoint directories under
   `/var/lib/docker/volumes/` are gone; no listener remains on `18080`,
   `6379`, or `5432`.
6. S4 - `sudo -n docker image rm
   infisical/infisical:latest-postgres postgres:14-alpine redis:7`. All
   three top-level images and 33 intermediate layer sha256s were
   reported deleted; post-remove inspection confirms each image is
   absent.
7. S5 - `sudo -n rm -v /etc/yum.repos.d/infisical-infisical-cli.repo`.
8. S6 - `sudo -n dnf clean metadata` reported "Removed 226 files, 82
   directories (total of 221 MiB). 0 errors occurred."
9. S7 - `sudo -n dnf repolist --enabled | grep -iE 'infisical'`
   returned no rows; on-disk listing of `/etc/yum.repos.d/infisical-*`
   confirmed no remaining file; the Tailscale stable repo and unrelated
   repos remain enabled exactly as before.
10. Comprehensive post-apply validation from a fresh SSH process: all
    twelve target post-state checks passed (see Evidence).
11. Held-open control session closed via `SIGTERM`.

No deviation from packet. R10-style follow-ups (`restorecon -F`) were not
needed here because the apply did not touch any SELinux-managed file
other than to delete it.

## Evidence

### Timestamps And Identity

```text
drift_check_utc:           2026-05-13T21:48:30Z
snapshot_created_utc:      2026-05-13T21:48:56Z
post_apply_validation_utc: 2026-05-13T21:50:17Z
hostname:                  fedora-top
operator:                  verlyn13 (human-supervised agent session in system-config)
ssh_path:                  fedora-top.home.arpa via HostKeyAlias=192.168.0.206
```

### Snapshot

```text
snapshot_path: /var/backups/jefahnierocks-infisical-redis-retirement-20260513T214856Z
permissions:   0700 root:root
contents:
  docker-compose-ps.txt      (656 B)
  containers.json            (33,473 B, env values for KEY/SECRET/PASSWORD/
                              TOKEN/JWT/AUTH/CONNECTION_URI redacted to
                              <redacted>)
  volumes.json               (914 B)
  network.json               (2,371 B)
  images.txt                 (121 B; three image lines)
  ports-before.txt           (695 B; ss output for 18080/6379/5432 at apply
                              time)
  repo-files/infisical-infisical-cli.repo
                             (1,390 B, mode 0400; copy of the deleted DNF
                              repo file for audit and possible future
                              restore)
  manifest.sha256
secret-leak scan:            grep for the prior known Postgres DB password
                             text against containers.json returned no
                             match. The seven secret-shaped env keys
                             redacted in containers.json per container:
                             /infisical-app:
                               AUTH_SECRET, DB_CONNECTION_URI,
                               ENCRYPTION_KEY, POSTGRES_PASSWORD,
                               INFISICAL_TOKEN, POSTHOG_API_KEY,
                               CAPTCHA_SITE_KEY
                             /infisical-redis:
                               ALLOW_EMPTY_PASSWORD, POSTGRES_PASSWORD,
                               INFISICAL_TOKEN, ENCRYPTION_KEY,
                               AUTH_SECRET
                             /infisical-postgres:
                               ENCRYPTION_KEY, AUTH_SECRET,
                               POSTGRES_PASSWORD, INFISICAL_TOKEN
```

### S2 - `docker compose down --volumes --remove-orphans`

```text
Container infisical-app Stopping -> Stopped -> Removing -> Removed
Container infisical-redis Stopping -> Stopped -> Removing -> Removed
Container infisical-postgres Stopping -> Stopped -> Removing -> Removed
Volume happy-secrets_redis_data Removing -> Removed
Volume happy-secrets_pg_data Removing -> Removed
Network happy-secrets_infisical Removing -> Removed
```

### S3 - Remnant Verification

```text
docker ps -a --filter label=happy-secrets:       (empty)
docker volume ls --filter label=happy-secrets:   (empty)
docker network ls --filter label=happy-secrets:  (empty)

docker inspect infisical-app:        absent
docker inspect infisical-redis:      absent
docker inspect infisical-postgres:   absent
docker volume inspect happy-secrets_pg_data:     absent
docker volume inspect happy-secrets_redis_data:  absent
docker network inspect happy-secrets_infisical:  absent

ss listeners on 18080, 6379, 5432:   (none)

mountpoint dirs:
  /var/lib/docker/volumes/happy-secrets_pg_data       absent
  /var/lib/docker/volumes/happy-secrets_redis_data    absent
```

### S4 - Image Removal

```text
Removed images:
  infisical/infisical:latest-postgres   sha256:dea342eb3e0d... (~1,558,580,619 B)
  postgres:14-alpine                    sha256:071bc6204b70... (~271,637,585 B)
  redis:7                               sha256:0fdc3e401cf3... (~124,466,807 B)

Layer untags / deletes reported:
  3 image manifests untagged
  33 layer sha256 IDs deleted

Post-remove inspect:
  infisical/infisical:latest-postgres   absent
  postgres:14-alpine                    absent
  redis:7                               absent

Approximate space recovered:           ~1.95 GB
```

### S5/S6/S7 - DNF

```text
S5 result:    removed '/etc/yum.repos.d/infisical-infisical-cli.repo'
S6 result:    "Removed 226 files, 82 directories (total of 221 MiB). 0 errors occurred."
S7 result:    dnf repolist --enabled | grep -i infisical  -> no rows
              ls /etc/yum.repos.d/infisical-*             -> no file
              tailscale-stable                            -> still enabled (out of scope)

Remaining enabled repos (sanity, all unrelated):
  code, copr:emixampp/synology-drive, copr:mczernek/vale,
  copr:phracek/PyCharm, fedora, fedora-cisco-openh264, gh-cli,
  google-chrome, rpmfusion-free, rpmfusion-free-updates,
  rpmfusion-nonfree, rpmfusion-nonfree-nvidia-driver,
  rpmfusion-nonfree-steam, rpmfusion-nonfree-updates,
  tailscale-stable, updates
```

### Boundary Sanity (must be unchanged)

```text
docker engine:        active, version 29.4.2, containers=12 (all
                      pre-existing exited containers), running=0
                      (no running containers - intended; only the
                      happy-secrets project was running before apply)
sshd allowusers:      verlyn13
visudo -c:            /etc/sudoers parsed OK; ansible-automation parsed OK
sudoers.d listing:    ansible-automation only (privilege cleanup state)
firewalld state:      running
firewalld services:   dhcpv6-client, mdns, samba-client, ssh
                      (FedoraWorkstation zone; unchanged from pre-apply)
snapshot directory:   /var/backups/jefahnierocks-infisical-redis-retirement-20260513T214856Z
                      still present, 0700 root:root, 7 files + 1 subdir
```

### Rollback

```text
rollback_used: no
rollback_state: not applicable - volume destruction in S2 is intentional
                and irreversible per the approved phrase. The snapshot
                directory retains the metadata (non-secret) for forensic
                audit only. The retired Infisical DNF repo file is
                copied into the snapshot at repo-files/ if the operator
                ever needs to reconstruct the upstream repo definition.
```

## Boundary Assertions

The following surfaces were intentionally not touched and remain in their
pre-apply state:

- SSH daemon, drop-ins, `authorized_keys`, host keys (still hardened per
  the 2026-05-13 SSH apply record)
- `firewalld` zones, services, rules (`FedoraWorkstation` zone unchanged;
  broad port allowances now have no Infisical/Redis listeners behind them
  but the zone definition itself is untouched and remains a separate
  cleanup target)
- sudoers, users, groups, Docker group membership (still per the
  2026-05-13 privilege cleanup apply record)
- Docker engine, daemon config, daemon socket permissions; other Docker
  projects (`api`, `maat-framework`, `scanner`) remain in their prior
  exited state and were not touched
- Tailscale stable DNF repo and `tailscaled` (separate decision)
- WARP, `cloudflared`, Cloudflare DNS, Tunnel, Access, Gateway
- OPNsense, ISC DHCP scopes, Unbound host overrides, NAT, HAProxy, WoL
- LUKS, TPM, Secure Boot, firmware, sleep/power, reboot behavior
- 1Password items, vaults, fields

## Remaining Blockers

The host remains not fully managed. Follow-on packets pending:

- `firewalld` narrowing: with Infisical and Redis listeners gone, the
  `FedoraWorkstation` zone's broad `1025-65535/tcp` and `1025-65535/udp`
  allowances and broad service set (`mdns`, `samba-client`, etc.) can be
  narrowed in a separate packet. SSH should remain reachable on `22/tcp`.
- Tailscale retain/remove decision (currently installed, logged out, repo
  enabled). WARP and `cloudflared` design packet for off-LAN access.
- Fedora repo trust path: Tailscale repo signing-key failure remains; if
  Tailscale stays, repair its signing key path; if it goes, remove the
  repo file too.
- LUKS/remote-reboot strategy and AC/no-sleep policy.
- 1Password device-admin and recovery items for `fedora-top`.
- Future narrow review of `verlyn13 NOPASSWD: ALL`.
- Account-lifecycle decision for `mesh-ops` (lock, delete, or leave as
  standard-only).
- General Docker hygiene packet: there remain 11 exited containers
  (`maat_postgres`, `api-db-1`, `vault-staging`, `maat_timescale`,
  `scanner-scc-1`, several `act-*` runs, `agitated_pike`, `cool_williams`)
  and ~25 GB of reclaimable image storage, ~3.3 GB of reclaimable build
  cache, and ~4.25 GB of reclaimable named-volume storage from other
  projects. Cleaning those is out of scope for this packet.
- MacBook `known_hosts` reconciliation for `fedora-top.home.arpa` so the
  `HostKeyAlias=192.168.0.206` workaround is no longer needed.

## Security Note On The Postgres DB Password

While the project was running, the Postgres password was visible to any
process with `docker engine` access via `docker inspect`. After this
apply the containers and their env are gone, so the password is no
longer recoverable from this host. If the same password was reused
anywhere else (Hetzner Infisical instance, another stack, password
manager entry), treat the prior exposure window as a known fact and
decide whether rotation elsewhere is warranted; this packet does not
itself rotate any external credential.

## Related

- [fedora-top-infisical-redis-retirement-packet-2026-05-13.md](./fedora-top-infisical-redis-retirement-packet-2026-05-13.md)
- [fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md)
- [fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [../secrets.md](../secrets.md)
