-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- Converted from config/hypr/UserConfigs/01-UserDefaults.conf (active values only).

KOOLDOTS_DEFAULTS = KOOLDOTS_DEFAULTS or {}

-- Defaults (can be overridden from UserConfigs/user_defaults.lua).
KOOLDOTS_DEFAULTS.edit = "nvim"
KOOLDOTS_DEFAULTS.visual = "nvim"
KOOLDOTS_DEFAULTS.term = "kitty"
KOOLDOTS_DEFAULTS.files = "pcmanfm-qt"
KOOLDOTS_DEFAULTS.search_engine = "https://duckduckgo.com/search?q={}"

-- Optional user overrides live outside the pristine lua/ source tree.
do
	local configHome = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
	local userDefaults = configHome .. "/hypr/UserConfigs/user_defaults.lua"
	local ok, err = pcall(dofile, userDefaults)
	if not ok and err and tostring(err):find("No such file or directory", 1, true) == nil then
		print("[WARN] Unable to load user defaults file " .. userDefaults .. ": " .. tostring(err))
	end
end

-- Apply user defaults as environment variables so apps spawned by Hyprland
-- inherit the correct editor / visual editor / terminal / file manager.
-- (Parity with `env = EDITOR,nvim` etc. from 01-UserDefaults.conf.)
-- NOTE: actual hl.env() application lives in lua/env.lua (loaded later),
-- which reads KOOLDOTS_DEFAULTS populated here.
