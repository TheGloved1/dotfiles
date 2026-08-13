local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local hyprDir = configHome .. "/hypr"

HYPR_BASE_DIR = hyprDir

---Load a module
---@param name string
---@return nil
function load_module(name)
	dofile(hyprDir .. "/" .. name .. ".lua")
end

load_module("setup")

-- For Noctalia Color templates
require("noctalia").apply_theme()
