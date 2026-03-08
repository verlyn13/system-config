# 30-agentic.zsh — Minimal, predictable environment for AI tool sessions
# GATE: agentic-only (only loads when NG_MODE=agentic)

[[ "$NG_MODE" != "agentic" ]] && return 0

PROMPT='%~ %# '
unsetopt BEEP
export TERM_PROGRAM_AGENTIC=1
# No RPROMPT, no precmd hooks, no title-setting
