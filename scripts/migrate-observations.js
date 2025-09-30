#!/usr/bin/env node
// Merge per-observer *.ndjson into canonical observations.ndjson per project
const fs = require('fs');
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE || '.';
const DATA_DIR = path.join(HOME, '.local', 'share', 'devops-mcp');
const REGISTRY = path.join(DATA_DIR, 'project-registry.json');
const OBS_DIR = path.join(DATA_DIR, 'observations');
const ALT_OBS_DIR = path.join(HOME, 'Library', 'Application Support', 'devops.mcp', 'observations');

function code(id){ return id.replace(/[:/]/g,'__'); }
function readJSON(file){ return JSON.parse(fs.readFileSync(file,'utf-8')); }

function projectDirs(id){
  const c = code(id);
  return [path.join(OBS_DIR,c), path.join(ALT_OBS_DIR,c)].filter(d=>fs.existsSync(d));
}

function migrate(id){
  const dirs = projectDirs(id);
  const seen = new Set();
  let merged = [];
  for(const dir of dirs){
    try{
      for(const f of fs.readdirSync(dir)){
        if(!f.endsWith('.ndjson')) continue;
        const lines = fs.readFileSync(path.join(dir,f),'utf-8').split('\n').filter(Boolean);
        for(const ln of lines){
          try{ const obj = JSON.parse(ln); const key = obj.run_id? `${obj.observer}:${obj.run_id}` : `${obj.observer}:${obj.timestamp}:${obj.summary}`; if(!seen.has(key)){ seen.add(key); merged.push(obj);} }catch{}
        }
      }
    }catch{}
  }
  merged.sort((a,b)=> new Date(a.timestamp) - new Date(b.timestamp));
  const outDir = path.join(OBS_DIR, code(id));
  fs.mkdirSync(outDir,{recursive:true});
  const outFile = path.join(outDir,'observations.ndjson');
  const payload = merged.map(o=>JSON.stringify(o)).join('\n') + (merged.length?'\n':'');
  fs.writeFileSync(outFile, payload);
  if(merged.length) fs.writeFileSync(path.join(outDir,'latest.json'), JSON.stringify(merged[merged.length-1],null,2));
  return { id, migrated: merged.length, file: outFile };
}

function main(){
  const reg = readJSON(REGISTRY);
  const ids = process.argv[2] ? [process.argv[2]] : (reg.projects||[]).map(p=>p.id);
  const results = ids.map(migrate);
  console.log(JSON.stringify({ ok:true, results }, null, 2));
}

if(require.main===module) main();

