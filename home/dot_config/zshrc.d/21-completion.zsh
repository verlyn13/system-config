# 21-completion.zsh — Completion system (heavy, not needed by agents)
# GATE: interactive-only (skipped when NG_MODE=agentic)

[[ "$NG_MODE" == "agentic" ]] && return 0

autoload -Uz compinit
# Only regenerate completion dump once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
