---
title: Security Hardening Implementation Plan
category: implementation
component: security_posture
status: active
version: 0.3.1
last_updated: 2026-05-02
tags: [security, hardening, 1password, ssh, mcp, containers, macos, audit]
priority: critical
---

# Security Hardening Implementation Plan

Formal work plan for the 2026-05-02 UA office wired-connection security audit
and the follow-up hardening work. This document is implementation-facing: it
records what was observed, who owns each surface, what to change, how to prove
the change worked, and what to roll back if it does not.

Private raw evidence lives outside the repo:

```text
~/Library/Logs/security-audit/2026-05-02-ua-wired/
```

Use `evidence-manifest.tsv` in that directory as the artifact index. Do not
copy raw secret material, shell-history matches, or private key contents into
this repo. This plan should cite artifact filenames and command shapes, not
confidential values.

## Current Read

The audit did not establish key compromise. The SSH key finding is a
blast-radius and lifecycle issue, not proof that the keys are unsafe today.
FileVault, local permissions, and the existing 1Password migration reduce the
immediate risk. The correct posture is to migrate and rotate keys deliberately
over time, starting with infrastructure keys and any identities that still have
wide production reach.

The highest live exposure is network-facing developer services published by
OrbStack/Docker on a public campus interface. macOS Application Firewall does
not intercept these because OrbStack's port forwarder runs through a privileged
helper outside the application-firewall scope. That work should precede
longer-lived credential cleanup.

## Findings Summary

Concrete numbers extracted from the audit artifact directory. Filenames refer
to entries under `~/Library/Logs/security-audit/2026-05-02-ua-wired/`.

### Network exposure (`tcp-listeners.txt`, `self-public-ip-portcheck.txt`)

- 15 TCP ports answer on the campus public IP `137.229.236.154`.
- 13 of those are container-published from OrbStack (`flux-*`, `authentik-*`,
  `budget-triage-db-local`).
- 2 are non-container app listeners: `Resolve` on `49152` and `rapportd` on
  `60979`.
- All container publishes appear as both `0.0.0.0:port` and `[::]:port`
  (IPv4 and IPv6 each get an explicit listener).
- macOS sharing services (SSH, SMB, AFP, VNC, AirPlay) all time out — the
  Sharing-disabled posture is working for system services.

### SSH inventory (`ssh-key-inventory.tsv`)

- 26 private keys in `~/.ssh/` and subdirectories.
- 21 of 26 open with empty passphrase. The 5 passphrase-protected keys are
  `synology_nas_key`, `traefik_key`, `libreweb_key`, `container_key`, and
  `google_compute_engine` (four ED25519 plus one RSA-3072).
- 5 entries already declared in `home/.chezmoidata.yaml` `ssh.host_migrations`,
  but several reference `.1password.pub` paths that do not yet exist on disk
  (the chezmoi template correctly falls back to the local private key in that
  case).
- Static manifest in `scripts/import-ssh-keys.zsh` and
  `scripts/write-1p-ssh-import-manifest.zsh` now covers all 26 keys (expanded
  from 12 in v0.3.1). Includes `id_ed25519_hetzner_root`,
  `id_ed25519_business_org`, and `id_ed25519_business-org` (note
  dash/underscore divergence — likely two distinct identities historically),
  the five passphrase-protected keys, and the four Synology / cross-machine
  identities the original 12-entry manifest omitted.
- `opnsense_usermgmt.from-1password` is present, suggesting a partial 1P
  import attempt that was not completed.

### LaunchAgents (`launch-plists.tsv`, `launchctl-custom-details.txt`)

- 6 broken or stale custom user-level agents:
  - `com.mcp.docs`, `com.mcp.models`, `com.mcp.control`,
    `com.mcp.daily-refresh` — all exit `EX_CONFIG` (78);
    point to `~/workspace/mcp-control-plane/` (Doppler-era tree).
  - `com.happy-devkit.mcp-server` — exit `EX_CONFIG` after 3,027 restart
    attempts; path under `~/Development/business-org/happy-devkit/`.
  - `com.jefahnierocks.host-capability-substrate.measure` — exit `127`,
    hard-codes `mise installs/just/1.46.0` path that breaks on `just` upgrade.
- 2 with invalid plist XML (`com.workspace.budgeteer.{api,ingest}`) — raw
  `&&` not entity-escaped (`&amp;&amp;`).
- 4 healthy custom agents: `homebrew.mxcl.redis`, `homebrew.mxcl.ollama`,
  `com.jefahnierocks.mcp-usage-collector`, `com.maat.processmonitor`.

### Shell history (`history-sensitive-counts-v2.txt`,
`shell-history-settings.txt`)

- `~/.zsh_history` (legacy, pre-XDG): 187 sensitive-pattern matches.
- `~/.local/state/zsh/history` (XDG, current): 306 matches.
- `~/.local/share/fish/fish_history` (unsupported per shell policy): 139
  matches.
- `~/.bash_history`: 0.
- zsh recurrence prevention is in place: `HIST_IGNORE_SPACE`, `EXTENDED_HISTORY`,
  `HIST_IGNORE_DUPS`, `SHARE_HISTORY` all set in
  `home/dot_config/zshrc.d/20-interactive.zsh`.

### MCP exposure (`mcp-config-server-names.txt`,
`mcp-config-sensitive-token-counts.txt`, `claude-json-secret-literal-counts.txt`)

- 6 AI tools all carry the same baseline (Copilot CLI omits `github` because
  it has a built-in).
- 0 secret literals (`op://`, `github_pat_*`, `ghp_`, `sk-`) across any synced
  config. The wrapper-based externalization is doing its job.
- The 713 "sensitive keypath" hits in `~/.claude.json` are env var *names*
  (`GITHUB_TOKEN`, etc.) inside MCP server `env` blocks, not values.

### WARP / Zero Trust (`warp-state.txt`)

- Connected, `Always On: true`, `Switch Locked: false` (user can disconnect).
- Tunnel: WireGuard via `162.159.193.7`. (MASQUE became the default for new
  device profiles on 2025-09-30; this profile remains pinned to WireGuard.)
- Mode: `WarpWithDnsOverHttps` — the documented default; supports DNS,
  network, HTTP, and posture filtering.
- Org: `homezerotrust`, profile id `2257cffa-50dc-4f5f-9fdc-083035e927c9`.
- `cdn-cgi/trace`: `warp=plus` (Zero Trust enrolled), `gateway=off` (Gateway
  HTTP proxy not inspecting this device's traffic). Most likely cause: the
  org-level Secure Web Gateway proxy toggle (TCP) is not enabled in Traffic
  Settings.
- Adult-profile contract values per
  `~/Repos/local/cloudflare-dns/infrastructure/pulumi/policy-inputs.yaml`:
  `serviceModeV2.mode = "warp"`, `tunnelProtocol = "wireguard"`,
  `switchLocked = false`, `allowedToLeave = true`. Profile id matches the
  observed `2257cffa-50dc-4f5f-9fdc-083035e927c9`.

### Agent memory (`agentic-memory-pii-counts.tsv`)

- `~/.codex/memories/MEMORY.md`: 64 KB; 5 IPv4, 1 MAC, 119 personal-term
  matches, 117 infra-term matches.
- `~/.codex/memories/memory_summary.md`: 18 KB; 1 IPv4, 1 MAC, 44 personal,
  48 infra.
- `~/.claude/CLAUDE.md`: 6.9 KB; 0 IPs/MACs, 2 personal — clean.
- `~/.claude/projects/-Users-verlyn13/memory/MEMORY.md`: 823 bytes; 10
  personal terms. Note this is the global-scope Claude memory, distinct from
  the project-scoped memory at
  `~/.claude/projects/-Users-verlyn13-Organizations-jefahnierocks-system-config/memory/`.

### macOS posture (`firewall-baseline.txt`,
`macos-security-controls.txt`, `bpf-wireshark.txt`,
`sharing-sharepoints.txt`)

- Application Firewall enabled, stealth mode on, block-all off, FileVault on,
  SIP enabled, Gatekeeper assessments enabled.
- ChmodBPF LaunchDaemon loaded; user `verlyn13` is in the `access_bpf` group;
  256+ `/dev/bpfNN` devices are readable by anything running as the user
  (live packet capture without root).
- One configured share point: `/Users/verlyn13/Public` shared via SMB with
  guest access enabled and read-write. SMB sharing service itself is off, so
  it is dormant — but if Sharing is ever enabled, guests get write access by
  default.

### Cloud credential file permissions (`cloud-credential-file-perms.tsv`)

- `~/.aws/credentials`, `~/.aws/config`, `~/.config/gh/hosts.yml`,
  `~/.config/mcp/common.env` are all `600`.
- `~/.docker/config.json` is `644` (typically only contains a `credsStore`
  reference; no secret material expected).

## Ownership Model

Keep the same source-of-truth split used by the rest of `system-config`.

| Scope | Owner | Examples | Rules |
|---|---|---|---|
| System-level host posture | Human/operator plus macOS and installed apps; documented here when durable | Firewall, Sharing, WARP, OrbStack, Wireshark ChmodBPF, LaunchDaemons | Verify live state before changing. Avoid persisting secrets. Prefer reversible changes with artifact-backed before/after evidence. |
| User-level managed config | `system-config` | `home/`, `home/dot_config/1Password/ssh/agent.toml.tmpl`, `home/dot_ssh/`, `home/dot_local/bin/`, `scripts/sync-mcp.sh`, user-level MCP baseline | Store structure and `op://` references only. Never store resolved secret values. Run `chezmoi apply --dry-run` before apply. |
| User-level secret store | 1Password account `my.1password.com`, vault `Dev` | SSH Key items, `github-mcp`, `github-dev-tools`, MCP API keys | Item and field names are stable contracts once referenced. Agents may verify and read when needed; creating/reorganizing items remains human-directed. The `op` CLI cannot import or edit existing SSH Key items — that is a desktop-app workflow. |
| Project-level config | Each project repo | `.mise.toml`, `.envrc`, `.env.1p`, `.mcp.json`, compose files, project docs | Project-specific runtime, env, and service exposure belong in the project. Do not solve project-local service exposure by broadening global host config. |
| Machine/service identities | Owning infra repo or platform | deploy keys, GitHub Apps, OIDC, workload identities, service tokens | Do not reuse the human workstation 1Password SSH agent as unattended automation identity. |

### Session-Scope Responsibility Map

This is the routing-layer view: which repository or surface a given track is
executable from. Agents should respect this map and not cross repository
boundaries during normal operation.

| Track | Where it executes | Notes |
|---|---|---|
| P0 evidence | Host (manual) | Already complete. This repo only references the artifact index. |
| P1 container rebinding | `~/ai/flux/`, `~/ai/flux-agent-b/`, `~/Development/personal/authentik/`, plus an ad hoc `budget-triage-db-local` container | One PR per project repo. Not editable from `system-config`. |
| P2 non-container listeners | Host (manual macOS settings, app preferences) | rapportd is Continuity / Handoff; Resolve port is panel/control. |
| P3 SSH migration | `system-config` (manifest, chezmoi templates) plus 1Password GUI plus remote authorized_keys | Three surfaces; coordinated. |
| P4 history scrub | Host (manual one-shot) plus `system-config` (operational rule in policy doc) | History files are user-global; documenting the rule belongs here. |
| P5 macOS Sharing/Firewall/TCC/BPF | Host (System Settings, `tccutil`, `socketfilterfw`, `launchctl`) | Decisions are personal; this doc records what to consider. |
| P6 LaunchAgents | Host (`launchctl unload`) plus the originating project repo for any source fix | Agents whose origin tree is gone get unloaded and the plist removed; agents whose origin still exists get fixed in that repo. |
| P7 MCP profiles | `system-config` (`scripts/sync-mcp.sh`, `scripts/mcp-servers.json`, `home/dot_local/bin/`) | Pure user-level baseline work. |
| P8 agent memory | `~/.codex/memories/`, `~/.claude/` (host) | Personal review. The codex memory is the heavy carrier. |
| P9 WARP / Gateway enforcement | `~/Repos/local/cloudflare-dns/` (Pulumi: 39 resources covering Gateway DNS policies, lists, device profiles, WARP enrollment Access app, Gateway DNS location); Cloudflare Zero Trust dashboard (org admin only) for the Secure Web Gateway proxy toggle and 2 legacy unmanaged policies | Two distinct external surfaces. system-config does not own either. cloudflare-dns/CLAUDE.md is authoritative for the Pulumi-side contracts. |
| P10 ng-doctor posture | `system-config` (`home/dot_local/bin/executable_ng-doctor.tmpl`) | Pure repo work; designed to land last. |

## 1Password Context

The current policy is 1Password-first. `docs/secrets.md` is authoritative for
secret handling, and `docs/ssh.md` is authoritative for SSH policy.

Live contracts:

- Account: `my.1password.com`
- Primary vault: `Dev`
- Readiness check: `op vault get Dev --account my.1password.com >/dev/null`
- Runtime resolution pattern: inherited env var, then `op read --account
  my.1password.com`, then fail.
- Project references use `op://` URIs; raw values must not appear in repo
  files.
- `~/.config/mcp/common.env` contains `op://` references only (verified by
  audit: no secret literals).
- The 1Password SSH agent is configured through
  `home/dot_config/1Password/ssh/agent.toml.tmpl`.
- `home/.chezmoidata.yaml` currently enables `ssh.use_1password_agent` and
  pins the SSH agent to the `Dev` vault.

Most repos on this machine are 1Password-first. The `cloudflare-dns`
project (`~/Repos/local/cloudflare-dns/`, see its `CLAUDE.md`) is an
explicit, documented exception that uses gopass for four secrets, all
under path `cloudflare/cloudflare-dns/*`:

- `api-token` — Pulumi (`infra:*`)
- `workers-deploy-token` — Workers Scripts deploy
- `logs-read-token` — Log Explorer (`dns-explain` worker)
- `sync-secret` — Bearer for manual sync trigger

Treat those four paths as load-bearing. Do not silently override or
migrate without coordinating with the cloudflare-dns maintainer; per
that project's contract, `wrangler secret put` requires OAuth login as
`iac-automation@jefahnierocks.com`, not an API token, so a 1Password
migration changes more than just the gopass commands. **TODO**: mirror
this exception in `docs/secrets.md` (which currently remains 1Password-first
at v2.2.1). The mirror is deferred until the cloudflare-dns gopass paths
are confirmed long-term load-bearing rather than transitional. Treat
*other* gopass references encountered on this machine as migration
residue unless an analogous project-level exception exists.

### Repo-side framework primitives (use these; do not invent)

The 1Password local secrets framework on this workstation is already
established. Reuse it; do not invent parallel patterns when something
already exists.

- **Multi-vault SSH agent.** `home/dot_config/1Password/ssh/agent.toml.tmpl`
  emits one `[[ssh-keys]]` stanza per entry in `home/.chezmoidata.yaml`
  `ssh.onepassword.vaults`. To add a vault, add it to the YAML list and
  re-apply chezmoi. Stanza order is the order keys are offered.
- **`.1password.pub` file rendering.** Pattern at
  `home/dot_ssh/id_ed25519_happy_patterns.1password.pub.tmpl`:
  ```go
  {{ onepasswordRead "op://Dev/<item-name>/public key" -}}
  ```
  One template per public-key file. Chezmoi renders at apply time; the
  rendered file becomes the `IdentityFile` target named in the SSH conf
  module.
- **`ssh.host_migrations` map.** `home/.chezmoidata.yaml` `ssh.host_migrations`
  binds a logical host to a `.pub` path. The SSH conf templates fall back
  to the local private key when the `.pub` does not exist at apply time
  — this is the staged-cutover behavior, not a bug. Add an entry, render
  the `.pub` template, then re-apply.
- **`allowed_signers` list.** `home/.chezmoidata.yaml` `ssh.allowed_signers`
  is rendered through `home/dot_ssh/allowed_signers.tmpl`. Append-only on
  rotation: keep old entries so historical signed commits stay verifiable.
  Each entry has `principal`, `public_key`, optional `comment`.
- **`op://` env manifests.** `home/dot_config/mcp/private_common.env`
  contains references only (verified zero secret literals in audit). Run
  via `op run --account my.1password.com --env-file=$HOME/.config/mcp/common.env -- <tool>`.
  Wrappers in `home/dot_local/bin/executable_mcp-*-server.tmpl` do an
  `op read` fallback when env vars are absent.
- **Wrapper pattern.** A new auth-backed integration follows the wrapper
  shape: take env-var first; `op read` when missing; never persist the
  resolved value.

For SSH rotation specifically: every step has a primitive in this
framework already. The "Rotation runbook (per identity)" sub-section in
P3 walks through which primitive to touch in which order. Do not author a
new pattern.

### `op` CLI capabilities for SSH Key items (current state)

- **Cannot import existing private key material.** This has been on the
  public roadmap since 2022 with no shipped feature. Treat as indefinitely
  deferred. Source: 1Password developer docs and community thread.
- **Cannot edit SSH Key items with `op item edit`.** Title, tags, and notes
  changes for existing SSH Key items must go through the desktop GUI.
- **Can generate a fresh SSH Key item** (key generated inside 1Password)
  since `op` 2.21.0 (Aug 2023):
  ```bash
  op item create --category=ssh --vault=Dev \
    --title="ssh-hetzner-primary-2026" \
    --ssh-generate-key=ed25519
  ```
- **Public-key extraction** is reliable:
  ```bash
  op read "op://Dev/ssh-hetzner-primary-2026/public_key"
  ```

### `IdentityAgent` multi-vault behavior

Multiple vaults are supported by repeating `[[ssh-keys]]` stanzas in
`agent.toml`. Each may name `item`, `vault`, and/or `account`. Order of
stanzas is the order keys are offered, which becomes load-bearing past
`MaxAuthTries=6` keys. There is no per-host filter inside `agent.toml`;
host-to-key binding lives in `~/.ssh/config` via `IdentityFile <pub>` plus
`IdentitiesOnly yes`. There is no persistent per-app deny mechanism — the
only structural way to keep an autonomous agent off the SSH agent is to
launch it with `SSH_AUTH_SOCK` and `IdentityAgent` unset (or pointed at a
different agent), or to keep its target keys in a vault not listed in
`agent.toml`.

## SSH Key Migration Principle

Do not delete local `~/.ssh` private keys just because the audit found that
many open without a passphrase.

### Lockout-prevention principle (do this every time)

The single most important rule is: **never remove a credential before its
replacement is verified working from a second terminal**. Concrete
guarantees this rule preserves:

- A second terminal session, started before the rotation, retains shell
  authority and can roll back any local config change.
- The remote host accepts both the old and the new key for the entire
  rotation window. The old key is removed only after the new one is
  proven functional.
- The chezmoi-managed `host_migrations` template falls back to the local
  private key when the new `.pub` is not yet rendered. This is the
  intentional staged-rollout behavior; do not "fix" the fallback.
- For any host where there is no console / out-of-band recovery path
  (e.g., remote VPS, no IPMI), keep at least one untouched key with full
  access until the first migration cycle on a *different* host has been
  verified end-to-end.
- For Git SSH signing identities, append the new key to `allowed_signers`
  *before* switching `user.signingkey`. Never delete entries from
  `allowed_signers` — old signed commits remain verifiable only as long as
  their public key is in the file.
- When in doubt, increase the rotation window. There is no operational
  cost to the old key remaining in `authorized_keys` for an extra day.

The desired sequence is:

1. Inventory local keys and map each to an owner, remote, and intended use.
2. Classify each identity into one of:
   - human interactive Git identity
   - human interactive server/network identity
   - project-specific deploy identity
   - stale/unknown
   - machine/unattended identity that should move away from human 1Password
3. Decide for each whether to:
   - **Generate fresh in 1Password and rotate** (preferred for production-reach
     keys; avoids the "private key was on disk for years" provenance issue)
   - **Import existing into 1Password as SSH Key item** (preserves the public
     key; still requires desktop-app workflow for importing private material)
   - **Archive and remove** (stale / unknown after provenance review)
4. Stage nonsecret public-key paths in `home/.chezmoidata.yaml` and
   `home/dot_ssh/conf.d/*.conf.tmpl`.
5. Apply only after `chezmoi apply --dry-run`.
6. Verify auth and signing behavior.
7. Remove or archive local private-key files only after they are no longer
   referenced and the remote side has accepted the 1Password-backed identity.
8. For rotations, append the new public key to remote `authorized_keys`
   while still authenticated with the old, then switch local config, then
   remove the old key from the remote in a controlled window.

Priority order:

1. Network and server administration identities.
2. GitHub/Git identities with broad repo reach.
3. Project-specific keys.
4. Unknown or stale keys for removal after provenance review.

Existing helper scripts:

- `scripts/write-1p-ssh-import-manifest.zsh` writes a static TSV manifest
  (26 entries as of v0.3.1, covering every private key the audit found).
- `scripts/import-ssh-keys.zsh` verifies local files and 1Password item
  presence, but it cannot import existing private keys. 1Password desktop is
  required for importing existing key material as SSH Key items.

## Implementation Tracks

### P0. Preserve and Refresh Evidence

Goal: every hardening change has before/after evidence.

Tasks:

- Keep the audit artifact directory private and intact.
- Before each remediation, rerun the narrow evidence command for that surface.
- After each remediation, rerun the same command and add a dated note to the
  working issue or implementation log.
- Never store command outputs that include secret values in the repo.

Verification:

```bash
shasum -a 256 ~/Library/Logs/security-audit/2026-05-02-ua-wired/evidence-manifest.tsv
```

Status: directory exists with `drwx------` permissions; no remediation work
required for this track.

### P1. Bind Container Ports to Loopback

Goal: remove public-interface exposure for local developer services while
keeping local agents and browsers able to reach them through loopback.

Findings (Appendix A is the authoritative table):

| Owner repo | Container | Public ports |
|---|---|---|
| `~/ai/flux/infra/compose/compose.yaml` | `flux-otel-collector` | 4317, 4318, 8888 |
| same | `flux-jaeger` | 16686 |
| same | `flux-postgres` | 5433 (host) |
| same | `flux-garage` | 3900, 3903 |
| same | `flux-caddy` | 8080 |
| `~/ai/flux-agent-b/infra/compose/compose.yaml` | `flux-valkey` | 6380 (host) |
| `~/Development/personal/authentik/compose.yaml` | `authentik-server-1` | 9000, 9443 |
| ad hoc (no compose file) | `budget-triage-db-local` | 5432 |

Default remediation (per project repo):

For each `ports:` entry, replace shorthand `"5432:5432"` with explicit
loopback bindings for both address families. The IPv4 loopback alone does
**not** cover `::1`; each family needs its own entry. Recommended long-form:

```yaml
services:
  postgres:
    ports:
      - { target: 5432, published: 5432, host_ip: "127.0.0.1", protocol: tcp }
      - { target: 5432, published: 5432, host_ip: "::1",       protocol: tcp }
```

Short-form equivalent (Compose v2 / schema 3.x both accept):

```yaml
ports:
  - "127.0.0.1:5432:5432"
  - "[::1]:5432:5432"
```

For projects we do not own, prefer a per-stack `compose.override.yaml` rather
than editing the upstream file. Compose ports lists *concatenate* by default,
so the override needs `!override`:

```yaml
services:
  db:
    ports: !override
      - "127.0.0.1:5432:5432"
      - "[::1]:5432:5432"
```

Backstop (host-side, only if per-project edits are not feasible):

```json
// ~/.orbstack/config/docker.json
{
  "ip": "127.0.0.1",
  "default-network-opts": {
    "bridge": {
      "com.docker.network.bridge.host_binding_ipv4": "127.0.0.1"
    }
  }
}
```

`"ip"` covers the default `bridge` network; `default-network-opts` covers
newly created user-defined bridges (existing Compose-created networks are
unaffected — `docker compose down` then `up` is required). Restart with
`orb restart docker`. Note: this option accepts an IPv6 literal but cannot
be set to both families simultaneously, so per-project explicit binding
remains the cleaner answer.

For the ad hoc `budget-triage-db-local` container (no compose file):
`docker stop` and recreate with `-p 127.0.0.1:5432:5432 -p '[::1]:5432:5432'`.

Side effects to plan around:

- **Tailscale, ZeroTier, WARP virtual interfaces**: `utun*` is not loopback.
  `127.0.0.1`-bound services are unreachable from tailnet peers. If any cross-machine
  access is needed, bind to the tailscale interface IP explicitly in addition
  to loopback, or use `tailscale serve`.
- **Container-to-host via published port**: containers reaching host services
  via `host.docker.internal` resolve to the bridge IP, not loopback. A host
  service bound only to `127.0.0.1` will refuse those connections. Either
  keep that one service on `0.0.0.0` (with a `pf` deny rule) or bind to the
  bridge IP explicitly.
- **macOS Application Firewall does not stop 0.0.0.0-bound containers** —
  the privileged helper bypasses `socketfilterfw`. Stealth mode does not
  intercept either. Loopback binding is the only reliable host-side fix
  short of a `pf` rule, which has no widely-validated public recipe for
  OrbStack.

Acceptance gate:

```bash
lsof -nP -iTCP -sTCP:LISTEN
docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Ports}}'
PUBLIC_IP="$(curl -s https://api.ipify.org)"
for p in 5432 5433 8080 9000 9443 6380 16686 4317 4318 8888 3900 3903; do
  nc -G 1 -zv "$PUBLIC_IP" "$p" 2>&1 | head -1
done
```

Expected result: container ports listen on `127.0.0.1` and `::1` only;
self-connect to the public IP fails or times out for every port in the set.

Risks: if a deployed Tailscale/ZeroTier-based workflow depended on a public
container port (unlikely in this inventory), it would break. Roll back by
restoring the prior `ports:` lines in the affected `compose.yaml`.

### P2. Close or Justify Non-Container Listeners

Goal: no unexpected public-interface listeners.

Current follow-ups:

- `rapportd` on `*:60979`: enables Continuity / Handoff / Universal
  Clipboard / watch unlock / iPhone camera. Keep if those features are in
  use. To disable: System Settings → General → AirDrop & Handoff → off.
  Verify the listener is gone with `lsof -nP -iTCP:60979`.
- DaVinci Resolve on `*:49152`: typically panel/control or remote-render
  feature. Resolve documents this in app preferences (Network) — disable
  if not needed.

UDP context (`udp-sockets.txt`): Chrome and Google software hold many
`*:5353` mDNS bindings. mDNS is link-local (TTL=1), so this does not appear
on the public IP. No action needed unless privacy preference dictates.

Acceptance gate:

```bash
lsof -nP -iTCP -sTCP:LISTEN
PUBLIC_IP="$(curl -s https://api.ipify.org)"
for p in 49152 60979; do nc -G 1 -zv "$PUBLIC_IP" "$p" 2>&1 | head -1; done
```

Risks: turning off Continuity loses Handoff, watch unlock, iPhone camera.
Resolve panel or remote workflow may need adjustment if this app is used in
a multi-machine setup.

### P3. Migrate and Rotate SSH Keys Through 1Password

Goal: move human interactive SSH identities to the 1Password SSH agent and
retire local private key files after verification. Rotate over time; do not
treat the audit as proof of compromise.

Current chezmoi state (`home/.chezmoidata.yaml`):

```yaml
ssh:
  use_1password_agent: true
  identity_agent: "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  host_migrations:
    github_personal: "~/.ssh/id_ed25519_personal.1password.pub"
    github_happy_patterns: "~/.ssh/id_ed25519_happy_patterns.1password.pub"
    hetzner_user: "~/.ssh/id_ed25519_hetzner_primary_admin.1password.pub"
    hetzner_runner: "~/.ssh/id_ed25519_hetzner_runner_admin.1password.pub"
    runpod_inference: "~/.ssh/runpod-inference.1password.pub"
```

The chezmoi templates are designed to fall back to local private-key paths
when a `.pub` does not yet exist, so partially staged migrations do not
break SSH. This is the correct staged-rollout behavior.

Task order:

1. **Regenerate the manifest** from the audit inventory. (Done in v0.3.1:
   both `scripts/write-1p-ssh-import-manifest.zsh` and
   `scripts/import-ssh-keys.zsh` now carry all 26 entries with audit-derived
   classifications. See Appendix B for the per-key triage table.)
2. **Decide rotate-fresh vs import** per identity. Default rule:
   - Production-reach human keys (server admin, GitHub broad reach):
     **generate fresh in 1Password** via `op item create --category=ssh
     --ssh-generate-key=ed25519`, append new public key to remote
     `authorized_keys` (or GitHub account), then switch local config.
   - Project deploy keys: **generate fresh and rotate**.
   - Stale/unknown: **archive locally then delete** after provenance review;
     do not import.
   - Pre-existing identities for which provenance is clear and rotation is
     not required immediately: **import via 1Password desktop** as SSH Key
     items.
3. **Render `.1password.pub` files** from 1Password only where needed by a
   matching `home/dot_ssh/*.1password.pub.tmpl`.
4. **Add `ssh.host_migrations` entries** one host category at a time. The
   existing entries in `chezmoidata.yaml` reference `.pub` files that may
   not exist yet — those entries are inert until the corresponding `.pub`
   is rendered, which is by design.
5. Keep project docs from depending on local private key filenames.

### Rotation runbook (per identity, leveraging existing framework)

For each identity to rotate, in order. Each step names the framework
primitive it touches. Do not skip step 1 — it is the rollback session.

1. **Open a second terminal session** with the *current* working SSH
   identity loaded. Do not close it until verification passes. This is
   the rollback session.

2. **Decide rotate-fresh or import.** For production-reach keys, prefer
   rotate-fresh:
   ```bash
   op item create --category=ssh --vault=Dev \
     --title="ssh-<host-or-identity>-$(date +%Y%m)" \
     --ssh-generate-key=ed25519
   ```
   For low-reach historical keys you want to preserve as-is, import via
   the 1Password desktop app (CLI cannot import private material).

3. **Add the `.pub` template** at
   `home/dot_ssh/<filename>.1password.pub.tmpl` containing:
   ```go
   {{ onepasswordRead "op://Dev/<item-title>/public key" -}}
   ```
   `chezmoi diff` should show the new file content. `chezmoi apply
   --dry-run` must succeed.

4. **Append the new public key to remote `authorized_keys`** while still
   authenticated with the old key. Verify in a *third* terminal:
   ```bash
   ssh -o IdentitiesOnly=yes -i <new-pub-path> <user@host>
   ```
   The new key must succeed before continuing. The old key must still
   succeed; do not remove it yet.

5. **Stage the chezmoi `host_migrations` entry** in
   `home/.chezmoidata.yaml`:
   ```yaml
   ssh:
     host_migrations:
       <logical_name>: "~/.ssh/<filename>.1password.pub"
   ```
   Run `chezmoi diff` to confirm the SSH conf module's `IdentityFile`
   line will switch. `chezmoi apply --dry-run` must succeed.

6. **Apply.** `chezmoi apply`. Verify SSH still works *from the rollback
   session*:
   ```bash
   ssh -G <host> | rg '^(identityfile|identityagent) '
   ssh -T <host>
   ```
   For Git identities, also run `git -c user.signingkey=<new-pub> commit
   --allow-empty -m "rotation test"` and verify with `git log
   --show-signature -1`.

7. **For Git signing identities**, append the new key to
   `home/.chezmoidata.yaml` `ssh.allowed_signers`:
   ```yaml
   - principal: "<email>"
     public_key: "ssh-ed25519 <pubkey>"
     comment: "<item-title>-<date>"
   ```
   Re-apply. Confirm `git log --show-signature -1` still passes for
   *old* commits — the old key entry must remain in the list.

8. **Wait at least 24 hours** with both keys live in the remote
   `authorized_keys`. Use the new key in normal workflows. If anything
   goes wrong, the rollback session retains shell authority.

9. **Remove the old key from the remote** `authorized_keys`. Verify with
   the rollback session that the new key still works. Verify the *old*
   key is now rejected (this confirms the rotation is committed).

10. **Archive (do not delete) the old SSH Key item in 1Password** —
    archived items are excluded from the agent's key offering
    automatically. Archival preserves the item for audit. If the old
    key was on disk, move (do not `rm`) the local file into a private
    backup directory outside the repo and outside `~/.ssh`.

11. **Update Appendix B** with the new state for the rotated identity.

If any step fails, do not advance. The rollback session retains full
access; restoring chezmoi state is `git checkout -- home/.chezmoidata.yaml
home/dot_ssh/<filename>.1password.pub.tmpl && chezmoi apply`.

Multi-vault `agent.toml` pattern (if SSH Key items end up split across
vaults):

```toml
[[ssh-keys]]
vault = "Dev"

[[ssh-keys]]
vault = "Infrastructure"
account = "my.1password.com"
```

Order of `[[ssh-keys]]` blocks is the order keys are offered. Past 6 keys
total, `MaxAuthTries=6` becomes a constraint and ordering matters — put
the most-frequently-used identity first.

`allowed_signers` lifecycle:

- 1Password does not maintain `~/.ssh/allowed_signers` automatically. It
  is user-maintained, and `home/dot_ssh/allowed_signers.tmpl` is the
  managed source.
- On rotation: **append** the new key to `allowed_signers`. Do not delete
  old entries — old commits remain verifiable only as long as the old
  public key is in the file. Optional: add OpenSSH `valid-before` /
  `valid-after` time bounds per entry.

Acceptance gate:

```bash
ng-doctor ssh
ssh -G github.com | rg '^(identityagent|identityfile|forwardagent|identitiesonly) '
git log --show-signature -1
ssh -T <each migrated host alias>
```

Do not remove a local private key until:

- the target host resolves to the 1Password SSH agent,
- the target host accepts the 1Password-backed public key,
- fallback access exists (e.g., a console or a still-active second key),
  and
- the relevant project docs no longer require the local private key path.

Risks: removing a key prematurely locks the user out of a production host.
Always verify access from a second terminal before removing local material.
Keep one unmigrated key as last-resort access until at least the first
rotation cycle is verified.

### P4. Scrub Shell History and Keep It Clean

Goal: remove stale sensitive commands from history files and prevent
recurrence.

Current state:

- zsh recurrence prevention is in place: `HIST_IGNORE_SPACE`,
  `EXTENDED_HISTORY`, `HIST_EXPIRE_DUPS_FIRST`, `HIST_IGNORE_DUPS`,
  `HIST_VERIFY`, `SHARE_HISTORY`, `INC_APPEND_HISTORY`. Source:
  `home/dot_config/zshrc.d/20-interactive.zsh`.
- Audit found 632 sensitive matches across three files (Findings Summary).
- The XDG-located zsh history (`~/.local/state/zsh/history`) is the active
  one; `~/.zsh_history` is the legacy file.
- fish is not part of the managed shell surface; fish history can be
  retired entirely.

Tasks:

- Work from counts and interactive review, not pasted matches.
- Back up history files into a private local directory outside the repo:
  ```bash
  install -d -m 700 "$HOME/Library/Logs/security-audit/2026-05-02-ua-wired/history-pre-scrub"
  for f in ~/.zsh_history ~/.local/state/zsh/history ~/.local/share/fish/fish_history; do
    [[ -f "$f" ]] && cp -p "$f" "$HOME/Library/Logs/security-audit/2026-05-02-ua-wired/history-pre-scrub/"
  done
  ```
- Review and rewrite matched lines out of each file using interactive `vim`
  with the same regex used by the audit.
- Consider deleting `~/.zsh_history` entirely (legacy) and
  `~/.local/share/fish/fish_history` (unsupported shell) after backup.
- Document the operational rule in `docs/secrets.md` or
  `docs/agentic-tooling.md`: leading-space commands, `op run --env-file`,
  committed `op://` manifests for any sensitive shell input.

Acceptance gate:

```bash
rg -n '(?i)(token|secret|api[_-]?key|password|bearer|aws_|gh_|github_pat)' \
  ~/.zsh_history ~/.local/state/zsh/history ~/.local/share/fish/fish_history 2>/dev/null \
  | wc -l
```

Expected result: count drops to false-positives only (documentation text or
`op://` references). Fish history file may no longer exist.

Risks: history rewriting is irreversible. Always work from the backup.
If interactive review is rushed, valid commands can be lost; budget time
accordingly.

### P5. Rationalize macOS Sharing, Firewall, TCC, and BPF

Goal: reduce unnecessary local app privileges and passive discovery.

Specific findings to act on:

- `/Users/verlyn13/Public` is configured as an SMB share point with guest
  access enabled (read-write). The SMB sharing service itself is off, so
  the share is dormant. Lock down the share point definition (revoke guest
  write or remove the share point entirely) so re-enabling SMB does not
  expose write access by default:
  ```bash
  sudo sharing -r 'Jeffrey Johnson’s Public Folder'
  ```
- `kTCCServiceAppleEvents` is granted to
  `/opt/homebrew/Cellar/node/25.9.0_1/bin/node`. AppleEvents grants the
  ability to script other apps. A node binary having this is unusual and
  worth investigating (likely from an Electron app that ran node and
  triggered the prompt). If not load-bearing, revoke via `tccutil reset
  AppleEvents` or System Settings → Privacy & Security → Automation.
- File-provider, network-volumes, and folder-access TCC grants are broad
  across the AI tools (claude-code, claudefordesktop, codex, windsurf,
  vscode, iterm2, Terminal). Revoke any that are not load-bearing for
  current workflows.
- ChmodBPF LaunchDaemon is loaded; user is in `access_bpf` group; live
  packet capture without root is possible from any user-owned process.
  Keep only if Wireshark is actually used. To remove:
  ```bash
  sudo launchctl bootout system /Library/LaunchDaemons/org.wireshark.ChmodBPF.plist
  sudo dscl . -delete /Groups/access_bpf GroupMembership $USER
  ```

Preserve (do not touch during P5 cleanup):

- **Cloudflare WARP daemon**
  (`com.cloudflare.1dot1dot1dot1.macos.warp.daemon`, system `LaunchDaemon`)
  — load-bearing for the home Zero Trust DNS posture. Listed under
  Appendix C "leave alone" but worth restating: do not `bootout`, do not
  remove the bundle.
- **WARP TCC grants** for `com.cloudflare.1dot1dot1dot1` and
  `com.cloudflare.1dot1dot1dot1.macos.warp.daemon` — required for the
  daemon to manage network state. Do not revoke during the
  Automation / Files & Folders sweep.
- **ALF allowlist entries for the WARP daemon** — if the App Firewall is
  toggled off and back on, or the allowlist is reset as part of P5, the
  WARP daemon must be re-added explicitly. Verify after any ALF change:
  `warp-cli status` should report `Connected`. Cross-check with
  `~/Repos/local/cloudflare-dns/docs/warp-cli.md` (live runbook for the
  WARP-side contracts).

Acceptance gates:

```bash
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
sharing -l
sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
  'select service, client, auth_value from access order by service, client;'
ls -l /Library/LaunchDaemons/org.wireshark.ChmodBPF.plist /dev/bpf* 2>/dev/null | head
```

Risks: revoking TCC grants causes apps to re-prompt on next use.
Removing ChmodBPF requires reinstalling or re-granting if Wireshark is
used later. Removing the Public share point is reversible via System
Settings.

### P6. Clean Up Broken LaunchAgents

Goal: remove persistent failure loops and stale local services.

Disposition (Appendix C is the authoritative table):

| Label | Status | Action | Owner repo |
|---|---|---|---|
| `com.mcp.docs` | EX_CONFIG | unload + delete plist | none (origin tree gone or stale) |
| `com.mcp.models` | EX_CONFIG | unload + delete plist | none |
| `com.mcp.control` | EX_CONFIG | unload + delete plist | none |
| `com.mcp.daily-refresh` | EX_CONFIG | unload + delete plist | none |
| `com.happy-devkit.mcp-server` | EX_CONFIG (3027 restarts) | unload; investigate Doppler-era origin in `~/Development/business-org/happy-devkit/` | external repo |
| `com.jefahnierocks.host-capability-substrate.measure` | exit 127 | fix hard-coded `mise installs/just/1.46.0` path; switch to `$(mise which just)` or PATH-derived | `~/Organizations/jefahnierocks/host-capability-substrate/` |
| `com.workspace.budgeteer.api` | invalid plist (raw `&&`) | fix XML (escape `&` as `&amp;`) or refactor to a launcher script | `~/workspace/business-manager/` |
| `com.workspace.budgeteer.ingest` | invalid plist (raw `&&`) | same as above | `~/workspace/business-manager/` |
| `homebrew.mxcl.redis` | running, healthy | keep | Homebrew |
| `homebrew.mxcl.ollama` | running, healthy | keep | Homebrew |
| `com.jefahnierocks.mcp-usage-collector` | runs every 60s, exit 0 | keep | `system-config` |
| `com.maat.processmonitor` | runs from `~/Development/happy-patterns-org/maat-framework/` | review with maat owner | external repo |

The four `com.mcp.*` agents predate the 1Password migration and reference
a Doppler-era tree. Unload pattern:

```bash
launchctl bootout "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.mcp.docs.plist"
rm "$HOME/Library/LaunchAgents/com.mcp.docs.plist"
```

For the budgeteer plists, the immediate cause is that XML requires `&` to
be escaped as `&amp;`. The plist source has raw `&&` inside a `<string>`
element, which Apple's plist parser rejects. Two repair options:

1. Edit the plist to escape: `cd … &amp;&amp; …`
2. Refactor: move the shell pipeline into
   `~/workspace/business-manager/scripts/budgeteer-api-start.sh` and have
   the plist invoke that script directly. Cleaner long-term.

For the HCS measure agent (`exit 127`), the hard-coded mise install path
breaks whenever `just` is upgraded. Fix in the host-capability-substrate
repo by either (a) using the mise shim in `~/.local/share/mise/shims/just`
or (b) emitting `mise exec just -- measure` so the version is resolved at
launch time.

Acceptance gate:

```bash
launchctl list | rg 'com\.(mcp|happy|jefahnierocks|workspace|maat)'
plutil -lint ~/Library/LaunchAgents/*.plist
```

Risks: an unloaded agent that is actually load-bearing in some workflow
will manifest as a missing service. Keep the plist files in the
`pre-scrub` backup directory to allow restore.

### P7. Split Agentic MCP Trust Profiles

Goal: reduce prompt-injection blast radius. The "lethal trifecta"
(Willison, June 2025) framing extended by Meta's Oct 2025 "Agents Rule of
Two" is the current consensus: when an agent has any **two of three**
properties — (A) access to private data, (B) exposure to untrusted content,
(C) ability to change state externally or communicate externally —
prompt-injection attacks become exploitable.

Mapping the current baseline (Appendix D is the authoritative table):

| Server | A: private | B: untrusted | C: state-change/exfil |
|---|---|---|---|
| `context7`, `*-docs` | – | weak (vendor docs) | – |
| `memory` | yes (read+write) | – | – |
| `sequential-thinking` | – | – | – |
| `brave-search`, `firecrawl` | – | yes (arbitrary web) | – |
| `github` | yes | yes (issue/PR bodies) | yes (comment, PR, edit) |
| `runpod` | yes | – | yes (pod create runs arbitrary image) |
| `cloudflare` | yes | – | yes (DNS write is textbook exfil; Worker deploy is RCE) |

`github` alone embodies all three legs. `cloudflare` and `runpod` are
state-change channels that should not co-reside with an untrusted-content
session. `memory` is a dual-use sink: an injection can write to it now and
exfil later via a (C)-capable session.

Proposed two-profile design:

- **`engineering` (default)** — current baseline. All 10 servers. Used
  for trusted local engineering work where the human is reviewing each
  step.
- **`low-risk`** — `context7`, `cloudflare-docs`, `runpod-docs`,
  `sequential-thinking`, `brave-search`, `firecrawl`. **No** `github`,
  `cloudflare`, `runpod`, or `memory`. Used for sessions that read
  untrusted external content (web pages, PR/issue bodies).

Per-tool switching reality (researched):

| Tool | Mechanism for runtime profile selection |
|---|---|
| Codex CLI | `--profile <name>` plus per-profile `[mcp_servers.*]` blocks in `~/.codex/config.toml`. Cleanest of the six. |
| Claude Code CLI | Per-project `.mcp.json` (project > user precedence), or `--mcp-config <file>` flag. Useful: launch from a directory with a low-risk `.mcp.json`. |
| Cursor | Per-project `.cursor/mcp.json`. Project wins over user-level. |
| Copilot CLI | `--mcp-config <file>` flag. Wrap with a shell alias. |
| Claude Desktop | **No native switch.** Single global `claude_desktop_config.json`. Only practical option is to swap files via a launcher. |
| Windsurf | **No native switch.** Single global `~/.codeium/windsurf/mcp_config.json`. Same constraint as Claude Desktop. |

Server-side scope reduction (current state):

- **GitHub MCP**: `--read-only` flag (`GITHUB_READ_ONLY=1`); `--toolsets` /
  `GITHUB_TOOLSETS=` (e.g., `repos,issues`); `--dynamic-toolsets`. As of
  Jan 2026 the server filters classic-PAT (`ghp_`) tools by OAuth scope
  automatically; fine-grained PATs (`github_pat_`) are not auto-filtered,
  so use `--read-only` and PAT permission scoping instead.
- **Cloudflare MCP**: no `--read-only` flag in the official server (issue
  #263 open). Practical alternative: community `pocc/cloudflare-mcp`
  provides ~354 read-only tools.
- **RunPod MCP**: scope at the API key (RunPod supports read-only API
  keys) — issue distinct keys per profile.

Implementation approach for `system-config`:

1. Add a second source-of-truth file `scripts/mcp-servers-low-risk.json`
   containing only the `low-risk` set.
2. Extend `scripts/sync-mcp.sh` to accept `--profile {engineering,low-risk}`
   and route to the appropriate source file. Default remains
   `engineering` for backwards compatibility.
3. For the wrappers that accept scope flags (GitHub, RunPod), add a
   parallel `home/dot_local/bin/executable_mcp-github-readonly-server.tmpl`
   that injects `--read-only` and a read-only PAT if a separate
   `op://Dev/github-mcp-readonly/token` item exists. Otherwise document
   the gap.
4. Document Claude Desktop and Windsurf as "file-swap only" until vendor
   support changes.

Acceptance gate:

```bash
scripts/sync-mcp.sh --dry-run
scripts/sync-mcp.sh --profile low-risk --dry-run
jq '.mcpServers | keys' ~/.claude.json ~/.cursor/mcp.json
python3 - <<'PY'
import tomllib, pathlib
print(sorted(tomllib.loads(pathlib.Path("~/.codex/config.toml").expanduser().read_text()).get("mcp_servers", {}).keys()))
PY
```

Risks: misrouting a session to `engineering` while reading untrusted
content reintroduces the trifecta. Mitigation: human-in-loop confirmation
for any (C) tool call; rate-limit any one session's tool calls.

Note on cloudflare-dns: the
`~/Repos/local/cloudflare-dns/` project does **not** use the
`cloudflare` MCP server for any of its work. It invokes the Cloudflare
API via Bash + `curl` with the gopass-backed `api-token` (Pulumi),
`workers-deploy-token` (worker deploys), and `logs-read-token` (Log
Explorer). Profile assignment for the `cloudflare` MCP server in this
plan has no effect inside that project's CWD. A future reviewer should
not "fix" the absence of the MCP server in cloudflare-dns sessions; the
absence is intentional and contracted in that project's `CLAUDE.md`.

### P8. Review Agent Memory and Local Context

Goal: keep useful operational memory while removing details that are too
specific for default loading.

Tasks:

- Review global Codex memory (`~/.codex/memories/MEMORY.md` 64 KB,
  `memory_summary.md` 18 KB) for personal identifiers, family/care
  details, public IPs, MAC addresses, and full infrastructure topology.
  This file is the heavy carrier of PII per the audit count.
- Review global Claude memory (`~/.claude/CLAUDE.md`) — already low-PII
  but worth a sweep.
- Note the global-scope Claude memory at
  `~/.claude/projects/-Users-verlyn13/memory/MEMORY.md` (823 bytes, 10
  personal terms). Decide whether this should remain global-scope or be
  moved into a project-specific memory dir.
- Move high-sensitivity facts into project docs only when needed, or omit
  them entirely if they are not load-bearing.
- Do not delete context blindly; record what utility is lost by each
  removal.

Acceptance gate:

```bash
rg -n '(?i)(public ip|mac address|family|care|home address|password|token)' \
  ~/.claude ~/.codex/memories
```

Risks: removing context that was load-bearing degrades agent helpfulness
on operational tasks. Backup before edit.

### P9. WARP and Network Policy Guardrails

Goal: understand and rationalize the current Zero Trust posture without
overstepping into surfaces this repo does not own.

**Key finding (research-backed).** The workstation is enrolled in the
`homezerotrust` org and the WARP tunnel is up, but `gateway=off` on
`cdn-cgi/trace`. The most likely cause is that the org's Secure Web
Gateway proxy toggle (TCP/UDP/ICMP) is **not enabled** in Cloudflare One
Traffic Settings. Without that toggle, Gateway HTTP filtering, network
policies, and posture-gated policies do not apply to this device. **DNS
policies still apply** via the home-network Gateway DoH resolver even
with the proxy toggle off — this is by design for the `homezerotrust`
deployment.

**Authority and scope split.** Two distinct external surfaces own the
WARP / Gateway state. system-config does not own either.

| Surface | Scope | Owner of record |
|---|---|---|
| `~/Repos/local/cloudflare-dns/` (Pulumi, 39 resources) | Gateway DNS policies, custom-block / custom-block-content / custom-block-ads / custom-allow / custom-breakglass lists, three custom WARP device profiles (kids, adults, headless), default device profile (singleton import), managed networks / TLS beacon, WARP enrollment Access app, Gateway DNS location | cloudflare-dns repo (Pulumi state of record at `state.json`) |
| Cloudflare Zero Trust dashboard, NOT in Pulumi | Secure Web Gateway proxy toggle (Traffic Settings → Network); two legacy unmanaged policies "Cert Pinning" (precedence 0) and "Block Malware" (precedence 9000) | org admin only |

The system-config plan does **not** flip the Secure Web Gateway proxy
toggle. The plan does **not** edit anything in the cloudflare-dns Pulumi
tree. The plan **does** verify state, document the scope split, and
ensure the workstation-side preserve list (P5) keeps the WARP daemon and
its TCC / ALF entries intact.

Tasks before any policy decision:

- Snapshot current state to the audit directory:
  ```bash
  warp-cli status  > ~/Library/Logs/security-audit/2026-05-02-ua-wired/warp-state.post-action.txt
  warp-cli settings >> ~/Library/Logs/security-audit/2026-05-02-ua-wired/warp-state.post-action.txt
  warp-cli tunnel stats >> ~/Library/Logs/security-audit/2026-05-02-ua-wired/warp-state.post-action.txt
  ```
- Read the cloudflare-dns architecture and posture docs first; they are
  the rationale source for both Pulumi-managed state and the dashboard
  toggle decision:
  - `~/Repos/local/cloudflare-dns/docs/architecture.md`
  - `~/Repos/local/cloudflare-dns/docs/zero-trust-nav.md`
  - `~/Repos/local/cloudflare-dns/docs/warp-cli.md`
  - `~/Repos/local/cloudflare-dns/state.json` (machine-readable, jq-queryable)
- Verify or decide org-admin state in the Cloudflare Zero Trust dashboard
  (org admin action; this repo does not flip it):
  Traffic Settings → Network → "Allow Secure Web Gateway to proxy traffic"
  toggle. If intentional ("DNS-only enforcement for adults profile"),
  document why in cloudflare-dns docs. If unintentional, enable through
  org admin.
- Verify enrollment health at <https://help.teams.cloudflare.com/> —
  should show **WARP** + **Gateway Proxy** with the correct **Team
  name** (`homezerotrust`).
- Confirm break-glass:
  - `warp-cli disconnect` works without auth (`Switch Locked: false`).
  - `Allowed to Leave Org: true` — user can fully unenroll if needed.
  - Recovery codes in 1Password if `Switch Locked` is ever changed to
    true (this is a `cloudflare-dns/policy-inputs.yaml` decision).
  - Another admin device can issue an External Emergency Disconnect.
- Note the protocol situation: this profile is pinned to WireGuard.
  MASQUE became the default for new device profiles 2025-09-30; this
  device remains on WireGuard until the cloudflare-dns Pulumi
  `tunnelProtocol` value is changed.

Acceptance gate:

```bash
warp-cli status
warp-cli settings | rg -i '(mode|always on|switch locked|gateway|protocol)'

# Public trace — confirms enrollment + Gateway proxy state from public vantage
curl -s https://www.cloudflare.com/cdn-cgi/trace | rg '^(warp|gateway|colo|loc)='

# Home Gateway DoH probe — proves Gateway DNS is enforced from THIS device
# via the home network's Gateway location, not via generic 1.1.1.1.
# Expect NXDOMAIN or A 0.0.0.0; gateway DoH hostname is per cloudflare-dns/state.json.
curl -sH 'accept: application/dns-json' \
  'https://lx46e0bb3m.cloudflare-gateway.com/dns-query?name=malware.testcategory.com&type=A'

# Compare: generic public DNS (Gateway DNS NOT enforced here)
dig @1.1.1.1 malware.testcategory.com
```

Risks: enabling the Secure Web Gateway proxy toggle at org level affects
every enrolled device, not just this workstation. That decision belongs
in cloudflare-dns documentation and org-admin coordination, not in
system-config. Tightening posture rules can lock the device out; keep
`Switch Locked: false` and `Allowed to Leave Org: true` until any new
posture rule is verified on a non-critical device first.

### P10. Codify Posture Checks

Goal: make the next audit cheap and repeatable.

Add a 10th `ng-doctor` category, `posture`, that mirrors the existing
9-category structure (`home/dot_local/bin/executable_ng-doctor.tmpl`).
Each check follows the established `check_<thing>()` / `pass` / `fail` /
`skip` pattern.

Initial checks should be informational (use `skip` with a descriptive
reason rather than `fail`) until P1–P9 settle, so a transitional state
does not flood the doctor with false-fails. Once each track has
stabilized, flip the corresponding check to `pass`/`fail` semantics.

Proposed checks:

- `firewall_enabled`
- `firewall_stealth_mode_on`
- `sharing_remote_login_off`
- `sharing_smb_off`
- `sharing_screen_off`
- `sharing_airplay_off`
- `sharing_no_guest_writable_share_points`
- `docker_no_publishes_to_zero_zero_zero_zero`
- `non_container_listeners_only_expected`
- `op_ssh_agent_socket_present`
- `op_ssh_agent_config_targets_dev_vault`
- `ssh_no_empty_passphrase_keys` (count threshold)
- `shell_history_no_sensitive_patterns` (count threshold)
- `launchagents_all_loaded_or_disabled`
- `wireshark_chmodbpf_present_only_if_used`
- `warp_connected_and_dns_gateway_enforced` — adults-profile expectations
  per `~/Repos/local/cloudflare-dns/infrastructure/pulumi/policy-inputs.yaml`:
  - `serviceModeV2.mode == "warp"` (display string `WarpWithDnsOverHttps`)
  - `tunnelProtocol == "wireguard"`
  - `switchLocked == false`
  - `allowedToLeave == true`
  - profile id `2257cffa-50dc-4f5f-9fdc-083035e927c9`
  - DoH probe (proves home Gateway DNS is enforced from this device,
    not generic 1.1.1.1):
    ```bash
    curl -sH 'accept: application/dns-json' \
      'https://lx46e0bb3m.cloudflare-gateway.com/dns-query?name=malware.testcategory.com&type=A'
    ```
    Expect NXDOMAIN or `A 0.0.0.0`. The DoH hostname source-of-truth is
    `~/Repos/local/cloudflare-dns/state.json`.
- `warp_http_proxy_enforced` — separate check for the org-level Secure
  Web Gateway proxy toggle (currently observed off). This check should
  start in skip-mode until the org-admin decision is documented; do not
  fail-loud on it.

Acceptance gate:

```bash
ng-doctor posture
shellcheck home/dot_local/bin/executable_ng-doctor.tmpl
chezmoi apply --dry-run
```

Risks: adding too many fail-loud checks at once turns the doctor into
noise. Land checks in skip-mode first; promote to fail-mode only after
the underlying surface is stable.

## Work Order

The original sequencing (P1 first, then P2, etc.) does not match where
each track is executable. Reordered by session scope and immediate
risk:

1. **In this repo, low-risk, immediate** (no live infrastructure
   change):
   - P10 skeleton: add `posture` category to `ng-doctor` with all checks
     in skip-mode. Establishes the framework.
   - P3 manifest expansion: extend
     `scripts/write-1p-ssh-import-manifest.zsh` and
     `scripts/import-ssh-keys.zsh` to cover all 26 keys. No key motion.
     **(Landed in v0.3.1.)**

2. **In this repo, medium-risk** (changes user-level managed config):
   - P7 profile design: add `scripts/mcp-servers-low-risk.json`,
     extend `scripts/sync-mcp.sh` with `--profile`, optionally add a
     `mcp-github-readonly-server` wrapper.
   - P6 LaunchAgent disposition for system-config-owned agents:
     `com.jefahnierocks.mcp-usage-collector` is healthy, no action.

3. **Cross-scope handoffs** (issue or PR per repo):
   - P1 → `~/ai/flux/`, `~/ai/flux-agent-b/`,
     `~/Development/personal/authentik/` (one PR each adding loopback
     bindings); plus an ad hoc fix for `budget-triage-db-local`.
   - P6 → `~/Development/business-org/happy-devkit/`,
     `~/Organizations/jefahnierocks/host-capability-substrate/`,
     `~/workspace/business-manager/` for source-side fixes; for the four
     `com.mcp.*` agents whose origin tree is gone, simply unload + remove
     plist (no source repo to update).

4. **Host actions (operator)**:
   - P2 listener decisions (Continuity / Resolve).
   - P4 history scrub.
   - P5 macOS Sharing / firewall / TCC / BPF review.
   - P8 memory hygiene.

5. **Org-admin actions**:
   - P9 verify or enable the Cloudflare One Secure Web Gateway proxy
     toggle in the `homezerotrust` Traffic Settings.

6. **After 1–5 settle**:
   - P10 fill in real assertions in `ng-doctor posture` (flip checks
     from skip-mode to pass/fail-mode as each surface stabilizes).

## Risks and Rollback Summary

| Track | Highest-risk failure | Rollback |
|---|---|---|
| P1 | Loopback bind breaks tailnet/utun reach for a service that needed it | Restore the prior `ports:` lines in the affected `compose.yaml`; restart container. |
| P2 | Disabling Continuity loses Handoff and watch unlock | Re-enable in System Settings → General → AirDrop & Handoff. |
| P3 | Removing a local key locks user out of a host before the 1Password-backed key is accepted | Keep one unmigrated key as last-resort access; verify auth from a second terminal before removing. |
| P4 | Lost commands during interactive history rewrite | Restore from `history-pre-scrub/` backup. |
| P5 | Revoking TCC grants causes apps to re-prompt | Re-grant on next prompt. ChmodBPF removal is reinstall-required. |
| P6 | Unloading an agent that was load-bearing | Restore plist from backup; `launchctl bootstrap`. |
| P7 | Misrouting a session to `engineering` while reading untrusted content | Human-in-loop confirmation for (C) tool calls; rate-limit. |
| P8 | Removing memory context that was load-bearing | Restore from backup. |
| P9 | Enabling Gateway at org level affects every device | Test on a non-critical device first; coordinate with org admin. |
| P10 | Flipping posture checks to fail-mode prematurely floods the doctor | Land checks in skip-mode first; promote individually. |

## Definition of Done

This plan is complete when:

- no local development container publishes to the campus/public interface
  without an explicit documented reason,
- no unexpected non-container listener accepts connections on the public
  IP,
- SSH keys with production reach have either moved to 1Password SSH
  agent or have a documented rotation date,
- unsupported or stale history files are scrubbed,
- broken custom LaunchAgents are repaired or removed,
- macOS sharing, firewall, TCC, and BPF decisions are documented,
- agentic MCP profiles have a low-risk untrusted-content mode,
- `ng-doctor posture` can reproduce the key checks without exposing
  secrets, and
- the WARP / Gateway state is intentional and documented.

## Appendices

### Appendix A: Public-Interface Listener Inventory

From `tcp-listeners.txt`, `docker-portbindings.txt`,
`self-public-ip-portcheck.txt`.

| Port | Service | Source | Reachable from public IP? |
|---|---|---|---|
| 3900 | flux-garage | `~/ai/flux/infra/compose/compose.yaml` | yes |
| 3903 | flux-garage admin | same | yes |
| 4317 | flux-otel-collector OTLP gRPC | same | yes |
| 4318 | flux-otel-collector OTLP HTTP | same | yes |
| 5432 | budget-triage-db-local | ad hoc container | yes |
| 5433 | flux-postgres | `~/ai/flux/infra/compose/compose.yaml` | yes |
| 6380 | flux-valkey | `~/ai/flux-agent-b/infra/compose/compose.yaml` | yes |
| 8080 | flux-caddy | `~/ai/flux/infra/compose/compose.yaml` | yes |
| 8888 | flux-otel-collector telemetry | same | yes |
| 9000 | authentik-server | `~/Development/personal/authentik/compose.yaml` | yes |
| 9443 | authentik-server (TLS) | same | yes |
| 16686 | flux-jaeger UI | `~/ai/flux/infra/compose/compose.yaml` | yes |
| 22 | sshd | macOS Remote Login (off) | timeout |
| 445 | smbd | macOS File Sharing (off) | timeout |
| 548 | AFP | macOS (off) | timeout |
| 5900 | VNC | macOS Screen Sharing (off) | timeout |
| 7000 | AirPlay | macOS (off) | timeout |
| 49152 | Resolve | DaVinci Resolve app | yes |
| 60979 | rapportd | macOS Continuity / Handoff | yes |

Loopback-only services (already correctly bound):
`redis-server` (6379), `figma_agent` (44950, 44960), several `java`
listeners (17170, 17358, 58957, 58984, 59096, 58395, 51962, 58408),
OrbStack control sockets (32222, 52752, 45893), `ollama` (11434).

### Appendix B: SSH Key Triage

From `ssh-key-inventory.tsv`. `passphrase` column: yes = passphrase
present; no = empty passphrase opens.

| File | Passphrase | Likely category | Proposed action |
|---|---|---|---|
| `id_ed25519` | no | mesh / shared workstation key | classify; consider rotate-fresh |
| `id_ed25519_personal` | no | GitHub personal | already in `host_migrations`; verify .pub render |
| `id_ed25519_work` | no | GitHub work identity | rotate-fresh and import |
| `id_ed25519_business` | no | GitHub business identity | rotate-fresh and import |
| `id_ed25519_business-org` | no | happy-patterns-org variant | de-duplicate with `business_org`; rotate-fresh |
| `id_ed25519_business_org` | no | business-org variant | de-duplicate with `business-org`; rotate-fresh |
| `id_ed25519_hubofaxel` | no | GitHub hubofaxel | rotate-fresh and import |
| `id_ed25519_hubofwyn` | no | GitHub hubofwyn | rotate-fresh and import |
| `id_ed25519_nash-group` | no | GitHub nash-group | rotate-fresh and import |
| `id_ed25519_hetzner_user` | no | Hetzner user access | rotate-fresh (production reach) |
| `id_ed25519_hetzner` | no | Hetzner runner | rotate-fresh |
| `id_ed25519_hetzner_root` | no | Hetzner root — high blast radius | rotate-fresh urgently; replace with role-scoped key if possible |
| `id_ed25519_documentation` | no | doc container | provenance review; archive if unused |
| `id_ed25519_mac` | no | verlyn13@fedora-top — cross-machine | provenance review |
| `id_ed25519_scope` | no | unclear | provenance review |
| `id_ed25519_proxmox` | no | Proxmox user access | rotate-fresh |
| `opnsense_usermgmt` | no | OPNsense user management | rotate-fresh |
| `opnsense_usermgmt.from-1password` | no | partial 1P import attempt | reconcile and remove |
| `opnsense_ed25519` | no | OPNsense alternate | provenance review; archive or rotate |
| `dad_admin` | no | Windows admin SSH | provenance review; rotate or archive |
| `synology_downloader_service` | no | Synology service account | provenance review; rotate |
| `synology_nas_key` | yes | Synology user access | passphrase present — keep on disk for now or import as-is |
| `traefik_key` | yes | Traefik server (root@traefik) | passphrase present — high reach, plan rotation |
| `libreweb_key` | yes | libreweb host | passphrase present — review |
| `container_key` | yes | lx101 container | passphrase present — review |
| `google_compute_engine` | yes | RSA-3072 GCP instance | review; consider GCP OS Login or service account instead |

Existing chezmoi `host_migrations` entries that point to `.pub` files
not yet present on disk (template falls back to local key):
`hetzner_user → id_ed25519_hetzner_primary_admin.1password.pub`,
`hetzner_runner → id_ed25519_hetzner_runner_admin.1password.pub`. These
are staged for future apply.

### Appendix C: LaunchAgent Disposition

From `launch-plists.tsv` and `launchctl-custom-details.txt`. See P6 for
remediation workflow.

| Label | Status | Action | Owner |
|---|---|---|---|
| `com.mcp.docs` | EX_CONFIG | unload + delete plist | none (origin gone) |
| `com.mcp.models` | EX_CONFIG | unload + delete plist | none |
| `com.mcp.control` | EX_CONFIG | unload + delete plist | none |
| `com.mcp.daily-refresh` | EX_CONFIG | unload + delete plist | none |
| `com.happy-devkit.mcp-server` | EX_CONFIG (3027 restarts) | unload + investigate | external repo |
| `com.jefahnierocks.host-capability-substrate.measure` | exit 127 | fix mise path | HCS repo |
| `com.workspace.budgeteer.api` | invalid plist | escape `&` or refactor | external repo |
| `com.workspace.budgeteer.ingest` | invalid plist | escape `&` or refactor | external repo |
| `homebrew.mxcl.redis` | running | keep | Homebrew |
| `homebrew.mxcl.ollama` | running | keep | Homebrew |
| `com.jefahnierocks.mcp-usage-collector` | running, exit 0 | keep | system-config |
| `com.maat.processmonitor` | running | review with maat owner | external repo |
| `com.google.GoogleUpdater.wake`, `com.google.keystone.*` | system | leave alone | Google |

System-level `LaunchDaemons` (all leave alone unless explicitly removing
the underlying app): `org.wireshark.ChmodBPF` (P5 candidate),
`com.cloudflare.1dot1dot1dot1.macos.warp.daemon` (**load-bearing for
the home Zero Trust DNS posture — explicitly preserve**),
`wifiman-desktop`, `dev.orbstack.OrbStack.privhelper`,
`us.zoom.ZoomDaemon`.

### Appendix D: MCP Server Risk Mapping (Agents Rule of Two)

Per Meta's Oct 2025 framing extending Willison's June 2025 lethal
trifecta. (A) private data access; (B) untrusted content exposure;
(C) state-change-or-external-communication.

| Server | A | B | C | Profile membership |
|---|---|---|---|---|
| `context7` | – | weak | – | engineering, low-risk |
| `cloudflare-docs` | – | weak | – | engineering, low-risk |
| `runpod-docs` | – | weak | – | engineering, low-risk |
| `sequential-thinking` | – | – | – | engineering, low-risk |
| `brave-search` | – | yes | – | engineering, low-risk |
| `firecrawl` | – | yes | – | engineering, low-risk |
| `memory` | yes | – | – | engineering only |
| `github` | yes | yes | yes | engineering only |
| `runpod` | yes | – | yes | engineering only |
| `cloudflare` | yes | – | yes | engineering only |

`github` alone has all three legs and is the highest-risk single server.
`memory` is dual-use: writeable now, exfiltratable later via a
(C)-capable session — design around that constraint.

### Appendix E: Reference Sources

External research consulted while drafting this plan (URLs as of 2026-05-02):

- Docker port publishing and IPv6 binding behavior:
  - <https://docs.docker.com/engine/network/port-publishing/>
  - <https://docs.docker.com/engine/network/drivers/bridge/>
- OrbStack networking and configuration:
  - <https://docs.orbstack.dev/docker/network>
  - <https://docs.orbstack.dev/settings>
  - <https://github.com/orbstack/orbstack/issues/291>
  - <https://github.com/orgs/orbstack/discussions/950>
- macOS firewall vs Docker:
  - <https://github.com/docker/for-mac/issues/729>
- 1Password SSH agent:
  - <https://developer.1password.com/docs/ssh/manage-keys/>
  - <https://developer.1password.com/docs/cli/item-edit/>
  - <https://developer.1password.com/docs/ssh/agent/config/>
  - <https://developer.1password.com/docs/ssh/agent/security/>
  - <https://developer.1password.com/docs/ssh/git-commit-signing/>
  - <https://app-updates.agilebits.com/product_history/CLI2>
- MCP / agentic security:
  - Willison, lethal trifecta: <https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/>
  - Meta, Agents Rule of Two: <https://ai.meta.com/blog/practical-ai-agent-security/>
  - Claude Code MCP scopes: <https://code.claude.com/docs/en/mcp>
  - Codex MCP and profiles: <https://developers.openai.com/codex/mcp>, <https://developers.openai.com/codex/config-basic>
  - GitHub MCP read-only / toolsets: <https://github.com/github/github-mcp-server>
  - MCP Security Best Practices: <https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices>
- Cloudflare WARP / Zero Trust:
  - Client modes: <https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/configure/modes/>
  - Gateway proxy toggle: <https://developers.cloudflare.com/cloudflare-one/traffic-policies/proxy/>
  - Test DNS filtering: <https://developers.cloudflare.com/cloudflare-one/traffic-policies/dns-policies/test-dns-filtering/>
  - Posture checks: <https://developers.cloudflare.com/cloudflare-one/reusable-components/posture-checks/>
  - WARP macOS changelog (2025-09-30 MASQUE default): <https://developers.cloudflare.com/changelog/product/cloudflare-one-client/>

### Internal cross-repo references

- `~/Repos/local/cloudflare-dns/CLAUDE.md` — guardrails for the
  Pulumi-managed Zero Trust DNS surface (39 resources, gopass-backed
  secrets, blocklist-sync worker, device profile contracts)
- `~/Repos/local/cloudflare-dns/docs/architecture.md` — system
  architecture, profile contracts, list contents, free-tier limits
- `~/Repos/local/cloudflare-dns/docs/zero-trust-nav.md` — current
  Cloudflare dashboard paths (2025 redesign)
- `~/Repos/local/cloudflare-dns/docs/warp-cli.md` — WARP-side
  enrollment + diagnostic runbook
- `~/Repos/local/cloudflare-dns/state.json` — machine-readable live
  Pulumi state, jq-queryable
- `~/Organizations/jefahnierocks/host-capability-substrate/docs/host-capability-substrate/research/local/2026-05-02-system-config-security-audit-evidence.md`
  — HCS-side translation of these findings into ontology terms
