# System Setup Update - Project Context

## Project Overview
This repository contains configuration documentation and templates for setting up a reproducible macOS development environment. It includes observability platform integration, MCP servers, and dashboard bridges.

## Project Structure
```
system-setup-update/
├── scripts/            # Utility scripts for discovery, validation, and integration
├── observers/          # Observation scripts for monitoring various aspects
├── contracts/          # API contracts and specifications
├── docs/              # Documentation and guides
├── schema/            # JSON schemas for validation
├── examples/          # Example configurations
└── .github/           # GitHub workflows and templates
```

## Key Services and Ports
- MCP Server: Port 4319 (already running)
- Dashboard Bridge: Port 3210 (when active)
- SSE endpoints for real-time updates

## Important Files
- CLAUDE.md: AI assistant context (similar to this file)
- INDEX.md: Main documentation index
- manifest.json: Project manifest with integration details
- .env.example: Environment variable template

## Current Stage
The project is in Stage 1 (complete) of the observability platform implementation:
- ✅ MCP server configured and running
- ✅ Dashboard bridge implemented
- ✅ Discovery scripts functional
- ✅ Validation tools in place

## Available Scripts
Key scripts in the scripts/ directory:
- project-discover.sh: Discovers projects in workspace
- workspace-discover.sh: Workspace-wide discovery
- validate-manifest.mjs: Validates project manifests
- integration-smoke.sh: Tests integration health
- http-bridge.js: HTTP bridge server
- obs-run.sh: Runs observers

## Dependencies
All required tools are installed:
- yq: YAML processor (installed via Homebrew)
- jq: JSON processor (installed via Homebrew)
- Node.js: For JavaScript scripts (managed via mise)
- ripgrep: For searching (installed as rg)

## Environment Variables
Check .env.example for required variables. Key ones:
- WORKSPACE_ROOT: Base workspace directory
- OBS_BRIDGE_PORT: Bridge server port (default: 3210)
- MCP_SERVER_PORT: MCP server port (default: 4319)

## Testing and Validation
To verify functionality:
```bash
# Check MCP server
curl -s http://localhost:4319/health

# Run discovery
./scripts/project-discover.sh

# Validate manifest
node scripts/validate-manifest.mjs

# Test integration
./scripts/integration-smoke.sh
```

## Common Tasks
1. **Running observers**: `./scripts/obs-run.sh <observer-name>`
2. **Starting dashboard bridge**: `node scripts/http-bridge.js`
3. **Checking system health**: `./scripts/system-health.sh`
4. **Validating contracts**: Check contracts/ directory

## Notes for AI Agents
- The system is already configured - focus on verification and enhancement
- Use existing scripts rather than recreating functionality
- Check port availability before starting services
- Respect existing configuration patterns
- The MCP server authentication token is in the environment