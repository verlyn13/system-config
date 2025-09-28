#!/bin/bash
# Legacy Repository Helper - Assists with safe migration/archival
# Usage: ./legacy-repo-helper.sh [check|archive|banner]

set -euo pipefail

readonly LEGACY_REPO="$HOME/Development/personal/system-setup"
readonly CURRENT_REPO="$HOME/Development/personal/system-setup-update"
readonly ARCHIVE_PATH="$HOME/archive/2025/repos/system-setup-legacy"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

# Check legacy repository status
check_legacy() {
    echo "🔍 Checking legacy repository status..."
    echo

    if [[ -d "$LEGACY_REPO" ]]; then
        echo -e "${YELLOW}⚠️  Legacy repository found:${NC} $LEGACY_REPO"

        # Check if it's a git repo
        if [[ -d "$LEGACY_REPO/.git" ]]; then
            echo "  Git status:"
            (cd "$LEGACY_REPO" && git status --short | head -5)

            # Check for uncommitted changes
            if (cd "$LEGACY_REPO" && git status --porcelain | grep -q .); then
                echo -e "  ${RED}✗ Has uncommitted changes${NC}"
            else
                echo -e "  ${GREEN}✓ Clean (no uncommitted changes)${NC}"
            fi

            # Check last commit date
            local last_commit=$(cd "$LEGACY_REPO" && git log -1 --format="%ar")
            echo "  Last commit: $last_commit"
        fi

        # Check size
        local size=$(du -sh "$LEGACY_REPO" | cut -f1)
        echo "  Size: $size"

        echo
        echo "Recommendations:"
        echo "  1. Archive the repository: $0 archive"
        echo "  2. Add deprecation banner: $0 banner"
    else
        echo -e "${GREEN}✓ No legacy repository found${NC}"
    fi

    echo
    echo "Current repository: $CURRENT_REPO"
    if [[ -d "$CURRENT_REPO/.git" ]]; then
        local commits=$(cd "$CURRENT_REPO" && git rev-list --count HEAD)
        echo "  Commits: $commits"
        echo -e "  Status: ${GREEN}Active${NC}"
    fi
}

# Archive legacy repository
archive_legacy() {
    if [[ ! -d "$LEGACY_REPO" ]]; then
        echo "No legacy repository to archive"
        return 0
    fi

    echo "📦 Archiving legacy repository..."
    echo "  From: $LEGACY_REPO"
    echo "  To: $ARCHIVE_PATH"
    echo

    # Dry run first
    echo -e "${YELLOW}DRY RUN - No changes will be made${NC}"
    echo "Would execute:"
    echo "  1. Create archive directory: mkdir -p $(dirname "$ARCHIVE_PATH")"
    echo "  2. Move repository: mv $LEGACY_REPO $ARCHIVE_PATH"
    echo "  3. Create symlink with README: ln -s $CURRENT_REPO $LEGACY_REPO"
    echo

    read -p "Proceed with actual archive? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Archive cancelled"
        return 0
    fi

    # Create archive directory
    mkdir -p "$(dirname "$ARCHIVE_PATH")"

    # Move repository
    mv "$LEGACY_REPO" "$ARCHIVE_PATH"
    echo -e "${GREEN}✓ Repository archived${NC}"

    # Create README at old location
    mkdir -p "$LEGACY_REPO"
    cat > "$LEGACY_REPO/README.md" <<'EOF'
# ⚠️ ARCHIVED - Repository Moved

This repository has been **ARCHIVED** and replaced by:
👉 **[system-setup-update](../system-setup-update)**

## Status
- **Archived**: 2025-09-28
- **Replacement**: `system-setup-update`
- **Archive Location**: `~/archive/2025/repos/system-setup-legacy`

## Why Archived?
- Superseded by improved implementation
- Contains outdated patterns
- Maintained for reference only

## DO NOT USE THIS REPOSITORY

All active development happens in:
```bash
cd ~/Development/personal/system-setup-update
```

---
*This is an automated archive notice*
EOF

    echo -e "${GREEN}✓ Archive complete with README redirect${NC}"
}

# Add deprecation banner to legacy repo README
add_banner() {
    if [[ ! -d "$LEGACY_REPO" ]]; then
        echo "No legacy repository found"
        return 0
    fi

    local readme="$LEGACY_REPO/README.md"

    echo "📝 Adding deprecation banner to legacy README..."

    # Check if banner already exists
    if [[ -f "$readme" ]] && grep -q "DEPRECATED" "$readme"; then
        echo -e "${YELLOW}Banner already exists${NC}"
        return 0
    fi

    # Create banner
    local banner='# 🚨 DEPRECATED - DO NOT USE

> **This repository is DEPRECATED and replaced by [system-setup-update](../system-setup-update)**
>
> **Status**: ⛔ ARCHIVED / READ-ONLY
> **Replacement**: `~/Development/personal/system-setup-update`
> **Last Update**: Legacy content - DO NOT USE

---

'

    # Prepend banner to README
    if [[ -f "$readme" ]]; then
        # Backup original
        cp "$readme" "$readme.bak"
        echo "$banner" > "$readme.tmp"
        cat "$readme.bak" >> "$readme.tmp"
        mv "$readme.tmp" "$readme"
    else
        echo "$banner" > "$readme"
        echo "Original README content was here..." >> "$readme"
    fi

    echo -e "${GREEN}✓ Banner added to $readme${NC}"

    # Also add .DEPRECATED file as additional signal
    touch "$LEGACY_REPO/.DEPRECATED"
    echo "system-setup-update" > "$LEGACY_REPO/.DEPRECATED"

    echo -e "${GREEN}✓ .DEPRECATED marker file created${NC}"
}

# Main command router
main() {
    local command="${1:-check}"

    case "$command" in
        check)
            check_legacy
            ;;
        archive)
            archive_legacy
            ;;
        banner)
            add_banner
            ;;
        *)
            echo "Usage: $0 [check|archive|banner]"
            echo
            echo "Commands:"
            echo "  check   - Check legacy repository status (default)"
            echo "  archive - Archive legacy repo and create redirect"
            echo "  banner  - Add deprecation banner to legacy README"
            exit 1
            ;;
    esac
}

main "$@"