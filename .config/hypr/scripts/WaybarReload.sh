#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Simple waybar reload / restart helper.
# Usage:
#   WaybarReload.sh          -> reload config (keeps bar, hot-reloads css/json)
#   WaybarReload.sh restart  -> fully kill and relaunch waybar

if [[ "${1:-reload}" == "restart" ]]; then
	pkill -x waybar 2>/dev/null || true
	sleep 1
	"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/WaybarStartup.sh" >/dev/null 2>&1 &
else
	if command -v waybar-msg >/dev/null 2>&1; then
		waybar-msg cmd reload
	else
		pkill -SIGUSR2 waybar
	fi
fi
