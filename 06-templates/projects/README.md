---
title: Readme
category: template
component: readme
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

#!/bin/bash
# Project Template System - README

## Overview
This directory contains project templates and generators for quickly scaffolding new projects with consistent structure and tooling.

## Available Templates

### Project Types
- **node** - Node.js/TypeScript project with Bun
- **python** - Python project with uv package manager  
- **go** - Go module project
- **rust** - Rust project with cargo
- **react** - React application with Vite
- **next** - Next.js 15 application
- **cli** - Command-line tool template
- **lib** - Library/package template
- **api** - API service with Fastify

## Usage

### Using the Generator Script
```bash
# Make the script executable (first time only)
chmod +x new-project.fish

# Create a new project
./new-project.fish <type> <project-name>

# Examples
./new-project.fish node my-app
./new-project.fish python data-processor  
./new-project.fish react dashboard
./new-project.fish api user-service
```

### Manual Template Usage
Each template can also be applied manually by copying the relevant sections from the generator script.

## Template Features

### All Templates Include:
- ✅ Git repository initialization
- ✅ README.md with structure
- ✅ .gitignore with sensible defaults
- ✅ .editorconfig for consistent formatting
- ✅ .mise.toml for version management
- ✅ .envrc for direnv integration
- ✅ VS Code settings

### Language-Specific Features:

#### Node.js/TypeScript
- Bun as package manager and runtime
- TypeScript configuration
- Biome for linting/formatting
- Vitest for testing

#### Python
- uv for fast package management
- Black, Ruff, and MyPy configured
- pytest for testing
- Modern pyproject.toml setup

#### Go
- Go modules initialized
- Standard cmd/pkg/internal structure
- Makefile with common tasks

#### Rust
- Cargo project structure
- Tokio runtime included
- Criterion for benchmarking

#### React
- Vite for fast builds
- TypeScript configured
- Testing setup with Vitest
- Tailwind CSS ready

#### Next.js
- Latest Next.js 15
- App router
- TypeScript + Tailwind
- Optimized for Bun

## Customization

### Adding New Templates
1. Edit `new-project.fish`
2. Add a new case in the switch statement
3. Include language-specific setup commands
4. Update this README

### Modifying Existing Templates
Templates can be customized by editing the relevant section in `new-project.fish`.

## Best Practices

### Project Structure
All projects follow these conventions:
- Source code in `src/` directory
- Tests in `tests/` or `src/**/*.test.ts`
- Documentation in `docs/` or README
- Environment config via .env files

### Version Management
Projects use mise for managing language versions:
- Versions specified in .mise.toml
- Consistent with system-wide policy
- Automatic activation via direnv

### Development Workflow
1. Create project with template
2. Customize configuration files
3. Install dependencies
4. Start development server
5. Write code with hot reload
6. Run tests continuously
7. Build for production

## Integration with System

These templates integrate with your development environment:
- **mise** handles language versions
- **direnv** loads environment automatically
- **chezmoi** can track dotfiles
- **GitHub** ready for push
- **VS Code** configured for each language

## Examples

### Create a TypeScript CLI Tool
```bash
./new-project.fish cli my-cli-tool
cd ~/Development/verlyn13/my-cli-tool
bun run dev
```

### Create a Python Data Science Project
```bash
./new-project.fish python ml-experiment
cd ~/Development/verlyn13/ml-experiment
uv add pandas numpy scikit-learn jupyter
uv run jupyter lab
```

### Create a Full-Stack App
```bash
# Frontend
./new-project.fish react app-frontend
cd ~/Development/verlyn13/app-frontend
bun run dev

# Backend
./new-project.fish api app-backend
cd ~/Development/verlyn13/app-backend
bun run dev
```

## Maintenance

Templates should be updated when:
- New language versions are released
- Better tools become available
- Project requirements change
- Team standards evolve

Last updated: 2025-09-26
