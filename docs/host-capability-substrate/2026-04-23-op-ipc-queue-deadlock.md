---
title: 1Password CLI IPC Queue Deadlock — Field Report
category: report
component: host_capability_substrate
status: informational
version: 1.0.0
last_updated: 2026-04-23
tags: [op, 1password, ipc, direnv, envrc, deadlock, queue, substrate, broker, field-report]
priority: high
---

# 1Password CLI IPC Queue Deadlock — Field Report

Status: **informational**. Not an ADR.

Audience: downstream agents (GPT-5.4-class, Opus-4.7-class) picking up this investigation, plus human operators designing the substrate's secret-broker component.

Companion / same-session sibling:
[`2026-04-23-claude-desktop-op-consent-cycle.md`](./2026-04-23-claude-desktop-op-consent-cycle.md). This report documents a **second surface** of the same underlying 1Password IPC fragility, observed under a different consumer (direnv `use op` + inline `op read` in a project's `.envrc`) and revealing a system-wide assumption that merits explicit documentation.

Related surfaces:

- [`implementation-charter.md`](./implementation-charter.md) — substrate invariants
- [`../secrets.md`](../secrets.md) — 1Password CLI policy
- [`../mcp-config.md`](../mcp-config.md) — MCP framework (shares the same IPC path)
- [`../project-conventions.md`](../project-conventions.md) — documented `.envrc` patterns using `use op`

## Synopsis

On 2026-04-23, while investigating the Claude Desktop MCP consent cycle documented in the companion report, the user's terminal session cd'd into `~/Repos/verlyn13/runpod-inference` and `direnv` emitted: `direnv: ([/opt/homebrew/bin/direnv export zsh]) is taking a while to execute. Use CTRL-C to give up.` The `direnv export` never completed. Investigation revealed that the `op` CLI's IPC path to the 1Password desktop app is effectively serialized for a given user session — one stuck `op` call blocks all subsequent calls, regardless of consumer. The queue had accumulated ~15 stuck `op` invocations over the session (my own `op whoami` diagnostic probe at the head, 45 minutes old; plus multiple MCP wrapper spawn attempts from Claude Code CLI / Cursor / Codex / Claude Desktop). The runpod-inference `.envrc`'s two synchronous `op` calls — `op vault get Dev` via the global `use_op` helper, and an inline `op read` for `RUNPOD_API_KEY` — joined the bottom of the deadlocked queue and never completed. This is a second instance of the same underlying fragility the first field report identified, expressed through a different surface (shell entry via direnv rather than MCP child startup). It strengthens the case for a substrate-side credential broker that replaces direct `op` IPC for all consumers.

## Timeline

All times local (America/Anchorage).

| Approx. elapsed | Event | Evidence |
|---|---|---|
| 45 min prior | Diagnostic probe issued `op whoami --account my.1password.com` in a background command; call entered 1P IPC queue and never returned | PID 98842, elapsed 45:01 at inspection |
| 24+ min prior | Cloudflare MCP audit probes `op item get cloudflare-mcp-jefahnierocks` × 2 from session investigation | PIDs 2986, 3684 |
| 18 min prior | First wave of MCP wrapper `op read` calls (5 wrappers) from client startup | PIDs 4424, 4495, 4497, 4520, 4524 |
| 14 min prior | Second wave of MCP wrapper `op read` calls (4 wrappers) | PIDs 7136, 7191, 7223, 7248 |
| 6 min prior | Earlier direnv attempt; `op vault get Dev` stuck | PID 11151 |
| 3 min prior | **User cd'd into `~/Repos/verlyn13/runpod-inference`**; direnv fired `.envrc`; `op vault get Dev` stuck | PID 12436, elapsed 3:09 at inspection |
| 0 | User reports the hang and asks for diagnosis | This session |

## What the user observed

Direct user observation:

```
~/Organizations/jefahnierocks/system-config main ?⇡
❯ cd ~/Repos/verlyn13/runpod-inference
direnv: ([/opt/homebrew/bin/direnv export zsh]) is taking a while to execute. Use CTRL-C to give up.
```

The prompt never returned until Ctrl-C. This differs from a normal cold-start `op` experience — which is slow (~9s) but completes — in that it did not complete.

## What system inspection showed

### The `op` process queue (confirmed)

```text
PID     ELAPSED   CMDLINE
98842   45:01     op whoami --account my.1password.com
2986    24:49     op item get cloudflare-mcp-jefahnierocks
3684    22:12     op item get cloudflare-mcp-jefahnierocks
4424    18:37     op read --account my.1password.com op://Dev/brave-search/api-key
4495    18:36     op read --account my.1password.com op://Dev/firecrawl/api-key
4497    18:36     op read --account my.1password.com op://Dev/runpod-api/api-key
4520    18:07     op read --account my.1password.com op://Dev/cloudflare-mcp-jefahnierocks/token
4524    18:06     op read --account my.1password.com op://Dev/github-mcp/token
7136    12:04     op read --account my.1password.com op://Dev/brave-search/api-key
7191    12:04     op read --account my.1password.com op://Dev/firecrawl/api-key
7223    12:01     op read --account my.1password.com op://Dev/cloudflare-mcp-jefahnierocks/token
7248    11:34     op read --account my.1password.com op://Dev/github-mcp/token
11151    6:11     op vault get Dev --account my.1password.com
12436    3:09     op vault get Dev --account my.1password.com   ← user's direnv
```

Plus ~10 `op daemon` processes accumulated (normal steady-state: 1–2).

### 1Password app state (confirmed)

- `/Applications/1Password.app/Contents/MacOS/1Password` PID 1194 is running (launched `--silent --just-updated --should-restart`), holding both IPC sockets open per `lsof`:
  ```text
  1Password 1194 verlyn13 24u unix .../2BUA8C4S2C.com.1password/t/s.sock
  1Password 1194 verlyn13 53u unix .../2BUA8C4S2C.com.1password/t/agent.sock
  ```
- The 1Password app is not crashed; its IPC sockets are still listening; but no `op` call in the queue is completing.

### Claim family — socket is alive, queue is stuck

This is the load-bearing empirical observation:

1. The IPC sockets exist (`lsof` confirms).
2. The 1Password app process is running.
3. New `op` calls connect (they don't error immediately with "socket not found").
4. But **none of the 15+ queued `op` calls are completing**, including the head-of-queue call that has been blocked 45 minutes.

This is not a socket-gone failure. It is a **queue stall**: the serializing boundary between connected clients and 1Password's vault-unlock state machine has stopped advancing.

## Mechanism — what the runpod-inference `.envrc` actually invokes

Project file: `~/Repos/verlyn13/runpod-inference/.envrc` (hash: 681 bytes, dated 2026-04-17):

```bash
use mise
use op

# Runpod API key — inline `op read` resolves via 1Password at shell entry.
# Project-scoped only; never replicate this line into a shell rc or .env.
export RUNPOD_API_KEY="$(op read 'op://Dev/runpod-api/api-key')"

export RUNPOD_INFERENCE_ENV="${RUNPOD_INFERENCE_ENV:-dev}"
export RUNPOD_MODE="${RUNPOD_MODE:-local}"

# Local non-secret defaults. Pod/remote hosts set these differently.
export HF_HOME="${HF_HOME:-$PWD/.cache/huggingface}"
export HF_HUB_CACHE="${HF_HUB_CACHE:-$PWD/.cache/huggingface/hub}"
export OUTPUT_ROOT="${OUTPUT_ROOT:-$PWD/outputs}"

# Optional per-host non-secret overrides (never committed).
source_env_if_exists .envrc.local.nonsecret
```

Global `use_op` helper at `~/.config/direnv/direnvrc` (chezmoi source: `home/dot_config/direnv/direnvrc.tmpl`):

```bash
use_op() {
  if ! command -v op >/dev/null 2>&1; then
    log_error "1Password CLI (op) is required but not installed"
    log_error "Install: brew install --cask 1password-cli"
    return 1
  fi
  # Desktop-app integration: op whoami reports "not signed in" even when
  # op read works. Use vault access as the canonical readiness check.
  if ! op vault get Dev --account my.1password.com >/dev/null 2>&1; then
    log_error "1Password CLI cannot access vault 'Dev' on my.1password.com"
    log_error "Open 1Password app and enable Settings > Developer > Integrate with 1Password CLI"
    return 1
  fi
}
```

On `cd ~/Repos/verlyn13/runpod-inference`, direnv runs `/opt/homebrew/bin/direnv export zsh` as a subprocess:

1. `use mise` — fast (<1s)
2. `use op` — **synchronous** `op vault get Dev --account my.1password.com`  ← first `op` call
3. `export RUNPOD_API_KEY="$(op read 'op://Dev/runpod-api/api-key')"`  ← second `op` call (inline)
4. Non-op exports (fast)
5. `source_env_if_exists .envrc.local.nonsecret` (may or may not exist)

Every cd into runpod-inference pays at minimum **two cold-start `op` calls** against the 1P IPC queue — ~18 seconds wall-clock on a healthy cold session, longer if the user must biometrically unlock. The "taking a while" message fires at ~5s, which is why healthy-system cold cd's already show the warning. Deadlocked-queue cd's never clear it.

### Healthy-system baseline (reference)

From the companion field report's observation on this same system:

```text
$ time op read --account my.1password.com 'op://Dev/<item>/<field>' >/dev/null
op read … > /dev/null   0.04s user 0.04s system 0% cpu 8.964 total
```

~9 seconds wall-clock per call on cold 1P integration session. With two calls, cd-into-runpod-inference under a healthy cold 1P session is ~18s total — fast enough to not be a daily irritant but slow enough that direnv's "taking a while" warning routinely fires. Under a warm session, sub-100ms per call.

## Mechanism — 1P IPC queuing behavior

### The serialization point

The `op` CLI, when used against a desktop-app-integrated account (`my.1password.com` with "biometric unlock via desktop app integration" enabled), makes calls against the 1Password app through a Unix socket at `$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/s.sock`. This socket is the integration endpoint.

Empirical observation from this session supports — but does not prove — the following design of the IPC server:

- **Single-queue, per-user semantics.** The 1Password app processes one integration request at a time per user session, presumably to serialize biometric-unlock prompts and vault-state transitions.
- **Head-of-line blocking.** If a request at the head of the queue is waiting for a user action (biometric unlock, consent confirmation, password) that does not arrive, subsequent requests wait behind it indefinitely.
- **No built-in timeout.** `op` does not appear to enforce a client-side timeout. Calls wait forever.

This is consistent with today's observation: one stuck `op whoami` at the head of the queue (45 minutes old) has been blocking the 14+ subsequent calls behind it, including the user's direnv `op vault get Dev`.

### What stalled the head of the queue

The head-of-queue call (PID 98842) is my own diagnostic probe from earlier in this session. It was issued inside a background command that chained many ps / log queries; `op whoami` was one step in the chain. At the time I issued it, the 1P CLI session was cold — meaning the first call needed a fresh desktop-app handshake and (likely) a biometric unlock. The background-command context may have been unable to bring the biometric dialog forward (Claude Code's Bash tool spawns children with specific TTY/session semantics that GUI applications may treat as non-interactive). The dialog may have been queued internally by 1P and never surfaced for user interaction.

**This hypothesis is consistent with but not proven by the observation.** It is possible the call is stuck for some other reason — see Open questions.

### Why direnv's call joined the same queue

`op`'s integration path is global for a user session. Any `op` invocation — whether from a terminal shell, a direnv hook, an MCP wrapper, or a background diagnostic — connects to the same socket and enters the same queue. There is no separate "fast lane" for interactive shells. Direnv's shell-entry `op vault get` is indistinguishable, at the IPC layer, from my diagnostic probe or an MCP wrapper's startup `op read`.

This is the load-bearing system assumption worth explicit documentation: **`op` IPC is session-global. There is one queue shared by every consumer.**

## Mechanism — how this session's deadlock built up

A chronological walkthrough, supported by elapsed-time evidence:

1. **T − 45 min**: Investigation into the Claude Desktop consent cycle began. At some point I issued a background `ps / op whoami / log show` diagnostic chain. The `op whoami` call joined the IPC queue. On a cold 1P session, `op whoami` typically triggers a biometric-unlock prompt; either the prompt was consumed by the later `op read` I issued (which did complete, allowing unlock) OR it never surfaced. The `op whoami` process has remained in-queue ever since — PID 98842 still stuck at inspection, elapsed 45:01.

2. **T − 24 to T − 22 min**: Cloudflare MCP audit probes issued `op item get` twice. Both entered the queue behind #1. Still stuck at inspection as PIDs 2986 and 3684.

3. **T − 18 min**: First wave of five MCP wrapper `op read` calls from a client startup cycle. These are the MCP wrappers spawned by Claude Code CLI / Cursor / Codex / Claude Desktop during normal client operations (config reload, session reconnect). All five entered the queue. Still stuck at inspection as PIDs 4424-4524.

4. **T − 14 min**: Second wave of four MCP wrapper `op read` calls. Same story. PIDs 7136-7248.

5. **T − 6 min**: First symptomatic direnv attempt — the user's earlier `cd` that also hung. PID 11151, `op vault get Dev`.

6. **T − 3 min**: Current direnv hang. `cd ~/Repos/verlyn13/runpod-inference` → `.envrc` → `use op` → `op vault get Dev` → PID 12436 → joins queue → hangs.

No event in this session **unstuck** the queue. Each consumer added stress; none drained.

### Adjacent observation — Claude Desktop crash (companion report)

The companion report documents that Claude Desktop crashed during its MCP consent cycle. It is plausible that the Claude Desktop crash contributed IPC pressure without directly blocking the queue, because:

- Claude Desktop's MCP wrapper spawns fed op-read calls into the queue
- When Claude Desktop was killed mid-cycle, some subset of those calls died with their parent process (their op daemon connections would be cleaned up by the kernel)
- The remaining queued calls (including wrappers spawned by terminal-hosted clients that are still running) continued to accumulate

The Claude Desktop crash is a **contributor** to the degraded state but not its **root cause**. The root cause is the head-of-queue `op whoami` stall.

## Substrate implications

This report reinforces every substrate requirement the companion report raised, and adds an additional surface to the same problem class.

### Confirmed requirement — centralized credential broker

The companion report argued: _"MCP children don't talk to `op` directly; they talk to the substrate over an authenticated local socket. No per-wrapper consent prompts."_

Today's evidence extends that case: **not only MCP children; every secret-fetching surface on this system belongs on the same broker.** That includes:

- MCP wrapper startup (covered in companion report)
- `direnv use_op` + inline `op read` calls in project `.envrc` files (this report)
- Any interactive `op read ...` at the shell (low frequency, but same path)
- Any scripted tool that calls `op read` for its own reasons (sync-mcp.sh verification, ng-doctor checks, system-update plugin auth)

One broker — not six — is the right fan-in point. With the broker in place:

- Consumers connect to a local Unix socket maintained by the broker (e.g., `$XDG_RUNTIME_DIR/hcs/broker.sock`).
- The broker maintains a warm connection to 1P IPC, re-using the vault-unlock state across all requests.
- Consumer requests are multiplexed by the broker; no queue accumulates at the 1P IPC layer because the broker is always the single client.
- Consumers that can tolerate failure (direnv, ng-doctor) get a fast-fail path (<100ms) when the broker is unreachable.
- Consumers that need the value (MCP wrappers) get the same latency profile as a warm 1P session (sub-100ms).

### Confirmed requirement — consumer-side timeouts

`op` itself does not appear to enforce a client-side timeout; a call that enters the IPC queue can wait forever. The substrate's client library must wrap every broker call with a timeout appropriate to the consumer:

- direnv `.envrc` loads: 5s total budget (direnv shows "taking a while" at ~5s)
- MCP wrapper startup: 10s budget (matches Electron MCP init timeout)
- Interactive CLI: 30s budget (matches user tolerance)

Calls that exceed the budget should fail cleanly, log a diagnostic, and let the consumer handle degradation (e.g., direnv continues without the secret; MCP wrapper exits with clear error).

### New requirement — session-wide queue visibility

The substrate broker should expose a diagnostic surface (`hcs status op-queue` or similar) that reveals the current state of pending secret requests, including:

- Requests waiting on 1P IPC
- Requests that have exceeded their timeout
- Requests that are serving cached values

Without this, a deadlock like today's is opaque until a user happens to run `ps | grep op` — which requires they already suspect the cause.

### Adjacent requirement — graceful degradation for read-only consumers

direnv's `use_op` readiness check (`op vault get Dev`) is **informational** — it tells the user if 1P is reachable, nothing more. On a stuck 1P, failing this check cleanly (with a 5s timeout) would let the rest of the `.envrc` proceed without the `RUNPOD_API_KEY` export, allowing the user to at least get a working shell in the project directory. Today's design blocks the entire `.envrc` on a single 1P stall.

Under the substrate, `use_op` becomes a broker probe — fast to fail, fast to succeed, and clearly labeled when degraded.

## Impact on the current system

### What is currently affected

- `cd` into any project whose `.envrc` uses `use op` or calls `op read` hangs until either the user kills the op processes or restarts 1P.
- Repos with this `.envrc` pattern on this system include at least `~/Repos/verlyn13/runpod-inference` (confirmed); others using `use op` may exhibit the same.
- New MCP client sessions cannot spawn op-calling wrappers cleanly.
- Any new `op` call (including `op whoami` for health checks) joins the deadlocked queue.

### What is currently fine

- The 1Password desktop app itself is running and the vault is accessible via the app's UI.
- 1P SSH agent (separate socket at `agent.sock`) is unaffected; SSH operations still work.
- Terminals that have already resolved their `.envrc` (no new cd) continue to work; their env vars are already exported.
- MCP servers that have completed their initial op-call-and-exec-into-npx are running on their already-resolved token and are not impacted.

### Recovery procedure

Not executed in this report, per the standing pattern of not fixing during diagnostic documentation. Listed for operational reference:

**Fastest recovery:**

```bash
pkill -9 op                 # kill the queued op processes
# (op daemon instances may also need killing if they're wedged)
pkill -9 -f "op daemon"
```

This unsticks the queue by removing all queued clients; 1P's IPC has nothing waiting, new calls connect cleanly. Downstream processes (MCP wrappers, direnv hooks) that had their parent op calls killed will fail; they can be restarted.

**Cleaner recovery (optional):**

Quit and relaunch the 1Password app. This resets the IPC socket listener on the 1P side. Any in-flight op calls error with "socket closed"; subsequent ones work.

**Slowest recovery:**

Wait. Not recommended — at 45+ minutes on the head-of-queue call with no observed timeout, there is no evidence `op` or 1Password ever unblocks the queue without intervention.

## Evidence catalog

### Process listing at inspection (16:00 local approximate)

Full queue captured in §Mechanism — how this session's deadlock built up above.

### Socket state

```text
$ lsof 2>/dev/null | grep -E "2BUA8C4S2C.*\.sock"
1Password 1194 verlyn13  24u  unix 0x19725c52df9917bb ... .../t/s.sock
1Password 1194 verlyn13  53u  unix 0xf2cb69dffb0e9051 ... .../t/agent.sock

$ ls -la ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/
total 0
```

Note: `ls` reports "total 0" because Unix domain sockets are not regular files and don't show in the `total` byte count; the sockets are live in the kernel's namespace but invisible to basic file-listing tools. `lsof` is the correct way to inspect their state.

### 1Password app state

```text
$ pgrep -lf '/Applications/1Password.app/Contents/MacOS/1Password'
1194 /Applications/1Password.app/Contents/MacOS/1Password --silent --just-updated --should-restart
1208 /Applications/1Password.app/Contents/MacOS/1Password-Crash-Handler
```

The `--just-updated` flag on PID 1194 suggests the 1Password app was recently updated. This is notable: a recent update could have changed IPC server behavior and be a contributing factor. See Open questions.

### The directly implicating PID

```text
12436  (parent 11134)  03:09  op vault get Dev --account my.1password.com
```

Parent 11134 is the zsh hosting `/opt/homebrew/bin/direnv export zsh`; this is the chain the user's `cd ~/Repos/verlyn13/runpod-inference` set in motion.

## Confirmed vs hypothesized

### Confirmed (direct observation)

- 15+ `op` processes are queued and blocked, ages ranging from 3 minutes to 45 minutes.
- The 1Password app is running; its IPC sockets (`s.sock`, `agent.sock`) are held open by PID 1194.
- The head-of-queue call is PID 98842 `op whoami`, elapsed 45:01, and has not returned.
- The user's direnv-triggered `op vault get Dev` is PID 12436, elapsed 3:09, still in the queue.
- `op` does not appear to enforce a client-side timeout under these conditions.
- The runpod-inference `.envrc` calls `op` twice per shell-entry (readiness check + inline expansion).
- Healthy-system cold-start latency per `op` call is ~9s (baseline from companion report).

### Hypothesized (consistent with observation, not directly proven)

- The 1P IPC server serializes requests per user session (single queue). **How to confirm:** stress-test with concurrent `op read` calls under a known-warm session; observe whether latency grows linearly (queue) or stays flat (parallel).
- Head-of-queue blocking is caused by a biometric-unlock prompt that never surfaced. **How to confirm:** under a known-clean state, issue `op whoami` from a non-interactive context (cron, launchd, background tool) while the 1P app has no focus; observe whether the prompt queues invisibly.
- The 1Password app's `--just-updated` state may have changed IPC server behavior mid-session. **How to confirm:** check 1Password release notes for the specific version (look at `/Applications/1Password.app/Contents/Info.plist CFBundleShortVersionString`) for any IPC-related changes.
- The Claude Desktop crash documented in the companion report contributed to queue pressure but did not cause the deadlock. **How to confirm:** reproduce the deadlock with Claude Desktop disabled entirely.

### Limitations / not investigated

- No attempt was made to inspect 1Password's internal IPC server implementation (closed).
- The `--just-updated` version of 1Password was not captured by version number.
- It is not known whether `op` has a timeout flag or environment variable that would have prevented the hang (e.g., `OP_TIMEOUT` or similar). Worth future investigation for direnv `use_op` hardening.
- Other projects on this machine with `.envrc` calling `op` were not enumerated; the blast radius may be larger than runpod-inference alone.

## Reproduction recipe

### Observational (non-destructive)

Useful for confirming whether a system is in the deadlocked state before taking action:

```bash
# Queue depth + ages
ps -eo pid,ppid,etime,args | grep -E "\bop\b" | grep -v "op daemon\|grep"

# Expected clean state: 0–2 entries, no entry older than ~15s.
# Deadlocked state: many entries, head-of-queue older than several minutes.

# 1P app sockets
lsof 2>/dev/null | grep "2BUA8C4S2C.*\.sock"

# Expected: two sockets (s.sock, agent.sock) owned by the 1Password process.
# If socket count is ≠ 2, or if no 1Password process owns them, something
# structurally different is wrong (not today's symptom).

# Queue depth as single number
ps -eo comm | grep -c "^op$"
```

### Synthetic reproduction (destructive — will put 1P into the state)

Only run under controlled conditions:

```bash
# Step 1: ensure 1P integration is in "cold" state
#   Most reliably: fully quit + relaunch the 1Password app, do not authenticate to it.

# Step 2: from a non-interactive context (background shell, launchd agent, etc.)
#   issue op whoami. This typically triggers a biometric prompt that
#   non-interactive callers cannot fulfill.
( op whoami --account my.1password.com >/dev/null 2>&1 ) &

# Step 3: from normal shells, issue further op calls — these should hang
#   behind the head-of-queue call.
time op vault get Dev --account my.1password.com

# Step 4: observe queue depth
ps -eo pid,etime,args | grep -E "\bop\b" | grep -v daemon

# Recovery:
pkill -9 op ; pkill -9 -f "op daemon"
```

## Open questions for further investigation

Listed by information value:

1. **Does 1P IPC actually serialize per user, or is the head-of-queue blocking coincidental?** Stress-test under controlled concurrency; measure latency scaling. Dispositive.

2. **What `op` flags or env vars enforce a client-side timeout?** Audit `op --help`, `op read --help`, and the source at `cloudflare/mcp` / `1Password/cli` (public). Finding a timeout knob means direnv's `use_op` and MCP wrappers can avoid hanging forever even without the substrate broker.

3. **Which specific 1Password version was `--just-updated` to?** Capture `CFBundleShortVersionString` and check release notes for IPC-related changes since the prior version.

4. **Does the biometric-unlock prompt surface correctly when `op` is called from a background subprocess of Claude Code's Bash tool?** This is the specific context where today's head-of-queue stall likely originated. If background-subprocess `op` calls reliably stall, that's a class of bug worth reporting upstream (either to `op` or to Claude Code) and an explicit constraint the substrate must handle.

5. **What percentage of project `.envrc` files on this machine call `op`?** Enumerate `~/**/.envrc` for `use op` + `op read`. Quantifies the blast radius of this failure mode.

6. **Is there a supported way to cancel a queued `op` request from 1P side (rather than killing the client)?** The 1Password app's Developer settings may expose integration diagnostics.

7. **Does the substrate broker need to be the only `op` caller, or can it coexist with direct `op` calls?** If 1P IPC is truly single-queue, direct callers outside the broker would still hit the same contention. Design question.

## Cross-links to other evidence

- Companion field report: [`2026-04-23-claude-desktop-op-consent-cycle.md`](./2026-04-23-claude-desktop-op-consent-cycle.md) — the same IPC surface under a different consumer (MCP children rather than direnv), observed earlier in the same session
- [`implementation-charter.md`](./implementation-charter.md) — substrate's binding invariants; evaluate §adapter auth requirements against the three confirmed and two new requirements raised here
- [`../secrets.md`](../secrets.md) — current secrets policy; documents `use op` as the accepted direnv pattern (v2.2.0)
- [`../project-conventions.md`](../project-conventions.md) — documents `use op` + inline `op read` as the accepted project `.envrc` shape
- [`../mcp-config.md`](../mcp-config.md) — MCP wrapper pattern, same IPC dependency

## Artifact references

### Source files relevant to this cycle

| File | Role |
|---|---|
| `home/dot_config/direnv/direnvrc.tmpl` | Chezmoi source for `use_op`, `use_user_mcp_secrets`, and other helpers; deployed to `~/.config/direnv/direnvrc` |
| `home/dot_config/direnv/direnv.toml.tmpl` | direnv configuration (forces `/opt/homebrew/bin/bash` over `/bin/bash`); deployed to `~/.config/direnv/direnv.toml` |
| `~/Repos/verlyn13/runpod-inference/.envrc` | The specific `.envrc` that triggered today's hang (external to system-config; preserved unchanged) |
| `home/dot_local/bin/executable_mcp-*-server.tmpl` | MCP wrappers; same op IPC consumers as the direnv path |

### Runtime artifacts

- `$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/s.sock` — the IPC socket
- `$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` — SSH agent (unrelated to this issue but physically adjacent)
- `$HOME/.config/op/op-daemon.sock` — `op`'s own local daemon socket (separate from 1P IPC)
- `/Applications/1Password.app/Contents/Info.plist` — 1Password app version info

## Change log

| Version | Date | Change |
|---|---|---|
| 1.0.0 | 2026-04-23 | Initial report, drafted the same day as the user's direnv hang, with queue state still captured live. |
