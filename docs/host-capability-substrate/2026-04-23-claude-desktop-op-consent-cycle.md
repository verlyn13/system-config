---
title: Claude Desktop × 1Password MCP Consent Cycle — Field Report
category: report
component: host_capability_substrate
status: informational
version: 1.0.0
last_updated: 2026-04-23
tags: [mcp, claude-desktop, 1password, op, tcc, consent, argv-leak, substrate, adapter, auth, electron, gui-host, field-report]
priority: high
---

# Claude Desktop × 1Password MCP Consent Cycle — Field Report

Status: **informational**. Not an ADR — no decision binding follows from this document. This is a forensic record of a concrete production-environment observation made on 2026-04-23, preserved to inform the substrate's MCP adapter design under real conditions.

Audience: downstream agents (GPT-5.4-class, Opus-4.7-class) picking up this investigation, and human operators who will eventually implement the substrate's MCP auth adapter.

Related surfaces:

- [`implementation-charter.md`](./implementation-charter.md) — the substrate's binding invariants
- [`tooling-surface-matrix.md`](./tooling-surface-matrix.md) — per-host capability + sync target posture
- [`../mcp-config.md`](../mcp-config.md) — current user-level MCP framework
- [`../secrets.md`](../secrets.md) — 1Password integration policy
- [`../github-mcp.md`](../github-mcp.md) — GitHub MCP wrapper specifics (same pattern as cloudflare)

## Synopsis

On 2026-04-23, Claude Desktop (`com.anthropic.claudefordesktop`, v1.3883.0) was added as the sixth sync target for the user-level MCP baseline via commit `946a058`. The baseline includes five stdio wrappers (`mcp-brave-search-server`, `mcp-firecrawl-server`, `mcp-runpod-server`, `mcp-cloudflare-server`, `mcp-github-server`) that call `op read` against a desktop-app-integrated 1Password account at child-process startup. On next Claude Desktop launch, a self-sustaining prompt cycle began: macOS surfaced "bash would like to access data from other apps" repeatedly; user approvals did not terminate the cycle; Claude Desktop eventually crashed, leaving an orphaned Electron crashpad handler as residue. The pattern exposes a class of friction that is invisible to terminal-hosted MCP clients (Claude Code CLI, Codex CLI, Cursor) but is unavoidable under GUI-hosted MCP clients with the current wrapper design. A secondary finding — static bearer tokens leak into argv via `mcp-remote --header` — was surfaced during process inspection and is pre-existing, not caused by the Claude Desktop addition, but the new sync amplifies exposure.

## Timeline

All times local (America/Anchorage, Homer, Alaska).

| Time | Event | Evidence |
|---|---|---|
| 2026-04-23 morning | Cloudflare MCP wired into baseline (commits `826d553`, `9210aae`) | Five stdio wrappers now call `op read`: brave-search, firecrawl, runpod, cloudflare, github |
| 2026-04-23 14:39:01 | `claude_desktop_config.json` backed up prior to sync (`...bak-20260423-143901`) | `ls -la ~/Library/Application Support/Claude/claude_desktop_config.json.bak-*` |
| 2026-04-23 14:39 | `scripts/sync-mcp.sh` writes 10-server `mcpServers` block to Claude Desktop config for the first time; `globalShortcut` and `preferences` preserved | Commit `946a058` |
| 2026-04-23 14:41+ | User launches Claude Desktop; macOS begins surfacing "bash would like to access data from other apps" repeatedly | User-reported |
| 2026-04-23 ~15:48 | Claude Desktop main process exits (not in `ps` at time of investigation); orphaned `chrome_crashpad_handler` for Claude.app remains, elapsed 13:14 at investigation time 16:01 | `ps -eo pid,ppid,etime,args` shows only crashpad at PID 47843, parent reparented to launchd (ppid=1) |
| 2026-04-23 16:01 | Investigation begins; system state captured | See §Evidence catalog |

## What the user observed

Direct user description:

1. A macOS notification repeatedly appears: **"bash would like to access data from other apps."**
2. Pressing **Allow** triggers a 1Password prompt for credentials (biometric / password unlock).
3. Authenticating to 1Password does not stop the cycle; the "bash would like to access" notification reappears.
4. The cycle started immediately after the Claude Desktop MCP sync went live.

User correctly identified the connection to the substrate plane before any diagnostic action was taken and requested investigation without remediation.

## What system inspection showed

### Claude Desktop process state (confirmed)

At 2026-04-23 16:01 local:

- **No** `/Applications/Claude.app/Contents/MacOS/Claude` process running. Main Claude Desktop process has exited.
- **One orphaned** `chrome_crashpad_handler` for Claude.app at PID 47843, parent PID 1 (reparented to launchd after the main process died), elapsed 13:14. This is Electron's crash-reporting sidecar; it outlives its parent when the parent exits uncleanly.
- **Two** `chrome-native-host` helpers from Claude.app's Contents/Helpers, parented by Google Chrome (PID 9523). These handle the Chrome extension bridge for Claude.ai; unrelated to MCP.

Annotated `ps` evidence:

```text
47843     1    13:14 /Applications/Claude.app/Contents/Frameworks/Electron Framework.framework/Helpers/
                     chrome_crashpad_handler
                     --database=/Users/verlyn13/Library/Application Support/Claude/Crashpad
                     --annotation=_productName=Claude --annotation=_version=1.3883.0
                     --annotation=prod=Electron --annotation=ver=41.2.0
```

Interpretation: Claude.app launched, attempted MCP bringup, hit the consent cycle, and eventually died ungracefully. The crashpad handler's survival is diagnostic for an abnormal exit path (SIGKILL by OS, unhandled renderer crash, or similar).

### Other MCP-hosting clients at the same moment (confirmed)

Three non-Claude-Desktop MCP clients were simultaneously running:

| PPID | Parent process | MCP children observed |
|---|---|---|
| 13821 | `claude` (Claude Code CLI, PID 13821, parent 4911) | memory, sequential-thinking, brave-search, runpod, github-via-mcp-remote |
| 8378 | `claude` (Claude Code CLI, PID 8378, parent 4953) | memory, sequential-thinking, brave-search, runpod, github-via-mcp-remote |
| 11695 | `codex` (OpenAI Codex CLI, parent 11693) | memory, sequential-thinking, brave-search, runpod |

None of these terminal-hosted clients experienced the consent cycle. They all use the same five op-calling wrappers. The differentiator is their parent app, not their MCP child set.

### `op daemon` proliferation (confirmed)

Count of `op daemon` processes at inspection time: **10**.

```text
count: 10
```

Normal steady-state under healthy integration is 1–2 daemons (one per active integration session; they are shared across recent `op` invocations). Ten concurrent daemons indicates **each attempted `op read` spawned its own integration handshake without consolidating**, which is consistent with the prompt cycle: every new bash-wrapper process initiated a fresh authentication attempt, piled up the daemon count, and left them uncleanly terminated when the parent wrapper was killed by Claude Desktop's timeout.

### Argv token leakage — observed (confirmed, pre-existing)

`ps -eo pid,args` at inspection time revealed the GitHub PAT plaintext in the command line of `mcp-remote` child processes:

```text
13925 13821 npm exec mcp-remote@0.1.38 https://api.githubcopilot.com/mcp/ \
            --transport http-only --silent \
            --header Authorization: Bearer <REDACTED_FINE_GRAINED_PAT> \
            --header X-MCP-Toolsets: context,repos,issues,...
```

Processes currently leaking the PAT: **4** (two `npm exec` wrappers, two `node .../mcp-remote`, reflecting two Claude Code CLI sessions).

This is **not** caused by the Claude Desktop sync. The leak is inherent to `mcp-remote`'s interface: it accepts `--header` flags for auth. Any header passed that way becomes argv, and argv is world-readable for same-user processes via `ps`. The pattern exists for both the github wrapper (long-standing) and the cloudflare wrapper (added 2026-04-23).

`--silent` **does not** fix this — it only suppresses mcp-remote's own stderr logging. It has no effect on the argv the OS presents to `ps`.

### Recent 1P consent dialog log — not found (limitation)

`log show --last 30m` with predicates for `com.apple.TCC` and 1Password subsystems returned no matching entries. Either:

- 1Password's consent dialog is implemented outside Apple's TCC subsystem (as a private in-app XPC flow; the user prompt is rendered by 1Password itself, not by `tccd`), OR
- macOS's unified logging subsystem requires different predicates to surface these events.

The user's dialog phrasing ("**bash** would like to access data from other apps") is consistent with **1Password's own cross-app-access consent UI** (per 1Password's documentation of the CLI desktop-app integration), not with standard macOS TCC prompts (which phrase as "`<App>` would like to access `<resource>`"). This supports the in-app-XPC hypothesis.

### macOS TCC database — inaccessible (limitation)

Reading `~/Library/Application Support/com.apple.TCC/TCC.db` directly failed:

```text
Error: unable to open database "…/TCC.db": unable to open database file
```

This is expected under macOS: only processes with Full Disk Access can read TCC.db. Our investigation shell lacks that entitlement. Content is not available for the substrate's purposes without elevating permissions, which is intentionally out of scope.

## Mechanism — 1Password's per-parent-app consent model

### How `op` resolves secrets against a desktop-app-integrated account

The `op` CLI at `/opt/homebrew/bin/op` (installed version 2.32.1, macOS aarch64), when run against an account whose sign-in is backed by the 1Password desktop app (`my.1password.com` with "biometric unlock via desktop app integration" enabled), does the following at each `op read` invocation:

1. Opens the Unix domain socket at `$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` (the IPC path for CLI↔desktop-app integration). Observed via `lsof | grep 2BUA8C4S2C.com.1password`.
2. Presents a caller-identity attestation. This is believed to include the calling binary path, code signature, and the parent process identity (the app that launched `op`).
3. The 1Password desktop app checks its internal consent store: "is this `(calling-binary, parent-app)` pair approved?"
4. If unapproved: the desktop app surfaces a consent dialog to the user — phrased as **"`<calling-binary>` would like to access data from other apps"** — and optionally a biometric/password prompt.
5. If approved: `op` receives a decrypted item reference and returns the requested field value over stdout.

The **consent scope is the tuple, not just the binary**. This is the central mechanism behind today's observation.

Evidence for tuple-scoping (hypothesized mechanism, empirically consistent):

- Same `/bin/bash` binary under Terminal.app / iTerm2.app has been approved during prior interactive use — no prompts when Claude Code CLI / Codex CLI / Cursor invoke the wrappers.
- Same `/bin/bash` binary under Claude.app's process tree triggers the prompt — consent has not been previously granted for this parent-app scope.

This is **hypothesized**; confirming requires inspecting 1Password's internal consent store format (likely under `~/Library/Group Containers/2BUA8C4S2C.com.1password/Library/Application Support/1Password/Data/1password.sqlite` — but the schema is not documented).

### What terminal-hosted MCP clients get for free

Claude Code CLI, Codex CLI, and Cursor (when launched via iTerm2 or similar) inherit the following consent chain:

1. iTerm2 was previously granted permission to launch bash / zsh (normal macOS behavior; implicit at app install time for terminal emulators).
2. The user has previously run `op` interactively in a terminal-hosted shell session. 1Password prompted "bash would like to access data from other apps" once during that session; user approved.
3. 1Password stored a consent record for the tuple `(bash under Terminal-class parents, approved)`.
4. All subsequent bash wrapper executions under terminal parents inherit that grant.

Under this model, auth-required MCP wrappers that call `op read` are effectively zero-touch for terminal clients — their consent was pre-warmed by ordinary developer use before MCP was ever wired.

### What Claude Desktop gets instead

1. Claude.app has never been the parent of any bash process that called `op` before today (at least for this user). No consent grant exists for the tuple `(bash under Claude.app, ?)`.
2. At MCP bringup, Claude.app spawns five bash wrappers in quick succession. Each is the first bash-under-Claude.app invocation in its own sense.
3. Each invocation triggers a distinct consent prompt because 1Password's consent cache entry, at best, is keyed per-tuple-per-bash-PID (worst case) or per-tuple-per-parent-PID (better case) — but either way, five concurrent new bash PIDs under the same parent app generate five prompts.
4. Even after approval, each wrapper's `op read` has its own timing window that interacts with Claude Desktop's per-child init timeout (see below).

## Mechanism — Claude Desktop's MCP child lifecycle

### Spawn-on-config-load semantics

Claude Desktop reads `~/Library/Application Support/Claude/claude_desktop_config.json` at launch. For each entry in `mcpServers`, it:

1. Resolves `command` on PATH (PATH is inherited from an Electron-enriched parent environment; not the minimal launchd PATH the main Claude Desktop process itself receives — see [investigation artifact: Electron PATH enrichment](#evidence-electron-path-enrichment)).
2. Forks a child with that command + args + env.
3. Attempts an MCP initialize handshake over the child's stdio.
4. If initialize does not complete within the client's timeout, kills the child and marks the server unavailable.

Empirically, Claude Desktop appears to **respawn** the child after kill — not just mark it failed. This is consistent with the user-observed behavior that prompts keep coming after each approval; if the child were marked failed-permanently after one timeout, the prompt for that server would occur exactly once. Instead, approvals are followed by new prompts for the same binary — strong signal that respawn is happening.

### Initialize timeout window

Electron-hosted MCP clients in the 2025Q4–2026Q1 cohort (Claude Desktop, Cursor's Electron variants, VS Code's MCP) typically impose a 15–30s per-server initialize timeout.

**Hypothesized, not confirmed for Claude Desktop 1.3883.0.** The exact timeout value for Claude Desktop 1.3883.0 is not documented publicly; it is believed to be in this range based on:

- Electron defaults for stdio-based IPC initialization
- Observed behavior: user approvals come faster than 30s (per subjective user timing) but the cycle continues, suggesting that **approval alone is insufficient** — the wrapper also needs to complete `op read` + `exec npx` + mcp-remote initialization before the timeout fires. Cold-start `op read` under fresh biometric unlock has been observed at ~9s in this same system (see [§Evidence — op cold-start latency](#evidence--op-cold-start-latency)); cold-start `npx` resolution for an unknown package typically adds 2–10s.

Confirming the timeout value requires either Claude Desktop source access or instrumentation; both out of scope for this report.

### Kill-and-respawn cascade

The self-sustaining cycle operates as follows:

```
[t=0]    Claude Desktop launches. Reads claude_desktop_config.json with 10 servers.
[t≈1s]   Spawns 10 MCP children in parallel:
         - 5 stateless (memory, sequential-thinking, context7 via mcp-remote,
           runpod-docs via mcp-remote, cloudflare-docs via mcp-remote) — no op needed
         - 5 auth-required bash wrappers (brave-search, firecrawl, runpod,
           cloudflare, github) — each calls op read at startup

[t≈1s]   Five bash processes, all children of Claude.app, all trying op read.
         1Password sees 5 first-time-from-Claude.app invocations.
         Five "bash would like to access data from other apps" dialogs queue.

[t≈1–30s] User begins clicking through dialogs. Biometric unlock per approval.
         Each approval allows THAT bash PID to complete its op read and proceed
         to exec npx (or exec its stdio server). Typical elapsed time from
         spawn to successful initialize under cold op: ~15–30s.

[t≈30s]  Claude Desktop's initialize timeout fires on wrappers that haven't
         completed. Most likely victims: whichever two or three wrappers the
         user hasn't yet approved.
         Claude Desktop kills those children.
         Claude Desktop respawns replacement children (same command, new PID).

[t≈30s+] New bash PIDs enter 1Password's consent check. Even if the user
         already approved the prior PID under Claude.app, the consent grant's
         exact scope determines whether it carries over. Empirically it
         does NOT carry over — new prompts appear.

[t=∞]    Cycle sustains. User approves, wrappers respawn, new prompts,
         eventually Claude Desktop's renderer/main process crashes under
         accumulated timeout + IPC pressure, leaving an orphaned crashpad.
```

### Why approvals don't stop the cycle

Three hypotheses, all compatible with observation:

1. **Consent cache key includes child PID**, not just `(binary, parent-app)`. Every respawned bash has a new PID → new prompt. Weakly supported; most IPC consent systems key on (binary hash, parent binary hash) not on volatile PIDs, but 1Password's implementation is closed.

2. **Consent is granted but the wrapper still times out** before initialize completes, so Claude Desktop kills it. From the user's perspective the approval didn't "work" because the server never became available. New spawn fires new approval. Weakly supported (user said explicitly "allowing does not stop the cycle").

3. **Approval is granted at biometric-confirm, but the consent grant has a short TTL or a per-invocation semantic** that means each fresh bash call needs fresh biometric. Plausible and consistent with the "auth once per op call" security posture some users configure in 1Password.

These are not mutually exclusive. Further investigation would need to:

- Launch one wrapper directly from a Claude.app–equivalent context while instrumenting the 1P IPC socket
- Inspect 1Password's consent store schema for TTL and key structure
- Vary the `bypassBiometric` / similar 1P settings and observe

## Secondary finding — token leakage via argv

Pre-existing issue, surfaced during today's investigation but not caused by today's changes.

### Exact exec surface that leaks

In `home/dot_local/bin/executable_mcp-github-server.tmpl` (chezmoi-deployed to `~/.local/bin/mcp-github-server`):

```bash
exec npx -y "mcp-remote@${MCP_REMOTE_VERSION}" \
  "$REMOTE_URL" \
  --transport http-only \
  --silent \
  --header "Authorization: Bearer ${GITHUB_PAT}" \
  --header "X-MCP-Toolsets: ${TOOLSETS}"
```

Identical pattern in `home/dot_local/bin/executable_mcp-cloudflare-server.tmpl`:

```bash
exec npx -y "mcp-remote@${MCP_REMOTE_VERSION}" \
  "$REMOTE_URL" \
  --transport http-only \
  --silent \
  --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
```

After `exec`, the npx child (then the node child running mcp-remote) has these args in its argv. `argv` is exposed via `ps -eo args` to any process running as the same UID. The token is plaintext in the shell process's proc table entry for the lifetime of the mcp-remote child (which is the lifetime of the MCP session).

### Why `--silent` does not help

`--silent` suppresses mcp-remote's **own stderr** output — the `Using custom headers: {"Authorization":"Bearer …"}` line that mcp-remote otherwise logs at startup. This was load-bearing for preventing token leakage into **host-managed log files** (the MCP client that invokes the stdio wrapper often pipes child stderr to a log).

`--silent` has **no effect on argv**. The OS presents argv to any process that asks. `ps`, `/proc/<pid>/cmdline` on Linux, `/proc/<pid>/psinfo` on Solaris, and on macOS the `sysctl kern.procargs2` interface all bypass the process's own output controls.

### Who's exposed, when

Exposure window: from the moment the wrapper execs `npx` (which inherits and advertises the argv) until the mcp-remote child dies. For active MCP sessions, this is the lifetime of the MCP client session — hours to days under normal usage.

Threat model: any process running as the same macOS user can `ps -eo args` and read the token. This includes:

- Any npm package with a postinstall script that runs `ps`
- Any Python / Node library used in a project that happens to enumerate processes
- Any malicious code in a repo that is opened in an editor that spawns language servers

The user was not previously aware of this exposure. It was noticed incidentally during investigation because `ps` output in one of the diagnostic commands happened to include the PAT.

### What the substrate must do about it

The substrate, when it takes over MCP auth, must either:

- Hold bearers in process memory and add them as HTTP headers when forwarding requests (never pass token through child args or env), OR
- If the substrate spawns helper processes, use file-descriptor passing or a local authenticated socket to deliver secrets to children, never argv or env.

## Implications for the HCS substrate

Three structural requirements this field observation raises for the substrate's MCP adapter design:

### Requirement 1 — centralized auth broker, not per-wrapper op calls

**Problem.** Today's pattern: each wrapper calls `op read` at its own startup. This scales badly in two directions:

- **Under GUI MCP hosts:** per-parent-app consent is non-shared across N concurrent wrappers → prompt storm → timeout cascade → crash.
- **Under terminal hosts:** N concurrent wrappers each pay 1–9s cold-start latency against `op`; MCP init is slow on cold launches (observed: 5 stdio wrappers × ~1s each = 5s added to shell agent startup).

**Substrate-side fix.** A single long-lived substrate daemon holds warm-cached credentials. MCP child processes (for backward-compatible clients) connect to the substrate over an authenticated local socket (UDS or localhost TCP with a per-session token) and receive either: (a) the resolved secret, or (b) the result of a capability call that needs the secret, without ever seeing the secret itself.

With the substrate as broker:

- 1Password's consent is granted **once to the substrate binary**, not once-per-wrapper-per-parent-app. The substrate is the only thing that talks to `op`. All MCP children are wrappers around a substrate client library that uses the local socket.
- Terminal and GUI MCP hosts behave identically from the consent-model perspective.
- Cold-start latency for secrets becomes zero after the substrate's first warm-up.

### Requirement 2 — tokens never cross a process boundary as argv

**Problem.** Today's wrapper exec's mcp-remote with `--header "Authorization: Bearer <token>"`. The token is in argv. World-readable to same-user processes.

**Substrate-side fix.** The substrate is itself the HTTP client for remote MCP servers that need bearer auth. The bearer never leaves the substrate's process memory. The MCP adapter surface exposed to clients is a stdio proxy that forwards protocol traffic without touching the auth layer — or the substrate is the direct remote MCP client and exposes results via its own adapter.

Concretely: the substrate replaces `mcp-remote` as the stdio-HTTP bridge for authenticated remote MCP servers. When a client asks for a "github" MCP session, the substrate opens the HTTPS connection, adds the Authorization header from its own memory, and streams protocol traffic between client stdio and the remote HTTP server. No child process sees the token.

### Requirement 3 — host-adapter lifecycle awareness

**Problem.** Today's sync writes the same `command` string to every host config. Host-specific respawn semantics are invisible to the sync layer. GUI hosts' aggressive respawn + per-parent-app consent = cascade; terminal hosts' persistent children = no problem.

**Substrate-side fix.** The substrate adapter layer (not the sync layer) owns host-specific wiring. For each supported host:

- Generate a stable, minimal stdio proxy binary that Claude Desktop / Cursor / Claude Code CLI / Codex CLI all point at.
- The proxy binary does one thing: connect to the substrate's local socket, relay stdio ↔ socket frames, die cleanly on EOF.
- The substrate owns lifecycle semantics per-host: long-lived connection that survives a client respawn; reuses an already-warm MCP session for that capability; surfaces clean errors to hosts that need them without incurring re-consent prompts.

This inverts today's model: instead of many per-capability wrappers (one per MCP server), there's **one proxy wrapper per host, which connects to the substrate for all capabilities**.

## Impact on the current system

### What is currently broken

- Claude Desktop launch → MCP bringup → consent cycle → eventual crash.
- Claude Desktop is the only sync target exhibiting this failure mode. All five other hosts (Claude Code CLI, Codex CLI, Cursor, Windsurf, Copilot CLI) operate normally.

### What is currently fine

- Commit `946a058` (adding Claude Desktop as sync target) can remain; it is a correctly-formed write to a correctly-identified config file with correctly-preserved app-managed sibling keys. The fault is not in the config write; it is in the runtime interaction with 1Password's consent model.
- The terminal-hosted MCP clients are unaffected and continue to serve as the primary day-to-day MCP surface.
- Claude Desktop's non-MCP functionality (chat, conversation UI) is unaffected — the user can continue using Claude Desktop for non-MCP work if they tolerate the prompt cycle on startup, or they can disable MCP in Claude Desktop via the Connectors UI while this is resolved, or they can revert today's Claude Desktop config change.

### What is exposed (secondary)

- GitHub PAT in argv: visible in `ps` for any process same-user owned, for the lifetime of the mcp-remote child. Exposed now; was also exposed before today; was not known to the user before today.
- Cloudflare token in argv: same pattern; same threat model. Current token has 30-day TTL and is intentionally over-permissive for build-out (see `op://Dev/cloudflare-mcp-jefahnierocks`), so the exposure window is bounded.

## Evidence catalog

### Evidence — current process inventory

```
claude.app main:            NOT RUNNING
claude.app crashpad:        PID 47843, ppid=1, elapsed 13:14
                            — indicates uncontrolled exit of main process

claude code CLI instances:  PID 4911 (parent of MCP ppid 13821)
                            PID 4953 (parent of MCP ppid 8378)
codex CLI instance:         parent of MCP ppid 11695

op daemon instances:        10 concurrent (normal steady-state: 1–2)

processes exposing github PAT via argv:  4
                            (2x npm exec mcp-remote, 2x node .../mcp-remote)
```

### Evidence — Electron PATH enrichment

```
Claude.app main process PATH:
  /usr/bin:/bin:/usr/sbin:/sbin       (minimal; inherited from launchd)

Claude.app MCP child (memory) PATH:
  /usr/local/bin:/opt/homebrew/bin:/Users/verlyn13/.cargo/bin:
  /Users/verlyn13/.bun/bin:/Users/verlyn13/Library/pnpm:
  /Users/verlyn13/.local/bin:/Users/verlyn13/bin:
  /Users/verlyn13/.local/share/mise/shims:/Users/verlyn13/.orbstack/bin:
  /usr/bin:/bin:/usr/sbin:/sbin
```

Mechanism: Claude Desktop's Electron runtime (known to use one of `fix-path` / `shell-path` npm packages or equivalent) invokes the user's login shell with `-ilc 'echo $PATH'` at app startup and uses the result when spawning MCP children. This is why `op`, `npx`, mise shims, and our `~/.local/bin/mcp-*-server` wrappers all resolve correctly despite Claude Desktop's main process having a minimal launchd PATH. Confirmed by comparing main-process and child-process PATH output via `ps -E`.

### Evidence — op cold-start latency

```
$ time op read --account my.1password.com 'op://Dev/cloudflare-mcp-jefahnierocks/token' >/dev/null
op read ... > /dev/null   0.04s user 0.04s system 0% cpu 8.964 total
```

Total wall-clock on a cold / newly-unlocked 1P CLI integration session: ~9 seconds. This is the cost of establishing the IPC socket, biometric unlock, vault decrypt, and returning a single field value. On a warm session, total is <100ms.

This matters for the timeout-respawn cascade: even after the consent prompt is approved, the wrapper has to pay ~9s before it can `exec npx` and begin MCP initialize. Combined with `npx` package resolution cold-start (another few seconds), total time-from-spawn-to-MCP-initialized-handshake is well inside the typical 15–30s Electron timeout window.

### Evidence — 1Password group container IPC sockets

```
1Password  1194  …/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
1Password  1194  …/Library/Group Containers/2BUA8C4S2C.com.1password/t/s.sock
1Password  1194  …/Library/Application Support/1Password/Data/1password.sqlite
```

The `agent.sock` is the SSH agent surface. The `s.sock` is the integration/CLI surface — this is what `op` talks to for vault access against a desktop-integrated account. The 1password.sqlite is the local encrypted store; the consent cache is likely stored in it (unconfirmed; schema is not documented).

## Confirmed vs hypothesized

### Confirmed (direct observation or causal proof in today's investigation)

- Claude Desktop was newly added as an MCP sync target today (commit `946a058`).
- Claude Desktop's config file has been written correctly, with all non-MCP keys preserved (verified via `jq`).
- Claude Desktop process is not currently running; only an orphaned crashpad handler remains.
- Ten `op daemon` processes are concurrently running (`ps | grep op daemon | wc -l` = 10).
- GitHub PAT is visible in `ps -eo args` output for running `mcp-remote` children (4 processes).
- Terminal-hosted MCP clients (Claude Code CLI, Codex CLI) are running with no consent-prompt issue against the same five op-calling wrappers.
- Electron enriches child PATH from login-shell; main-process PATH is minimal.
- `op read` cold start takes ~9s wall-clock on this system.
- `--silent` does NOT suppress argv; verified by running `op read` into `ps` and inspecting live `mcp-remote` children.
- TCC.db is not readable without Full Disk Access; diagnostic elevation is out of scope.

### Hypothesized (consistent with observation, not directly proven)

- 1Password's consent is tuple-scoped on `(calling-binary, parent-app)`, not just binary. Terminal-hosted approvals don't extend to Claude-Desktop-hosted invocations, so the substrate has to treat them as separate consent planes. **How to confirm:** inspect 1password.sqlite schema; or craft a controlled-environment reproduction where the same bash binary is invoked from two different GUI parents with known-separate consent states.
- Claude Desktop enforces a 15–30s per-MCP-server initialize timeout. **How to confirm:** strings-dump Claude Desktop's app.asar for timeout constants; or instrument an MCP server that delays responding to `initialize` and measure time-to-kill.
- Claude Desktop respawns killed MCP children. **How to confirm:** stop approving prompts; instrument a wrapper to log every startup with a timestamp and PID; observe whether new PIDs for the same server keep appearing.
- Claude Desktop's main process crashes as a secondary effect of accumulated timeouts + IPC pressure. **How to confirm:** parse the Electron crash dump left by the crashpad handler (at `~/Library/Application Support/Claude/Crashpad`); look for OOM, assertion, or renderer-kill signatures.
- Consent grants have a per-invocation or short-TTL semantic under 1Password's "require biometric unlock on every CLI access" setting. **How to confirm:** vary the user's 1Password biometric requirement setting and observe whether the cycle changes.

### Limitations / not investigated

- macOS unified log querying for the exact consent dialog event was unsuccessful; different predicates may surface it. Worth a later pass.
- 1Password's consent store schema is not documented and was not decoded.
- Claude Desktop's `app.asar` was not introspected for MCP lifecycle source. Doing so would be dispositive for several hypothesized items above.
- Claude Desktop's renderer crashpad dump was not parsed; it would reveal the exact failure mode of the main-process crash.

## Reproduction recipe

Use these to confirm the diagnosis, or to verify any future fix.

### Minimum viable reproduction (destructive — will trigger prompt storm)

```bash
# 0. Pre-reqs: 1Password desktop app integration enabled; at least one
#    op-calling wrapper configured in Claude Desktop's mcpServers block;
#    user has NOT previously approved "bash" consent under Claude.app.

# 1. Fully quit Claude Desktop and ensure no Claude.app processes remain:
pkill -TERM -f '/Applications/Claude.app/'
sleep 2
pgrep -fl 'Claude.app' && echo "still running — kill manually" || echo "clean"

# 2. (Optional) revoke prior consent for bash under Claude.app, if present.
#    Note: 1Password's consent store schema is closed; revocation is
#    currently only possible via the 1Password app UI → Developer settings.

# 3. Launch Claude Desktop:
open -a Claude

# 4. Observe: multiple "bash would like to access data from other apps"
#    dialogs queue. Approving them does not stop subsequent dialogs from
#    appearing within the same Claude Desktop session.
```

### Observation commands (non-destructive)

```bash
# Process state (count of op daemons, crashpad residue, live Claude.app procs)
ps -eo pid,ppid,etime,args | grep -E "op daemon|/Claude|crashpad" | grep -v grep

# Argv token leakage check (4 processes exposing PAT today)
ps -eo pid,args | grep -E "Authorization: Bearer" | grep -v grep | wc -l

# Electron PATH enrichment (compare main vs child PATH)
CLAUDE_PID=$(pgrep -f '/Applications/Claude.app/Contents/MacOS/Claude$' | head -1)
ps -E -p "$CLAUDE_PID" | tr ' ' '\n' | grep ^PATH=
MCP_PID=$(pgrep -f "server-memory" | head -1)
ps -E -p "$MCP_PID" | tr ' ' '\n' | grep ^PATH=

# 1P cold-start latency
time op read --account my.1password.com 'op://Dev/<any-item>/<field>' >/dev/null

# op integration sockets
lsof 2>/dev/null | grep -i "2BUA8C4S2C.com.1password"

# Orphaned crashpad residue after a crash
ps -eo pid,ppid,etime,args | grep crashpad | grep -i claude
```

### Instrumenting a wrapper for lifecycle observation

Temporary patch to `~/.local/bin/mcp-cloudflare-server` to log each invocation:

```bash
#!/usr/bin/env bash
# INSTRUMENTED — do not commit
LOGFILE="$HOME/tmp/mcp-cloudflare-lifecycle.log"
mkdir -p "$(dirname "$LOGFILE")"
printf '%s pid=%d ppid=%d parent=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$$" "$PPID" \
    "$(ps -o command= -p "$PPID" 2>/dev/null | head -c 80)" \
    >> "$LOGFILE"

# …original wrapper body below…
```

Tail `~/tmp/mcp-cloudflare-lifecycle.log` during Claude Desktop launch to observe respawn rate, parent PID changes, and per-invocation timing.

## What NOT to attempt (and why each fails)

### Do not remove Claude Desktop from the sync target

Removing it hides the signal without resolving the class. The substrate has to support GUI-hosted MCP clients eventually; understanding this failure mode now is more valuable than avoiding it.

### Do not replace `op read` with `op run --env-file` inside wrappers

`op run --env-file=$HOME/.config/mcp/common.env -- <tool>` resolves all secrets once and injects as env. This works great for terminal launches where the user runs `op run -- claude` manually. It does NOT work for GUI-launched children, because:

- Claude Desktop does not launch MCP children through a user shell where `op run` could be the launcher.
- You can't make Claude Desktop itself launch under `op run` (Finder / Spotlight / Dock launches bypass shell wrappers).
- Even if you wrapped the entire Claude.app in `op run`, Electron's own PATH-enrichment shell invocation would happen before your `op run`'s env reached MCP children, because Electron runs the shell fresh per-spawn.

### Do not add `op` to 1Password's "don't prompt me" allowlist

This would suppress the dialog but does NOT resolve the underlying timeout-respawn cascade. If the respawn hypothesis is correct, wrappers would still time out under cold `op` sessions and Claude Desktop would still crash, just silently. Also, it removes the security signal — not just a UX irritant but a useful boundary.

### Do not switch wrappers to env-var-only auth (drop the `op read` fallback)

This would require launching Claude Desktop from a shell with the env pre-populated by `op run --env-file` — which is a manual, error-prone launch flow that loses the one-click GUI experience. And the argv leak via mcp-remote `--header` would still exist: env-sourced tokens still end up in argv once they're passed to mcp-remote.

### Do not move to Claude Desktop's native Connectors UI instead of file-based config

The Connectors UI works for individual users clicking through setup, but:

- It doesn't support the same set of servers (no wrapper-mediated stdio).
- It doesn't propagate across machines via chezmoi.
- It doesn't integrate with the substrate's eventual broker model.
- It's not programmatically manageable.

The file-based config is the right long-term surface; today's issue is a runtime-auth-model issue, not a config-surface issue.

## Open questions for further investigation

Listed in rough priority order for information value:

1. **What exactly is 1Password's consent-cache key?** Inspect `1password.sqlite` schema (requires reverse-engineering; not officially documented). Key question: is it keyed on (binary path, parent-app bundle ID), (binary code-signature, parent code-signature), or something time-bounded? This determines whether the substrate-as-broker approach fully resolves the cycle or only reduces frequency.

2. **What is Claude Desktop 1.3883.0's MCP initialize timeout?** Strings-dump `~/Applications/Claude.app/Contents/Resources/app.asar` (after extracting; `asar extract` tool from npm). Search for timeout-related constants. Determines whether a faster-starting substrate proxy would avoid the cascade without architectural change.

3. **Does Claude Desktop's MCP client send `notifications/cancelled` before killing a child?** This would give the substrate's proxy binary a clean shutdown signal. Packet-capture on a stdio pipe is non-trivial; easier to instrument the wrapper to log all stdin frames.

4. **What's in the Claude Desktop crash dump from today's session?** At `~/Library/Application Support/Claude/Crashpad/pending/<uuid>.dmp` (most likely). Parse with `minidump_stackwalk` or similar. Determines whether the crash is MCP-related (renderer OOM, assertion) or coincidental.

5. **Can a minimal stdio proxy completely replace mcp-remote for bearer-auth cases?** Write a ~100-line Node or Rust binary that accepts `--upstream-url` and `--upstream-auth-env`, reads the auth value from env at startup (never argv), and relays stdio to the HTTPS endpoint. Confirms the argv-leak is fixable without substrate-level changes.

6. **Does the 1P consent grant persist across Claude Desktop restarts, or only within a session?** Approve all five wrappers, verify Claude Desktop MCP is fully working, fully quit Claude Desktop, relaunch, observe whether prompts recur. Determines the short-term UX improvement available with a "grant once, tolerate it" flow.

7. **Under `op`'s "biometric unlock for every operation" setting, is per-wrapper biometric unlock required separately from 1Password's cross-app-access consent?** These are two independent prompts if so. Vary the 1Password app's biometric requirement setting and observe.

## Artifact references

### Source files touched today relevant to this cycle

| File | Role |
|---|---|
| `scripts/sync-mcp.sh` | Commit `946a058` added `sync_json_config "Claude Desktop"` call + `transform_for_claude_desktop` helper |
| `scripts/mcp-servers.json` | 10 baseline servers; 5 of which are op-calling wrappers |
| `home/dot_local/bin/executable_mcp-github-server.tmpl` | Wrapper that leaks PAT via argv; pre-existing |
| `home/dot_local/bin/executable_mcp-cloudflare-server.tmpl` | Same pattern, added 2026-04-23 |
| `home/dot_local/bin/executable_mcp-brave-search-server.tmpl` | op-calling wrapper; pre-existing |
| `home/dot_local/bin/executable_mcp-firecrawl-server.tmpl` | op-calling wrapper; pre-existing |
| `home/dot_local/bin/executable_mcp-runpod-server.tmpl` | op-calling wrapper; pre-existing |

### Runtime artifacts to preserve for further analysis

- `~/Library/Application Support/Claude/claude_desktop_config.json.bak-20260423-143901` — pre-sync config backup
- `~/Library/Application Support/Claude/claude_desktop_config.json` — current state; has 10 MCP servers
- `~/Library/Application Support/Claude/Crashpad/pending/*.dmp` — today's crash dumps (if Claude.app crashed after sync took effect)
- `~/Library/Logs/DiagnosticReports/Claude_*.crash` or similar — macOS crash log path for Electron apps
- `~/Library/Group Containers/2BUA8C4S2C.com.1password/Library/Application Support/1Password/Data/1password.sqlite` — 1Password consent store (encrypted; not directly queryable but observable by structure/size changes)

### Related reference docs

- [`../mcp-config.md`](../mcp-config.md) — current MCP framework; describes the sync model that introduced Claude Desktop as the 6th target
- [`../github-mcp.md`](../github-mcp.md) — original documentation of the stdio-via-`mcp-remote` wrapper pattern that first introduced the argv leak surface
- [`../secrets.md`](../secrets.md) — 1Password policy; establishes that secrets never persist in config files
- [`implementation-charter.md`](./implementation-charter.md) — binding invariants for the substrate; relevant for sizing the adapter auth requirement
- [`tooling-surface-matrix.md`](./tooling-surface-matrix.md) — per-host matrix; Claude Desktop row added as sync target today

## Change log

| Version | Date | Change |
|---|---|---|
| 1.0.0 | 2026-04-23 | Initial report, drafted the day of observation while process state was still live. |
