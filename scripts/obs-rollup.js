#!/usr/bin/env node
// Observation rollup and SLO evaluation (no external deps)

const fs = require('fs');
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE || '.';
const DATA_DIR = path.join(HOME, '.local', 'share', 'devops-mcp');
const REGISTRY = path.join(DATA_DIR, 'project-registry.json');
const OBS_DIR = path.join(DATA_DIR, 'observations');

function readJSON(p, fallback = null) { try { return JSON.parse(fs.readFileSync(p, 'utf-8')); } catch { return fallback; } }
function lines(file) { try { return fs.readFileSync(file, 'utf-8').split('\n').filter(Boolean); } catch { return []; } }

function tailObservations(projectId, limit = 200) {
  const dir = path.join(OBS_DIR, projectId.replace(/[:/]/g, '__'));
  const file = path.join(dir, 'observations.ndjson');
  const ls = lines(file);
  return ls.slice(Math.max(0, ls.length - limit)).map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
}

function parseThreshold(expr) {
  if (typeof expr !== 'string') return null;
  const m = expr.match(/^(>=|<=|>|<|==)\s*([\d.]+)$/);
  if (!m) return null;
  return { op: m[1], value: Number(m[2]) };
}

function compare(op, a, b) {
  switch (op) {
    case '>=': return a >= b;
    case '<=': return a <= b;
    case '>': return a > b;
    case '<': return a < b;
    case '==': return a === b;
    default: return false;
  }
}

function p95(arr) {
  if (!arr.length) return 0;
  const s = [...arr].sort((a, b) => a - b);
  const idx = Math.ceil(0.95 * s.length) - 1;
  return s[Math.max(0, idx)];
}

function aggregate(projectId, limit = 200, reg) {
  const obs = tailObservations(projectId, limit);
  const counts = { ok: 0, warn: 0, fail: 0 };
  const latency = {};
  for (const o of obs) {
    if (counts[o.status] !== undefined) counts[o.status]++;
    if (o.metrics && typeof o.metrics.latency_ms === 'number') {
      const key = o.observer || 'unknown';
      (latency[key] ||= []).push(o.metrics.latency_ms);
    }
  }
  const overall = counts.fail > 0 ? 'fail' : counts.warn > 0 ? 'warn' : (counts.ok > 0 ? 'ok' : 'unknown');

  // SLOs: use manifest if available
  let slo = { ciSuccessRate: null, p95LocalBuildSec: null };
  try {
    const p = reg.projects.find(p => p.id === projectId);
    if (p && p.manifest && p.manifest.observability && p.manifest.observability.slo) slo = p.manifest.observability.slo;
  } catch {}

  const buildP95ms = p95(latency['build'] || []);
  const p95Check = slo.p95LocalBuildSec ? compare(parseThreshold(slo.p95LocalBuildSec).op, buildP95ms / 1000, parseThreshold(slo.p95LocalBuildSec).value) : null;

  return {
    project_id: projectId,
    overall,
    counts,
    observers: Object.fromEntries(Object.entries(latency).map(([k, v]) => [k, { p95_ms: p95(v), runs: v.length }])),
    slo: {
      p95LocalBuildSec: slo.p95LocalBuildSec || null,
      p95LocalBuildSec_ok: p95Check,
      ciSuccessRate: slo.ciSuccessRate || null,
      ciSuccessRate_ok: null // compute from CI integration if available
    }
  };
}

if (require.main === module) {
  const projectId = process.argv[2];
  if (!projectId) { console.error('Usage: obs-rollup.js <project_id> [limit]'); process.exit(1); }
  const limit = Number(process.argv[3] || 200);
  const reg = readJSON(REGISTRY, { projects: [] });
  const out = aggregate(projectId, limit, reg);
  console.log(JSON.stringify(out, null, 2));
}

module.exports = { aggregate };

