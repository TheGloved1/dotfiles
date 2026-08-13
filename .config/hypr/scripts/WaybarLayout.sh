#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Script for waybar layout or configs

IFS=$'\n\t'

# Define directories
waybar_layouts="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/configs"
waybar_config="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config"
SCRIPTSDIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
msg=' 🎌 NOTE: Some waybar LAYOUT NOT fully compatible with some STYLES'

# Apply selected configuration
apply_config() {
    ln -sf "$waybar_layouts/$1" "$waybar_config"
    "${SCRIPTSDIR}/Refresh.sh" &
}

main() {
    # Resolve current symlink target and basename
    current_target=$(readlink -f "$waybar_config")
    current_name=$(basename "$current_target")

    # Build sorted list of available layouts
    mapfile -t options < <(
        find -L "$waybar_layouts" -maxdepth 1 -type f -printf '%f\n' | sort
    )

    # Mark and locate the active layout
    default_row=0
    MARKER="👉"
    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == "$current_name" ]]; then
            options[i]="$MARKER ${options[i]}"
            default_row=$i
            break
        fi
    done

    # Launch noctalia dmenu with the annotated list, keeping the active-row marker
    choice=$(printf '%s\n' "${options[@]}" \
        | noctalia dmenu -p "Select Waybar Layout"
    )

    # Exit if nothing chosen
    [[ -z "$choice" ]] && { echo "No option selected. Exiting."; exit 0; }

    # Strip marker before applying
    choice=${choice#"$MARKER "}

    case "$choice" in
        "no panel")
            pgrep -x "waybar" && pkill waybar || true
            ;;
        *)
            apply_config "$choice"
            ;;
    esac
}

main
