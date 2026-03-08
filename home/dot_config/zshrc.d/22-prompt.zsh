# 22-prompt.zsh — Prompt configuration (starship)
# GATE: interactive-only (skipped when NG_MODE=agentic)

[[ "$NG_MODE" == "agentic" ]] && return 0

if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
