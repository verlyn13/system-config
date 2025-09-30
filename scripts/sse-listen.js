#!/usr/bin/env node
// Minimal SSE listener for /api/events/stream
const http = require('http');

const BRIDGE = process.env.OBS_BRIDGE_URL || 'http://127.0.0.1:7171';
const url = new URL('/api/events/stream', BRIDGE);

const req = http.request({ hostname: url.hostname, port: url.port, path: url.pathname + (url.search||''), method: 'GET', headers: { Accept: 'text/event-stream' } }, res => {
  res.setEncoding('utf8');
  res.on('data', chunk => process.stdout.write(chunk));
});
req.on('error', err => { console.error('SSE error:', err.message); process.exit(1); });
req.end();

