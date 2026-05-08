---
title: MCP bearer-token argv exposure (GitHub + Cloudflare wrappers)
category: incident
component: mcp_secrets
status: open
version: 1.0.0
last_updated: 2026-05-08
tags: [security, mcp, mcp-remote, github-pat, cloudflare-token, argv, 1password, incident]
priority: critical
---

# MCP bearer-token argv exposure — 2026-05-08

## TL;DR

The repo's GitHub MCP and Cloudflare MCP stdio wrappers correctly resolve their
secrets at launch via `op read` (no persistent file leak), but then exec
`mcp-remote@0.1.38` with the bearer token as a CLI argument
(`--header "Authorization: Bearer $TOKEN"`). `mcp-remote` 0.1.x has **no
non-argv mechanism** for setting custom headers (verified upstream), so the
token ends up in process argv where every local user / EDR / process-accounting
surface can read it.

Discovered 2026-05-08 during iTerm2 Phase B verification when `pgrep -fl iTerm`
incidentally revealed the GitHub PAT in two `mcp-remote` argument lists.

The Cloudflare wrapper has the identical architectural flaw — it has not been
observed leaking yet only because no `pgrep` ran while it was active.

This is not a wrapper bug; it's a structural limitation of the bridge tool the
wrappers depend on. The fix is architectural, not a one-line patch.

## Affected secrets

| 1P item | Field | Wrapper | Endpoint | Status |
|---|---|---|---|---|
| `op://Dev/github-mcp/token` | `token` | `~/.local/bin/mcp-github-server` | `https://api.githubcopilot.com/mcp/` | **Observed exposed in argv on 2026-05-08; treat as compromised. Rotate.** |
| `op://Dev/cloudflare-mcp-jefahnierocks/token` | `token` | `~/.local/bin/mcp-cloudflare-server` | `https://mcp.cloudflare.com/mcp` | Same architectural flaw; exposure inevitable when wrapper runs. Rotate as a precaution. |

Other MCP wrappers in the same directory (`mcp-brave-search-server`,
`mcp-firecrawl-server`, `mcp-runpod-server`) use **stdio servers that read
tokens from env vars directly** — no `--header` argv path. They are not
affected by this flaw.

## How the system is supposed to work (per repo conventions)

Per [`docs/secrets.md`](./secrets.md) and [`docs/mcp-config.md`](./mcp-config.md):

- **Resolution path**: env var → `op read --account my.1password.com` → fail.
- **Never** persist secret values in user-global config files (`~/.claude.json`,
  `~/.codex/config.toml`, IDE MCP configs).
- **Never** export secrets globally in shell config.
- The intended pattern: launcher reads secret into a *process-local* env var
  via `op read`, then exec's the actual MCP server which consumes the env
  var.

The wrappers correctly read into env (lines 30–33 of
`executable_mcp-github-server.tmpl`, lines 37–40 of
`executable_mcp-cloudflare-server.tmpl`). The break in the chain is the final
exec, which materializes the env var into argv via shell expansion of
`--header "Authorization: Bearer ${TOKEN}"`. From that point on, the secret is
visible to anyone who can read the bridge's process argv.

## Root cause

[`mcp-remote@0.1.x`](https://github.com/geelen/mcp-remote) supports custom
headers **only** via the `--header` CLI flag. Verified upstream:

> Custom HTTP headers (including Authorization) can only be passed via
> command-line arguments with environment variable interpolation — no
> alternative non-argv mechanisms are documented.

There is no `--header-from-env`, no config file, no stdin path, no FD passing.
Env-var "support" in the docs refers only to `${VAR}` substitution at config
render time — by the time `mcp-remote` runs, the value is already in argv.

The wrapper headers ("mcp-remote runs with --silent so the Authorization
header is never written to stderr") describe stderr safety, not argv safety.
Argv was never addressed by the wrapper design.

## Live exposure points (current state on this box)

At time of writing, **4 `mcp-remote@0.1.38` processes are running** with
GitHub PAT in argv. Parents observed: Claude Code (`claude`) and Codex CLI's
vendored binary, both spawned from interactive zsh sessions inside iTerm2.

Argv is visible to:

- **Any local user / process** via `ps`, `pgrep -fl`, `lsof -p`, Activity Monitor.
- **macOS Endpoint Security framework**: anything subscribed to
  `ES_EVENT_TYPE_NOTIFY_EXEC` (EDR agents, antivirus, observability) sees full
  argv at exec time.
- **Process accounting** (`/var/log/asl/*`, `log show --predicate 'subsystem == "com.apple.libtrace.osx"'`)
  if any audit framework is logging exec events.
- **Crash reports** at `~/Library/Logs/DiagnosticReports/` if any of these
  processes crashed (none observed for `mcp-remote` / `node` related to MCP at
  scan time, but check on a per-rotation basis).
- **iTerm2 scrollback** wherever a `ps` / `pgrep -fl` was run that included
  these processes (Dev profile uses unlimited scrollback). The earlier session
  captured the token in scrollback by running `pgrep -fl iTerm`.
- **Shell history** if the user ran `pgrep -fl ...` and the token-bearing
  output was captured (most history files are command-only, but redirected
  outputs land in files).

## Blast radius — places to check

This is the comprehensive list. Check each before declaring the rotation
complete. Some are unlikely, but the list exists so nothing is forgotten.

### A. Live processes
- `pgrep -fl "mcp-remote@0.1"` — kill these first **after** revocation.
- `lsof -p <pid>` for each — see what file descriptors / sockets are open.

### B. Local logs
- `~/Library/Logs/Claude/*` — Claude Code logs. May include subprocess argv on
  certain log levels. Grep for the PAT prefix `github_pat_11AC5K4RY0`.
- `~/Library/Caches/claude-cli-nodejs/*` — Claude Code cache.
- `~/.codex/log/*`, `~/.codex/sessions/*` — Codex transcripts; may include
  spawn-event metadata.
- `~/.npm/_logs/*` — npm spawn metadata, occasionally argv on errors.
- `~/.npm/_npx/*` — npx-installed copies of `mcp-remote`; check whether any
  log or cache file there picked up argv.
- `~/Library/Logs/system-update/*` — system-config update logs (per
  `MEMORY.md`); unlikely but cheap to check.

### C. macOS-specific surfaces
- `~/Library/Logs/DiagnosticReports/*` — crash reports. None matched
  `*mcp*`/`*remote*`/`*node*` at scan time.
- `~/Desktop/sysdiagnose*`, `/var/tmp/sysdiagnose*` — none present at scan
  time. If one is generated for any reason during the exposure window, it
  contains a `ps`/`launchctl` snapshot.
- `log show --predicate 'process == "mcp-remote"' --info --debug --last 1d` —
  unified-log query for any `mcp-remote` activity.
- Endpoint Security / EDR agent local stores (Carbon Black, CrowdStrike,
  SentinelOne, Apple's own `endpoint_security` clients). If anything of this
  shape is installed on this host, it has argv at exec time and it has
  probably already shipped to its backend. Confirm whether one is running:
  `kextstat | grep -i endpoint`, `pgrep -lf "Endpoint\|sentinel\|carbon"`.

### D. Backups
- **Time Machine**: snapshots of `~/Library/Logs/`, `~/Library/Caches/`,
  `~/.npm/`, `~/.codex/` taken during the exposure window will retain
  whatever logs they contained. `tmutil listbackups` to enumerate; targeted
  check inside specific backup snapshots.
- **iCloud Drive / iCloud-synced Library** — typically not synced, but worth
  confirming on this host.
- **Any third-party backup tool** (Backblaze, Arq, Crashplan): same concern.

### E. Cloud / observability
- Sentry — `docs/sentry-cli-setup.md` exists; if any tool reports errors with
  subprocess context to a Sentry project, the token may have shipped. Check
  Sentry events for the period since the PAT was issued.
- GitHub itself — pull the **PAT-use audit log** for the GitHub PAT before
  revoking. GitHub records token use against repos; review for unexpected
  origin IPs / unexpected actions. Path: GitHub → Settings → Security log,
  filter by token. If the org has SSO/audit logging, also check there.
- Cloudflare — equivalent audit for the Cloudflare token: dashboard → Manage
  Account → Audit Log, filter by API Token use.

### F. iTerm2 scrollback (high-confidence local exposure)
- Open windows that ran `pgrep -fl iTerm` or any `ps` query during the
  exposure window contain the token in scrollback. With unlimited scrollback
  on the Dev profile, this persists until the window is closed.
- iTerm2 saved-state / "Restore on launch" features may persist scrollback
  across restarts:
  - `defaults read com.googlecode.iterm2 ResumeOnLaunch`
  - Settings → General → Startup → "Window restoration policy"
  - If non-default, scrollback may be persisted to disk under
    `~/Library/Application Support/iTerm2/SavedState/`.
- Mitigation: close affected windows; consider a session-wide
  Edit → Clear Buffer for any window that ran the leaking command.

### G. Shell history
- `~/.zsh_history`, `~/.bash_history` — typically command-only. The leaking
  command was `pgrep -fl iTerm`, which is harmless to keep. Only the
  redirected output in this conversation contained the token.

### H. Editor / IDE
- VS Code workspace state, Cursor state, JetBrains caches — if any of these
  ran a terminal that captured the leaking output, scrollback exists in their
  per-workspace state files.

## What this PAT permits (impact assessment)

Per [`docs/github-mcp.md`](./github-mcp.md) the `github-mcp` PAT carries a
broad fine-grained scope. Highlights for the audit:

- **Contents R/W** + **Workflows R/W** + **Actions R/W** — an attacker with
  the PAT could push code to any covered repo, modify GitHub Actions workflow
  YAML to exfiltrate other secrets, dispatch workflows.
- **Pull requests R/W** + **Discussions R/W** + **Issues R/W** — write
  arbitrary content under the `verlyn13` identity.
- **Code scanning R/W** + **Repository security advisories R/W** — could
  silence alerts.
- **Org Members R, Org Administration R** — info disclosure on org
  membership.
- **Org Projects R/W** — modify org projects.

When checking the GitHub PAT-use audit, prioritize:
- workflow_dispatch / push events from unexpected origins
- repo content modifications outside known-good IPs
- new SSH keys / new deploy keys / new repo collaborators on covered repos
- changes to `.github/workflows/*` in any covered repo

## Remediation playbook (ordered)

Order matters: revoke first so even live argv leaks become useless before
anything else.

1. **Revoke at GitHub** — `https://github.com/settings/personal-access-tokens`
   (fine-grained tokens), find `github-mcp`, click Revoke. Token is dead in
   <30 s.
2. **Pull GitHub PAT-use audit** for the period since the token was issued
   (or last rotated). Look for the patterns above. **Do this before generating
   the replacement** so the audit window is clean.
3. **Revoke the Cloudflare token** at the Cloudflare dashboard → My Profile →
   API Tokens — same architectural flaw, treat as precautionary.
4. **Pull Cloudflare audit** for the same period.
5. **Stop running processes:**
   ```bash
   pkill -f "mcp-remote@0.1"
   ```
   Restart any MCP host (Claude Code, Codex) after the architectural fix
   below — letting them respawn the wrappers with the OLD token in argv
   re-creates the leak.
6. **Decide architectural fix** (see "Fix options" below). Implement before
   re-launching MCP hosts.
7. **Generate replacement PATs** with the same scope set per
   `docs/github-mcp.md`. Store in 1Password under the same items
   (`op://Dev/github-mcp/token`, `op://Dev/cloudflare-mcp-jefahnierocks/token`).
8. **Verify resolution**:
   ```bash
   op read --account my.1password.com "op://Dev/github-mcp/token" >/dev/null && echo gh-ok
   op read --account my.1password.com "op://Dev/cloudflare-mcp-jefahnierocks/token" >/dev/null && echo cf-ok
   ```
9. **Re-launch MCP hosts** (Claude Code, Codex) and verify NO token in argv:
   ```bash
   pgrep -fl "mcp-remote" | grep -E "github_pat_|Bearer " && echo LEAKED || echo CLEAN
   ```
10. **Local sweep**: greps with the **old** PAT prefix (e.g.
    `github_pat_11AC5K4RY0`) across `~/Library/Logs`, `~/Library/Caches`,
    `~/.npm`, `~/.codex` to confirm whether the old token was logged anywhere
    on disk. Same with the old Cloudflare token prefix. **Use the actual
    revoked token strings** when grepping; do not type them again into shell
    history — read from a temp file and delete after.
11. **Backup sweep**: optional but advised. The old tokens are revoked; the
    risk is enabling forensic forensics if a backup is exfiltrated.
12. **iTerm2 scrollback**: clear any windows that ran the leaking commands.

## Fix options (architectural)

These solve the same underlying problem. Pick one before relaunching MCP.

### Option 1 — Replace `mcp-remote` with GitHub's official MCP server (recommended for github)

GitHub publishes a stdio MCP server that reads `GITHUB_PERSONAL_ACCESS_TOKEN`
from env (no argv). It's a binary released to GitHub Releases and is also
distributed as a Docker image.

- Pros: env-only auth (clean), maintained by GitHub, no dependency on a
  third-party bridge.
- Cons: the toolset filtering via `X-MCP-Toolsets` header is specific to
  GitHub's hosted Copilot MCP endpoint. The local server may expose a
  different toolset that needs to be re-curated. Verify before adopting.
- Cloudflare has no equivalent first-party stdio server today (they own the
  remote MCP, not a stdio bridge). Option 1 doesn't help Cloudflare.

### Option 2 — Custom in-repo Node bridge that reads token from env

Write a ~30-line Node script:
- reads `Authorization: Bearer ${GITHUB_PAT}` from env at startup
- speaks stdio MCP to its parent
- forwards to the upstream HTTP MCP endpoint with the header injected
  internally

This is essentially a re-implementation of `mcp-remote` minus the argv-only
header path. Maintenance: small, self-contained, version-pinned in repo.
Works for both GitHub and Cloudflare.

### Option 3 — Patch / fork `mcp-remote` upstream to accept `--header-from-env`

Send a PR to `geelen/mcp-remote` adding `--header-from-env Name=ENVVAR`. If
accepted, pin the new version. Until accepted, vendor a fork and pin to the
fork's tag.

- Pros: one-line install, benefits the broader MCP ecosystem.
- Cons: depends on upstream review velocity; worst-case requires maintaining
  a fork.

### Option 4 — Local socat / proxy that injects the header

Run a localhost-only HTTP proxy that injects the Authorization header for
matching upstreams; point `mcp-remote` at the proxy with no header in argv.

- Pros: language-neutral.
- Cons: heavier than Option 2, adds a long-running listener, more attack
  surface.

**Recommendation:** Option 2 (custom Node bridge) is the lowest-risk,
in-repo, env-auth path that covers both GitHub and Cloudflare without
upstream dependencies. Option 1 is appealing for GitHub specifically but
doesn't generalize.

## Verification (post-fix)

```bash
# 1. No token in argv anywhere.
pgrep -fl "mcp-remote\|mcp-bridge" | grep -E "github_pat_|sk-|cf_|Bearer " \
  && echo "LEAKED" || echo "CLEAN"

# 2. ng-doctor still passes (MCP wrappers still resolve).
ng-doctor tools

# 3. End-to-end smoke test — per docs/github-mcp.md:
( printf '{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0.0.0"}}}\n'
  printf '{"jsonrpc":"2.0","method":"notifications/initialized"}\n'
  printf '{"jsonrpc":"2.0","id":1,"method":"tools/list"}\n'
  sleep 8
) | ~/.local/bin/mcp-github-server 2>/tmp/w.err >/tmp/w.out
echo "stderr: $(wc -c < /tmp/w.err) bytes"   # expect 0
jq -cs 'map(select(.id==1)) | .[0].result.tools | length' /tmp/w.out
rm /tmp/w.err /tmp/w.out
```

## Out of scope for this incident (track separately)

- Audit `mcp-cloudflare-server` for the same fix; pair-rotate.
- Update `docs/github-mcp.md` and `docs/cloudflare-mcp.md` with the new
  wrapper architecture once chosen.
- Update `docs/secrets.md` with a new principle: "Never pass secrets via
  argv; not even briefly. Argv is observable for the lifetime of the
  process by every local subject."
- Add an `ng-doctor` check that scans live `mcp-*` processes for tokens in
  argv and fails on detection.
- Audit other launchers in the repo for the same antipattern (the four
  non-mcp-remote wrappers above are clean per current read; re-verify after
  any change).

## References

- [`docs/secrets.md`](./secrets.md) — secret-handling policy
- [`docs/mcp-config.md`](./mcp-config.md) — MCP framework
- [`docs/github-mcp.md`](./github-mcp.md) — GitHub MCP integration; PAT
  scopes and rotation procedure
- [`docs/cloudflare-mcp.md`](./cloudflare-mcp.md) — Cloudflare MCP
  integration
- Wrapper template: `home/dot_local/bin/executable_mcp-github-server.tmpl`
- Wrapper template: `home/dot_local/bin/executable_mcp-cloudflare-server.tmpl`
- mcp-remote upstream: https://github.com/geelen/mcp-remote
