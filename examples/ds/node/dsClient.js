#!/usr/bin/env node
// Minimal DS client for dashboard/server examples (Node >=24)
const DS = process.env.DS_BASE_URL || 'http://127.0.0.1:7777';
const TOKEN = process.env.DS_TOKEN || '';

async function get(path){
  const res = await fetch(new URL(path, DS), { headers: TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {} });
  if (!res.ok) throw new Error(`${path} ${res.status}`);
  return res.json();
}

(async () => {
  try {
    const health = await get('/v1/health');
    const caps = await get('/v1/capabilities');
    console.log(JSON.stringify({ health, capabilities: caps }, null, 2));
  } catch (e) {
    console.error('DS client error:', e.message);
    process.exit(1);
  }
})();
