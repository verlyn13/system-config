#!/usr/bin/env node

// Test script to verify project discovery in MCP server
// This directly tests the project discovery logic

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Test configuration
const testConfig = {
  workspaces: [
    "~/Development/personal",
    "~/Development/work",
    "~/Development/business"
  ]
};

// Expand tilde to home directory
function expandTilde(filepath) {
  if (filepath.startsWith('~/')) {
    return path.join(process.env.HOME, filepath.slice(2));
  }
  return filepath;
}

// Detect project type
function detectProject(root) {
  const detectors = [];
  let kind = 'generic';
  const f = (rel) => path.join(root, rel);
  const exists = (rel) => {
    try {
      return fs.existsSync(f(rel));
    } catch {
      return false;
    }
  };

  if (exists('.git')) detectors.push('git');
  if (exists('package.json')) {
    detectors.push('node');
    kind = 'node';
  }
  if (exists('go.mod')) {
    detectors.push('go');
    kind = detectors.includes('node') ? 'mix' : 'go';
  }
  if (exists('pyproject.toml') || exists('requirements.txt')) {
    detectors.push('python');
    kind = (kind === 'generic' ? 'python' : 'mix');
  }
  if (exists('mise.toml') || exists('.mise.toml')) detectors.push('mise');
  if (exists('project.manifest.yaml')) detectors.push('manifest');

  if (detectors.length === 0) return null;

  const name = path.basename(root);
  return { name, root, kind, detectors };
}

// Walk directory tree
function* walk(dir, maxDepth, depth = 0) {
  if (depth > maxDepth) return;

  let entries = [];
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;

    // Skip hidden directories except .git
    if (entry.name.startsWith('.') && entry.name !== '.git') continue;

    // Skip common non-project directories
    if (['node_modules', 'vendor', 'dist', 'build', 'target', '.cache'].includes(entry.name)) {
      continue;
    }

    const childPath = path.join(dir, entry.name);

    // Check if this directory is a project
    const project = detectProject(childPath);
    if (project) {
      yield project;
      // Don't recurse into projects (they might have sub-projects but usually not)
      continue;
    }

    // Recurse into non-project directories
    yield* walk(childPath, maxDepth, depth + 1);
  }
}

// Main discovery function
function discoverProjects() {
  console.log('🔍 Starting project discovery...\n');
  console.log('Workspaces:', testConfig.workspaces, '\n');

  const allProjects = [];

  for (const workspace of testConfig.workspaces) {
    const expanded = expandTilde(workspace);

    if (!fs.existsSync(expanded)) {
      console.log(`⚠️  Workspace does not exist: ${workspace}`);
      continue;
    }

    console.log(`\n📁 Scanning workspace: ${workspace}`);
    console.log(`   Path: ${expanded}`);

    const projects = [];

    // First check if the workspace root itself is a project
    const rootProject = detectProject(expanded);
    if (rootProject) {
      projects.push(rootProject);
    }

    // Then walk subdirectories
    for (const project of walk(expanded, 2)) {
      projects.push(project);
    }

    console.log(`   Found ${projects.length} projects:`);
    for (const p of projects) {
      console.log(`   ✓ ${p.name} (${p.kind}) - ${p.detectors.join(', ')}`);
      allProjects.push(p);
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log(`📊 Summary: ${allProjects.length} total projects discovered`);
  console.log('='.repeat(60));

  // Group by kind
  const byKind = {};
  for (const p of allProjects) {
    byKind[p.kind] = (byKind[p.kind] || 0) + 1;
  }

  console.log('\nProjects by type:');
  for (const [kind, count] of Object.entries(byKind)) {
    console.log(`  ${kind}: ${count}`);
  }

  return allProjects;
}

// Run discovery
discoverProjects();