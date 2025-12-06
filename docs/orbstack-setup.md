---
title: OrbStack Setup
category: reference
component: orbstack_setup
status: active
version: 1.0.0
last_updated: 2025-11-03
tags: []
priority: high
---


# OrbStack Setup

This document describes the installation and configuration of OrbStack in this development environment.

## Overview

- **Installation method**: Homebrew cask (`brew install --cask orbstack`)
- **Current version**: Check with `orb version`
- **Location**: `/Applications/OrbStack.app`
- **CLI binaries**: `/Applications/OrbStack.app/Contents/MacOS/bin/`
- **Configuration**: Single Fish config managed via chezmoi
- **Documentation**: https://docs.orbstack.dev/

## What is OrbStack?

OrbStack is a fast, lightweight replacement for Docker Desktop on macOS. It provides:

- **Docker Engine**: Full Docker compatibility
- **Container Management**: Run Docker containers with better performance
- **Linux Machines**: Lightweight Linux VMs for development
- **Kubernetes**: Built-in Kubernetes support (optional)
- **Lower Resource Usage**: Significantly lighter than Docker Desktop
- **Faster Startup**: Near-instant container and VM startup times

## Installation

OrbStack is installed via Homebrew and managed through chezmoi templates:

```bash
brew install --cask orbstack
```

### Automated Installation

The chezmoi template `run_once_17-install-orbstack.sh` handles initial installation:

```bash
chezmoi apply
```

This script:
1. Checks if `orb` command exists
2. Installs `orbstack` cask via Homebrew if missing
3. Checks for available updates on each run
4. Provides installation location and version info
5. Instructions for completing setup

## Configuration

### Single Source of Truth

All OrbStack CLI configuration is managed through:

**Template**: `06-templates/chezmoi/dot_config/fish/conf.d/17-orbstack.fish.tmpl`
**Active config**: `~/.config/fish/conf.d/17-orbstack.fish`

Apply changes with:

```bash
chezmoi apply
```

### Brewfile Integration

OrbStack is declared in the GUI applications Brewfile:

**Template**: `~/.local/share/chezmoi/workspace/dotfiles/Brewfile.gui`

```ruby
cask "orbstack"  # Docker Desktop replacement
```

## First-Time Setup

After installation:

1. **Launch OrbStack Application**:
   ```bash
   open /Applications/OrbStack.app
   ```

2. **Complete Initial Setup**:
   - Follow the guided setup in the OrbStack app
   - Grant necessary permissions when prompted
   - Choose default settings or customize as needed

3. **Verify CLI Access**:
   ```bash
   orb version
   docker --version
   ```

4. **Start OrbStack**:
   ```bash
   orb start
   ```

## CLI Commands

### OrbStack Management

OrbStack automatically installs its CLI tools to `/usr/local/bin` and `/opt/homebrew/bin`, making them immediately available in your PATH. The Fish configuration provides convenient aliases but **does not override** the native commands.

#### Core Commands (Native - Already in PATH)

- `orb` - OrbStack management CLI
- `orbctl` - OrbStack control CLI (lower-level operations)
- `docker` - Docker CLI (provided by OrbStack)
- `docker-compose` - Docker Compose CLI (provided by OrbStack)

#### Convenience Aliases (Provided by Fish Config)

**OrbStack shortcuts:**
- `orbstart` - Start OrbStack (`orb start`)
- `orbstop` - Stop OrbStack (`orb stop`)
- `orbrestart` - Restart OrbStack (`orb restart`)
- `orbstatus` - Show running status (`orb status`)
- `orbinfo` - Show system information (`orb info`)
- `orbopen` - Open OrbStack application

**Docker shortcuts:**
- `dps` - List running containers (`docker ps`)
- `dpsa` - List all containers (`docker ps -a`)
- `dimages` - List Docker images
- `dclean` - Clean up unused Docker resources (with confirmation)

**Status and updates:**
- `orbstack_status` - Comprehensive installation and status check
- `orbstack_check_updates` - Check for available updates

### Usage Examples

```bash
# Start OrbStack
orbstart

# Check status
orbstatus

# Run a Docker container
docker run hello-world

# List running containers
docker ps

# Stop OrbStack
orbstop

# Get detailed status
orbstack_status
```

## Docker Compatibility

OrbStack provides complete Docker compatibility:

- All standard `docker` and `docker-compose` commands work
- Docker images and containers are managed by OrbStack
- Existing Docker projects work without modification
- Docker volumes and networks are fully supported

### Migrating from Docker Desktop

If migrating from Docker Desktop:

1. **Stop Docker Desktop**:
   ```bash
   # Quit Docker Desktop application
   ```

2. **Uninstall Docker Desktop** (optional):
   ```bash
   # Move to Trash or use official uninstaller
   ```

3. **Install OrbStack**:
   ```bash
   chezmoi apply
   ```

4. **Import Existing Data** (if needed):
   - OrbStack can import Docker Desktop volumes
   - Follow OrbStack's migration guide in the app

## Linux Machines

OrbStack also supports running lightweight Linux VMs:

```bash
# Create a new Linux machine
orb create ubuntu my-ubuntu

# List machines
orb list

# Shell into a machine
orb shell my-ubuntu

# Stop a machine
orb stop my-ubuntu

# Remove a machine
orb delete my-ubuntu
```

## Updates

### Checking for Updates

```bash
orbstack_check_updates
```

### Updating OrbStack

```bash
brew upgrade --cask orbstack
```

OrbStack also has built-in auto-update functionality that can be configured in the application preferences.

## Troubleshooting

### OrbStack Not Starting

1. Check if OrbStack is running:
   ```bash
   orbstatus
   ```

2. Try restarting:
   ```bash
   orbstop && orbstart
   ```

3. Check logs:
   ```bash
   orb logs
   ```

### Docker Command Not Found

1. Verify OrbStack is installed:
   ```bash
   orbstack_status
   ```

2. Check PATH configuration:
   ```bash
   echo $PATH | tr ' ' '\n' | grep OrbStack
   ```

3. Restart your shell:
   ```bash
   exec fish
   ```

### Performance Issues

1. Check resource usage in OrbStack app
2. Adjust resource limits in OrbStack settings
3. Consider pruning unused containers and images:
   ```bash
   docker system prune -a
   ```

## Fish Shell Completions

Fish completions are automatically loaded from the OrbStack application bundle:

**Location**: `/Applications/OrbStack.app/Contents/Resources/completions/fish/orbctl.fish`

The completions are sourced automatically by the Fish configuration file.

## Environment Variables

OrbStack uses these environment variables (set in Fish config):

- `ORBSTACK_APP`: Path to OrbStack.app
- `ORBSTACK_BIN`: Path to OrbStack CLI binaries

## Advanced Configuration

### Resource Limits

Configure resource limits in the OrbStack app:
1. Open OrbStack
2. Go to **Settings** → **Resources**
3. Adjust CPU, Memory, and Disk limits

### Network Settings

Configure networking in OrbStack app:
1. Open OrbStack
2. Go to **Settings** → **Network**
3. Configure port forwarding, DNS, etc.

## Integration with Other Tools

### mise Integration

OrbStack works seamlessly with mise-managed tools:

```bash
# Use mise-managed Node.js with Docker
mise use node@20
docker run -v $(pwd):/app -w /app node:20 npm install
```

### direnv Integration

OrbStack respects direnv environments:

```bash
# .envrc
export DOCKER_HOST=unix:///var/run/docker.sock
```

## References

- **Official Documentation**: https://docs.orbstack.dev/
- **CLI Reference**: https://docs.orbstack.dev/cli
- **Docker Compatibility**: https://docs.orbstack.dev/docker
- **Linux Machines**: https://docs.orbstack.dev/machines
- **Migration Guide**: https://docs.orbstack.dev/install#migrating-from-docker-desktop

## Related Files

- Fish config: `06-templates/chezmoi/dot_config/fish/conf.d/17-orbstack.fish.tmpl`
- Installer: `06-templates/chezmoi/run_once_17-install-orbstack.sh.tmpl`
- Brewfile: `~/.local/share/chezmoi/workspace/dotfiles/Brewfile.gui`
- Update script: `scripts/update-orbstack.sh` (to be created)
