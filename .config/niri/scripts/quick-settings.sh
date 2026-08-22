#!/usr/bin/env bash
# quick-settings.sh — Hypr Utils.quick_settings() port via picker
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"

# Prefer noctalia dmenu, fallback to rofi
PICKER="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/picker.sh"
if [[ -x "$PICKER" ]]; then
  picker_cmd="bash $PICKER"
else
  picker_cmd="bash"
fi

term="${TERMINAL:-kitty}"
edit="${EDITOR:-nvim}"
visual="${VISUAL:-$edit}"

# Defaults from hypr 02-defaults.lua if exists
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/modules/02-defaults.lua" ]]; then
  # simple grep
  t=$(grep -oP 'DEFAULTS\.term\s*=\s*"\K[^"]+' "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/modules/02-defaults.lua" 2>/dev/null || echo "")
  [[ -n "$t" ]] && term="$t"
fi

hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
niri_dir="${XDG_CONFIG_HOME:-$HOME/.config}/niri"
modules="$hypr_dir/modules"
items=(
  "Edit Niri Config|$niri_dir/config.kdl"
  "Edit Niri Noctalia|$niri_dir/noctalia.kdl"
  "Edit Hypr Defaults|$modules/02-defaults.lua"
  "Edit Hypr Keybinds|$modules/keybinds.lua"
  "Edit Hypr Window Rules|$modules/window_rules.lua"
  "Edit Hypr Decorations|$modules/decorations.lua"
  "Edit Monitors|$modules/monitors.lua"
  "Configure Monitors (nwg-displays)|nwg-displays"
  "GTK Settings (nwg-look)|nwg-look"
  "QT Settings (qt6ct)|qt6ct"
)

# Build display list
display=$(printf '%s\n' "${items[@]}" | cut -d'|' -f1)

chosen=""
if is_exec noctalia; then
  chosen=$(printf '%s\n' "$display" | noctalia dmenu -p "Quick Settings" 2>/dev/null || true)
elif is_exec rofi; then
  chosen=$(printf '%s\n' "$display" | rofi -dmenu -i -p "Quick Settings" 2>/dev/null || true)
else
  # fallback: yad or notify
  notify "Quick Settings" "Install noctalia dmenu or rofi" "low"
  exit 0
fi

[[ -z "$chosen" ]] && exit 0
entry=$(printf '%s\n' "${items[@]}" | grep -F "$chosen|" | head -n1)
target=$(printf '%s' "$entry" | cut -d'|' -f2)

if [[ -z "$target" ]]; then exit 0; fi

# If target is a command (no file), exec it
if [[ ! -f "$target" && ! -e "$target" ]]; then
  bash -c "$target >/dev/null 2>&1 &" 2>/dev/null || true
  exit 0
fi

# Open file in editor (check TUI)
if grep -qE '(nvim|vim|nano|hx|helix|kak|micro)' <<< "$visual" 2>/dev/null; then
  bash -c "$term -e $visual \"$target\" >/dev/null 2>&1 &" 2>/dev/null || true
elif [[ -n "$visual" ]]; then
  bash -c "$visual \"$target\" >/dev/null 2>&1 &" 2>/dev/null || true
else
  bash -c "$term -e $edit \"$target\" >/dev/null 2>&1 &" 2>/dev/null || true
fi
