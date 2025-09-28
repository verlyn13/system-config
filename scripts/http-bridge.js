#!/usr/bin/env node
// Read-only HTTP bridge for local dashboard access
// Serves: /api/telemetry-info, /api/projects, /api/projects/:id/status, /api/health, /api/events/stream
// No external deps; Node >=18 recommended

const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE || '.';
const DATA_DIR = path.join(HOME, '.local', 'share', 'devops-mcp');
const REGISTRY = path.join(DATA_DIR, 'project-registry.json');
const OBS_DIR = path.join(DATA_DIR, 'observations');

function sendJSON(res, code, obj) {
  const data = JSON.stringify(obj);
  res.writeHead(code, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data),
    'Cache-Control': 'no-store',
  });
  res.end(data);
}

function safeReadJSON(file, fallback = null) {
  try {
    const content = fs.readFileSync(file, 'utf-8');
    return JSON.parse(content);
  } catch {
    return fallback;
  }
}

function listProjects() {
  const reg = safeReadJSON(REGISTRY, { projects: [] });
  return reg.projects || [];
}

function latestFor(projectId) {
  const dir = path.join(OBS_DIR, projectId.replace(/[:/]/g, '__'));
  const latestPath = path.join(dir, 'latest.json');
  return safeReadJSON(latestPath, null);
}

function redacted(obj) {
  if (!obj) return obj;
  const clone = JSON.parse(JSON.stringify(obj));
  if (clone.links && clone.links.repo && typeof clone.links.repo === 'string') {
    clone.links.repo = clone.links.repo.replace(/^(https?:\/\/)[^/@]+@/i, '$1');
  }
  return clone;
}

function getObsLines(projectId, limit = 100, cursor = null) {
  const dir = path.join(OBS_DIR, projectId.replace(/[:/]/g, '__'));
  const file = path.join(dir, 'observations.ndjson');
  if (!fs.existsSync(file)) return { items: [], next: null };
  const lines = fs.readFileSync(file, 'utf-8').split('\n').filter(Boolean);
  let start = 0;
  if (cursor) {
    const idx = Number(cursor);
    if (!Number.isNaN(idx) && idx >= 0 && idx < lines.length) start = idx;
  }
  const slice = lines.slice(Math.max(0, lines.length - limit));
  const items = slice.map(l => { try { return redacted(JSON.parse(l)); } catch { return null; } }).filter(Boolean);
  const next = lines.length > limit ? String(lines.length - limit) : null;
  return { items, next };
}

function telemetryInfo() {
  return {
    contractVersion: '1.0.0',
    schemaVersion: 'obs.v1',
    registry_path: REGISTRY,
    observations_dir: OBS_DIR,
    sse: { endpoint: '/api/events/stream', heartbeat_ms: 15000 },
    retention_hint: 'local ndjson; rotate externally',
    link_templates: {
      trace: 'http://localhost:3000/explore?traceId=${trace_id}'
    }
  };
}

function rollupStatus(projectId) {
  const latest = latestFor(projectId);
  if (!latest) return { status: 'unknown' };
  return { status: latest.status, summary: latest.summary, observer: latest.observer, at: latest.timestamp };
}

function tryLoadRegistry() { return safeReadJSON(REGISTRY, { projects: [] }); }

const server = http.createServer((req, res) => {
  const parsed = url.parse(req.url, true);
  const { pathname, query } = parsed;

  if (pathname === '/api/health') {
    const ok = fs.existsSync(DATA_DIR);
    return sendJSON(res, ok ? 200 : 503, {
      ok,
      data_dir: DATA_DIR,
      registry_present: fs.existsSync(REGISTRY),
      obs_dir_present: fs.existsSync(OBS_DIR),
      version: '0.1.0'
    });
  }

  if (pathname === '/api/telemetry-info') {
    return sendJSON(res, 200, telemetryInfo());
  }

  if (pathname === '/.well-known/ai-discovery.json') {
    const p = path.join(__dirname, '..', '.well-known', 'ai-discovery.json');
    try {
      const body = fs.readFileSync(p, 'utf-8');
      res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
      return res.end(body);
    } catch {}
    return sendJSON(res, 404, { error: 'ai-discovery not found' });
  }

  if (pathname === '/api/projects') {
    const reg = tryLoadRegistry();
    const projects = reg.projects || [];
    const rollup = require(path.join(__dirname, 'obs-rollup.js'));
    const items = projects.map(p => ({
      id: p.id,
      name: p.name,
      org: p.org,
      tier: p.tier,
      kind: p.kind,
      path: p.path,
      status: rollupStatus(p.id),
      aggregate: rollup.aggregate(p.id, 200, reg)
    }));
    return sendJSON(res, 200, { projects: items, count: items.length, generated_at: new Date().toISOString() });
  }

  const projectStatusMatch = pathname.match(/^\/api\/projects\/([^/]+)\/status$/);
  if (projectStatusMatch) {
    const projectId = decodeURIComponent(projectStatusMatch[1]);
    const limit = Math.min(500, Number(query.limit || 100));
    const cursor = query.cursor || null;
    const result = getObsLines(projectId, limit, cursor);
    return sendJSON(res, 200, { project_id: projectId, ...result });
  }

  if (pathname === '/api/events/stream') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });
    res.write(`: ok\n\n`);

    const watchers = new Map();
    const writeEvent = (type, data) => {
      res.write(`event: ${type}\n`);
      res.write(`data: ${JSON.stringify(data)}\n\n`);
    };

    const projects = listProjects();
    for (const p of projects) {
      const dir = path.join(OBS_DIR, p.id.replace(/[:/]/g, '__'));
      const file = path.join(dir, 'observations.ndjson');
      try {
        if (fs.existsSync(file)) {
          const watcher = fs.watch(file, { persistent: false }, (evt) => {
            if (evt === 'change') {
              const { items } = getObsLines(p.id, 1);
              if (items.length) writeEvent('ProjectObsCompleted', items[0]);
            }
          });
          watchers.set(file, watcher);
        }
      } catch {}
    }

    const heartbeat = setInterval(() => {
      res.write(`: hb ${Date.now()}\n\n`);
    }, 15000);

    req.on('close', () => {
      clearInterval(heartbeat);
      for (const [, w] of watchers) try { w.close(); } catch {}
    });
    return;
  }

  const healthMatch = pathname.match(/^\/api\/projects\/([^/]+)\/health$/);
  if (healthMatch) {
    const projectId = decodeURIComponent(healthMatch[1]);
    const reg = tryLoadRegistry();
    const rollup = require(path.join(__dirname, 'obs-rollup.js'));
    const summary = rollup.aggregate(projectId, Number(query.limit || 200), reg);
    return sendJSON(res, 200, summary);
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not found');
});

const port = Number(process.env.PORT || 7171);
server.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`HTTP bridge listening on http://localhost:${port}`);
});
