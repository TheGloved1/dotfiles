#!/usr/bin/env bash
# Generate wallust-hyprland.conf for hyprlock from wallust-hyprland.lua

set -euo pipefail

hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
lua_file="$hypr_dir/wallust/wallust-hyprland.lua"
conf_file="$hypr_dir/wallust/wallust-hyprland.conf"

# Already locked? Don't spawn a second instance.
pidof hyprlock >/dev/null 2>&1 && exit 0

# Rebuild color variables each lock so the palette is always current.
if [ -f "$lua_file" ]; then
  sed -nE 's/^[[:space:]]*(foreground|background|cursor|color[0-9]+)[[:space:]]*=[[:space:]]*"([^"]+)",?[[:space:]]*$/\$\1 = \2/p' "$lua_file" \
    > "${conf_file}.tmp"
  mv -f "${conf_file}.tmp" "$conf_file"
fi

exec hyprlock "$@"
