#!/usr/bin/env bash
BACKEND=wayland
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
CACHE_FILE="$CACHE_DIR/keybinds.cache"

if pidof yad >/dev/null; then pkill yad; fi

NEED_REBUILD=1
if [ -f "$CACHE_FILE" ]; then
  CACHE_MTIME=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  NEED_REBUILD=0
  while IFS= read -r -d '' f; do
    if [ "$(stat -c %Y "$f" 2>/dev/null || echo 0)" -gt "$CACHE_MTIME" ]; then
      NEED_REBUILD=1
      break
    fi
  done < <(find "$HOME/.config/hypr" -name '*.conf' -print0 2>/dev/null)
fi

if [ "$NEED_REBUILD" -eq 1 ]; then
  mkdir -p "$CACHE_DIR"
  raw=$(hyprctl binds 2>/dev/null) || exit 1

  rows=()
  mods=""; key=""; desc=""; disp=""; arg=""

  val() { sed 's/.*: *//' <<< "$1" | sed 's/&/\&amp;/g'; }

  while IFS= read -r line; do
    case "$line" in
      bindd*|bindr*|bindl*|bind*)
        mods=""; key=""; desc=""; disp=""; arg=""
        ;;
    esac
    case "$line" in
      *modmask:*)
        mask=$(val "$line")
        mods=""
        (( mask & 64 )) && mods=""
        (( mask & 1  )) && mods="${mods:+$mods }Shift"
        (( mask & 4  )) && mods="${mods:+$mods }Ctrl"
        (( mask & 8  )) && mods="${mods:+$mods }Alt"
        ;;
      *key:*)
        key=$(val "$line")
        ;;
      *description:*)
        desc=$(val "$line")
        [ "$desc" = "false" ] && desc=""
        ;;
      *dispatcher:*)
        disp=$(val "$line")
        ;;
      *arg:*)
        arg=$(val "$line")
        if [ -n "$key" ] && [ "$key" != "mouse" ] && [[ "$key" != mouse_* ]] && [[ "$key" != xf86* ]] && [[ "$key" != [-+]* ]]; then
          d="${desc:-$disp}"
          c="${arg:0:50}"
          rows+=("$mods $key" "$d" "$c")
        fi
        ;;
    esac
  done <<< "$raw"

  declare -p rows > "$CACHE_FILE"
else
  source "$CACHE_FILE"
fi

GDK_BACKEND=$BACKEND yad \
  --center \
  --title="KooL Quick Cheat Sheet" \
  --no-buttons \
  --list \
  --column=Key: \
  --column=Description: \
  --column=Comment: \
  --timeout-indicator=bottom \
  -- \
  "${rows[@]}"