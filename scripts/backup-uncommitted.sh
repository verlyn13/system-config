#!/bin/bash
# Backup repositories with uncommitted changes
# Generated: 2025-09-26

set -euo pipefail

# Setup
BACKUP_ROOT="$HOME/Backups/repos-$(date +%Y%m%d-%H%M%S)"
REPORT_FILE="$HOME/Development/personal/system-setup-update/07-reports/backup-report-$(date +%Y-%m-%d).md"

echo "🔒 Creating backup of repositories with uncommitted changes"
echo "Backup location: $BACKUP_ROOT"
mkdir -p "$BACKUP_ROOT"

# Initialize report
cat > "$REPORT_FILE" <<EOF
# Repository Backup Report
**Date**: $(date +"%Y-%m-%d %H:%M:%S")
**Backup Location**: $BACKUP_ROOT

## Backed Up Repositories

| Repository | Uncommitted | Untracked | Backup Path |
|------------|------------|-----------|-------------|
EOF

# Counter
backed_up=0

# Read the JSON scan report
SCAN_REPORT="$HOME/Development/personal/system-setup-update/07-reports/repo-scan-$(date +%Y-%m-%d).json"

if [ ! -f "$SCAN_REPORT" ]; then
    echo "❌ No scan report found. Please run repo-scanner.py first."
    exit 1
fi

# Process each repo with uncommitted changes
echo "Processing repositories with uncommitted changes..."

# Use jq to parse the JSON and find repos with uncommitted changes
jq -r '.[] | select(.uncommitted > 0) | "\(.path)|\(.name)|\(.uncommitted)|\(.untracked)"' "$SCAN_REPORT" | while IFS='|' read -r path name uncommitted untracked; do
    echo "  📦 Backing up $name ($uncommitted uncommitted, $untracked untracked)..."

    # Create backup directory structure
    profile=$(basename $(dirname "$path"))
    backup_path="$BACKUP_ROOT/$profile/$name"

    # Copy the repository (follow symlinks with -L)
    if [ -L "$path" ]; then
        # If it's a symlink, copy the actual directory it points to
        real_path=$(readlink -f "$path")
        if [ -d "$real_path" ]; then
            cp -RL "$real_path" "$backup_path"
        else
            echo "    ⚠️  Skipping broken symlink: $path"
            continue
        fi
    else
        cp -R "$path" "$backup_path"
    fi

    # Add to report
    echo "| $profile/$name | $uncommitted | $untracked | $backup_path |" >> "$REPORT_FILE"

    ((backed_up++)) || true
done

# Special handling for the huge maat-framework repo
MAAT_PATH="$HOME/Development/happy-patterns-org/maat-framework"
if [ -d "$MAAT_PATH" ]; then
    echo "  ⚠️  Special handling for maat-framework (1821 files)..."
    echo "  Creating minimal backup (git diff only)..."

    MAAT_BACKUP="$BACKUP_ROOT/happy-patterns-org/maat-framework-diff"
    mkdir -p "$MAAT_BACKUP"

    cd "$MAAT_PATH"
    git diff > "$MAAT_BACKUP/uncommitted.diff"
    git diff --cached > "$MAAT_BACKUP/staged.diff"
    git status > "$MAAT_BACKUP/status.txt"

    echo "| happy-patterns-org/maat-framework | 1821 | 85004 | $MAAT_BACKUP (diff only) |" >> "$REPORT_FILE"
fi

# Complete report
cat >> "$REPORT_FILE" <<EOF

## Summary
- **Total Repositories Backed Up**: $backed_up
- **Backup Size**: $(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)
- **Backup Location**: \`$BACKUP_ROOT\`

## Next Steps
1. Review uncommitted changes in each repository
2. Commit or stash changes as appropriate
3. Pull latest from remotes
4. Update project configurations
EOF

echo "✅ Backup complete!"
echo "   Location: $BACKUP_ROOT"
echo "   Report: $REPORT_FILE"
echo ""
echo "📝 Next: Review changes and decide what to commit/stash"