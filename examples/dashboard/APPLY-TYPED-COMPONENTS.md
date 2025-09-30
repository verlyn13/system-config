Apply typed components to replace raw JSON rendering

1) From the dashboard repo root, apply the patch:

git apply ../system-setup-update/examples/dashboard/patches/typed-components.patch

2) Ensure the typed-integration patch is already applied (ContractsProvider, server proxies).

3) Environment

export OBS_BRIDGE_URL=http://127.0.0.1:7171
# export BRIDGE_TOKEN=... (if set on bridge)

4) Start server and Vite dev server.

5) Verify
- Visit /projects/:id → ObserversView cards render; no raw JSON.
- Diagnostics panel shows health & coverage; click a “Run Discovery” control if available to call /api/discover.

