# How to Freeze Contracts - Stage 1 Guide

**Purpose**: Step-by-step instructions for freezing contracts and schemas in Stage 1

## Overview

Stage 1 involves freezing all API contracts and schemas to ensure stability and backward compatibility. This guide covers the technical steps to implement the freeze.

## 1. Tag the Contract Version

### Create Version Tag
```bash
# Ensure you're on main with latest changes
git checkout main
git pull origin main

# Create annotated tag for contract version
git tag -a "contracts-v1.1.0" -m "Contract Freeze: v1.1.0

Stage 1 Contract Freeze
- All Stage 0 endpoints locked
- OpenAPI spec frozen
- JSON schemas frozen
- Breaking changes now require version bump"

# Push tag to remote
git push origin contracts-v1.1.0
```

### Update VERSION File
```bash
# Ensure contracts/VERSION reflects v1.1.0
cat contracts/VERSION
# Should output: v1.1.0
```

## 2. Create Contract Changelog

### Create CHANGELOG.md
```markdown
# Contract Changelog

## v1.1.0 - 2025-09-29 [FROZEN]

### Stage 0 Endpoints (Locked)

#### Discovery
- GET `/api/discovery/services` - Service discovery with ds.self_status
- GET `/api/discovery/schemas` - Schema listing with fallback
- GET `/api/schemas/{name}` - Individual schema retrieval

#### Projects
- GET `/api/projects` - Project listing
- GET `/api/projects/{id}/manifest` - Manifest with validation
- GET `/api/projects/{id}/integration` - Integration with services.ds.self_status
- GET `/api/projects/{id}/status` - Project status
- GET `/api/projects/{id}/health` - Project health

#### Tools
- POST `/api/tools/obs_validate` - Validation tool
- POST `/api/tools/obs_migrate` - Migration tool

#### SSE
- GET `/api/events/stream` - Server-sent events

#### Well-known
- GET `/.well-known/obs-bridge.json` - Public discovery
- GET `/api/obs/well-known` - Alias (public)

### Schemas (Locked)
- obs.integration.v1.json
- obs.manifest.result.v1.json
- obs.line.v1.json
- obs.health.v1.json
- service.discovery.v1.json
- obs.validate.result.v1.json
- obs.migrate.result.v1.json

### Contract Rules
- No breaking changes to locked endpoints
- New endpoints allowed (additive only)
- Optional fields can be added to responses
- Required fields cannot be added to requests
```

Save as `contracts/CHANGELOG.md`

## 3. OpenAPI Validation & Linting

### Install OpenAPI Tools
```bash
npm install -g @redocly/cli
# or
npm install --save-dev @redocly/cli
```

### Create Lint Configuration
Create `.redocly.yaml`:
```yaml
extends:
  - recommended

rules:
  operation-operationId: error
  operation-summary: error
  operation-description: warn
  tag-description: warn
  info-contact: warn
  info-license: warn

features.openapi:
  jsonSchemasPath: ./schema
```

### Run OpenAPI Linting
```bash
# Lint the OpenAPI spec
npx redocly lint openapi.yaml

# Validate structure
npx redocly bundle openapi.yaml -o dist/openapi-bundled.yaml

# Generate documentation
npx redocly build-docs openapi.yaml -o dist/api-docs.html
```

## 4. Schema Validation Setup

### Add Schema CI Check
Create `.github/workflows/contract-validation.yml`:
```yaml
name: Contract Validation
on:
  pull_request:
    paths:
      - 'openapi.yaml'
      - 'schema/*.json'
      - 'contracts/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install dependencies
        run: |
          npm install ajv ajv-formats
          npm install -g @redocly/cli

      - name: Lint OpenAPI
        run: npx redocly lint openapi.yaml

      - name: Validate schemas compile
        run: node scripts/validate-schemas.js

      - name: Check contract version
        run: |
          VERSION=$(cat contracts/VERSION)
          echo "Contract version: $VERSION"
          if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Invalid version format"
            exit 1
          fi
```

### Create Schema Validator
Create `scripts/validate-schemas.js`:
```javascript
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const Ajv2020 = require('ajv/dist/2020');
const addFormats = require('ajv-formats');

const ajv = new Ajv2020({ strict: false });
addFormats(ajv);

const schemaDir = path.join(__dirname, '..', 'schema');
const files = fs.readdirSync(schemaDir).filter(f => f.endsWith('.json'));

let failed = false;
for (const file of files) {
  try {
    const schema = JSON.parse(fs.readFileSync(path.join(schemaDir, file), 'utf8'));
    ajv.compile(schema);
    console.log(`✅ ${file} - valid`);
  } catch (e) {
    console.error(`❌ ${file} - ${e.message}`);
    failed = true;
  }
}

if (failed) process.exit(1);
console.log('\n✅ All schemas valid');
```

## 5. Enforce Backward Compatibility

### Add Breaking Change Detection
Create `scripts/detect-breaking-changes.js`:
```javascript
#!/usr/bin/env node
// Compare OpenAPI specs for breaking changes
const { diff } = require('openapi-diff');

async function checkBreaking() {
  const result = await diff({
    sourceSpec: 'https://raw.githubusercontent.com/[org]/[repo]/main/openapi.yaml',
    destinationSpec: './openapi.yaml'
  });

  if (result.breakingDifferences.length > 0) {
    console.error('❌ Breaking changes detected:');
    console.error(result.breakingDifferences);
    process.exit(1);
  }

  console.log('✅ No breaking changes detected');
}

checkBreaking().catch(console.error);
```

## 6. Document Frozen Contracts

### Update README
Add to main README.md:
```markdown
## Contract Status: FROZEN (v1.1.0)

As of Stage 1, all API contracts and schemas are frozen.
- Breaking changes require a major version bump
- See [contracts/CHANGELOG.md](contracts/CHANGELOG.md) for details
- Run `npm run validate:contracts` to check compliance
```

### Add NPM Scripts
Update package.json:
```json
{
  "scripts": {
    "validate:contracts": "npm run lint:openapi && npm run validate:schemas",
    "lint:openapi": "redocly lint openapi.yaml",
    "validate:schemas": "node scripts/validate-schemas.js",
    "check:breaking": "node scripts/detect-breaking-changes.js"
  }
}
```

## 7. Communicate the Freeze

### Create Announcement
Post in all agent repos:
```markdown
## 📋 Contract Freeze Notice - v1.1.0

All API contracts and schemas are now FROZEN as of Stage 1.

**What this means:**
- No breaking changes to existing endpoints
- New endpoints can be added (additive only)
- Optional response fields can be added
- Required request fields cannot be added

**Validation:**
- CI will enforce contract compliance
- Run `npm run validate:contracts` locally
- See [Contract Freeze Guide](link) for details

**Version:** v1.1.0
**Tag:** contracts-v1.1.0
```

## Quick Checklist

- [ ] Tag version as `contracts-v1.1.0`
- [ ] Create contracts/CHANGELOG.md
- [ ] Setup OpenAPI linting (.redocly.yaml)
- [ ] Add contract validation CI workflow
- [ ] Create schema validation script
- [ ] Update documentation
- [ ] Communicate freeze to all agents

## Rollback Procedure

If a breaking change is absolutely necessary:
1. Create new major version (v2.0.0)
2. Document migration path
3. Support both versions temporarily
4. Deprecate v1 with timeline
5. Coordinate migration across all agents

---
**Stage 1 Contract Freeze - Ensuring API Stability**