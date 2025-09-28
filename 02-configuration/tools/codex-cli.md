---
title: Codex CLI Configuration
category: configuration
component: codex
status: active
version: 1.0.0
last_updated: 2025-09-26
tags: [ai-assistant, automation, tooling]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: high
---

# Codex CLI Configuration Guide
## GPT-5 Profiles, Safety Controls, and Tooling on macOS Tahoe (26)

---

## Overview

This guide captures the production-grade Codex CLI configuration used on the macOS Tahoe
workstation. It standardizes profile behavior, sandbox boundaries, approval policies, Model Context
Protocol (MCP) tooling, and cost controls so every session behaves predictably.

You will:
- Install or update Codex CLI via Homebrew (`brew install openai-tools/codex/codex`).
- Populate `~/.codex/config.toml` with a shared baseline plus task-specific profiles.
- Layer guidance through `AGENTS.md` files so the assistant inherits house rules.
- Wire in MCP servers, cost guardrails, and secret management through `api_key_cmd`.
- Verify effective settings inside the TUI (`/status`, `/diff`, `/prompts`).

---

## Directory Layout

```
~/.codex/
├── config.toml          # Global defaults + profiles
├── AGENTS.md            # Personal guardrails (optional but recommended)
└── logs/                # Session transcripts when log level >= info

~/Development/personal/system-setup-update/
└── AGENTS.md            # Repo-specific architecture + tooling directives (future)
```

Create the directory if it does not exist:

```bash
mkdir -p ~/.codex
```

---

## Baseline Configuration (`~/.codex/config.toml`)

Use the following scaffold as the authoritative baseline. Update `last_updated` metadata in this
repository when the config changes.

```toml
model           = "gpt-5"
model_provider  = "openai"
approval_policy = "on-request"
sandbox_mode    = "workspace-write"
retain_data     = false
log_level       = "info"

[budget]
session = 3.00
daily  = 40.00

[profiles.speed]
model = "gpt-5-mini"

[profiles.deep]
model                  = "gpt-5"
model_reasoning_effort = "high"

[profiles.agent]
model           = "gpt-5-mini"
approval_policy = "never"
sandbox_mode    = "workspace-write"

[profiles.maint]
model           = "gpt-5"
approval_policy = "on-request"

[mcp_servers.context]
command = "context7"
args    = ["--stdio"]
enabled = true
timeout = "30s"

[mcp_servers.graphiti_memory]
command = "graphiti-memory"
args    = ["--stdio"]
enabled = true
```

> **Known bug (2025-09)**: Some builds ignore `sandbox_mode` declared inside profiles. If `/status`
> shows a mismatch, re-run the CLI with `--sandbox=workspace-write` (or desired override) to force
> the correct level.

---

## Profile Matrix

| Profile      | Model       | Use Case                                  | Notes |
|--------------|-------------|-------------------------------------------|-------|
| `default`    | `gpt-5`     | Interactive work with human approvals     | Safe baseline |
| `speed`      | `gpt-5-mini`| Quick edits, inexpensive brainstorming    | Lower token cost |
| `deep`       | `gpt-5`     | Long-form reasoning, refactors, reviews   | Enables `model_reasoning_effort=high` |
| `agent`      | `gpt-5-mini`| Non-interactive runs (`codex exec`)       | No approval prompts; stays inside workspace sandbox |
| `maint`      | `gpt-5`     | Trusted maintenance sessions              | Keep on-request approvals; pass `--sandbox=full` manually when needed |

Switch profiles on launch, e.g., `codex -p deep --sandbox=workspace-write`.

---

## Secrets & Authentication

Keep API credentials out of shell history by delegating to your password manager:

```toml
api_key_cmd = ["gopass", "show", "-o", "openai/api_key"]
preferred_auth_method = "apikey"
```

If you migrate to Azure OpenAI, extend the config with endpoint, deployment, and API version keys
sourced from the same `gopass` store.

---

## MCP Servers

Codex auto-discovers MCP servers defined in `config.toml`. Add entries per tool and ensure each
binary is on `PATH`.

```toml
[mcp_servers.context]
command = "context7"
args    = ["--stdio"]
enabled = true
timeout = "30s"

[mcp_servers.graphiti_memory]
command = "graphiti-memory"
args    = ["--stdio"]
enabled = true
```

Test connectivity from an interactive session:

```bash
codex -p deep --sandbox=workspace-write
# Inside Codex: ask it to "use context7" on a sample query.
```

If the CLI omits the server list, call the tool explicitly by name—execution succeeds even when the
UI fails to list the server (regression tracked in `openai/codex#2837`).

---

## AGENTS.md Layering

Codex merges instructions in the following order:

1. `~/.codex/AGENTS.md` — Personal tone, safety posture, default tools.
2. `<repo>/AGENTS.md` — Architecture reference for this repository.
3. `<repo>/<feature>/AGENTS.md` — Task-specific overrides.

Author concise rules. For example, the global file should call out preferred tooling (uv, ruff, bun,
biome) and secrets policy. The repo file can summarize documentation architecture and validation
commands (`markdownlint`, `validate-system.py`).

---

## Safety Controls

- **Sandbox**: Default to `workspace-write`. Only opt into `--sandbox=full` inside trusted
  monorepos, and rely on macOS Full Disk Access prompts when crossing system boundaries.
- **Approvals**: Leave `approval_policy="on-request"` for interactive deep work so the agent pauses
  before destructive commands. Create opt-in profiles (`agent`) for scripted runs that must proceed
  autonomously (sets `approval_policy="never"`).
- **Network**: Keep the default “deny” posture unless a task demands network access. Future updates
  may expose `[security]` options for allowlists; document any changes here.

Run `/status` inside the TUI to confirm active settings before lengthy sessions.

---

## Budget Guards

Budget limits prevent runaway sessions when operating unattended:

```toml
[budget]
session = 3.00
daily  = 40.00
```

Adjust thresholds when delegating long multi-stage refactors or reviews. Codex displays cumulative
spend in `/status`.

---

## Workflow Patterns

```bash
# Deep interactive session (verification step)
codex -p deep --sandbox=workspace-write
# Inside Codex: /status, /diff, /prompts

# Scripted one-off with no approval prompts (CI-style)
codex -p agent exec "Run the test suite; if failing, propose a minimal fix."

# High-trust maintenance (verify sandbox via /status)
codex -p maint --sandbox=full
```

During interactive work, use `/diff` to inspect the git workspace, `/prompts` to review recent
instructions, and `/retry` to re-run assistant output with modified guidance.

---

## Validation Checklist

1. `codex -p deep --sandbox=workspace-write`
   - Inside, run `/status` and confirm model, approvals, sandbox, and budget.
2. Request execution of `context7` via MCP and confirm the tool responds.
3. Run `codex -p agent exec "echo ok"` to ensure non-interactive runs respect the workspace sandbox.
4. Inspect `~/.codex/logs/` for session artifacts when troubleshooting unexpected behavior.

Record results in `07-reports/status/sync-summary.md` during scheduled documentation syncs.

---

## Troubleshooting

- **Sandbox shows `full` unexpectedly**: Launch Codex with `--sandbox=workspace-write` until the
  profile-level bug is patched.
- **MCP server missing**: Check the binary path and ensure the command speaks MCP over stdio. Codex
  will silently skip servers that exit with non-zero status.
- **API key prompt**: Verify `api_key_cmd` resolves successfully. Run the array manually to confirm
  the secret is available (`gopass show -o openai/api_key`).
- **Session cost exceeded**: Raise `budget.session` temporarily or break work into smaller
  prompts—Codex terminates the session once limits are hit.

Document any deviations or overrides in this file so future agents inherit accurate context.
```
