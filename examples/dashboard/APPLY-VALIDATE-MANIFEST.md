Add a Validate Manifest button to ManifestCard

1) From dashboard repo root, apply the patch:

git apply ../system-setup-update/examples/dashboard/patches/validate-manifest-button.patch

2) Ensure the server proxies /api/obs/projects/:id/manifest to the bridge (added in previous patches).

3) Start the app. ManifestCard now has a "Validate" button with a spinner.

