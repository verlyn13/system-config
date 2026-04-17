#!/usr/bin/env zsh

set -euo pipefail

MANIFEST_PATH="${1:-/tmp/1p-ssh-import-manifest.tsv}"

mkdir -p -- "$(dirname -- "$MANIFEST_PATH")"

cat > "$MANIFEST_PATH" <<'EOF'
/Users/verlyn13/.ssh/id_ed25519_personal	ssh/workstation/personal/github	ssh,interactive,github,workstation,personal	Primary personal Git SSH key.
/Users/verlyn13/.ssh/id_ed25519_work	ssh/workstation/work/github	ssh,interactive,github,workstation,work	Work Git SSH key.
/Users/verlyn13/.ssh/id_ed25519_business	ssh/workstation/business/github	ssh,interactive,github,workstation,business	Business Git SSH key.
/Users/verlyn13/.ssh/id_ed25519_hubofaxel	ssh/workstation/hubofaxel/github	ssh,interactive,github,workstation,hubofaxel	Git SSH key for hubofaxel.
/Users/verlyn13/.ssh/id_ed25519_hubofwyn	ssh/workstation/hubofwyn/github	ssh,interactive,github,workstation,hubofwyn	Git SSH key for hubofwyn.
/Users/verlyn13/.ssh/id_ed25519_nash-group	ssh/workstation/nash-group/github	ssh,interactive,github,workstation,nash-group	Git SSH key for Nash Group.
/Users/verlyn13/.ssh/id_ed25519_hetzner_user	ssh/server/hetzner/user	ssh,server,hetzner,user	Hetzner user access key.
/Users/verlyn13/.ssh/id_ed25519_hetzner	ssh/server/hetzner/runner	ssh,server,hetzner,runner	Hetzner runner access key.
/Users/verlyn13/.ssh/id_ed25519	ssh/mesh/workstation/shared	ssh,mesh,workstation,shared	Trusted mesh workstation key.
/Users/verlyn13/.ssh/opnsense_usermgmt	ssh/network/opnsense/usermgmt	ssh,network,opnsense,usermgmt	OPNsense user management key.
/Users/verlyn13/.ssh/id_ed25519_proxmox	ssh/virtualization/proxmox/user	ssh,virtualization,proxmox,user	Proxmox user access key.
/Users/verlyn13/.ssh/dad_admin	ssh/windows/dad-admin	ssh,windows,admin,dad-admin	Windows admin SSH key.
EOF

printf 'Wrote manifest: %s\n' "$MANIFEST_PATH"
printf 'Entries: %s\n' "$(wc -l < "$MANIFEST_PATH" | tr -d ' ')"
