#!/usr/bin/env bash
# layout-dispatch.sh — Hypr Utils.layout_keybind_dispatch() port
# Niri is always scrolling, so map Hypr layout-aware focus/cycle to niri equivalents.
# Usage: layout-dispatch.sh [cycle-next|prev|focus-left|right|up|down|current]
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
require_niri

arg="${1:-}"
case "$arg" in
  cycle-next|next)  # Hypr scrolling: focus right else cycle
                    before=$(niri_json focused-window | wc -c)
                    niri_action focus-column-right 2>/dev/null || true
                    after=$(niri_json focused-window | wc -c)
                    # fallback to next window in column
                    if [[ "$before" -eq "$after" ]]; then
                      niri_action focus-window-down 2>/dev/null || true
                    fi
                    ;;
  cycle-prev|prev|previous) niri_action focus-column-left 2>/dev/null || niri_action focus-window-up 2>/dev/null || true
                         ;;
  focus-left|l)      niri_action focus-column-left-or-last 2>/dev/null || niri_action focus-column-left 2>/dev/null || true
                    ;;
  focus-right|r)     niri_action focus-column-right-or-first 2>/dev/null || niri_action focus-column-right 2>/dev/null || true
                    ;;
  focus-up|u)        niri_action focus-window-up 2>/dev/null || niri_action focus-workspace-up 2>/dev/null || true
                    ;;
  focus-down|d)      niri_action focus-window-down 2>/dev/null || niri_action focus-workspace-down 2>/dev/null || true
                    ;;
  layout|current|status) notify "Layout" "niri: always scrolling (Hypr monocle/master/dwindle not applicable)" "low"
                    ;;
  *) echo "Usage: $0 [cycle-next|prev|focus-left|right|up|down|current]" >&2; exit 1;;
esac
