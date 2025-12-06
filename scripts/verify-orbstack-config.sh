#!/usr/bin/env bash
# Verify OrbStack configuration safety before applying
# Run this before 'chezmoi apply' to ensure no conflicts

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}OrbStack Configuration Safety Check${NC}"
echo "===================================="
echo ""

# Track if any issues found
ISSUES=0

# Check 1: OrbStack is installed
echo -n "Checking OrbStack installation... "
if test -d /Applications/OrbStack.app; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
    echo "  OrbStack not installed at /Applications/OrbStack.app"
    echo "  Config will not cause issues but won't be useful"
fi

echo ""

# Check 2: Native commands are available
echo "Checking native commands:"
for cmd in docker docker-compose orb orbctl; do
    echo -n "  $cmd: "
    if command -v "$cmd" >/dev/null 2>&1; then
        location=$(which "$cmd")
        echo -e "${GREEN}✓${NC} $location"
    else
        echo -e "${YELLOW}⚠ Not found${NC}"
    fi
done

echo ""

# Check 3: Verify no Fish function overrides exist
echo "Checking for existing Fish function conflicts:"
for cmd in docker docker-compose orb orbctl; do
    echo -n "  $cmd: "
    # Use fish to check if it's a function
    if fish -c "type -q $cmd && functions -q $cmd" 2>/dev/null; then
        echo -e "${RED}✗ Already defined as function${NC}"
        echo "    WARNING: Fish function already exists for '$cmd'"
        echo "    This may cause conflicts!"
        ISSUES=$((ISSUES + 1))
    else
        echo -e "${GREEN}✓${NC} Not overridden"
    fi
done

echo ""

# Check 4: Verify new config doesn't define conflicting functions
echo "Checking new configuration file:"
CONFIG_FILE="06-templates/chezmoi/dot_config/fish/conf.d/17-orbstack.fish.tmpl"
if test -f "$CONFIG_FILE"; then
    echo -n "  Searching for function overrides... "
    # Check if config defines docker or orb as functions (excluding comments)
    if grep -E "^function (docker|docker-compose|orb|orbctl) " "$CONFIG_FILE" >/dev/null 2>&1; then
        echo -e "${RED}✗ FOUND${NC}"
        echo "    ERROR: Config file defines function overrides!"
        echo "    This WILL break native commands!"
        ISSUES=$((ISSUES + 1))
    else
        echo -e "${GREEN}✓${NC} No overrides"
    fi

    echo -n "  Checking for PATH manipulation... "
    if grep -E "fish_add_path.*ORBSTACK" "$CONFIG_FILE" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Found${NC}"
        echo "    WARNING: Config manipulates PATH"
        echo "    This may not be necessary"
    else
        echo -e "${GREEN}✓${NC} None found"
    fi
else
    echo -e "${RED}✗ Config file not found${NC}"
    echo "  Expected: $CONFIG_FILE"
    ISSUES=$((ISSUES + 1))
fi

echo ""

# Check 5: Verify PATH is already correct
echo "Checking PATH configuration:"
echo -n "  /opt/homebrew/bin in PATH: "
if echo "$PATH" | grep -q "/opt/homebrew/bin"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
fi

echo -n "  /usr/local/bin in PATH: "
if echo "$PATH" | grep -q "/usr/local/bin"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
fi

echo ""

# Summary
echo "===================================="
if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Configuration is safe to apply:"
    echo "  chezmoi apply"
    echo ""
    echo "After applying, verify with:"
    echo "  fish -c 'orbstack_status'"
    exit 0
else
    echo -e "${RED}✗ Found $ISSUES issue(s)${NC}"
    echo ""
    echo "DO NOT apply configuration until issues are resolved!"
    echo "Review: docs/orbstack-safety-review.md"
    exit 1
fi
