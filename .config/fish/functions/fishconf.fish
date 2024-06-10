function fishconf --wraps='cd ~/.config/fish/ && nvim' --description 'alias fishconf=cd ~/.config/fish/ && nvim'
  cd ~/.config/fish/ && nvim $argv
        
end
