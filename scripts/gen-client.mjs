#!/usr/bin/env node
// Pipeline: Spectral lint -> Redocly bundle -> Generate types (openapi-typescript)
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';

const SRC = process.env.OAS_SRC || 'openapi.yaml';
const OUT_BUNDLE = process.env.OAS_BUNDLE || 'build/openapi.bundled.yaml';
const TYPES_OUT = process.env.OAS_TYPES_OUT || 'examples/dashboard/generated/bridge-types.d.ts';

function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { stdio: 'inherit', ...opts });
  if (r.status !== 0) process.exit(r.status || 1);
}

// 1) Spectral lint (OAS rules)
run('npx', ['@stoplight/spectral-cli', 'lint', SRC, '-r', 'spectral:oas']);

// 2) Redocly bundle (dereferenced)
fs.mkdirSync('build', { recursive: true });
run('npx', ['@redocly/cli', 'bundle', SRC, '--dereferenced', '-o', OUT_BUNDLE]);

// 3) Generate types (openapi-typescript)
fs.mkdirSync(fs.dirname ? fs.dirname(TYPES_OUT) : 'examples/dashboard/generated', { recursive: true });
run('npx', ['openapi-typescript', OUT_BUNDLE, '-o', TYPES_OUT]);

console.log('Client generation pipeline completed.');

