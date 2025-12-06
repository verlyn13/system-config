---
title: Codex Cli
category: configuration
component: codex_cli
status: active
version: 2.0.0
last_updated: 2025-12-05
tags: [configuration, settings]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: medium
---


# Codex CLI Configuration Guide
## GPT-5 Profiles, Safety Controls, and Tooling on macOS Tahoe (26)

---

## Overview

This guide reflects the December 2025 Codex CLI behavior. Codex has a single global config file,
supports profiles inside that file, and does not auto-read project configs. We emulate project
overrides using `CODEX_CONFIG`.

---

## Configuration locations & precedence

1. CLI flags
2. Active profile inside `~/.codex/config.toml`
3. Top-level entries in `~/.codex/config.toml`

Codex only reads this one file. To use project-specific configs, set `CODEX_CONFIG=</path/to/config>`
before launching the CLI (see Project pattern below).

---

## Recommended global config (`~/.codex/config.toml`)

Use this as the canonical baseline for interactive work, keeping approvals on-request and the
workspace sandbox enabled by default.

```toml
# GLOBAL CODEX CONFIGURATION

model = "gpt-5.1"
model_provider = "openai"
profile = "dev"

# Reasoning
model_reasoning_effort = "high"
model_verbosity = "low"
model_max_output_tokens = 4096

# Approvals & sandbox
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[shell_environment_policy]
inherit = "none"
include_only = ["PATH", "HOME", "OPENAI_API_KEY", "UV_PKG_INDEX"]
exclude = ["AWS_*", "GCP_*", "TOKEN", "SECRET", "KEY"]

[features]
apply_patch_freeform = true
streamable_shell = true
web_search_request = true

[model_providers.openai]
name = "OpenAI"
base_url = "https://api.openai.com/v1"
env_key = "OPENAI_API_KEY"
request_max_retries = 4
stream_idle_timeout_ms = 300000

[otel]
environment = "dev"
exporter = "none"

[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]

[profiles.dev]
model_reasoning_effort = "high"
approval_policy = "on-request"

[profiles.fast]
model = "gpt-4.1"
model_reasoning_effort = "low"
approval_policy = "untrusted"

[profiles.review]
model = "gpt-5-pro"
model_reasoning_effort = "high"
approval_policy = "never"
```

> Notes
> - Codex does **not** ship a CLAUDE.md equivalent; use CLI flags or shell aliases to point to a
>   system prompt file when needed.
> - `CODEX_CONFIG` can point to an alternate TOML file (used internally by the IDE as well).
> - MCP servers live inside the same TOML file; no separate directories are required.

---

## Project-level pattern (manual)

Codex will not auto-read project files. Mirror the Claude hierarchy by wrapping `CODEX_CONFIG`:

```
<project>/.codex/
  config.toml       # committed
  config.local.toml # gitignored, personal
```

Wrapper script (`<project>/bin/codex`):

```bash
#!/usr/bin/env bash
if [ -f ".codex/config.local.toml" ]; then
  export CODEX_CONFIG="$(pwd)/.codex/config.local.toml"
else
  export CODEX_CONFIG="$(pwd)/.codex/config.toml"
fi
exec codex "$@"
```

Direnv alternative (`.envrc`):

```bash
export CODEX_CONFIG="$(pwd)/.codex/config.toml"
```

This yields: CLI flags → profile → top-level → project/local file.

---

## Installation & verification

- Install: `brew install openai/openai/codex`
- Ensure config dir: `mkdir -p ~/.codex && touch ~/.codex/config.toml`
- Export global config path (zsh): `export CODEX_CONFIG="$HOME/.codex/config.toml"`
- Test: `codex --version`

---

## Validation checklist

1. Launch `codex -p dev --sandbox=workspace-write` and run `/status` (model, approvals, sandbox).
2. Confirm MCP server loads (`context7` in the example baseline).
3. Verify project override by setting `CODEX_CONFIG=$PWD/.codex/config.toml` and re-running `/status`.
4. Check `~/.codex/logs/` when diagnosing failed sessions.

---

## Troubleshooting

- **Project config ignored**: Ensure `CODEX_CONFIG` is exported in the shell or wrapper script before
  launching Codex.
- **MCP server missing**: Verify the command exists on `PATH` and exits zero on startup; Codex skips
  failing servers without prompting.
- **Sandbox/approvals mismatch**: Re-run with explicit flags (`--sandbox=workspace-write
  --approval-policy=on-request`) to override profile defaults.
- **API key prompt**: Confirm `OPENAI_API_KEY` is in the forwarded env list inside
  `[shell_environment_policy]`.

Document deviations here so future runs stay in sync.
