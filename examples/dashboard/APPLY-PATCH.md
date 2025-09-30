Dashboard typed-integration patch

1) From the dashboard repo root, apply the patch:

git apply ../system-setup-update/examples/dashboard/patches/typed-integration.patch

2) Install dependencies:

npm i ajv --save

3) Configure environment (optional):

export OBS_BRIDGE_URL=http://127.0.0.1:7171

4) Start the server and Vite dev server as usual.

5) Verify:
- Open the app; Diagnostics panel should show bridge health and obs coverage.
- Project detail should render typed payloads (validated by Ajv).

