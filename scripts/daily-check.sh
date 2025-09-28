#!/usr/bin/env bash
# Daily System Health Check
# Runs automatically via cron or manually for system validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/daily-check-$(date +%Y-%m-%d).log"
REPORT_FILE="$PROJECT_ROOT/DAILY-REPORT.md"

# Ensure log directory exists
mkdir -p "$PROJECT_ROOT/logs"

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Header
log "${BLUE}════════════════════════════════════════════════════════════════${NC}"
log "${BLUE}                    Daily System Health Check                     ${NC}"
log "${BLUE}                    $(date '+%Y-%m-%d %H:%M:%S')                  ${NC}"
log "${BLUE}════════════════════════════════════════════════════════════════${NC}"
log ""

# 1. Check Policy Compliance
log "${YELLOW}▶ Running Policy Compliance Check...${NC}"
cd "$PROJECT_ROOT"
if python 04-policies/validate-policy.py > /tmp/compliance-output.txt 2>&1; then
    COMPLIANCE_SCORE=$(grep "Compliance Score:" /tmp/compliance-output.txt | grep -o '[0-9.]*%' || echo "0%")
    log "${GREEN}✓ Compliance Score: $COMPLIANCE_SCORE${NC}"
else
    log "${RED}✗ Compliance check failed${NC}"
    COMPLIANCE_SCORE="Failed"
fi
log ""

# 2. Check System Resources
log "${YELLOW}▶ Checking System Resources...${NC}"

# CPU Usage
CPU_USAGE=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
if (( $(echo "$CPU_USAGE < 80" | bc -l) )); then
    log "${GREEN}✓ CPU Usage: ${CPU_USAGE}%${NC}"
else
    log "${RED}✗ High CPU Usage: ${CPU_USAGE}%${NC}"
fi

# Memory Usage
MEMORY_INFO=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages free:\s+(\d+)/ and $free=$1; /Pages active:\s+(\d+)/ and $active=$1; /Pages inactive:\s+(\d+)/ and $inactive=$1; /Pages wired down:\s+(\d+)/ and $wired=$1; END { $total=($free+$active+$inactive+$wired)*$size/1048576; $used=($active+$wired)*$size/1048576; printf "%.1f %.1f", $used, $total }')
MEMORY_USED=$(echo $MEMORY_INFO | awk '{print $1}')
MEMORY_TOTAL=$(echo $MEMORY_INFO | awk '{print $2}')
MEMORY_PERCENT=$(echo "scale=1; ($MEMORY_USED / $MEMORY_TOTAL) * 100" | bc)

if (( $(echo "$MEMORY_PERCENT < 90" | bc -l) )); then
    log "${GREEN}✓ Memory Usage: ${MEMORY_PERCENT}% (${MEMORY_USED}MB / ${MEMORY_TOTAL}MB)${NC}"
else
    log "${RED}✗ High Memory Usage: ${MEMORY_PERCENT}%${NC}"
fi

# Disk Usage
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 85 ]; then
    log "${GREEN}✓ Disk Usage: ${DISK_USAGE}%${NC}"
else
    log "${RED}✗ High Disk Usage: ${DISK_USAGE}%${NC}"
fi
log ""

# 3. Check Core Services
log "${YELLOW}▶ Checking Core Services...${NC}"

# Homebrew
if command -v brew &> /dev/null; then
    BREW_VERSION=$(brew --version | head -1 | awk '{print $2}')
    log "${GREEN}✓ Homebrew: $BREW_VERSION${NC}"
else
    log "${RED}✗ Homebrew: Not installed${NC}"
fi

# Mise
if command -v mise &> /dev/null; then
    MISE_VERSION=$(mise --version 2>/dev/null | awk '{print $1}')
    log "${GREEN}✓ Mise: $MISE_VERSION${NC}"
else
    log "${RED}✗ Mise: Not installed${NC}"
fi

# Docker (via OrbStack)
if docker info &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    log "${GREEN}✓ Docker: $DOCKER_VERSION (running)${NC}"
else
    log "${YELLOW}⚠ Docker: Not running${NC}"
fi

# Chezmoi
if command -v chezmoi &> /dev/null; then
    CHEZMOI_STATUS=$(chezmoi status --no-pager 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHEZMOI_STATUS" -eq 0 ]; then
        log "${GREEN}✓ Chezmoi: In sync${NC}"
    else
        log "${YELLOW}⚠ Chezmoi: $CHEZMOI_STATUS files changed${NC}"
    fi
else
    log "${RED}✗ Chezmoi: Not installed${NC}"
fi
log ""

# 4. Check Inbox Status
log "${YELLOW}▶ Checking Inbox...${NC}"
INBOX_COUNT=$(find ~/00_inbox -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$INBOX_COUNT" -eq 0 ]; then
    log "${GREEN}✓ Inbox: Empty${NC}"
else
    log "${YELLOW}⚠ Inbox: $INBOX_COUNT items pending${NC}"
fi
log ""

# 5. Check for Updates
log "${YELLOW}▶ Checking for Updates...${NC}"

# Homebrew updates
BREW_OUTDATED=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')
if [ "$BREW_OUTDATED" -eq 0 ]; then
    log "${GREEN}✓ Homebrew: All packages up to date${NC}"
else
    log "${YELLOW}⚠ Homebrew: $BREW_OUTDATED packages outdated${NC}"
fi

# Mise updates
MISE_OUTDATED=$(mise outdated 2>/dev/null | wc -l | tr -d ' ')
if [ "$MISE_OUTDATED" -le 1 ]; then  # Header line
    log "${GREEN}✓ Mise: All tools up to date${NC}"
else
    log "${YELLOW}⚠ Mise: $(($MISE_OUTDATED - 1)) tools have updates${NC}"
fi
log ""

# 6. Generate Daily Report
log "${YELLOW}▶ Generating Daily Report...${NC}"

cat > "$REPORT_FILE" << EOF
# Daily System Report
**Date**: $(date '+%Y-%m-%d %H:%M:%S')
**Hostname**: $(hostname)

## System Health
- **Compliance Score**: $COMPLIANCE_SCORE
- **CPU Usage**: ${CPU_USAGE}%
- **Memory Usage**: ${MEMORY_PERCENT}%
- **Disk Usage**: ${DISK_USAGE}%

## Service Status
- **Homebrew**: ${BREW_VERSION:-Not installed}
- **Mise**: ${MISE_VERSION:-Not installed}
- **Docker**: ${DOCKER_VERSION:-Not running}
- **Chezmoi**: ${CHEZMOI_STATUS:-0} changes pending

## Pending Tasks
- **Inbox Items**: $INBOX_COUNT
- **Outdated Packages**: $BREW_OUTDATED
- **Outdated Tools**: $(($MISE_OUTDATED - 1))

## Recommendations
EOF

# Add recommendations based on findings
if [ "$INBOX_COUNT" -gt 5 ]; then
    echo "- Review and process inbox items (${INBOX_COUNT} pending)" >> "$REPORT_FILE"
fi

if [ "$BREW_OUTDATED" -gt 0 ]; then
    echo "- Run \`brew upgrade\` to update packages" >> "$REPORT_FILE"
fi

if [ "$MISE_OUTDATED" -gt 1 ]; then
    echo "- Run \`mise upgrade\` to update tools" >> "$REPORT_FILE"
fi

if [ "$CHEZMOI_STATUS" -gt 0 ]; then
    echo "- Run \`chezmoi apply\` to sync dotfiles" >> "$REPORT_FILE"
fi

if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "- Investigate high CPU usage (${CPU_USAGE}%)" >> "$REPORT_FILE"
fi

if (( $(echo "$MEMORY_PERCENT > 90" | bc -l) )); then
    echo "- Investigate high memory usage (${MEMORY_PERCENT}%)" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "*Generated by daily-check.sh*" >> "$REPORT_FILE"

log "${GREEN}✓ Report saved to: $REPORT_FILE${NC}"
log ""

# Summary
log "${BLUE}════════════════════════════════════════════════════════════════${NC}"
log "${BLUE}                          Check Complete                          ${NC}"
log "${BLUE}════════════════════════════════════════════════════════════════${NC}"

# Exit code based on critical issues
if [ "$COMPLIANCE_SCORE" = "Failed" ] || [ "$DISK_USAGE" -gt 90 ] || (( $(echo "$MEMORY_PERCENT > 95" | bc -l) )); then
    exit 1
fi

exit 0