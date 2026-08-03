local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local hyprDir = configHome .. "/hypr"

local function load_module(name)
	dofile(hyprDir .. "/lua/" .. name .. ".lua")
end

load_module("user_overrides")
load_module("monitors")
load_module("workspaces")
