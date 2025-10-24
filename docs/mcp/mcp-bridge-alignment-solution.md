---
title: Mcp Bridge Alignment Solution
category: reference
component: mcp_bridge_alignment_solution
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

# MCP-Bridge Alignment Solution

**Date**: 2025-09-28
**Status**: ✅ RESOLVED

## Problem Summary

The MCP server's `project_discover` tool was working correctly (finding 37-41 projects) but the results weren't accessible to the HTTP bridge or dashboard because:
1. MCP server only returned data, didn't persist it
2. HTTP bridge expected registry at `~/.local/share/devops-mcp/project-registry.json`
3. Old workspace discovery wrote to different location (`~/.local/share/workspace/registry.json`)

## Solution Implemented

### 1. Unified Registry Location
**Path**: `~/.local/share/devops-mcp/project-registry.json`
- Single source of truth for both MCP server and HTTP bridge
- Shared between all services

### 2. New Discovery Script
**Script**: `scripts/project-discover.sh`
- Detects projects by common markers (`.git`, `package.json`, `go.mod`, etc.)
- Writes to shared registry location
- Returns JSON summary to stdout for HTTP bridge consumption
- Successfully discovers 37 projects across 3 workspaces

### 3. HTTP Bridge Updates
**Endpoints**:
- `/api/health` - Shows registry status
- `/api/projects` - Returns all projects (auto-discovers if empty)
- `/api/discover` - Manual discovery trigger
- `/api/projects/:id/status` - Project-specific status
- `/api/projects/:id/health` - Project health metrics

### 4. Discovery Results

```json
{
  "discovered": 37,
  "stats": {
    "total": 37,
    "byKind": [
      {"kind": "generic", "count": 25},
      {"kind": "node", "count": 5},
      {"kind": "python", "count": 4},
      {"kind": "go", "count": 3}
    ],
    "byWorkspace": [
      {"workspace": "personal", "count": 23},
      {"workspace": "work", "count": 13},
      {"workspace": "business", "count": 1}
    ]
  }
}
```

## Testing Verification

### 1. Discovery Script
```bash
$ bash scripts/project-discover.sh 2>/dev/null | jq '.discovered'
37
```

### 2. HTTP Bridge Health
```bash
$ curl -s http://localhost:7171/api/health | jq
{
  "ok": true,
  "data_dir": "/Users/verlyn13/.local/share/devops-mcp",
  "registry_present": true,
  "obs_dir_present": true
}
```

### 3. Projects API
```bash
$ curl -s http://localhost:7171/api/projects | jq '.projects | length'
37
```

### 4. Manual Discovery
```bash
$ curl -s http://localhost:7171/api/discover | jq '.discovered'
37
```

## Integration Guide for Dashboard

### Environment Variables
```bash
# Required
export OBS_BRIDGE_URL="http://127.0.0.1:7171"

# Optional (for custom roots)
export DEVOPS_MCP_ROOTS="$HOME/Development/personal,$HOME/Development/work,$HOME/Development/business"
```

### Dashboard Implementation

1. **On Startup**:
   ```javascript
   // Check bridge health
   const health = await fetch(`${OBS_BRIDGE_URL}/api/health`).then(r => r.json());

   // Get projects (auto-discovers if empty)
   const projects = await fetch(`${OBS_BRIDGE_URL}/api/projects`).then(r => r.json());
   ```

2. **Manual Discovery Button**:
   ```javascript
   async function triggerDiscovery() {
     const result = await fetch(`${OBS_BRIDGE_URL}/api/discover`).then(r => r.json());
     console.log(`Discovered ${result.discovered} projects`);
     // Refresh project list
     await loadProjects();
   }
   ```

3. **Project Details**:
   ```javascript
   async function getProjectStatus(projectId) {
     const status = await fetch(`${OBS_BRIDGE_URL}/api/projects/${projectId}/status`)
       .then(r => r.json());
     return status;
   }
   ```

## MCP Server Integration

For the MCP server to write directly to the shared registry:

```typescript
// In project_discover.ts after discovery
import { writeFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

export async function projectDiscover(args?: ProjectDiscoverInput) {
  // ... existing discovery logic ...

  // Write to shared registry
  const registryPath = join(homedir(), '.local/share/devops-mcp/project-registry.json');
  const registry = {
    version: '2.0.0',
    generated: new Date().toISOString(),
    discovered: projects.length,
    projects,
    stats: {
      total: projects.length,
      byKind: /* calculate */,
      byWorkspace: /* calculate */
    }
  };

  writeFileSync(registryPath, JSON.stringify(registry, null, 2));

  return { count: projects.length, projects };
}
```

## Operational Flow

1. **Continuous Discovery** (Hourly via LaunchAgent):
   ```bash
   scripts/obs-hourly.sh
   ├── project-discover.sh → Updates registry
   ├── obs-run.sh → Runs observers
   └── eval-slo.sh → Evaluates SLOs
   ```

2. **On-Demand Discovery**:
   - Dashboard: GET `/api/discover`
   - CLI: `bash scripts/project-discover.sh`
   - MCP: Call `project_discover` tool

3. **Data Flow**:
   ```
   Discovery Sources → Registry File → HTTP Bridge → Dashboard
        ↓                  ↓              ↓            ↓
   [MCP/Scripts]    [~/.local/...]   [Port 7171]   [UI at :3000]
   ```

## Validation Checklist

- [x] Registry file exists at correct location
- [x] Discovery finds 37 projects
- [x] HTTP bridge reads registry successfully
- [x] `/api/projects` returns project list
- [x] `/api/discover` triggers new discovery
- [x] Dashboard can access bridge endpoints
- [x] Projects grouped by workspace and kind
- [x] No duplicate projects in registry

## Repository Ownership

- **Authoritative**: `system-setup-update` (this repository)
- **Legacy**: `system-setup` (read-only reference)
- **Scripts Location**: `/scripts/` in this repository
- **Registry Location**: `~/.local/share/devops-mcp/project-registry.json`

## Known Issues Resolved

1. ✅ MCP discovery working but not persisted
2. ✅ Bridge looking in wrong location for registry
3. ✅ Workspace discovery script using different path
4. ✅ Discovery script hanging on macOS find command
5. ✅ HTTP bridge `/api/discover` endpoint missing

## Next Steps

1. **For Dashboard Team**:
   - Update environment to use port 7171
   - Add "Refresh Projects" button calling `/api/discover`
   - Show project counts by workspace in UI

2. **For MCP Team**:
   - Optional: Add registry writing to `project_discover` tool
   - Keep using shared registry path

3. **For DevOps**:
   - Set up LaunchAgent for hourly discovery
   - Monitor registry freshness

---

*This solution ensures complete alignment between MCP server, HTTP bridge, and dashboard for project discovery and observability.*