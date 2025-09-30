#!/usr/bin/env node
import process from 'node:process';

const BRIDGE = process.argv[2] || process.env.OBS_BRIDGE_URL || 'http://127.0.0.1:7171';
const PID = process.env.PROJECT_ID || process.argv[3];
if (!PID) { console.error('Usage: PROJECT_ID=<id> node scripts/validate-manifest.mjs [bridgeUrl]'); process.exit(2); }

async function main(){
  const r = await fetch(`${BRIDGE}/api/projects/${encodeURIComponent(PID)}/manifest`);
  const j = await r.json();
  console.log(JSON.stringify(j, null, 2));
  if (!r.ok || j.valid === false) process.exit(1);
}

main().catch(e => { console.error(e); process.exit(1); });

