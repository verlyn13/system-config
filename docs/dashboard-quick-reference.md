---
title: Dashboard Quick Reference
category: reference
component: dashboard_quick_reference
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Dashboard Quick Reference Card

## Environment Setup
```bash
export OBS_BRIDGE_URL=http://127.0.0.1:7171
export BRIDGE_TOKEN=your-secret-token  # Optional
```

## Essential Endpoints

### System Status
```javascript
// Health check
GET /api/health
Response: { ok: true, data_dir: "...", registry_present: true }

// System info
GET /api/telemetry-info
Response: { contractVersion: "1.0.0", schemaVersion: "obs.v1" }
```

### Projects
```javascript
// List all projects (auto-discovers if empty)
GET /api/projects
Response: { projects: [...], count: 37 }

// Manual discovery
GET /api/discover
Response: { ok: true, discovery: { discovered: 37 } }
```

### Observations
```javascript
// Get all observations for project
GET /api/obs/projects/{project_id}/observers
Query: ?limit=200&cursor=...
Response: { items: [...], next: "cursor" }

// Get specific observer data
GET /api/obs/projects/{project_id}/observer/git
Response: { items: [...git observations...] }

// Get project health summary
GET /api/projects/{project_id}/health
Response: { overall: "ok|warn|fail", counts: {ok:5, warn:2, fail:1} }
```

### Execute Observers
```javascript
// Run specific observer
POST /api/tools/project_obs_run
Body: { "project_id": "abc123", "observer": "git" }
Response: { ok: true, results: { git: { status: "complete", lines: 1 } } }

// Run all observers
POST /api/tools/project_obs_run
Body: { "project_id": "abc123" }
Response: { ok: true, results: { git: {...}, deps: {...}, ... } }
```

### Live Updates
```javascript
// Server-sent events stream
GET /api/events/stream

// Example connection
const events = new EventSource(`${OBS_BRIDGE_URL}/api/events/stream`);
events.onmessage = (e) => {
  const data = JSON.parse(e.data);
  console.log('Event:', data.type, data);
};
```

## Authentication (if BRIDGE_TOKEN set)

```javascript
// Add to all requests except health/telemetry-info
headers: {
  'Authorization': `Bearer ${BRIDGE_TOKEN}`,
  'Content-Type': 'application/json'
}
```

## Data Formats

### Project Object
```json
{
  "id": "9a9cc800b78b",
  "name": "scopecam",
  "path": "/Users/.../scopecam",
  "workspace": "personal",
  "kind": "generic",
  "detectors": ["git", "manifest"]
}
```

### Observation Object (NDJSON line)
```json
{
  "apiVersion": "obs.v1",
  "run_id": "uuid",
  "timestamp": "2025-09-28T21:00:00Z",
  "project_id": "9a9cc800b78b",
  "observer": "git",
  "status": "ok",
  "data": {
    "branch": "main",
    "commit": "abc123",
    "dirty_files": 5
  }
}
```

## Common Patterns

### Initialize Dashboard
```javascript
async function initDashboard() {
  // 1. Check bridge health
  const health = await fetch(`${OBS_BRIDGE_URL}/api/health`).then(r => r.json());
  if (!health.ok) throw new Error('Bridge unhealthy');

  // 2. Get projects
  let projects = await fetch(`${OBS_BRIDGE_URL}/api/projects`).then(r => r.json());

  // 3. If no projects, trigger discovery
  if (projects.count === 0) {
    await fetch(`${OBS_BRIDGE_URL}/api/discover`);
    projects = await fetch(`${OBS_BRIDGE_URL}/api/projects`).then(r => r.json());
  }

  // 4. Connect to event stream
  connectToEvents();

  return projects;
}
```

### Refresh Project Data
```javascript
async function refreshProject(projectId) {
  const [health, observations] = await Promise.all([
    fetch(`${OBS_BRIDGE_URL}/api/projects/${projectId}/health`).then(r => r.json()),
    fetch(`${OBS_BRIDGE_URL}/api/obs/projects/${projectId}/observers`).then(r => r.json())
  ]);

  return { health, observations };
}
```

### Run Observer with Retry
```javascript
async function runObserver(projectId, observer = 'git', retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(`${OBS_BRIDGE_URL}/api/tools/project_obs_run`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ project_id: projectId, observer })
      });

      if (response.ok) {
        return await response.json();
      }
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(r => setTimeout(r, 1000 * (i + 1)));
    }
  }
}
```

## Troubleshooting

### No projects showing
```bash
# Trigger discovery
curl http://localhost:7171/api/discover
```

### 401 Unauthorized
```bash
# Check if token is set
echo $BRIDGE_TOKEN
# Include in requests
curl -H "Authorization: Bearer $BRIDGE_TOKEN" http://localhost:7171/api/projects
```

### SSE Connection Drops
```javascript
// Implement reconnection
events.onerror = () => {
  setTimeout(() => connectToEvents(), 5000);
};
```

### Empty Observations
```bash
# Run observer manually
curl -X POST http://localhost:7171/api/tools/project_obs_run \
  -H "Content-Type: application/json" \
  -d '{"project_id": "PROJECT_ID", "observer": "git"}'

# Check if files exist
ls ~/.local/share/devops-mcp/observations/PROJECT_ID/
```

## Available Observers
- `git` - Repository status
- `deps` - Dependencies
- `build` - Build configuration
- `quality` - Code quality
- `sbom` - Software bill of materials
- `manifest` - Project manifest

## Notes
- All observation data is NDJSON (single-line JSON)
- Bridge auto-discovers on empty registry
- Observations stored in two possible locations (bridge handles merging)
- Use bridge endpoints only, don't read files directly
- SSE heartbeat every 15 seconds

---

*Quick reference for dashboard integration with the observation bridge.*