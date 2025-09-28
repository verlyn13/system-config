#!/bin/bash
# Install the new-project command globally

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_SCRIPT="$SCRIPT_DIR/06-templates/projects/new-project.fish"
TARGET_DIR="$HOME/bin"
TARGET_LINK="$TARGET_DIR/new-project"

# Ensure ~/bin exists
mkdir -p "$TARGET_DIR"

# Make script executable
chmod +x "$TEMPLATE_SCRIPT"

# Create symlink
if [ -L "$TARGET_LINK" ] || [ -f "$TARGET_LINK" ]; then
    echo "Removing existing new-project command..."
    rm -f "$TARGET_LINK"
fi

ln -s "$TEMPLATE_SCRIPT" "$TARGET_LINK"

echo "✅ Installed new-project command"
echo "   Location: $TARGET_LINK -> $TEMPLATE_SCRIPT"
echo ""
echo "Usage: new-project <type> <name>"
echo ""
echo "Available project types:"
echo "  node       - Node.js/TypeScript with Bun"
echo "  python     - Python with uv"
echo "  go         - Go module"
echo "  rust       - Rust with cargo"
echo "  react      - React with Vite"
echo "  next       - Next.js 15"
echo "  cli        - CLI tool"
echo "  lib        - Library"
echo "  api        - API service"
