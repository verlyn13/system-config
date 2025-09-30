#!/bin/bash

# Contract Enforcement Setup Script
# This script sets up contract enforcement across all your repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Contract Enforcement Setup Wizard        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Detect contract system location
CONTRACTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo -e "${GREEN}✓${NC} Contract system found at: $CONTRACTS_DIR"

# Function to setup a repository
setup_repository() {
    local repo_path="$1"
    local repo_name="$(basename "$repo_path")"
    local enforcement_mode="${ENFORCEMENT_MODE:-standard}"

    echo ""
    echo -e "${BLUE}Setting up: $repo_name${NC}"
    if is_core_repo "$repo_name"; then
        echo -e "${GREEN}Type: CORE SYSTEM REPOSITORY (strict enforcement)${NC}"
        enforcement_mode="strict"
    else
        echo -e "${BLUE}Type: Standard project (standard enforcement)${NC}"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -d "$repo_path/.git" ]; then
        echo -e "${YELLOW}⚠️  Not a git repository, skipping${NC}"
        return
    fi

    cd "$repo_path"

    # 1. Install pre-commit hook
    echo -e "${BLUE}→${NC} Installing pre-commit hook..."
    if [ -e ".git/hooks/pre-commit" ] && [ ! -L ".git/hooks/pre-commit" ]; then
        echo -e "${YELLOW}  ⚠️  Existing pre-commit hook found${NC}"
        echo -n "  Backup and replace? (y/n): "
        read -r response
        if [ "$response" = "y" ]; then
            mv .git/hooks/pre-commit .git/hooks/pre-commit.backup.$(date +%Y%m%d%H%M%S)
            ln -sf "$CONTRACTS_DIR/enforcement/git-hooks/pre-commit" .git/hooks/pre-commit
            echo -e "${GREEN}  ✓${NC} Pre-commit hook installed (old hook backed up)"
        else
            echo -e "${YELLOW}  ⏭️${NC} Skipped pre-commit hook"
        fi
    else
        ln -sf "$CONTRACTS_DIR/enforcement/git-hooks/pre-commit" .git/hooks/pre-commit
        echo -e "${GREEN}  ✓${NC} Pre-commit hook installed"
    fi

    # 2. Setup GitHub Actions workflow
    echo -e "${BLUE}→${NC} Setting up CI/CD workflow..."
    mkdir -p .github/workflows

    if [ -f ".github/workflows/contracts.yml" ]; then
        echo -e "${YELLOW}  ⚠️  Contract workflow already exists${NC}"
    else
        cat > .github/workflows/contracts.yml << EOF
name: Contract Enforcement

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  contract-enforcement:
    uses: $CONTRACTS_DIR/enforcement/ci-cd/github-actions.yml@main
EOF
        echo -e "${GREEN}  ✓${NC} GitHub Actions workflow created"
    fi

    # 3. Detect service type and setup runtime enforcement
    echo -e "${BLUE}→${NC} Detecting service type..."

    SERVICE_TYPE="unknown"
    if [ -f "go.mod" ]; then
        SERVICE_TYPE="go"
    elif [ -f "package.json" ]; then
        SERVICE_TYPE="node"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        SERVICE_TYPE="python"
    fi

    echo -e "${GREEN}  ✓${NC} Detected: $SERVICE_TYPE"

    # 4. Install runtime enforcement based on type
    case "$SERVICE_TYPE" in
        go)
            setup_go_runtime "$repo_path" "$repo_name"
            ;;
        node)
            setup_node_runtime "$repo_path" "$repo_name"
            ;;
        python)
            setup_python_runtime "$repo_path" "$repo_name"
            ;;
        *)
            echo -e "${YELLOW}  ⏭️${NC} Unknown service type, skipping runtime setup"
            ;;
    esac

    # 5. Create CLAUDE.md for contract awareness
    if [ ! -f "CLAUDE.md" ]; then
        echo -e "${BLUE}→${NC} Creating CLAUDE.md for AI assistance..."

        if [ "$enforcement_mode" = "strict" ]; then
            cat > CLAUDE.md << EOF
# Contract Enforcement - CORE SYSTEM REPOSITORY

This is a CORE SYSTEM REPOSITORY with STRICT contract enforcement enabled.

## Critical Requirements:
1. Use external observer names (git, not repo; mise, not deps)
2. Include apiVersion: "obs.v1" in ALL observations
3. Follow project_id format exactly: $repo_name:org/repo
4. NEVER expose 'quality' observer externally
5. Maintain SLO thresholds:
$(if [[ "$repo_name" == "ds-go" ]]; then
    echo "   - Response time p95: 200ms"
    echo "   - Error rate: 5%"
    echo "   - Availability: 99.9%"
elif [[ "$repo_name" == "devops-mcp" ]]; then
    echo "   - Response time p95: 300ms"
    echo "   - Error rate: 1%"
    echo "   - Availability: 99.95%"
elif [[ "$repo_name" == "system-dashboard" ]]; then
    echo "   - Response time p95: 750ms"
    echo "   - Error rate: 20%"
    echo "   - Availability: 99.5%"
else
    echo "   - Response time p95: 500ms"
    echo "   - Error rate: 10%"
    echo "   - Availability: 99.0%"
fi)

Run validation: $CONTRACTS_DIR/../docs/contracts-reference/validate-integration.sh $repo_name

For details: $CONTRACTS_DIR/ENFORCEMENT_PRINCIPLES.md
Integration guide: $CONTRACTS_DIR/../docs/contracts-reference/$repo_name-integration.md
EOF
        else
            cat > CLAUDE.md << EOF
# Contract Enforcement

This repository has standard contract enforcement enabled.

## Requirements:
1. Use proper observer names in external APIs
2. Include required fields in observations
3. Follow project_id format: service:org/repo
4. Maintain reasonable SLO targets

Run validation: $CONTRACTS_DIR/../docs/contracts-reference/validate-integration.sh $repo_name

For details: $CONTRACTS_DIR/ENFORCEMENT_PRINCIPLES.md
EOF
        fi
        echo -e "${GREEN}  ✓${NC} CLAUDE.md created"
    fi

    echo -e "${GREEN}✅ Setup complete for $repo_name${NC}"
}

# Setup Go runtime enforcement
setup_go_runtime() {
    local repo_path="$1"
    local repo_name="$2"

    echo -e "${BLUE}→${NC} Setting up Go runtime enforcement..."

    # Check if internal/contracts exists
    if [ ! -d "internal/contracts" ]; then
        mkdir -p internal/contracts
        cp "$CONTRACTS_DIR/enforcement/runtime/universal-middleware.go" internal/contracts/enforcement.go

        # Create a simple integration file
        cat > internal/contracts/setup.go << 'EOF'
package contracts

import (
    "net/http"
    "os"
)

// SetupEnforcement adds contract enforcement to your HTTP server
func SetupEnforcement(handler http.Handler) http.Handler {
    mode := ModeMonitor // Start with monitoring
    if os.Getenv("CONTRACT_ENFORCE") == "true" {
        mode = ModeEnforce
    }

    enforcer := NewUniversalContractEnforcer(
        WithMode(mode),
        WithServiceName("SERVICE_NAME"),
    )

    return enforcer.Middleware(handler)
}
EOF
        sed -i.bak "s/SERVICE_NAME/$repo_name/g" internal/contracts/setup.go && rm internal/contracts/setup.go.bak

        echo -e "${GREEN}  ✓${NC} Go contract enforcement added to internal/contracts/"
        echo -e "${YELLOW}  📝${NC} Add to your main.go: handler = contracts.SetupEnforcement(handler)"
    else
        echo -e "${YELLOW}  ⏭️${NC} internal/contracts already exists"
    fi
}

# Setup Node.js runtime enforcement
setup_node_runtime() {
    local repo_path="$1"
    local repo_name="$2"

    echo -e "${BLUE}→${NC} Setting up Node.js runtime enforcement..."

    # Check package.json for framework
    if grep -q '"express"' package.json 2>/dev/null; then
        echo -e "${GREEN}  ✓${NC} Express detected"

        if [ ! -f "src/contracts/enforcement.js" ] && [ ! -f "server/contracts/enforcement.js" ]; then
            mkdir -p src/contracts 2>/dev/null || mkdir -p server/contracts
            local contracts_dir="src/contracts"
            [ -d "server/contracts" ] && contracts_dir="server/contracts"

            cp "$CONTRACTS_DIR/enforcement/runtime/universal-middleware.js" "$contracts_dir/enforcement.js"

            cat > "$contracts_dir/setup.js" << EOF
const { express } = require('./enforcement');

module.exports = function setupContractEnforcement(app) {
    const mode = process.env.CONTRACT_ENFORCE === 'true' ? 'enforce' : 'monitor';

    app.use(express({
        mode: mode,
        serviceName: '$repo_name',
        logViolations: true,
        webhookUrl: process.env.CONTRACT_WEBHOOK_URL
    }));

    console.log(\`Contract enforcement enabled in \${mode} mode\`);
};
EOF

            echo -e "${GREEN}  ✓${NC} Node.js contract enforcement added to $contracts_dir/"
            echo -e "${YELLOW}  📝${NC} Add to your app: require('$contracts_dir/setup')(app)"
        else
            echo -e "${YELLOW}  ⏭️${NC} Contract enforcement already exists"
        fi
    else
        echo -e "${YELLOW}  ⏭️${NC} Framework not detected, manual setup required"
    fi
}

# Setup Python runtime enforcement
setup_python_runtime() {
    local repo_path="$1"
    local repo_name="$2"

    echo -e "${BLUE}→${NC} Setting up Python runtime enforcement..."
    echo -e "${YELLOW}  📝${NC} Python runtime enforcement requires manual integration"
    echo -e "      See: $CONTRACTS_DIR/../docs/contracts-reference/quick-start.md"
}

# Core system repositories that require strict contract enforcement
CORE_REPOS=("ds-go" "devops-mcp" "system-dashboard" "system-setup-update")

# Main menu
show_menu() {
    echo ""
    echo "Contract Enforcement Setup Options:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Core System Repositories:"
    echo "1) Setup core system repos (ds-go, devops-mcp, system-dashboard, system-setup-update)"
    echo "2) Setup a specific core repo"
    echo ""
    echo "Other Projects:"
    echo "3) Setup current directory"
    echo "4) Setup any repository by path"
    echo "5) Scan and setup all Git repos in ~/Development/personal"
    echo ""
    echo "Tools & Monitoring:"
    echo "6) Open monitoring dashboard"
    echo "7) Run validation tests"
    echo "8) Check enforcement status"
    echo ""
    echo "9) Exit"
    echo ""
    echo -n "Choice [1-9]: "
}

# Check if repo is a core system repo
is_core_repo() {
    local repo_name="$1"
    for core in "${CORE_REPOS[@]}"; do
        if [[ "$repo_name" == "$core" ]]; then
            return 0
        fi
    done
    return 1
}

# Setup core system repositories
setup_core_repos() {
    echo ""
    echo -e "${BLUE}Setting up core system repositories...${NC}"
    echo "These repos will have STRICT enforcement enabled."
    echo ""

    # Core repos are in ~/Development/personal, not inside system-setup-update
    local parent_dir="$HOME/Development/personal"
    local found=0
    local setup=0

    for repo in "${CORE_REPOS[@]}"; do
        local repo_path="$parent_dir/$repo"

        if [ -d "$repo_path/.git" ]; then
            echo -e "${GREEN}✓${NC} Found: $repo"
            ((found++))

            echo -n "  Setup $repo? (y/n): "
            read -r response
            if [ "$response" = "y" ]; then
                setup_repository "$repo_path"
                ((setup++))
            else
                echo -e "${YELLOW}  ⏭️${NC} Skipped $repo"
            fi
        else
            echo -e "${YELLOW}⚠️${NC} Not found: $repo_path"
        fi
    done

    echo ""
    echo -e "${GREEN}✅ Setup complete: $setup/$found core repositories${NC}"
}

# Setup a specific core repository
setup_specific_core() {
    echo ""
    echo "Select core repository:"
    echo "━━━━━━━━━━━━━━━━━━━━━"

    local i=1
    for repo in "${CORE_REPOS[@]}"; do
        echo "$i) $repo"
        ((i++))
    done
    echo ""
    echo -n "Choice [1-${#CORE_REPOS[@]}]: "
    read -r choice

    if [[ $choice -ge 1 && $choice -le ${#CORE_REPOS[@]} ]]; then
        local repo_name="${CORE_REPOS[$((choice-1))]}"
        # Core repos are in ~/Development/personal
        local repo_path="$HOME/Development/personal/$repo_name"

        if [ -d "$repo_path/.git" ]; then
            setup_repository "$repo_path"
        else
            echo -e "${RED}❌ Repository not found: $repo_path${NC}"
        fi
    else
        echo -e "${RED}Invalid choice${NC}"
    fi
}

# Setup all repos in parent directory with classification
setup_all_repos() {
    echo ""
    echo -e "${BLUE}Scanning ~/Development/personal for Git repositories...${NC}"
    echo ""

    local parent_dir="$HOME/Development/personal"
    local core_count=0
    local other_count=0
    local skip_count=0

    # First, show what will be done
    echo "Found repositories:"
    echo "━━━━━━━━━━━━━━━━━"

    for dir in "$parent_dir"/*; do
        if [ -d "$dir/.git" ]; then
            local repo_name="$(basename "$dir")"
            if is_core_repo "$repo_name"; then
                echo -e "${GREEN}[CORE]${NC} $repo_name - Will use STRICT enforcement"
                ((core_count++))
            else
                echo -e "${BLUE}[OTHER]${NC} $repo_name - Will use STANDARD enforcement"
                ((other_count++))
            fi
        fi
    done

    echo ""
    echo "Summary: $core_count core repos, $other_count other projects"
    echo -n "Proceed with setup? (y/n): "
    read -r response

    if [ "$response" != "y" ]; then
        echo -e "${YELLOW}Cancelled${NC}"
        return
    fi

    # Now set them up
    local setup_count=0
    for dir in "$parent_dir"/*; do
        if [ -d "$dir/.git" ]; then
            local repo_name="$(basename "$dir")"

            # Skip certain directories that shouldn't have contracts
            if [[ "$repo_name" == "*.github.io" ]] || [[ "$repo_name" == ".*" ]]; then
                echo -e "${YELLOW}⏭️ Skipping: $repo_name${NC}"
                ((skip_count++))
                continue
            fi

            echo ""
            if is_core_repo "$repo_name"; then
                echo -e "${GREEN}Setting up CORE repo: $repo_name${NC}"
                ENFORCEMENT_MODE="strict" setup_repository "$dir"
            else
                echo -e "${BLUE}Setting up project: $repo_name${NC}"
                ENFORCEMENT_MODE="standard" setup_repository "$dir"
            fi
            ((setup_count++))
        fi
    done

    echo ""
    echo -e "${GREEN}✅ Setup complete:${NC}"
    echo "   Core repos: $core_count"
    echo "   Other projects: $other_count"
    echo "   Skipped: $skip_count"
    echo "   Total setup: $setup_count"
}

# Check enforcement status across repos
check_enforcement_status() {
    echo ""
    echo -e "${BLUE}Checking Contract Enforcement Status...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local parent_dir="$HOME/Development/personal"

    # Check core repos
    echo ""
    echo "Core System Repositories:"
    for repo in "${CORE_REPOS[@]}"; do
        local repo_path="$parent_dir/$repo"
        if [ -d "$repo_path/.git" ]; then
            echo -n "  $repo: "

            local status=""

            # Check pre-commit hook
            if [ -L "$repo_path/.git/hooks/pre-commit" ] || [ -f "$repo_path/.git/hooks/pre-commit" ]; then
                status="${status}✓pre-commit "
            else
                status="${status}✗pre-commit "
            fi

            # Check CI/CD
            if [ -f "$repo_path/.github/workflows/contracts.yml" ]; then
                status="${status}✓CI/CD "
            else
                status="${status}✗CI/CD "
            fi

            # Check runtime (varies by language)
            if [ -f "$repo_path/go.mod" ] && [ -d "$repo_path/internal/contracts" ]; then
                status="${status}✓runtime"
            elif [ -f "$repo_path/package.json" ] && ([ -d "$repo_path/src/contracts" ] || [ -d "$repo_path/server/contracts" ]); then
                status="${status}✓runtime"
            else
                status="${status}✗runtime"
            fi

            echo "$status"
        else
            echo -e "  $repo: ${RED}NOT FOUND${NC}"
        fi
    done

    echo ""
    echo "Quick Actions:"
    echo "  Run option 1 to setup all core repos"
    echo "  Run option 7 to validate a specific service"
}

# Setup monitoring dashboard
setup_dashboard() {
    echo ""
    echo -e "${BLUE}Setting up monitoring dashboard...${NC}"

    # Open dashboard in browser
    if command -v open &> /dev/null; then
        open "$CONTRACTS_DIR/dashboard/compliance-dashboard.html"
        echo -e "${GREEN}✓${NC} Dashboard opened in browser"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$CONTRACTS_DIR/dashboard/compliance-dashboard.html"
        echo -e "${GREEN}✓${NC} Dashboard opened in browser"
    else
        echo -e "${GREEN}✓${NC} Dashboard available at:"
        echo "    file://$CONTRACTS_DIR/dashboard/compliance-dashboard.html"
    fi

    echo ""
    echo "To serve the dashboard:"
    echo "  cd $CONTRACTS_DIR/dashboard"
    echo "  python3 -m http.server 8080"
    echo "  # Then visit http://localhost:8080/compliance-dashboard.html"
}

# Run validation tests
run_validation() {
    echo ""
    echo -e "${BLUE}Running validation tests...${NC}"

    if [ -f "$CONTRACTS_DIR/../docs/contracts-reference/validate-integration.sh" ]; then
        echo -n "Enter service name to validate: "
        read -r service_name
        bash "$CONTRACTS_DIR/../docs/contracts-reference/validate-integration.sh" "$service_name"
    else
        echo -e "${RED}❌ Validation script not found${NC}"
    fi
}

# Main loop
while true; do
    show_menu
    read -r choice

    case $choice in
        1)
            setup_core_repos
            ;;
        2)
            setup_specific_core
            ;;
        3)
            setup_repository "$(pwd)"
            ;;
        4)
            echo -n "Enter repository path: "
            read -r repo_path
            if [ -d "$repo_path" ]; then
                setup_repository "$repo_path"
            else
                echo -e "${RED}❌ Directory not found: $repo_path${NC}"
            fi
            ;;
        5)
            setup_all_repos
            ;;
        6)
            setup_dashboard
            ;;
        7)
            run_validation
            ;;
        8)
            check_enforcement_status
            ;;
        9)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done