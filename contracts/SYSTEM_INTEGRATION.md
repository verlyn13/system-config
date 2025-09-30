# System Configuration Integration Guide

## 🎯 Overview

The core system configuration now provides:
1. **Project Manifests** - Standardized service metadata
2. **MCP Server** - System monitoring and contract validation
3. **Real-time Dashboard** - Live compliance monitoring
4. **Contract Enforcement** - Multi-layer quality gates

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Services Layer                        │
├───────────────┬─────────────┬─────────────┬─────────────┤
│    ds-go      │ devops-mcp  │  dashboard  │ system-setup│
│ manifest.json │manifest.json│manifest.json│manifest.json│
└───────┬───────┴──────┬──────┴──────┬──────┴──────┬──────┘
        │              │             │              │
        └──────────────┼─────────────┼──────────────┘
                       ▼             ▼
        ┌──────────────────────────────────────────┐
        │         MCP System Monitor Server        │
        │  • Service Discovery                     │
        │  • Health Checking                       │
        │  • Compliance Validation                 │
        │  • Observation Collection                │
        └──────────────┬───────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────────┐
        │       Dashboard Server (Port 8089)       │
        │  • Real-time Monitoring                  │
        │  • SLO Breach Detection                  │
        │  • Violation Tracking                    │
        │  • SSE Updates                          │
        └──────────────────────────────────────────┘
```

## 🚀 Getting Started

### 1. Install Dependencies

```bash
# Dashboard server
cd ~/Development/personal/system-setup-update/contracts/dashboard
npm install

# MCP server
cd ~/Development/personal/mcp-servers/system-monitor
npm install
```

### 2. Start the Dashboard Server

```bash
cd ~/Development/personal/system-setup-update/contracts/dashboard
npm start

# Dashboard will be available at http://localhost:8089
```

### 3. Configure MCP Server (Optional)

Add to your Claude desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "system-monitor": {
      "command": "node",
      "args": [
        "/Users/verlyn13/Development/personal/mcp-servers/system-monitor/index.js"
      ]
    }
  }
}
```

## 📋 Project Manifests

Each core service has a `manifest.json` that defines:

### Required Fields
```json
{
  "apiVersion": "manifest.v1",
  "kind": "ProjectManifest",
  "metadata": {
    "name": "service-name",
    "repository": "https://github.com/user/repo",
    "created": "ISO-8601",
    "updated": "ISO-8601"
  },
  "spec": {
    "type": "service|library|tool|documentation",
    "language": "go|node|python|mixed",
    "contracts": {
      "enabled": true,
      "mode": "enforce|monitor|disabled",
      "slo": {
        "response_time_p95": 200,
        "error_rate": 0.05,
        "availability": 99.9
      }
    }
  },
  "status": {
    "phase": "running|degraded|stopped|error",
    "metrics": {
      "response_time_p95": 185,
      "error_rate": 0.02,
      "availability": 99.95
    }
  }
}
```

### Current Manifests

| Service | Location | SLO p95 | Error Rate | Availability |
|---------|----------|---------|------------|--------------|
| ds-go | `~/Development/personal/ds-go/manifest.json` | 200ms | 5% | 99.9% |
| system-setup-update | `~/Development/personal/system-setup-update/manifest.json` | 500ms | 10% | 99.0% |
| devops-mcp | *To be created* | 300ms | 1% | 99.95% |
| system-dashboard | *To be created* | 750ms | 20% | 99.5% |

## 🔧 MCP Server Tools

The system-monitor MCP server provides:

### Available Tools

1. **get_manifest** - Get project manifest for a service
2. **list_services** - List all services with manifests
3. **check_health** - Check health status of a service
4. **get_compliance** - Get contract compliance status
5. **get_metrics** - Get current metrics for a service
6. **validate_observation** - Validate an observation
7. **send_observation** - Send an observation to the system

### Example Usage (in Claude)

```
Use the system-monitor MCP server to check compliance across all services

Use the system-monitor MCP server to get the manifest for ds-go

Use the system-monitor MCP server to validate this observation: {
  "apiVersion": "obs.v1",
  "run_id": "test-123",
  "timestamp": "2025-09-28T12:00:00Z",
  "project_id": "ds-go:verlyn13/ds-go",
  "observer": "git",
  "summary": "Test observation",
  "metrics": {"duration_ms": 100},
  "status": "completed"
}
```

## 📊 Dashboard Features

### Real-time Metrics
- Overall compliance percentage
- Service count and status
- Active violations
- SLO breaches
- Observer mappings

### Service Cards
Each service shows:
- Compliance status (compliant/partial/non-compliant)
- Current metrics vs SLO thresholds
- Response time, error rate, availability
- Contract enforcement mode

### Violation Stream
- Real-time violation updates
- Severity indicators
- Service attribution
- Timestamp tracking

### API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Dashboard HTML |
| `GET /api/services` | List all services with status |
| `GET /api/compliance` | Overall compliance metrics |
| `GET /api/metrics/:service` | Service-specific metrics |
| `GET /api/observations` | Recent observations |
| `GET /api/violations` | Current violations |
| `GET /api/stream` | SSE real-time updates |
| `GET /health` | Server health check |

## 🔄 Data Flow

### 1. Service → Manifest
```bash
# Each service updates its manifest.json with current status
{
  "status": {
    "phase": "running",
    "metrics": {
      "response_time_p95": 185,
      "error_rate": 0.02,
      "availability": 99.95
    },
    "lastObservation": "2025-09-28T12:30:00Z"
  }
}
```

### 2. Dashboard → Manifests
```javascript
// Dashboard reads manifests every 30 seconds
const services = await glob('~/Development/personal/*/manifest.json');
```

### 3. Dashboard → Browser
```javascript
// SSE updates pushed to browser
event: update
data: {"services": 2, "compliance": "94.2%"}
```

## 🎯 Contract Compliance Flow

```
1. Service generates observation
   ↓
2. Pre-commit hook validates
   ↓
3. CI/CD pipeline checks
   ↓
4. Runtime middleware enforces
   ↓
5. MCP server validates
   ↓
6. Dashboard displays status
```

## 🚨 SLO Breach Detection

The system automatically detects SLO breaches:

```javascript
// Example breach detection
if (metrics.response_time_p95 > slo.response_time_p95) {
  breach = {
    metric: 'response_time_p95',
    threshold: 200,
    actual: 215,
    severity: 'warning'
  };
}
```

Breaches are:
- Displayed in dashboard
- Sent via SSE to connected clients
- Logged for analysis
- Can trigger alerts (webhook configured)

## 📈 Monitoring Best Practices

### 1. Update Manifests Regularly
Services should update their `manifest.json` status section with current metrics.

### 2. Use Proper Observer Names
Always use external observer names in manifests:
- ✅ `git` (not `repo`)
- ✅ `mise` (not `deps`)
- ❌ Never use `quality`

### 3. Monitor Dashboard
Keep the dashboard open during development to see real-time compliance.

### 4. Respond to Violations
When violations appear:
1. Check the service logs
2. Review recent changes
3. Fix the violation
4. Update the manifest

## 🔐 Security Considerations

### Dashboard Access
Currently runs on `localhost:8089` without authentication. For production:
- Add authentication middleware
- Use HTTPS
- Restrict CORS origins

### Manifest Validation
All manifests are validated against schema before use.

### MCP Server
Runs with stdio transport, inherits Claude's permissions.

## 🛠️ Troubleshooting

### Dashboard Not Loading Services
```bash
# Check manifest files exist
ls ~/Development/personal/*/manifest.json

# Check dashboard server logs
npm start
```

### MCP Server Not Responding
```bash
# Test MCP server directly
cd ~/Development/personal/mcp-servers/system-monitor
node index.js
# Should output: "System Monitor MCP Server running"
```

### Compliance Shows 0%
- Ensure manifests have `spec.contracts.enabled: true`
- Check `status.metrics` are populated
- Verify SLO thresholds are reasonable

## 📚 Next Steps

1. **Add Missing Manifests**
   - Create manifests for `devops-mcp` and `system-dashboard` when repos exist

2. **Automate Manifest Updates**
   - Services should update their manifest.json automatically
   - Use GitHub Actions to update on deploy

3. **Enhance Dashboard**
   - Add historical graphs
   - Implement alert notifications
   - Add drill-down views

4. **Expand MCP Tools**
   - Add remediation actions
   - Implement auto-fix capabilities
   - Add predictive analytics

---

The integrated system provides a complete view of contract compliance and service health across your entire development environment.