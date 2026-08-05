local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local hyprDir = configHome .. "/hypr"

HYPR_BASE_DIR = hyprDir

---@param name string
local function load_module(name)
	dofile(hyprDir .. "/" .. name .. ".lua")
end

load_module("config")
