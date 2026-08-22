#!/usr/bin/env bash
# kill-active.sh — Hypr Utils.kill_active_process() port
# Kills PID of focused window via niri IPC (vs hyprctl activewindow pid)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=helpers.sh
source "$DIR/helpers.sh"
require_niri

json=$(niri_json focused-window)

# Try multiple field paths (niri_ipc: id, pid, title, app_id)
pid=$(json_get "$json" '.pid // .FocusedWindow.pid // .focused_window.pid // empty' | head -n1)
# Fallback: Python extraction
if [[ -z "$pid" || "$pid" == "null" ]]; then
  pid=$(printf '%s' "$json" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if 'FocusedWindow' in d: d=d['FocusedWindow']
    if 'focused_window' in d: d=d['focused_window']
    print(d.get('pid',''))
except: print('')
" 2>/dev/null || echo "")
fi

if [[ -z "$pid" || "$pid" == "null" || "$pid" == "0" ]]; then
  notify "Kill Active Window" "No active window PID found" "low" "${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/images/error.png"
  exit 0
fi

if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
  notify "Kill Active Window" "Invalid PID: $pid" "critical"
  exit 1
fi

# Confirm via niri window title for notify
title=$(json_get "$json" '.title // .FocusedWindow.title // ""' | head -n1)
if kill -TERM "$pid" 2>/dev/null; then
  notify "Kill Active Window" "Sent TERM to $title (pid $pid)" "low"
  sleep 0.5
  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL "$pid" 2>/dev/null || true
    notify "Kill Active Window" "Sent KILL to $title (pid $pid)" "normal"
  fi
else
  notify "Kill Active Window" "Failed to kill pid $pid" "critical"
  exit 1
fi
