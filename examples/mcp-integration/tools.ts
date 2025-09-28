// Example MCP tools (skeletons) using local orchestrators
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { join } from 'node:path';

const execFileAsync = promisify(execFile);

const ROOT = process.env.PROJECT_ROOT || process.cwd();
const SCRIPTS = join(ROOT, 'scripts');

export async function tool_project_discover(params: { roots?: string[]; strict?: boolean } = {}) {
  // Uses scripts/project-discover.sh; ignores params for now (allowlist guarded there)
  const { stdout } = await execFileAsync(join(SCRIPTS, 'project-discover.sh'));
  return JSON.parse(stdout);
}

export async function tool_project_obs_run(params: { project_id?: string; observers?: string; schedule?: 'hourly'|'daily'|'weekly' }) {
  if (params.schedule) {
    const { stdout } = await execFileAsync(join(SCRIPTS, 'obs-run.sh'), ['--schedule', params.schedule]);
    return { ok: true, mode: 'schedule', stdout };
  }
  if (!params.project_id) throw new Error('project_id required');
  const args = ['--project', params.project_id];
  if (params.observers) args.push('--observers', params.observers);
  const { stdout } = await execFileAsync(join(SCRIPTS, 'obs-run.sh'), args);
  return { ok: true, mode: 'project', stdout };
}

export async function tool_project_health(params: { project_id: string }) {
  const { stdout } = await execFileAsync('node', [join(ROOT, 'scripts', 'http-bridge.js')], { timeout: 1000 }).catch(() => ({ stdout: '' } as any));
  // Placeholder: in a live server, fetch and compute; here just confirm wiring
  return { project_id: params.project_id, status: 'unknown', note: 'Compute via resources.project_status history rollup' };
}

