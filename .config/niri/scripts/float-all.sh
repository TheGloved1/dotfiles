#!/usr/bin/env bash
# float-all.sh — Hypr Utils.float_all_windows() + Float-all-Windows.sh port
# Toggles floating for all windows on the focused workspace via niri IPC
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
require_niri

# Get focused workspace id
ws_json=$(niri_json workspaces)
# Fallback: if JSON fails, just act on all windows
if ! is_exec jq && ! is_exec python3; then
  notify "Float All" "jq/python3 required" "critical"
  exit 1
fi

# Get workspace of focused window as active workspace
fw_json=$(niri_json focused-window)
ws_id=$(json_get "$fw_json" '.workspace_id // .FocusedWindow.workspace_id // .focused_window.workspace_id // empty')

# Get all windows JSON
wins_json=$(niri_json windows)

# If we can parse with jq, do per-workspace filter, else toggle all
if is_exec jq; then
  # jq path: niri 26.04 windows is array of {id, title, app_id, workspace_id}
  ids=$(printf '%s' "$wins_json" | jq -r --arg ws "$ws_id" '
    if type=="array" then
      .[] | select((.workspace_id // .FocusedWindow.workspace_id // "") | tostring == $ws or $ws=="") | .id // .window_id // empty
    elif has("Ok") then .Ok[] | select((.workspace_id // "") | tostring == $ws) | .id // empty
    else empty end
  ' 2>/dev/null | grep -v '^$' || true)
else
  ids=$(printf '%s' "$wins_json" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d, dict) and 'Ok' in d: d=d['Ok']
    ws=sys.argv[1] if len(sys.argv)>1 else ''
    for w in d if isinstance(d, list) else []:
        wid=str(w.get('workspace_id',''))
        if ws=='' or wid==ws:
            print(w.get('id',''))
except: pass
" "$ws_id" 2>/dev/null || true)
fi

if [[ -z "$ids" ]]; then
  # fallback: toggle focused only
  niri_action toggle-window-floating
  notify "Float All" "Toggled focused window (no workspace filter)" "low"
  exit 0
fi

count=0
for id in $ids; do
  # Focus window by id then toggle
  # niri focus-window expects id as integer
  niri msg action focus-window --id "$id" 2>/dev/null || niri_action focus-window "$id" 2>/dev/null || true
  sleep 0.03
  niri_action toggle-window-floating
  count=$((count+1))
done
notify "Float All" "Toggled $count windows on workspace ${ws_id:-active}" "low"
