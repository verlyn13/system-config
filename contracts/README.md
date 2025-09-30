# Contract System - Complete Implementation

## 🎯 Overview

This directory contains the complete contract enforcement system that ensures consistency, quality, and compliance across all services in our polyglot environment. The system implements **multi-layer enforcement** from development through production.

## 📊 Current Status

- **Phase 1**: ✅ **COMPLETE** - Schemas, Validation, OPA Policy
- **Phase 2**: ✅ **COMPLETE** - Runtime Enforcement, CI/CD, Pre-commit Hooks
- **Phase 3**: ✅ **COMPLETE** - Monitoring Dashboard, Full Documentation

## 🚀 Quick Start

```bash
# Option 1: Run the automated setup wizard
./enforcement/setup-enforcement.sh

# Option 2: Manual setup for a specific repo
cd your-repo
ln -sf ../system-setup-update/contracts/enforcement/git-hooks/pre-commit .git/hooks/pre-commit

# Option 3: Validate current compliance
../docs/contracts-reference/validate-integration.sh ds-go
```

## 🔒 Five Layers of Contract Enforcement

### 1. **Development Time** (Immediate Feedback)
- JSON schemas for IDE validation
- Local validation scripts
- Template generators for compliant code

### 2. **Pre-Commit Hooks** (Local Gate)
```bash
# Automatic validation before every commit
# Location: enforcement/git-hooks/pre-commit
```
**Validates:**
- ❌ Internal observer names (`repo`, `deps`)
- ❌ Blocked observers (`quality`)
- ❌ Missing `apiVersion: "obs.v1"`
- ❌ Invalid project_id format
- ❌ OPA policies without `import rego.v1`

### 3. **CI/CD Pipeline** (Shared Gate)
```yaml
# GitHub Actions on every PR
# Location: enforcement/ci-cd/github-actions.yml
```
**Features:**
- Service type detection
- Observer name validation
- Schema compliance checks
- SLO threshold validation
- PR comment with compliance report

### 4. **Runtime Enforcement** (Production Protection)
```javascript
// Node.js Integration
const { express } = require('./contracts/enforcement/runtime/universal-middleware');
app.use(express({ mode: 'enforce', serviceName: 'ds-go' }));
```

```go
// Go Integration
enforcer := NewUniversalContractEnforcer(WithMode(ModeEnforce))
http.Handle("/", enforcer.Middleware(handler))
```

**Capabilities:**
- Automatic observer mapping
- Request/response validation
- SSE stream validation
- SLO breach detection
- Real-time metrics

### 5. **Monitoring Dashboard** (Visibility)
```bash
# Open the compliance dashboard
open dashboard/compliance-dashboard.html
```
**Shows:**
- Overall compliance percentage
- Service-specific status
- Recent violations
- SLO breach tracking
- Real-time updates

## 📁 Directory Structure

```
contracts/
├── schemas/                    # JSON Schema definitions
│   ├── obs.line.v1.json       # Observation schema (v1)
│   └── slobreach.v1.json      # SLO breach schema
│
├── integration/                # Integration modules
│   ├── validation.js          # Node.js validation module
│   └── opa_client.py          # Python OPA client
│
├── policy/                     # OPA policies
│   └── opa/
│       ├── working.rego       # Main OPA policy (v1.8)
│       └── test.rego          # Policy tests
│
├── enforcement/                # Enforcement mechanisms
│   ├── git-hooks/
│   │   └── pre-commit         # Git pre-commit hook
│   ├── ci-cd/
│   │   └── github-actions.yml # CI/CD workflow
│   ├── runtime/
│   │   ├── universal-middleware.js  # Node.js middleware
│   │   └── universal-middleware.go  # Go middleware
│   └── setup-enforcement.sh   # Automated setup wizard
│
├── dashboard/                  # Monitoring
│   └── compliance-dashboard.html # Real-time dashboard
│
├── ENFORCEMENT_PRINCIPLES.md   # Enforcement philosophy
├── STATUS.md                   # Implementation status
└── README.md                   # This file
```

## 🎯 Key Enforcement Rules

### Observer Name Mapping
| Internal | External | Status |
|----------|----------|---------|
| `repo` | `git` | Auto-mapped |
| `deps` | `mise` | Auto-mapped |
| `quality` | - | **BLOCKED** |

### Project ID Format
```
service:organization/repository
```
- ✅ `ds-go:verlyn13/ds-go`
- ❌ `DS-GO:verlyn13/ds-go` (uppercase)
- ❌ `ds-go/verlyn13/ds-go` (wrong separator)

### Required Fields
```json
{
  "apiVersion": "obs.v1",
  "run_id": "uuid-v4",
  "timestamp": "ISO-8601",
  "project_id": "service:org/repo",
  "observer": "external-name",
  "summary": "description",
  "metrics": {},
  "status": "completed"
}
```

## 📈 Service-Specific SLOs

| Service | Response Time (p95) | Error Rate | Availability |
|---------|-------------------|------------|--------------|
| **ds-go** | 200ms | 5% | 99.9% |
| **devops-mcp** | 300ms | 1% | 99.95% |
| **system-dashboard** | 750ms | 20% | 99.5% |
| **system-setup-update** | 500ms | 10% | 99.0% |

## 🔧 Integration Examples

### Express.js
```javascript
const contracts = require('./contracts/enforcement/runtime/universal-middleware');

app.use(contracts.express({
  mode: 'enforce',
  serviceName: 'my-service',
  blockOnViolation: true
}));
```

### Go HTTP
```go
import "contracts/enforcement/runtime"

func main() {
    enforcer := NewUniversalContractEnforcer(
        WithMode(ModeEnforce),
        WithServiceName("my-service"),
    )

    http.Handle("/", enforcer.Middleware(myHandler))
}
```

### Python Flask
```python
from contracts.integration.opa_client import OPAClient

client = OPAClient()

@app.before_request
def validate_contracts():
    # Validation logic
    pass
```

## 📊 Monitoring & Metrics

### Access Dashboard
```bash
# Open in browser
open dashboard/compliance-dashboard.html

# Or serve it
cd dashboard
python3 -m http.server 8080
# Visit http://localhost:8080/compliance-dashboard.html
```

### Metrics Collected
- Total requests processed
- Contract violations by type
- Observer mappings performed
- SLO breaches detected
- Compliance percentage per service

## 🚨 Emergency Procedures

### Skip Pre-commit (NOT RECOMMENDED)
```bash
git commit --no-verify -m "EMERGENCY: [reason]"
```

### Disable Runtime Enforcement (TEMPORARY)
```javascript
// Switch to monitor mode temporarily
app.use(contracts.express({ mode: 'monitor' }));
```

## 📚 Documentation

- **[ENFORCEMENT_PRINCIPLES.md](ENFORCEMENT_PRINCIPLES.md)** - Philosophy and strategy
- **[../docs/contracts-reference/](../docs/contracts-reference/)** - Integration guides
  - `quick-start.md` - 5-minute setup
  - `ds-go-integration.md` - Go service guide
  - `devops-mcp-integration.md` - MCP server guide
  - `system-dashboard-integration.md` - Dashboard guide
  - `migration-checklist.md` - Step-by-step migration

## ✅ Compliance Checklist

- [ ] Pre-commit hook installed
- [ ] CI/CD workflow added
- [ ] Runtime middleware integrated
- [ ] Observer names mapped correctly
- [ ] Project IDs formatted properly
- [ ] SLO thresholds configured
- [ ] Dashboard accessible
- [ ] Team trained on contracts

## 🎉 Success Metrics

When fully implemented, you should see:
- **0** internal observer names in production
- **100%** valid project_id format
- **<0.1%** runtime validation failures
- **<1%** SLO breach rate
- **100%** repos with enforcement

---

**Remember:** Contracts enforce quality automatically. Every violation prevented saves debugging time and improves reliability.