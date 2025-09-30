#!/usr/bin/env bash
set -euo pipefail

# Multi-repository governance application script
# Applies standard governance configuration to selected repositories

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$HOME/.local/share/devops-mcp/project-registry.json"

# Default configuration
DRY_RUN=false
REPOS=""
GOVERNANCE_TEMPLATE="$REPO_ROOT/.github"

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Apply repository governance configuration to multiple repositories.

OPTIONS:
    --dry-run           Show what would be done without making changes
    --repos=REPOS       Comma-separated list of repository names to process
    --template=PATH     Path to governance template directory (default: .github/)
    --help              Show this help message

EXAMPLES:
    # Dry run on specific repositories
    $0 --dry-run --repos="devops-mcp,docs-dev,ds-go"

    # Apply governance to all active repositories
    $0 --repos="\$(jq -r '.projects[] | select(.detectors[] == \"git\") | .name' \$REGISTRY | head -5 | tr '\n' ',')"

    # Apply to single repository
    $0 --repos="devops-mcp"

GOVERNANCE TEMPLATE:
    The script copies governance files from --template directory:
    - settings.yml (Probot configuration)
    - CODEOWNERS (Code ownership rules)
    - workflows/repository-governance.yml (Validation workflow)

PREREQUISITES:
    - GitHub CLI authenticated (gh auth status)
    - Target repositories must exist and be accessible
    - Governance template must be valid
EOF
}

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

validate_prerequisites() {
  log "Validating prerequisites..."

  # Check GitHub CLI
  if ! command -v gh >/dev/null 2>&1; then
    log "ERROR: GitHub CLI (gh) not found. Please install: brew install gh"
    exit 1
  fi

  # Check authentication
  if ! gh auth status >/dev/null 2>&1; then
    log "ERROR: GitHub CLI not authenticated. Please run: gh auth login"
    exit 1
  fi

  # Check registry
  if [ ! -f "$REGISTRY" ]; then
    log "ERROR: Project registry not found: $REGISTRY"
    exit 1
  fi

  # Check governance template
  if [ ! -d "$GOVERNANCE_TEMPLATE" ]; then
    log "ERROR: Governance template directory not found: $GOVERNANCE_TEMPLATE"
    exit 1
  fi

  # Validate template files
  local required_files=("settings.yml" "CODEOWNERS" "workflows/repository-governance.yml")
  for file in "${required_files[@]}"; do
    if [ ! -f "$GOVERNANCE_TEMPLATE/$file" ]; then
      log "ERROR: Required governance file not found: $GOVERNANCE_TEMPLATE/$file"
      exit 1
    fi
  done

  log "✓ Prerequisites validated"
}

get_repo_path() {
  local repo_name="$1"
  jq -r ".projects[] | select(.name == \"$repo_name\") | .path" "$REGISTRY"
}

get_repo_remote() {
  local repo_path="$1"
  if [ -d "$repo_path/.git" ]; then
    cd "$repo_path"
    git remote get-url origin 2>/dev/null | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\)\.git.*/\1/' || echo ""
  else
    echo ""
  fi
}

apply_governance_to_repo() {
  local repo_name="$1"
  local repo_path
  local repo_remote
  local github_repo

  log "Processing repository: $repo_name"

  # Get repository path from registry
  repo_path=$(get_repo_path "$repo_name")
  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    log "  ⚠ Repository path not found or doesn't exist: $repo_path"
    return 1
  fi

  # Get GitHub remote
  repo_remote=$(get_repo_remote "$repo_path")
  if [ -z "$repo_remote" ]; then
    log "  ⚠ No GitHub remote found for $repo_name, skipping"
    return 1
  fi

  github_repo="$repo_remote"
  log "  → Repository: $github_repo"
  log "  → Local path: $repo_path"

  # Check if repository is accessible via GitHub API
  if ! gh repo view "$github_repo" >/dev/null 2>&1; then
    log "  ⚠ Repository not accessible via GitHub API: $github_repo"
    return 1
  fi

  # Create .github directory if it doesn't exist
  local target_github_dir="$repo_path/.github"
  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$target_github_dir/workflows"
  else
    log "  [DRY RUN] Would create directory: $target_github_dir/workflows"
  fi

  # Copy governance files
  local files_to_copy=(
    "settings.yml"
    "CODEOWNERS"
    "workflows/repository-governance.yml"
  )

  for file in "${files_to_copy[@]}"; do
    local source="$GOVERNANCE_TEMPLATE/$file"
    local target="$target_github_dir/$file"

    if [ "$DRY_RUN" = false ]; then
      # Ensure target directory exists
      mkdir -p "$(dirname "$target")"

      # Customize settings.yml for this repository
      if [[ "$file" == "settings.yml" ]]; then
        sed "s/name: system-setup-update/name: $repo_name/g" "$source" > "$target"
        log "  ✓ Customized and copied: $file"
      else
        cp "$source" "$target"
        log "  ✓ Copied: $file"
      fi
    else
      log "  [DRY RUN] Would copy: $file → $target"
    fi
  done

  # Install Probot: Settings app if not already installed
  if [ "$DRY_RUN" = false ]; then
    log "  → Installing Probot: Settings app..."
    # Note: This requires manual installation via GitHub Apps marketplace
    log "  ⚠ Manual step required: Install Probot Settings app on $github_repo"
    log "    URL: https://github.com/apps/settings"
  else
    log "  [DRY RUN] Would install Probot: Settings app on $github_repo"
  fi

  # Commit and push changes
  if [ "$DRY_RUN" = false ]; then
    cd "$repo_path"
    if git status --porcelain | grep -q ".github/"; then
      git add .github/
      git commit -m "feat: implement repository governance framework

- Add Probot settings configuration
- Implement CODEOWNERS for critical files
- Add governance validation workflow
- Establish branch protection rules

Co-authored-by: System Setup Automation <system@local>"

      # Check if we can push
      if git remote get-url origin >/dev/null 2>&1; then
        git push origin "$(git branch --show-current)"
        log "  ✓ Changes committed and pushed"
      else
        log "  ✓ Changes committed (no remote to push to)"
      fi
    else
      log "  → No changes to commit"
    fi
  else
    log "  [DRY RUN] Would commit and push governance changes"
  fi

  log "  ✓ Governance applied to $repo_name"
  return 0
}

main() {
  local repo_list
  local success_count=0
  local total_count=0

  validate_prerequisites

  if [ -z "$REPOS" ]; then
    log "ERROR: No repositories specified. Use --repos or --help for usage."
    exit 1
  fi

  # Convert comma-separated repos to array
  IFS=',' read -ra repo_list <<< "$REPOS"

  log "Starting governance application..."
  log "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
  log "Template: $GOVERNANCE_TEMPLATE"
  log "Repositories: ${#repo_list[@]}"

  for repo in "${repo_list[@]}"; do
    # Trim whitespace
    repo=$(echo "$repo" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$repo" ] && continue

    ((total_count++))
    if apply_governance_to_repo "$repo"; then
      ((success_count++))
    fi
  done

  log "Governance application complete:"
  log "  Success: $success_count/$total_count repositories"

  if [ "$success_count" -lt "$total_count" ]; then
    log "  Some repositories failed - check logs above for details"
    exit 1
  fi

  log "✓ All repositories processed successfully"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --repos=*)
      REPOS="${1#*=}"
      shift
      ;;
    --template=*)
      GOVERNANCE_TEMPLATE="${1#*=}"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

main "$@"