#!/bin/bash

# Comprehensive Git Repository Scanner
# Finds all repos and checks their status

echo "=== Git Repository Status Report ==="
echo "Date: $(date)"
echo "=================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Summary counters
total_repos=0
repos_with_changes=0
repos_with_unpushed=0
repos_behind=0
repos_diverged=0

# Arrays to store problematic repos
declare -a changed_repos
declare -a unpushed_repos
declare -a behind_repos
declare -a diverged_repos

# Function to check repo status
check_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    local has_issues=false

    cd "$repo_path" 2>/dev/null || return

    # Skip if not a git repo
    if [ ! -d .git ]; then
        return
    fi

    total_repos=$((total_repos + 1))

    # Get branch name
    branch=$(git branch --show-current 2>/dev/null || echo "unknown")

    # Check for uncommitted changes
    if ! git diff --quiet 2>/dev/null || ! git diff --staged --quiet 2>/dev/null; then
        has_issues=true
        repos_with_changes=$((repos_with_changes + 1))
        changed_repos+=("$repo_path")
    fi

    # Check for untracked files
    untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

    # Check for unpushed commits
    if git rev-parse --abbrev-ref @{u} &>/dev/null; then
        ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")

        if [ "$ahead" -gt 0 ]; then
            has_issues=true
            repos_with_unpushed=$((repos_with_unpushed + 1))
            unpushed_repos+=("$repo_path")
        fi

        if [ "$behind" -gt 0 ]; then
            has_issues=true
            repos_behind=$((repos_behind + 1))
            behind_repos+=("$repo_path")
        fi

        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
            repos_diverged=$((repos_diverged + 1))
            diverged_repos+=("$repo_path")
        fi
    else
        ahead="?"
        behind="?"
    fi

    # Only show repos with issues or if verbose
    if [ "$has_issues" = true ] || [ "$VERBOSE" = "1" ]; then
        echo -e "${BLUE}Repository:${NC} $repo_path"
        echo "  Branch: $branch"

        # Show uncommitted changes
        if ! git diff --quiet 2>/dev/null || ! git diff --staged --quiet 2>/dev/null; then
            echo -e "  ${RED}✗ Uncommitted changes${NC}"
            if [ "$VERBOSE" = "1" ]; then
                git status --short | head -5 | sed 's/^/    /'
            fi
        fi

        # Show untracked files
        if [ "$untracked" -gt 0 ]; then
            echo -e "  ${YELLOW}? Untracked files: $untracked${NC}"
        fi

        # Show push/pull status
        if [ "$ahead" != "?" ]; then
            if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
                echo -e "  ${RED}⇅ Diverged: $ahead ahead, $behind behind${NC}"
            elif [ "$ahead" -gt 0 ]; then
                echo -e "  ${YELLOW}↑ Unpushed commits: $ahead${NC}"
            elif [ "$behind" -gt 0 ]; then
                echo -e "  ${YELLOW}↓ Behind remote: $behind commits${NC}"
            fi
        else
            echo -e "  ${YELLOW}! No upstream branch${NC}"
        fi

        echo
    fi
}

# Scan all directories
echo "Scanning repositories..."
echo "========================"
echo

# Scan each major directory
for base_dir in ~/Development/personal ~/Development/work ~/Development/business ~/Development/business-org ~/Development/active ~/Development/happy-patterns-org; do
    if [ -d "$base_dir" ]; then
        echo "Scanning: $base_dir"
        # Find all git repos in this directory
        while IFS= read -r repo; do
            if [ -n "$repo" ]; then
                check_repo "$repo"
            fi
        done < <(find "$base_dir" -type d -name ".git" -maxdepth 2 2>/dev/null | sed 's/\/.git$//')
    fi
done

# Summary Report
echo "=================================="
echo "SUMMARY REPORT"
echo "=================================="
echo "Total repositories scanned: $total_repos"
echo
echo -e "${RED}Critical Issues:${NC}"
echo "  Repos with uncommitted changes: $repos_with_changes"
echo "  Repos with unpushed commits: $repos_with_unpushed"
echo "  Repos behind remote: $repos_behind"
echo "  Repos diverged from remote: $repos_diverged"
echo

# List problematic repos
if [ ${#changed_repos[@]} -gt 0 ]; then
    echo -e "${RED}Repositories with uncommitted changes:${NC}"
    printf '  %s\n' "${changed_repos[@]}"
    echo
fi

if [ ${#unpushed_repos[@]} -gt 0 ]; then
    echo -e "${YELLOW}Repositories with unpushed commits:${NC}"
    printf '  %s\n' "${unpushed_repos[@]}"
    echo
fi

if [ ${#behind_repos[@]} -gt 0 ]; then
    echo -e "${YELLOW}Repositories behind remote:${NC}"
    printf '  %s\n' "${behind_repos[@]}"
    echo
fi

if [ ${#diverged_repos[@]} -gt 0 ]; then
    echo -e "${RED}Repositories diverged from remote:${NC}"
    printf '  %s\n' "${diverged_repos[@]}"
    echo
fi

echo "=================================="
echo "Scan complete!"