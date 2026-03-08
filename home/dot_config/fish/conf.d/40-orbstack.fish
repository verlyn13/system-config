# 40-orbstack.fish — OrbStack convenience functions

if not set -q ORBSTACK_APP
    set -gx ORBSTACK_APP /Applications/OrbStack.app
end

if test -f "$ORBSTACK_APP/Contents/Resources/completions/fish/orbctl.fish"
    source "$ORBSTACK_APP/Contents/Resources/completions/fish/orbctl.fish"
end

if type -q orb
    function orbstart -d 'Start OrbStack'; orb start $argv; end
    function orbstop -d 'Stop OrbStack'; orb stop $argv; end
    function orbrestart -d 'Restart OrbStack'; orb restart $argv; end
    function orbstatus -d 'Show OrbStack status'; orb status $argv; end
end

if type -q docker
    function dps -d 'List running containers'; docker ps $argv; end
    function dpsa -d 'List all containers'; docker ps -a $argv; end
    function dimages -d 'List images'; docker images $argv; end
end
