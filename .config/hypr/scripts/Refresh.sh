#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Refresh the Noctalia shell (bar, dock, menus) and Hyprland
# after wallpaper / color-scheme / theme-mode changes.
# The old ags/quickshell/waybar/swaybg relaunch chain was removed
# because Noctalia runs as a persistent daemon and needs no restart.

SCRIPTSDIR=${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts

# Reload Noctalia config so the bar, dock, and generated templates
# pick up the current palette / theme mode.
noctalia msg config-reload >/dev/null 2>&1

# Re-run Hyprland startup Lua so noctalia.apply_theme() refreshes
# Hyprland-side colors (window / border / gtk window decorations).
hyprctl reload >/dev/null 2>&1

exit 0
