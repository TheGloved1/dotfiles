#!/usr/bin/env bash
# Region screenshot with post-capture notification actions
# Uses slurp+grim for capture, notify-send for actions

set -euo pipefail

time=$(date "+%d-%b_%H-%M-%S")
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"
check_file="$dir/$file"

mkdir -p "$dir"

iDIR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/icons"
iDoR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/images"

# Take region screenshot
tmpfile=$(mktemp)
wayfreeze --hide-cursor &
frozen=$!
trap 'kill "$frozen" 2>/dev/null' EXIT
sleep 0.2
geometry=$(slurp)
if [ -n "$geometry" ]; then
    grim -g "$geometry" - >"$tmpfile"
fi
kill "$frozen" 2>/dev/null
wait "$frozen" 2>/dev/null
trap - EXIT

if [ ! -s "$tmpfile" ]; then
    notify-send -u low -i "$iDoR/note.png" " Screenshot" " NOT Saved (cancelled)"
    rm -f "$tmpfile"
    exit 1
fi

# Save and copy to clipboard
wl-copy <"$tmpfile"
mv "$tmpfile" "$check_file"

# Notify with actions
notify_cmd=(
    notify-send -t 10000
    -A action1=Open
    -A action2=Delete
    -A "action3=Get Text (OCR)"
    -h string:x-canonical-private-synchronous:shot-notify
    -i "$iDIR/picture.png"
)
resp=$(timeout 10 "${notify_cmd[@]}" " Screenshot" " Saved")

case "$resp" in
    action1)
        # Open in swappy
        swappy -f - <"$check_file" &
        ;;
    action2)
        rm "$check_file" &
        ;;
    action3)
        # OCR with tesseract and notify result
        if command -v tesseract >/dev/null 2>&1; then
            text=$(tesseract "$check_file" stdout 2>/dev/null)
            text=$(echo "$text" | sed '/^[[:space:]]*$/d')
            if [ -n "$text" ]; then
                echo "$text" | wl-copy
                notify-send -u low -i "$iDIR/picture.png" " OCR Complete" "$(echo "$text" | head -c 200)"
            else
                notify-send -u low -i "$iDoR/note.png" " OCR" "No text detected"
            fi
        else
            notify-send -u low -i "$iDoR/note.png" " OCR" "tesseract not installed"
        fi
        ;;
esac