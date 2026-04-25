---
title: Temporary MCP Usage Collector
category: field-report
component: host_capability_substrate
status: active
date: 2026-04-24
tags: [mcp, telemetry, launchd, substrate, local-only]
---

# Temporary MCP Usage Collector

## Purpose

For a few days starting 2026-04-24, this workstation runs a local-only
LaunchAgent that samples MCP process fan-out and resource shape. The goal is to
give the host-capability-substrate migration concrete data for broker design,
rate-limit policy, GUI-host behavior, and resource budgeting.

This collector is intentionally simple. It is not observability infrastructure
and should be removed after the substrate planning window.

## Service

| Item | Value |
|---|---|
| LaunchAgent label | `com.jefahnierocks.mcp-usage-collector` |
| Repo script | `scripts/mcp-usage-collector.sh` |
| Default interval | 60 seconds |
| Data directory | `~/.local/state/system-config/mcp-usage-collector/` |
| Log directory | `~/Library/Logs/system-config/` |
| Data format | daily JSONL files named `YYYY-MM-DD.jsonl` |

Commands:

```bash
scripts/mcp-usage-collector.sh status
scripts/mcp-usage-collector.sh snapshot
scripts/mcp-usage-collector.sh uninstall
scripts/mcp-usage-collector.sh path
```

## Collected Data

Each sample records:

- local system load and process count
- MCP process count and `mcp-remote` session count
- MCP session counts by owning host and endpoint
- per-agent process/resource totals (`rss_kb`, `%cpu`, process count)
- detailed MCP process rows with PID, parent PID, age, RSS, CPU, endpoint, and
  redacted argv
- redacted parent chain for `node ... mcp-remote` sessions
- top agent/MCP processes by RSS
- known `last_<plane>_mcp_429` markers from sibling current-state docs
- local Claude MCP log tail counters for rate-limit markers, initialize/tool
  list churn, and transport closes

The collector does not call Cloudflare, Runpod, GitHub, 1Password, or any other
external API. It does not read process environments. It redacts bearer headers,
token-like argv fields, password-like argv fields, and common MCP secret env
names if they appear in command arguments.

## Use For Planning

This data should answer:

1. How many authenticated MCP sessions are normally live per host?
2. Which GUI hosts respawn or duplicate sessions?
3. Which MCP servers dominate steady-state memory?
4. Whether a substrate broker needs per-token serialization, per-endpoint
   shaping, or both.
5. How often 429 markers appear relative to local MCP fan-out.

## Stop Condition

Stop the service after enough data is collected:

```bash
scripts/mcp-usage-collector.sh uninstall
```

The uninstall command removes the LaunchAgent but keeps JSONL samples under
`~/.local/state/system-config/mcp-usage-collector/` for manual review.
