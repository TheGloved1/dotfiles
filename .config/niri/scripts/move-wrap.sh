#!/usr/bin/env bash
# move-wrap.sh — Hypr Utils.move_wrap() port
# Usage: move-wrap.sh [l|r|u|d]
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
require_niri

dir="${1:-}"
case "$dir" in
  l|left)  # Hypr: scrolling layout swapcol l else move l
           niri_action move-column-left 2>/dev/null || niri_action swap-window-left 2>/dev/null || true
           ;;
  r|right) niri_action move-column-right 2>/dev/null || niri_action swap-window-right 2>/dev/null || true
           ;;
  u|up)    # Hypr: move to workspace up
           if ! niri_action move-window-to-workspace-up 2>/dev/null; then
             # fallback: move column to workspace up
             niri_action move-column-to-workspace-up 2>/dev/null || true
           fi
           ;;
  d|down)  if ! niri_action move-window-to-workspace-down 2>/dev/null; then
             niri_action move-column-to-workspace-down 2>/dev/null || true
           fi
           ;;
  *) echo "Usage: $0 [l|r|u|d]" >&2; exit 1;;
esac
# Keep Hypr's fullscreen check: if fullscreen, just move workspace
