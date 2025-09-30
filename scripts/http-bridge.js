#!/usr/bin/env node
// Read-only HTTP bridge for local dashboard access
// Serves: /api/telemetry-info, /api/projects, /api/projects/:id/status, /api/health, /api/events/stream
// Also serves discovery endpoints: /api/discovery/registry, /api/discovery/schemas
// No external deps; Node >=24 recommended

const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
let ajvValidateObs = null;
let ajvValidateBreach = null;
let ajvValidateManifest = null;
let schemaCache = null; // { etag, schemas: [...], loadedAt }
try {
  const Ajv = require('ajv');
  const ajv = new Ajv({ strict: true, allErrors: true });
  const obsSchemaPath = path.join(__dirname, '..', 'schema', 'obs.line.v1.json');
  const obsSchema = JSON.parse(fs.readFileSync(obsSchemaPath, 'utf-8'));
  ajvValidateObs = ajv.compile(obsSchema);
  const breachSchemaPath = path.join(__dirname, '..', 'schema', 'obs.slobreach.v1.json');
  let breachSchema = null;
  try { breachSchema = JSON.parse(fs.readFileSync(breachSchemaPath, 'utf-8')); ajvValidateBreach = ajv.compile(breachSchema); } catch {}
  // Warm schema cache
  const manifestPath = path.join(__dirname, '..', 'schema', 'project.manifest.schema.json');
  const manifestV1Path = path.join(__dirname, '..', 'schema', 'project.manifest.v1.json');
  const schemas = [obsSchema];
  try { schemas.push(JSON.parse(fs.readFileSync(manifestPath, 'utf-8'))); } catch {}
  try { schemas.push(JSON.parse(fs.readFileSync(manifestV1Path, 'utf-8'))); } catch {}
  if (breachSchema) schemas.push(breachSchema);
  try {
    const m = fs.existsSync(manifestV1Path)
      ? JSON.parse(fs.readFileSync(manifestV1Path, 'utf-8'))
      : (fs.existsSync(manifestPath) ? JSON.parse(fs.readFileSync(manifestPath, 'utf-8')) : null);
    if (m) ajvValidateManifest = ajv.compile(m);
  } catch {}
  const m1 = fs.statSync(obsSchemaPath).mtimeMs;
  const m2 = fs.existsSync(manifestPath) ? fs.statSync(manifestPath).mtimeMs : 0;
  const m2b = fs.existsSync(manifestV1Path) ? fs.statSync(manifestV1Path).mtimeMs : 0;
  const m3 = (breachSchema && fs.existsSync(breachSchemaPath)) ? fs.statSync(breachSchemaPath).mtimeMs : 0;
  const etag = `W/"${Number(m1 + m2 + m2b + m3).toString(36)}-${schemas.length}"`;
  schemaCache = { etag, schemas, loadedAt: new Date().toISOString() };
} catch (_) {
  ajvValidateObs = null; // Optional; will fallback to basic checks
}

const HOME = process.env.HOME || process.env.USERPROFILE || '.';
const DATA_DIR = path.join(HOME, '.local', 'share', 'devops-mcp');
const REGISTRY = path.join(DATA_DIR, 'project-registry.json');
const OBS_DIR = path.join(DATA_DIR, 'observations');
const SYS_REGISTRY = path.join(HOME, '.config', 'system', 'registry.yaml');
const ALT_OBS_DIR = path.join(HOME, 'Library', 'Application Support', 'devops.mcp', 'observations');

function sendJSON(res, code, obj, extraHeaders = null) {
  const data = JSON.stringify(obj);
  const headers = {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data),
    'Cache-Control': 'no-store',
  };
  if (extraHeaders && typeof extraHeaders === 'object') {
    for (const [k, v] of Object.entries(extraHeaders)) headers[k] = v;
  }
  if (process.env.BRIDGE_CORS === '1' || process.env.BRIDGE_CORS === 'true') {
    headers['Access-Control-Allow-Origin'] = '*';
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, If-None-Match';
    headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS';
  }
  res.writeHead(code, headers);
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

function projectDirs(projectId) {
  const code = projectId.replace(/[:/]/g, '__');
  const dirs = [path.join(OBS_DIR, code), path.join(ALT_OBS_DIR, code)];
  return dirs.filter(d => fs.existsSync(d));
}

function latestFor(projectId) {
  const dirs = projectDirs(projectId);
  const files = dirs.map(d => path.join(d, 'latest.json')).filter(f => fs.existsSync(f));
  if (!files.length) return null;
  files.sort((a,b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);
  return safeReadJSON(files[0], null);
}

function redacted(obj) {
  if (!obj) return obj;
  const clone = JSON.parse(JSON.stringify(obj));
  // Canonicalize observer names for external consumption (repo->git, deps->mise)
  if (clone.observer === 'repo') clone.observer = 'git';
  if (clone.observer === 'deps') clone.observer = 'mise';
  if (clone.links && clone.links.repo && typeof clone.links.repo === 'string') {
    clone.links.repo = clone.links.repo.replace(/^(https?:\/\/)[^/@]+@/i, '$1');
  }
  return clone;
}

function getObsLines(projectId, limit = 100, cursor = null) {
  const dirs = projectDirs(projectId);
  let lines = [];
  for (const dir of dirs) {
    const allFile = path.join(dir, 'observations.ndjson');
    if (fs.existsSync(allFile)) {
      lines = lines.concat(fs.readFileSync(allFile, 'utf-8').split('\n').filter(Boolean));
    }
    try {
      const files = fs.readdirSync(dir).filter(f => f.endsWith('.ndjson'));
      for (const f of files) {
        if (f === 'observations.ndjson') continue;
        lines = lines.concat(fs.readFileSync(path.join(dir, f), 'utf-8').split('\n').filter(Boolean));
      }
    } catch {}
  }
  if (!lines.length) return { items: [], next: null };
  let start = 0;
  if (cursor) {
    const idx = Number(cursor);
    if (!Number.isNaN(idx) && idx >= 0 && idx < lines.length) start = idx;
  }
  const parsed = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  parsed.sort((a,b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
  const slice = parsed.slice(Math.max(0, parsed.length - limit));
  const items = slice.map(redacted);
  const next = parsed.length > limit ? String(parsed.length - limit) : null;
  return { items, next };
}

function ensureCanonicalAppend(projectId, line) {
  try {
    const code = projectCode(projectId);
    const dir = path.join(OBS_DIR, code);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    let obj = null;
    try { obj = JSON.parse(line); } catch {}
    if (!obj) return; // ignore invalid JSON
    // Canonicalize observer aliases
    if (obj.observer === 'repo') obj.observer = 'git';
    if (obj.observer === 'deps') obj.observer = 'mise';
    const payload = JSON.stringify(obj);
    fs.appendFileSync(path.join(dir, 'observations.ndjson'), payload + '\n');
    fs.writeFileSync(path.join(dir, 'latest.json'), JSON.stringify(obj, null, 2));
  } catch {}
}

function projectCode(projectId) {
  // Filesystem-safe encoding for project directories
  return String(projectId).replace(/[:/]/g, '__');
}

function migrateProjectObservations(projectId) {
  const dirs = projectDirs(projectId);
  const seen = new Set();
  let merged = [];
  for (const dir of dirs) {
    try {
      const files = fs.readdirSync(dir).filter(f => f.endsWith('.ndjson'));
      for (const f of files) {
        const lines = fs.readFileSync(path.join(dir, f), 'utf-8').split('\n').filter(Boolean);
        for (const ln of lines) {
          try {
            const obj = JSON.parse(ln);
            if (obj.observer === 'repo') obj.observer = 'git';
            if (obj.observer === 'deps') obj.observer = 'mise';
            const key = obj.run_id ? `${obj.observer}:${obj.run_id}` : `${obj.observer}:${obj.timestamp}:${obj.summary}`;
            if (!seen.has(key)) { seen.add(key); merged.push(obj); }
          } catch {}
        }
      }
    } catch {}
  }
  merged.sort((a,b) => new Date(a.timestamp) - new Date(b.timestamp));
  const code = projectCode(projectId);
  const outDir = path.join(OBS_DIR, code);
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  const payload = merged.map(o => JSON.stringify(o)).join('\n') + (merged.length ? '\n' : '');
  fs.writeFileSync(path.join(outDir, 'observations.ndjson'), payload);
  if (merged.length) fs.writeFileSync(path.join(outDir, 'latest.json'), JSON.stringify(merged[merged.length-1], null, 2));
  return { migrated: merged.length };
}

const CONTRACT_VERSION = (() => {
  try { return fs.readFileSync(path.join(__dirname, '..', 'contracts', 'VERSION'), 'utf-8').trim(); } catch { return 'v1.1.0'; }
})();

function telemetryInfo() {
  return {
    contractVersion: CONTRACT_VERSION,
    schemaVersion: 'obs.v1',
    registry_path: REGISTRY,
    observations_dir: OBS_DIR,
    openapi_url: '/openapi.yaml',
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

function discoverIfNeeded() {
  try {
    const auto = process.env.BRIDGE_AUTO_DISCOVER;
    if (auto === '0' || auto === 'false') return { attempted: false };
    const reg = safeReadJSON(REGISTRY, { projects: [] });
    if (reg.projects && reg.projects.length > 0) return { attempted: false };
    const script = path.join(__dirname, 'project-discover.sh');
    if (fs.existsSync(script)) {
      const out = execFileSync(script, { encoding: 'utf-8' });
      return { attempted: true, result: JSON.parse(out) };
    }
  } catch (e) {
    return { attempted: true, error: String(e) };
  }
  return { attempted: false };
}

function runDiscovery() {
  const script = path.join(__dirname, 'project-discover.sh');
  if (!fs.existsSync(script)) throw new Error('project-discover.sh not found');
  const out = execFileSync(script, { encoding: 'utf-8' });
  return JSON.parse(out);
}

function tryLoadRegistry() { return safeReadJSON(REGISTRY, { projects: [] }); }

function tryLoadSystemRegistryJSON() {
  try {
    const out = execFileSync('bash', ['-lc', `yq -o=json "${SYS_REGISTRY}"`], { encoding: 'utf-8' });
    return JSON.parse(out);
  } catch { return null; }
}

function getServiceURL(name) {
  const sys = tryLoadSystemRegistryJSON();
  if (sys && sys.services && sys.services[name] && sys.services[name].url) {
    let url = sys.services[name].url;
    // Handle ${ENV:-default} syntax
    if (url.includes('${')) {
      url = url.replace(/\$\{([^:-]+)(?::-([^}]+))?\}/g, (match, envVar, defaultValue) => {
        return process.env[envVar] || defaultValue || match;
      });
    }
    return url;
  }
  if (name === 'ds') return process.env.DS_BASE_URL || 'http://127.0.0.1:7777';
  if (name === 'mcp') return process.env.MCP_BASE_URL || 'http://127.0.0.1:4319';
  return null;
}

function httpGet(urlString, headers = {}, timeoutMs = 1500) {
  return new Promise((resolve) => {
    try {
      const u = new URL(urlString);
      const mod = u.protocol === 'https:' ? require('https') : require('http');
      const req = mod.request({ hostname: u.hostname, port: u.port, path: u.pathname + (u.search || ''), method: 'GET', headers, timeout: timeoutMs }, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: data }));
      });
      req.on('error', () => resolve({ status: 0, headers: {}, body: '' }));
      req.on('timeout', () => { req.destroy(); resolve({ status: 0, headers: {}, body: '' }); });
      req.end();
    } catch { resolve({ status: 0, headers: {}, body: '' }); }
  });
}

async function httpGetJSON(urlString, headers = {}, timeoutMs = 1500) {
  const { status, body } = await httpGet(urlString, headers, timeoutMs);
  try { return { ok: status >= 200 && status < 300, status, body: JSON.parse(body) }; } catch { return { ok: false, status, body: null }; }
}

const server = http.createServer(async (req, res) => {
  const parsed = url.parse(req.url, true);
  const { pathname, query } = parsed;

  // Basic CORS support (dev)
  if (process.env.BRIDGE_CORS === '1' || process.env.BRIDGE_CORS === 'true') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, If-None-Match');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); }
  }

  // Optional token auth
  const token = process.env.BRIDGE_TOKEN || '';
  const publicPaths = new Set(['/api/health', '/api/telemetry-info', '/.well-known/ai-discovery.json', '/.well-known/obs-bridge.json', '/api/obs/well-known']);
  if (token && !publicPaths.has(pathname)) {
    const auth = req.headers['authorization'] || '';
    const ok = auth.startsWith('Bearer ') && auth.slice(7) === token;
    if (!ok) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({ error: 'unauthorized' }));
    }
  }

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

  if (pathname === '/openapi.yaml' || pathname === '/api/discovery/openapi') {
    try {
      const p = path.join(__dirname, '..', 'openapi.yaml');
      const body = fs.readFileSync(p, 'utf-8');
      res.writeHead(200, { 'Content-Type': 'application/yaml', 'Cache-Control': 'no-store' });
      return res.end(body);
    } catch (e) {
      return sendJSON(res, 404, { error: 'openapi not found' });
    }
  }

  // Serve schemas for OpenAPI relative $refs (e.g., ./schema/foo.json)
  const schemaAlias = pathname.match(/^\/schema\/([^/]+)$/);
  if (schemaAlias) {
    try {
      const name = decodeURIComponent(schemaAlias[1]);
      const file = path.join(__dirname, '..', 'schema', name);
      if (!fs.existsSync(file)) return sendJSON(res, 404, { error: 'schema_not_found' });
      const body = fs.readFileSync(file, 'utf-8');
      const etag = `W/"${fs.statSync(file).mtimeMs.toString(36)}-${Buffer.byteLength(body)}"`;
      if ((req.headers['if-none-match'] || '') === etag) { res.writeHead(304); return res.end(); }
      res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'ETag': etag });
      return res.end(body);
    } catch (e) {
      return sendJSON(res, 500, { error: 'schema_error', details: String(e.message || e) });
    }
  }

  const schemaMatch = pathname.match(/^\/api\/schemas\/([^/]+)$/);
  if (schemaMatch) {
    try {
      const name = decodeURIComponent(schemaMatch[1]);
      const file = path.join(__dirname, '..', 'schema', name);
      if (!fs.existsSync(file)) return sendJSON(res, 404, { error: 'schema_not_found' });
      const body = fs.readFileSync(file, 'utf-8');
      const etag = `W/"${fs.statSync(file).mtimeMs.toString(36)}-${Buffer.byteLength(body)}"`;
      if ((req.headers['if-none-match'] || '') === etag) { res.writeHead(304); return res.end(); }
      res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'ETag': etag });
      return res.end(body);
    } catch (e) {
      return sendJSON(res, 500, { error: 'schema_error', details: String(e.message || e) });
    }
  }

  if (pathname === '/api/discovery/services') {
    const sys = tryLoadSystemRegistryJSON();
    const ds = getServiceURL('ds');
    const mcp = getServiceURL('mcp');
    const payload = {
      ds: ds ? {
        url: ds,
        well_known: new URL('/.well-known/obs-bridge.json', ds).toString(),
        openapi: new URL('/openapi.yaml', ds).toString(),
        capabilities: new URL('/v1/capabilities', ds).toString(),
        health: new URL('/v1/health', ds).toString(),
        self_status: new URL('/api/self-status', ds).toString()
      } : null,
      mcp: mcp ? {
        url: mcp,
        openapi: new URL('/openapi.yaml', mcp).toString(),
        self_status: new URL('/api/self-status', mcp).toString()
      } : null,
      registry: sys,
      ds_token_present: !!process.env.DS_TOKEN,
      ts: Date.now()
    };
    // Compute weak ETag from registry mtime and URLs
    let mtime = 0;
    try { if (fs.existsSync(SYS_REGISTRY)) mtime = fs.statSync(SYS_REGISTRY).mtimeMs|0; } catch {}
    const etag = `W/"svc-${mtime.toString(36)}-${(ds||'').length + (mcp||'').length}"`;
    const inm = req.headers['if-none-match'] || '';
    if (inm && inm === etag) { res.writeHead(304); return res.end(); }
    return sendJSON(res, 200, payload, { 'Cache-Control': 'public, max-age=15, must-revalidate', 'ETag': etag });
  }

  if (pathname === '/api/discovery/registry') {
    try {
      // Return registry YAML as JSON if yq is available
      const out = execFileSync('bash', ['-lc', `yq -o=json "${SYS_REGISTRY}"`], { encoding: 'utf-8' });
      return sendJSON(res, 200, JSON.parse(out));
    } catch (e) {
      return sendJSON(res, 404, { error: 'registry not available', details: String(e.message || e) });
    }
  }

  if (pathname === '/api/discovery/schemas') {
    try {
      // Try to use schemaCache if available
      if (schemaCache) {
        const inm = req.headers['if-none-match'] || '';
        if (inm && inm === schemaCache.etag) {
          res.writeHead(304);
          return res.end();
        }
        const names = [];
        try { names.push(...fs.readdirSync(path.join(__dirname, '..', 'schema')).filter(f => f.endsWith('.json'))); } catch {}
        const ids = schemaCache.schemas.map(s => s.$id).filter(Boolean);
        const body = JSON.stringify({ schemas: schemaCache.schemas, names, ids, etag: schemaCache.etag, loadedAt: schemaCache.loadedAt });
        res.writeHead(200, {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
          'Cache-Control': 'no-store',
          'ETag': schemaCache.etag
        });
        return res.end(body);
      }

      // Fallback: Load schemas directly from files when Ajv/schemaCache is not available
      const schemaDir = path.join(__dirname, '..', 'schema');
      const schemaFiles = fs.readdirSync(schemaDir).filter(f => f.endsWith('.json'));
      const schemas = [];
      const names = schemaFiles;
      const ids = [];

      for (const file of schemaFiles) {
        try {
          const content = fs.readFileSync(path.join(schemaDir, file), 'utf8');
          const schema = JSON.parse(content);
          schemas.push(schema);
          if (schema.$id) ids.push(schema.$id);
        } catch (err) {
          console.warn(`Failed to load schema ${file}:`, err.message);
        }
      }

      const etag = `"fallback-${Date.now()}"`;
      const body = JSON.stringify({ schemas, names, ids, etag, loadedAt: new Date().toISOString() });
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        'Cache-Control': 'no-store',
        'ETag': etag
      });
      return res.end(body);
    } catch (e) {
      return sendJSON(res, 500, { error: 'failed to load schemas', details: String(e.message || e) });
    }
  }

  // Validate and return a project's manifest
  const manifestMatch = pathname.match(/^\/api\/projects\/([^/]+)\/manifest$/);
  if (manifestMatch) {
    const projectId = decodeURIComponent(manifestMatch[1]);
    const reg = tryLoadRegistry();
    const proj = (reg.projects || []).find(p => p.id === projectId);
    if (!proj) return sendJSON(res, 404, { error: 'project_not_found' });
    const pth = proj.manifest_path || (proj.path ? path.join(proj.path, 'project.manifest.yaml') : null);
    if (!pth || !fs.existsSync(pth)) return sendJSON(res, 404, { error: 'manifest_not_found' });
    try {
      const out = execFileSync('bash', ['-lc', `yq -o=json "${pth}"`], { encoding: 'utf-8' });
      const data = JSON.parse(out);
      let valid = null, errors = null;
      if (ajvValidateManifest) {
        valid = ajvValidateManifest(data);
        if (!valid) errors = ajvValidateManifest.errors;
      }
      return sendJSON(res, 200, { path: pth, valid, errors, manifest: data, checkedAt: Date.now() });
    } catch (e) {
      return sendJSON(res, 500, { error: 'manifest_parse_failed', details: String(e.message || e) });
    }
  }

  const obsManifestMatch = pathname.match(/^\/api\/obs\/projects\/([^/]+)\/manifest$/);
  if (obsManifestMatch) {
    // Rewrite to primary route
    req.url = `/api/projects/${encodeURIComponent(obsManifestMatch[1])}/manifest`;
    // Re-run handler logic by calling the function recursively is complex; so duplicate minimal logic
    const projectId = decodeURIComponent(obsManifestMatch[1]);
    const reg = tryLoadRegistry();
    const proj = (reg.projects || []).find(p => p.id === projectId);
    if (!proj) return sendJSON(res, 404, { error: 'project_not_found' });
    const pth = proj.manifest_path || (proj.path ? path.join(proj.path, 'project.manifest.yaml') : null);
    if (!pth || !fs.existsSync(pth)) return sendJSON(res, 404, { error: 'manifest_not_found' });
    try {
      const out = execFileSync('bash', ['-lc', `yq -o=json "${pth}"`], { encoding: 'utf-8' });
      const data = JSON.parse(out);
      let valid = null, errors = null;
      if (ajvValidateManifest) {
        valid = ajvValidateManifest(data);
        if (!valid) errors = ajvValidateManifest.errors;
      }
      return sendJSON(res, 200, { path: pth, valid, errors, manifest: data, checkedAt: Date.now() });
    } catch (e) {
      return sendJSON(res, 500, { error: 'manifest_parse_failed', details: String(e.message || e) });
    }
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

  // Direct well-known route
  if (pathname === '/.well-known/obs-bridge.json') {
    const p = path.join(__dirname, '..', '.well-known', 'obs-bridge.json');
    try {
      const body = fs.readFileSync(p, 'utf-8');
      res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
      return res.end(body);
    } catch {}
    return sendJSON(res, 404, { error: 'obs-bridge descriptor not found' });
  }

  // Aliases for convenience/parity (/api/obs/*)
  if (pathname === '/api/obs/well-known') {
    const p = path.join(__dirname, '..', '.well-known', 'obs-bridge.json');
    try {
      const body = fs.readFileSync(p, 'utf-8');
      res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
      return res.end(body);
    } catch {}
    return sendJSON(res, 404, { error: 'obs-bridge descriptor not found' });
  }

  if (pathname === '/api/obs/discovery/schemas') {
    // Delegate to discovery/schemas
    const inm = req.headers['if-none-match'] || '';
    req.url = '/api/discovery/schemas';
    req.headers['if-none-match'] = inm;
    // Fall through to handler below (same logic)
  }

  if (pathname === '/api/obs/discovery/services') {
    // Mirror discovery/services
    const sys = tryLoadSystemRegistryJSON();
    const ds = getServiceURL('ds');
    const mcp = getServiceURL('mcp');
    return sendJSON(res, 200, {
      ds: ds ? {
        url: ds,
        well_known: new URL('/.well-known/obs-bridge.json', ds).toString(),
        openapi: new URL('/openapi.yaml', ds).toString(),
        capabilities: new URL('/v1/capabilities', ds).toString(),
        health: new URL('/v1/health', ds).toString(),
        self_status: new URL('/api/self-status', ds).toString()
      } : null,
      mcp: mcp ? {
        url: mcp,
        openapi: new URL('/openapi.yaml', mcp).toString(),
        self_status: new URL('/api/self-status', mcp).toString()
      } : null,
      registry: sys,
      ds_token_present: !!process.env.DS_TOKEN,
      ts: Date.now()
    });
  }

  if (pathname === '/api/obs/discovery/openapi') {
    // Serve same as /openapi.yaml
    try {
      const p = path.join(__dirname, '..', 'openapi.yaml');
      const body = fs.readFileSync(p, 'utf-8');
      res.writeHead(200, { 'Content-Type': 'application/yaml', 'Cache-Control': 'no-store' });
      return res.end(body);
    } catch (e) {
      return sendJSON(res, 404, { error: 'openapi not found' });
    }
  }

  const obsSchemaAlias = pathname.match(/^\/api\/obs\/schemas\/([^/]+)$/);
  if (obsSchemaAlias) {
    const name = decodeURIComponent(obsSchemaAlias[1]);
    const file = path.join(__dirname, '..', 'schema', name);
    if (!fs.existsSync(file)) return sendJSON(res, 404, { error: 'schema_not_found' });
    const body = fs.readFileSync(file, 'utf-8');
    const etag = `W/"${fs.statSync(file).mtimeMs.toString(36)}-${Buffer.byteLength(body)}"`;
    if ((req.headers['if-none-match'] || '') === etag) { res.writeHead(304); return res.end(); }
    res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'ETag': etag });
    return res.end(body);
  }

  if (pathname === '/api/projects') {
    const attempt = discoverIfNeeded();
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
    const payload = { projects: items, count: items.length, generated_at: new Date().toISOString() };
    // Compute weak ETag from registry mtime and count
    let mtime = 0, size = 0;
    try { if (fs.existsSync(REGISTRY)) { const st = fs.statSync(REGISTRY); mtime = st.mtimeMs|0; size = st.size|0; } } catch {}
    const etag = `W/"proj-${mtime.toString(36)}-${size.toString(36)}-${items.length}"`;
    const inm = req.headers['if-none-match'] || '';
    if (inm && inm === etag) { res.writeHead(304); return res.end(); }
    return sendJSON(res, 200, payload, { 'Cache-Control': 'public, max-age=10, must-revalidate', 'ETag': etag });
  }

  // Compatibility obs routes for dashboard
  const obsListMatch = pathname.match(/^\/api\/obs\/projects\/([^/]+)\/observers$/);
  if (obsListMatch) {
    const projectId = decodeURIComponent(obsListMatch[1]);
    const limit = Math.min(1000, Number(query.limit || 200));
    const result = getObsLines(projectId, limit, query.cursor || null);
    return sendJSON(res, 200, { project_id: projectId, ...result });
  }
  const obsTypeMatch = pathname.match(/^\/api\/obs\/projects\/([^/]+)\/observer\/([^/]+)$/);
  if (obsTypeMatch) {
    const projectId = decodeURIComponent(obsTypeMatch[1]);
    const type = decodeURIComponent(obsTypeMatch[2]);
    const limit = Math.min(1000, Number(query.limit || 200));
    const all = getObsLines(projectId, 5000).items;
    const items = all.filter(it => (it.observer||'') === type).slice(-limit);
    return sendJSON(res, 200, { project_id: projectId, observer: type, items, next: null });
  }

  if (pathname === '/api/discover') {
    try {
      const result = runDiscovery();
      return sendJSON(res, 200, { ok: true, discovery: result });
    } catch (e) {
      return sendJSON(res, 500, { ok: false, error: String(e) });
    }
  }

  if (pathname === '/api/obs/validate') {
    const reg = tryLoadRegistry();
    const projects = reg.projects || [];
    let withObs = 0, withoutObs = 0;
    for (const p of projects) {
      const dirs = projectDirs(p.id);
      const has = dirs.some(d => {
        try { return fs.readdirSync(d).some(f => f.endsWith('.ndjson')); } catch { return false; }
      });
      if (has) withObs++; else withoutObs++;
    }
    return sendJSON(res, 200, {
      ok: true,
      projects_total: projects.length,
      projects_with_observations: withObs,
      projects_without_observations: withoutObs
    });
  }

  if (pathname === '/api/tools/obs_validate' && req.method === 'POST') {
    const reg = tryLoadRegistry();
    const projects = reg.projects || [];
    let withObs = 0, withoutObs = 0;
    for (const p of projects) {
      const dirs = projectDirs(p.id);
      const has = dirs.some(d => {
        try { return fs.readdirSync(d).some(f => f.endsWith('.ndjson')); } catch { return false; }
      });
      if (has) withObs++; else withoutObs++;
    }
    return sendJSON(res, 200, {
      ok: true,
      telemetry: { reachable: true },
      registry: { path: REGISTRY, exists: fs.existsSync(REGISTRY) },
      dirs: [OBS_DIR, ALT_OBS_DIR],
      projects_total: projects.length,
      projects_with_observations: withObs,
      projects_without_observations: withoutObs
    });
  }

  if (pathname === '/api/tools/obs_migrate' && req.method === 'POST') {
    let pid = null;
    try { const b = JSON.parse(await new Promise(r=>{ let d=''; req.on('data',c=>d+=c); req.on('end',()=>r(d)); })); pid = b.project_id || null; } catch {}
    const reg = tryLoadRegistry();
    const ids = pid ? [pid] : (reg.projects || []).map(p => p.id);
    const results = ids.map(id => ({ id, ...migrateProjectObservations(id) }));
    return sendJSON(res, 200, { ok: true, results });
  }

  if (pathname === '/api/obs/tools/obs_validate' && req.method === 'POST') {
    // Alias to /api/tools/obs_validate
    req.url = '/api/tools/obs_validate';
    const reg = tryLoadRegistry();
    const projects = reg.projects || [];
    let withObs = 0, withoutObs = 0;
    for (const p of projects) {
      const dirs = projectDirs(p.id);
      const has = dirs.some(d => {
        try { return fs.readdirSync(d).some(f => f.endsWith('.ndjson')); } catch { return false; }
      });
      if (has) withObs++; else withoutObs++;
    }
    return sendJSON(res, 200, {
      ok: true,
      telemetry: { reachable: true },
      registry: { path: REGISTRY, exists: fs.existsSync(REGISTRY) },
      dirs: [OBS_DIR, ALT_OBS_DIR],
      projects_total: projects.length,
      projects_with_observations: withObs,
      projects_without_observations: withoutObs
    });
  }

  if (pathname === '/api/obs/tools/obs_migrate' && req.method === 'POST') {
    // Alias to /api/tools/obs_migrate
    let pid = null;
    try { const b = JSON.parse(await new Promise(r=>{ let d=''; req.on('data',c=>d+=c); req.on('end',()=>r(d)); })); pid = b.project_id || null; } catch {}
    const reg = tryLoadRegistry();
    const ids = pid ? [pid] : (reg.projects || []).map(p => p.id);
    const results = ids.map(id => ({ id, ...migrateProjectObservations(id) }));
    return sendJSON(res, 200, { ok: true, results });
  }

  const projectStatusMatch = pathname.match(/^\/api\/projects\/([^/]+)\/status$/);
  if (projectStatusMatch) {
    const projectId = decodeURIComponent(projectStatusMatch[1]);
    const limit = Math.min(500, Number(query.limit || 100));
    const cursor = query.cursor || null;
    const result = getObsLines(projectId, limit, cursor);
    return sendJSON(res, 200, { project_id: projectId, ...result });
  }

  const projectIntegrationMatch = pathname.match(/^\/api\/projects\/([^/]+)\/integration$/);
  if (projectIntegrationMatch) {
    (async () => {
      const projectId = decodeURIComponent(projectIntegrationMatch[1]);
      const reg = tryLoadRegistry();
      const project = (reg.projects || []).find(p => p.id === projectId);
      if (!project) return sendJSON(res, 404, { error: 'project_not_found' });

      // Aggregate observer stats
      const all = getObsLines(projectId, 5000).items;
      const byType = {};
      for (const it of all) {
        const t = (it.observer || '').toLowerCase();
        const key = t === 'repo' ? 'git' : t === 'deps' ? 'mise' : t;
        if (!byType[key]) byType[key] = { count: 0, latest: null };
        byType[key].count++;
        byType[key].latest = it; // ordered ascending; last wins
      }

      // Rollup
      const rollup = require(path.join(__dirname, 'obs-rollup.js'));
      const summary = rollup.aggregate(projectId, 500, reg);

      // DS and MCP probes
      const dsUrl = getServiceURL('ds');
      const mcpUrl = getServiceURL('mcp');
      const dsHeaders = {};
      if (process.env.DS_TOKEN) dsHeaders['Authorization'] = `Bearer ${process.env.DS_TOKEN}`;
      const dsCaps = dsUrl ? await httpGetJSON(new URL('/v1/capabilities', dsUrl).toString(), dsHeaders) : { ok: false };
      const dsHealth = dsUrl ? await httpGetJSON(new URL('/v1/health', dsUrl).toString(), dsHeaders) : { ok: false };
      const dsSelf = dsUrl ? await httpGetJSON(new URL('/api/self-status', dsUrl).toString(), dsHeaders) : { ok: false };
      const mcpSelf = mcpUrl ? await httpGetJSON(new URL('/api/self-status', mcpUrl).toString()) : { ok: false };

      // High-level readiness summary
      const registryPresent = fs.existsSync(REGISTRY);
      const detectors = Object.keys(byType);
      const ready = registryPresent && detectors.length > 0 && summary.overall !== 'fail';

      return sendJSON(res, 200, {
        contractVersion: CONTRACT_VERSION,
        schemaVersion: 'obs.v1',
        project: {
          id: project.id,
          name: project.name,
          org: project.org,
          tier: project.tier,
          kind: project.kind,
          path: project.path,
          manifest_present: !!project.manifest
        },
        observers: byType,
        health: summary,
        services: {
          ds: { url: dsUrl, reachable: !!dsCaps.ok, capabilities: dsCaps.body || null, health: dsHealth.body || null, self_status: dsSelf.body || null },
          mcp: { url: mcpUrl, reachable: !!mcpSelf.ok, self_status: mcpSelf.body || null }
        },
        summary: {
          path: project.path,
          detectors,
          registryPath: REGISTRY,
          registryPresent,
          manifestValid: true,
          ready
        },
        timestamp: new Date().toISOString(),
        checkedAt: Date.now()
      });
    })();
    return;
  }

  const obsIntegrationMatch = pathname.match(/^\/api\/obs\/projects\/([^/]+)\/integration$/);
  if (obsIntegrationMatch) {
    // Mirror main integration endpoint using same logic
    (async () => {
      const projectId = decodeURIComponent(obsIntegrationMatch[1]);
      const reg = tryLoadRegistry();
      const project = (reg.projects || []).find(p => p.id === projectId);
      if (!project) return sendJSON(res, 404, { error: 'project_not_found' });

      const all = getObsLines(projectId, 5000).items;
      const byType = {};
      for (const it of all) {
        const t = (it.observer || '').toLowerCase();
        const key = t === 'repo' ? 'git' : t === 'deps' ? 'mise' : t;
        if (!byType[key]) byType[key] = { count: 0, latest: null };
        byType[key].count++;
        byType[key].latest = it;
      }

      const rollup = require(path.join(__dirname, 'obs-rollup.js'));
      const summary = rollup.aggregate(projectId, 500, reg);

      const dsUrl = getServiceURL('ds');
      const mcpUrl = getServiceURL('mcp');
      const dsHeaders = {};
      if (process.env.DS_TOKEN) dsHeaders['Authorization'] = `Bearer ${process.env.DS_TOKEN}`;
      const dsCaps = dsUrl ? await httpGetJSON(new URL('/v1/capabilities', dsUrl).toString(), dsHeaders) : { ok: false };
      const dsHealth = dsUrl ? await httpGetJSON(new URL('/v1/health', dsUrl).toString(), dsHeaders) : { ok: false };
      const dsSelf = dsUrl ? await httpGetJSON(new URL('/api/self-status', dsUrl).toString(), dsHeaders) : { ok: false };
      const mcpSelf = mcpUrl ? await httpGetJSON(new URL('/api/self-status', mcpUrl).toString()) : { ok: false };

      const registryPresent = fs.existsSync(REGISTRY);
      const detectors = Object.keys(byType);
      const ready = registryPresent && detectors.length > 0 && summary.overall !== 'fail';

      return sendJSON(res, 200, {
        contractVersion: CONTRACT_VERSION,
        schemaVersion: 'obs.v1',
        project: {
          id: project.id,
          name: project.name,
          org: project.org,
          tier: project.tier,
          kind: project.kind,
          path: project.path,
          manifest_present: !!project.manifest
        },
        observers: byType,
        health: summary,
        services: {
          ds: { url: dsUrl, reachable: !!dsCaps.ok, capabilities: dsCaps.body || null, health: dsHealth.body || null, self_status: dsSelf.body || null },
          mcp: { url: mcpUrl, reachable: !!mcpSelf.ok, self_status: mcpSelf.body || null }
        },
        summary: {
          path: project.path,
          detectors,
          registryPath: REGISTRY,
          registryPresent,
          manifestValid: true,
          ready
        },
        timestamp: new Date().toISOString(),
        checkedAt: Date.now()
      });
    })();
    return;
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
      // SSE validation and canonicalization
      if (type === 'ProjectObsCompleted') {
        if (!data || typeof data !== 'object') return;
        // Skip internal-only observers like 'quality' for public stream
        if (data.observer === 'quality') return;
        const item = redacted(data);
        if (ajvValidateObs && !ajvValidateObs(item)) {
          console.error('[Bridge] SSE validation failed', ajvValidateObs.errors);
          return;
        }
        res.write(`event: ${type}\n`);
        res.write(`id: ${Date.now()}\n`);
        res.write(`retry: 5000\n`);
        res.write(`data: ${JSON.stringify(item)}\n\n`);
        return;
      }
      if (type === 'SLOBreach') {
        if (ajvValidateBreach && (!data || !ajvValidateBreach(data))) {
          console.error('[Bridge] SLOBreach SSE validation failed', ajvValidateBreach?.errors);
          return;
        }
        res.write(`event: ${type}\n`);
        res.write(`id: ${Date.now()}\n`);
        res.write(`retry: 5000\n`);
        res.write(`data: ${JSON.stringify(data)}\n\n`);
        return;
      }
    };

    const projects = listProjects();
    for (const p of projects) {
      const code = p.id.replace(/[:/]/g, '__');
      const dir = path.join(OBS_DIR, code);
      const obsFile = path.join(dir, 'observations.ndjson');
      const eventsFile = path.join(dir, 'events.ndjson');
      try {
        if (fs.existsSync(obsFile)) {
          const watcher = fs.watch(obsFile, { persistent: false }, (evt) => {
            if (evt === 'change') {
              const { items } = getObsLines(p.id, 1);
              if (items.length) writeEvent('ProjectObsCompleted', items[0]);
            }
          });
          watchers.set(obsFile, watcher);
        } else if (fs.existsSync(dir)) {
          const watcherD = fs.watch(dir, { persistent: false }, (evt, filename) => {
            if (filename === 'observations.ndjson') {
              const { items } = getObsLines(p.id, 1);
              if (items.length) writeEvent('ProjectObsCompleted', items[0]);
            }
          });
          watchers.set(dir + ':obs', watcherD);
        }
      } catch {}
      try {
        if (fs.existsSync(eventsFile)) {
          const watcherE = fs.watch(eventsFile, { persistent: false }, (evt) => {
            if (evt === 'change') {
              try {
                const lines = fs.readFileSync(eventsFile, 'utf-8').trim().split('\n');
                const last = lines[lines.length - 1];
                const obj = JSON.parse(last);
                if (obj && obj.type === 'SLOBreach') writeEvent('SLOBreach', obj);
              } catch {}
            }
          });
          watchers.set(eventsFile, watcherE);
        } else if (fs.existsSync(dir)) {
          const watcherED = fs.watch(dir, { persistent: false }, (evt, filename) => {
            if (filename === 'events.ndjson') {
              try {
                const lines = fs.readFileSync(eventsFile, 'utf-8').trim().split('\n');
                const last = lines[lines.length - 1];
                const obj = JSON.parse(last);
                if (obj && obj.type === 'SLOBreach') writeEvent('SLOBreach', obj);
              } catch {}
            }
          });
          watchers.set(dir + ':events', watcherED);
        }
      } catch {}
    }

    // Optional: immediately replay the latest observation for fast validation
    if (query.replay_last === '1') {
      try {
        for (const p of projects) {
          const { items } = getObsLines(p.id, 1);
          if (items.length) writeEvent('ProjectObsCompleted', items[0]);
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

  // Self-status endpoint (bridge proxy to MCP self_status resource)
  if (pathname === '/api/self-status') {
    try {
      const reg = tryLoadRegistry();
      const projectCount = reg?.projects?.length || 0;
      const registryMtime = fs.existsSync(REGISTRY) ? fs.statSync(REGISTRY).mtimeMs : 0;
      const strict = (process.env.BRIDGE_STRICT === '1' || process.env.BRIDGE_STRICT === 'true');
      const hasSchemas = !!schemaCache;
      const observations_dirs = [OBS_DIR, ALT_OBS_DIR].filter(d => fs.existsSync(d));
      return sendJSON(res, 200, {
        contractVersion: CONTRACT_VERSION,
        schemaVersion: 'obs.v1',
        strict,
        schemas_etag: schemaCache?.etag || null,
        registry_path: REGISTRY,
        registry_mtime: registryMtime,
        observations_dirs,
        project_count: projectCount,
        bridge_port: port,
        ok: true,
        timestamp: new Date().toISOString()
      });
    } catch (e) {
      return sendJSON(res, 500, {
        ok: false,
        error: String(e),
        timestamp: new Date().toISOString()
      });
    }
  }

  // Manual discovery trigger endpoint
  if (pathname === '/api/discover') {
    try {
      console.log('[Bridge] Manual discovery triggered via /api/discover');
      const result = runDiscovery();
      console.log(`[Bridge] Discovery complete: ${result.discovered || 0} projects`);
      return sendJSON(res, 200, result);
    } catch (e) {
      console.error('[Bridge] Discovery failed:', e);
      return sendJSON(res, 500, { error: 'Discovery failed', details: String(e) });
    }
  }

  // Observer execution endpoint
  if (pathname === '/api/tools/project_obs_run' || pathname === '/api/tool/project_obs_run') {
    if (req.method !== 'POST') {
      return sendJSON(res, 405, { error: 'Method not allowed' });
    }

    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        let { project_id, observer, observers } = JSON.parse(body || '{}');

        if (!project_id) {
          return sendJSON(res, 400, { error: 'project_id required' });
        }

        // Get project from registry
        const reg = tryLoadRegistry();
        const project = reg?.projects?.find(p => p.id === project_id);

        if (!project) {
          return sendJSON(res, 404, { error: `Project ${project_id} not found` });
        }

        // Canonical observer acceptance with alias mapping
        const aliasMap = { repo: 'git', deps: 'mise' };
        const allowed = new Set(['git','mise','sbom','build','manifest']);
        let requested = [];
        if (Array.isArray(observers) && observers.length) {
          requested = observers.map(o => aliasMap[o] || o);
        } else if (observer) {
          requested = [aliasMap[observer] || observer];
        }
        if (requested.some(o => o === 'quality')) return sendJSON(res, 400, { error: 'observer_not_supported' });
        if (requested.some(o => !allowed.has(o))) return sendJSON(res, 400, { error: 'observer_invalid' });
        // Map canonical observers to script names in this repo
        const observerMap = {
          'git': 'repo-observer.sh',
          'mise': 'deps-observer.sh',
          'build': 'build-observer.sh',
          'sbom': 'sbom-observer.sh',
          'manifest': 'manifest-observer.sh'
        };

        const defaultSet = ['git', 'mise', 'build', 'sbom', 'manifest'];
        const runList = requested.length ? Array.from(new Set(requested)) : defaultSet;
        const results = {};

        console.log(`[Bridge] Running observers for project ${project_id}: ${runList.join(', ')}`);

        // Run observers
        let anyStrictViolation = false;
        for (const obs of runList) {
          const scriptName = observerMap[obs] || `${obs}-observer.sh`;
          const scriptPath = path.join(__dirname, '..', 'observers', scriptName);

          if (!fs.existsSync(scriptPath)) {
            console.warn(`[Bridge] Observer script not found: ${scriptPath}`);
            results[obs] = { status: 'failed', error: 'Observer not found' };
            continue;
          }

          try {
            // Create output directory
            const outputDir = path.join(OBS_DIR, project_id.replace(/[:/]/g,'__'));
            if (!fs.existsSync(outputDir)) {
              fs.mkdirSync(outputDir, { recursive: true });
            }

            // Run observer script (pass both path and ID as arguments)
            const { execSync } = require('child_process');
            const output = execSync(`bash ${scriptPath} "${project.path}" "${project_id}"`, {
              encoding: 'utf-8',
              timeout: 10000,
              env: { ...process.env, PROJECT_ID: project_id }
            });

            // Save output to NDJSON file
            const outputFile = path.join(outputDir, `${obs}.ndjson`);
            const line = output.trim();
            // Validate line if strict
            const strict = (process.env.BRIDGE_STRICT === '1' || process.env.BRIDGE_STRICT === 'true');
            let valid = true;
            try {
              const red = redacted(JSON.parse(line));
              if (ajvValidateObs) valid = ajvValidateObs(red);
              if (valid) {
                fs.appendFileSync(outputFile, JSON.stringify(red) + '\n');
                ensureCanonicalAppend(project_id, JSON.stringify(red));
              } else if (strict) {
                results[obs] = { status: 'failed', error: 'schema_violation', details: ajvValidateObs?.errors };
                anyStrictViolation = true;
                continue;
              } else {
                // Non-strict, append raw
                fs.appendFileSync(outputFile, line.endsWith('\n') ? line : line + '\n');
                ensureCanonicalAppend(project_id, line);
              }
            } catch (e) {
              if (strict) {
                results[obs] = { status: 'failed', error: 'invalid_json' };
                anyStrictViolation = true;
                continue;
              } else {
                fs.appendFileSync(outputFile, line.endsWith('\n') ? line : line + '\n');
                ensureCanonicalAppend(project_id, line);
              }
            }

            results[obs] = {
              status: 'complete',
              lines: output.split('\n').filter(Boolean).length,
              file: outputFile
            };

            console.log(`[Bridge] Observer ${obs} completed: ${results[obs].lines} lines`);
          } catch (error) {
            console.error(`[Bridge] Observer ${obs} failed:`, error.message);
            results[obs] = {
              status: 'failed',
              error: error.message.substring(0, 200)
            };
          }
        }

        const payload = {
          ok: Object.values(results).some(r => r.status === 'complete'),
          project_id,
          results
        };
        const strictFail = (process.env.BRIDGE_STRICT_FAIL === '1' || process.env.BRIDGE_STRICT_FAIL === 'true');
        if (strictFail && anyStrictViolation) {
          res.writeHead(422, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify(payload));
        }
        return sendJSON(res, 200, payload);
      } catch (error) {
        console.error('[Bridge] obs-run error:', error);
        return sendJSON(res, 500, { error: 'Internal error', details: error.message });
      }
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not found');
});

const port = Number(process.env.PORT || 7171);
server.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`HTTP bridge listening on http://localhost:${port}`);
});
