Add Manifest and MCP status cards to Dashboard

1) From dashboard repo root, apply the patch:

git apply ../system-setup-update/examples/dashboard/patches/manifest-mcp-cards.patch

2) Ensure previous patches are applied:
- typed-integration.patch
- typed-components.patch
- integration-card.patch

3) Environment:

export OBS_BRIDGE_URL=http://127.0.0.1:7171
# export BRIDGE_TOKEN=...

4) Start dashboard and verify:
- Project detail shows Manifest Validation (YAML/JSON view) under Integration card
- Documentation page shows MCP Server status below DS CLI status

