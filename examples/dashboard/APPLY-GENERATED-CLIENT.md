Swap dashboard bridgeAdapter to use generated TS client

1) Generate client from the bridge OpenAPI (in system-setup-update):

./scripts/generate-openapi-client.sh examples/dashboard/generated/bridge-client

2) In the dashboard repo, copy the generated client into src (or adjust import path):

mkdir -p src/generated/bridge-client
cp -r ../system-setup-update/examples/dashboard/generated/bridge-client/* src/generated/bridge-client/

3) Apply the adapter patch:

git apply ../system-setup-update/examples/dashboard/patches/bridge-adapter-client.patch

4) Ensure VITE_API_URL points to your dashboard server base (e.g., http://localhost:3001).

5) Start the app; components using bridgeAdapter will prefer the generated client.

