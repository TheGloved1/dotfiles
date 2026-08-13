#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================

# Modified version of Refresh.sh but waybar wont refresh
# Used by automatic wallpaper change
# Modified inorder to refresh rofi background, Wallust and notifications

SCRIPTSDIR=${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts
SCRIPTSDIR=${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# quit ags & relaunch ags
ags -q && ags &

# quit quickshell & relaunch quickshell
pkill qs && qs &


# reload noctalia (runs as a daemon; no relaunch needed)
noctalia msg config-reload

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${SCRIPTSDIR}/RainbowBorders.sh"; then
    ${SCRIPTSDIR}/RainbowBorders.sh &
fi


exit 0