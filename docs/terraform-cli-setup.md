---
title: Terraform CLI Setup
category: reference
component: terraform_cli_setup
status: active
version: 2.0.0
last_updated: 2026-02-05
tags: [cli, terraform, iac, homebrew]
priority: medium
---

# Terraform CLI Setup

Standardized installation for HashiCorp Terraform CLI.

## Overview

- **Installation**: Homebrew (exclusively)
- **Location**: `/opt/homebrew/bin/terraform` (Apple Silicon)
- **Config**: `~/.terraform.d/`
- **Credentials**: `~/.terraform.d/credentials.tfrc.json`
- **Official docs**: https://developer.hashicorp.com/terraform/cli

## Installation

```bash
./scripts/update-terraform-cli.sh
```

This script:
- Taps `hashicorp/tap`
- Installs/upgrades `hashicorp/tap/terraform`
- Warns about mise conflicts

Verify:

```bash
which terraform
terraform -version
```

**Note**: Homebrew is the exclusive installation method. Terraform has been removed from `.mise.toml` to avoid PATH conflicts.

## Authentication

### Terraform Cloud/Enterprise

Non-interactive (recommended):

```bash
export TF_TOKEN_app_terraform_io="your-token"
./scripts/terraform-auth-setup.sh
```

Interactive:

```bash
terraform login app.terraform.io
```

Verify:

```bash
cat ~/.terraform.d/credentials.tfrc.json | jq '.credentials | keys[]'
```

## Common Commands

```bash
terraform init      # Initialize
terraform validate  # Validate config
terraform plan      # Preview changes
terraform apply     # Apply changes
```

## Updates

```bash
./scripts/update-terraform-cli.sh
```

## Troubleshooting

### Command not found

```bash
# Ensure Homebrew bin in PATH
fish_add_path /opt/homebrew/bin
```

### Multiple terraform binaries

```bash
# Check all locations
command -v -a terraform

# Remove mise version if present
mise uninstall terraform
```

### Auth issues

```bash
# Recreate credentials
export TF_TOKEN_app_terraform_io="your-token"
./scripts/terraform-auth-setup.sh

# Or interactive
terraform login
```

## Related

- [Terraform CLI Docs](https://developer.hashicorp.com/terraform/cli)
- [Update script](../scripts/update-terraform-cli.sh)
- [Auth setup script](../scripts/terraform-auth-setup.sh)
