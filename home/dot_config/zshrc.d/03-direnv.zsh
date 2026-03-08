# 03-direnv.zsh — Hook direnv into zsh
# GATE: always

if command -v direnv &>/dev/null; then
  export DIRENV_LOG_FORMAT=""
  eval "$(direnv hook zsh)"
fi
