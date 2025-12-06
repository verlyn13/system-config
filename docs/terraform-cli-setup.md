---
title: Terraform Cli Setup
category: reference
component: terraform_cli_setup
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Terraform CLI Setup

This document standardizes installation, updates, and authentication for the HashiCorp Terraform CLI in this environment.

## Overview

- Installation method: Homebrew (exclusively)
- Version: Terraform v1.14.0 (latest via Homebrew)
- Location: `/opt/homebrew/bin/terraform` (Apple Silicon) or `/usr/local/bin/terraform` (Intel)
- Config dir: `~/.terraform.d/`
- Credentials: `~/.terraform.d/credentials.tfrc.json`
- Helper scripts: `scripts/update-terraform-cli.sh`, `scripts/terraform-auth-setup.sh`

## Installation

### Homebrew (exclusive method)

```bash
./scripts/update-terraform-cli.sh
```

What it does:
- Taps `hashicorp/tap`
- Installs or upgrades `hashicorp/tap/terraform`
- Verifies Homebrew binary is installed
- Warns if mise-managed terraform conflicts exist
- Prints binary path and version

Verify:

```bash
which terraform
terraform -version
```

**Note:** This system uses Homebrew exclusively for Terraform to avoid PATH conflicts with mise-managed tools. Terraform has been removed from `.mise.toml`.

## Authentication

Terraform CLI authenticates to Terraform Cloud/Enterprise using a token stored in `~/.terraform.d/credentials.tfrc.json`.

### Non-interactive (recommended for automation)

Use the environment variable `TF_TOKEN_app_terraform_io` and the helper script to create/merge credentials:

```bash
export TF_TOKEN_app_terraform_io="<YOUR_TFC_TOKEN>"
./scripts/terraform-auth-setup.sh
```

This safely merges the token into `~/.terraform.d/credentials.tfrc.json` under `app.terraform.io`.

### Interactive

```bash
./scripts/terraform-auth-setup.sh   # will run `terraform login app.terraform.io`
```

You can also run `terraform login` directly and follow the prompt.

### Verify Auth

```bash
cat ~/.terraform.d/credentials.tfrc.json | jq '.credentials | keys[]'
# expect: app.terraform.io
```

## Commands

- Version: `terraform -version`
- Init: `terraform init`
- Validate: `terraform validate`
- Plan: `terraform plan`
- Apply: `terraform apply`

## Update Management

```bash
./scripts/update-terraform-cli.sh
```

This script ensures the latest Homebrew version is installed and detects any conflicts with mise-managed versions.

## Troubleshooting

- Command not found:
  - Ensure Homebrew bin is in PATH: `fish_add_path /opt/homebrew/bin` (Apple Silicon)
  - Or bash/zsh: `export PATH="/opt/homebrew/bin:$PATH"`

- Multiple terraform binaries:
  - Inspect: `command -v -a terraform`
  - If mise version is found: `mise uninstall terraform`
  - Ensure Homebrew's `/opt/homebrew/bin` comes before mise in PATH

- Version mismatch (mise conflict):
  - Uninstall mise version: `mise uninstall terraform`
  - Verify Homebrew version: `/opt/homebrew/bin/terraform -version`
  - Run script to detect issues: `./scripts/update-terraform-cli.sh`

- Auth issues:
  - Recreate credentials: set `TF_TOKEN_app_terraform_io` and rerun `scripts/terraform-auth-setup.sh`
  - Or interactive: `terraform login`

## Integration with This Repo

- Homebrew is the exclusive installation method for Terraform
- Terraform removed from `.mise.toml` to avoid PATH conflicts
- Helper scripts live in `scripts/` and are idempotent & safe to rerun
- Scripts detect and warn about mise conflicts

## Status (Local)

After running the update script, you should see:

```
Binary: /opt/homebrew/bin/terraform
Version: Terraform v1.14.0 (or latest)
Auth: app.terraform.io present in ~/.terraform.d/credentials.tfrc.json
```

If mise conflict exists, the script will warn you to uninstall the mise version.

---

Maintainer: System setup team
Last Reviewed: 2025-11-20

