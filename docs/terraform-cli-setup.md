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

- Installation methods: Homebrew (primary), mise (optional)
- Version: Terraform v1.13.3 (via Homebrew)
- Location: `which terraform` → typically `/opt/homebrew/bin/terraform`
- Config dir: `~/.terraform.d/`
- Credentials: `~/.terraform.d/credentials.tfrc.json`
- Helper scripts: `scripts/update-terraform-cli.sh`, `scripts/terraform-auth-setup.sh`

## Installation

### Homebrew (recommended)

```bash
./scripts/update-terraform-cli.sh
```

What it does:
- Taps `hashicorp/tap`
- Installs or upgrades `hashicorp/tap/terraform`
- Prints binary path and version

Verify:

```bash
which terraform
terraform -version
```

### mise (optional)

This repo includes `terraform = "latest"` in `.mise.toml` so you can optionally manage Terraform with mise:

```bash
mise install
```

Notes:
- Prefer one manager per tool in your shell PATH to avoid ambiguity (Homebrew is the default in this setup).
- Ensure PATH ordering if you switch to mise-managed binaries.

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

- Check/update (brew): `./scripts/update-terraform-cli.sh`
- Optional (mise): `mise install terraform@latest`

## Troubleshooting

- Command not found:
  - Ensure Homebrew bin is in PATH: `fish_add_path /opt/homebrew/bin` (Apple Silicon)
  - Or bash/zsh: `export PATH="/opt/homebrew/bin:$PATH"`

- Multiple terraform binaries:
  - Inspect: `command -v -a terraform`
  - Reorder PATH so the desired manager comes first

- Auth issues:
  - Recreate credentials: set `TF_TOKEN_app_terraform_io` and rerun `scripts/terraform-auth-setup.sh`
  - Or interactive: `terraform login`

## Integration with This Repo

- Use Homebrew as the primary install to match other system tools
- `.mise.toml` includes Terraform for optional mise-based workflows
- Helper scripts live in `scripts/` and are idempotent & safe to rerun

## Status (Local)

Sample local state on this machine:

```
Binary: /opt/homebrew/bin/terraform
Version: Terraform v1.13.3
Auth: app.terraform.io present in ~/.terraform.d/credentials.tfrc.json
```

---

Maintainer: System setup team
Last Reviewed: 2025-10-18

