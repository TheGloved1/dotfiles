#!/usr/bin/env bash
# Check if the active window is blocked from screensharing.
# Exits 0 if blocked, 1 if not. Prints a short status line.

BLOCK_TAG="screenshare-block"

if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found."
    exit 2
fi

window="$(hyprctl activewindow -j 2>/dev/null)" || true
if [[ -z "$window" ]]; then
    echo "No active window."
    exit 2
fi

if jq -e --arg tag "$BLOCK_TAG" 'any(.tags[]?; . == $tag)' >/dev/null 2>&1 <<<"$window"; then
    echo "Blocked from screensharing."
    exit 0
else
    echo "Not blocked from screensharing."
    exit 1
fi
