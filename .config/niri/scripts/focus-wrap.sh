#!/usr/bin/env bash
# focus-wrap.sh — Hypr Utils.focus_wrap() port via niri IPC
# Usage: focus-wrap.sh [l|r|u|d|left|right|up|down]
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
require_niri

dir="${1:-}"
case "$dir" in
  l|left)  niri_action focus-column-left-or-last   # wrap left
           # niri wrap is built-in via left-or-last; fallback to workspace if fullscreen
           ;;
  r|right) niri_action focus-column-right-or-first
           ;;
  u|up)    # Hypr up wraps to prev workspace if no window above
           before=$(niri_json focused-window | json_get - '.id // .FocusedWindow.id // empty')
           niri_action focus-window-up
           after=$(niri_json focused-window | json_get - '.id // .FocusedWindow.id // empty')
           if [[ "$before" == "$after" && -n "$before" ]]; then
             niri_action focus-workspace-up
           fi
           ;;
  d|down)  before=$(niri_json focused-window | json_get - '.id // .FocusedWindow.id // empty')
           niri_action focus-window-down
           after=$(niri_json focused-window | json_get - '.id // .FocusedWindow.id // empty')
           if [[ "$before" == "$after" && -n "$before" ]]; then
             niri_action focus-workspace-down
           fi
           ;;
  *) echo "Usage: $0 [l|r|u|d]" >&2; exit 1;;
esac
