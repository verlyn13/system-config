---
title: Mcp Examples
category: reference
component: mcp_examples
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# MCP Server Practical Examples

## Real-World Usage Scenarios

### Scenario 1: Monday Morning System Update

**What you say to Claude:**
```
"It's Monday morning, update my entire system and tell me what changed"
```

**What Claude executes via MCP:**
```javascript
// 1. Check system health
const health = await mcp.callTool('mcp_health');
console.log(`System health: ${health.status}`);

// 2. Run full convergence
const result = await mcp.callTool('system_converge', {
  profile: 'personal',
  confirm: true
});

// 3. Report changes
console.log(`Changes applied:
- Homebrew: ${result.steps.pkg_apply.brew_changes} packages
- Mise: ${result.steps.pkg_apply.mise_changes} runtimes
- Dotfiles: ${result.steps.dotfiles_apply.files_changed} files
- Residuals: ${result.residual_count} (should be 0)
- Audit ID: ${result.audit_id}
`);
```

### Scenario 2: Starting a New Project

**What you say:**
```
"I'm starting a new TypeScript project called 'awesome-api', set up my environment"
```

**What Claude executes:**
```javascript
// 1. Check TypeScript tools
const inventory = await mcp.readResource('devops://pkg_inventory');
const hasTypeScript = inventory.mise.includes('node');

// 2. If missing, plan installation
if (!hasTypeScript) {
  const plan = await mcp.callTool('pkg_sync_plan', {
    misefile: `
[tools]
node = "24"
bun = "latest"
`
  });

  // 3. Apply the plan
  await mcp.callTool('pkg_sync_apply', {
    plan: plan,
    confirm: true
  });
}

// 4. Verify environment
const newInventory = await mcp.readResource('devops://pkg_inventory');
console.log("TypeScript environment ready with:", newInventory.mise);
```

### Scenario 3: Investigating System Issues

**What you say:**
```
"Something seems wrong, diagnose my system"
```

**What Claude executes:**
```javascript
// 1. Get comprehensive health check
const health = await mcp.callTool('mcp_health');

// 2. Check telemetry status
const telemetry = await mcp.readResource('devops://telemetry_info');

// 3. Review recent operations
const auditQuery = `
  SELECT datetime(ts) as time, tool, json_extract(result, '$.ok') as success
  FROM calls
  WHERE ts > datetime('now', '-1 hour')
  ORDER BY ts DESC LIMIT 10
`;
// Claude reads audit log...

// 4. Check for residuals
const lastConverge = await mcp.callTool('system_plan', {
  profile: 'personal'
});

// 5. Report findings
console.log(`Diagnosis:
- Health Status: ${health.status}
- Telemetry: ${telemetry.reachable ? 'Connected' : 'Disconnected'}
- Recent Failures: ${failureCount}
- Pending Changes: ${lastConverge.total_operations}
- Residuals: ${lastConverge.residuals || 'None'}
`);
```

### Scenario 4: Installing Multiple Tools

**What you say:**
```
"I need httpie, jq, and the GitHub CLI installed"
```

**What Claude executes:**
```javascript
// 1. Create Brewfile with requested tools
const brewfile = `
brew "httpie"
brew "jq"
brew "gh"
`;

// 2. Plan the installation
const plan = await mcp.callTool('pkg_sync_plan', {
  brewfile: brewfile
});

// 3. Show what will be installed
console.log(`Will install:
${plan.brew.installs.map(pkg => `  - ${pkg}`).join('\n')}
`);

// 4. Apply with confirmation
const result = await mcp.callTool('pkg_sync_apply', {
  plan: plan,
  confirm: true
});

// 5. Verify installation
if (result.ok && result.residual.brew.installs.length === 0) {
  console.log("✅ All tools installed successfully");
} else {
  console.log("⚠️ Some tools failed to install:", result.residual.brew.installs);
}
```

### Scenario 5: Preparing for a Presentation

**What you say:**
```
"I'm giving a presentation in 30 minutes, make sure my system is stable"
```

**What Claude executes:**
```javascript
// 1. Quick health check (no changes)
const health = await mcp.callTool('mcp_health');

// 2. Check for pending updates WITHOUT applying
const plan = await mcp.callTool('system_plan', {
  profile: 'personal'
});

// 3. Ensure no critical issues
const telemetry = await mcp.readResource('devops://telemetry_info');

// 4. Report status
console.log(`Pre-presentation check:
- System Health: ${health.status}
- Pending Updates: ${plan.total_operations} (will apply after presentation)
- Critical Issues: None
- Telemetry: ${telemetry.reachable ? 'OK' : 'Warning: Telemetry offline'}

Your system is stable for the presentation.
${plan.total_operations > 0 ? 'Run system convergence after your presentation to apply updates.' : ''}
`);
```

### Scenario 6: Weekly Maintenance

**What you say:**
```
"It's Friday afternoon, do my weekly maintenance"
```

**What Claude executes:**
```javascript
// 1. Full system convergence
const converge = await mcp.callTool('system_converge', {
  profile: 'personal',
  confirm: true
});

// 2. Check audit log size
// Claude checks ~/Library/Application Support/devops.mcp/audit.sqlite3

// 3. Review telemetry health
const telemetry = await mcp.readResource('devops://telemetry_info');

// 4. Check policy compliance
const policy = await mcp.readResource('devops://policy_manifest');

// 5. Generate summary
console.log(`Weekly Maintenance Complete:
- Packages Updated: ${converge.steps.pkg_apply.summary}
- Dotfiles Synced: ${converge.steps.dotfiles_apply.ok ? '✓' : '✗'}
- Audit Log Size: ${auditSize}MB
- Telemetry Status: ${telemetry.health}
- Policy Compliance: ${policy.compliance_score}%
- Next Maintenance: ${nextFriday}

All systems operating normally.
`);
```

### Scenario 7: Debugging Failed Convergence

**What you say:**
```
"The last convergence failed, help me fix it"
```

**What Claude executes:**
```javascript
// 1. Get last convergence audit ID
const lastAudit = // Query audit log for last system_converge

// 2. Check what failed
const logs = // Read logs at timestamp

// 3. Check residuals
const plan = await mcp.callTool('system_plan', {
  profile: 'personal'
});

// 4. Try targeted fix
if (plan.brew.installs.length > 0) {
  console.log("Attempting to fix Homebrew issues...");
  // Run brew doctor, cleanup, etc.
}

// 5. Retry convergence
const retry = await mcp.callTool('system_converge', {
  profile: 'personal',
  confirm: true
});

console.log(`Fix attempt:
- Original Issue: ${originalError}
- Fix Applied: ${fixDescription}
- Retry Result: ${retry.ok ? 'SUCCESS' : 'FAILED'}
${retry.ok ? '' : 'Manual intervention may be required.'}
`);
```

### Scenario 8: Secret Management

**What you say:**
```
"I need to use my GitHub token in a script"
```

**What Claude executes:**
```javascript
// 1. Get secret reference (never the actual value!)
const secretRef = await mcp.callTool('secrets_read_ref', {
  path: 'personal/github/token'
});

// 2. Use in a secure way
console.log(`Secret reference obtained: ${secretRef.ref}

To use in your script:
\`\`\`bash
#!/bin/bash
# The MCP server will inject the secret as an environment variable
# Never hardcode the actual token!

export GITHUB_TOKEN="${secretRef.ref}"
# Your script commands here
gh api user
\`\`\`

The secret will be injected at runtime, never exposed in logs or audit.
`);
```

### Scenario 9: Compliance Check

**What you say:**
```
"Are we compliant with all policies?"
```

**What Claude executes:**
```javascript
// 1. Get policy manifest
const policy = await mcp.readResource('devops://policy_manifest');

// 2. Run system plan to check state
const plan = await mcp.callTool('system_plan', {
  profile: 'personal'
});

// 3. Check telemetry SLOs
const telemetry = await mcp.readResource('devops://telemetry_info');

// 4. Generate compliance report
console.log(`Compliance Report:
- Policy Version: ${policy.version}
- Overall Score: ${policy.compliance_score}%
- Violations: ${policy.violations.length}

Details:
${policy.violations.map(v => `  ⚠️ ${v.rule}: ${v.message}`).join('\n')}

Recommendations:
${plan.total_operations > 0 ? '- Run system convergence to fix violations' : '- System is fully compliant'}
`);
```

### Scenario 10: Emergency Rollback

**What you say:**
```
"Something broke after the last update, rollback to yesterday"
```

**What Claude executes:**
```javascript
// 1. Find yesterday's good commit
// Query git log in system-setup repo

// 2. Converge to that specific commit
const rollback = await mcp.callTool('system_converge', {
  profile: 'personal',
  ref: 'abc123def', // Yesterday's commit
  confirm: true
});

// 3. Verify rollback
const health = await mcp.callTool('mcp_health');

console.log(`Rollback Complete:
- Rolled back to: ${commitDate} (${commitHash})
- System Health: ${health.status}
- Changes Reverted: ${rollback.summary}

System restored to yesterday's configuration.
To investigate the issue, check audit log for the failed convergence.
`);
```

## Command Patterns

### Information Gathering (Safe)
```javascript
// Always safe to run - no system changes
await mcp.callTool('mcp_health');
await mcp.readResource('devops://telemetry_info');
await mcp.readResource('devops://pkg_inventory');
await mcp.readResource('devops://repo_status');
await mcp.readResource('devops://policy_manifest');
```

### Planning (Safe)
```javascript
// Shows what WOULD happen - no changes
await mcp.callTool('system_plan', { profile: 'personal' });
await mcp.callTool('pkg_sync_plan', { brewfile: '...' });
```

### Execution (Requires Confirm)
```javascript
// Actually changes the system - needs confirm:true
await mcp.callTool('system_converge', { profile: 'personal', confirm: true });
await mcp.callTool('pkg_sync_apply', { plan: planObj, confirm: true });
await mcp.callTool('dotfiles_apply', { profile: 'personal', confirm: true });
```

## Integration Tips

### With Dashboard
- Keep dashboard open at http://localhost:5173
- Watch real-time telemetry during operations
- Use trace IDs to correlate operations

### With CI/CD
- Use INERT mode for validation
- Pin to specific commits for reproducibility
- Check audit logs for compliance

### With Daily Workflow
- Start each day with convergence
- Check health before important work
- Review audit logs weekly

## Related Documentation

- [MCP Usage Guide](../01-setup/06-mcp-usage.md)
- [MCP Server Configuration](../02-configuration/tools/mcp-server.md)
- [Integration Guide](../03-automation/mcp-dashboard-integration.md)