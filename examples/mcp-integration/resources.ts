// Example MCP resource implementations backed by local files
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const HOME = process.env.HOME || process.env.USERPROFILE || '.';
const DATA_DIR = join(HOME, '.local', 'share', 'devops-mcp');
const REGISTRY = join(DATA_DIR, 'project-registry.json');
const OBS_DIR = join(DATA_DIR, 'observations');

type ProjectManifest = any;
type ObserverOutput = any;

function loadRegistry(): { projects: any[] } {
  return JSON.parse(readFileSync(REGISTRY, 'utf-8'));
}

export async function resource_project_manifest(project_id: string): Promise<ProjectManifest> {
  const reg = loadRegistry();
  const p = reg.projects.find((x: any) => x.id === project_id);
  if (!p) throw new Error(`Project not found: ${project_id}`);
  return p.manifest;
}

export async function resource_project_status(project_id: string, limit = 100): Promise<{ latest?: ObserverOutput; history: ObserverOutput[]; }> {
  const dir = join(OBS_DIR, project_id.replace(/[:/]/g, '__'));
  const ndjsonPath = join(dir, 'observations.ndjson');
  try {
    const lines = readFileSync(ndjsonPath, 'utf-8').trim().split('\n').filter(Boolean);
    const history = lines.slice(-limit).map(l => JSON.parse(l));
    return { latest: history[history.length - 1], history };
  } catch {
    return { latest: undefined, history: [] };
  }
}

export async function resource_project_inventory(): Promise<{ total: number; projects: any[]; }> {
  const reg = loadRegistry();
  return { total: reg.projects.length, projects: reg.projects };
}

