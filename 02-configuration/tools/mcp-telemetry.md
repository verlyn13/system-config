---
title: Mcp Telemetry
category: configuration
component: mcp_telemetry
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: [configuration, settings]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: medium
---


# MCP Server Telemetry Configuration

## Overview

The DevOps MCP server includes a comprehensive telemetry foundation based on OpenTelemetry (OTel) for distributed tracing, metrics collection, and structured logging. This provides real-time visibility into server operations, performance metrics, and system convergence activities while maintaining strict privacy controls.

## Architecture

### OpenTelemetry Stack (Implemented)

```
MCP Server (devops-mcp)
    ├── Traces (via @opentelemetry/sdk-node)
    │   └── OTLP HTTP/gRPC → Collector
    ├── Metrics (via @opentelemetry/sdk-node)
    │   └── OTLP HTTP/gRPC → Collector
    └── Logs (Pino + OTLP export)
        ├── JSON to stderr/file
        └── OTLP HTTP/gRPC → Collector

OTel Collector (localhost:4318 HTTP, 4317 gRPC)
    ├── Receivers: OTLP protocols
    ├── Processors: Batch, Redaction
    └── Exporters: Dashboard, Storage

System Dashboard
    └── Ingests telemetry for visualization
```

### Telemetry Components (Actual Implementation)

```
src/lib/telemetry/
├── otel.ts              # initTelemetry() - SDK setup with OTLP exporters
├── metrics.ts           # incTool(), observeToolDuration(), incToolError()
├── tracing.ts           # withSpan() wrapper for instrumentation
├── health.ts            # getReachability() - OTLP endpoint health check
├── info.ts              # getTelemetryInfo() - config & status for dashboards
├── contract.ts          # TELEMETRY_CONTRACT - types and vocabulary
├── profile_context.ts   # getProfileAttributes() - profile-aware metrics
└── ../logging/
    └── logger.ts        # Pino logger with redaction & OTLP transport
```

### Profile-Aware Telemetry

The MCP server tracks metrics by profile (personal, work, etc.) for better insights:

```typescript
// Automatically added to all tool metrics
const attrs = getProfileAttributes(profile);
// Adds: { profile: 'personal', host: 'macpro.local' }

// Metrics are then segmented:
mcp_tool_requests_total{tool="system_converge", profile="personal"}
mcp_tool_duration_ms{tool="dotfiles_apply", profile="work"}
```

This enables:
- Per-profile SLO tracking
- Multi-environment monitoring
- Profile-specific alerting
- Usage pattern analysis

## Configuration

### MCP Server Config

Add to `~/.config/devops-mcp/config.toml`:

```toml
[telemetry]
enabled = true
export = "otlp"                      # "otlp" | "none"
endpoint = "http://127.0.0.1:4318"   # OTLP HTTP endpoint
protocol = "http"                    # "grpc" | "http"
sample_ratio = 1.0                   # 1.0 = 100% sampling
metrics_histogram = "exponential"    # Better tail accuracy
redact = ["OPENAI_API_KEY", "GITHUB_TOKEN", "gopass"]
max_attr_bytes = 2048
max_log_bytes = 8192
env = "local"                        # "local" | "ci" | "prod"

[telemetry.resource]
service_name = "devops-mcp"
service_version = "0.3.0"
deployment_environment = "local"

[telemetry.logs]
level = "info"                       # "debug" | "info" | "warn" | "error"
sink = "stderr"                      # "stderr" | "file"
format = "json"                      # "json" | "text"

[telemetry.security]
hash_repo_urls = true                # Hash full URLs
strip_pii = true                     # Remove personal data
audit_telemetry = true               # Log telemetry operations
```

### OpenTelemetry Collector

Install and configure the collector at `~/.config/otel-collector/config.yaml`:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 127.0.0.1:4317
      http:
        endpoint: 127.0.0.1:4318

processors:
  batch:
    timeout: 5s
    send_batch_size: 1024

  attributes/redact:
    actions:
      - key: secret.*
        action: delete
      - key: password
        action: delete
      - key: token
        action: delete

  resource:
    attributes:
      - key: host.name
        action: hash
      - key: host.id
        action: hash

exporters:
  # Console logging (development)
  logging:
    loglevel: warn

  # Prometheus metrics
  prometheusremotewrite:
    endpoint: http://localhost:9009/api/v1/write

  # Tempo traces
  otlp/tempo:
    endpoint: http://localhost:14250
    tls:
      insecure: true

  # Loki logs
  loki:
    endpoint: http://localhost:3100/loki/api/v1/push
    labels:
      attributes:
        service_name: service.name
        level: severity_text

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, attributes/redact]
      exporters: [otlp/tempo, logging]

    metrics:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [prometheusremotewrite]

    logs:
      receivers: [otlp]
      processors: [batch, attributes/redact]
      exporters: [loki, logging]
```

## Instrumentation

### Traces

Every MCP request creates a trace with nested spans:

```
mcp.request (root span)
├── attributes:
│   ├── mcp.method: "tools/call"
│   ├── mcp.tool: "system_converge"
│   ├── system.repo.commit: "abc123"
│   ├── policy.version: "1.0.0"
│   └── plan.sha: "def456"
│
├── pkg.plan
│   ├── brew.list (100ms)
│   └── mise.list (50ms)
│
├── pkg.apply
│   ├── locks.acquire (2ms)
│   ├── brew.install (5s per package)
│   ├── mise.install (3s per runtime)
│   └── locks.release (1ms)
│
├── dotfiles.apply
│   ├── chezmoi.diff (200ms)
│   └── chezmoi.apply (1s)
│
└── audit.write (10ms)
```

### Metrics

#### RED Metrics (Request/Error/Duration)

```prometheus
# Request rate
mcp_tool_requests_total{tool="system_converge"}

# Error rate
mcp_tool_errors_total{tool="system_converge", error_kind="validation_failed"}

# Duration histogram
mcp_tool_duration_ms{tool="system_converge", quantile="0.95"}

# Rate limiting
mcp_tool_ratelimit_dropped_total{tool="secrets_read_ref"}
```

#### Convergence Metrics

```prometheus
# Convergence runs
converge_runs_total{profile="personal", mode="real"}
converge_success_total{profile="personal"}
converge_abort_total{reason="pkg_failed"}

# Residuals (should be zero)
converge_residual_count{kind="brew"}
converge_residual_count{kind="mise"}
converge_residual_count{kind="dotfiles"}

# Lock contention
locks_contention_ms{lock="pkg", quantile="0.99"}

# Audit performance
audit_queue_flush_ms{quantile="0.95"}
```

#### Security Metrics

```prometheus
# Secret access
secrets_requests_total
secrets_denied_total{reason="path_not_allowed"}
secrets_duration_ms{quantile="0.95"}

# Policy validation
policy_validate_total{result="pass"}
policy_violations_total{severity="critical"}
```

### Structured Logs

JSON logs with trace correlation:

```json
{
  "ts": "2025-09-27T10:30:45.123Z",
  "level": "info",
  "msg": "Converge completed",
  "trace_id": "7b3f1c2d4e5f6789",
  "span_id": "a1b2c3d4",
  "tool": "system_converge",
  "duration_ms": 8234,
  "audit_id": "uuid-123",
  "repo_commit": "abc123def",
  "plan_sha": "sha256:789xyz",
  "residual_counts": {
    "brew": 0,
    "mise": 0,
    "dotfiles": 0
  }
}
```

## Domain Events

The MCP server emits structured domain events for dashboard consumption:

### Event Types

```typescript
// Planning completed
interface ConvergePlanned {
  trace_id: string;
  profile: string;
  commit: string;
  plan_sha: string;
  counts: {
    brew_installs: number;
    brew_upgrades: number;
    mise_installs: number;
    dotfiles_changes: number;
  };
}

// Application completed
interface ConvergeApplied {
  trace_id: string;
  audit_ids: {
    pkg?: string;
    dotfiles?: string;
  };
  residual_counts: Record<string, number>;
  ok: boolean;
  duration_ms: number;
}

// Convergence aborted
interface ConvergeAborted {
  trace_id: string;
  reason: string;
  step: string;
  error_kind: string;
}

// Policy validation
interface PolicyValidated {
  trace_id: string;
  commit: string;
  passed: boolean;
  violations: Array<{
    id: string;
    severity: 'critical' | 'high' | 'medium' | 'low';
  }>;
}

// Repository sync
interface RepoSynced {
  trace_id: string;
  url: string;
  commit: string;
  verified_sig: boolean;
  branch: string;
}
```

## Dashboard Integration

### Grafana Dashboard Panels

#### Overview Panel
```json
{
  "title": "MCP Server Overview",
  "panels": [
    {
      "id": "success_rate",
      "query": "converge_success_total / converge_runs_total",
      "visualization": "stat"
    },
    {
      "id": "p95_latency",
      "query": "histogram_quantile(0.95, mcp_tool_duration_ms)",
      "visualization": "graph"
    },
    {
      "id": "residuals",
      "query": "converge_residual_count",
      "visualization": "heatmap"
    }
  ]
}
```

#### Operations Panel
```json
{
  "title": "MCP Operations",
  "panels": [
    {
      "id": "request_rate",
      "query": "rate(mcp_tool_requests_total[5m])",
      "visualization": "timeseries"
    },
    {
      "id": "error_rate",
      "query": "rate(mcp_tool_errors_total[5m])",
      "visualization": "timeseries"
    },
    {
      "id": "rate_limits",
      "query": "rate(mcp_tool_ratelimit_dropped_total[5m])",
      "visualization": "timeseries"
    }
  ]
}
```

### System Dashboard Integration

The system dashboard at `~/Development/personal/system-dashboard` can query telemetry:

```typescript
// Query recent convergence events
const events = await fetch('http://localhost:3100/loki/api/v1/query', {
  method: 'POST',
  body: JSON.stringify({
    query: '{service_name="devops-mcp"} |= "ConvergeApplied"',
    limit: 100
  })
});

// Link to trace view
const traceUrl = `http://localhost:16686/trace/${event.trace_id}`;

// Query current metrics
const metrics = await fetch('http://localhost:9090/api/v1/query', {
  method: 'POST',
  body: new URLSearchParams({
    query: 'converge_residual_count'
  })
});
```

## Privacy & Security

### Redaction Rules

The telemetry system enforces strict redaction:

```typescript
// Never logged/exported
const REDACT_PATTERNS = [
  /OPENAI_API_KEY=.*/,
  /GITHUB_TOKEN=.*/,
  /password[:=].*/i,
  /secret[:=].*/i,
  /token[:=].*/i,
  /key[:=].*/i,
  /Bearer .*/,
  /Basic .*/
];

// Hashed before export
const HASH_FIELDS = [
  'host.name',
  'host.id',
  'user.name',
  'repo.url.full'
];

// Size limits
const MAX_ATTRIBUTE_SIZE = 2048;
const MAX_LOG_SIZE = 8192;
```

### Cardinality Control

Prevent metric explosion:

```typescript
// Good: Low cardinality
metrics.inc({ tool: "pkg_sync", status: "success" });

// Bad: High cardinality (DON'T DO)
metrics.inc({ tool: "pkg_sync", package: packageName });

// Instead: Use exemplars
metrics.inc(
  { tool: "pkg_sync" },
  { exemplar: { package_hash: hash(packageName) } }
);
```

## SLOs & Alerting

### Service Level Objectives

| SLO | Target | Alert Threshold | Window |
|-----|--------|-----------------|--------|
| Convergence Success Rate | ≥99% | <97% | 30m |
| P95 Latency | <10s | >30s | 15m |
| Zero Residuals | 100% | Any >0 | 2 runs |
| Rate Limit Health | <10/hr | >30/hr | 10m |
| Secret Denials | 0 | Any | 1h |
| Audit Integrity | 100% | Failure | 5m |

### Alert Rules

```yaml
# Prometheus alert rules
groups:
  - name: mcp_server
    rules:
      - alert: ConvergenceFailureRate
        expr: |
          (1 - (
            rate(converge_success_total[30m]) /
            rate(converge_runs_total[30m])
          )) > 0.03
        for: 30m
        annotations:
          summary: "High convergence failure rate: {{ $value | humanizePercentage }}"

      - alert: ResidualsPersist
        expr: converge_residual_count > 0
        for: 10m
        annotations:
          summary: "Residuals persist after convergence"

      - alert: SecretAccessDenied
        expr: increase(secrets_denied_total[1h]) > 0
        annotations:
          summary: "Secret access denied: {{ $value }} attempts"
```

## Running the Stack

### Local Development

```bash
# 1. Start OTel Collector (if using external backends)
otelcol --config ~/.config/otel-collector/config.yaml

# 2. Run MCP server with telemetry
cd ~/Development/personal/devops-mcp
pnpm dev  # Development mode with pretty logs

# 3. Check telemetry status
echo '{"method":"resources/read","params":{"uri":"devops://telemetry_info"}}' | \
  node dist/index.js | jq '.contents[0].text' | jq

# 4. Start system dashboard
cd ~/Development/personal/system-dashboard
bun run dev
open http://localhost:5173

# 5. Monitor logs
tail -f ~/Library/Application\ Support/devops.mcp/logs/server.ndjson | jq
```

### Production Setup

```bash
# Install as services
brew services start opentelemetry-collector
launchctl load ~/Library/LaunchAgents/devops.mcp.plist

# Monitor
tail -f ~/Library/Application\ Support/devops.mcp/telemetry.log
```

## Performance Impact

### Resource Overhead
- CPU: <2% for telemetry processing
- Memory: ~10MB for buffers and state
- Network: ~1KB/s at normal operation
- Disk: ~100MB/day for local metrics

### Optimization Tips
- Use sampling in production (0.1-0.2 ratio)
- Enable batch processing (5s timeout)
- Set retention policies (7d traces, 30d metrics)
- Use delta temporality for counters
- Enable compression on exporters

## Troubleshooting

### No Telemetry Data

```bash
# Check collector is running
curl http://localhost:13133/  # Collector health

# Verify MCP config
grep telemetry ~/.config/devops-mcp/config.toml

# Check export endpoint
nc -zv localhost 4317  # gRPC
nc -zv localhost 4318  # HTTP

# Enable debug logging
export OTEL_LOG_LEVEL=debug
```

### High Cardinality

```sql
-- Find high cardinality series in Prometheus
SELECT COUNT(DISTINCT series)
FROM prometheus_tsdb_symbol_table_size_bytes;

-- Identify problematic labels
SELECT label_name, COUNT(DISTINCT label_value)
FROM prometheus_tsdb_cardinality_by_label_pair
GROUP BY label_name
ORDER BY 2 DESC;
```

### Missing Traces

```bash
# Check sampling ratio
grep sample_ratio ~/.config/devops-mcp/config.toml

# Verify trace propagation
export OTEL_TRACES_EXPORTER=logging
pnpm dev  # Should log spans to console

# Check collector pipeline
grep -A5 "traces:" ~/.config/otel-collector/config.yaml
```

## Future Enhancements

### Planned
- [ ] Custom dashboard templates
- [ ] Automated anomaly detection
- [ ] Cost tracking metrics
- [ ] SLO burn rate alerts
- [ ] Trace-to-log correlation

### Under Consideration
- [ ] eBPF-based network observability
- [ ] Continuous profiling integration
- [ ] ML-based root cause analysis
- [ ] Synthetic monitoring probes
- [ ] Distributed tracing for git operations

## Related Documentation

- [MCP Server Configuration](./mcp-server.md)
- [System Dashboard](../../system-dashboard/README.md)
- [Audit & Compliance](../../04-policies/audit-policy.md)
- [OpenTelemetry Docs](https://opentelemetry.io/docs/)
- [Grafana Dashboard Examples](https://grafana.com/grafana/dashboards/)