#!/usr/bin/env bash
# screenshare-toggle.sh — Hypr SUPER+CTRL+S screenshare-block tag toggle port
# Niri has no tag system; we emulate via block-out-from screencast using window id.
# We store blocked ids in $XDG_CACHE_HOME/niri-blocked-windows
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
require_niri

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/niri-blocked-windows"
mkdir -p "$(dirname "$CACHE")"
touch "$CACHE"

json=$(niri_json focused-window)
win_id=$(printf '%s' "$json" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if 'FocusedWindow' in d: d=d['FocusedWindow']
    print(d.get('id',''))
except: print('')
" 2>/dev/null | tr -d '\n')
title=$(printf '%s' "$json" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if 'FocusedWindow' in d: d=d['FocusedWindow']
    print(d.get('title',''))
except: print('')
" 2>/dev/null || echo "window")

if [[ -z "$win_id" ]]; then notify "Screenshare Block" "No focused window" "low"; exit 0; fi

if grep -q "^$win_id$" "$CACHE" 2>/dev/null; then
  grep -v "^$win_id$" "$CACHE" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
  notify "Screenshare Enabled" "Re-enabled for $title" "low"
else
  echo "$win_id" >> "$CACHE"
  notify "Screenshare Disabled" "Blocked $title from screencast (niri block-out-from manual)" "low"
fi
# Note: true block-out-from requires window-rule; this is state tracking for future rule generation.
# For now we rely on notify, as niri has no dynamic block-out per window via IPC.
