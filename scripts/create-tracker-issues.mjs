#!/usr/bin/env node
// Create MVP Epic and Stage 0 issues via GitHub API if GH_REPO and GH_TOKEN are set.
// Fallback: print markdown bodies to stdout for manual creation.

import process from 'node:process';

const GH_REPO = process.env.GH_REPO; // e.g. owner/name
const GH_TOKEN = process.env.GH_TOKEN || process.env.GITHUB_TOKEN;

function epicBody() {
  return `# MVP Orchestration Epic\n\nTrack the end-to-end MVP across repos using staged checklists. Agents:\n- Agent A = Bridge/Contracts (this repo)\n- Agent B = DS CLI repo\n- Agent C = Dashboard repo\n- Agent D = MCP server repo\n\n## Milestones\n\n- [ ] Stage 0 — Prep & Baseline\n- [ ] Stage 1 — Contract Freeze & CI Gates\n- [ ] Stage 2 — Typed Clients & Adapters\n- [ ] Stage 3 — SSE & Observers\n- [ ] Stage 4 — UX & Prefetch\n- [ ] Stage 5 — Demo & Rollout\n\n---\n\n## Stage 0 — Prep & Baseline\n\n### Agent A (Bridge/Contracts)\n- [x] Discovery endpoints complete: \`/api/discovery/services\`, \`/api/discovery/schemas\`, \`/api/schemas/{name}\`\n- [x] Project endpoints complete: \`/api/projects/{id}/{manifest,integration}\`\n- [x] Tools endpoints complete: \`POST /api/tools/{obs_validate,obs_migrate}\`\n- [x] SSE: \`/api/events/stream\` emitting events\n- [x] Aliases under \`/api/obs/*\` mirror primary routes\n- [ ] \`.well-known/obs-bridge.json\` published\n- [x] CI workflow \`validate-endpoints\` present and green on main\n- [x] Dev helpers exist: \`scripts/run-bridge-dev.sh\`, \`scripts/sse-listen.js\`, \`scripts/ds-validate.mjs\`\n\n### Agent B (DS CLI)\n- [ ] \`schema_version: "ds.v1"\` on core endpoints\n- [ ] \`/api/self-status\` includes \`nowMs:number\`\n- [ ] Discovery present: \`/.well-known/obs-bridge.json\`, \`/api/discovery/services\`\n- [ ] Go client \`pkg/dsclient\` + example & tests present\n\n### Agent C (Dashboard)\n- [ ] \`bridgeAdapter\` scaffolded (typed client fallback-safe)\n- [ ] \`dsAdapter\` scaffolded (optional in Stage 0)\n- [ ] Contracts viewer page exists\n- [ ] DS/MCP status cards scaffolded\n\n### Agent D (MCP)\n- [ ] \`/api/obs/*\` parity routes implemented\n- [ ] OpenAPI + schemas served\n- [ ] Self-status includes \`schemaVersion\`, \`contractVersion\`, \`nowMs\`\n\n### Acceptance\n- [ ] \`node scripts/validate-endpoints.js\` passes (optionally with \`PROJECT_ID\`)\n- [ ] \`DS_BASE_URL=... DS_TOKEN=... node scripts/ds-validate.mjs\` passes\n- [ ] Discovery shows \`ts:number\` and \`ds.self_status\` present\n`;
}

function stage0Body() {
  return `# Stage 0 — Prep & Baseline\n\nEpic: <link to MVP Orchestration Epic>\nOwners: @AgentA @AgentB @AgentC @AgentD\n\n## Agent A — Bridge/Contracts\n- [x] Discovery endpoints complete: \`/api/discovery/services\`, \`/api/discovery/schemas\`, \`/api/schemas/{name}\`\n- [x] Project endpoints complete: \`/api/projects/{id}/{manifest,integration}\`\n- [x] Tools endpoints complete: \`POST /api/tools/{obs_validate,obs_migrate}\`\n- [x] SSE: \`/api/events/stream\` emitting events\n- [x] Aliases under \`/api/obs/*\` mirror primary routes\n- [ ] \`.well-known/obs-bridge.json\` published\n- [x] CI workflow \`validate-endpoints\` present and green on main\n- [x] Dev helpers exist: \`scripts/run-bridge-dev.sh\`, \`scripts/sse-listen.js\`, \`scripts/ds-validate.mjs\`\n\n## Agent B — DS CLI\n- [ ] \`schema_version: "ds.v1"\` on core endpoints\n- [ ] \`/api/self-status\` includes \`nowMs:number\`\n- [ ] Discovery present: \`/.well-known/obs-bridge.json\`, \`/api/discovery/services\`\n- [ ] Go client \`pkg/dsclient\` + example & tests present\n\n## Agent C — Dashboard\n- [ ] \`bridgeAdapter\` scaffolded (typed client fallback-safe)\n- [ ] \`dsAdapter\` scaffolded (optional in Stage 0)\n- [ ] Contracts viewer page exists\n- [ ] DS/MCP status cards scaffolded\n\n## Agent D — MCP\n- [ ] \`/api/obs/*\` parity routes implemented\n- [ ] OpenAPI + schemas served\n- [ ] Self-status includes \`schemaVersion\`, \`contractVersion\`, \`nowMs\`\n\n## Validation Steps\n\n\`\nnode scripts/validate-endpoints.js\nDS_BASE_URL=http://127.0.0.1:7777 DS_TOKEN=... node scripts/ds-validate.mjs\nnode scripts/sse-listen.js\n\`\n`;
}

async function createIssue(title, body, labels = []) {
  const res = await fetch(`https://api.github.com/repos/${GH_REPO}/issues`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${GH_TOKEN}`,
      'Accept': 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
    body: JSON.stringify({ title, body, labels })
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`GitHub API error ${res.status}: ${txt}`);
  }
  return res.json();
}

(async () => {
  if (!GH_REPO || !GH_TOKEN) {
    console.error('GH_REPO/GH_TOKEN not set. Printing issue bodies for manual creation.');
    console.log('\n--- Epic (title: MVP Orchestration Epic) ---\n');
    console.log(epicBody());
    console.log('\n--- Stage 0 (title: Stage 0 — Prep & Baseline) ---\n');
    console.log(stage0Body());
    process.exit(0);
  }
  try {
    const epic = await createIssue('MVP Orchestration Epic', epicBody(), ['epic','mvp']);
    const stage0 = await createIssue('Stage 0 — Prep & Baseline', stage0Body(), ['stage','tracking']);
    console.log('Created issues:');
    console.log(`Epic: ${epic.html_url}`);
    console.log(`Stage 0: ${stage0.html_url}`);
  } catch (err) {
    console.error('Failed to create issues:', err.message);
    process.exit(1);
  }
})();

