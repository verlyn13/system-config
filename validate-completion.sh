#!/bin/bash
# Quick system validation to confirm all changes

echo "🔍 Running System Validation..."
echo ""

# 1. Check if renovate.json exists
if [ -f ~/Development/personal/system-setup-update/renovate.json ]; then
    echo "✅ Renovate configuration exists"
else
    echo "❌ Renovate configuration missing"
fi

# 2. Check GitHub Actions
if [ -d ~/Development/personal/system-setup-update/.github/workflows ]; then
    WORKFLOW_COUNT=$(ls ~/Development/personal/system-setup-update/.github/workflows/*.yml | wc -l)
    echo "✅ GitHub Actions configured ($WORKFLOW_COUNT workflows)"
else
    echo "❌ GitHub Actions not configured"
fi

# 3. Check project templates
if [ -f ~/Development/personal/system-setup-update/06-templates/projects/new-project.fish ]; then
    echo "✅ Project templates created"
else
    echo "❌ Project templates missing"
fi

# 4. Check Bun PATH configuration
if grep -q "if test -d ~/.bun/bin" ~/.config/fish/conf.d/04-paths.fish 2>/dev/null; then
    echo "✅ Bun PATH configuration updated"
else
    echo "⚠️  Bun PATH configuration needs update"
fi

# 5. Check mise for Bun
if mise which bun &>/dev/null; then
    BUN_VERSION=$(bun --version)
    echo "✅ Bun accessible via mise: $BUN_VERSION"
else
    echo "ℹ️  Bun not installed via mise (optional)"
fi

# 6. Run policy validation
echo ""
echo "📊 Running Policy Compliance Check..."
cd ~/Development/personal/system-setup-update
python 04-policies/validate-policy.py 2>&1 | grep "Compliance Score" || echo "Could not run compliance check"

echo ""
echo "✨ Validation Complete!"
echo ""
echo "To activate all changes:"
echo "  1. Reload your shell: exec fish"
echo "  2. Or open a new terminal window"
echo ""
echo "To test project templates:"
echo "  chmod +x ~/Development/personal/system-setup-update/install-templates.sh"
echo "  ~/Development/personal/system-setup-update/install-templates.sh"
echo "  new-project node test-app"
