#!/usr/bin/env node
// Create a Stage tracker issue via GitHub CLI (gh) or print body.
import process from 'node:process';

const STAGE = process.argv[2] || '1';
const NAME = process.argv[3] || 'Contract Freeze & CI Gates';

const title = `Stage ${STAGE} — ${NAME}`;
const body = `# ${title}\n\nEpic: <link to MVP Orchestration Epic>\nOwners: @AgentA @AgentB @AgentC @AgentD\n\n## Entrance Criteria (READY)\n- [x] Agent A Stage 0 complete (Bridge endpoints, aliases, SSE, tools, schemas, OpenAPI)\n- [x] DS validation script present (scripts/ds-validate.mjs)\n- [x] MCP alias endpoints planned and runbook present\n- [x] Orchestration scaffolds applied across repos\n\n## Agent A — Bridge/Contracts\n- [ ] Freeze contracts (OpenAPI + JSON Schemas) and annotate version (contracts/VERSION)\n- [ ] Ensure all example timestamps use epoch ms consistently\n- [ ] CI gates enforced on PRs:\n  - [ ] Ajv schema validation\n  - [ ] OpenAPI lint\n  - [ ] Endpoint validation (health, discovery, well-known, tools)\n\n## Agent B — DS CLI\n- [ ] \`/api/self-status\` includes \`schema_version: "ds.v1"\` and \`nowMs:number\`\n- [ ] \`/v1/health\` and \`/v1/capabilities\` available and versioned\n- [ ] Discovery present: \`/.well-known/obs-bridge.json\`, \`/api/discovery/services\`\n- [ ] Readme/docs note \`schema_version\` + envelope behavior\n\n## Agent C — Dashboard\n- [ ] Docs page links to discovery, openapi, registry\n- [ ] Contracts page: ETag-aware schema fetch + raw JSON toggle\n\n## Agent D — MCP\n- [ ] CI alias parity tests for \`/api/obs/*\`\n- [ ] Endpoint smoke: discovery services + openapi + self-status (\`schemaVersion\`, \`nowMs\`)\n\n## Validation Steps\n\n\`\`\`\n# DS validation\nDS_BASE_URL=http://127.0.0.1:7777 DS_TOKEN=<token> node scripts/ds-validate.mjs\n\n# MCP smoke\ncurl -sS http://127.0.0.1:4319/api/obs/discovery/services | jq '.ts|type'\ncurl -sS http://127.0.0.1:4319/api/obs/discovery/openapi | head -n 3\ncurl -sS http://127.0.0.1:4319/api/self-status | jq '.schemaVersion, .nowMs'\n\`\`\`\n\n## Acceptance\n- [ ] Contracts frozen and tagged\n- [ ] CI gates enforced across repos\n- [ ] DS and MCP validations pass\n`;

async function main(){
  const useGh = process.env.USE_GH !== '0';
  if (useGh) {
    const { spawnSync } = await import('node:child_process');
    const r = spawnSync('gh', ['issue', 'create', '-t', title, '-F', '-','-l','stage,tracking'], { input: body, encoding: 'utf-8' });
    if (r.status === 0) {
      process.stdout.write(r.stdout);
      return;
    }
  }
  console.log(body);
}

main().catch(e => { console.error(e); process.exit(1); });

