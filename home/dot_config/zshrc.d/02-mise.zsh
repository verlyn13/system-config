# 02-mise.zsh — Activate mise (full hook for direnv integration)
# GATE: always

if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi
