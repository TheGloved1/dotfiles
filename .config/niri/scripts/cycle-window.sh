#!/usr/bin/env bash
# cycle-window.sh — Hypr Utils.lua_cycle_window(next|previous) port
# Cycles visible windows on active workspace sorted by y,x (Hypr logic)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
require_niri

mode="${1:-next}"
if [[ "$mode" == "prev" || "$mode" == "previous" || "$mode" == "back" || "$mode" == "b" ]]; then
  mode="prev"
else
  mode="next"
fi

# Get windows and focused window IDs via JSON
wins_json=$(niri_json windows)
fw_json=$(niri_json focused-window)
fw_id=$(printf '%s' "$fw_json" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if 'FocusedWindow' in d: d=d['FocusedWindow']
    print(d.get('id',''))
except: print('')
" 2>/dev/null | tr -d '\n' || echo "")

# Build sorted list by workspace then position if available; fallback to id order
# niri windows don't expose x,y; we approximate by id order (creation order) which is close to tiling order
if is_exec jq; then
  ws_id=$(printf '%s' "$fw_json" | jq -r '.workspace_id // .FocusedWindow.workspace_id // empty' 2>/dev/null | head -n1)
  ids=$(printf '%s' "$wins_json" | jq -r --arg ws "$ws_id" '
    def unwrap: if has("Ok") then .Ok else . end;
    unwrap | if type=="array" then
      map(select(.workspace_id == ($ws|tonumber) or $ws=="")) | sort_by(.id) | .[].id
    else empty end
  ' 2>/dev/null | grep -v '^$' || true)
else
  ids=$(printf '%s' "$wins_json" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d, dict) and 'Ok' in d: d=d['Ok']
    import sys
    ws=sys.argv[1] if len(sys.argv)>1 else ''
    lst=[w for w in d if isinstance(d, list) and str(w.get('workspace_id',''))==ws or ws=='']
    lst=sorted(lst, key=lambda x: x.get('id',0))
    for w in lst: print(w.get('id',''))
except: pass
" "$ws_id" 2>/dev/null || true)
fi

# Convert to array
mapfile -t ids_arr <<< "$ids"
# Filter empty
ids_arr=($(printf '%s\n' "${ids_arr[@]}" | grep -v '^$' || true))
if (( ${#ids_arr[@]} < 2 )); then exit 0; fi

# Find index of focused
idx=-1
for i in "${!ids_arr[@]}"; do
  if [[ "${ids_arr[$i]}" == "$fw_id" ]]; then idx=$i; break; fi
done
if (( idx == -1 )); then exit 0; fi

if [[ "$mode" == "prev" ]]; then
  target_idx=$(( (idx - 1 + ${#ids_arr[@]}) % ${#ids_arr[@]} ))
else
  target_idx=$(( (idx + 1) % ${#ids_arr[@]} ))
fi
target_id="${ids_arr[$target_idx]}"
niri msg action focus-window --id "$target_id" 2>/dev/null || niri_action focus-window "$target_id"
