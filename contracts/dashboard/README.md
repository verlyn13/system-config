# System Compliance Dashboard

## ⚠️ IMPORTANT: SINGLE DASHBOARD PORT

**THE DASHBOARD ALWAYS RUNS ON PORT 8089**
- Configuration: `config.json`
- URL: **http://localhost:8089**
- No other ports are used for the dashboard

## 🚀 Quick Start

```bash
# Start the dashboard (ALWAYS on port 8089)
./start-dashboard.sh

# Or manually:
npm install
npm start
```

Then open: **http://localhost:8089** (THE ONLY DASHBOARD URL)

## 📊 Dashboard Features

### Tabs

1. **Overview** - System-wide metrics and service summary
2. **Services** - Detailed view of all services
3. **Observers** - Active observers and recent observations
4. **Violations** - Contract violations and SLO breaches

### Real-time Updates

- Server-Sent Events (SSE) for live updates
- Auto-refresh every 30 seconds (toggleable)
- Manual refresh button

## 🔧 How It Works

### Data Sources

The dashboard reads `manifest.json` files from service directories:

```
~/Development/personal/
├── ds-go/
│   └── manifest.json          ← Service manifest
├── system-setup-update/
│   └── manifest.json          ← Service manifest
├── devops-mcp/
│   └── manifest.json          ← (Create when repo exists)
└── system-dashboard/
    └── manifest.json          ← (Create when repo exists)
```

### Manifest Structure

Each service needs a `manifest.json` with:

```json
{
  "apiVersion": "manifest.v1",
  "kind": "ProjectManifest",
  "metadata": {
    "name": "service-name",
    "repository": "https://github.com/user/repo"
  },
  "spec": {
    "type": "service",
    "language": "go",
    "contracts": {
      "enabled": true,
      "mode": "enforce",
      "slo": {
        "response_time_p95": 200,
        "error_rate": 0.05,
        "availability": 99.9
      }
    }
  },
  "status": {
    "phase": "running",
    "metrics": {
      "response_time_p95": 185,
      "error_rate": 0.02,
      "availability": 99.95
    }
  }
}
```

## 📡 API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Dashboard HTML interface |
| `GET /api/services` | List all services with manifests |
| `GET /api/compliance` | Overall compliance metrics |
| `GET /api/metrics/:service` | Service-specific metrics |
| `GET /api/observations` | Recent observations |
| `GET /api/violations` | Current violations |
| `GET /api/stream` | SSE real-time updates |
| `GET /health` | Server health check |

## 🎯 Observers

### What Are Observers?

Observers are components that monitor and report on different aspects of your services:

- **git** - Repository and code analysis
- **mise** - Dependency management
- **sbom** - Software Bill of Materials
- **build** - Build system events
- **manifest** - Service manifest updates

### "Run Observers" Button

When you click "Run Observers" in the Observers tab:

1. Dashboard collects current observations from service manifests
2. Shows recent observations in the list
3. Updates observer counts

**Note**: Observations are generated based on manifest data. For real observations, services need to be running and sending data.

## 🔍 Troubleshooting

### No Services Showing

1. Check that manifest.json files exist:
```bash
ls ~/Development/personal/*/manifest.json
```

2. Verify manifest format is valid JSON:
```bash
cat ~/Development/personal/ds-go/manifest.json | python3 -m json.tool
```

### Observers Not Showing

Observers appear when:
- Services have `contracts.enabled: true` in manifest
- Services are in `running` status
- Manifest includes valid metrics

### Dashboard Not Loading

1. Check server is running:
```bash
curl http://localhost:8089/health
```

2. Check for port conflicts:
```bash
lsof -i :8089
```

3. View server logs in terminal where `npm start` is running

## 📈 Understanding Compliance

### Overall Compliance

Calculated as: `(compliant services / total services) × 100`

### Service Status

- **Compliant** - Contracts enabled, no SLO breaches
- **Partial** - Contracts enabled, has SLO breaches
- **Non-Compliant** - Contracts disabled or errors

### SLO Breaches

Detected when metrics exceed thresholds:
- Response time > threshold = breach
- Error rate > threshold = breach
- Availability < threshold = breach

## 🛠️ Development

### Adding Mock Data

For testing without real services, edit manifests to include sample metrics:

```json
"status": {
  "phase": "running",
  "metrics": {
    "response_time_p95": 150,
    "error_rate": 0.01,
    "availability": 99.99
  }
}
```

### Custom Observers

Add to service manifest:

```json
"spec": {
  "contracts": {
    "observers": ["git", "mise", "custom-observer"]
  }
}
```

---

For more information, see the [System Integration Guide](../SYSTEM_INTEGRATION.md)