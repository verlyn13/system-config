#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const BRIDGE = process.env.OBS_BRIDGE_URL || 'http://127.0.0.1:7171';
const TOKEN = process.env.BRIDGE_TOKEN || '';
const TIMEOUT_MS = Number(process.env.SSE_VALIDATE_TIMEOUT_MS || 5000);

function loadJSON(p) { return JSON.parse(fs.readFileSync(p, 'utf-8')); }

function compileValidators() {
  const ajv = new Ajv2020({ strict: true, allErrors: true });
  addFormats(ajv);
  const dir = path.join(process.cwd(), 'schema');

  // Load and add all schemas to resolve references
  const health = loadJSON(path.join(dir, 'obs.health.v1.json'));
  const line = loadJSON(path.join(dir, 'obs.line.v1.json'));
  const breach = loadJSON(path.join(dir, 'obs.slobreach.v1.json'));

  // Add schemas to Ajv instance to resolve $refs
  ajv.addSchema(health, 'https://contracts.local/schemas/obs.health.v1.json');
  ajv.addSchema(line, 'https://contracts.local/schemas/obs.line.v1.json');
  ajv.addSchema(breach, 'https://contracts.local/schemas/obs.slobreach.v1.json');

  const vLine = ajv.compile(line);
  const vBreach = ajv.compile(breach);
  return { vLine, vBreach };
}

async function sseValidate() {
  const { vLine, vBreach } = compileValidators();
  const url = new URL('/api/events/stream?replay_last=1', BRIDGE);
  const headers = { Accept: 'text/event-stream' };
  if (TOKEN) headers['Authorization'] = `Bearer ${TOKEN}`;
  const ctrl = new AbortController();
  const to = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, { headers, signal: ctrl.signal });
    if (!res.ok || !res.body) throw new Error('SSE connection failed');
    const reader = res.body.getReader();
    // Optionally trigger an observer run to produce an event after connection
    if ((process.env.SSE_TRIGGER_OBSERVER || '0') === '1') {
      try {
        const projRes = await fetch(new URL('/api/projects', BRIDGE), { headers: TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {} });
        const pj = await projRes.json();
        const pid = pj?.projects?.[0]?.id;
        if (pid) {
          await fetch(new URL('/api/tools/project_obs_run', BRIDGE), {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', ...(TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {}) },
            body: JSON.stringify({ project_id: pid, observer: 'manifest' })
          }).catch(()=>{});
        }
      } catch {}
    }
    let buf = '';
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buf += new TextDecoder().decode(value);
      const parts = buf.split('\n\n');
      buf = parts.pop() || '';
      for (const chunk of parts) {
        const lines = chunk.split('\n');
        const ev = { event: null, data: null };
        for (const ln of lines) {
          if (ln.startsWith('event: ')) ev.event = ln.slice(7).trim();
          else if (ln.startsWith('data: ')) ev.data = ln.slice(6);
        }
        if (!ev.event || !ev.data) continue;
        try {
          const obj = JSON.parse(ev.data);
          if (ev.event === 'ProjectObsCompleted') {
            if (!vLine(obj)) { console.error('ProjectObsCompleted invalid', vLine.errors); clearTimeout(to); await reader.cancel(); process.exit(1); }
            console.log('ProjectObsCompleted valid');
            clearTimeout(to); await reader.cancel(); process.exit(0);
          }
          if (ev.event === 'SLOBreach') {
            if (!vBreach(obj)) { console.error('SLOBreach invalid', vBreach.errors); clearTimeout(to); await reader.cancel(); process.exit(1); }
            console.log('SLOBreach valid');
            clearTimeout(to); await reader.cancel(); process.exit(0);
          }
        } catch {}
      }
    }
  } catch (e) {
    console.error('SSE validation error:', e.message || e);
    process.exit(1);
  } finally { clearTimeout(to); }
  console.error('SSE validation timed out');
  process.exit(1);
}

sseValidate();
