# 41-tailscale.zsh — Tailscale CLI helpers
# GATE: always

# Add Tailscale CLI to PATH if installed via .app
if [[ -x /Applications/Tailscale.app/Contents/MacOS/tailscale ]]; then
  path_prepend /Applications/Tailscale.app/Contents/MacOS
fi

if command -v tailscale &>/dev/null; then
  alias tsstatus='tailscale status'
  alias tsip='tailscale ip'
fi
