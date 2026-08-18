#!/usr/bin/env bash
# Picker wrapper for noctalia dmenu / rofi
# Usage: picker.sh [command] [prompt] [items...]
#   command: "noctalia dmenu" (default) or "rofi" 
#   prompt: prompt string
#   items: newline-separated items via stdin, or args

set -euo pipefail

command="${1:-noctalia dmenu}"
prompt="${2:-}"
shift 2 || true

# Read items from stdin if available, otherwise from args
if [ -t 0 ]; then
    # No stdin, use remaining args
    items=("$@")
else
    # Read from stdin
    mapfile -t items
fi

if [ ${#items[@]} -eq 0 ]; then
    exit 1
fi

# Build the command
case "$command" in
    "noctalia dmenu"|"noctalia")
        if [ -n "$prompt" ]; then
            printf '%s\n' "${items[@]}" | noctalia dmenu -p "$prompt"
        else
            printf '%s\n' "${items[@]}" | noctalia dmenu
        fi
        ;;
    "rofi")
        if [ -n "$prompt" ]; then
            printf '%s\n' "${items[@]}" | rofi -dmenu -i -p "$prompt"
        else
            printf '%s\n' "${items[@]}" | rofi -dmenu -i
        fi
        ;;
    *)
        # Assume it's a full command with args
        if [ -n "$prompt" ]; then
            printf '%s\n' "${items[@]}" | eval "$command -p $prompt"
        else
            printf '%s\n' "${items[@]}" | eval "$command"
        fi
        ;;
esac