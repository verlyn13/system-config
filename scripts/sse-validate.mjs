#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const BRIDGE = process.env.OBS_BRIDGE_URL || 'http://127.0.0.1:7171';
const TOKEN = process.env.BRIDGE_TOKEN || '';
const TIMEOUT_MS = Number(process.env.SSE_VALIDATE_TIMEOUT_MS || 8000);

function loadJSON(p) { return JSON.parse(fs.readFileSync(p, 'utf-8')); }

function compileValidators() {
  const ajv = new Ajv2020({ strict: true, allErrors: true });
  addFormats(ajv);
  const dir = path.join(process.cwd(), 'schema');
  const line = loadJSON(path.join(dir, 'obs.line.v1.json'));
  const breach = loadJSON(path.join(dir, 'obs.slobreach.v1.json'));
  const vLine = ajv.compile(line);
  const vBreach = ajv.compile(breach);
  return { vLine, vBreach };
}

async function sseValidate() {
  const { vLine, vBreach } = compileValidators();
  const url = new URL('/api/events/stream', BRIDGE);
  const headers = { Accept: 'text/event-stream' };
  if (TOKEN) headers['Authorization'] = `Bearer ${TOKEN}`;
  const ctrl = new AbortController();
  const to = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, { headers, signal: ctrl.signal });
    if (!res.ok || !res.body) throw new Error('SSE connection failed');
    const reader = res.body.getReader();
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
            if (!vLine(obj)) { console.error('ProjectObsCompleted invalid', vLine.errors); process.exit(1); }
            console.log('ProjectObsCompleted valid');
            clearTimeout(to); return;
          }
          if (ev.event === 'SLOBreach') {
            if (!vBreach(obj)) { console.error('SLOBreach invalid', vBreach.errors); process.exit(1); }
            console.log('SLOBreach valid');
            clearTimeout(to); return;
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

