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
alias pacrmorphans='sudo pacman -Rn $(pacman -Qtdq)'
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
      sudo pacman -Rn $(pacman -Qtdq)
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
        sudo pacman -Rn $selected
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