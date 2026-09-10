# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Up/Down arrows: prefix-filter history, but move within multiline buffers
# up-line-or-search / down-line-or-search = multiline-aware wrapper around history-search-*
autoload -Uz up-line-or-search down-line-or-search
for _km in viins main; do
  bindkey -M $_km '^[[A' up-line-or-search
  bindkey -M $_km '^[[B' down-line-or-search
  bindkey -M $_km '^[OA' up-line-or-search
  bindkey -M $_km '^[OB' down-line-or-search
done
for _km in vicmd; do
  bindkey -M $_km '^[[A' up-line-or-search
  bindkey -M $_km '^[[B' down-line-or-search
  bindkey -M $_km '^[OA' up-line-or-search
  bindkey -M $_km '^[OB' down-line-or-search
done
unset _km
