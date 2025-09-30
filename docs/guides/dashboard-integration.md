---
title: Dashboard Integration Guide
category: guide
component: dashboard
status: active
version: 1.0.0
last_updated: 2025-09-28
tags: [dashboard, ui, integration, mcp, bridge]
priority: high
---

# Dashboard Integration Guide

This guide provides the complete integration requirements for the dashboard UI to properly connect with the MCP server and HTTP bridge.

## API Endpoints

### Core Endpoints

#### Project Discovery
```javascript
// Trigger manual discovery
GET /api/discover
Response: { discovered: 37, registry: "path", timestamp: "ISO8601" }

// Get all projects
GET /api/projects
Response: { projects: [...], total: 37 }

// Get single project
GET /api/projects/:id
Response: { id, name, path, workspace, kind, detectors, observations }
```

#### Observer Execution
```javascript
// Run specific observer for project
POST /api/tools/project_obs_run
Body: {
  "project_id": "abc123def456",
  "observer": "git" | "mise" | "build" | "sbom"  // optional, runs all if omitted
}
Response: { ok: true, results: {...} }
```

#### System Health
```javascript
// Get bridge health status
GET /api/self-status
Response: {
  "bridge_version": "1.0.0",
  "registry_mtime": 1234567890000,
  "project_count": 37,
  "bridge_port": 7171,
  "health": "ok",
  "timestamp": "2025-09-28T15:30:00Z"
}

// Get maintenance status (MCP server)
POST /api/tools/server_maintain
Response: {
  "ok": true,
  "audit_checkpoint": true,
  "retention_cleanup": 0,
  "cache_prune": 5,
  "vacuum": true
}
```

### Project Filtering

```javascript
// Query parameters for /api/projects
GET /api/projects?q=search&kind=node&detectors=git,mise&sort=name&order=asc&page=1&pageSize=20

Parameters:
- q: Search term (matches name or path)
- kind: Filter by project type (node|go|python|rust|mix|generic)
- detectors: Comma-separated detector list (git|node|go|python|rust|mise|manifest|make|docker)
- sort: Sort field (name|kind|workspace)
- order: Sort order (asc|desc)
- page: Page number (1-based)
- pageSize: Items per page (default 20)
```

### Event Streaming

```javascript
// Server-sent events for real-time updates
GET /api/events/stream?project_id=xxx

Event format:
data: {"type":"discovery","projects":37,"timestamp":"2025-09-28T15:30:00Z"}

data: {"type":"observation","project_id":"abc123","observer":"git","status":"complete"}

: hb 1234567890  // Heartbeat every 15s
```

## Error Handling

### Retry Strategy
The dashboard MUST implement retry logic for:

1. **Observer Failures**: Observers may timeout or fail
   - Retry up to 3 times with exponential backoff
   - Start with 100ms, max 500ms between retries

2. **Network Errors**: Connection issues to bridge
   - Implement automatic reconnection for SSE streams
   - Show connection status in UI

### Partial Data Handling
```javascript
// Observers may return partial results
{
  "ok": true,
  "results": {
    "git": { "status": "complete", "data": {...} },
    "mise": { "status": "failed", "error": "timeout" },
    "build": { "status": "partial", "data": {...}, "warning": "incomplete" }
  }
}
```

## UI Requirements

### Project List View
```javascript
// Component: ProjectList
const ProjectList = () => {
  // Poll /api/projects every 30s
  // Display: name, workspace, kind, detector icons
  // Actions: Run Observer, View Details

  return (
    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Workspace</th>
          <th>Type</th>
          <th>Detectors</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        {projects.map(p => (
          <ProjectRow key={p.id} project={p} />
        ))}
      </tbody>
    </table>
  );
};
```

### Observer Control Panel
```javascript
// Component: ObserverPanel
const ObserverPanel = ({ projectId }) => {
  const observers = ['git', 'mise', 'build', 'sbom'];

  const runObserver = async (observer) => {
    setLoading(true);
    try {
      const res = await fetch('/api/tools/project_obs_run', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ project_id: projectId, observer })
      });

      if (!res.ok) throw new Error('Observer failed');

      const data = await res.json();
      // Handle partial results
      if (data.results[observer]?.status === 'partial') {
        showWarning('Observer returned partial results');
      }
    } catch (error) {
      // Implement retry logic here
      retry(() => runObserver(observer), { times: 3, delay: 100 });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="observer-panel">
      {observers.map(obs => (
        <button
          key={obs}
          onClick={() => runObserver(obs)}
          disabled={loading}
        >
          Run {obs}
        </button>
      ))}
    </div>
  );
};
```

### Health Monitor
```javascript
// Component: HealthMonitor
const HealthMonitor = () => {
  const [status, setStatus] = useState(null);

  useEffect(() => {
    const interval = setInterval(async () => {
      try {
        const res = await fetch('/api/self-status');
        const data = await res.json();
        setStatus(data);
      } catch (error) {
        setStatus({ health: 'error', error: error.message });
      }
    }, 5000);  // Check every 5s

    return () => clearInterval(interval);
  }, []);

  return (
    <div className={`health-indicator ${status?.health}`}>
      <span>Bridge: {status?.health || 'unknown'}</span>
      <span>Projects: {status?.project_count || 0}</span>
    </div>
  );
};
```

## Data Schema Compliance

The dashboard MUST validate data against the project integration schema:

```javascript
// Validate project structure
const validateProject = (project) => {
  const required = ['id', 'name', 'path', 'workspace', 'kind', 'detectors'];
  return required.every(field => project[field] !== undefined);
};

// Validate observer output
const validateObserverOutput = (output) => {
  // Each line must be valid JSON (NDJSON format)
  const lines = output.split('\n').filter(Boolean);
  return lines.every(line => {
    try {
      JSON.parse(line);
      return true;
    } catch {
      return false;
    }
  });
};
```

## Connection Management

```javascript
class BridgeConnection {
  constructor(baseUrl = 'http://localhost:7171') {
    this.baseUrl = baseUrl;
    this.eventSource = null;
    this.reconnectAttempts = 0;
  }

  connect() {
    this.eventSource = new EventSource(`${this.baseUrl}/api/events/stream`);

    this.eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      this.handleEvent(data);
    };

    this.eventSource.onerror = () => {
      this.reconnect();
    };

    // Reset reconnect counter on successful connection
    this.eventSource.onopen = () => {
      this.reconnectAttempts = 0;
    };
  }

  reconnect() {
    if (this.reconnectAttempts >= 5) {
      console.error('Max reconnection attempts reached');
      return;
    }

    setTimeout(() => {
      this.reconnectAttempts++;
      this.connect();
    }, Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000));
  }

  handleEvent(data) {
    // Dispatch events to UI components
    switch(data.type) {
      case 'discovery':
        // Update project list
        break;
      case 'observation':
        // Update observation status
        break;
      default:
        console.warn('Unknown event type:', data.type);
    }
  }
}
```

## Testing the Integration

Use the validation script to ensure proper integration:

```bash
# Run validation suite
./scripts/validate-integration.sh

# Monitor system health
./scripts/system-health.sh

# Manual testing
curl http://localhost:7171/api/projects | jq
curl http://localhost:7171/api/self-status | jq
```

## Common Issues & Solutions

### Issue: Projects not showing
**Solution**: Ensure discovery has run
```bash
curl http://localhost:7171/api/discover
```

### Issue: Observer timeout
**Solution**: Increase timeout parameter
```javascript
POST /api/tools/project_obs_run
{ "project_id": "xxx", "observer": "build", "timeoutMs": 5000 }
```

### Issue: SSE connection drops
**Solution**: Implement automatic reconnection with exponential backoff

### Issue: Stale data
**Solution**: Use registry modification time to detect updates
```javascript
const isStale = (registryMtime) => {
  const age = Date.now() - registryMtime;
  return age > 3600000; // Older than 1 hour
};
```

## Summary

The dashboard must:
1. ✅ Handle partial observer results gracefully
2. ✅ Implement retry logic for failed operations
3. ✅ Maintain SSE connection with auto-reconnect
4. ✅ Validate data against schema
5. ✅ Show real-time health status
6. ✅ Support selective observer execution
7. ✅ Display connection status to users
8. ✅ Handle timeouts appropriately

---

*This guide ensures the dashboard UI properly integrates with the hardened MCP server and HTTP bridge infrastructure.*