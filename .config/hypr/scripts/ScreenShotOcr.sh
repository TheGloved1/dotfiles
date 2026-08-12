#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# OCR for screenshots via tesseract

set -euo pipefail

sDIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
iDIR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/icons"
ROFI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config.rasi"

IMAGE="${1:-}"

notify() {
	notify-send -u low -h string:x-canonical-private-synchronous:ocr-notify -i "${iDIR}/picture.png" "OCR" "$1"
}

if ! command -v tesseract >/dev/null 2>&1; then
	notify "tesseract not found. Install with: sudo pacman -S tesseract tesseract-data-eng"
	exit 1
fi

if [[ -n "${IMAGE}" ]]; then
	text="$(tesseract "${IMAGE}" stdout 2>/dev/null || true)"
else
	tmpimg="$(mktemp --suffix=.png)"
	wl-paste -t image/png >"${tmpimg}" 2>/dev/null || true
	if [[ ! -s "${tmpimg}" ]]; then
		rm -f "${tmpimg}"
		"${sDIR}/Sounds.sh" --error >/dev/null 2>&1 &
		notify "No image in clipboard"
		exit 1
	fi
	text="$(tesseract "${tmpimg}" stdout 2>/dev/null || true)"
	rm -f "${tmpimg}"
fi

if [[ -z "${text}" ]]; then
	"${sDIR}/Sounds.sh" --error >/dev/null 2>&1 &
	notify "No text detected"
	exit 1
fi

if pgrep -x "rofi" >/dev/null 2>&1; then
	pkill rofi
fi

list="Copy ALL text"
list+="\nOpen in editor"
while IFS= read -r line; do
	[[ -z "${line}" ]] && continue
	list+="\n${line}"
done <<< "${text}"

selection="$(printf '%b' "${list}" | rofi -dmenu -i -p "OCR Text" -config "${ROFI_CONFIG}")"

if [[ -z "${selection}" ]]; then
	exit 0
fi

if [[ "${selection}" == "Open in editor" ]]; then
	editor="${VISUAL:-${EDITOR:-nvim}}"
	edit_file="$(mktemp --suffix=.txt)"
	printf '%s\n' "${text}" > "${edit_file}"
	"${sDIR}/LaunchTerminal.sh" "kitty" "${editor} ${edit_file}"
	"${sDIR}/Sounds.sh" --screenshot >/dev/null 2>&1 &
	notify "Opened ${#text} chars in ${editor}"
	exit 0
fi

if [[ "${selection}" == "Copy ALL text" ]]; then
	printf '%s\n' "${text}" | wl-copy
else
	printf '%s\n' "${selection}" | wl-copy
fi

"${sDIR}/Sounds.sh" --screenshot >/dev/null 2>&1 &
notify "Copied ${#text} chars to clipboard"
exit 0
