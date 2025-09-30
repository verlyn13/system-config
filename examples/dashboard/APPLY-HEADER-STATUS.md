Add a global header status chip for Bridge and MCP

1) From dashboard repo root, apply the patch:

git apply ../system-setup-update/examples/dashboard/patches/header-status-chip.patch

2) Ensure the server proxies /api/mcp/self-status to the MCP bridge (already added in previous patches).

3) Start the app. A small fixed chip shows Bridge and MCP status in the top-right.

