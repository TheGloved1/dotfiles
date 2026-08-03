#!/usr/bin/env bash
set -euo pipefail

direction="${1:-}"
case "$direction" in
l | left)
  dir="l"
  ws_dir="e-1"
  ;;
r | right)
  dir="r"
  ws_dir="e+1"
  ;;
u | up)
  dir="u"
  ws_dir="e-1"
  ;;
d | down)
  dir="d"
  ws_dir="e+1"
  ;;
*)
  echo "Usage: $0 [l|r|u|d]" >&2
  exit 1
  ;;
esac

# If focused window is fullscreen, skip in-workspace focus moves
fullscreen=$(hyprctl -j activewindow 2>/dev/null | jq -r '.fullscreen // 0')
if [[ "$fullscreen" != "0" ]]; then
  hyprctl dispatch "hl.dsp.focus({ workspace = \"$ws_dir\" })" >/dev/null 2>&1 || true
  exit 0
fi

current=$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.id // -1')
active=$(hyprctl -j activewindow 2>/dev/null | jq -r '.address // empty')
current_x=$(hyprctl -j activewindow 2>/dev/null | jq -r '.at[0] // 0')
current_y=$(hyprctl -j activewindow 2>/dev/null | jq -r '.at[1] // 0')

# For horizontal moves, wrap within the same workspace (left/right edge),
# only falling back to workspace switch on left/right workflows is avoided;
# horizontal wrap targets windows on the same workspace.
if [[ "$direction" == "l" || "$direction" == "r" ]]; then
  # Candidates on the same workspace, excluding the active window.
  candidates=$(hyprctl -j clients 2>/dev/null | jq -r --argjson ws "$current" --arg act "$active" \
    '[.[] | select(.workspace.id == $ws and .address != $act) | { addr: .address, x: ((.at[0] // 0) + ((.size[0] // 0) / 2)), y: ((.at[1] // 0) + ((.size[1] // 0) / 2)) }]')

  if [[ "$direction" == "l" ]]; then
    # Farthest-left window whose center is still to the left of the active window.
    pick=$(echo "$candidates" | jq -r --argjson cx "$current_x" \
      '[.[] | select(.x < $cx)] | sort_by(.x) | if length == 0 then null else .[0].addr end // empty')
    if [[ -n "$pick" ]]; then
      hyprctl dispatch "hl.dsp.focus({ window = \"address:$pick\" })" >/dev/null 2>&1 || true
    else
      # At left edge: wrap to the rightmost window on this workspace.
      wrap=$(echo "$candidates" | jq -r 'sort_by(.x) | if length == 0 then null else .[-1].addr end // empty')
      if [[ -n "$wrap" ]]; then
        hyprctl dispatch "hl.dsp.focus({ window = \"address:$wrap\" })" >/dev/null 2>&1 || true
      else
        hyprctl dispatch "hl.dsp.focus({ workspace = \"e-1\" })" >/dev/null 2>&1 || true
      fi
    fi
  else
    # Farthest-right window whose center is still to the right of the active window.
    pick=$(echo "$candidates" | jq -r --argjson cx "$current_x" \
      '[.[] | select(.x > $cx)] | sort_by(.x) | if length == 0 then null else .[0].addr end // empty')
    if [[ -n "$pick" ]]; then
      hyprctl dispatch "hl.dsp.focus({ window = \"address:$pick\" })" >/dev/null 2>&1 || true
    else
      # At right edge: wrap to the leftmost window on this workspace.
      wrap=$(echo "$candidates" | jq -r 'sort_by(.x) | if length == 0 then null else .[0].addr end // empty')
      if [[ -n "$wrap" ]]; then
        hyprctl dispatch "hl.dsp.focus({ window = \"address:$wrap\" })" >/dev/null 2>&1 || true
      else
        hyprctl dispatch "hl.dsp.focus({ workspace = \"e+1\" })" >/dev/null 2>&1 || true
      fi
    fi
  fi
  exit 0
fi

clients=$(hyprctl -j clients 2>/dev/null | jq -r --argjson ws "$current" \
  '[.[] | select(.workspace.id == $ws) | .at[1] // 0]')

if [[ "$direction" == "d" ]]; then
  has_below=$(echo "$clients" | jq -r --argjson cy "$current_y" \
    '[.[] | . > $cy] | any // false')
  if [[ "$has_below" == "true" ]]; then
    hyprctl dispatch "hl.dsp.focus({ direction = \"d\" })" >/dev/null 2>&1 || true
  else
    hyprctl dispatch "hl.dsp.focus({ workspace = \"e+1\" })" >/dev/null 2>&1 || true
  fi
else
  has_above=$(echo "$clients" | jq -r --argjson cy "$current_y" \
    '[.[] | . < $cy] | any // false')
  if [[ "$has_above" == "true" ]]; then
    hyprctl dispatch "hl.dsp.focus({ direction = \"u\" })" >/dev/null 2>&1 || true
  else
    hyprctl dispatch "hl.dsp.focus({ workspace = \"e-1\" })" >/dev/null 2>&1 || true
  fi
fi
