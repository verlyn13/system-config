---
title: Root Navigation Index
category: index
component: system
status: active
version: 2.1.0
last_updated: 2025-09-28
tags: [navigation, index, root]
priority: critical
---

# Root Navigation Index

## 📚 Documentation Has Moved

All documentation is now properly organized under `/docs/` with metadata and categorization.

➡️ **[Go to Documentation Index](docs/INDEX.md)** - Complete navigation guide

## Quick Links

### System Status
- 📊 **[Current Status](docs/system/implementation-status.md)** - Real-time system state
- ✅ **[Validation Report](docs/system/system-validation-report.md)** - Latest validation
- 🔒 **[Hardening Checklist](docs/system/system-hardening-checklist.md)** - Security tasks

### Integration & Setup
- 🔧 **[MCP Integration](docs/mcp/integration-guide.md)** - Server and bridge setup
- 📱 **[Dashboard Setup](docs/mcp/dashboard-mcp-integration-directive.md)** - UI integration
- 👁️ **[Observability](docs/guides/PROJECT-OBSERVABILITY-PLAN.md)** - Observer design

### Maintenance
- 📋 **[Maintenance Guide](docs/guides/MAINTENANCE-GUIDE.md)** - System maintenance
- 🔐 **[Secrets Management](docs/guides/SECRETS-MANAGEMENT-GUIDE.md)** - Security guide

## Repository Root Files

Only these essential files remain at root level:

| File | Purpose | Status |
|------|---------|--------|
| `README.md` | Repository overview and quick start | Active |
| `CHANGELOG.md` | Version history and release notes | Active |
| `CLAUDE.md` | AI assistant context and guidelines | Active |
| `INDEX.md` | This navigation pointer | Active |
| `REPO-STRUCTURE.md` | Repository organization guide | Active |

## Documentation Organization

```
docs/
├── INDEX.md              # Complete documentation navigation
├── system/               # System status and configuration
│   ├── implementation-status.md
│   ├── system-validation-report.md
│   └── system-hardening-checklist.md
├── mcp/                  # MCP server and bridge
│   ├── integration-guide.md
│   └── dashboard-integration.md
├── guides/               # Implementation guides
│   ├── MAINTENANCE-GUIDE.md
│   └── PROJECT-OBSERVABILITY-PLAN.md
└── reports/              # Status reports
    └── daily-report.md
```

## Navigation Paths

1. **New User**: README.md → 01-setup/00-prerequisites.md
2. **System Check**: docs/INDEX.md → docs/system/implementation-status.md
3. **Integration**: docs/INDEX.md → docs/mcp/integration-guide.md
4. **Maintenance**: docs/INDEX.md → docs/guides/MAINTENANCE-GUIDE.md

---

*All documentation follows our metadata standards and organizational policies. For complete navigation, see [/docs/INDEX.md](docs/INDEX.md)*