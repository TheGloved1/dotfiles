local configHome = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. ".config")
local hyprDir = configHome .. "/hypr"
local configsDir = hyprDir .. "/configs"

local function has_kvantum_qml_module()
	local cmd = "find /usr/lib /usr/lib64 /usr/share -type d -path '*/qml/*/kvantum' -print -quit 2>/dev/null"
	local pipe = io.popen(cmd, "r")
	if not pipe then
		return false
	end
	local output = pipe:read("*a") or ""
	pipe:close()
	return output:match("%S") ~= nil
end

local function apply_qt_style_fallbacks()
	if not hl or not hl.env then
		return
	end

	if has_kvantum_qml_module() then
		return
	end

	local style_override = (os.getenv("QT_STYLE_OVERRIDE") or ""):lower()
	if style_override == "kvantum" or style_override == "kvantum-dark" then
		hl.env("QT_STYLE_OVERRIDE", "Fusion")
	end

	local quick_controls = (os.getenv("QT_QUICK_CONTROLS_STYLE") or ""):lower()
	if quick_controls == "kvantum" then
		hl.env("QT_QUICK_CONTROLS_STYLE", "Basic")
	end
end

local function load_optional(path)
	local ok, err = pcall(dofile, path)
	if ok then
		return true
	end
	if err and tostring(err):find("No such file or directory", 1, true) == nil then
		print("[WARN] Unable to load " .. path .. ": " .. tostring(err))
	end
	return false
end

local config_files = {
	"defaults.lua",
	"env.lua",
	"startup.lua",
	"window_rules.lua",
	"layer_rules.lua",
	"keybinds.lua",
	"settings.lua",
	"animations.lua",
	"decorations.lua",
	"laptops.lua",
	"monitors.lua",
	"workspaces.lua",
}

for _, file in ipairs(config_files) do
	load_optional(configsDir .. "/" .. file)
end

apply_qt_style_fallbacks()
