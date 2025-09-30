#!/usr/bin/env node
/*
 Prefetch & ETag validation for Stage 4 readiness.
 - Fetches key endpoints, records ETag, verifies conditional GET (304 or identical ETag).
 - Summarizes cacheability for Dashboard prefetch design.
*/
import http from 'node:http';
import https from 'node:https';
import { URL } from 'node:url';

const BASE = process.env.OBS_BRIDGE_URL || 'http://127.0.0.1:7171';
const TOKEN = process.env.BRIDGE_TOKEN || '';

const endpoints = [
  '/api/health',
  '/api/discovery/services',
  '/api/discovery/schemas',
  '/api/projects',
];

function req(path, headers = {}) {
  const u = new URL(path, BASE);
  const mod = u.protocol === 'https:' ? https : http;
  return new Promise((resolve, reject) => {
    const opts = {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        ...(TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {}),
        ...headers,
      },
    };
    const r = mod.request(u, opts, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        const body = Buffer.concat(chunks).toString('utf8');
        resolve({ status: res.statusCode, headers: res.headers, body });
      });
    });
    r.on('error', reject);
    r.end();
  });
}

function statusOK(status) {
  return status && status >= 200 && status < 300;
}

async function run() {
  const results = [];
  for (const path of endpoints) {
    const first = await req(path);
    const etag = first.headers.etag || first.headers['etag'];
    const cacheControl = first.headers['cache-control'] || '';
    const expires = first.headers['expires'] || '';
    let conditional = null;
    if (etag) {
      conditional = await req(path, { 'If-None-Match': etag });
    }
    results.push({ path, first, etag, conditional, cacheControl, expires });
  }

  // Report
  let ok = true;
  for (const r of results) {
    const firstOK = statusOK(r.first.status);
    // Health and no-store endpoints don't need conditional caching
    const isHealth = r.path.includes('/health');
    const isSchemas = r.path.includes('/schemas');
    const noStore = (r.cacheControl || '').includes('no-store');
    let condOK = true;
    if (!isHealth && !noStore) {
      if (r.etag && r.conditional) {
        condOK = (r.conditional.status === 304) || (statusOK(r.conditional.status) && ((r.conditional.headers.etag || r.conditional.headers['etag']) === r.etag));
      }
    }
    ok = ok && firstOK && condOK;
    console.log(`- ${r.path}: status=${r.first.status} etag=${r.etag || '-'} cache-control=${r.cacheControl || '-'} expires=${r.expires || '-'}`);
    if (r.etag) {
      console.log(`  conditional: status=${r.conditional.status}`);
    } else {
      console.log('  conditional: (no ETag, skipped)');
    }
  }

  if (!ok) {
    console.error('Prefetch validation failed: some endpoints are not cache-friendly');
    process.exit(1);
  } else {
    console.log('✓ Prefetch validation passed');
  }
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
