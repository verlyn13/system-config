---
title: 06 Mcp Usage
category: setup
component: 06_mcp_usage
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: [installation, setup]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: medium
---


# MCP Server Usage Guide - ACTUALLY Using It for System Management

## Purpose: Why We Have This

The DevOps MCP server is **the primary interface** for AI-assisted system management. It enforces policies, maintains audit trails, and ensures reproducible operations. **If you're not using it, you're managing your system the hard way.**

## Prerequisites

### 1. Verify MCP Server is Running

```bash
# Check if running via launchd
launchctl list | grep devops.mcp

# Or start manually
cd ~/Development/personal/devops-mcp
pnpm start
```

### 2. Enable in Claude Code

Add to your Claude Code configuration (`~/Library/Application Support/Codeium CLI/config.json`):

```json
{
  "mcpServers": {
    "devops": {
      "command": "node",
      "args": ["/Users/verlyn13/Development/personal/devops-mcp/dist/index.js"],
      "disabled": false
    }
  }
}
```

## ACTUAL Daily Usage Patterns

### 1. System Convergence (What You Should Do Daily)

**Instead of manually running brew/mise/chezmoi**, use MCP:

```javascript
// In Claude Code, ask:
"Converge my system to ensure everything is up to date"

// Claude will execute:
await mcp.callTool('system_converge', {
  profile: 'personal',
  confirm: true
});
```

This single command:
- Syncs with system-setup repo
- Validates policies
- Plans package changes
- Applies Homebrew updates
- Applies mise runtime updates
- Applies dotfile changes
- Tracks everything in audit log

### 2. Package Management

**Before installing anything manually**, use MCP to maintain consistency:

```javascript
// Check what would change
await mcp.callTool('pkg_sync_plan', {
  brewfile: `
tap "homebrew/cask"
brew "jq"
brew "httpie"
cask "visual-studio-code"
`
});

// Apply if happy
await mcp.callTool('pkg_sync_apply', {
  plan: planFromAbove,
  confirm: true
});
```

### 3. Dotfiles Management

**Stop editing dotfiles directly**. Use MCP:

```javascript
// Check dotfile state
const state = await mcp.readResource('devops://dotfiles_state');

// Apply any pending changes
await mcp.callTool('dotfiles_apply', {
  profile: 'personal',
  confirm: true
});
```

### 4. System Health Checks

**Regular health monitoring**:

```javascript
// Get comprehensive health report
const health = await mcp.callTool('mcp_health');

// Check telemetry status
const telemetry = await mcp.readResource('devops://telemetry_info');

// View package inventory
const packages = await mcp.readResource('devops://pkg_inventory');

// Check repo status
const repos = await mcp.readResource('devops://repo_status');
```

## System Management Workflows

### Morning Routine

```markdown
1. Start your day:
   "Check my system health and apply any pending updates"

2. Claude executes via MCP:
   - mcp_health check
   - system_converge if needed
   - Reports any issues

3. Review in dashboard:
   http://localhost:5173
```

### Before Starting a Project

```markdown
1. Tell Claude:
   "Prepare my system for working on [project-name]"

2. Claude will:
   - Check project requirements
   - Install missing dependencies via MCP
   - Ensure correct tool versions
   - Set up environment
```

### Weekly Maintenance

```markdown
1. "Perform weekly system maintenance"

2. MCP operations:
   - Full system convergence
   - Package updates
   - Dotfile sync
   - Audit log review
   - Policy compliance check
```

## Integration with Dashboard

The MCP server provides telemetry that feeds the system dashboard:

```bash
# Ensure dashboard bridge is enabled
cat ~/.config/devops-mcp/config.toml | grep dashboard_bridge

# Should show:
[dashboard_bridge]
enabled = true
port = 3001
token = "your-secret-token"
allowed_origins = ["http://localhost:5173"]
```

Dashboard endpoints:
- `http://localhost:3001/api/telemetry` - Telemetry info
- `http://localhost:3001/api/logs` - Recent logs
- `http://localhost:3001/api/audit` - Audit entries

## Common Operations via MCP

### Update Everything

```javascript
// Complete system update
await mcp.callTool('system_converge', {
  profile: 'personal',
  confirm: true
});
```

### Check What Would Change

```javascript
// Dry run - see plan without applying
await mcp.callTool('system_plan', {
  profile: 'personal'
});
```

### Validate Policy Compliance

```javascript
// Check if system meets policies
const policy = await mcp.readResource('devops://policy_manifest');
console.log(policy);
```

### Secret Management

```javascript
// Get secret reference (never the value)
const secretRef = await mcp.callTool('secrets_read_ref', {
  path: 'personal/github/token'
});
// Use secretRef in other operations
```

## Monitoring & Troubleshooting

### View Audit Trail

```bash
# Recent operations
sqlite3 ~/Library/Application\ Support/devops.mcp/audit.sqlite3 \
  "SELECT datetime(ts), tool, json_extract(result, '$.ok') as success
   FROM calls ORDER BY ts DESC LIMIT 10"
```

### Check Logs

```bash
# Live logs (pretty printed)
tail -f ~/Library/Application\ Support/devops.mcp/logs/server.ndjson | jq

# Errors only
tail -f ~/Library/Application\ Support/devops.mcp/server.err
```

### Telemetry Status

```javascript
// In Claude Code
const info = await mcp.readResource('devops://telemetry_info');
console.log(JSON.parse(info.contents[0].text));
```

## Best Practices

### DO ✅

1. **Use MCP for ALL system changes**
   - Package installation
   - Configuration updates
   - Tool version changes

2. **Let Claude drive MCP**
   - Describe what you want
   - Let Claude translate to MCP operations
   - Review audit trail

3. **Monitor via dashboard**
   - Keep dashboard open during operations
   - Watch real-time telemetry
   - Check for SLO violations

4. **Trust the convergence**
   - Run daily convergence
   - Don't manually tweak afterward
   - Report issues to fix root cause

### DON'T ❌

1. **Don't bypass MCP**
   - No manual `brew install`
   - No direct `chezmoi apply`
   - No manual config edits

2. **Don't ignore failures**
   - Check residuals
   - Review audit logs
   - Fix root causes

3. **Don't disable telemetry**
   - It's how you know what's happening
   - Required for dashboard
   - Essential for debugging

## Example Daily Conversation

```markdown
You: "Good morning, check my system and apply updates"

Claude: I'll check your system health and apply any pending updates.

[Executes mcp_health]
System is healthy. Compliance: 96.7%

[Executes system_converge]
Convergence complete:
- Homebrew: 2 packages updated (ripgrep, bat)
- Mise: No changes
- Dotfiles: 1 file updated (.gitconfig)
- Residuals: 0 (all clean)
- Audit ID: abc-123-def

Your system is now fully up to date. View details at http://localhost:5173

You: "Great, now prepare for working on the dashboard project"

Claude: I'll ensure your environment is ready for the dashboard project.

[Checks project requirements]
[Installs any missing dependencies via MCP]
[Verifies Node 24 is active]

Environment ready:
- Node 24.9.0 ✓
- Bun 1.2.22 ✓
- All dependencies installed ✓
- Dev server can be started with: bun run dev
```

## Advanced Usage

### Custom Profiles

Configure different profiles in `~/.config/devops-mcp/config.toml`:

```toml
[profiles]
"macpro.local" = "personal"
"work-laptop" = "work"
"ci-runner" = "ci"
```

Then converge with specific profile:

```javascript
await mcp.callTool('system_converge', {
  profile: 'work',
  confirm: true
});
```

### INERT Mode Testing

Test changes without applying:

```javascript
// Set environment variable first
process.env.DEVOPS_MCP_INERT = "1";

// Now operations are safe
await mcp.callTool('system_converge', {
  profile: 'personal',
  confirm: true
});
// Returns what WOULD happen, doesn't actually do it
```

### Repository-Driven Operations

Pin to specific commit:

```javascript
await mcp.callTool('system_converge', {
  profile: 'personal',
  ref: 'abc123def',  // Specific commit
  confirm: true
});
```

## Metrics to Watch

Key metrics that indicate healthy MCP usage:

1. **Daily convergence runs**: Should be ≥1
2. **Convergence success rate**: Should be >99%
3. **Residuals after apply**: Should be 0
4. **Audit entries per day**: Shows you're using MCP
5. **Telemetry drops**: Should be 0

Check these in the dashboard or via:

```bash
# Convergence count today
sqlite3 ~/Library/Application\ Support/devops.mcp/audit.sqlite3 \
  "SELECT COUNT(*) FROM calls
   WHERE tool='system_converge'
   AND date(ts)=date('now')"
```

## Summary: Just Use It!

The MCP server is running. The policies are defined. The telemetry is flowing. The dashboard is ready.

**Stop managing your system manually. Start every work session with:**

```
"Hey Claude, converge my system"
```

That's it. That's the whole point. Let the automation work for you.

## Related Documentation

- [MCP Server Configuration](../02-configuration/tools/mcp-server.md)
- [MCP Telemetry](../02-configuration/tools/mcp-telemetry.md)
- [Integration Guide](../03-automation/mcp-dashboard-integration.md)
- [Policy Framework](../04-policies/policy-as-code.yaml)