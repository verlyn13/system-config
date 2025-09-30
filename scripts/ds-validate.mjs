#!/usr/bin/env node
import process from 'node:process';

const DS = process.env.DS_BASE_URL || 'http://127.0.0.1:7777';
const TOKEN = process.env.DS_TOKEN || '';

async function jget(path) {
  const res = await fetch(new URL(path, DS), { headers: TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {} });
  const data = await res.json().catch(() => ({ }));
  return { ok: res.ok, status: res.status, data };
}

(async () => {
  let failed = false;
  const self = await jget('/api/self-status');
  if (!self.ok) { console.error('DS self-status failed', self.status); failed = true; }
  if (self.data && self.data.schema_version !== 'ds.v1') { console.error('DS schema_version mismatch', self.data.schema_version); failed = true; }
  if (self.data && typeof self.data.nowMs !== 'number') { console.error('DS nowMs missing or invalid'); failed = true; }

  const health = await jget('/v1/health');
  if (!health.ok) { console.error('DS health failed', health.status); failed = true; }
  if (health.data && health.data.schema_version !== 'ds.v1') { console.error('DS health schema_version mismatch', health.data.schema_version); failed = true; }

  const caps = await jget('/v1/capabilities');
  if (!caps.ok) { console.error('DS capabilities failed', caps.status); failed = true; }

  if (failed) process.exit(1);
  console.log('DS validation passed');
})();

