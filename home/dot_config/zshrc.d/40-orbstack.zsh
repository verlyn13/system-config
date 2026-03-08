# 40-orbstack.zsh — OrbStack convenience aliases
# GATE: always

if command -v orb &>/dev/null; then
  alias orbstart='orb start'
  alias orbstop='orb stop'
  alias orbrestart='orb restart'
  alias orbstatus='orb status'
fi

if command -v docker &>/dev/null; then
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias dimages='docker images'
fi
