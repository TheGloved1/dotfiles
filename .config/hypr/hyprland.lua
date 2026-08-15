local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local hyprDir = configHome .. "/hypr"

HYPR_BASE_DIR = hyprDir

-- Setup config
require("setup")
