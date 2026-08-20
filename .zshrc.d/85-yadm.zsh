# yadm commit helpers — conventional commit type detection
_dot_is_comment() {
  [[ "$1" =~ '^[[:space:]]*(#|;|//|/\*|\*|"|--)' ]]
}

_dot_detect_type() {
  local f st
  for f in "$@"; do
    st=$(yadm status --porcelain -- "$f" 2>/dev/null)
    if [[ "$st" == A* ]]; then
      print -r -- add
      return
    fi
    if [[ "$st" == D* ]]; then
      print -r -- remove
      return
    fi
    if [[ "$st" == R* ]]; then
      print -r -- update
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
    print -r -- update
  elif [[ $added -eq 1 && $removed -eq 1 ]]; then
    print -r -- update
  elif [[ $added -eq 1 ]]; then
    print -r -- add
  else
    print -r -- remove
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

# persistent saved-path list — paths recorded by `dot <path>` get reused by bare `dot`
_dot_paths_file() {
  local base="${XDG_STATE_HOME:-$HOME/.local/state}"
  mkdir -p "$base/yadm"
  print -r -- "$base/yadm/dot-paths"
}

_dot_load_paths() {
  local file=$(_dot_paths_file)
  [[ -f "$file" ]] && print -r -- "${(f)"$(< "$file")"}"
}

_dot_save_paths() {
  local file=$(_dot_paths_file)
  local -a existing=($(_dot_load_paths))
  local -a new
  local p norm
  for p in "$@"; do
    norm=${~p:a}
    if (( ! ${existing[(Ie)$norm]} )) && (( ! ${new[(Ie)$norm]} )); then
      new+=("$norm")
    fi
  done
  if (( ${#new} )); then
    printf '%s\n' "${new[@]}" >> "$file"
  fi
}

_dot_forget_paths() {
  local file=$(_dot_paths_file)
  [[ -f "$file" ]] || return 0
  local -a keep
  local p norm drop arg
  for p in $(_dot_load_paths); do
    norm=${~p:a}
    drop=0
    for arg in "$@"; do
      arg=${~arg:a}
      if [[ "$norm" == "$arg" ]]; then
        drop=1
        break
      fi
    done
    (( drop )) || keep+=("$p")
  done
  : > "$file"
  if (( ${#keep} )); then
    printf '%s\n' "${keep[@]}" >> "$file"
  fi
}

_dot_clear_paths() {
  : > "$(_dot_paths_file)"
}

_dot_list_paths() {
  local -a saved=($(_dot_load_paths))
  if (( ${#saved} )); then
    printf '%s\n' "${saved[@]}"
  else
    echo "No saved paths"
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
    lp|list-paths|--list)
      _dot_list_paths
      ;;
    --forget)
      if (( $# == 0 )); then
        echo "Usage: dot --forget <path>..."
      else
        _dot_forget_paths "$@"
      fi
      ;;
    --clear)
      _dot_clear_paths
      echo "Saved-path list cleared"
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
      files+=(${(f)"$(yadm diff --cached --name-only --diff-filter=D 2>/dev/null)"})
      if [[ ${#files} -eq 0 ]]; then
        echo "No changes to commit"
        return 0
      fi
      yadm add -- "${files[@]}"
      _dot_commit_and_push
      ;;
    "")
      local -a saved
      saved=($(_dot_load_paths))
      if (( ${#saved} )); then
        yadm add -- "${saved[@]}"
        _dot_commit_and_push
      else
        yadm status -s
      fi
      ;;
    *)
      # No recognized subcommand — treat args as paths to add, commit, maybe push
      if [[ -e ${~subcmd} ]] || [[ "$subcmd" == "." ]] || [[ "$subcmd" == -* ]]; then
        local p
        for p in "$subcmd" "$@"; do
          if [[ "$p" != -* ]] && [[ -e ${~p} ]] && [[ "$p" != "." ]]; then
            _dot_save_paths "$p"
          fi
        done

        yadm add "$subcmd" "$@"

        _dot_commit_and_push
      else
        yadm "$subcmd" "$@"
      fi
      ;;
  esac
}