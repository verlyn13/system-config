// Typed helpers for system-dashboard to consume bridge discovery and validate payloads
import Ajv from 'ajv';

export async function loadSchemas(bridgeUrl) {
  const res = await fetch(`${bridgeUrl}/api/discovery/schemas`, { headers: { 'Accept': 'application/json' } });
  if (res.status === 304) return null;
  if (!res.ok) throw new Error(`Failed to load schemas: ${res.status}`);
  const { schemas, etag } = await res.json();
  return { schemas, etag };
}

export function buildValidators(schemas) {
  const ajv = new Ajv({ strict: true, allErrors: true });
  const byId = new Map(schemas.map(s => [s.$id, s]));
  const obs = byId.get('https://contracts.local/schemas/obs.line.v1.json');
  if (!obs) throw new Error('ObserverLine schema missing');
  const validateObs = ajv.compile(obs);
  const health = byId.get('https://contracts.local/schemas/obs.health.v1.json');
  const validateHealth = health ? ajv.compile(health) : null;
  const breach = byId.get('https://contracts.local/schemas/obs.slobreach.v1.json');
  const validateBreach = breach ? ajv.compile(breach) : null;
  return { ajv, validateObs, validateHealth, validateBreach };
}

export function validateObsEvent(validateObs, payload) {
  const ok = validateObs(payload);
  if (!ok) throw new Error(`ObserverLine validation failed: ${JSON.stringify(validateObs.errors)}`);
}

export function sseConnect(bridgeUrl, onEvent) {
  const es = new EventSource(`${bridgeUrl}/api/events/stream`);
  es.addEventListener('ProjectObsCompleted', (ev) => {
    try { const data = JSON.parse(ev.data); onEvent('ProjectObsCompleted', data); } catch {}
  });
  es.addEventListener('SLOBreach', (ev) => {
    try { const data = JSON.parse(ev.data); onEvent('SLOBreach', data); } catch {}
  });
  return es;
}

export async function typedFetchHealth(bridgeUrl, projectId, validateHealth) {
  const r = await fetch(`${bridgeUrl}/api/projects/${encodeURIComponent(projectId)}/health`);
  const data = await r.json();
  if (validateHealth) {
    const ok = validateHealth(data);
    if (!ok) throw new Error(`Health invalid: ${JSON.stringify(validateHealth.errors)}`);
  }
  return data;
}

export function validateObsList(validateObs, items) {
  if (!Array.isArray(items)) throw new Error('items must be array');
  for (const it of items) {
    const ok = validateObs(it);
    if (!ok) throw new Error(`ObserverLine invalid: ${JSON.stringify(validateObs.errors)}`);
  }
}
