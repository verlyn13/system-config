# 20-prompt.fish — Starship prompt

if status is-interactive
    if type -q starship
        if not set -q __STARSHIP_INIT_DONE
            set -gx __STARSHIP_INIT_DONE 1
            starship init fish | source
        end
    end
end
