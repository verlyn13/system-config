# 03-direnv.fish — Hook direnv into fish

if status is-interactive
    if not set -q DIRENV_DISABLE
        if type -q direnv
            set -gx DIRENV_LOG_FORMAT ""
            direnv hook fish | source
        end
    end
end
