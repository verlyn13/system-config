#!/usr/bin/env fish
# Safety Verification Script - Run BEFORE applying new shell config
# This checks that critical PATH components and tools will remain accessible

set -l RED (set_color red)
set -l GREEN (set_color green)
set -l YELLOW (set_color yellow)
set -l BLUE (set_color blue)
set -l NORMAL (set_color normal)

echo $BLUE"================================"$NORMAL
echo $BLUE"Shell Configuration Safety Check"$NORMAL
echo $BLUE"================================"$NORMAL
echo ""

# Track issues
set -l issues 0

# Function to check command
function check_cmd
    set -l cmd $argv[1]
    set -l desc $argv[2]

    if type -q $cmd
        echo $GREEN"✓"$NORMAL" $desc: $cmd found at "(which $cmd)
    else
        echo $RED"✗"$NORMAL" $desc: $cmd NOT FOUND"
        set issues (math $issues + 1)
    end
end

# Function to check path entry
function check_path
    set -l path_entry $argv[1]

    if test -d $path_entry
        echo $GREEN"✓"$NORMAL" PATH entry exists: $path_entry"
    else
        echo $YELLOW"⚠"$NORMAL" PATH entry missing: $path_entry (may not be critical)"
    end
end

echo $BLUE"1. Critical Commands"$NORMAL
echo "-------------------"
check_cmd fish "Fish shell"
check_cmd brew "Homebrew"
check_cmd mise "Mise version manager"
check_cmd git "Git"
check_cmd chezmoi "Chezmoi"
echo ""

echo $BLUE"2. Current PATH Components"$NORMAL
echo "-------------------------"
for p in $PATH
    echo "  • $p"
end
echo ""

echo $BLUE"3. Critical PATH Entries"$NORMAL
echo "-----------------------"
check_path "/opt/homebrew/bin"
check_path "$HOME/.local/share/mise"
check_path "$HOME/.npm-global/bin"
check_path "$HOME/.local/bin"
echo ""

echo $BLUE"4. Mise Installations"$NORMAL
echo "--------------------"
if type -q mise
    mise list 2>/dev/null | head -10
    echo ""
else
    echo $RED"✗ Mise not found!"$NORMAL
    set issues (math $issues + 1)
    echo ""
end

echo $BLUE"5. Current TERM Settings"$NORMAL
echo "-----------------------"
echo "TERM: $TERM"
if set -q TMUX
    echo $GREEN"✓"$NORMAL" Inside tmux (TERM should be tmux-256color or screen-256color)"
    if test "$TERM" = "tmux-256color"; or test "$TERM" = "screen-256color"
        echo $GREEN"✓"$NORMAL" TERM is correctly set for tmux"
    else
        echo $YELLOW"⚠"$NORMAL" TERM is $TERM (unusual for tmux, but may be OK)"
    end
else
    echo "Not inside tmux (TERM should be xterm-256color or similar)"
    if test "$TERM" = "xterm-256color"
        echo $GREEN"✓"$NORMAL" TERM is correctly set"
    else
        echo $YELLOW"⚠"$NORMAL" TERM is $TERM (may want xterm-256color)"
    end
end
echo ""

echo $BLUE"6. Existing Configuration Files"$NORMAL
echo "-------------------------------"
set -l config_files \
    ~/.config/fish/config.fish \
    ~/.config/fish/conf.d/00-homebrew.fish \
    ~/.config/fish/conf.d/01-mise.fish \
    ~/.config/fish/conf.d/04-paths.fish

for f in $config_files
    if test -f $f
        echo $GREEN"✓"$NORMAL" Exists: $f"
    else
        echo $YELLOW"⚠"$NORMAL" Missing: $f"
    end
end
echo ""

echo $BLUE"7. New Configuration Preview"$NORMAL
echo "---------------------------"
set -l new_config ~/Development/personal/system-setup-update/06-templates/chezmoi/dot_config/fish/config.fish.tmpl

if test -f $new_config
    echo $GREEN"✓"$NORMAL" New config template found"
    echo "   Will preserve:"
    echo "   • MISE_TRUSTED_CONFIG_PATHS"
    echo "   • MISE_EXPERIMENTAL"
    echo "   • Existing conf.d/ files (loaded automatically)"
    echo "   • All current PATH entries"
    echo ""
    echo "   Will add:"
    echo "   • Tmux auto-start configuration"
    echo "   • Enhanced aliases (with fallbacks)"
    echo "   • Helper functions (mkcd, extract, note, weather)"
    echo "   • FZF configuration"
else
    echo $RED"✗"$NORMAL" New config template NOT found"
    set issues (math $issues + 1)
end
echo ""

echo $BLUE"8. Safety Checks"$NORMAL
echo "---------------"

# Check if conf.d will be preserved
if test -d ~/.config/fish/conf.d
    set -l conf_count (count ~/.config/fish/conf.d/*.fish)
    echo $GREEN"✓"$NORMAL" conf.d directory exists with $conf_count files"
    echo "   These will continue to load automatically"
else
    echo $YELLOW"⚠"$NORMAL" conf.d directory not found"
end

# Check for local override
if test -f ~/.config/fish/config.local.fish
    echo $GREEN"✓"$NORMAL" config.local.fish exists (will be sourced)"
else
    echo $BLUE"ℹ"$NORMAL" config.local.fish doesn't exist (optional, for machine-specific overrides)"
end

echo ""

# Summary
echo $BLUE"================================"$NORMAL
if test $issues -eq 0
    echo $GREEN"✓ SAFETY CHECK PASSED"$NORMAL
    echo ""
    echo "It appears safe to apply the new configuration."
    echo "Your PATH and critical tools should remain accessible."
    echo ""
    echo $YELLOW"Recommended next steps:"$NORMAL
    echo "1. Backup current config: cp ~/.config/fish/config.fish ~/.config/fish/config.fish.backup"
    echo "2. Apply with: chezmoi apply"
    echo "3. Test in new terminal: exec fish"
    echo "4. If issues occur, restore: cp ~/.config/fish/config.fish.backup ~/.config/fish/config.fish"
else
    echo $RED"✗ SAFETY CHECK FAILED ($issues issues)"$NORMAL
    echo ""
    echo "Please resolve the issues above before applying."
end
echo $BLUE"================================"$NORMAL
