---
title: Vercel Cli Setup
category: reference
component: vercel_cli_setup
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Vercel CLI Setup

This document describes the installation and configuration of Vercel CLI in this development environment.

## Overview

- **Installation method**: npm global (`vercel`)
- **Current version**: Check with `vercel --version`
- **Location**: `~/.npm-global/bin/vercel`
- **Configuration**: Single Fish config managed via chezmoi
- **Documentation**: https://vercel.com/docs/cli

## Installation

Vercel CLI is installed via npm and managed through chezmoi templates:

```bash
npm install -g vercel
```

### Automated Installation

The chezmoi template `run_once_15-install-vercel.sh` handles initial installation:

```bash
chezmoi apply
```

This script:
1. Checks if `vercel` command exists
2. Installs `vercel` via npm if missing
3. Checks for available updates on each run
4. Provides installation location and version info

## Configuration

### Single Source of Truth

All Vercel CLI configuration is managed through:

**Template**: `06-templates/chezmoi/dot_config/fish/conf.d/15-vercel.fish.tmpl`
**Active config**: `~/.config/fish/conf.d/15-vercel.fish`

Apply changes with:

```bash
chezmoi apply
```

### Authentication

Vercel CLI supports multiple authentication methods.

#### Option 1: Interactive Login (Recommended for Local Development)

```bash
vercel login
```

This opens your browser and authenticates your local CLI. The token is stored in `~/.vercel/auth.json`.

#### Option 2: Token-Based Authentication (For CI/CD)

Create a token in Vercel dashboard:
1. Go to **Settings** → **Tokens**
2. Create a new token
3. Copy the token value

Store securely in gopass:

```bash
gopass insert vercel/token
```

The Fish configuration automatically retrieves the token when needed:

```fish
# Default command to fetch token
VERCEL_TOKEN_CMD="gopass show vercel/token"
```

Set in environment (for CI/CD):

```bash
export VERCEL_TOKEN="$(gopass show vercel/token)"
```

#### Option 3: Environment Variables (Project-Specific)

In your `.envrc`:

```bash
export VERCEL_TOKEN="$(gopass show vercel/token)"
export VERCEL_ORG_ID="team_xxxxx"  # Optional: default team
export VERCEL_PROJECT_ID="prj_xxxxx"  # Optional: default project
```

## Commands

### Aliases and Functions

| Command | Description | Usage |
|---------|-------------|-------|
| `vercel` / `vc` | Vercel CLI main command | `vercel --help` |
| `vercel-deploy` | Deploy to production | `vercel-deploy` |
| `vercel-preview` | Deploy to preview | `vercel-preview` |
| `vercel-dev` | Start local dev server | `vercel-dev` |
| `vercel-logs` | View deployment logs | `vercel-logs [url]` |
| `vercel-env` | Manage environment variables | `vercel-env ls` |
| `vercel-pull` | Pull env vars locally | `vercel-pull` |
| `vercel-link` | Link directory to project | `vercel-link` |
| `vercel-list` | List deployments | `vercel-list` |
| `vercel-inspect` | Inspect deployment | `vercel-inspect [url]` |
| `vercel-login` | Authenticate | `vercel-login` |
| `vercel-whoami` | Show current user | `vercel-whoami` |
| `vercel-prod` | Deploy + Sentry release | `vercel-prod` |
| `vercel-staging` | Preview + Sentry release | `vercel-staging` |
| `vercel_check_updates` | Check for CLI updates | `vercel_check_updates` |
| `vercel_status` | Show installation status | `vercel_status` |

### Common Operations

#### Deploy to Production

```bash
# Deploy to production
vercel --prod

# Or use the alias
vercel-deploy

# With Sentry integration
vercel-prod
```

#### Deploy to Preview

```bash
# Deploy to preview/staging
vercel

# Or use the alias
vercel-preview

# With Sentry integration
vercel-staging
```

#### Link a Project

```bash
# Link current directory to Vercel project
vercel link

# This creates .vercel/ directory with project config
```

#### Pull Environment Variables

```bash
# Pull all environment variables
vercel env pull

# Pull for specific environment
vercel env pull .env.development.local --environment development
vercel env pull .env.production.local --environment production
```

#### Manage Environment Variables

```bash
# List all environment variables
vercel env ls

# Add a new environment variable
vercel env add MY_VAR

# Remove an environment variable
vercel env rm MY_VAR

# Pull env vars to local file
vercel env pull .env.local
```

#### View Deployment Logs

```bash
# View logs for latest deployment
vercel logs

# View logs for specific deployment
vercel logs <deployment-url>

# Follow logs in real-time
vercel logs --follow
```

#### List Deployments

```bash
# List recent deployments
vercel list

# List deployments for specific project
vercel list my-project
```

#### Inspect Deployment

```bash
# Get detailed info about a deployment
vercel inspect <deployment-url>
```

#### Local Development

```bash
# Start Vercel dev server (with serverless functions)
vercel dev

# Specify port
vercel dev --listen 3000
```

## Project-Specific Configuration

### Linking Projects

When you run `vercel` for the first time in a directory:

```bash
vercel
? Set up and deploy "~/projects/my-app"? [Y/n] y
? Which scope do you want to deploy to? My Team
? Link to existing project? [y/N] y
? What's the name of your existing project? my-app
```

This creates `.vercel/` directory with:
- `project.json` - Project configuration
- `README.txt` - Information about the link

### Configuration File (vercel.json)

Create `vercel.json` in your project root:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "installCommand": "npm install",
  "functions": {
    "api/**/*.ts": {
      "maxDuration": 30
    }
  },
  "regions": ["iad1"],
  "env": {
    "MY_VAR": "@my-secret"
  }
}
```

### Environment-Specific Settings

```bash
# Per-project configuration via .envrc
export VERCEL_ORG_ID="team_xxxxx"
export VERCEL_PROJECT_ID="prj_xxxxx"
export VERCEL_TOKEN="$(gopass show vercel/projects/my-app/token)"
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/vercel-deploy.yml`:

```yaml
name: Vercel Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Vercel CLI
        run: npm install -g vercel

      - name: Pull Vercel Environment
        run: vercel pull --yes --environment=production --token=${{ secrets.VERCEL_TOKEN }}
        env:
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}

      - name: Build Project
        run: vercel build --prod --token=${{ secrets.VERCEL_TOKEN }}

      - name: Deploy to Vercel
        run: vercel deploy --prebuilt --prod --token=${{ secrets.VERCEL_TOKEN }}
```

Add secrets to GitHub:
- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

### GitLab CI

```yaml
variables:
  VERCEL_ORG_ID: $VERCEL_ORG_ID
  VERCEL_PROJECT_ID: $VERCEL_PROJECT_ID

deploy:
  script:
    - npm install -g vercel
    - vercel pull --yes --environment=production --token=$VERCEL_TOKEN
    - vercel build --prod --token=$VERCEL_TOKEN
    - vercel deploy --prebuilt --prod --token=$VERCEL_TOKEN
```

### Automated Deployments with Git Integration

Vercel can automatically deploy when you push to Git:

1. **Connect Repository**: In Vercel dashboard, import your Git repository
2. **Configure Settings**: Set build command, environment variables
3. **Auto-Deploy**: Every push triggers a deployment
   - `main` branch → Production
   - Other branches → Preview deployments

## Troubleshooting

### CLI Not Found After Installation

Check that npm global bin is in your PATH:

```bash
fish -c 'echo $PATH | tr " " "\n" | grep npm-global'
```

Should show: `~/.npm-global/bin`

If missing, check `~/.config/fish/conf.d/04-paths.fish`:

```fish
fish_add_path ~/.npm-global/bin
```

### Authentication Issues

**Problem**: `Error: Not authenticated`

**Solutions**:

1. **Check authentication status**:
   ```bash
   vercel whoami
   # Or
   vercel_status
   ```

2. **Login interactively**:
   ```bash
   vercel login
   ```

3. **Verify token (for CI/CD)**:
   ```bash
   echo $VERCEL_TOKEN
   # Or
   gopass show vercel/token
   ```

4. **Re-authenticate**:
   ```bash
   vercel logout
   vercel login
   ```

### Project Not Linked

**Problem**: `Error: No existing credentials found. Please run \`vercel login\``

**Solutions**:

1. **Link the project**:
   ```bash
   vercel link
   ```

2. **Check for .vercel directory**:
   ```bash
   ls -la .vercel/
   ```

3. **Re-link if corrupted**:
   ```bash
   rm -rf .vercel/
   vercel link
   ```

### Deployment Failures

**Problem**: Deployment fails with build errors

**Solutions**:

1. **Test build locally**:
   ```bash
   vercel build
   ```

2. **Check build logs**:
   ```bash
   vercel logs <deployment-url>
   ```

3. **Verify environment variables**:
   ```bash
   vercel env ls
   ```

4. **Pull production env locally**:
   ```bash
   vercel env pull .env.production.local --environment production
   ```

### Environment Variable Issues

**Problem**: Environment variables not available in deployment

**Solutions**:

1. **List env vars in Vercel**:
   ```bash
   vercel env ls
   ```

2. **Add missing variables**:
   ```bash
   vercel env add MY_VAR production
   ```

3. **Check variable exposure**:
   - Variables starting with `NEXT_PUBLIC_` are exposed to browser
   - Other variables are server-side only

4. **Redeploy after adding variables**:
   ```bash
   vercel --prod
   ```

### Slow Deployments

**Problem**: Deployments take too long

**Solutions**:

1. **Use prebuilt deployments**:
   ```bash
   vercel build
   vercel deploy --prebuilt
   ```

2. **Check bundle size**:
   ```bash
   npm run build
   # Check output for large bundles
   ```

3. **Enable caching** in `vercel.json`:
   ```json
   {
     "github": {
       "silent": true,
       "autoJobCancelation": true
     }
   }
   ```

## Best Practices

### 1. Use Environment Variables Wisely

```bash
# Store in Vercel (not in git)
vercel env add DATABASE_URL production

# Pull for local development
vercel env pull .env.local

# Use .env.example for documentation
cp .env.local .env.example
# Remove actual values from .env.example
```

### 2. Link Projects Consistently

```bash
# Always link in project root
cd ~/projects/my-app
vercel link

# Commit .vercel to git for team consistency
# But exclude auth tokens (they're in ~/.vercel/auth.json)
echo ".vercel" >> .gitignore  # Don't do this!
# Actually, .vercel/project.json SHOULD be committed
```

### 3. Use vercel.json for Configuration

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": "nextjs",
  "regions": ["iad1"],
  "functions": {
    "api/**/*.ts": {
      "maxDuration": 30
    }
  }
}
```

### 4. Test Locally Before Deploying

```bash
# Use Vercel dev for serverless functions
vercel dev

# Build locally first
vercel build

# Then deploy the build
vercel deploy --prebuilt --prod
```

### 5. Manage Deployments

```bash
# List recent deployments
vercel list

# Promote a specific deployment
vercel promote <deployment-url>

# Remove old deployments
vercel remove <deployment-url> --yes
```

### 6. Monitor Deployments

```bash
# Check deployment status
vercel inspect <deployment-url>

# View real-time logs
vercel logs --follow

# Check for errors
vercel logs | grep ERROR
```

## Integration with Other Tools

### With Sentry CLI

Use the provided Fish functions:

```bash
# Deploy and create Sentry release
vercel-prod   # Production deployment + Sentry
vercel-staging  # Preview deployment + Sentry
```

Or manually:

```bash
# Deploy
vercel --prod

# Create Sentry release
SENTRY_RELEASE="$(git rev-parse HEAD)" ./scripts/sentry-release.sh production
```

### With Prisma

```bash
# Build with Prisma generation
vercel build

# The build includes prisma generate automatically
# (if configured in package.json postinstall)
```

### With Next.js

Vercel automatically detects Next.js and configures:
- Build command: `next build`
- Output directory: `.next`
- Development command: `next dev`

Override in `vercel.json` if needed:

```json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install"
}
```

## Additional Resources

- **Official Documentation**: https://vercel.com/docs/cli
- **CLI Reference**: https://vercel.com/docs/cli/commands
- **Configuration**: https://vercel.com/docs/projects/project-configuration
- **Environment Variables**: https://vercel.com/docs/projects/environment-variables
- **Deployment**: https://vercel.com/docs/deployments/overview
- **GitHub Integration**: https://vercel.com/docs/git/vercel-for-github

## Quick Reference Commands

```bash
# Check installation
vercel --version
vercel_status

# Authentication
vercel login
vercel whoami

# Project setup
vercel link
vercel env pull

# Deployment
vercel              # Preview
vercel --prod       # Production
vercel-prod         # Production + Sentry

# Management
vercel list         # List deployments
vercel logs         # View logs
vercel env ls       # List env vars

# Development
vercel dev          # Local dev with serverless
vercel build        # Build locally

# Updates
npm update -g vercel
vercel_check_updates
```

## Related Files

- Fish config: `~/.config/fish/conf.d/15-vercel.fish`
- Installer: `~/.local/share/chezmoi/run_once_15-install-vercel.sh`
- Update script: `scripts/update-vercel-cli.sh`
- Template: `06-templates/chezmoi/dot_config/fish/conf.d/15-vercel.fish.tmpl`
