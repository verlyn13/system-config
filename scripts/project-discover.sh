#!/bin/bash
# Simple project discovery that writes to shared MCP/Bridge location
set -euo pipefail

# Shared registry location
readonly REGISTRY_FILE="$HOME/.local/share/devops-mcp/project-registry.json"
mkdir -p "$(dirname "$REGISTRY_FILE")"

# Use the existing test script logic that we know works
cat > /tmp/discover.js << 'EOF'
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOTS = [
  path.join(process.env.HOME, 'Development/personal'),
  path.join(process.env.HOME, 'Development/work'),
  path.join(process.env.HOME, 'Development/business'),
  path.join(process.env.HOME, 'Development/business-org')
];

function generateId(p) {
  return crypto.createHash('sha1').update(p).digest('hex').slice(0, 12);
}

function detectProject(dir) {
  const detectors = [];
  let kind = 'generic';

  try {
    if (fs.existsSync(path.join(dir, '.git'))) detectors.push('git');
    if (fs.existsSync(path.join(dir, 'package.json'))) {
      detectors.push('node');
      kind = 'node';
    }
    if (fs.existsSync(path.join(dir, 'go.mod'))) {
      detectors.push('go');
      kind = detectors.includes('node') ? 'mix' : 'go';
    }
    if (fs.existsSync(path.join(dir, 'pyproject.toml')) ||
        fs.existsSync(path.join(dir, 'requirements.txt'))) {
      detectors.push('python');
      kind = kind === 'generic' ? 'python' : 'mix';
    }
    if (fs.existsSync(path.join(dir, 'Cargo.toml'))) {
      detectors.push('rust');
      kind = kind === 'generic' ? 'rust' : 'mix';
    }
    if (fs.existsSync(path.join(dir, 'mise.toml')) ||
        fs.existsSync(path.join(dir, '.mise.toml'))) {
      detectors.push('mise');
    }
    if (fs.existsSync(path.join(dir, 'project.manifest.yaml'))) {
      detectors.push('manifest');
    }
  } catch {
    return null;
  }

  if (detectors.length === 0) return null;

  return {
    id: generateId(dir),
    name: path.basename(dir),
    path: dir,
    workspace: path.basename(path.dirname(dir)),
    kind,
    detectors
  };
}

function discoverProjects() {
  const projects = [];

  for (const root of ROOTS) {
    if (!fs.existsSync(root)) continue;

    try {
      const dirs = fs.readdirSync(root, { withFileTypes: true });

      for (const dir of dirs) {
        if (!dir.isDirectory()) continue;
        if (dir.name.startsWith('.')) continue;
        if (['node_modules', 'vendor', 'dist', 'build'].includes(dir.name)) continue;

        const fullPath = path.join(root, dir.name);
        const project = detectProject(fullPath);

        if (project) {
          projects.push(project);
        }
      }
    } catch (e) {
      console.error(`Error scanning ${root}:`, e.message);
    }
  }

  return projects;
}

// Main
const projects = discoverProjects();

// Calculate stats
const byKind = {};
const byWorkspace = {};

for (const p of projects) {
  byKind[p.kind] = (byKind[p.kind] || 0) + 1;
  byWorkspace[p.workspace] = (byWorkspace[p.workspace] || 0) + 1;
}

const registry = {
  version: '2.0.0',
  generated: new Date().toISOString(),
  discovered: projects.length,
  projects: projects,
  stats: {
    total: projects.length,
    byKind: Object.entries(byKind).map(([kind, count]) => ({ kind, count })),
    byWorkspace: Object.entries(byWorkspace).map(([workspace, count]) => ({ workspace, count }))
  }
};

// Output for the shell script
console.log(JSON.stringify(registry, null, 2));
EOF

# Run the Node.js script
echo "🔍 Running project discovery..." >&2
RESULT=$(node /tmp/discover.js)

# Save to registry
echo "$RESULT" > "$REGISTRY_FILE"

# Extract summary
DISCOVERED=$(echo "$RESULT" | jq '.discovered')
echo "✅ Discovery complete: $DISCOVERED projects found" >&2
echo "   Registry: $REGISTRY_FILE" >&2

# Output summary JSON for HTTP bridge (to stdout for consumption)
echo "$RESULT" | jq '{discovered: .discovered, registry_path: "'$REGISTRY_FILE'", stats: .stats}'

# Clean up
rm -f /tmp/discover.js