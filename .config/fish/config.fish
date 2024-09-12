if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_greeting ''
end

set PATH $PATH /usr/local/go/bin
set --export PATH $PATH /home/gloves/.local/bin
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set -gx EDITOR nvim 

starship init fish | source
enable_transience


