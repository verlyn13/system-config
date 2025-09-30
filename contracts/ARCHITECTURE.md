# System Architecture & Configuration

## 🎯 Single Source of Truth

**CRITICAL: The dashboard ALWAYS runs on port 8089**

This document defines the authoritative system architecture. All components MUST refer to this documentation and the associated configuration files.

## 📍 Core Services & Ports

| Service | Port | URL | Config File |
|---------|------|-----|-------------|
| **Dashboard** | **8089** | **http://localhost:8089** | `dashboard/config.json` |
| OPA | 8181 | http://localhost:8181 | `opa-config.yaml` |
| MCP System Monitor | stdio | N/A | `mcp-servers/system-monitor/package.json` |

## 🗂️ System Registry

The complete system configuration is stored in: **`SYSTEM_REGISTRY.json`**

This file contains:
- All service configurations
- Repository mappings
- API endpoints
- Contract schemas and policies

## 🚦 Dashboard Access

### There is ONLY ONE dashboard URL:
```
http://localhost:8089
```

### Start the dashboard:
```bash
cd contracts/dashboard
./start-dashboard.sh
```

### Configuration location:
```
contracts/dashboard/config.json
```

## 🔍 Validation

Run system validation to ensure configuration integrity:
```bash
cd contracts
./validate-system.sh
```

This checks:
1. OPA installation
2. Dashboard configuration validity
3. System registry consistency
4. Service manifest validity
5. Dashboard server configuration
6. OPA policy compilation

## 📊 Dashboard Features

### Available Tabs:
1. **Overview** - System-wide compliance metrics
2. **Services** - Individual service status and metrics
3. **Observers** - Active observers and formatted observations (NO RAW JSON)
4. **Projects** - Project analysis and contract status

### Key Endpoints:
- UI: `http://localhost:8089`
- API: `http://localhost:8089/api`
- Health: `http://localhost:8089/health`
- SSE Stream: `http://localhost:8089/api/stream`

## 🔐 Policy Enforcement

### Dashboard Configuration Policy
Location: `policies/dashboard-config.rego`

This policy ensures:
- Dashboard uses port 8089
- URLs are correctly configured
- All endpoints use the correct base URL

### Validation Command:
```bash
opa eval -d policies/dashboard-config.rego \
         -i dashboard/config.json \
         "data.dashboard.config.allow"
```

## 📦 Service Manifests

Each service requires a `manifest.json` file at the repository root:

```json
{
  "apiVersion": "manifest.v1",
  "spec": {
    "contracts": {
      "enabled": true,
      "mode": "enforce",
      "slo": {
        "response_time_p95": 200,
        "error_rate": 0.05,
        "availability": 99.9
      }
    }
  }
}
```

Current services with manifests:
- `~/Development/personal/ds-go/manifest.json`
- `~/Development/personal/system-setup-update/manifest.json`

## 🎭 Observer System

Observers monitor different aspects of services:

| Observer | Purpose | Displays |
|----------|---------|----------|
| git | Repository analysis | Formatted commit info |
| mise | Dependency management | Tool versions |
| manifest | Service configuration | Compliance status |
| build | Build system events | Build success/failure |

**IMPORTANT:** Observers display formatted data, NEVER raw JSON in the dashboard.

## 🏗️ Directory Structure

```
contracts/
├── SYSTEM_REGISTRY.json      # Single source of truth
├── ARCHITECTURE.md            # This file
├── validate-system.sh         # System validation script
├── dashboard/
│   ├── config.json           # Dashboard configuration (port 8089)
│   ├── manifest.json         # Dashboard's own manifest
│   ├── dashboard-server.js   # Main server (reads config.json)
│   ├── index.html           # Dashboard UI
│   ├── start-dashboard.sh   # Startup script
│   └── README.md            # Dashboard documentation
├── policies/
│   ├── dashboard-config.rego # Dashboard validation policy
│   └── contracts.v1.rego    # Contract enforcement policies
├── schemas/
│   ├── obs.line.v1.json     # Observation schema
│   ├── manifest.v1.json     # Manifest schema
│   └── slo_breach.v1.json   # SLO breach schema
└── enforcement/
    └── setup-enforcement.sh  # Contract setup script
```

## ⚠️ Important Rules

1. **NEVER** create additional dashboard servers on different ports
2. **ALWAYS** use port 8089 for the dashboard
3. **ALWAYS** validate configurations with `validate-system.sh`
4. **NEVER** display raw JSON in the dashboard UI
5. **ALWAYS** format observations for human readability

## 🚀 Getting Started

1. Validate the system:
   ```bash
   cd contracts
   ./validate-system.sh
   ```

2. Start the dashboard:
   ```bash
   cd dashboard
   ./start-dashboard.sh
   ```

3. Open in browser:
   ```
   http://localhost:8089
   ```

## 📝 Notes

- The dashboard automatically reads all service manifests from `~/Development/personal/*/manifest.json`
- Real-time updates via Server-Sent Events (SSE)
- Auto-refresh every 30 seconds
- All configurations are validated by OPA policies

---

**Remember:** Port 8089 is the ONLY dashboard port. This is enforced by configuration, documentation, and policy.