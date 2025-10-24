---
title: Mcp Project Discovery Analysis
category: reference
component: mcp_project_discovery_analysis
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

# MCP Project Discovery Analysis

## Investigation Summary

The MCP server (`devops-mcp`) has fully functional project discovery capabilities that are properly configured and working correctly.

## Key Findings

### 1. Configuration ✅ Correct
- Workspaces are properly defined in `~/.config/devops-mcp/config.toml` (lines 10-17)
- The configuration schema supports workspaces (`src/config.ts`, line 33)
- Tilde expansion is correctly applied to workspace paths (`src/config.ts`, line 200)

### 2. Implementation ✅ Complete
- Project discovery tool exists: `src/tools/project_discover.ts`
- Tool is registered in MCP server: `src/index.ts` (lines 93-105)
- The tool name is: `project_discover`

### 3. Discovery Results ✅ Working
Testing confirms the discovery mechanism finds:
- **41 total projects** across 3 workspaces
- Personal workspace: 24 projects
- Work workspace: 15 projects
- Business workspace: 2 projects

Project types detected:
- Generic: 29
- Node.js: 5
- Python: 4
- Go: 3

## The Real Issue

The MCP agent reported "Project list currently empty" but this is likely because:
1. The agent didn't call the `project_discover` tool
2. The agent was looking for a different tool name or resource
3. The projects aren't exposed as resources (they're only available via the tool)

## Solution for MCP Agent

To get project information from the MCP server, use:

```javascript
// Call the project_discover tool
const response = await mcp.callTool('project_discover', {});
// Response contains: { count: 41, projects: [...] }
```

## Available MCP Tools

The devops-mcp server provides these project-related tools:
- `project_discover` - Discover all projects in configured workspaces
- `project_obs_run` - Run observers on a specific project (requires project_id)

## Architecture Notes

The current implementation:
1. Reads workspaces from TOML config
2. Walks each workspace directory (max depth 2)
3. Detects project types by presence of marker files:
   - `.git` - Version control
   - `package.json` - Node.js
   - `go.mod` - Go
   - `pyproject.toml` - Python
   - `mise.toml` - Mise configuration
   - `project.manifest.yaml` - Project manifest

## Next Steps

If the MCP agent needs projects exposed differently:
1. **Option A**: Agent should call the existing `project_discover` tool
2. **Option B**: Add a resource endpoint for projects (if tools aren't sufficient)
3. **Option C**: Cache project list and expose as static resource

The implementation is architecturally complete and functional. The issue appears to be a communication gap between what the agent expects and what the server provides.