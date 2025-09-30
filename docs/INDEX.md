---
title: Documentation Index
category: index
component: system
status: active
version: 2.0.0
last_updated: 2025-09-28
tags: [documentation, index, navigation]
priority: critical
---

# System Documentation Index

## Quick Links

- [System Status](system/implementation-status.md) - Current system state
- [MCP Integration](mcp/integration-guide.md) - MCP server and bridge setup
- [Observability](guides/PROJECT-OBSERVABILITY-PLAN.md) - Observer implementation
- [Dashboard Guide](guides/dashboard-integration.md) - Dashboard UI integration
- [Contracts Index](../docs/contracts.md) - Schemas, OpenAPI, well-known
- [Environment Variables](../docs/env.md) - Bridge/server env vars
- [Client Generation](../docs/guides/client-generation.md) - Generate TS clients from OpenAPI
- [Integration Checklist](../docs/integration-checklist.md) - End-to-end steps

### Quick Commands
```bash
# Validate system integration
./scripts/validate-integration.sh

# Monitor system health (interactive)
./scripts/system-health.sh

# Trigger discovery
./scripts/run-discovery.sh
# or: curl http://localhost:7171/api/discover

# Migrate observations to consolidated format
node ./scripts/migrate-observations.js

# Run observer for a project
curl -X POST http://localhost:7171/api/tools/project_obs_run \
  -H "Content-Type: application/json" \
  -d '{"project_id": "PROJECT_ID", "observer": "git"}'
```

## Documentation Structure

### `/docs/system/` - System Status & Configuration
- [`implementation-status.md`](system/implementation-status.md) - Real-time system status
- [`master-status.md`](system/master-status.md) - Master tracking document
- [`system-validation-report.md`](system/system-validation-report.md) - Latest validation
- [`system-hardening-checklist.md`](system/system-hardening-checklist.md) - Hardening tasks

### `/docs/mcp/` - MCP Server & Bridge
- [`integration-guide.md`](mcp/integration-guide.md) - Complete integration guide
- [`mcp-bridge-alignment-solution.md`](mcp/mcp-bridge-alignment-solution.md) - Alignment fix
- [`mcp-project-discovery-analysis.md`](mcp/mcp-project-discovery-analysis.md) - Discovery analysis
- [`mcp-server-hardening-update.md`](mcp/mcp-server-hardening-update.md) - Latest hardening
- [`hardening-complete.md`](mcp/hardening-complete.md) - **✅ FINAL hardening implementation**
- [`dashboard-mcp-integration-directive.md`](mcp/dashboard-mcp-integration-directive.md) - Dashboard integration

### `/docs/reports/` - Status Reports
- [`daily-report.md`](reports/daily-report.md) - Daily status
- [`COMPLETION-REPORT-2025-09-26.md`](reports/COMPLETION-REPORT-2025-09-26.md) - Phase completion
- [`PROJECT-ORGANIZATION-REPORT.md`](reports/PROJECT-ORGANIZATION-REPORT.md) - Project structure
- [`hardening-completion-report-2025-09-28.md`](reports/hardening-completion-report-2025-09-28.md) - **✅ Hardening complete**
- [`critical-audit-2025-09-28.md`](reports/critical-audit-2025-09-28.md) - **⚠️ Critical issues found**
- [`latest-changes-verification-2025-09-28.md`](reports/latest-changes-verification-2025-09-28.md) - **✅ Latest changes verified**

### `/docs/guides/` - Implementation Guides
- [`MAINTENANCE-GUIDE.md`](guides/MAINTENANCE-GUIDE.md) - System maintenance
- [`SECRETS-MANAGEMENT-GUIDE.md`](guides/SECRETS-MANAGEMENT-GUIDE.md) - Secrets handling
- [`PROJECT-OBSERVABILITY-PLAN.md`](guides/PROJECT-OBSERVABILITY-PLAN.md) - Observer design
- [`IMPLEMENTATION-PLAN-2025-09-28.md`](guides/IMPLEMENTATION-PLAN-2025-09-28.md) - Implementation roadmap
- [`dashboard-integration.md`](guides/dashboard-integration.md) - **📊 Dashboard UI integration requirements**

### `/docs/` - Core Documentation
- `INDEX.md` - This file
- [`observability.md`](observability.md) - Observability overview
- [`dashboard_quickstart.md`](dashboard_quickstart.md) - Dashboard setup

## Root Level Documents (Minimal)

Only these documents should remain at repository root:
- `README.md` - Repository overview
- `CHANGELOG.md` - Version history
- `CLAUDE.md` - AI assistant context
- `INDEX.md` - Quick navigation

## Document Standards

### Required Metadata
Every document must have YAML frontmatter:
```yaml
---
title: Document Title
category: [system|mcp|guide|report|index]
component: [component-name]
status: [active|deprecated|draft]
version: X.Y.Z
last_updated: YYYY-MM-DD
tags: [tag1, tag2]
priority: [critical|high|medium|low]
---
```

### Categories
- `system` - System configuration and status
- `mcp` - MCP server related
- `guide` - How-to guides
- `report` - Status reports
- `index` - Navigation documents

### File Naming
- Use lowercase with hyphens: `system-status.md`
- Reports include dates: `daily-report-2025-09-28.md`
- Guides are descriptive: `secrets-management-guide.md`

## Navigation Paths

### For System Status
1. Start: [`docs/INDEX.md`](INDEX.md)
2. Current: [`docs/system/implementation-status.md`](system/implementation-status.md)
3. Validation: [`docs/system/system-validation-report.md`](system/system-validation-report.md)

### For MCP Setup
1. Start: [`docs/INDEX.md`](INDEX.md)
2. Integration: [`docs/mcp/integration-guide.md`](mcp/integration-guide.md)
3. Dashboard: [`docs/mcp/dashboard-mcp-integration-directive.md`](mcp/dashboard-mcp-integration-directive.md)

### For Maintenance
1. Start: [`docs/INDEX.md`](INDEX.md)
2. Guide: [`docs/guides/MAINTENANCE-GUIDE.md`](guides/MAINTENANCE-GUIDE.md)
3. Checklist: [`docs/system/system-hardening-checklist.md`](system/system-hardening-checklist.md)

## Search Index

### By Component
- **MCP Server**: [mcp/](mcp/)
- **HTTP Bridge**: [mcp/integration-guide.md](mcp/integration-guide.md)
- **Dashboard**: [dashboard_quickstart.md](dashboard_quickstart.md)
- **Observers**: [guides/PROJECT-OBSERVABILITY-PLAN.md](guides/PROJECT-OBSERVABILITY-PLAN.md)

### By Task
- **Setup**: [README.md](../README.md)
- **Integration**: [mcp/integration-guide.md](mcp/integration-guide.md)
- **Maintenance**: [guides/MAINTENANCE-GUIDE.md](guides/MAINTENANCE-GUIDE.md)
- **Validation**: [system/system-validation-report.md](system/system-validation-report.md)

### By Priority
- **Critical**: System status, Integration guide
- **High**: Hardening, Maintenance
- **Medium**: Reports, Guides
- **Low**: Historical reports

---

*This index provides structured navigation through all system documentation.*
