---
title: DevOps MCP Server Configuration
category: reference
component: mcp-server
status: active
version: 0.3.0
last_updated: 2025-09-27
tags: [mcp, ai-agents, devops, automation]
priority: high
---

# DevOps MCP Server Configuration

## Overview

The DevOps MCP (Model Context Protocol) server is a safety-first automation layer that exposes golden-path DevOps workflows to AI agents with strict policy enforcement and comprehensive audit trails. It provides controlled access to system management tools (chezmoi, mise, brew, git) through a secure, rate-limited interface.

**Repository**: `~/Development/personal/devops-mcp`
**Version**: 0.3.0
**Status**: Stage-7 Complete (Telemetry Implemented)
**Node Requirement**: ≥24.0.0
**Telemetry**: OpenTelemetry integrated (traces, metrics, logs)

## Architecture

### Core Components

```
devops-mcp/
├── src/
│   ├── index.ts              # MCP server registration
│   ├── config.ts             # TOML configuration loader
│   ├── lib/
│   │   ├── audit.ts          # SQLite/JSONL audit logging
│   │   ├── exec.ts           # Hardened command execution
│   │   ├── git.ts            # Git operations & provenance
│   │   ├── locks.ts          # Resource locking
│   │   ├── provenance.ts     # Plan SHA & verification
│   │   ├── ratelimit.ts      # Rate limiting implementation
│   │   ├── logging/
│   │   │   └── logger.ts     # Pino structured logging
│   │   └── telemetry/
│   │       ├── otel.ts       # OpenTelemetry SDK init
│   │       ├── metrics.ts    # Metric instruments
│   │       ├── tracing.ts    # Span management
│   │       ├── health.ts     # OTLP reachability
│   │       ├── info.ts       # Telemetry metadata
│   │       ├── contract.ts   # Type definitions
│   │       └── profile_context.ts # Profile-aware telemetry
│   ├── http/
│   │   └── shim.ts           # Dashboard HTTP bridge
│   ├── tools/                # MCP tool implementations
│   │   ├── converge_host.ts  # Local host orchestration
│   │   ├── system_converge.ts # Repo-driven convergence
│   │   ├── system_plan.ts    # System planning from repo
│   │   ├── pkg_sync.ts       # Package synchronization
│   │   └── dotfiles_apply.ts # Chezmoi application
│   └── resources/            # MCP resource providers
│       ├── system_repo_state.ts    # Git repo state
│       ├── policy_manifest_repo.ts # Policy from repo
│       └── pkg_inventory.ts        # Package inventory
├── examples/
│   ├── config.example.toml   # Configuration template
│   └── devops.mcp.plist      # launchd service definition
└── scripts/
    └── integration-smoke.mjs  # Integration test suite
```

### Security Model

1. **Execution Hardening**
   - `execFile` only (no shell interpolation)
   - Sanitized PATH environment
   - No inherited environment by default
   - Command allowlisting

2. **Audit Trail**
   - Every operation logged to SQLite/JSONL
   - Location: `~/Library/Application Support/devops.mcp/audit.sqlite3`
   - Retention: 30 days (configurable)
   - Hashed secret references (no values stored)

3. **Access Control**
   - Rate limiting per tool/resource
   - Capability tiers (read_only, pkg_admin, mutate_repo)
   - Secret path allowlisting
   - Traversal protection

## Installation & Setup

### 1. Clone and Install

```bash
cd ~/Development/personal
git clone git@github.com:verlyn13/devops-mcp.git
cd devops-mcp

# Ensure Node 24 is active
mise use -g node@24

# Install dependencies
pnpm install

# Build the server
pnpm build

# Verify compilation
pnpm check
```

### 2. Configure the Server

Create configuration at `~/.config/devops-mcp/config.toml`:

```toml
# Allowlists
[allow]
paths = ["~/Development", "~/.config", "/opt/homebrew"]
commands = ["chezmoi", "brew", "git", "mise", "rsync", "tar", "jq", "gopass", "env"]
pathDirs = ["/usr/bin", "/bin", "/usr/sbin", "/sbin", "/opt/homebrew/bin", "/opt/homebrew/sbin"]

# System repository configuration (NEW in Stage-6)
[system_repo]
url = "git@github.com:verlyn13/system-setup-update.git"
branch = "main"
root = "/"

# Profile mappings (NEW in Stage-6)
[profiles]
"macpro.local" = "personal"
"sandbox" = "personal-sandbox"

# Workspace directories
workspaces = ["~/Development/personal", "~/Development/work", "~/Development/business-org"]

# Audit configuration
[audit]
dir = "~/Library/Application Support/devops.mcp"
kind = "sqlite"  # or "jsonl"
retainDays = 30
maxBlobBytes = 262144
fallbackJsonl = true

# Rate limits
[limits]
default_rps = 2
read_only_rps = 5
pkg_admin_rps = 0.2
secrets_rps = 0.2

# Capability assignments
[capabilities]
mcp_health = "read_only"
policy_manifest = "read_only"
dotfiles_state = "read_only"
pkg_inventory = "read_only"
repo_status = "read_only"
pkg_sync_plan = "pkg_admin"
pkg_sync_apply = "pkg_admin"
dotfiles_apply = "mutate_repo"
patch_apply_check = "mutate_repo"
system_converge = "pkg_admin"

# Secret management
[secrets]
gopass_roots = ["personal/devops/*", "org/*"]
gopass_storeDir = "~/.password-store"

# Package management
[pkg]
apply_mode = "per-op"  # or "bundle"
brew_bundle_file = "~/Brewfile"
brew_bundle_cleanup = false
mise_mode = "per-op"

# Timeouts
[timeouts]
default = "30s"
brew = "300s"
mise = "120s"
chezmoi = "60s"
git = "60s"

# Telemetry (Stage-7)
[telemetry]
enabled = true
export = "otlp"                      # "otlp" or "none"
endpoint = "http://127.0.0.1:4318"   # OTLP HTTP endpoint
protocol = "http"                    # "http" or "grpc"
sample_ratio = 1.0                   # 1.0 = 100% sampling
env = "local"                        # "local", "ci", or "prod"

[telemetry.logs]
level = "info"                       # debug|info|warn|error
sink = "stderr"                      # stderr|file
attributes_allowlist = []            # Extra OTLP log attributes

[telemetry.redact]
paths = ["secrets.api", "*.session"] # Additional redaction patterns
censor = "[REDACTED]"

# SLOs (Service Level Objectives)
[slos]
maxResidualPctAfterApply = 0        # No residuals allowed
maxConvergeDurationMs = 120000       # 2 minute max
maxDroppedPer5m = 0                 # No telemetry drops allowed
```

### 3. Claude Code Integration

Add to your Claude Code MCP configuration:

```json
{
  "mcpServers": {
    "devops-local": {
      "command": "node",
      "args": ["~/Development/personal/devops-mcp/dist/index.js"],
      "disabled": false
    }
  }
}
```

### 4. Run the Server

#### Development Mode
```bash
cd ~/Development/personal/devops-mcp
pnpm dev  # Runs with tsx, no build required
```

#### Production Mode
```bash
pnpm build
pnpm start
```

#### As launchd Service (macOS)
```bash
# Install the service
launchctl bootstrap gui/$UID examples/devops.mcp.plist

# Start/restart
launchctl kickstart -k gui/$UID/local.devops.mcp

# Check logs
tail -f ~/Library/Application\ Support/devops.mcp/server.log
```

## Available Tools

### Read-Only Tools

| Tool | Description | Requirements |
|------|-------------|--------------|
| `mcp_health` | Server health and policy status | None |
| `patch_apply_check` | Validate diff without applying | Repository path |

### Planning Tools

| Tool | Description | Requirements |
|------|-------------|--------------|
| `pkg_sync_plan` | Plan Homebrew/mise changes | Brewfile/misefile content |
| `system_plan` | Plan from system repo | Profile name |

### Mutating Tools (Gated)

| Tool | Description | Requirements |
|------|-------------|--------------|
| `pkg_sync_apply` | Apply package changes | Plan + `confirm=true` |
| `dotfiles_apply` | Apply chezmoi changes | `confirm=true` |
| `system_converge` | Full system convergence | Profile + `confirm=true` |
| `converge_host` | Local host convergence | Project path + `confirm=true` |

### Secret Management

| Tool | Description | Requirements |
|------|-------------|--------------|
| `secrets_read_ref` | Get opaque secret reference | Gopass path (allowlisted) |

## Available Resources

| Resource | URI | Description |
|----------|-----|-------------|
| `policy_manifest` | `devops://policy_manifest` | Current policy configuration |
| `dotfiles_state` | `devops://dotfiles_state` | Chezmoi state |
| `pkg_inventory` | `devops://pkg_inventory` | Installed packages |
| `repo_status` | `devops://repo_status` | Repository status |
| `system_repo_state` | `devops://system_repo_state` | System repo state (Stage-6) |
| `policy_manifest_repo` | `devops://policy_manifest_repo` | Repo policy (Stage-6) |
| `telemetry_info` | `devops://telemetry_info` | Telemetry endpoints & config (Stage-7) |

## Convergence Workflow

### Stage-6 Repo-Authority Flow

The new system convergence flow ensures all changes are driven from a pinned git commit:

```mermaid
graph TD
    A[system_converge] --> B[Sync Repository]
    B --> C[Verify Signature]
    C --> D[Validate Policy]
    D --> E{Policy Pass?}
    E -->|No| F[Abort]
    E -->|Yes| G[Generate Plan]
    G --> H[Apply Packages]
    H --> I{Packages OK?}
    I -->|No| F
    I -->|Yes| J[Apply Dotfiles]
    J --> K[Verify Residuals]
    K --> L[Complete]
```

### Circuit-Breaking

The server implements defensive circuit-breaking:
- Aborts if policy validation fails
- Aborts if package application fails (`ok=false`)
- Never attempts dotfiles if packages fail
- Single retry on transient package failures
- Timeout enforcement per step

### Lock Ordering

To prevent deadlocks:
1. Package lock acquired first
2. Dotfiles lock acquired second
3. Locks released immediately after use
4. Short-lived locks (< timeout)

## INERT Mode (Testing)

Run without system mutations:

```bash
export DEVOPS_MCP_INERT=1
pnpm dev
```

In INERT mode:
- All mutations return `inert=true`
- State files written for verification
- Subsequent plans should be no-ops
- Useful for CI/CD validation

## Dashboard HTTP Bridge

The MCP server includes an optional HTTP bridge for dashboard integration, providing REST-like access to telemetry and audit data.

### Configuration

Add to `~/.config/devops-mcp/config.toml`:

```toml
[dashboard_bridge]
enabled = true
port = 3001  # 0 for random port
token = "your-secret-bearer-token"
allowed_origins = ["http://localhost:5173", "http://localhost:3000"]
```

### Available Endpoints

When enabled, the bridge provides:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/telemetry` | GET | Telemetry configuration and status |
| `/api/logs` | GET | Recent log entries (last 100 lines) |
| `/api/audit` | GET | Recent audit entries |

### Security Features

- **Rate limiting**: 5 requests per second per IP
- **Bearer token authentication**: Required if configured
- **CORS support**: Only configured origins allowed
- **Read-only access**: No mutations possible via HTTP

### Usage Example

```bash
# Get telemetry info
curl -H "Authorization: Bearer your-secret-bearer-token" \
  http://localhost:3001/api/telemetry

# Get recent logs
curl -H "Authorization: Bearer your-secret-bearer-token" \
  http://localhost:3001/api/logs

# From dashboard JavaScript
fetch('http://localhost:3001/api/telemetry', {
  headers: {
    'Authorization': 'Bearer your-secret-bearer-token'
  }
})
.then(res => res.json())
.then(data => console.log(data));
```

The bridge starts automatically when `dashboard_bridge.enabled = true` and provides a lightweight HTTP interface for dashboards that can't use the MCP protocol directly.

## Telemetry & Observability

The MCP server includes comprehensive OpenTelemetry instrumentation providing:

### Telemetry Streams

**Traces**: End-to-end request tracking
- Every MCP request creates a root span
- Child spans for pkg operations, dotfiles, locks
- Trace IDs correlate across all telemetry

**Metrics**: RED (Rate/Error/Duration) + USE (Utilization/Saturation/Errors)
- `mcp_tool_requests_total{tool}` - Request counts
- `mcp_tool_duration_ms{tool}` - Latency histograms
- `converge_residual_count{kind}` - Post-apply residuals
- `locks_contention_ms{lock}` - Lock wait times

**Logs**: Structured JSON with trace correlation
- Pino logger with automatic redaction
- ServiceStart banner on startup
- SLO breach events
- Audit correlation via IDs

### Checking Telemetry Status

```bash
# Fetch telemetry configuration
echo '{"method": "resources/read", "params": {"uri": "devops://telemetry_info"}}' | \
  node ~/Development/personal/devops-mcp/dist/index.js | jq

# Response includes:
# - OTLP endpoints and reachability
# - Log sinks (file paths or stderr)
# - Redaction patterns
# - SLO thresholds
# - Contract version
```

### Log Locations

**Development** (with TTY):
- Pretty logs to console
- JSON logs to `~/Library/Application Support/devops.mcp/logs/server.ndjson`
- Daily rotation with 7-day retention

**Production** (no TTY):
- JSON logs to stderr for collector ingestion
- OTLP log export if configured

### Dashboard Integration

The telemetry data integrates with:
- System dashboard at `~/Development/personal/system-dashboard`
- Grafana dashboards (if configured)
- Any OpenTelemetry-compatible backend

See [MCP Telemetry Configuration](./mcp-telemetry.md) for detailed setup.

## Audit & Compliance

### Viewing Audit Logs

SQLite:
```sql
-- Connect to audit database
sqlite3 ~/Library/Application\ Support/devops.mcp/audit.sqlite3

-- Recent operations
SELECT * FROM calls ORDER BY ts DESC LIMIT 10;

-- Find specific audit ID
SELECT * FROM calls WHERE id = '<audit_id>';

-- Operations by tool
SELECT tool, COUNT(*) FROM calls GROUP BY tool;
```

JSONL:
```bash
# Search by audit ID
rg '<audit_id>' ~/Library/Application\ Support/devops.mcp/audit.jsonl

# Recent operations
tail -n 20 ~/Library/Application\ Support/devops.mcp/audit.jsonl | jq
```

### Audit Fields

Each audit entry contains:
- `id`: UUID for correlation
- `ts`: ISO timestamp
- `tool`/`resource`: Operation name
- `args`: Sanitized arguments (secrets hashed)
- `result`: Operation outcome
- `repo_commit`: Source commit (Stage-6)
- `plan_sha`: Plan hash for verification
- `duration_ms`: Execution time

## Integration Testing

Run the integration test suite:

```bash
cd ~/Development/personal/devops-mcp

# INERT mode (no mutations)
DEVOPS_MCP_INERT=1 npm run integration:smoke

# Real mode (applies changes)
npm run integration:smoke
```

The integration tests verify:
- Protocol negotiation
- Tool registration
- Resource availability
- Rate limiting
- Audit logging
- INERT mode behavior

## Troubleshooting

### Common Issues

**Server won't start**
- Verify Node 24: `node --version`
- Check config exists: `ls ~/.config/devops-mcp/config.toml`
- Review logs: `tail -f ~/Library/Application\ Support/devops.mcp/server.err`

**Rate limiting (429 errors)**
- Check limits in config.toml
- Review audit log for frequency
- Adjust `[limits]` section

**Permission denied**
- Verify paths in `[allow]` section
- Check command in allowlist
- Review audit log for denied operations

**INERT mode issues**
- Ensure `DEVOPS_MCP_INERT=1` is exported
- Check for state files in audit dir
- Verify plans show no-ops on re-run

### Debug Output

Enable verbose logging:
```bash
DEBUG=mcp:* pnpm dev
```

View server readiness:
```bash
# Server writes "READY <epoch>" when initialized
pnpm dev 2>&1 | grep READY
```

## CI/CD Integration

### GitHub Actions (Non-Mutating)

For PR validation in system-setup repo:

```yaml
name: MCP Validation
on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '24'

      - name: Setup MCP
        run: |
          cd ../
          git clone https://github.com/verlyn13/devops-mcp.git
          cd devops-mcp
          npm install
          npm run build

      - name: Run INERT validation
        env:
          DEVOPS_MCP_INERT: "1"
        run: |
          node ../devops-mcp/dist/index.js &
          MCP_PID=$!
          sleep 2

          # Run system_plan
          echo '{"profile":"ci","ref":"HEAD"}' | \
            node -e "/* call system_plan */"

          kill $MCP_PID

      - name: Upload plan
        uses: actions/upload-artifact@v4
        with:
          name: system-plan
          path: plan.json
```

## Performance Considerations

### Resource Usage
- Memory: ~50MB baseline, ~100MB under load
- CPU: <1% idle, spikes during operations
- Disk: Audit log growth ~1MB/day typical

### Optimization Tips
- Use SQLite audit for better performance
- Adjust rate limits based on usage patterns
- Enable log rotation in production
- Consider bundle mode for large package operations

## Security Best Practices

1. **Never commit config.toml** with secrets
2. **Restrict gopass_roots** to minimum paths
3. **Review audit logs** regularly
4. **Rotate credentials** used by MCP
5. **Monitor rate limit violations**
6. **Keep Node 24** updated
7. **Use signed commits** for system repo

## Future Enhancements

### Planned (Next Sprint)
- [ ] Bundle mode for Homebrew operations
- [ ] Negotiated protocol in health endpoint
- [ ] Daily log rotation
- [ ] Attestation files for applied changes

### Under Consideration
- [ ] OpenTelemetry integration
- [ ] Prometheus metrics export
- [ ] Web UI for audit viewing
- [ ] Multi-profile concurrent operations
- [ ] Rollback capabilities

## Related Documentation

- [System Overview](../../SYSTEM-OVERVIEW.md)
- [Policy Framework](../../04-policies/policy-as-code.yaml)
- [Chezmoi Configuration](../tools/chezmoi-config.md)
- [Package Management](../tools/package-management.md)
- [Security Setup](../../01-setup/05-security.md)