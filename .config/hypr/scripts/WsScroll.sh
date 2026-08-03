#!/bin/bash
# Navigate workspaces via Lua dispatcher.
# Usage: WsScroll.sh <direction>
#   direction: "next" (e+1) or "prev" (e-1)

case "${1:-}" in
  next) hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })' >/dev/null 2>&1 || true ;;
  prev) hyprctl dispatch 'hl.dsp.focus({ workspace = "e-1" })' >/dev/null 2>&1 || true ;;
esac
