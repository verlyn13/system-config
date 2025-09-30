---
title: Repository Management Framework
category: governance
component: repository
status: active
version: 1.0.0
last_updated: 2025-09-30
tags: [governance, automation, settings]
priority: high
---

# Repository Management Framework

## Overview

This document defines the repository governance framework for the system-setup-update project and its 38 managed repositories.

## Repository Settings Automation

### Probot: Settings Integration

The repository uses [Probot: Settings](https://probot.github.io/apps/settings/) to manage repository configuration as code:

- **Configuration**: `.github/settings.yml`
- **Triggers**: Automatic on push to main branch
- **Scope**: Repository settings, branch protection, labels, environments

### Branch Protection Strategy

**Main Branch Protection:**
- ✅ Required status checks (strict)
- ✅ Require pull request reviews (1 approver)
- ✅ Dismiss stale reviews
- ✅ No force pushes or deletions
- ❌ Admin enforcement disabled (for emergency access)

**Required Status Checks:**
- `Validate JSON Schemas`
- `Lint OpenAPI`
- `System Validation`
- `Convention Checks`
- `Contract Validation`

## Multi-Repository Management

### Repository Classification

Based on the 38-repository analysis:

```yaml
Workspace Distribution:
  personal/: ~30 repositories
  work/: ~8 repositories

Technology Stack:
  - Node.js projects: ~15 repositories
  - Python projects: ~8 repositories
  - Go projects: ~5 repositories
  - Generic/Config: ~10 repositories
```

### Standardization Strategy

**Phase 1: Environment Alignment** ✅
- Standard `.envrc` with embedded `use_mise()` function
- Trusted `.mise.toml` configurations
- Consistent PATH and environment setup

**Phase 2: Governance Propagation** (Recommended)
- Core repositories get similar governance rules
- Shared workflow templates
- Consistent labeling and issue templates

**Phase 3: Automation Scaling** (Future)
- Repository template system
- Bulk settings management
- Compliance monitoring across all repos

## Implementation Steps

### 1. Install Probot: Settings App

```bash
# Navigate to GitHub App installation
# https://github.com/apps/settings
# Install on verlyn13/system-setup-update repository
```

### 2. Validate Current Configuration

```bash
# Test governance workflow
gh workflow run repository-governance.yml

# Verify settings file
python3 -c "import yaml; yaml.safe_load(open('.github/settings.yml'))"
```

### 3. Monitor Application

After Probot installation, changes to `.github/settings.yml` will automatically:
- Update repository settings
- Apply branch protection rules
- Sync labels and environments
- Create audit log entries

## Security Considerations

### Access Control
- **CODEOWNERS**: Protects critical configuration files
- **Required Reviews**: All governance changes need approval
- **Status Checks**: Prevent broken configurations

### Audit Trail
- All setting changes tracked in repository history
- Probot provides additional audit logging
- GitHub security alerts enabled

### Emergency Procedures
- Admin bypass disabled for normal operation
- Emergency access via GitHub enterprise controls
- Local repository recovery procedures documented

## Compliance Integration

### Policy Alignment
The governance framework enforces the policy requirements from `04-policies/policy-as-code.yaml`:

- **Repository Security**: Branch protection, required reviews
- **Change Management**: Controlled via pull requests and status checks
- **Documentation**: All governance decisions documented
- **Automation**: Settings managed as code, not manual clicks

### Validation
The `03-automation/scripts/validate-system.py` script includes repository governance checks:

```python
def validate_repo_governance(self):
    """Ensure repository governance standards are met"""
    # Check for settings.yml existence
    # Validate CODEOWNERS syntax
    # Verify required workflows exist
```

## Multi-Repo Scaling Strategy

### Immediate Actions (Next 30 days)
1. **Core Repository Governance**: Apply similar settings to top 5 active repositories
2. **Template Creation**: Build repository template with standard governance
3. **Workflow Standardization**: Create shared workflow templates

### Medium-term (30-90 days)
1. **Bulk Management Tool**: Script to apply governance across repository families
2. **Compliance Dashboard**: Monitor governance compliance across all 38 repos
3. **Automated Onboarding**: New repository automatic governance application

### Long-term (90+ days)
1. **Organization-wide Policies**: GitHub organization-level governance rules
2. **Cross-repository Dependencies**: Manage shared contracts and schemas
3. **Advanced Automation**: AI-assisted governance and compliance monitoring

## Monitoring and Maintenance

### Health Checks
- **Weekly**: Repository settings compliance scan
- **Monthly**: Access review and permission audit
- **Quarterly**: Governance framework effectiveness review

### Metrics
- Pull request review compliance rate
- Status check pass/fail ratios
- Time to resolve governance violations
- Repository setting drift detection

## Troubleshooting

### Common Issues
1. **Probot Not Responding**: Check app installation and permissions
2. **Status Check Failures**: Verify workflow names match settings.yml
3. **CODEOWNERS Syntax**: Validate with `.github/workflows/repository-governance.yml`

### Recovery Procedures
1. **Settings Corruption**: Restore from git history, manual GitHub fixes
2. **Branch Protection Bypass**: Emergency admin access, audit trail required
3. **Workflow Failures**: Temporary protection rule relaxation with immediate fix

## Related Documentation
- [Contract Freeze Guide](../guides/contract-freeze-howto.md)
- [System Validation Policy](../../04-policies/policy-as-code.yaml)
- [Multi-repo Environment Alignment](../../scripts/multirepo-align-env.sh)