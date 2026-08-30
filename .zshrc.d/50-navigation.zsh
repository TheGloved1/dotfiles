# Zoxide
eval "$(zoxide init zsh)"

alias cd="z"

# yazi: cd into last browsed directory on exit
# shared wrapper - used by both `y` and `yazi` so `yazi` is default in interactive shells
__yazi_cd() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
function y() { __yazi_cd "$@" }
function yazi() { __yazi_cd "$@" }

# Ctrl+E: run y (yazi file manager)
bindkey -s '^E' 'y
'