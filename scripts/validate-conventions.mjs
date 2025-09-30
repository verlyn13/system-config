#!/usr/bin/env node
// Validate port and env conventions across the repo to avoid confusion.
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const exts = new Set(['.md','.yaml','.yml','.js','.mjs','.ts','.tsx','.sh']);
const ignoreDirs = new Set(['node_modules','.git','.next','dist','build']);

const patterns = [
  { name: 'MCP uses 7171 (should be 4319)', re: /(MCP[_A-Z]*|mcp)[^\n]{0,40}127\.0\.0\.1:7171/i },
  { name: 'Bridge uses 4319 (should be 7171)', re: /(BRIDGE|OBS_BRIDGE_URL|bridge)[^\n]{0,40}127\.0\.0\.1:4319/i },
  { name: 'DS uses wrong port (should be 7777)', re: /(DS[_A-Z]*|ds)[^\n]{0,40}127\.0\.0\.1:(7171|4319)/i },
  { name: 'MCP_BASE_URL default not 4319', re: /(MCP_BASE_URL)\s*[:=]\s*['"]?http:\/\/127\.0\.0\.1:(?!4319)\d+/ },
  { name: 'MCP_URL default not 4319', re: /(MCP_URL)\s*[:=]\s*['"]?http:\/\/127\.0\.0\.1:(?!4319)\d+/ },
  { name: 'OBS_BRIDGE_URL default not 7171', re: /(OBS_BRIDGE_URL)\s*[:=]\s*['"]?http:\/\/127\.0\.0\.1:(?!7171)\d+/ },
  { name: 'DS_BASE_URL default not 7777', re: /(DS_BASE_URL)\s*[:=]\s*['"]?http:\/\/127\.0\.0\.1:(?!7777)\d+/ },
];

function* walk(dir){
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) {
      if (entry.name === '.github' || entry.name === '.well-known') {
        // include
      } else if (ignoreDirs.has(entry.name)) {
        continue;
      }
    }
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) yield* walk(p);
    else {
      const ext = path.extname(entry.name);
      if (exts.has(ext)) yield p;
    }
  }
}

let violations = [];
for (const file of walk(ROOT)) {
  let text = '';
  try { text = fs.readFileSync(file, 'utf8'); } catch { continue; }
  for (const rule of patterns) {
    const m = rule.re.exec(text);
    if (m) {
      const idx = m.index;
      const snippet = text.slice(Math.max(0, idx - 40), Math.min(text.length, idx + 80)).replace(/\n/g,' ');
      violations.push({ file, rule: rule.name, snippet });
    }
  }
}

if (violations.length) {
  console.error('Convention violations found:');
  for (const v of violations) {
    console.error(`- ${v.rule}: ${v.file}`);
    console.error(`  ... ${v.snippet} ...`);
  }
  process.exit(1);
}
console.log('Conventions OK');

