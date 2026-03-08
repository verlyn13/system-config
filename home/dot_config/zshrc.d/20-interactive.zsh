# 20-interactive.zsh — Human-friendly shell enhancements
# GATE: interactive-only (skipped when NG_MODE=agentic)

[[ "$NG_MODE" == "agentic" ]] && return 0

# History
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY INC_APPEND_HISTORY

# Shell options
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt CORRECT INTERACTIVE_COMMENTS NO_BEEP

# Key bindings (emacs mode)
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[f' forward-word
bindkey '^[b' backward-word
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# FZF integration
if command -v fzf &>/dev/null; then
  source <(fzf --zsh 2>/dev/null) || true
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# Useful functions
mkcd() { mkdir -p "$1" && cd "$1"; }
