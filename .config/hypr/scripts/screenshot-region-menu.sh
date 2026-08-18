#!/usr/bin/env bash
# Region screenshot with post-capture menu (Swappy / OCR)
# Based on original ScreenShot.sh and ScreenShotOcr.sh

set -euo pipefail

time=$(date "+%d-%b_%H-%M-%S")
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
dir="$PICTURES_DIR/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

iDIR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/icons"
iDoR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/images"
sDIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"

check_file="$dir/$file"

mkdir -p "$dir"

# Take region screenshot (from original shotarea/shotswappy)
tmpfile=$(mktemp)
wayfreeze --hide-cursor &
frozen=$!
trap 'kill "$frozen" 2>/dev/null' EXIT
sleep 0.2
geometry=$(slurp)
if [[ -n "$geometry" ]]; then
    grim -g "$geometry" - >"$tmpfile"
fi
kill "$frozen" 2>/dev/null
wait "$frozen" 2>/dev/null || true
trap - EXIT

if [[ ! -s "$tmpfile" ]]; then
    notify-send -u low -i "$iDoR/note.png" " Screenshot" " Cancelled"
    rm -f "$tmpfile"
    exit 1
fi

# Copy to clipboard and save
wl-copy <"$tmpfile"
mv "$tmpfile" "$check_file"

"${sDIR}/Sounds.sh" --screenshot >/dev/null 2>&1 &

# Show action menu
notify_cmd=(
    notify-send -t 10000
    -A "action1=Open"
    -A "action2=Find Text"
    -h string:x-canonical-private-synchronous:shot-notify
    -i "$iDIR/picture.png"
)
resp=$(timeout 10 "${notify_cmd[@]}" " Screenshot" " Saved — choose action")

case "$resp" in
    "action1")
        # Open in Swappy for markup
        swappy -f - <"$check_file" &
        ;;
    "action2")
        # OCR - Find Text
        if command -v tesseract >/dev/null 2>&1; then
            text=$(tesseract "$check_file" stdout 2>/dev/null)
            text=$(echo "$text" | sed '/^[[:space:]]*$/d')
            if [[ -n "$text" ]]; then
                # Copy all text to clipboard
                printf '%s\n' "$text" | wl-copy
                notify-send -u low -i "$iDIR/picture.png" " OCR Copied" "$(echo "$text" | head -c 300)"
            else
                notify-send -u low -i "$iDoR/note.png" " OCR" "No text detected"
            fi
        else
            notify-send -u low -i "$iDoR/note.png" " OCR" "tesseract not installed"
        fi
        ;;
esac