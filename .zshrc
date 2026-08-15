
# Add ~/.local/bin to PATH (for oh-my-posh and other local binaries)
export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:/usr/local/bin

# oh-my-posh prompt
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.omp.json)"

# Zoxide
eval "$(zoxide init zsh)"

alias cd="z"

# Mommy
# precmd() { mommy -1 -s $? }

# Zsh plugins (standalone, not tied to oh-my-zsh)
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Custom Aliases
alias wbreload="$HOME/.config/hypr/scripts/WaybarReload.sh"
alias hyprconf="nvim $HOME/.config/hypr"
alias chmodx='chmod +x'
alias exemake='chmod +x'
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

# Arch Linux aliases (ported from oh-my-zsh archlinux plugin)
alias pacupg='sudo pacman -Syu'
alias pacin='sudo pacman -S'
alias pacins='sudo pacman -U'
alias pacrem='sudo pacman -R'
alias paclean='sudo pacman -Sc'
alias pacrep='pacman -Si'
alias pacreps='pacman -Ss'
alias pacloc='pacman -Qi'
alias paclocs='pacman -Qs'
alias paclsorphans='sudo pacman -Qdt'
alias pacrmorphans='sudo pacman -Rs $(pacman -Qtdq)'
alias pacdebug='pacman -Qtdq | grep -i debug'
alias pacmir='sudo pacman -Syy'
alias pacown='pacman -Qo'
alias pacfiles='pacman -F'
alias yaupg='yay -Syu'
alias yain='yay -S'
alias yarem='yay -R'
alias yareps='yay -Ss'
alias yaloc='yay -Qi'
alias yalocs='yay -Qs'
alias yaycon='yay --noconfirm'
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -5"

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

pac() {
  case "$1" in
    install|i)
      [[ $# -lt 2 ]] && echo "Usage: pac install <package(s)>" && return 1
      shift
      sudo pacman -S "$@"
      ;;
    remove|rm)
      [[ $# -lt 2 ]] && echo "Usage: pac remove <package(s)>" && return 1
      shift
      sudo pacman -R "$@"
      ;;
    update)
      sudo pacman -Sy
      ;;
    upgrade|up)
      sudo pacman -Syu
      ;;
    search|s)
      [[ $# -lt 2 ]] && echo "Usage: pac search <query>" && return 1
      shift
      pacman -Ss "$@"
      ;;
    info)
      [[ $# -lt 2 ]] && echo "Usage: pac info <package>" && return 1
      shift
      pacman -Si "$@"
      ;;
    list|ls)
      if [[ $# -ge 2 ]]; then
        shift
        pacman -Qs "$@"
      else
        pacman -Q
      fi
      ;;
    show)
      [[ $# -lt 2 ]] && echo "Usage: pac show <package>" && return 1
      shift
      pacman -Qi "$@"
      ;;
    files)
      [[ $# -lt 2 ]] && echo "Usage: pac files <package>" && return 1
      shift
      pacman -Ql "$@"
      ;;
    owns|own)
      [[ $# -lt 2 ]] && echo "Usage: pac owns <file>" && return 1
      shift
      pacman -Qo "$@"
      ;;
    orphans)
      pacman -Qdt
      ;;
    autoremove)
      sudo pacman -Rns $(pacman -Qtdq)
      ;;
    clean)
      sudo pacman -Sc
      ;;
    refresh)
      sudo pacman -Syy
      ;;
    help|h|-h|--help|"")
      echo "pac — pacman wrapper"
      echo ""
      echo "Usage: pac <command> [arguments]"
      echo ""
      echo "Commands:"
      echo "  install, i   <pkg(s)>     Install package(s)"
      echo "  remove, rm   <pkg(s)>     Remove package(s) with deps & config"
      echo "  search, s    <query>      Search repos"
      echo "  info         <pkg>        Show detailed repo info"
      echo "  update                     Sync package databases"
      echo "  upgrade, up               Full system upgrade"
      echo "  list, ls     [pkg]        List installed packages (filter by pkg)"
      echo "  show         <pkg>        Show installed package details"
      echo "  files        <pkg>        List files owned by package"
      echo "  owns, own    <path>       Find which package owns a file"
      echo "  orphans                     List orphaned packages"
      echo "  autoremove                 Remove orphaned packages"
      echo "  clean                      Clean package cache"
      echo "  refresh                    Force refresh package databases"
      echo "  help, h                     Show this help message"
      echo ""
      echo "For AUR packages, use 'aur' (yay wrapper) instead."
      ;;
    *)
      echo "Unknown command: $1"
      echo "Run 'pac help' for usage."
      return 1
      ;;
  esac
}
alias pm='pac'

_aur_is_aur() {
  pacman -Si "$1" &>/dev/null
  [[ $? -ne 0 ]]
}

aur() {
  case "$1" in
    install|i)
      [[ $# -lt 2 ]] && echo "Usage: aur install <package(s)>" && return 1
      shift
      yay -Sa "$@"
      ;;
    remove|rm)
      [[ $# -lt 2 ]] && echo "Usage: aur remove <package(s)>" && return 1
      shift
      for pkg in "$@"; do
        _aur_is_aur "$pkg" || { echo "$pkg is not an AUR package"; return 1 }
      done
      yay -R "$@"
      ;;
    update)
      yay -Sy
      ;;
    upgrade|up)
      local aur_pkgs=$(comm -12 <(yay -Quq | sort) <(pacman -Qmq | sort))
      if [[ -n "$aur_pkgs" ]]; then
        yay -S $aur_pkgs
      else
        echo "No AUR packages to upgrade"
      fi
      ;;
    search|s)
      [[ $# -lt 2 ]] && echo "Usage: aur search <query>" && return 1
      yay -Ssa "$2"
      ;;
    info)
      [[ $# -lt 2 ]] && echo "Usage: aur info <package>" && return 1
      _aur_is_aur "$2" || { echo "$2 is not an AUR package"; return 1 }
      yay -Si "$2"
      ;;
    list|ls)
      if [[ $# -ge 2 ]]; then
        pacman -Qms "$2"
      else
        pacman -Qm
      fi
      ;;
    show)
      [[ $# -lt 2 ]] && echo "Usage: aur show <package>" && return 1
      _aur_is_aur "$2" || { echo "$2 is not an AUR package"; return 1 }
      yay -Qi "$2"
      ;;
    files)
      [[ $# -lt 2 ]] && echo "Usage: aur files <package>" && return 1
      _aur_is_aur "$2" || { echo "$2 is not an AUR package"; return 1 }
      yay -Ql "$2"
      ;;
    owns|own)
      [[ $# -lt 2 ]] && echo "Usage: aur owns <file>" && return 1
      local owner=$(yay -Qo "$2" 2>/dev/null | awk '{print $NF}')
      [[ -z "$owner" ]] && echo "No package owns $2" && return 1
      _aur_is_aur "$owner" || { echo "$owner is not an AUR package"; return 1 }
      echo "$owner owns $2"
      ;;
    orphans)
      comm -12 <(pacman -Qmq | sort) <(pacman -Qdtq | sort)
      ;;
    autoremove)
      local orphans=(${(f)"$(comm -12 <(pacman -Qmq | sort) <(pacman -Qdtq | sort))"})
      if [[ $#orphans -eq 0 ]]; then
        echo "No AUR orphans to remove"
        return
      fi
      local selected=(${(f)"$(printf '%s\n' $orphans | fzf --multi --prompt="Select AUR packages to remove > " --header="Orphaned AUR packages (Ctrl-A to select all)")"})
      if [[ $#selected -gt 0 ]]; then
        sudo pacman -Rns $selected
      else
        echo "Nothing selected"
      fi
      ;;
    clean)
      yay -Sc
      ;;
    refresh)
      yay -Syy
      ;;
    help|h|-h|--help|"")
      echo "aur — yay wrapper with apt-like syntax (AUR packages only)"
      echo ""
      echo "Usage: aur <command> [arguments]"
      echo ""
      echo "Commands:"
      echo "  install, i   <pkg(s)>     Install package(s) from the AUR"
      echo "  remove, rm   <pkg(s)>     Remove AUR package(s) with deps & config"
      echo "  search, s    <query>      Search AUR for packages"
      echo "  info         <pkg>        Show detailed AUR package info"
      echo "  update                     Sync package databases"
      echo "  upgrade, up               Upgrade installed AUR packages"
      echo "  list, ls     [pkg]        List installed AUR packages (filter by pkg)"
      echo "  show         <pkg>        Show installed AUR package details"
      echo "  files        <pkg>        List files owned by AUR package"
      echo "  owns, own    <path>       Find which AUR package owns a file"
      echo "  orphans                     List orphaned AUR packages"
      echo "  autoremove                 Remove orphaned AUR packages"
      echo "  clean                      Clean package cache (all packages)"
      echo "  refresh                    Force refresh package databases"
      echo "  help, h                     Show this help message"
      echo ""
      echo "For official repo packages only, use 'pac' (pacman wrapper) instead."
      ;;
    *)
      echo "Unknown command: $1"
      echo "Run 'aur help' for usage."
      return 1
      ;;
  esac
}

# yadm commit helpers — conventional commit type detection
_dot_is_comment() {
  [[ "$1" =~ '^[[:space:]]*(#|;|//|/\*|\*|"|--)' ]]
}

_dot_detect_type() {
  local f st
  for f in "$@"; do
    st=$(yadm status --porcelain -- "$f" 2>/dev/null)
    if [[ "$st" == A* ]]; then
      print -r -- feat
      return
    fi
    if [[ "$st" == R* ]]; then
      print -r -- refactor
      return
    fi
  done

  local diff_text
  diff_text=$(yadm diff --cached --unified=0 -- "$@" 2>/dev/null)

  local added=0 removed=0 meaningful=0 line content
  while IFS= read -r line; do
    case "$line" in
      "diff --"*|"index "*|"--- "*|"+++ "*|"@@"*|"new file mode"*|"deleted file mode"*|"old mode"*|"new mode"*|"similarity index"*|"rename "*)
        continue ;;
    esac
    if [[ "$line" == "+"* ]]; then
      content=${line#+}
      if [[ -n "$content" ]] && ! _dot_is_comment "$content"; then
        added=1
        meaningful=1
      fi
    elif [[ "$line" == "-"* ]]; then
      content=${line#-}
      if [[ -n "$content" ]] && ! _dot_is_comment "$content"; then
        removed=1
        meaningful=1
      fi
    fi
  done <<< "$diff_text"

  if [[ $meaningful -eq 0 ]]; then
    print -r -- style
  elif [[ $removed -eq 1 ]]; then
    print -r -- fix
  else
    print -r -- feat
  fi
}

# stage all given files, group-commit, prompt push
_dot_commit_and_push() {
  local staged_files=(${(f)"$(yadm diff --cached --name-only 2>/dev/null)"})

  if [[ ${#staged_files} -eq 0 ]]; then
    echo "No staged changes"
    local ahead
    ahead=$(yadm rev-list --count @{upstream}..HEAD 2>/dev/null)
    if [[ "$ahead" =~ ^[0-9]+$ ]] && (( ahead > 0 )); then
      echo "You have $ahead unpushed commit(s)"
      echo "Push to remote? [Y/n]"
      read -r "REPLY? > "
      if [[ -z "$REPLY" || "$REPLY" =~ ^[yY]$ ]]; then
        yadm push
      fi
    fi
    return 0
  fi

  local -A groups
  local f key
  for f in "${staged_files[@]}"; do
    key=$(print -r -- "$f" | awk -F/ '{ if (NF >= 2) print $2; else print $1 }')
    groups[$key]="${groups[$key]:-}$f"$'\n'
  done

  yadm reset -q

  local sorted_keys=(${(ok)groups})
  local k files ctype
  for k in "${sorted_keys[@]}"; do
    files=(${(f)groups[$k]})
    yadm add -- "${files[@]}"
    ctype=$(_dot_detect_type "${files[@]}")
    yadm commit -m "$ctype($k): update $k"
  done

  echo "Push to remote? [Y/n]"
  read -r "REPLY? > "
  if [[ -z "$REPLY" || "$REPLY" =~ ^[yY]$ ]]; then
    yadm push
  fi
}

# yadm wrapper — selective add, commit, optional push
dot() {
  local subcmd="${1:-}"
  shift 2>/dev/null || true

  case "$subcmd" in
    s|status)
      yadm status -s
      ;;
    d|diff)
      yadm diff "$@"
      ;;
    ds|diff-staged)
      yadm diff --staged "$@"
      ;;
    l|log)
      yadm log --oneline --decorate -20 "$@"
      ;;
    c|commit)
      local staged_files=(${(f)"$(yadm diff --cached --name-only 2>/dev/null)"})

      if [[ ${#staged_files} -eq 0 ]]; then
        echo "Nothing staged to commit"
        return 1
      fi

      local -A groups
      local f key
      for f in "${staged_files[@]}"; do
        key=$(print -r -- "$f" | awk -F/ '{ if (NF >= 2) print $2; else print $1 }')
        groups[$key]="${groups[$key]:-}$f"$'\n'
      done

      yadm reset -q

      local sorted_keys=(${(ok)groups})
      local k files ctype
      for k in "${sorted_keys[@]}"; do
        files=(${(f)groups[$k]})
        yadm add -- "${files[@]}"
        ctype=$(_dot_detect_type "${files[@]}")
        yadm commit -m "$ctype($k): update $k"
      done
      ;;
    p|push)
      echo "Push to remote? [Y/n]"
      read -r "REPLY? > "
      if [[ -z "$REPLY" || "$REPLY" =~ ^[yY]$ ]]; then
        yadm push "$@"
      fi
      ;;
    pf|push-force)
      echo "Force push to remote? [y/N]"
      read -r "REPLY? > "
      if [[ "$REPLY" =~ ^[yY]$ ]]; then
        yadm push --force-with-lease "$@"
      fi
      ;;
    co|checkout)
      yadm checkout "$@"
      ;;
    b|branch)
      yadm branch "$@"
      ;;
    r|reset)
      if [[ $# -eq 0 ]]; then
        yadm reset HEAD
      else
        yadm reset "$@"
      fi
      ;;
    last)
      yadm log -1 --stat
      ;;
    unstage)
      yadm reset HEAD -- "$@"
      ;;
    discard)
      yadm checkout -- "$@"
      ;;
    sync)
      local -a files
      files=(${(f)"$(yadm diff --name-only 2>/dev/null)"})
      if [[ ${#files} -eq 0 ]]; then
        echo "No unstaged changes to commit"
        return 0
      fi
      yadm add -- "${files[@]}"
      _dot_commit_and_push
      ;;
    "")
      yadm status -s
      ;;
    *)
      # No recognized subcommand — treat args as paths to add, commit, maybe push
      if [[ -e "$subcmd" ]] || [[ "$subcmd" == "." ]] || [[ "$subcmd" == -* ]]; then
        yadm add "$subcmd" "$@"

        _dot_commit_and_push
      else
        yadm "$subcmd" "$@"
      fi
      ;;
  esac
}

# Reload shell
alias reload='clear && exec zsh'

# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
#pokemon-colorscripts --no-title -s -r #without fastfetch
pokefetch() {
  local subcmd="${1:-}"
  shift 2>/dev/null || true

  case "$subcmd" in
    -c)
      pokemon-colorscripts --no-title -s -r | fastfetch -c $@ --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
      ;;
    *)
      pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/kooldots-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
      ;;
  esac
}

nocfetch() {
  local subcmd="${1:-}"
  shift 2>/dev/null || true

  case "$subcmd" in
    -c)
      fastfetch -c $HOME/.config/fastfetch/themes/noctalia.jsonc | fastfetch -c $@ --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
      ;;
    *)
      fastfetch -c $HOME/.config/fastfetch/themes/noctalia.jsonc | fastfetch -c $HOME/.config/fastfetch/kooldots-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
      ;;
  esac
}

pokefetch
# fastfetch. Will be disabled if above colorscript was chosen to install
#fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc

# Set-up icons for files/directories in terminal using lsd
# alias ls='lsd'
alias ls='eza --icons -a --group-directories-first'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Configure TMUX to open a new session if none exists and open a window in that session if it does exist
tmux() {
  if [ -z $TMUX ]; then
    if command tmux has-session -t TMUX 2>/dev/null; then
      command tmux new-window -t TMUX
      command tmux attach -t TMUX
    else
      command tmux new -s TMUX
    fi
  fi
}

. "$HOME/.local/share/../bin/env"
