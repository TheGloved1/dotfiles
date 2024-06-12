if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_greeting ''
end


# Created by `pipx` on 2024-01-07 01:08:57
set PATH $PATH /home/gloves/.local/bin
clear


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH


# zoxide
zoxide init fish | source


# starship
function on_exit --on-event fish_exit
  echo Fish is now exiting
end
starship init fish | source

enable_transience
