#!/usr/bin/env bash
app="${SWAYNC_APP_NAME,,}"
entry="${SWAYNC_DESKTOP_ENTRY,,}"
entry="${entry%.desktop}"
[[ -z "$app" && -z "$entry" ]] && exit 0

focus_class() {
	local cls="$1"
	if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
		hyprctl dispatch "hl.dsp.focus({ window = \"class:${cls}\" })" >/dev/null 2>&1
	else
		hyprctl dispatch focuswindow "class:${cls}" >/dev/null 2>&1
	fi
}

norm() { printf '%s' "${1,,}" | tr -cd '[:alnum:]'; }
app_norm="$(norm "$app")"

mapfile -t classes < <(hyprctl -j clients 2>/dev/null | jq -r '.[].class' 2>/dev/null)

target=""
for cls in "${classes[@]}"; do
	[[ "${cls,,}" == "$app" ]] && { target="$cls"; break; }
done
if [[ -z "$target" && -n "$entry" ]]; then
	for cls in "${classes[@]}"; do
		[[ "${cls,,}" == "$entry" ]] && { target="$cls"; break; }
	done
fi
if [[ -z "$target" && -n "$app_norm" ]]; then
	for cls in "${classes[@]}"; do
		[[ "$(norm "$cls")" == *"$app_norm"* ]] && { target="$cls"; break; }
	done
fi

[[ -n "$target" ]] && focus_class "$target"
exit 0
