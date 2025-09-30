# Orchestration Scaffold

Copy this scaffold into other repos (DS CLI, Dashboard, MCP) to standardize tracking:

- Issue templates: Epic, Stage, Task
- PR template with validation gates
- PR labeler config + workflow
- Demo/Runbook docs (repo-specific)

Use `../../scripts/apply-scaffold.sh <target-repo-path> <template>` to copy files.

Templates:
- `bridge/` — bridge/contract-oriented runbook
- `ds-cli/` — DS CLI runbook (self-status, verify script, example client)
- `dashboard/` — dashboard runbook (build, dev, typed adapters, SSE)
- `mcp/` — MCP server runbook (alias parity, OpenAPI, discovery)

