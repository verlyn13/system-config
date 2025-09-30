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

This directive provides everything needed for the dashboard to fully integrate with the MCP server's project discovery and observation capabilities.