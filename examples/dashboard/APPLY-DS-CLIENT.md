Add DS generated client and adapter

1) Generate DS client from DS OpenAPI:

./scripts/generate-openapi-client-ds.sh examples/dashboard/generated/ds-client

2) Copy to dashboard repo:

mkdir -p src/generated/ds-client
cp -r ../system-setup-update/examples/dashboard/generated/ds-client/* src/generated/ds-client/

3) Apply adapter template:

git apply ../system-setup-update/examples/dashboard/patches/ds-adapter-template.patch

4) Use VITE_DS_URL and VITE_DS_TOKEN for DS base URL and token.

5) Update components to import dsAdapter if needed, or route via bridgeAdapter.

