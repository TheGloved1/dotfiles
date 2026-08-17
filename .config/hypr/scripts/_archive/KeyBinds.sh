#!/usr/bin/env bash
# searchable enabled keybinds using Noctalia dmenu (supports bindd descriptions)
# Adapted for the pure-Lua config system (configs/keybinds.lua)

config_home="${XDG_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"
hypr_dir="$config_home/hypr"
keybinds_lua="$hypr_dir/configs/keybinds.lua"
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

display_keybinds=""

# Primary: read live binds from hyprctl (descriptions set via the Lua config)
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    display_keybinds=$(hyprctl binds -j 2>/dev/null | jq -r '
      .[]
      | select((.description // "") != "")
      | select((.submap // "") == "")
      | .key as $k
      | .description as $d
      | .modmask as $m
      | def bit(n): ($m / n | floor) % 2 >= 1;
        [ if bit(64) then "SUPER" else empty end,
          if bit(1) then "SHIFT" else empty end,
          if bit(4) then "CTRL" else empty end,
          if bit(8) then "ALT" else empty end
        ] | (if length == 0 then $k else (join(" + ") + " + " + $k) end) + "  ::  " + $d
    ' | sort -f -k1)
fi

# Fallback: parse bind(...) entries directly from the Lua config
if [[ -z "$display_keybinds" ]]; then
  display_keybinds=$(awk '
    /^[ \t]*--/ { next }
    /[ \t]*bind\(/ { in_bind = 1; key = ""; pending = 1 }
    in_bind && pending && match($0, /"[^"]+"/) {
      key = substr($0, RSTART, RLENGTH)
      gsub(/"/, "", key)
      pending = 0
    }
    in_bind && match($0, /description[ \t]*=[ \t]*"[^"]*"/) {
      d = substr($0, RSTART, RLENGTH)
      sub(/^[^"]*"/, "", d)
      sub(/"$/, "", d)
      if (key != "" && d != "") print key "  ::  " d
      key = ""
      in_bind = 0
    }
  ' "$keybinds_lua" | sort -f -k1)
fi

# use noctalia dmenu to display the keybinds
if [[ -n "$display_keybinds" ]]; then
  printf '%s\n' "$display_keybinds" | noctalia dmenu -p "Keybinds"
else
  notify-send -u low -i "${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/images/ja.png" "KeyBinds" "No keybinds found"
fi
