#!/usr/bin/env zsh

set -euo pipefail

ACCOUNT="my.1password.com"
VAULT="Dev"

# Default to a real expanded path. User may pass a custom path.
MANIFEST_PATH="${1:-$HOME/Documents/1p-ssh-import-manifest.tsv}"

typeset -i total_count=0
typeset -i local_present_count=0
typeset -i local_missing_count=0
typeset -i valid_key_count=0
typeset -i invalid_key_count=0
typeset -i onepassword_present_count=0
typeset -i onepassword_missing_count=0

info()  { printf '[INFO] %s\n' "$*"; }
warn()  { printf '[WARN] %s\n' "$*" >&2; }
error() { printf '[ERROR] %s\n' "$*" >&2; }

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    error "Required command not found: $cmd"
    exit 1
  }
}

check_prereqs() {
  require_cmd op
  require_cmd ssh-keygen

  info "Checking 1Password access for account '$ACCOUNT' and vault '$VAULT'..."
  op vault get "$VAULT" --account "$ACCOUNT" >/dev/null
}

ensure_manifest_dir() {
  mkdir -p -- "$(dirname -- "$MANIFEST_PATH")"
}

write_manifest() {
  ensure_manifest_dir

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

  info "Wrote manifest: $MANIFEST_PATH"
  info "Entries: $(wc -l < "$MANIFEST_PATH" | tr -d '[:space:]')"
}

item_exists() {
  local title="$1"
  op item get "$title" --account "$ACCOUNT" --vault "$VAULT" >/dev/null 2>&1
}

fingerprint_for_key() {
  local src="$1"
  ssh-keygen -lf "$src" 2>/dev/null
}

report_manifest() {
  local src title tags note fp

  printf '\n'
  printf '1Password CLI cannot import existing private key files into SSH Key items.\n'
  printf 'Use the desktop app for import. This script prepares and verifies the inventory.\n'
  printf 'CLI can generate SSH keys, but existing-key import is a desktop-app workflow. '
  printf 'CLI also cannot edit SSH key items.\n\n'

  while IFS=$'\t' read -r src title tags note || [[ -n "${src:-}" ]]; do
    [[ -n "${src:-}" ]] || continue
    (( total_count += 1 ))

    printf '== %s ==\n' "$title"
    printf 'source      %s\n' "$src"
    printf 'tags        %s\n' "$tags"
    printf 'note        %s\n' "$note"

    if [[ -f "$src" ]]; then
      (( local_present_count += 1 ))
      if fp="$(fingerprint_for_key "$src")"; then
        (( valid_key_count += 1 ))
        printf 'fingerprint %s\n' "$fp"
      else
        (( invalid_key_count += 1 ))
        printf 'fingerprint [unable to read key]\n'
      fi
    else
      (( local_missing_count += 1 ))
      printf 'fingerprint [missing file]\n'
    fi

    if item_exists "$title"; then
      (( onepassword_present_count += 1 ))
      printf '1password   already exists in %s\n' "$VAULT"
      printf 'action      none\n'
    else
      (( onepassword_missing_count += 1 ))
      printf '1password   missing from %s\n' "$VAULT"
      printf 'action      import manually in 1Password desktop app as SSH Key item\n'
    fi

    printf '\n'
  done < "$MANIFEST_PATH"
}

print_summary() {
  printf '===== Summary =====\n'
  printf 'Manifest path:        %s\n' "$MANIFEST_PATH"
  printf 'Total entries:        %d\n' "$total_count"
  printf 'Local files present:  %d\n' "$local_present_count"
  printf 'Local files missing:  %d\n' "$local_missing_count"
  printf 'Readable key files:   %d\n' "$valid_key_count"
  printf 'Unreadable key files: %d\n' "$invalid_key_count"
  printf 'Already in 1Password: %d\n' "$onepassword_present_count"
  printf 'Need manual import:   %d\n' "$onepassword_missing_count"
}

print_next_steps() {
  cat <<EOF

Next steps in 1Password desktop app:
  1. Open vault: $VAULT
  2. New Item -> SSH Key
  3. Add Private Key -> import/paste from the matching local file
  4. Set title exactly as shown in the report
  5. Add tags exactly as shown
  6. Add the note text shown
  7. Save

Manifest:
  $MANIFEST_PATH
EOF
}

main() {
  check_prereqs
  write_manifest
  printf '\n'
  report_manifest
  print_summary
  print_next_steps
}

main "$@"
