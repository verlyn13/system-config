# 25-keybindings.fish — Fish key bindings

if status is-interactive
    if not set -q fish_key_bindings; or test "$fish_key_bindings" = "fish_vi_key_bindings"
        fish_default_key_bindings
    end

    bind \e\[A history-search-backward
    bind \e\[B history-search-forward
    bind \eOA history-search-backward
    bind \eOB history-search-forward
    bind \cp history-search-backward
    bind \cn history-search-forward
    bind \cr history-pager
end
