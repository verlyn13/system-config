#!/usr/bin/env node
// Validate key bridge endpoints against JSON Schemas
const fs = require('fs');
const path = require('path');
const Ajv2020 = require('ajv/dist/2020');
const addFormats = require('ajv-formats');

const BRIDGE = process.env.OBS_BRIDGE_URL || 'http://127.0.0.1:7171';
const TOKEN = process.env.BRIDGE_TOKEN || '';

function authHeaders(extra = {}){
  return TOKEN ? { ...extra, Authorization: `Bearer ${TOKEN}` } : extra;
}

async function getJson(p){
  const r = await fetch(BRIDGE + p, { headers: authHeaders() });
  const j = await r.json();
  return { ok: r.ok, status: r.status, json: j };
}

function loadSchema(name){
  const p = path.join(__dirname, '..', 'schema', name);
  return JSON.parse(fs.readFileSync(p, 'utf-8'));
}

async function main(){
  const ajv = new Ajv2020({ strict: false, allErrors: true });

  // Preload all local schemas so $ref by $id resolves (no MissingRef)
  try {
    const dir = path.join(__dirname, '..', 'schema');
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.json'));
    for (const f of files) {
      try {
        const raw = fs.readFileSync(path.join(dir, f), 'utf-8');
        const obj = JSON.parse(raw);
        // Prefer $id if present; fallback to filename-based id
        const id = obj.$id || `local://${f}`;
        ajv.addSchema(obj, id);
      } catch (e) {
        console.warn('[validate-endpoints] skipped schema', f, String(e.message || e));
      }
    }
  } catch (e) {
    console.warn('[validate-endpoints] failed to preload schemas', String(e.message || e));
  }
  addFormats(ajv); // Add format support

  const PID = process.env.PROJECT_ID;
  const manifestRes = PID ? await getJson(`/api/projects/${encodeURIComponent(PID)}/manifest`) : { ok: false };
  const integRes = PID ? await getJson(`/api/projects/${encodeURIComponent(PID)}/integration`) : { ok: false };
  const svcRes = await getJson('/api/discovery/services');

  const manifestSchema = loadSchema('obs.manifest.result.v1.json');
  const integrationSchema = loadSchema('obs.integration.v1.json');
  const svcSchema = loadSchema('service.discovery.v1.json');
  const validateSchema = loadSchema('obs.validate.result.v1.json');
  const migrateSchema = loadSchema('obs.migrate.result.v1.json');

  // Compile validators - prefer retrieving by $id if already added
  const validateManifest = (manifestSchema.$id && ajv.getSchema(manifestSchema.$id)) || ajv.compile(manifestSchema);
  const validateIntegration = (integrationSchema.$id && ajv.getSchema(integrationSchema.$id)) || ajv.compile(integrationSchema);
  const validateSvc = (svcSchema.$id && ajv.getSchema(svcSchema.$id)) || ajv.compile(svcSchema);
  const validateObsValidate = (validateSchema.$id && ajv.getSchema(validateSchema.$id)) || ajv.compile(validateSchema);
  const validateObsMigrate = (migrateSchema.$id && ajv.getSchema(migrateSchema.$id)) || ajv.compile(migrateSchema);

  let failed = false;
  if (svcRes.ok && !validateSvc(svcRes.json)) { console.error('Service discovery validation failed', validateSvc.errors); failed = true; }
  if (manifestRes.ok && !validateManifest(manifestRes.json)) { console.error('Manifest validation shape failed', validateManifest.errors); failed = true; }
  if (integRes.ok && !validateIntegration(integRes.json)) { console.error('Integration validation shape failed', validateIntegration.errors); failed = true; }

  // Tools parity
  try {
    const v = await fetch(BRIDGE + '/api/tools/obs_validate', { method: 'POST', headers: authHeaders() });
    if (!v.ok) { console.error('obs_validate request failed with', v.status); failed = true; }
    else {
      const vj = await v.json();
      if (!validateObsValidate(vj)) { console.error('Obs validate result schema failed', validateObsValidate.errors); failed = true; }
    }
  } catch (e) { console.warn('obs_validate request error', e.message); failed = true; }
  try {
    const midPath = PID ? '/api/tools/obs_migrate' : '/api/tools/obs_migrate';
    const body = PID ? { project_id: PID } : {};
    const m = await fetch(BRIDGE + midPath, { method: 'POST', headers: authHeaders({ 'Content-Type': 'application/json' }), body: JSON.stringify(body) });
    if (!m.ok) { console.error('obs_migrate request failed with', m.status); failed = true; }
    else {
      const mj = await m.json();
      if (!validateObsMigrate(mj)) { console.error('Obs migrate result schema failed', validateObsMigrate.errors); failed = true; }
    }
  } catch (e) { console.warn('obs_migrate request error', e.message); failed = true; }

  if (failed) process.exit(1);
  console.log('Endpoint validation complete');
}

main().catch(e => { console.error(e); process.exit(1); });
