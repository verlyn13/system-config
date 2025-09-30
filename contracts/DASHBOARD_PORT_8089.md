# DASHBOARD PORT: 8089

## THIS IS THE ONLY DASHBOARD PORT

### ✅ Configuration Complete

The system dashboard has been configured with:

1. **Single Port**: 8089 (no other ports)
2. **Single URL**: http://localhost:8089
3. **Single HTML**: index.html (no fallbacks)
4. **Single Config**: config.json

### 📍 Key Files

| File | Purpose |
|------|---------|
| `dashboard/config.json` | Dashboard configuration (port 8089) |
| `dashboard/index.html` | Dashboard UI (formats observations properly) |
| `dashboard/dashboard-server.js` | Server (reads config.json) |
| `SYSTEM_REGISTRY.json` | System-wide configuration registry |
| `ARCHITECTURE.md` | Complete system architecture |

### ✅ Validation

Run these commands to verify:

```bash
# System validation
cd contracts
./validate-system.sh

# Dashboard test
cd dashboard
./test-dashboard.sh
```

### 🚀 Start Dashboard

```bash
cd contracts/dashboard
./start-dashboard.sh
```

Then open: **http://localhost:8089**

### ⚠️ Important

- **NO** other dashboard ports are allowed
- **NO** test servers on different ports
- **NO** raw JSON in observer output
- **NO** fallback HTML files

### 🔐 Policy Enforcement

The dashboard configuration is validated by OPA:
- Policy: `policies/dashboard-config.rego`
- Enforces: Port 8089 only

---

**Remember: 8089 is the ONLY dashboard port.**