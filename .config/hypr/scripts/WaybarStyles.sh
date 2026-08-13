#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Script for waybar styles

IFS=$'\n\t'

# Define directories
waybar_styles="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/style"
waybar_style="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/style.css"
SCRIPTSDIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
msg=' 🎌 NOTE: Some waybar STYLES NOT fully compatible with some LAYOUTS'

# Apply selected style
apply_style() {
    ln -sf "$waybar_styles/$1.css" "$waybar_style"
    "${SCRIPTSDIR}/Refresh.sh" &
}

main() {
    # resolve current symlink and strip .css
    current_target=$(readlink -f "$waybar_style")
    current_name=$(basename "$current_target" .css)

    # gather all style names (without .css) into an array
    mapfile -t options < <(
        find -L "$waybar_styles" -maxdepth 1 -type f -name '*.css' \
            -exec basename {} .css \; \
            | sort
    )

    # mark the active style and record its index
    default_row=0
    MARKER="👉"
    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == "$current_name" ]]; then
            options[i]="$MARKER ${options[i]}"
            default_row=$i
            break
        fi
    done

    # launch noctalia dmenu with the annotated list, keeping the active-row marker
    choice=$(printf '%s\n' "${options[@]}" \
        | noctalia dmenu -p "Select Waybar Style"
    )

    [[ -z "$choice" ]] && { echo "No option selected. Exiting."; exit 0; }

    # remove annotation and apply
    choice=${choice#"$MARKER "}
    apply_style "$choice"
}

main
