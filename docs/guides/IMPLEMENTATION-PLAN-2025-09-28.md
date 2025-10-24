---
title: Implementation Plan 2025 09 28
category: reference
component: implementation_plan_2025_09_28
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

# System Implementation Plan
**Created**: 2025-09-28
**Type**: Action Plan
**Priority**: High
**Timeline**: 2 weeks

## Executive Summary
This plan addresses all outstanding system issues discovered during the 2025-09-28 audit. The system is more mature than documentation indicated - Phase 5 (Security) and Phase 6 (Containers) are already complete. The main work involves inbox processing, minor configurations, and documentation alignment.

## Current System State

### Strengths (No Action Needed)
- ✅ **Security Stack**: gopass v1.15.18, age v1.2.1, GPG, SSH multi-account
- ✅ **Container Tools**: Docker v28.3.3, OrbStack, kubectl v1.34.1
- ✅ **Shell Performance**: 122ms startup (under 150ms target)
- ✅ **Automation**: Comprehensive LaunchAgent setup with MCP services
- ✅ **Claude Integration**: Full MCP server setup with multiple services

### Issues to Address
- ⚠️ **Inbox Overload**: 75+ files requiring organization
- ⚠️ **Documentation Drift**: Phases 5-6 marked incomplete but are actually done
- ⚠️ **Android Setup**: Installer present but not executed
- ⚠️ **Claude Environment**: `.claude/environment.sh` functionality unclear

## Implementation Phases

### Phase 1: Critical Inbox Processing (Day 1-2)
**Goal**: Secure sensitive files and clear critical items

#### 1.1 Security Files (IMMEDIATE)
```bash
# Move SSH keys to proper location
mv ~/00_inbox/id_ed25519_work* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519_work
chmod 644 ~/.ssh/id_ed25519_work.pub

# Process credential files through gopass
gopass insert work/maat-flex < ~/00_inbox/maat-flex-key.json
gopass insert work/maat-genai < ~/00_inbox/maat-genai-key.json
rm ~/00_inbox/maat-*.json  # Secure delete after storing
```

#### 1.2 Brewfiles Organization
```bash
# Review and consolidate Brewfiles
diff ~/00_inbox/Brewfile ~/workspace/dotfiles/Brewfile
# If newer, update dotfiles version
mv ~/00_inbox/Brewfile* ~/archive/2025/brewfiles/
```

#### 1.3 Documentation Files
```bash
# Move setup documentation to library
mkdir -p ~/library/docs/setup-history
mv ~/00_inbox/*.md ~/library/docs/setup-history/
```

### Phase 2: Tool Installation & Configuration (Day 3-4)
**Goal**: Complete pending installations and optimize configurations

#### 2.1 Android Development Setup
```bash
# Install Android Studio from existing DMG
hdiutil mount ~/00_inbox/android-studio-*.dmg
cp -R /Volumes/Android\ Studio/Android\ Studio.app /Applications/
hdiutil unmount /Volumes/Android\ Studio/
rm ~/00_inbox/android-studio-*.dmg

# Configure Android SDK via mise
mise install java@17  # Already done
# Set ANDROID_HOME in mise config
```

#### 2.2 Helm Installation (Kubernetes Management)
```bash
brew install helm
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

#### 2.3 Claude Environment Resolution
```yaml
# Investigation needed:
# 1. Determine if .claude/environment.sh is needed
# 2. If yes, create template for project-specific Claude configs
# 3. If no, remove commented code from Fish config

# Proposed solution: Create optional project Claude configs
# ~/.config/fish/functions/claude_project_env.fish
function claude_project_env
    if test -f .claude/environment.sh
        # Use native Fish instead of bass
        source .claude/environment.fish
    end
end
```

### Phase 3: Inbox Deep Clean (Day 5-6)
**Goal**: Process remaining 70+ files systematically

#### 3.1 Large Installers
```bash
# Chrome installer - verify if needed
if not test -d /Applications/Google\ Chrome.app
    # Install from DMG
else
    rm ~/00_inbox/googlechrome.dmg
end
```

#### 3.2 Trinity CLI/SDK Files
```bash
# Organize Trinity development files
mkdir -p ~/Development/work/trinity-cli
mv ~/00_inbox/trinity* ~/Development/work/trinity-cli/
cd ~/Development/work/trinity-cli && git init
```

#### 3.3 Scripts Categorization
```bash
# Review each script for utility vs one-off
for script in ~/00_inbox/*.sh
    # Read header comments
    # If utility: mv to ~/workspace/scripts/
    # If one-off: mv to ~/archive/2025/scripts/
end
```

### Phase 4: System Optimization (Day 7-8)
**Goal**: Fine-tune performance and automation

#### 4.1 Fish Shell Optimization
```fish
# Remove unused functions
fisher list | grep -v essential | xargs fisher remove

# Profile startup time
fish --profile-startup=/tmp/fish-profile.txt -c exit
# Analyze and optimize slow components
```

#### 4.2 Mise Optimization
```bash
# Update to latest
mise self-update

# Prune unused versions
mise prune --yes

# Configure trust for all Development directories
mise trust ~/Development/**/.mise.toml
```

#### 4.3 LaunchAgent Audit
```bash
# Review all LaunchAgents
launchctl list | grep com.mcp
# Disable any unused services
# Document active services in MAINTENANCE-GUIDE.md
```

### Phase 5: Documentation Reconciliation (Day 9-10)
**Goal**: Align documentation with reality

#### 5.1 Update Phase Status
- Mark Phase 5 (Security) as COMPLETE
- Mark Phase 6 (Containers) as COMPLETE
- Update Phase 7 (Android) progress after installation
- Document actual vs planned implementations

#### 5.2 Create Maintenance Runbooks
```markdown
# Weekly Maintenance (Sunday 5pm)
1. Process ~/00_inbox/ items
2. Run mise prune
3. Update tool versions
4. Review LaunchAgent logs
5. Archive completed work
```

#### 5.3 Update CLAUDE.md Files
- Document Claude MCP server integrations
- Add troubleshooting guides
- Include project-specific Claude setup instructions

### Phase 6: Validation & Testing (Day 11-12)
**Goal**: Ensure all changes work correctly

#### 6.1 Security Validation
```bash
# Test gopass
gopass ls
gopass health

# Test age encryption
echo "test" | age -r $(age-keygen -y ~/.ssh/id_ed25519_work) | age -d -i ~/.ssh/id_ed25519_work

# Test SSH multi-account
ssh -T git@github.com
ssh -T git@github-work
```

#### 6.2 Container Validation
```bash
# Docker
docker run --rm hello-world
docker-compose version

# Kubernetes
kubectl cluster-info
helm list
```

#### 6.3 System Health Check
```bash
# Run comprehensive check
~/Development/personal/system-setup-update/scripts/daily-check.sh

# Measure metrics
system-check  # Custom system health command
```

## Success Criteria

### Quantitative Metrics
- [ ] Inbox: 0 items (from 75+)
- [ ] Shell startup: <150ms maintained
- [ ] All phases documented accurately
- [ ] 95% policy compliance achieved

### Qualitative Goals
- [ ] No sensitive files in wrong locations
- [ ] All tools accessible via mise/PATH
- [ ] Documentation reflects reality
- [ ] Maintenance processes documented

## Risk Mitigation

### Backup Strategy
```bash
# Before major changes
tar -czf ~/archive/2025/pre-implementation-backup.tar.gz \
    ~/.ssh ~/.config ~/.local/share/chezmoi
```

### Rollback Plan
- Chezmoi: `chezmoi git checkout HEAD~1`
- Mise: Version rollback supported
- Configs: Backed up in archive

### Testing Approach
- Test in isolated environment first
- Validate each phase independently
- Keep detailed logs of changes

## Timeline & Milestones

| Week | Phase | Deliverable | Validation |
|------|-------|-------------|------------|
| Week 1 (Days 1-6) | 1-3 | Inbox cleared, tools installed | Security tests pass |
| Week 2 (Days 7-12) | 4-6 | System optimized, docs updated | All metrics met |

## Next Steps

1. **Immediate** (Today):
   - Move SSH keys to ~/.ssh/
   - Store credentials in gopass
   - Start Android Studio installation

2. **Tomorrow**:
   - Process documentation files
   - Begin script categorization
   - Install Helm

3. **This Week**:
   - Complete inbox processing
   - Update all documentation
   - Run validation tests

## Notes

- The system is more mature than initially documented
- Focus on organization and documentation rather than installation
- Maintain system discipline - follow the inbox workflow
- Schedule regular audits to prevent future drift

## Appendix: Command Reference

### Useful Commands for Implementation
```bash
# Check inbox status
ls -la ~/00_inbox/ | wc -l

# Find large files
find ~/00_inbox -size +100M -exec ls -lh {} \;

# Test all SSH connections
for host in github.com github-work github-business; do
    ssh -T git@$host 2>&1 | grep -E "success|authenticated"
done

# Measure current compliance
~/Development/personal/system-setup-update/scripts/validate-system.py
```

---
*This plan is based on the comprehensive audit conducted on 2025-09-28 and reflects the actual system state rather than outdated documentation.*