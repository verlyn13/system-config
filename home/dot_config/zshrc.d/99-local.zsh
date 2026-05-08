# 99-local.zsh — Machine-local overrides, not managed by chezmoi
# GATE: always
#
# Note: zz-iterm2.zsh loads AFTER this module (zz- sorts after 99-). Local
# overrides that mutate precmd_functions/preexec_functions/PS1 may be replaced
# by iTerm2 shell-integration. Mutate iTerm2 hooks from within precmd callbacks,
# not at module load.

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
