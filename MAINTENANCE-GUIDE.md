# 🔧 System Maintenance Guide
**Version**: 1.0.0 | **Updated**: 2025-09-26 | **Status**: ACTIVE

---

## 🎯 Quick Navigation

| Resource | Purpose | Access |
|----------|---------|--------|
| **[Master Status](MASTER-STATUS.md)** | Current system state | Single source of truth |
| **[Live Dashboard](http://localhost:5173)** | Real-time monitoring | `cd ~/Development/personal/system-dashboard && bun run dev` |
| **[Policy Validation](#daily-checks)** | Compliance checking | `python 04-policies/validate-policy.py` |
| **[Documentation Index](INDEX.md)** | Complete documentation | Full navigation |

---

## 📅 Maintenance Schedule

### Daily Tasks (Automated)
```bash
# Morning Health Check (cron: 0 9 * * *)
~/Development/personal/system-setup-update/scripts/daily-check.sh

# Evening Backup (cron: 0 18 * * *)
chezmoi git add . && chezmoi git commit -m "Daily backup $(date +%Y-%m-%d)"
```

### Weekly Tasks (Sunday 5pm)
- [ ] Review inbox (`~/00_inbox`)
- [ ] Update system packages (`brew upgrade && mise upgrade`)
- [ ] Check dashboard metrics
- [ ] Archive completed projects
- [ ] Update documentation

### Monthly Tasks (First Monday)
- [ ] Full system audit (`python 04-policies/validate-policy.py`)
- [ ] Security review (`gopass audit`)
- [ ] Disk cleanup (`brew cleanup && docker system prune`)
- [ ] Update MASTER-STATUS.md
- [ ] Review and update policies

### Quarterly Tasks
- [ ] Major version updates
- [ ] Policy review and revision
- [ ] Disaster recovery test
- [ ] Performance optimization review

---

## 🔍 System Discovery

### Where to Find Things

#### **Configuration Files**
```bash
# Dotfiles (source of truth)
~/.local/share/chezmoi/          # Chezmoi templates
~/.config/chezmoi/chezmoi.toml   # Machine-specific config

# Active configs
~/.config/fish/                  # Fish shell
~/.config/mise/                  # Version management
~/.config/iterm2/                # Terminal
~/.gitconfig                     # Git
~/.ssh/config                    # SSH
```

#### **Documentation**
```bash
# System setup docs
~/Development/personal/system-setup-update/
├── MASTER-STATUS.md             # Current state (START HERE)
├── MAINTENANCE-GUIDE.md         # This file
├── INDEX.md                     # Documentation index
├── 01-setup/                    # Setup guides
├── 02-configuration/            # Config details
├── 04-policies/                 # Policy definitions
└── 07-reports/                  # Status reports

# Dashboard
~/Development/personal/system-dashboard/  # Real-time monitoring
```

#### **Tools & Commands**
```bash
# Quick navigation
dev         # cd ~/Development
inbox       # cd ~/00_inbox
dots        # cd ~/workspace/dotfiles
work        # cd ~/workspace

# System checks
mise doctor
chezmoi doctor
direnv status
brew doctor

# Updates
chezmoi update    # Pull dotfiles
brew upgrade      # Update packages
mise upgrade      # Update runtimes
```

---

## 🚨 Common Maintenance Tasks

### 1. Check System Health
```bash
# Quick health check
python 04-policies/validate-policy.py

# Detailed status
open http://localhost:5173  # Dashboard

# Manual verification
mise ls          # Check installed versions
brew list        # Check packages
chezmoi status   # Check dotfile changes
```

### 2. Update Everything
```bash
# Full system update
brew update && brew upgrade
mise upgrade
chezmoi update
bun upgrade

# Clean up
brew cleanup
docker system prune -a
rm -rf ~/00_inbox/*_processed
```

### 3. Add New Tool/Package
```bash
# 1. Install via appropriate manager
brew install <package>       # System tools
mise use <tool>@<version>    # Language/runtime

# 2. Update documentation
vim ~/Development/personal/system-setup-update/MASTER-STATUS.md

# 3. Update policy if needed
vim 04-policies/policy-as-code.yaml

# 4. Commit changes
chezmoi add ~/.config/
chezmoi commit -m "Add <tool>"
```

### 4. Fix Compliance Issues
```bash
# Run validation
python 04-policies/validate-policy.py

# Review failures in report
cat compliance-report.md

# Fix based on issue type:
# - Missing directory: mkdir -p <path>
# - Wrong version: mise use <tool>@<version>
# - Missing config: chezmoi add <file>
```

### 5. Backup & Recovery
```bash
# Backup current state
chezmoi git add .
chezmoi git commit -m "Backup: $(date +%Y-%m-%d)"
chezmoi git push

# Disaster recovery
chezmoi init --apply git@github.com:yourusername/dotfiles.git
brew bundle --file=~/.local/share/chezmoi/Brewfile
mise install
```

---

## 📊 Monitoring & Alerts

### Dashboard Metrics to Watch
- **CPU Usage**: Alert if >80% sustained
- **Memory**: Alert if >90%
- **Disk**: Alert if any volume >85%
- **Compliance**: Alert if <95%
- **Chezmoi**: Alert if pending changes >5

### Log Locations
```bash
# System logs
/var/log/system.log              # macOS system
~/.local/state/mise/logs/        # Mise logs
~/Library/Logs/Homebrew/         # Homebrew logs

# Application logs
~/Development/personal/system-dashboard/logs/  # Dashboard logs
~/.config/fish/fish_history      # Shell history
```

---

## 🔄 Ongoing Work Integration

### Starting New Work
1. **Check current state**: `cat MASTER-STATUS.md`
2. **Verify compliance**: `python 04-policies/validate-policy.py`
3. **Open dashboard**: `open http://localhost:5173`
4. **Create in inbox**: `cd ~/00_inbox && touch new-work.md`
5. **Update documentation**: After implementation

### Project Workflow
```bash
# 1. Create new project
new-project <type> <name>

# 2. Work on project
cd ~/Development/<name>
# ... development ...

# 3. Document changes
echo "## $(date +%Y-%m-%d): <description>" >> PROJECT_LOG.md

# 4. Update system docs if needed
vim ~/Development/personal/system-setup-update/MASTER-STATUS.md
```

### Documentation Updates
Always update these when system changes:
1. **MASTER-STATUS.md** - Overall system state
2. **Policy files** - If new requirements
3. **This guide** - If new procedures
4. **Dashboard config** - If new metrics

---

## 🎛️ Dashboard Integration

The system dashboard at `~/Development/personal/system-dashboard/` provides:

### Real-time Monitoring
- System metrics (CPU, RAM, Disk, Network)
- Service status (all installed tools)
- Compliance score (policy validation)
- Chezmoi sync status

### Access Methods
```bash
# Start dashboard
cd ~/Development/personal/system-dashboard
bun run dev

# View in browser
open http://localhost:5173

# Check backend API
curl http://localhost:3001/api/system | jq
curl http://localhost:3001/api/compliance | jq
curl http://localhost:3001/api/chezmoi | jq
```

### Extending Dashboard
To add new metrics:
1. Update backend: `server/index.js`
2. Update frontend: `src/components/Dashboard.jsx`
3. Add to telemetry: `src/components/Telemetry.jsx`
4. Test: `bun test`

---

## 🔐 Security Maintenance

### Regular Security Tasks
```bash
# Check for secrets in code
git secrets --scan

# Audit password store
gopass audit

# Rotate age keys (quarterly)
age-keygen > ~/.config/age/key.txt.new
# ... migrate secrets ...
mv ~/.config/age/key.txt.new ~/.config/age/key.txt

# Update SSH keys (annually)
ssh-keygen -t ed25519 -C "email@example.com"
```

### Security Checklist
- [ ] No plain text secrets in repos
- [ ] Age key has correct permissions (600)
- [ ] SSH keys are Ed25519
- [ ] Gopass is locked when idle
- [ ] 2FA enabled on all accounts

---

## 🚀 Performance Optimization

### Regular Optimization
```bash
# Clean caches
brew cleanup -s
rm -rf ~/Library/Caches/*
rm -rf ~/.cache/*

# Optimize Git repos
find ~/Development -name .git -type d -exec git -C {} gc --aggressive \;

# Reset Spotlight
sudo mdutil -E /

# Clean Docker
docker system prune -a --volumes
```

### Performance Monitoring
```bash
# Check resource usage
htop                    # Interactive process viewer
iostat 5               # I/O statistics
vm_stat 5              # Virtual memory stats
nettop                 # Network usage

# Via dashboard
open http://localhost:5173/telemetry
```

---

## 📝 Troubleshooting Guide

### Common Issues & Fixes

#### Dashboard Not Loading
```bash
# Check if running
ps aux | grep "bun run dev"

# Restart
cd ~/Development/personal/system-dashboard
pkill -f "bun run dev"
bun run dev
```

#### Compliance Failures
```bash
# Re-run validation with verbose
python 04-policies/validate-policy.py --verbose

# Check specific tool
mise ls
brew list
chezmoi status
```

#### Performance Issues
```bash
# Check what's consuming resources
top -o cpu              # Sort by CPU
top -o mem              # Sort by memory

# Check disk space
df -h
du -sh ~/Development/*
```

#### Chezmoi Conflicts
```bash
# Check status
chezmoi status

# Diff changes
chezmoi diff

# Force apply (careful!)
chezmoi apply --force
```

---

## 📚 Quick Reference

### File Locations
| Type | Location | Purpose |
|------|----------|---------|
| **Status** | `MASTER-STATUS.md` | System state |
| **Policy** | `04-policies/policy-as-code.yaml` | Requirements |
| **Validation** | `04-policies/validate-policy.py` | Compliance check |
| **Dashboard** | `~/Development/personal/system-dashboard/` | Monitoring |
| **Dotfiles** | `~/.local/share/chezmoi/` | Config templates |

### Key Commands
| Command | Purpose |
|---------|---------|
| `python 04-policies/validate-policy.py` | Check compliance |
| `chezmoi status` | Check dotfile changes |
| `mise doctor` | Verify mise setup |
| `brew doctor` | Check Homebrew |
| `open http://localhost:5173` | Open dashboard |

### Support Resources
- [Documentation Index](INDEX.md)
- [Master Status](MASTER-STATUS.md)
- [Policy Definition](04-policies/policy-as-code.yaml)
- [Dashboard README](~/Development/personal/system-dashboard/README.md)

---

## ✅ Maintenance Completed Checklist

After each maintenance session:
- [ ] Updated MASTER-STATUS.md
- [ ] Ran policy validation
- [ ] Checked dashboard metrics
- [ ] Committed dotfile changes
- [ ] Updated documentation
- [ ] Cleared inbox if needed
- [ ] Logged work in this guide

---

*Last Maintenance: 2025-09-26*
*Next Scheduled: 2025-10-03*
*Compliance Score: 96.7%*