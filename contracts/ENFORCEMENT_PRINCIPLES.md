# Contract Enforcement Principles

## Core Philosophy

The contract system enforces consistency and quality across our polyglot environment through **prevention over correction**. We catch violations at the earliest possible stage - during development, before commit, in CI/CD, and at runtime.

## Enforcement Layers

### 1. Development Time (Earliest Detection)

**Principle**: Provide immediate feedback during coding to prevent violations from being created.

**Implementation**:
- IDE/Editor plugins that highlight contract violations
- Local validation scripts developers can run
- Template generators that create compliant code by default

**Benefits**:
- Fastest feedback loop
- No wasted time on invalid implementations
- Educational - developers learn contracts through tooling

### 2. Pre-Commit (Local Gate)

**Principle**: Prevent non-compliant code from entering version control.

**Implementation**:
```bash
# Install pre-commit hook
ln -sf ../../system-setup-update/contracts/enforcement/git-hooks/pre-commit .git/hooks/pre-commit
```

**What It Enforces**:
- ❌ Internal observer names (`repo`, `deps`) in external APIs
- ❌ Blocked observer (`quality`) exposed externally
- ❌ Missing `apiVersion: "obs.v1"` in observations
- ❌ Malformed project_id (must be `service:org/repo`)
- ❌ Invalid JSON schemas
- ❌ OPA policies without `import rego.v1`

**Override** (Emergency Only):
```bash
git commit --no-verify  # NOT RECOMMENDED
```

### 3. CI/CD Pipeline (Shared Gate)

**Principle**: Ensure all merged code meets contract requirements before deployment.

**Implementation**: GitHub Actions workflow that runs on every push and PR

**Enforcement Stages**:
1. **Detection**: Identify service type and applicable contracts
2. **Validation**: Check observer names, schemas, project IDs
3. **Testing**: Run service-specific contract tests
4. **SLO Check**: Validate SLO thresholds match requirements
5. **Reporting**: Generate compliance report, comment on PRs

**Failure Handling**:
- Blocks merge if contracts are violated
- Provides detailed error messages
- Suggests fixes in PR comments

### 4. Runtime (Production Protection)

**Principle**: Enforce contracts in production to prevent drift and catch edge cases.

**Implementation**: Universal middleware for all services

**Node.js Integration**:
```javascript
const { express } = require('./contracts/enforcement/runtime/universal-middleware');

app.use(express({
  mode: 'enforce',        // or 'monitor' for logging only
  serviceName: 'ds-go',
  blockOnViolation: true,
  webhookUrl: process.env.CONTRACT_WEBHOOK_URL
}));
```

**Go Integration**:
```go
import "contracts/enforcement/runtime"

enforcer := NewUniversalContractEnforcer(
    WithMode(ModeEnforce),
    WithServiceName("ds-go"),
)

http.Handle("/", enforcer.Middleware(handler))
```

**Runtime Actions**:
- Maps internal observers to external names automatically
- Blocks invalid observations (configurable)
- Reports violations to monitoring
- Tracks SLO breaches in real-time

## Enforcement Modes

### 1. Enforce Mode (Default)
- **Blocks** non-compliant requests/responses
- **Maps** observers automatically
- **Logs** all violations
- **Alerts** on SLO breaches
- **Use When**: Production, staging

### 2. Monitor Mode
- **Allows** non-compliant data through
- **Logs** violations for analysis
- **Tracks** metrics
- **Use When**: Migration period, debugging

### 3. Disabled Mode
- **No enforcement** or validation
- **Use When**: Emergency bypass (requires justification)

## Observer Name Enforcement

### The Problem
Internal service names leak implementation details and create coupling.

### The Solution
Strict mapping at all boundaries:

| Internal Name | External Name | Status |
|--------------|---------------|---------|
| `repo` | `git` | Mapped automatically |
| `deps` | `mise` | Mapped automatically |
| `quality` | - | **BLOCKED** - Never exposed |

### Enforcement Points
1. **Code**: Pre-commit hooks detect internal names
2. **CI/CD**: Build fails if internal names found
3. **Runtime**: Automatic mapping or blocking

## Project ID Enforcement

### Format Requirements
```
service:organization/repository
```

### Rules
- **Lowercase only**: `ds-go:verlyn13/ds-go` ✅
- **Hyphenated service names**: `system-setup-update:org/repo` ✅
- **Colon separator**: Service and path separated by `:` only
- **Forward slash**: Organization and repo separated by `/` only

### Invalid Examples
```
DS-GO:org/repo          # ❌ Uppercase service
ds-go/org/repo          # ❌ Wrong separator
ds_go:org/repo          # ❌ Underscore in service
ds-go:OrgName/repo      # ❌ Uppercase in org
```

## SLO Enforcement

### Service-Specific Thresholds

**ds-go** (Strict Performance):
- response_time_p95: 200ms
- error_rate: 5%
- availability: 99.9%

**devops-mcp** (High Availability):
- response_time_p95: 300ms
- error_rate: 1%
- availability: 99.95%

**system-dashboard** (UI Tolerance):
- response_time_p95: 750ms
- error_rate: 20%
- availability: 99.5%

### Breach Detection
1. **Runtime**: Middleware tracks every response
2. **Aggregation**: Metrics calculated over time windows
3. **Alerting**: Breaches trigger immediate alerts
4. **Recording**: All breaches logged as `slobreach.v1` events

## Schema Enforcement

### Required Fields
Every observation MUST have:
```json
{
  "apiVersion": "obs.v1",           // Exact string
  "run_id": "uuid-here",            // Valid UUID v4
  "timestamp": "2025-09-28T10:00:00Z", // ISO 8601
  "project_id": "service:org/repo",    // Valid format
  "observer": "git",                    // External name only
  "summary": "Human readable",          // Non-empty string
  "metrics": { "duration_ms": 100 },    // At least one metric
  "status": "completed"                 // Valid status
}
```

### Additional Properties
```json
"additionalProperties": false
```
This prevents schema drift by rejecting unknown fields.

## Compliance Monitoring

### Metrics Tracked
- Total requests processed
- Violations by type (request/response/SSE)
- Observer mappings performed
- SLO breaches detected
- Blocking rate

### Reporting
Every service reports metrics every 60 seconds:
```json
{
  "service": "ds-go",
  "timestamp": "2025-09-28T10:00:00Z",
  "mode": "enforce",
  "metrics": {
    "totalRequests": 10000,
    "violations": 5,
    "blocked": 3,
    "observerMappings": 25,
    "sloBreaches": 1,
    "violationRate": "0.0005"
  }
}
```

## Progressive Enforcement Strategy

### Phase 1: Education (Week 1-2)
- Install monitoring mode middleware
- Log violations without blocking
- Share violation reports with teams

### Phase 2: Local Enforcement (Week 3-4)
- Enable pre-commit hooks
- Developers fix violations before commit
- Monitor mode still in production

### Phase 3: CI/CD Gates (Week 5-6)
- Enable GitHub Actions workflow
- PRs blocked if non-compliant
- Production still in monitor mode

### Phase 4: Production Enforcement (Week 7+)
- Switch to enforce mode in production
- Block non-compliant requests
- Full contract compliance achieved

## Emergency Procedures

### Bypassing Enforcement

**Local Development**:
```bash
# Skip pre-commit hook (requires justification)
git commit --no-verify -m "EMERGENCY: [reason]"
```

**CI/CD**:
```yaml
# Add to commit message to skip CI contracts
[skip contracts] EMERGENCY: [reason]
```

**Runtime**:
```javascript
// Temporarily disable enforcement
app.use(contractMiddleware({
  mode: 'disabled',  // Must be reverted within 24 hours
}));
```

### Rollback Procedures
1. Switch to monitor mode immediately
2. Collect violation logs for analysis
3. Fix root cause
4. Re-enable enforcement with fixes

## Best Practices

### For Developers
1. **Run validation locally** before committing
2. **Use templates** that generate compliant code
3. **Test with enforcement** enabled in development
4. **Map observers early** in the data pipeline

### For Service Owners
1. **Start with monitor mode** to understand violations
2. **Fix violations incrementally** using violation reports
3. **Enable enforcement gradually** (dev → staging → prod)
4. **Track metrics** to ensure compliance

### For Platform Team
1. **Provide clear documentation** with examples
2. **Offer migration tools** for legacy code
3. **Monitor adoption** across services
4. **Celebrate compliance** achievements

## Success Metrics

### Technical Metrics
- **Zero** internal observer names in production
- **100%** valid project_id format
- **<0.1%** runtime validation failures
- **<1%** SLO breach rate

### Process Metrics
- **100%** repos with pre-commit hooks
- **100%** services with CI/CD validation
- **100%** production services with runtime enforcement
- **<24hr** mean time to compliance for new services

## Appendix: Quick Reference

### Install Pre-Commit Hook
```bash
cd your-repo
ln -sf ../system-setup-update/contracts/enforcement/git-hooks/pre-commit .git/hooks/pre-commit
```

### Add CI/CD Workflow
```yaml
# .github/workflows/contracts.yml
name: Contract Enforcement
uses: ./system-setup-update/contracts/enforcement/ci-cd/github-actions.yml
```

### Add Runtime Enforcement
```javascript
// Node.js
const contracts = require('contracts/enforcement/runtime/universal-middleware');
app.use(contracts.express({ mode: 'enforce' }));
```

```go
// Go
enforcer := contracts.NewUniversalContractEnforcer(contracts.WithMode(contracts.ModeEnforce))
http.Handle("/", enforcer.Middleware(handler))
```

---

Remember: **Contracts are not bureaucracy - they're automation of quality.** Every violation prevented saves debugging time and improves system reliability.