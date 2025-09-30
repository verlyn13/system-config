# CRITICAL: Dashboard Fragmentation Issue

## 🚨 CURRENT PROBLEM

We have **TWO separate dashboards** that are not aligned:

### 1. System Dashboard (ACTIVE - Port 5173)
- **Location**: `~/Development/personal/system-dashboard/`
- **Technology**: React + Vite + Express
- **Ports**:
  - Client: 5173 (Vite dev server)
  - Server: 3001 (Express API)
- **URL**: http://localhost:5173
- **Status**: ACTIVELY USED
- **Issue**: Shows raw JSON for observations in ProjectDetail.jsx

### 2. Contracts Dashboard (INACTIVE - Port 8089)
- **Location**: `~/Development/personal/system-setup-update/contracts/dashboard/`
- **Technology**: Plain HTML + Express
- **Port**: 8089
- **URL**: http://localhost:8089
- **Status**: NOT BEING USED
- **Issue**: Was being fixed but user isn't seeing changes

## 🔥 ROOT CAUSE

The dashboards are completely separate codebases with no shared configuration or policy enforcement. Changes to one don't affect the other.

## ✅ IMMEDIATE FIXES NEEDED

### Fix 1: Update the ACTIVE dashboard (system-dashboard)

The JSON display issue is in:
- File: `system-dashboard/src/components/ProjectDetail.jsx`
- Lines: 392 and 400 showing `JSON.stringify()`

### Fix 2: Create unified configuration

Both dashboards must read from:
- `SYSTEM_REGISTRY.json` - Single source of truth
- Shared manifest schemas
- Common OPA policies

### Fix 3: Policy enforcement

Create policies that:
1. Detect multiple dashboards
2. Enforce single dashboard usage
3. Validate all dashboards use same configuration

## 🎯 LONG-TERM SOLUTION

### Option 1: Merge dashboards
- Keep system-dashboard (React) as primary
- Move contracts dashboard features into it
- Delete contracts/dashboard

### Option 2: Proxy architecture
- Keep both but proxy through single port
- Contracts dashboard becomes API-only
- System dashboard consumes contracts API

### Option 3: Deprecate one
- Choose ONE dashboard
- Migrate all features to chosen one
- Archive the other with clear deprecation notice

## 📋 ACTION ITEMS

1. **Immediate**: Fix ProjectDetail.jsx in system-dashboard
2. **Short-term**: Create shared configuration both dashboards read
3. **Medium-term**: Implement OPA policies to prevent fragmentation
4. **Long-term**: Consolidate to single dashboard

## ⚠️ POLICY REQUIREMENTS

We need policies that:
- Detect when multiple services claim same purpose
- Enforce port allocation (no conflicts)
- Validate all dashboards against same schema
- Alert on configuration drift

## 🔐 ENFORCEMENT

```bash
# Check for dashboard fragmentation
find ~/Development/personal -name "dashboard*" -type d

# Validate only one dashboard is running
lsof -i :5173 -i :8089 -i :3001

# Ensure configuration alignment
opa eval -d policies/no-fragmentation.rego
```

---

**CRITICAL**: This fragmentation violates our core principle of single source of truth. We must fix this immediately.