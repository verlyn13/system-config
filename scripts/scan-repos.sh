#!/bin/bash
# Repository Scanner - Comprehensive Git Status Check
# Generated: 2025-09-26

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output files
REPORT_DIR="$HOME/Development/personal/system-setup-update/07-reports"
SCAN_REPORT="$REPORT_DIR/repo-scan-$(date +%Y-%m-%d).json"
SUMMARY_REPORT="$REPORT_DIR/repo-scan-summary-$(date +%Y-%m-%d).md"

# Initialize report
echo "[]" > "$SCAN_REPORT"

# Counter variables
total_repos=0
repos_with_changes=0
repos_behind=0
repos_ahead=0
repos_diverged=0
repos_clean=0
repos_no_remote=0

echo -e "${BLUE}=== Repository Scanner ===${NC}"
echo -e "${BLUE}Scanning all Git repositories in ~/Development...${NC}\n"

# Function to check repo status
check_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    local profile=$(basename $(dirname "$repo_path"))

    cd "$repo_path"

    # Get basic info
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local has_remote=$(git remote -v 2>/dev/null | grep -c origin || echo "0")
    local last_commit_date=$(git log -1 --format=%ci 2>/dev/null || echo "unknown")

    # Check for uncommitted changes
    local uncommitted=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # Check remote status if exists
    local behind=0
    local ahead=0
    if [ "$has_remote" -gt "0" ]; then
        git fetch --quiet 2>/dev/null || true
        behind=$(git rev-list HEAD..origin/"$current_branch" 2>/dev/null | wc -l | tr -d ' ')
        ahead=$(git rev-list origin/"$current_branch"..HEAD 2>/dev/null | wc -l | tr -d ' ')
        # Ensure values are numbers
        behind=${behind:-0}
        ahead=${ahead:-0}
    fi

    # Determine status
    local status="clean"
    if [ "$uncommitted" -gt "0" ]; then
        status="uncommitted"
        ((repos_with_changes++))
    elif [ "$behind" -gt "0" ] && [ "$ahead" -gt "0" ]; then
        status="diverged"
        ((repos_diverged++))
    elif [ "$behind" -gt "0" ]; then
        status="behind"
        ((repos_behind++))
    elif [ "$ahead" -gt "0" ]; then
        status="ahead"
        ((repos_ahead++))
    elif [ "$has_remote" -eq "0" ]; then
        status="no-remote"
        ((repos_no_remote++))
    else
        ((repos_clean++))
    fi

    # Create JSON entry
    local json_entry=$(cat <<EOF
{
  "name": "$repo_name",
  "path": "$repo_path",
  "profile": "$profile",
  "branch": "$current_branch",
  "status": "$status",
  "uncommitted": $uncommitted,
  "untracked": $untracked,
  "behind": $behind,
  "ahead": $ahead,
  "has_remote": $(if [ "$has_remote" -gt "0" ]; then echo "true"; else echo "false"; fi),
  "last_commit": "$last_commit_date"
}
EOF
    )

    # Append to report (using jq to maintain valid JSON array)
    local current=$(cat "$SCAN_REPORT")
    echo "$current" | jq ". += [$json_entry]" > "$SCAN_REPORT"

    # Print status
    case "$status" in
        "uncommitted")
            echo -e "${YELLOW}⚠️  $profile/$repo_name${NC} - $uncommitted uncommitted changes, $untracked untracked files"
            ;;
        "behind")
            echo -e "${RED}⬇️  $profile/$repo_name${NC} - $behind commits behind remote"
            ;;
        "ahead")
            echo -e "${BLUE}⬆️  $profile/$repo_name${NC} - $ahead commits ahead of remote"
            ;;
        "diverged")
            echo -e "${RED}🔄 $profile/$repo_name${NC} - diverged: $behind behind, $ahead ahead"
            ;;
        "no-remote")
            echo -e "${YELLOW}🏝️  $profile/$repo_name${NC} - no remote configured"
            ;;
        "clean")
            echo -e "${GREEN}✓  $profile/$repo_name${NC} - clean"
            ;;
    esac
}

# Scan all profiles
for profile_dir in ~/Development/*/; do
    profile=$(basename "$profile_dir")
    echo -e "\n${BLUE}Scanning $profile profile...${NC}"

    for repo_dir in "$profile_dir"*/; do
        if [ -d "$repo_dir/.git" ]; then
            ((total_repos++))
            check_repo "$repo_dir"
        fi
    done
done

# Generate summary report
cat > "$SUMMARY_REPORT" <<EOF
# Repository Scan Report
**Date**: $(date +"%Y-%m-%d %H:%M:%S")
**Total Repositories**: $total_repos

## Summary Statistics

| Status | Count | Percentage |
|--------|-------|------------|
| Clean | $repos_clean | $(echo "scale=1; $repos_clean * 100 / $total_repos" | bc)% |
| Uncommitted Changes | $repos_with_changes | $(echo "scale=1; $repos_with_changes * 100 / $total_repos" | bc)% |
| Behind Remote | $repos_behind | $(echo "scale=1; $repos_behind * 100 / $total_repos" | bc)% |
| Ahead of Remote | $repos_ahead | $(echo "scale=1; $repos_ahead * 100 / $total_repos" | bc)% |
| Diverged | $repos_diverged | $(echo "scale=1; $repos_diverged * 100 / $total_repos" | bc)% |
| No Remote | $repos_no_remote | $(echo "scale=1; $repos_no_remote * 100 / $total_repos" | bc)% |

## Repositories Requiring Attention

### ⚠️ Uncommitted Changes
EOF

# Add repos with uncommitted changes to report
jq -r '.[] | select(.status == "uncommitted") | "- **\(.profile)/\(.name)**: \(.uncommitted) uncommitted, \(.untracked) untracked"' "$SCAN_REPORT" >> "$SUMMARY_REPORT"

cat >> "$SUMMARY_REPORT" <<EOF

### ⬇️ Behind Remote
EOF

jq -r '.[] | select(.status == "behind") | "- **\(.profile)/\(.name)**: \(.behind) commits behind"' "$SCAN_REPORT" >> "$SUMMARY_REPORT"

cat >> "$SUMMARY_REPORT" <<EOF

### 🔄 Diverged from Remote
EOF

jq -r '.[] | select(.status == "diverged") | "- **\(.profile)/\(.name)**: \(.behind) behind, \(.ahead) ahead"' "$SCAN_REPORT" >> "$SUMMARY_REPORT"

# Print summary
echo -e "\n${BLUE}=== Scan Complete ===${NC}"
echo -e "Total repositories: ${BLUE}$total_repos${NC}"
echo -e "Clean: ${GREEN}$repos_clean${NC}"
echo -e "With uncommitted changes: ${YELLOW}$repos_with_changes${NC}"
echo -e "Behind remote: ${RED}$repos_behind${NC}"
echo -e "Ahead of remote: ${BLUE}$repos_ahead${NC}"
echo -e "Diverged: ${RED}$repos_diverged${NC}"
echo -e "No remote: ${YELLOW}$repos_no_remote${NC}"
echo -e "\nDetailed report saved to:"
echo -e "  JSON: ${BLUE}$SCAN_REPORT${NC}"
echo -e "  Summary: ${BLUE}$SUMMARY_REPORT${NC}"