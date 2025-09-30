Apply integration card UI (project-level integration and Run Observers)

1) From the dashboard repo root, apply the patch:

git apply ../system-setup-update/examples/dashboard/patches/integration-card.patch

2) Ensure typed-integration and typed-components patches are applied first.

3) Set environment:

export OBS_BRIDGE_URL=http://127.0.0.1:7171
# export BRIDGE_TOKEN=... (if set on bridge)

4) Start servers; visit /projects/:id
 - Verify the Integration card shows Overall status and DS/MCP reachability
 - Click "Run Observers" to POST /api/tools/project_obs_run via the server proxy

