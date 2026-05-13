---
title: Fedora Top Infisical/Redis Retirement Packet - 2026-05-13
category: operations
component: device_admin
status: applied
version: 0.2.0
last_updated: 2026-05-13
tags: [device-admin, fedora, docker, infisical, redis, retirement]
priority: high
---

# Fedora Top Infisical/Redis Retirement Packet - 2026-05-13

This packet defines the complete retirement of the laptop-hosted
`happy-secrets` Docker compose project from `fedora-top`. It was applied
live on 2026-05-13 (including the optional image-removal step S4); redacted
apply evidence is recorded in
[fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md).

The operator confirmed `happy-secrets` is a retired project and can be
removed completely; Infisical authority for current needs lives on the
Hetzner server only. No data export from this laptop instance was required.

The original text below is preserved for reuse and audit. No deviation from
the packet was needed at apply time.

## Scope

In scope:

- Stop and remove the three running containers:
  `infisical-app`, `infisical-redis`, `infisical-postgres`.
- Remove the two compose volumes:
  `happy-secrets_pg_data`, `happy-secrets_redis_data`.
- Remove the compose network:
  `happy-secrets_infisical`.
- Remove the three Cloudsmith DNF repo entries for Infisical CLI in
  `/etc/yum.repos.d/infisical-infisical-cli.repo` and clear DNF metadata
  cache.
- Optionally remove the three project-only Docker images
  (`infisical/infisical:latest-postgres`, `postgres:14-alpine`, `redis:7`)
  to reclaim ~1.95 GB. Guardian may choose to retain.
- Write a forensic-only snapshot of pre-destruction state (`docker inspect`
  metadata, port bindings, env keys, volume mountpoints) to
  `/var/backups/jefahnierocks-infisical-redis-retirement-<ts>` for audit.
  This snapshot is metadata only; no secret values are captured.

Out of scope (intentionally not touched, requires separate packets):

- `firewalld` zones, services, rules (laptop-side cleanup is sufficient;
  no firewall change is required because the listeners disappear with the
  containers).
- `tailscale-stable` DNF repo. Tailscale retain/remove is a separate
  decision.
- SSH, sudoers, group memberships (already hardened/cleaned).
- Docker engine itself, daemon config, other unrelated stopped containers
  (`maat_postgres`, `api-db-1`, `vault-staging`, `maat_timescale`,
  `scanner-scc-1`, the `act-*` images, etc.). The packet only touches the
  `happy-secrets` project. A separate Docker hygiene packet may be
  prepared later to clean those exited containers and the orphaned
  scratch images.
- Cloudflare, WARP, `cloudflared`, OPNsense, DNS, DHCP, LUKS, power,
  reboot, 1Password.

## Verified Current Live State

Observed via SSH from the MacBook on `2026-05-13T21:38:18Z` using
`HostKeyAlias=192.168.0.206`. Read-only; no state changed.

### Docker engine

```text
docker engine:    29.4.2 (active, enabled)
docker compose:   v2.5.1.2
```

### Running containers (happy-secrets project)

```text
container=infisical-app
  image=infisical/infisical:latest-postgres
  compose_project=happy-secrets
  compose_service=backend
  state=running, restartcount=0, restart_policy=unless-stopped
  ports=8080/tcp -> 0.0.0.0:18080 and [::]:18080
  mounts=(none)
  env summary: NODE_ENV=production, INFISICAL_PLATFORM_VERSION=v0.124.0-postgres,
               PORT=8080, HOST=0.0.0.0, HTTPS_ENABLED=false,
               STANDALONE_BUILD=true, STANDALONE_MODE=true,
               TELEMETRY_ENABLED=true, SITE_URL=http://localhost:18080,
               POSTGRES_USER=infisical_user, POSTGRES_DB=infisical_db,
               REDIS_URL=redis://redis:6379,
               DB_CONNECTION_URI=postgres://infisical_user:<redacted>@db:5432/infisical_db
  (encryption keys, JWT/auth secrets, and the DB password are not recorded
   in this repo. The DB password is visible to anyone with docker engine
   access on this host until the container is removed.)

container=infisical-redis
  image=redis:7
  compose_project=happy-secrets
  compose_service=redis
  state=running, restartcount=0, restart_policy=always
  ports=6379/tcp -> 0.0.0.0:6379 and [::]:6379
  mounts=volume happy-secrets_redis_data -> /data (rw)

container=infisical-postgres
  image=postgres:14-alpine
  compose_project=happy-secrets
  compose_service=db
  state=running, restartcount=0, restart_policy=always, healthcheck=healthy
  ports=5432/tcp (container-internal; no host publish)
  mounts=volume happy-secrets_pg_data -> /var/lib/postgresql/data (rw)
```

### Volumes (happy-secrets project)

```text
happy-secrets_pg_data     local   /var/lib/docker/volumes/happy-secrets_pg_data/_data        size ~74M
happy-secrets_redis_data  local   /var/lib/docker/volumes/happy-secrets_redis_data/_data     size ~353K
```

### Network

```text
happy-secrets_infisical   bridge   local
```

### Listeners (host)

```text
0.0.0.0:6379   docker-proxy
[::]:6379      docker-proxy
0.0.0.0:18080  docker-proxy
[::]:18080     docker-proxy
```

`infisical-postgres` exposes `5432/tcp` only inside the compose network;
not bound to host.

### Compose working directory state

```text
/home/verlyn13/Projects/happy-secrets   ABSENT on disk
```

The compose label still records the original working directory and
config-file path, but neither the directory nor the `docker-compose.yml`
exists at apply time. `docker compose -p happy-secrets <cmd>` still works
because compose tracks the project via container labels. No compose file
needs to be created or restored for this retirement.

### Project-only images

```text
infisical/infisical:latest-postgres  sha256:dea342eb3e0d... size 1,558,580,619 bytes
postgres:14-alpine                   sha256:071bc6204b70... size   271,637,585 bytes
redis:7                              sha256:0fdc3e401cf3... size   124,466,807 bytes
```

`docker ps -a --filter "ancestor=<image>"` confirms each of these three
images is referenced ONLY by the corresponding `happy-secrets` container.
No other containers (running or exited) use them. Safe to remove.

### DNF repos

```text
enabled repos (filtered):
  infisical-infisical-cli         (https://dl.cloudsmith.io/.../rpm/fedora/$releasever/$basearch)
  infisical-infisical-cli-noarch  (https://dl.cloudsmith.io/.../rpm/fedora/$releasever/noarch)
  infisical-infisical-cli-source  (https://dl.cloudsmith.io/.../rpm/fedora/$releasever/SRPMS)
  tailscale-stable                (out of scope - separate decision)

repo files on disk:
  /etc/yum.repos.d/infisical-infisical-cli.repo   (3 stanzas: all Infisical entries)
  /etc/yum.repos.d/tailscale.repo                 (out of scope)
```

The three Infisical entries live in one file; deleting that file retires
all three repos in one step. No installed RPM is known to require these
repos for runtime use - they were a CLI install path only.

### Systemd

```text
no /etc/systemd/system/*happy* or *infisical* unit files
no /usr/lib/systemd/system/*happy* or *infisical* unit files
docker.service          active, enabled
docker.socket           active
```

The compose project is not wired to any host systemd unit. Container
lifecycle is controlled entirely by Docker's restart policies. Once the
containers are removed, nothing on the host restarts them.

### Pre-existing backups

```text
/var/backups: no prior jefahnierocks-infisical-redis-retirement-* directories
```

## Proposed Retirement Sequence

| # | Change | Rationale |
|---|---|---|
| S1 | Forensic snapshot of pre-destruction metadata to `/var/backups/jefahnierocks-infisical-redis-retirement-<ts>` | Audit-only record; no secret values captured |
| S2 | `docker compose -p happy-secrets down --volumes --remove-orphans` | Stops and removes the three containers, the two named volumes, and the project network in one labelled operation; works without the compose file because compose tracks the project via container labels |
| S3 | Confirm no remnants via `docker ps -a`, `docker volume ls`, `docker network ls` filtered by project label | Verification only |
| S4 | (Optional) `docker image rm infisical/infisical:latest-postgres postgres:14-alpine redis:7` | Reclaims ~1.95 GB; safe because no other container references these images |
| S5 | `rm /etc/yum.repos.d/infisical-infisical-cli.repo` | Removes the three Infisical CLI Cloudsmith repos in one delete |
| S6 | `dnf clean metadata` | Clears cached metadata so the next `dnf` invocation re-resolves the package universe without the removed repos |
| S7 | Confirm `dnf repolist --enabled` no longer lists `infisical-*` | Verification only |

The compose project's working directory (`/home/verlyn13/Projects/happy-
secrets`) is already gone and no compose file remains to remove. If the
operator wants a placeholder README explaining the retirement, that can be
added in a separate, optional doc-only step - it is not part of this
packet.

## Backup / Export Expectations

The operator confirmed `happy-secrets` is a retired project; no data
export from this laptop instance is required. The packet therefore does
NOT include `pg_dump`, `redis-cli save`/`BGSAVE`, or any other data
preservation step.

What S1 does capture (audit only, no secret values):

```text
/var/backups/jefahnierocks-infisical-redis-retirement-<ts>/
  docker-compose-ps.txt          (docker compose -p happy-secrets ps output)
  containers.json                (docker inspect <names> | jq with secrets stripped)
  volumes.json                   (docker volume inspect <names>)
  network.json                   (docker network inspect <name>)
  images.txt                     (docker image ls of the three images with sha256)
  ports-before.txt               (ss -tulpn for 18080, 6379, 5432)
  repo-files/
    infisical-infisical-cli.repo (copy for audit; non-secret)
  manifest.sha256
```

The Postgres DB password and Infisical encryption/auth keys are NOT copied
into this snapshot. The `containers.json` step strips
`Config.Env` entries whose key matches a secret pattern before writing.

## Apply Commands

Apply only after explicit guardian approval. Use the same SSH options
documented in the SSH hardening packet, including
`HostKeyAlias=192.168.0.206` until MacBook `known_hosts` is reconciled.

### Held-Open Control Session

Open before any change:

```bash
ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  -o ControlMaster=no \
  -o ControlPath=none \
  verlyn13@fedora-top.home.arpa
```

### S1 - Forensic snapshot

```bash
sudo -n bash <<'EOF'
set -euo pipefail
SNAP="/var/backups/jefahnierocks-infisical-redis-retirement-$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 0700 -o root -g root "$SNAP"
install -d -m 0700 -o root -g root "$SNAP/repo-files"

docker compose -p happy-secrets ps > "$SNAP/docker-compose-ps.txt" 2>&1

# Container inspect with Env stripped of secret-shaped keys.
docker inspect infisical-app infisical-redis infisical-postgres \
  | python3 -c '
import json, sys, re
SECRET = re.compile(r"(KEY|SECRET|PASSWORD|TOKEN|JWT|AUTH|CONNECTION_URI)", re.I)
data = json.load(sys.stdin)
for c in data:
    env = c.get("Config", {}).get("Env", []) or []
    c["Config"]["Env"] = [
        e if not SECRET.search(e.split("=",1)[0]) else e.split("=",1)[0] + "=<redacted>"
        for e in env
    ]
json.dump(data, sys.stdout, indent=2)
' > "$SNAP/containers.json"

docker volume  inspect happy-secrets_pg_data happy-secrets_redis_data > "$SNAP/volumes.json"
docker network inspect happy-secrets_infisical > "$SNAP/network.json"

docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}' \
  | grep -E '^(infisical/infisical:latest-postgres|postgres:14-alpine|redis:7) ' \
  > "$SNAP/images.txt"

ss -tulpn 2>/dev/null | awk 'NR==1 || /:18080 / || /:6379 / || /:5432 /' \
  > "$SNAP/ports-before.txt"

install -m 0400 -o root -g root /etc/yum.repos.d/infisical-infisical-cli.repo \
  "$SNAP/repo-files/infisical-infisical-cli.repo"

( cd "$SNAP" && sha256sum -- *.txt *.json repo-files/* > manifest.sha256 )

echo "snapshot_path=$SNAP"
ls -la "$SNAP"
EOF
```

Record the printed `snapshot_path=...` value.

### S2 - Compose down with volumes

```bash
sudo -n docker compose -p happy-secrets down --volumes --remove-orphans
```

Expected output (order may differ by a small amount):

```text
Container infisical-app Stopping ... Stopped ... Removing ... Removed
Container infisical-redis Stopping ... Stopped ... Removing ... Removed
Container infisical-postgres Stopping ... Stopped ... Removing ... Removed
Volume happy-secrets_redis_data Removing ... Removed
Volume happy-secrets_pg_data Removing ... Removed
Network happy-secrets_infisical Removing ... Removed
```

### S3 - Verify no remnants

```bash
sudo -n bash <<'EOF'
set -u
echo "--- containers labelled happy-secrets ---"
docker ps -a --filter "label=com.docker.compose.project=happy-secrets" --format '{{.Names}} {{.Status}}'
echo "--- volumes labelled happy-secrets ---"
docker volume ls --filter "label=com.docker.compose.project=happy-secrets" --format '{{.Name}}'
echo "--- networks labelled happy-secrets ---"
docker network ls --filter "label=com.docker.compose.project=happy-secrets" --format '{{.Name}}'
echo "--- by-name fallbacks ---"
for n in infisical-app infisical-redis infisical-postgres; do
  docker inspect "$n" >/dev/null 2>&1 && echo "STILL_PRESENT: $n" || echo "absent: $n"
done
for v in happy-secrets_pg_data happy-secrets_redis_data; do
  docker volume inspect "$v" >/dev/null 2>&1 && echo "STILL_PRESENT: $v" || echo "absent: $v"
done
docker network inspect happy-secrets_infisical >/dev/null 2>&1 \
  && echo "STILL_PRESENT: happy-secrets_infisical" \
  || echo "absent: happy-secrets_infisical"
echo "--- listeners ---"
ss -tulpn 2>/dev/null | awk '/:18080 / || /:6379 / || /:5432 /' || echo "no remaining listeners"
EOF
```

All three filtered listings must be empty and all by-name checks must
return `absent:` for S2 to be considered successful.

### S4 - Image removal (optional)

```bash
sudo -n docker image rm infisical/infisical:latest-postgres postgres:14-alpine redis:7
sudo -n docker image ls | grep -E 'infisical|postgres:14-alpine|redis:7$' || echo "all three removed"
```

If the guardian wants to retain any of these images for future projects,
omit that image from the command line. Removing the images does not
affect the retirement of the project containers/volumes - it is purely
disk-space recovery (~1.95 GB).

### S5 - Remove Infisical DNF repos

```bash
sudo -n rm -v /etc/yum.repos.d/infisical-infisical-cli.repo
```

### S6 - Clear DNF metadata cache

```bash
sudo -n dnf clean metadata
```

### S7 - Confirm DNF repo retirement

```bash
sudo -n dnf repolist --enabled | grep -iE 'infisical' \
  && echo "FAIL: infisical repos still listed" \
  || echo "ok: infisical repos retired"
```

Tailscale stable repo intentionally remains; it is not in scope.

## Validation

Validation is run from a fresh SSH process while the held-open session
remains open. All checks must pass before closing the held-open session.

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n bash -s' <<'EOF'
set -u
echo "===== TIMESTAMP ====="
date -u +%Y-%m-%dT%H:%M:%SZ

echo "===== docker resources (must be empty) ====="
docker ps -a --filter "label=com.docker.compose.project=happy-secrets" --format '{{.Names}}'
docker volume ls --filter "label=com.docker.compose.project=happy-secrets" --format '{{.Name}}'
docker network ls --filter "label=com.docker.compose.project=happy-secrets" --format '{{.Name}}'

echo "===== by-name absence (must all say absent) ====="
for n in infisical-app infisical-redis infisical-postgres; do
  docker inspect "$n" >/dev/null 2>&1 && echo "PRESENT: $n" || echo "absent: $n"
done
for v in happy-secrets_pg_data happy-secrets_redis_data; do
  docker volume inspect "$v" >/dev/null 2>&1 && echo "PRESENT: $v" || echo "absent: $v"
done
docker network inspect happy-secrets_infisical >/dev/null 2>&1 \
  && echo "PRESENT: happy-secrets_infisical" \
  || echo "absent: happy-secrets_infisical"

echo "===== listeners (must show none on 18080/6379/5432) ====="
ss -tulpn 2>/dev/null | awk 'NR==1 || /:18080 / || /:6379 / || /:5432 /' || true

echo "===== images (must show none if S4 ran) ====="
docker image ls | grep -E 'infisical/infisical|postgres:14-alpine|redis:7$' || echo "(no project images)"

echo "===== dnf repos (must not include infisical) ====="
dnf repolist --enabled | grep -iE 'infisical' || echo "(no infisical repos)"
ls /etc/yum.repos.d/infisical-* 2>/dev/null && echo "FAIL: repo file still present" || echo "ok: repo file removed"

echo "===== docker engine still healthy ====="
systemctl is-active docker
docker info --format '{{.ServerVersion}} containers={{.Containers}} running={{.ContainersRunning}}'

echo "===== ssh allowusers (sanity, must be unchanged) ====="
sshd -T 2>/dev/null | grep -E '^allowusers '

echo "===== END ====="
EOF
```

Expected post-apply:

```text
container filter:    (empty)
volume filter:       (empty)
network filter:      (empty)
by-name:             all absent
listeners on 18080/6379/5432:  none
images (if S4 ran):  none
dnf repolist:        no infisical
repo file:           removed
docker engine:       active
sshd allowusers:     verlyn13   (unchanged - SSH not touched)
```

## Rollback

This packet is fundamentally different from the SSH hardening and
privilege cleanup packets: **volume removal in S2 is unrecoverable.**
After volumes are gone, the encrypted Postgres data and Redis state cease
to exist on this host.

The acceptable rollback windows are:

- **Before S2**: nothing has been changed yet (S1 only created an audit
  directory). Simply do not run S2 onward and remove the audit dir if
  desired.
- **Between S2 and S4/S5**: containers and volumes are gone. The project
  state cannot be recovered from this host. Containers can be re-created
  later if the compose file and `.env` are restored from another source
  (Hetzner backup, prior workstation copy), but the in-volume data does
  not return.
- **After S4**: image removal is recoverable by `docker pull` from a
  registry as long as network access is available. Tag pins
  (`postgres:14-alpine`, `redis:7`, `infisical/infisical:latest-postgres`)
  are stable enough to re-resolve.
- **After S5/S6**: DNF repo removal is recoverable - the repo file can
  be restored from the audit snapshot or re-fetched from the Infisical
  documentation. No system state depends on these repos being present.

Specifically: there is **no rollback for the Infisical encrypted data or
the Redis state**. The operator confirmed this is intentional ("retired
project, removed completely"). The packet does not pretend otherwise.

If the operator changes intent partway through and wants to preserve
state, the only recovery is to skip S2 entirely on this run and restart
the planning.

## DNF Repos After Retirement

The packet **does** disable/remove the three Infisical Cloudsmith repo
entries (`infisical-infisical-cli`, `infisical-infisical-cli-noarch`,
`infisical-infisical-cli-source`) by deleting their single repo file at
`/etc/yum.repos.d/infisical-infisical-cli.repo`, then running
`dnf clean metadata` so the next `dnf` operation re-resolves the package
universe without them.

Rationale:

- The retired project is gone, so the laptop has no continued use for
  the Infisical CLI.
- The 2026-05-13 pre-hardening report noted DNF GPG signing-key failures
  on these three repos; removing them eliminates the recurring failure
  prompt during `dnf check-update`.
- Re-adding the repos later is a single-file restore from the audit
  snapshot, or a re-install from upstream Infisical documentation.

The `tailscale-stable` repo is **not** touched by this packet. The
Tailscale retain/remove decision is a separate packet.

## Risks

- **Data destruction is intentional and unrecoverable**: volume removal
  in S2 cannot be undone. The operator has confirmed this is the desired
  outcome.
- **Postgres DB password is currently visible in container env**: any
  process with `docker inspect` permission on this host can read the
  Infisical Postgres password (and a smaller set of process-environment
  inspection tools can see it on the running container's `/proc`).
  Treat the password as compromised for any external context until the
  containers are gone in S2. If the same password was reused on the
  Hetzner-hosted Infisical or anywhere else, rotate it there separately;
  do not assume it stays secret.
- **Any current consumer of the laptop-hosted Infisical will break**: if
  any script, dev shell, or CI runner on this host (or pointed at this
  host) currently reads from `http://localhost:18080`, it will start
  failing after S2. The operator decision states Infisical authority is
  Hetzner-only, so this is the intended cutover; consumers should already
  point at Hetzner.
- **Docker engine remains broadly enabled and accessible**: the laptop
  Docker socket continues to grant root-equivalent capability to anyone
  in the `docker` group. After the recent privilege cleanup that group is
  `verlyn13` only; the surface area is acceptable but is not zero. A
  later packet may consider whether Docker should remain on this device
  at all.
- **Image removal is optional**: if the guardian later runs a project
  that needs `postgres:14-alpine` or `redis:7`, those images will need to
  be re-pulled. Network must be available at that future time.
- **The Cloudsmith metadata-expire windows are short** (`300`): removing
  the Infisical repos has no immediate side effect on background DNF
  caches.
- **No firewall change is needed**: closing the listeners is achieved by
  removing the containers, not by editing `firewalld`. The
  `FedoraWorkstation` zone's broad port allowances become moot for these
  ports because nothing is bound; a separate `firewalld` narrowing packet
  remains worthwhile but is out of scope here.
- **Other Docker projects remain unaffected**: `api`, `maat-framework`,
  and `scanner` compose projects are all in `exited` state; they are not
  touched. The many `act-*` scratch containers are likewise untouched.

## Required Approval Phrase

Live apply requires guardian approval substantially equivalent to:

```text
I approve applying the Fedora Infisical/Redis retirement packet live now:
snapshot the pre-destruction metadata (redacted) to
/var/backups/jefahnierocks-infisical-redis-retirement-<timestamp>; run
docker compose -p happy-secrets down --volumes --remove-orphans to stop
and remove the three containers and the two named volumes and the
project network; verify no remnants by label and by name and verify no
listeners remain on 18080/6379/5432; optionally remove the three
project-only images infisical/infisical:latest-postgres,
postgres:14-alpine, and redis:7; remove
/etc/yum.repos.d/infisical-infisical-cli.repo; run dnf clean metadata;
verify no infisical repos are listed. Do not touch SSH, firewalld,
sudoers, users, groups, the Docker engine itself, Tailscale, WARP,
cloudflared, Cloudflare, OPNsense, DNS, DHCP, LUKS, power, reboot, or
1Password. Accept that data destruction in S2 is intentional and not
recoverable.
```

Adjust the phrase to explicitly opt out of S4 (image removal) if the
guardian wants to retain `postgres:14-alpine` or `redis:7` for future
work.

## Evidence To Record After Apply

```text
timestamp:
operator:
held-open session used:
snapshot path:
docker compose down result:
container removal result (by name):
volume removal result (by name):
network removal result (by name):
listener absence result:
image removal performed: yes/no   (which images removed)
dnf repo removal result:
dnf clean metadata result:
dnf repolist post-apply:
rollback used: yes/no
remaining blockers:
```

Do not copy private keys, passwords, the Postgres DB password, Infisical
encryption/auth secrets, recovery keys, or raw audit logs containing
secrets into the repo.

## Related

- [fedora-top-system-config-agent-directive-2026-05-13.md](./fedora-top-system-config-agent-directive-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md)
- [fedora-top-prehardening-ingest-2026-05-13.md](./fedora-top-prehardening-ingest-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [../secrets.md](../secrets.md)
