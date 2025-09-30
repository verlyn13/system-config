#!/usr/bin/env node
import fs from 'node:fs';

function epicBody() {
  return `# MVP Orchestration Epic\n\nTrack the end-to-end MVP across repos using staged checklists. Agents:\n- Agent A = Bridge/Contracts (this repo)\n- Agent B = DS CLI repo\n- Agent C = Dashboard repo\n- Agent D = MCP server repo\n\n## Milestones\n\n- [ ] Stage 0 — Prep & Baseline\n- [ ] Stage 1 — Contract Freeze & CI Gates\n- [ ] Stage 2 — Typed Clients & Adapters\n- [ ] Stage 3 — SSE & Observers\n- [ ] Stage 4 — UX & Prefetch\n- [ ] Stage 5 — Demo & Rollout\n\n---\n\n## Stage 0 — Prep & Baseline\n\n### Agent A (Bridge/Contracts)\n- [x] Discovery endpoints complete: \`/api/discovery/services\`, \`/api/discovery/schemas\`, \`/api/schemas/{name}\`\n- [x] Project endpoints complete: \`/api/projects/{id}/{manifest,integration}\`\n- [x] Tools endpoints complete: \`POST /api/tools/{obs_validate,obs_migrate}\`\n- [x] SSE: \`/api/events/stream\` emitting events\n- [x] Aliases under \`/api/obs/*\` mirror primary routes\n- [ ] \`.well-known/obs-bridge.json\` published\n- [x] CI workflow \`validate-endpoints\` present and green on main\n- [x] Dev helpers exist: \`scripts/run-bridge-dev.sh\`, \`scripts/sse-listen.js\`, \`scripts/ds-validate.mjs\`\n\n### Agent B (DS CLI)\n- [ ] \`schema_version: "ds.v1"\` on core endpoints\n- [ ] \`/api/self-status\` includes \`nowMs:number\`\n- [ ] Discovery present: \`/.well-known/obs-bridge.json\`, \`/api/discovery/services\`\n- [ ] Go client \`pkg/dsclient\` + example & tests present\n\n### Agent C (Dashboard)\n- [ ] \`bridgeAdapter\` scaffolded (typed client fallback-safe)\n- [ ] \`dsAdapter\` scaffolded (optional in Stage 0)\n- [ ] Contracts viewer page exists\n- [ ] DS/MCP status cards scaffolded\n\n### Agent D (MCP)\n- [ ] \`/api/obs/*\` parity routes implemented\n- [ ] OpenAPI + schemas served\n- [ ] Self-status includes \`schemaVersion\`, \`contractVersion\`, \`nowMs\`\n\n### Acceptance\n- [ ] \`node scripts/validate-endpoints.js\` passes (optionally with \`PROJECT_ID\`)\n- [ ] \`DS_BASE_URL=... DS_TOKEN=... node scripts/ds-validate.mjs\` passes\n- [ ] Discovery shows \`ts:number\` and \`ds.self_status\` present\n`;
}

function stage0Body() {
  return `# Stage 0 — Prep & Baseline\n\nEpic: <link to MVP Orchestration Epic>\nOwners: @AgentA @AgentB @AgentC @AgentD\n\n## Agent A — Bridge/Contracts\n- [x] Discovery endpoints complete: \`/api/discovery/services\`, \`/api/discovery/schemas\`, \`/api/schemas/{name}\`\n- [x] Project endpoints complete: \`/api/projects/{id}/{manifest,integration}\`\n- [x] Tools endpoints complete: \`POST /api/tools/{obs_validate,obs_migrate}\`\n- [x] SSE: \`/api/events/stream\` emitting events\n- [x] Aliases under \`/api/obs/*\` mirror primary routes\n- [ ] \`.well-known/obs-bridge.json\` published\n- [x] CI workflow \`validate-endpoints\` present and green on main\n- [x] Dev helpers exist: \`scripts/run-bridge-dev.sh\`, \`scripts/sse-listen.js\`, \`scripts/ds-validate.mjs\`\n\n## Agent B — DS CLI\n- [ ] \`schema_version: "ds.v1"\` on core endpoints\n- [ ] \`/api/self-status\` includes \`nowMs:number\`\n- [ ] Discovery present: \`/.well-known/obs-bridge.json\`, \`/api/discovery/services\`\n- [ ] Go client \`pkg/dsclient\` + example & tests present\n\n## Agent C — Dashboard\n- [ ] \`bridgeAdapter\` scaffolded (typed client fallback-safe)\n- [ ] \`dsAdapter\` scaffolded (optional in Stage 0)\n- [ ] Contracts viewer page exists\n- [ ] DS/MCP status cards scaffolded\n\n## Agent D — MCP\n- [ ] \`/api/obs/*\` parity routes implemented\n- [ ] OpenAPI + schemas served\n- [ ] Self-status includes \`schemaVersion\`, \`contractVersion\`, \`nowMs\`\n\n## Validation Steps\n\n\`\nnode scripts/validate-endpoints.js\nDS_BASE_URL=http://127.0.0.1:7777 DS_TOKEN=... node scripts/ds-validate.mjs\nnode scripts/sse-listen.js\n\`\n`;
}

const args = new Map();
for (let i = 2; i < process.argv.length; i += 2) {
  if (process.argv[i] && process.argv[i+1]) args.set(process.argv[i], process.argv[i+1]);
}

const epicOut = args.get('--epic-out');
const stageOut = args.get('--stage0-out');

if (!epicOut || !stageOut) {
  console.error('Usage: emit-tracker-issue-bodies.mjs --epic-out <file> --stage0-out <file>');
  process.exit(2);
}

fs.writeFileSync(epicOut, epicBody(), 'utf8');
fs.writeFileSync(stageOut, stage0Body(), 'utf8');
console.log(`Wrote ${epicOut} and ${stageOut}`);

