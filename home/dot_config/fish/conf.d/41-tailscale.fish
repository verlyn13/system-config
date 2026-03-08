# 41-tailscale.fish — Tailscale CLI helpers

if not set -q TAILSCALE_APP
    set -gx TAILSCALE_APP /Applications/Tailscale.app
end

if test -x "$TAILSCALE_APP/Contents/MacOS/tailscale"
    fish_add_path -g "$TAILSCALE_APP/Contents/MacOS"
end

if type -q tailscale
    function tsstatus -d 'Show Tailscale status'; tailscale status $argv; end
    function tsip -d 'Show Tailscale IPs'; tailscale ip $argv; end
    function tsping -d 'Ping Tailscale device'; tailscale ping $argv; end
    function tsssh -d 'SSH via Tailscale'; tailscale ssh $argv; end
end
