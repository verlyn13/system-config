---
title: Repository Structure
category: reference
component: organization
status: active
version: 2.0.0
last_updated: 2025-09-26
tags: []
priority: high
---

# System Setup Repository Structure

> **Purpose**: Single source of truth for macOS development environment configuration, documentation, and automation
> **Version**: 2.0.0
> **Last Updated**: 2025-09-26
> **Status**: Active Development

## 📁 Repository Organization

```
system-setup-update/
├── README.md                    # Main entry point with quick start
├── INDEX.md                     # Complete navigation and document registry
├── REPO-STRUCTURE.md           # This file - organizational blueprint
├── CLAUDE.md                    # AI assistant context and guidelines
│
├── 01-setup/                    # Initial setup and installation
│   ├── README.md               # Setup overview and sequence
│   ├── 00-prerequisites.md     # System requirements and prep
│   ├── 01-homebrew.md          # Homebrew installation and config
│   ├── 02-chezmoi.md           # Chezmoi setup and initialization
│   ├── 03-fish-shell.md        # Fish shell configuration
│   ├── 04-mise.md              # Mise version management
│   └── 05-security.md          # Security tools and settings
│
├── 02-configuration/            # Detailed configuration guides
│   ├── README.md               # Configuration overview
│   ├── terminals/              # Terminal emulator configs
│   │   ├── iterm2.md          # iTerm2 complete setup
│   │   ├── warp.md            # Warp terminal setup
│   │   └── alacritty.md      # Alacritty configuration
│   ├── shells/                 # Shell configurations
│   │   ├── fish.md            # Fish shell details
│   │   ├── zsh.md             # Zsh configuration
│   │   └── bash.md            # Bash compatibility
│   ├── editors/                # Editor configurations
│   │   ├── vscode.md          # VS Code settings
│   │   ├── neovim.md          # Neovim setup
│   │   └── sublime.md         # Sublime Text config
│   └── tools/                  # Development tools
│       ├── git.md             # Git configuration
│       ├── docker.md          # Docker setup
│       └── ssh.md             # SSH multi-account setup
│
├── 03-automation/               # Automation and scripts
│   ├── README.md               # Automation overview
│   ├── scripts/                # Executable scripts
│   │   ├── setup.sh           # Main setup orchestrator
│   │   ├── validate.sh        # System validation
│   │   └── update.sh          # Update automation
│   ├── hooks/                  # Git and system hooks
│   └── workflows/              # GitHub Actions workflows
│
├── 04-policies/                 # System policies and compliance
│   ├── README.md               # Policy overview
│   ├── policy-as-code.yaml    # Machine-readable policies
│   ├── security-policy.md     # Security requirements
│   ├── version-policy.md      # Version management rules
│   └── compliance-check.py    # Policy validation script
│
├── 05-reference/                # Reference documentation
│   ├── README.md               # Reference overview
│   ├── troubleshooting.md     # Common issues and solutions
│   ├── migration.md           # Migration from other setups
│   ├── rollback.md            # Rollback procedures
│   └── faq.md                 # Frequently asked questions
│
├── 06-templates/                # Reusable templates
│   ├── README.md               # Template usage guide
│   ├── chezmoi/                # Chezmoi templates
│   ├── dotfiles/               # Dotfile templates
│   └── projects/               # Project scaffolding
│
├── 07-reports/                  # System reports and status
│   ├── README.md               # Reports overview
│   ├── status/                 # Current system status
│   │   ├── implementation.md  # Implementation progress
│   │   └── compliance.md      # Compliance status
│   ├── history/                # Historical reports
│   └── metrics/                # Performance metrics
│
└── .meta/                       # Metadata and tooling
    ├── labels.yaml             # Document labels and tags
    ├── dependencies.json       # Document dependencies
    ├── versions.json           # Version tracking
    └── sync-config.yaml        # Sync with live system config
```

## 🏷️ Document Metadata Structure

Every markdown document includes frontmatter:

```yaml
---
title: Document Title
category: setup|configuration|automation|policy|reference|template|report
component: homebrew|chezmoi|fish|iterm2|etc
status: draft|active|deprecated
version: 1.0.0
last_updated: 2025-09-26
dependencies:
  - doc: 01-setup/00-prerequisites.md
    type: required|optional
tags:
  - macos
  - terminal
  - productivity
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
---
```

## 📊 Document Categories

### Setup Documents (01-setup/)
- **Purpose**: Step-by-step installation guides
- **Metadata**: `category: setup`
- **Naming**: `{order}-{component}.md`
- **Status**: Must be executable in sequence

### Configuration Documents (02-configuration/)
- **Purpose**: Detailed configuration for each tool
- **Metadata**: `category: configuration`
- **Structure**: Grouped by tool type
- **Includes**: GUI settings, CLI commands, templates

### Automation Scripts (03-automation/)
- **Purpose**: Executable automation
- **Metadata**: `category: automation`
- **Requirements**: Must be idempotent
- **Testing**: Include validation steps

### Policy Documents (04-policies/)
- **Purpose**: System requirements and rules
- **Metadata**: `category: policy`
- **Format**: Human and machine-readable
- **Validation**: Automated compliance checks

### Reference Documents (05-reference/)
- **Purpose**: Supplementary information
- **Metadata**: `category: reference`
- **Content**: Troubleshooting, FAQs, guides

### Templates (06-templates/)
- **Purpose**: Reusable configurations
- **Metadata**: `category: template`
- **Usage**: Referenced by setup/config docs

### Reports (07-reports/)
- **Purpose**: System state and progress
- **Metadata**: `category: report`
- **Generation**: Automated where possible
- **Frequency**: On change or scheduled

## 🔄 Synchronization Strategy

### Active System Integration

1. **Chezmoi Bridge**
   ```bash
   # Sync from active dotfiles
   ~/.local/share/chezmoi/ → 06-templates/chezmoi/
   ```

2. **Configuration Export**
   ```bash
   # Export current configs
   ./03-automation/scripts/export-config.sh
   ```

3. **Status Reporting**
   ```bash
   # Generate current status
   ./03-automation/scripts/generate-report.sh
   ```

### Version Control Strategy

- **Main Branch**: Stable, tested configurations
- **Feature Branches**: New tools/configs
- **Tags**: System milestones (e.g., `v2.0.0-m3-optimized`)

## 📝 Documentation Standards

### File Naming
- Lowercase with hyphens: `tool-name-config.md`
- Numbered for sequence: `01-first-step.md`
- Categories in paths: `configuration/terminals/iterm2.md`

### Content Structure
1. Frontmatter (metadata)
2. Purpose statement
3. Prerequisites
4. Main content
5. Validation steps
6. Troubleshooting
7. Related documents

### Cross-References
```markdown
<!-- Link to related doc -->
See [Fish Shell Setup](../01-setup/03-fish-shell.md)

<!-- Link with context -->
After completing [Homebrew](../01-setup/01-homebrew.md#verification),
proceed to...
```

## 🚀 Quick Actions

### Generate Index
```bash
./03-automation/scripts/generate-index.sh
```

### Validate Structure
```bash
./03-automation/scripts/validate-structure.sh
```

### Check Compliance
```bash
python 04-policies/compliance-check.py
```

### Update Reports
```bash
./03-automation/scripts/update-reports.sh
```

## 🎯 Key Principles

1. **Single Source of Truth**: This repo is the authoritative documentation
2. **Executable Documentation**: All guides must be actionable
3. **Automated Validation**: Scripts verify documentation accuracy
4. **Living Documentation**: Reflects current system state
5. **Progressive Disclosure**: Basic → Advanced organization
6. **Dependency Tracking**: Clear prerequisites and relationships
7. **Version Awareness**: Track what works with what versions

## 🔗 Integration Points

- **Chezmoi**: Templates and configurations
- **GitHub Actions**: CI/CD for validation
- **System Scripts**: Automation tools
- **Policy Engine**: Compliance checking
- **Status Dashboard**: Current state visibility

This structure ensures the repository serves as both comprehensive documentation and active system management tool.