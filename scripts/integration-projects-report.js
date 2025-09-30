#!/usr/bin/env node
// Produce a consolidated integration report per project by querying the bridge
const http = require('http');

const BRIDGE = process.env.OBS_BRIDGE_URL || 'http://127.0.0.1:7171';

function getJSON(path){
  return new Promise((resolve,reject)=>{
    http.get(BRIDGE + path, (res)=>{
      let data=''; res.on('data',d=>data+=d); res.on('end',()=>{ try{ resolve(JSON.parse(data)); }catch(e){ reject(e);} });
    }).on('error',reject);
  });
}

(async () => {
  try {
    const projects = await getJSON('/api/projects');
    const items = projects.projects || [];
    const reports = [];
    for (const p of items) {
      const integ = await getJSON('/api/projects/' + encodeURIComponent(p.id) + '/integration');
      reports.push({ id: p.id, name: p.name, overall: integ.health.overall, observers: Object.keys(integ.observers), ds: integ.services.ds.reachable, mcp: integ.services.mcp.reachable });
    }
    console.log(JSON.stringify({ total: items.length, reports }, null, 2));
  } catch (e) {
    console.error('Integration report failed', e.message);
    process.exit(1);
  }
})();

