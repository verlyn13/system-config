---
title: Terraform CLI Setup
category: reference
component: terraform_cli_setup
status: active
version: 3.0.0
last_updated: 2026-04-08
tags: [cli, terraform, iac]
priority: medium
---

# Terraform CLI Setup

Terraform is a CLI tool with tool-native config. This repo does not manage Terraform through fish shell snippets.

## Overview

- Binary: `terraform`
- Config directory: `~/.terraform.d/`
- Credentials: `~/.terraform.d/credentials.tfrc.json`

## Installation

Use the project’s preferred package flow or a direct Homebrew install:

```bash
brew install hashicorp/tap/terraform
terraform -version
```

## Policy

- Keep Terraform credentials out of shell startup files.
- Prefer project `.envrc` or the tool-native credential file for auth.
- Do not add Terraform-specific fish helpers to this repo.
