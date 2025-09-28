---
title: MCP Server & Dashboard Integration
category: reference
component: integration
status: active
version: 1.0.0
last_updated: 2025-09-27
tags: [mcp, dashboard, telemetry, integration, monitoring]
priority: high
---

# MCP Server & Dashboard Integration

## Overview

This document describes how the DevOps MCP server, System Dashboard, and system-setup repository work together as an integrated system management platform. The integration provides real-time observability, policy enforcement, and AI-assisted automation for your development environment.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    system-setup-update (This Repo)              │
│  • Source of Truth: Policies, Configuration, Documentation      │
│  • Policy-as-Code definitions                                   │
│  • System validation scripts                                    │
└────────────────────────┬────────────────────────────────────────┘
                         │ Defines policies
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                        devops-mcp                               │
│  • Enforces policies via MCP protocol                          │
│  • Exposes tools/resources to AI agents                        │
│  • Generates telemetry (traces, metrics, logs)                │
│  • Maintains audit trail                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │ Telemetry via OTLP
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     system-dashboard                            │
│  • Visualizes telemetry data                                    │
│  • Shows compliance status                                      │
│  • Monitors convergence operations                              │
│  • Displays system health                                       │
└──────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Policy Definition → Enforcement

```yaml
# system-setup-update/04-policies/policy-as-code.yaml
tools:
  required:
    mise:
      min_version: "2024.1.0"
```
↓
```toml
# devops-mcp config enforces
[capabilities]
pkg_sync_apply = "pkg_admin"  # Gated by policy
```

### 2. MCP Operations → Telemetry

```javascript
// MCP server operation
converge_host({ project: "system-dashboard", confirm: true })
```
↓
```json
// Generates telemetry
{
  "trace_id": "abc123",
  "tool": "converge_host",
  "duration_ms": 5234,
  "audit_id": "uuid-789",
  "residual_counts": { "brew": 0, "mise": 0 }
}
```

### 3. Telemetry → Dashboard Visualization

The dashboard queries telemetry to show:
- Real-time convergence status
- Package inventory changes
- Policy compliance scores
- Audit trail with trace links

## Integration Points

### MCP Server → System Setup

**Policy Enforcement**:
- MCP server reads policies from system-setup repo
- Validates operations against policy-as-code.yaml
- Blocks non-compliant operations

**Configuration Source**:
- System repo provides Brewfiles, mise configs
- MCP uses repo-authority for reproducible operations
- All changes tracked to git commits

### MCP Server → Dashboard

**Telemetry Export**:
- OTLP traces to track operation flow
- Metrics for SLO monitoring
- Structured logs with trace correlation
- Domain events for convergence lifecycle

**Resource Access**:
```bash
# Dashboard fetches MCP telemetry info
curl -X POST http://localhost:3000/api/mcp/telemetry-info \
  -d '{"resource": "devops://telemetry_info"}'
```

### Dashboard → System Setup

**Compliance Monitoring**:
- Dashboard runs policy validation scripts
- Displays compliance percentage
- Links to relevant documentation

**Documentation Access**:
- Dashboard embeds links to system-setup docs
- Shows implementation status from MASTER-STATUS.md
- Provides context-aware help

## Configuration

### 1. MCP Server Config

`~/.config/devops-mcp/config.toml`:
```toml
[system_repo]
url = "git@github.com:verlyn13/system-setup-update.git"
branch = "main"
root = "/"

[telemetry]
enabled = true
export = "otlp"
endpoint = "http://127.0.0.1:4318"
protocol = "http"

[slos]
maxResidualPctAfterApply = 0
maxConvergeDurationMs = 120000
```

### 2. Dashboard Config

`~/Development/personal/system-dashboard/.env`:
```bash
# MCP Connection
MCP_SERVER_PATH=/Users/verlyn13/Development/personal/devops-mcp/dist/index.js
MCP_SERVER_NODE=/opt/homebrew/bin/node

# Telemetry Ingestion
OTLP_ENDPOINT=http://localhost:4318
ENABLE_TELEMETRY=true

# System Paths
SYSTEM_SETUP_PATH=/Users/verlyn13/Development/personal/system-setup-update
POLICY_FILE_PATH=/Users/verlyn13/Development/personal/system-setup-update/04-policies/policy-as-code.yaml
```

### 3. OpenTelemetry Collector

`~/.config/otel-collector/config.yaml`:
```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 127.0.0.1:4318
      grpc:
        endpoint: 127.0.0.1:4317

exporters:
  # Dashboard ingestion
  otlphttp/dashboard:
    endpoint: http://localhost:3000/api/telemetry

  # Persistent storage
  prometheusremotewrite:
    endpoint: http://localhost:9009/api/v1/write

  loki:
    endpoint: http://localhost:3100/loki/api/v1/push

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlphttp/dashboard]
    metrics:
      receivers: [otlp]
      exporters: [otlphttp/dashboard, prometheusremotewrite]
    logs:
      receivers: [otlp]
      exporters: [loki]
```

## Operations Playbook

### Starting the Stack

```bash
# 1. Start OpenTelemetry Collector
otelcol --config ~/.config/otel-collector/config.yaml

# 2. Start MCP Server
cd ~/Development/personal/devops-mcp
pnpm start  # or via launchd

# 3. Start Dashboard
cd ~/Development/personal/system-dashboard
bun run dev

# 4. Verify Integration
open http://localhost:5173  # Dashboard
curl http://localhost:13133/ # Collector health
```

### Monitoring a Convergence

1. **Trigger via Claude Code**:
```javascript
// In Claude Code with MCP enabled
await mcp.callTool('system_converge', {
  profile: 'personal',
  confirm: true
});
```

2. **Watch in Dashboard**:
- Navigate to Convergence tab
- See real-time progress bars
- View trace waterfall
- Check residual counts

3. **Verify in Audit**:
```sql
-- Query audit database
SELECT * FROM calls
WHERE tool = 'system_converge'
ORDER BY ts DESC LIMIT 1;
```

### Troubleshooting Integration

**No telemetry in dashboard**:
```bash
# Check MCP telemetry status
echo '{"method":"resources/read","params":{"uri":"devops://telemetry_info"}}' | \
  node ~/Development/personal/devops-mcp/dist/index.js | jq .contents[0].text | jq

# Verify collector is receiving
curl -s http://localhost:13133/metrics | grep otlp_receiver
```

**Policy misalignment**:
```bash
# Run validation in system-setup
cd ~/Development/personal/system-setup-update
python 04-policies/validate-policy.py

# Compare with MCP policy
echo '{"method":"resources/read","params":{"uri":"devops://policy_manifest"}}' | \
  node ~/Development/personal/devops-mcp/dist/index.js | jq
```

**Dashboard can't connect to MCP**:
```bash
# Test MCP server directly
echo '{"method":"tools/list"}' | \
  node ~/Development/personal/devops-mcp/dist/index.js

# Check dashboard logs
cd ~/Development/personal/system-dashboard
tail -f logs/dashboard.log
```

## Key Metrics & SLOs

### System-Wide SLOs

| Metric | Target | Source | Dashboard Panel |
|--------|--------|--------|-----------------|
| Convergence Success Rate | ≥99% | MCP metrics | Health Overview |
| P95 Convergence Duration | <120s | MCP traces | Performance |
| Policy Compliance | ≥95% | System validation | Compliance |
| Zero Residuals | 100% | MCP metrics | Convergence |
| Telemetry Drop Rate | 0% | Collector metrics | Observability |

### Alert Rules

Configured in dashboard and collector:

```javascript
// Dashboard alert configuration
const alerts = [
  {
    name: 'ConvergenceFailure',
    condition: 'converge_success_rate < 0.99',
    window: '30m',
    severity: 'warning'
  },
  {
    name: 'ResidualsPersist',
    condition: 'converge_residual_count > 0',
    window: '10m',
    severity: 'error'
  },
  {
    name: 'PolicyViolation',
    condition: 'policy_compliance_score < 0.95',
    window: '1h',
    severity: 'critical'
  }
];
```

## Security Considerations

### Data Privacy
- All telemetry is redacted before export
- Secret references are hashed, never logged
- PII is stripped from all streams

### Access Control
- MCP server uses capability tiers
- Dashboard requires authentication (if configured)
- Audit logs are append-only

### Network Security
- All components run locally by default
- OTLP can use TLS if configured
- No external data egress without explicit config

## Maintenance

### Daily Tasks
```bash
# Check system health
curl http://localhost:5173/api/health

# Review audit logs
sqlite3 ~/Library/Application\ Support/devops.mcp/audit.sqlite3 \
  "SELECT COUNT(*) as operations_today FROM calls WHERE date(ts) = date('now')"

# Check telemetry pipeline
curl -s http://localhost:13133/metrics | grep -E "(dropped|failed|error)"
```

### Weekly Tasks
- Review dashboard SLO trends
- Check for policy updates in system-setup
- Rotate logs if needed
- Update MCP server if new version available

### Monthly Tasks
- Full system validation
- Performance baseline review
- Update integration configurations
- Archive old telemetry data

## Future Enhancements

### Planned
- [ ] Bi-directional policy sync
- [ ] Dashboard-triggered convergence
- [ ] Real-time log streaming
- [ ] Automated remediation workflows
- [ ] Cost tracking integration

### Under Consideration
- [ ] Multi-environment support
- [ ] Team collaboration features
- [ ] External dashboard plugins
- [ ] ML-based anomaly detection
- [ ] Compliance reporting automation

## Related Documentation

- [MCP Server Configuration](../02-configuration/tools/mcp-server.md)
- [MCP Telemetry Configuration](../02-configuration/tools/mcp-telemetry.md)
- [System Dashboard README](~/Development/personal/system-dashboard/README.md)
- [Policy Framework](../04-policies/policy-as-code.yaml)
- [MASTER-STATUS](../MASTER-STATUS.md)