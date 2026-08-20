# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Up/Down arrows filter history by current input (prefix match)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[OA' history-search-backward
bindkey '^[OB' history-search-forward
