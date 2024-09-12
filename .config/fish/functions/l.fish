function l --wraps='eza' --description 'alias l=eza --color=always --long --no-filesize --git --icons=always --no-time --no-user --no-permissions -a --group-directories-first --tree --level=1'
  eza --color=always --long --no-filesize --git --icons=always --no-time --no-user --no-permissions -a --group-directories-first --tree --level=1 $argv
end

