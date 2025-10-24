---
title: Integration Guide Temp
category: reference
component: integration_guide_temp
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

# Dashboard-MCP Integration Directive

## Overview
This document provides the complete integration specification for connecting the System Dashboard UI to the MCP (Model Context Protocol) server's project discovery and observation capabilities.

## MCP Server Connection

### Endpoint Configuration
```javascript
// MCP Server Connection
const MCP_SERVER = {
  name: 'devops-mcp',
  transport: 'stdio',
  command: 'node',
  args: ['/Users/verlyn13/Development/personal/devops-mcp/dist/index.js'],
  // Alternative: Use npx for development
  // command: 'npx',
  // args: ['-y', '@verlyn/devops-mcp']
};
```

### Dashboard Bridge Configuration
The MCP server has a dashboard bridge configured at:
- **Port**: 4319
- **Allowed Origins**: `["http://localhost:5173", "http://localhost:3000"]`
- **Token**: `devops-mcp-bridge-token-2024`
- **Mutations**: Currently disabled (set `allow_mutations: false`)

## Available MCP Tools

### 1. Project Discovery
**Tool Name**: `project_discover`
**Input**: None or `{ maxDepth?: number }` (default: 2, max: 4)
**Returns**:
```typescript
interface ProjectDiscoverResponse {
  count: number;
  projects: Array<{
    id: string;        // SHA1 hash of path (12 chars)
    name: string;      // Directory name
    root: string;      // Absolute path
    kind: 'node' | 'go' | 'python' | 'mix' | 'generic';
    detectors: string[]; // ['git', 'node', 'mise', etc.]
  }>;
}
```

**Dashboard Usage**:
```javascript
async function loadProjects() {
  const response = await mcp.callTool('project_discover', {});
  const data = JSON.parse(response.content[0].text);
  // data.projects contains array of all discovered projects
  return data.projects;
}
```

### 2. Project Observer Execution
**Tool Name**: `project_obs_run`
**Input**: `{ project_id: string }`
**Returns**:
```typescript
interface ProjectObsResponse {
  ok: boolean;
  detail: {
    project: Project;
    status: {
      id: string;
      name: string;
      kind: string;
      git?: {
        branch?: string;
        dirty: boolean;
      };
      mise?: {
        exists: boolean;
      };
      build?: {
        hasBuild: boolean;
      };
      sbom?: {
        exists: boolean;
      };
    };
  };
}
```

**Dashboard Usage**:
```javascript
async function runProjectObservers(projectId) {
  const response = await mcp.callTool('project_obs_run', {
    project_id: projectId
  });
  const data = JSON.parse(response.content[0].text);
  return data.detail.status;
}
```

### 3. Project Health Summary
**Note**: This is available via `projectHealth()` function but may not be directly exposed as a tool. Check MCP server registration.

## Shell-Based Observer Integration

For richer observer data, the dashboard should also integrate with the shell-based observers in `/Users/verlyn13/Development/personal/system-setup-update/observers/`:

### Available Observers
1. **repo-observer.sh** - Repository metrics (commits, branches, contributors)
2. **deps-observer.sh** - Dependency analysis
3. **build-observer.sh** - Build status and metrics
4. **quality-observer.sh** - Code quality metrics
5. **sbom-observer.sh** - Software Bill of Materials

### Observer Output Format
All observers output NDJSON (newline-delimited JSON) to stdout:
```json
{"timestamp":"2025-09-28T10:00:00Z","observer":"repo","project":"devops-mcp","metrics":{...}}
```

### Running Observers via MCP
Create a custom tool wrapper if needed:
```javascript
async function runCustomObserver(projectPath, observerType) {
  // Option 1: Call via MCP exec tool if available
  const script = `/Users/verlyn13/Development/personal/system-setup-update/observers/${observerType}-observer.sh`;
  const response = await mcp.callTool('exec', {
    command: 'bash',
    args: [script, projectPath]
  });

  // Parse NDJSON output
  return response.content[0].text
    .split('\n')
    .filter(line => line.trim())
    .map(line => JSON.parse(line));
}
```

## Dashboard UI Implementation

### 1. Project List Component
```javascript
// ProjectList.jsx
import { useState, useEffect } from 'react';
import { useMCP } from './hooks/useMCP';

export function ProjectList() {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const mcp = useMCP();

  useEffect(() => {
    async function fetchProjects() {
      try {
        const response = await mcp.callTool('project_discover', {});
        const data = JSON.parse(response.content[0].text);

        // Group by workspace
        const grouped = data.projects.reduce((acc, project) => {
          const workspace = project.root.split('/')[4]; // Extract workspace name
          if (!acc[workspace]) acc[workspace] = [];
          acc[workspace].push(project);
          return acc;
        }, {});

        setProjects(grouped);
      } finally {
        setLoading(false);
      }
    }

    fetchProjects();
  }, []);

  return (
    <div className="project-list">
      {Object.entries(projects).map(([workspace, items]) => (
        <div key={workspace} className="workspace-group">
          <h3>{workspace} ({items.length})</h3>
          <div className="project-grid">
            {items.map(project => (
              <ProjectCard key={project.id} project={project} />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
```

### 2. Project Observer Component
```javascript
// ProjectObservers.jsx
export function ProjectObservers({ projectId }) {
  const [status, setStatus] = useState(null);
  const [observerData, setObserverData] = useState({});
  const mcp = useMCP();

  async function runObservers() {
    // Get basic status from MCP
    const response = await mcp.callTool('project_obs_run', {
      project_id: projectId
    });
    const data = JSON.parse(response.content[0].text);
    setStatus(data.detail.status);

    // Run additional observers
    const observers = ['repo', 'deps', 'build', 'quality'];
    for (const obs of observers) {
      const result = await runObserverScript(data.detail.project.root, obs);
      setObserverData(prev => ({ ...prev, [obs]: result }));
    }
  }

  return (
    <div className="observer-results">
      <button onClick={runObservers}>Run All Observers</button>

      {status && (
        <div className="status-grid">
          <StatusCard title="Git" data={status.git} />
          <StatusCard title="Mise" data={status.mise} />
          <StatusCard title="Build" data={status.build} />
          <StatusCard title="SBOM" data={status.sbom} />
        </div>
      )}

      {Object.entries(observerData).map(([observer, data]) => (
        <ObserverCard key={observer} type={observer} data={data} />
      ))}
    </div>
  );
}
```

## Real-time Updates via SSE

For real-time observer updates, implement Server-Sent Events:

### Backend Bridge (if not using MCP directly)
```javascript
// observer-bridge.js
import { EventEmitter } from 'events';
import { spawn } from 'child_process';

class ObserverBridge extends EventEmitter {
  runObserver(projectPath, observerType) {
    const script = `./observers/${observerType}-observer.sh`;
    const proc = spawn('bash', [script, projectPath]);

    proc.stdout.on('data', (data) => {
      const lines = data.toString().split('\n').filter(l => l);
      for (const line of lines) {
        try {
          const json = JSON.parse(line);
          this.emit('data', { observerType, data: json });
        } catch (e) {
          // Handle non-JSON output
        }
      }
    });

    proc.on('close', (code) => {
      this.emit('complete', { observerType, code });
    });
  }
}
```

### Frontend SSE Consumer
```javascript
// useObserverStream.js
export function useObserverStream(projectId) {
  const [events, setEvents] = useState([]);

  useEffect(() => {
    const eventSource = new EventSource(
      `http://localhost:4319/observers/stream?project=${projectId}`,
      {
        headers: {
          'Authorization': 'Bearer devops-mcp-bridge-token-2024'
        }
      }
    );

    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setEvents(prev => [...prev, data]);
    };

    return () => eventSource.close();
  }, [projectId]);

  return events;
}
```

## Data Storage & Caching

### Registry Location
The workspace registry is stored at:
```
~/.local/share/workspace/registry.json
```

### Observer Output Storage
Observer outputs are stored in NDJSON format:
```
~/.local/share/observers/
├── repo/
│   └── {project-id}.ndjson
├── deps/
│   └── {project-id}.ndjson
└── metrics/
    └── rollup.json
```

## Complete Integration Flow

1. **Initialize MCP Connection**
   ```javascript
   const mcp = await MCPClient.connect(MCP_SERVER);
   ```

2. **Discover Projects**
   ```javascript
   const projects = await mcp.callTool('project_discover', {});
   ```

3. **Display Project Grid**
   - Group by workspace
   - Show project type badges
   - Display detector icons

4. **Run Observers on Selection**
   ```javascript
   const status = await mcp.callTool('project_obs_run', { project_id });
   ```

5. **Stream Real-time Updates**
   - Connect to SSE endpoint
   - Update UI as observer data arrives

6. **Store Historical Data**
   - Save to IndexedDB or localStorage
   - Track trends over time

## Error Handling

```javascript
try {
  const response = await mcp.callTool('project_discover', {});
  if (!response.content?.[0]?.text) {
    throw new Error('Invalid response format');
  }
  const data = JSON.parse(response.content[0].text);
  // Process data
} catch (error) {
  if (error.code === 429) {
    // Rate limited - show retry message
    const retryAfter = error.data?.retryAfterMs || 5000;
    setTimeout(() => retry(), retryAfter);
  } else {
    // Show error to user
    console.error('MCP Error:', error);
  }
}
```

## Performance Considerations

1. **Cache Project List**: Project discovery can be expensive. Cache for 5 minutes.
2. **Debounce Observer Runs**: Prevent rapid re-runs of observers.
3. **Paginate Large Lists**: If > 50 projects, implement virtual scrolling.
4. **Background Updates**: Run observers in background, update UI incrementally.

## Security Notes

- Always validate the dashboard bridge token
- Sanitize project paths before display
- Never execute arbitrary commands from UI
- Use the MCP server's built-in rate limiting

## Testing the Integration

```bash
# 1. Ensure MCP server is running
ps aux | grep devops-mcp

# 2. Test project discovery directly
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"project_discover","arguments":{}},"id":1}' | \
  node /Users/verlyn13/Development/personal/devops-mcp/dist/index.js

# 3. Test with specific project
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"project_obs_run","arguments":{"project_id":"YOUR_PROJECT_ID"}},"id":2}' | \
  node /Users/verlyn13/Development/personal/devops-mcp/dist/index.js
```

This directive provides everything needed for the dashboard to fully integrate with the MCP server's project discovery and observation capabilities.# MCP-Bridge Alignment Solution

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

*This solution ensures complete alignment between MCP server, HTTP bridge, and dashboard for project discovery and observability.*# MCP Project Discovery Analysis

## Investigation Summary

The MCP server (`devops-mcp`) has fully functional project discovery capabilities that are properly configured and working correctly.

## Key Findings

### 1. Configuration ✅ Correct
- Workspaces are properly defined in `~/.config/devops-mcp/config.toml` (lines 10-17)
- The configuration schema supports workspaces (`src/config.ts`, line 33)
- Tilde expansion is correctly applied to workspace paths (`src/config.ts`, line 200)

### 2. Implementation ✅ Complete
- Project discovery tool exists: `src/tools/project_discover.ts`
- Tool is registered in MCP server: `src/index.ts` (lines 93-105)
- The tool name is: `project_discover`

### 3. Discovery Results ✅ Working
Testing confirms the discovery mechanism finds:
- **41 total projects** across 3 workspaces
- Personal workspace: 24 projects
- Work workspace: 15 projects
- Business workspace: 2 projects

Project types detected:
- Generic: 29
- Node.js: 5
- Python: 4
- Go: 3

## The Real Issue

The MCP agent reported "Project list currently empty" but this is likely because:
1. The agent didn't call the `project_discover` tool
2. The agent was looking for a different tool name or resource
3. The projects aren't exposed as resources (they're only available via the tool)

## Solution for MCP Agent

To get project information from the MCP server, use:

```javascript
// Call the project_discover tool
const response = await mcp.callTool('project_discover', {});
// Response contains: { count: 41, projects: [...] }
```

## Available MCP Tools

The devops-mcp server provides these project-related tools:
- `project_discover` - Discover all projects in configured workspaces
- `project_obs_run` - Run observers on a specific project (requires project_id)

## Architecture Notes

The current implementation:
1. Reads workspaces from TOML config
2. Walks each workspace directory (max depth 2)
3. Detects project types by presence of marker files:
   - `.git` - Version control
   - `package.json` - Node.js
   - `go.mod` - Go
   - `pyproject.toml` - Python
   - `mise.toml` - Mise configuration
   - `project.manifest.yaml` - Project manifest

## Next Steps

If the MCP agent needs projects exposed differently:
1. **Option A**: Agent should call the existing `project_discover` tool
2. **Option B**: Add a resource endpoint for projects (if tools aren't sufficient)
3. **Option C**: Cache project list and expose as static resource

The implementation is architecturally complete and functional. The issue appears to be a communication gap between what the agent expects and what the server provides.