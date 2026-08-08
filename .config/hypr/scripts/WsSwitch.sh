#!/bin/bash
# Focus a workspace by ID via Lua dispatcher.
# Usage: WsSwitch.sh <workspace_id>

[[ -z "$1" ]] && exit 1
# Log to file
hyprctl dispatch "hl.dsp.focus({ workspace = $1 })" >"/home/$USER/.config/hypr/hyprland.log" || true
