function ls --wraps='eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions' --wraps='eza --color=always --long --no-filesize --git --icons=always --no-time --no-user --no-permissions -a --group-directories-first --tree --level=1' --description 'alias ls=eza --color=always --long --no-filesize --git --icons=always --no-time --no-user --no-permissions -a --group-directories-first --tree --level=1'
  eza --color=always --long --no-filesize --git --icons=always --no-time --no-user --no-permissions -a --group-directories-first --tree --level=1 $argv
        
end
