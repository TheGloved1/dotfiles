#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Screenshot history browser with Open / Delete / Get Text

set -euo pipefail

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
dir="$PICTURES_DIR/Screenshots"
sDIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
iDIR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/icons"
ROFI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config.rasi"
ROFI_THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config-screenshot-history.rasi"

notify() {
	notify-send -u low -h string:x-canonical-private-synchronous:shot-history-notify -i "${iDIR}/picture.png" "Screenshot History" "$1"
}

if ! command -v rofi >/dev/null 2>&1; then
	notify "rofi not found"
	exit 1
fi

if [[ ! -d "$dir" ]]; then
	notify "No screenshots yet ($dir)"
	exit 1
fi

mapfile -t SHOTS < <(
	find -L "$dir" -maxdepth 1 -type f \
		\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.gif" \) \
		-printf '%T@ %p\n' 2>/dev/null |
		sort -rn |
		cut -d' ' -f2-
)

if [[ "${#SHOTS[@]}" -eq 0 ]]; then
	notify "No screenshots yet ($dir)"
	exit 1
fi

declare -A name_to_path=()
for shot in "${SHOTS[@]}"; do
	name_to_path["$(basename "$shot")"]="$shot"
done

scale_factor=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .scale' | head -n1)
monitor_height=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .height' | head -n1)
icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 15; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

if pgrep -x "rofi" >/dev/null 2>&1; then
	pkill rofi
fi

choice="$(
	for shot in "${SHOTS[@]}"; do
		printf '%s\x00icon\x1f%s\n' "$(basename "$shot")" "$shot"
	done | rofi -dmenu -i -config "$ROFI_THEME" -theme-str "$rofi_override"
)"
choice="$(printf '%s' "$choice" | xargs)"

if [[ -z "$choice" ]]; then
	exit 0
fi

path="${name_to_path[$choice]:-}"
if [[ -z "$path" || ! -f "$path" ]]; then
	notify "Selected screenshot not found: $choice"
	exit 1
fi

action="$(printf 'Open\nDelete\nGet Text' | rofi -dmenu -i -p "$(basename "$path")" -config "$ROFI_CONFIG")"
action="$(printf '%s' "$action" | xargs)"

case "$action" in
	Open)
		xdg-open "$path" &
		;;
	Delete)
		rm -f "$path"
		notify "Deleted $(basename "$path")"
		;;
	"Get Text")
		"${sDIR}/ScreenShotOcr.sh" "$path" &
		;;
esac

exit 0
