# Custom Aliases
alias exe='chmod +x'
alias ff="fastfetch"
alias oc="opencode"
alias config="cd $HOME/.config/$1"
alias c='config'
alias n='nvim'
alias niriconf="cd $HOME/.config/niri; nvim"
alias hyprconf="cd $HOME/.config/hypr; nvim"
alias neoconf="cd $HOME/.config/nvim; nvim"

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

# Quick symlink helper: mklink [-f|--force] <target> <link_path>
# Usage: mklink file.txt link.txt / mklink -f file.txt existing-link
mklink() {
  local force=0

  while (( $# > 0 )); do
    case "$1" in
      -f|--force) force=1; shift ;;
      -h|--help)
        echo "Usage: mklink [-f|--force] <target> <link_path>" >&2
        echo "  Create a symlink <link_path> -> <target>." >&2
        echo "  -f, --force  overwrite <link_path> if it exists (ln -sfn)" >&2
        return 0
        ;;
      --) shift; break ;;
      -*) echo "mklink: unknown option: $1" >&2; echo "Usage: mklink [-f|--force] <target> <link_path>" >&2; return 1 ;;
      *) break ;;
    esac
  done

  if (( $# != 2 )); then
    echo "Usage: mklink [-f|--force] <target> <link_path>" >&2
    echo "  Create a symlink <link_path> -> <target>." >&2
    echo "  -f, --force  overwrite <link_path> if it exists (ln -sfn)" >&2
    return 1
  fi

  local target="$1"
  local link="$2"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    echo "mklink: warning: target '$target' does not exist (creating dangling link)" >&2
  fi

  if [[ -e "$link" || -L "$link" ]] && (( ! force )); then
    echo "mklink: '$link' already exists (use -f to overwrite)" >&2
    return 1
  fi

  # Create parent directory for the link if needed.
  local parent="${link:h}"
  if [[ -n "$parent" && "$parent" != "." && ! -d "$parent" ]]; then
    mkdir -p -- "$parent" || return 1
  fi

  if (( force )); then
    ln -sfnv -- "$target" "$link"
  else
    ln -svn -- "$target" "$link"
  fi
}

# Set-up icons for files/directories in terminal using lsd
# alias ls='lsd'
alias ls='eza --icons -a --group-directories-first'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
