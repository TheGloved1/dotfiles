#!/usr/bin/env bash
set -euo pipefail

# Max workspace number this script will move windows into
MAX_WORKSPACE=9

direction="${1:-}"
case "$direction" in
l | left)
  hyprctl dispatch "hl.dsp.window.move({ direction = \"l\" })" >/dev/null 2>&1 || true
  exit 0
  ;;
r | right)
  hyprctl dispatch "hl.dsp.window.move({ direction = \"r\" })" >/dev/null 2>&1 || true
  exit 0
  ;;
u | up) delta=-1 ;;
d | down) delta=1 ;;
*)
  echo "Usage: $0 [l|r|u|d]" >&2
  exit 1
  ;;
esac

current=$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.id // -1')

move_to_workspace() {
  local target="$1"
  if ((target < 1 || target > MAX_WORKSPACE)); then
    return 0
  fi
  hyprctl dispatch "hl.dsp.window.move({ workspace = $target })" >/dev/null 2>&1 || true
}

# If focused window is fullscreen, skip in-workspace moves
fullscreen=$(hyprctl -j activewindow 2>/dev/null | jq -r '.fullscreen // 0')
if [[ "$fullscreen" != "0" ]]; then
  move_to_workspace $((current + delta))
  exit 0
fi

current_y=$(hyprctl -j activewindow 2>/dev/null | jq -r '.at[1] // 0')

clients=$(hyprctl -j clients 2>/dev/null | jq -r --argjson ws "$current" \
  '[.[] | select(.workspace.id == $ws) | .at[1] // 0]')

if [[ "$direction" == "d" ]]; then
  has_below=$(echo "$clients" | jq -r --argjson cy "$current_y" \
    '[.[] | . > $cy] | any // false')
  if [[ "$has_below" == "true" ]]; then
    hyprctl dispatch "hl.dsp.window.move({ direction = \"d\" })" >/dev/null 2>&1 || true
  else
    move_to_workspace $((current + 1))
  fi
else
  has_above=$(echo "$clients" | jq -r --argjson cy "$current_y" \
    '[.[] | . < $cy] | any // false')
  if [[ "$has_above" == "true" ]]; then
    hyprctl dispatch "hl.dsp.window.move({ direction = \"u\" })" >/dev/null 2>&1 || true
  else
    move_to_workspace $((current - 1))
  fi
fi
