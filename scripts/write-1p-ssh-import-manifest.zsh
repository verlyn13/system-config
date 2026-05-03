#!/usr/bin/env zsh

set -euo pipefail

MANIFEST_PATH="${1:-/tmp/1p-ssh-import-manifest.tsv}"

mkdir -p -- "$(dirname -- "$MANIFEST_PATH")"

cat > "$MANIFEST_PATH" <<'EOF'
/Users/verlyn13/.ssh/id_ed25519_personal	ssh/workstation/personal/github	ssh,interactive,github,workstation,personal	Primary personal Git SSH key.
/Users/verlyn13/.ssh/id_ed25519_work	ssh/workstation/work/github	ssh,interactive,github,workstation,work	Work Git SSH key.
/Users/verlyn13/.ssh/id_ed25519_business	ssh/workstation/business/github	ssh,interactive,github,workstation,business	Business Git SSH key.
/Users/verlyn13/.ssh/id_ed25519_business-org	ssh/workstation/business-org/github	ssh,interactive,github,workstation,business-org	GitHub identity for happy-patterns-org variant. De-duplicate with business_org.
/Users/verlyn13/.ssh/id_ed25519_business_org	ssh/workstation/business_org/github	ssh,interactive,github,workstation,business_org	GitHub identity for business-org variant. De-duplicate with business-org.
/Users/verlyn13/.ssh/id_ed25519_hubofaxel	ssh/workstation/hubofaxel/github	ssh,interactive,github,workstation,hubofaxel	Git SSH key for hubofaxel.
/Users/verlyn13/.ssh/id_ed25519_hubofwyn	ssh/workstation/hubofwyn/github	ssh,interactive,github,workstation,hubofwyn	Git SSH key for hubofwyn.
/Users/verlyn13/.ssh/id_ed25519_nash-group	ssh/workstation/nash-group/github	ssh,interactive,github,workstation,nash-group	Git SSH key for Nash Group.
/Users/verlyn13/.ssh/id_ed25519_documentation	ssh/workstation/documentation/container	ssh,workstation,documentation,container	laptop-to-documentation-container access key. Provenance review; archive if unused.
/Users/verlyn13/.ssh/id_ed25519_mac	ssh/workstation/mac/cross-machine	ssh,workstation,mac,cross-machine	verlyn13@fedora-top cross-machine identity. Provenance review.
/Users/verlyn13/.ssh/id_ed25519_scope	ssh/workstation/scope/unknown	ssh,workstation,scope,unknown	Provenance unclear. Review before action.
/Users/verlyn13/.ssh/id_ed25519_hetzner_user	ssh/server/hetzner/user	ssh,server,hetzner,user	Hetzner user access key.
/Users/verlyn13/.ssh/id_ed25519_hetzner	ssh/server/hetzner/runner	ssh,server,hetzner,runner	Hetzner runner access key.
/Users/verlyn13/.ssh/id_ed25519_hetzner_root	ssh/server/hetzner/root	ssh,server,hetzner,root,high-blast-radius	root@hetzner — high blast radius. Rotate-fresh urgently; replace with role-scoped key if possible.
/Users/verlyn13/.ssh/traefik_key	ssh/server/traefik/root	ssh,server,traefik,root,passphrase-protected	root@traefik — passphrase-protected. High reach, plan rotation.
/Users/verlyn13/.ssh/libreweb_key	ssh/server/libreweb/user	ssh,server,libreweb,user,passphrase-protected	libreweb host — passphrase-protected. Review.
/Users/verlyn13/.ssh/id_ed25519	ssh/mesh/workstation/shared	ssh,mesh,workstation,shared	Trusted mesh workstation key.
/Users/verlyn13/.ssh/opnsense_usermgmt	ssh/network/opnsense/usermgmt	ssh,network,opnsense,usermgmt	OPNsense user management key.
/Users/verlyn13/.ssh/opnsense_usermgmt.from-1password	ssh/network/opnsense/usermgmt-from-1p	ssh,network,opnsense,usermgmt,1password-import-residue	Partial 1Password import attempt. Reconcile with opnsense_usermgmt and remove.
/Users/verlyn13/.ssh/opnsense_ed25519	ssh/network/opnsense/admin	ssh,network,opnsense,admin	OPNsense alternate identity (opnsense@192.168.0.1). Provenance review.
/Users/verlyn13/.ssh/synology_downloader_service	ssh/network/synology/downloader-service	ssh,network,synology,service-account	Synology downloader service account. Provenance review; rotate.
/Users/verlyn13/.ssh/synology_nas_key	ssh/network/synology/user	ssh,network,synology,user,passphrase-protected	Synology user access — passphrase-protected. Keep on disk or import as-is.
/Users/verlyn13/.ssh/container_key	ssh/container/lx101/access	ssh,container,lx101,passphrase-protected	lx101-container-access — passphrase-protected. Review.
/Users/verlyn13/.ssh/id_ed25519_proxmox	ssh/virtualization/proxmox/user	ssh,virtualization,proxmox,user	Proxmox user access key.
/Users/verlyn13/.ssh/google_compute_engine	ssh/cloud/gcp/compute-engine	ssh,cloud,gcp,compute-engine,passphrase-protected,rsa3072	GCP Compute Engine RSA-3072. Consider GCP OS Login or service account instead of personal key.
/Users/verlyn13/.ssh/dad_admin	ssh/windows/dad-admin	ssh,windows,admin,dad-admin	Windows admin SSH key.
EOF

printf 'Wrote manifest: %s\n' "$MANIFEST_PATH"
printf 'Entries: %s\n' "$(wc -l < "$MANIFEST_PATH" | tr -d ' ')"
