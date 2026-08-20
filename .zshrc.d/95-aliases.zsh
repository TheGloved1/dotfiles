# Custom Aliases
alias hyprconf="nvim $HOME/.config/hypr"
alias exe='chmod +x'
alias neoconf="nvim $HOME/.config/nvim"
alias ff="fastfetch"
alias oc="opencode"

# Git aliases (ported from oh-my-zsh git plugin)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gst='git status'
alias gss='git status --short'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpsup='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gb='git branch'
alias gba='git branch --all'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias grb='git rebase'
alias grbi='git rebase --interactive'
alias gm='git merge'
alias gsta='git stash push'
alias gstp='git stash pop'
alias gstl='git stash list'
alias grv='git remote --verbose'
alias gcl='git clone --recurse-submodules'
alias gclean='git clean --interactive -d'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'

# Reload shell
alias reload='clear && exec zsh'
alias relaod='reload'

# Set-up icons for files/directories in terminal using lsd
# alias ls='lsd'
alias ls='eza --icons -a --group-directories-first'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
