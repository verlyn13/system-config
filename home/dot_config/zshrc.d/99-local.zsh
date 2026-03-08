# 99-local.zsh — Machine-local overrides, not managed by chezmoi
# GATE: always

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
