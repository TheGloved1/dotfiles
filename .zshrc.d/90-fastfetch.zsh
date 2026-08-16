# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
#pokemon-colorscripts --no-title -s -r #without fastfetch
pokefetch() {
  local subcmd="${1:-}"
  shift 2>/dev/null || true

  local theme="$HOME/.config/fastfetch/themes/noctalia.jsonc"
  local args=()
  if [ -f "$theme" ]; then
    local keys="$(jq -r '.display.color.keys // empty' "$theme")"
    local title="$(jq -r '.display.color.title // empty' "$theme")"
    local pgreen="$(jq -r '.display.percent.color.green // empty' "$theme")"
    local pyellow="$(jq -r '.display.percent.color.yellow // empty' "$theme")"
    local pred="$(jq -r '.display.percent.color.red // empty' "$theme")"
    local lc1="$(jq -r '.logo.color."1" // empty' "$theme")"
    local lc2="$(jq -r '.logo.color."2" // empty' "$theme")"
    [ -n "$keys" ] && args+=(--color-keys "$keys" --color-separator "$keys")
    [ -n "$title" ] && args+=(--color-title "$title")
    [ -n "$pgreen" ] && args+=(--percent-color-green "$pgreen")
    [ -n "$pyellow" ] && args+=(--percent-color-yellow "$pyellow")
    [ -n "$pred" ] && args+=(--percent-color-red "$pred")
    [ -n "$lc1" ] && args+=(--logo-color-1 "$lc1")
    [ -n "$lc2" ] && args+=(--logo-color-2 "$lc2")
  fi

  case "$subcmd" in
    -c)
      pokemon-colorscripts --no-title -s -r | fastfetch -c $@ "${args[@]}" --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
      ;;
    *)
      pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config.jsonc "${args[@]}" --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
      ;;
  esac
}

nocfetch() {
  local subcmd="${1:-}"
  shift 2>/dev/null || true

  local args=()
  if [ -f "$HOME/.config/fastfetch/themes/noctalia.jsonc" ]; then
    local theme="$HOME/.config/fastfetch/themes/noctalia.jsonc"
    local keys="$(jq -r '.display.color.keys // empty' "$theme")"
    local title="$(jq -r '.display.color.title // empty' "$theme")"
    local pgreen="$(jq -r '.display.percent.color.green // empty' "$theme")"
    local pyellow="$(jq -r '.display.percent.color.yellow // empty' "$theme")"
    local pred="$(jq -r '.display.percent.color.red // empty' "$theme")"
    local lc1="$(jq -r '.logo.color."1" // empty' "$theme")"
    local lc2="$(jq -r '.logo.color."2" // empty' "$theme")"
    [ -n "$keys" ] && args+=(--color-keys "$keys" --color-separator "$keys")
    [ -n "$title" ] && args+=(--color-title "$title")
    [ -n "$pgreen" ] && args+=(--percent-color-green "$pgreen")
    [ -n "$pyellow" ] && args+=(--percent-color-yellow "$pyellow")
    [ -n "$pred" ] && args+=(--percent-color-red "$pred")
    [ -n "$lc1" ] && args+=(--logo-color-1 "$lc1")
    [ -n "$lc2" ] && args+=(--logo-color-2 "$lc2")
  fi

  case "$subcmd" in
    -c)
      fastfetch -c $HOME/.config/fastfetch/themes/noctalia.jsonc | fastfetch -c $@ "${args[@]}" --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
      ;;
    *)
      fastfetch -c $HOME/.config/fastfetch/themes/noctalia.jsonc | fastfetch -c $HOME/.config/fastfetch/config.jsonc "${args[@]}" --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
      ;;
  esac
}

# fastfetch. Will be disabled if above colorscript was chosen to install
#fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc