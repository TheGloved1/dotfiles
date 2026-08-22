# Zoxide
eval "$(zoxide init zsh)"

alias cd="z"

# yazi: cd into last browsed directory on exit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Ctrl+E: run y (yazi file manager)
bindkey -s '^E' 'y
'