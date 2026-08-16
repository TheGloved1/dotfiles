-- Shared path constants (HYPR_BASE_DIR is set by hyprland.lua).
HYPR_DIR = HYPR_BASE_DIR
MODULES_DIR = HYPR_DIR .. "/modules"
SCRIPTS_DIR = HYPR_DIR .. "/scripts"

-- For Noctalia Color templates
Noctalia = require("noctalia")

local kvantum_checked = false
local kvantum_found = false

local function has_kvantum_qml_module()
	if kvantum_checked then
		return kvantum_found
	end
	kvantum_checked = true

	-- Only scan real Qt QML roots instead of the whole /usr tree.
	local cmd = "for d in /usr/lib/qt6/qml /usr/lib/qt5/qml /usr/lib/qt/qml "
		.. "/usr/lib64/qt6/qml /usr/lib64/qt5/qml /usr/lib64/qt/qml "
		.. "/usr/share/qt6/qml /usr/share/qt5/qml "
		.. "/usr/local/lib/qt6/qml /usr/local/lib/qt5/qml; do "
		.. '[ -d "$d" ] || continue; find "$d" -type d -path \'*/kvantum\' -print -quit 2>/dev/null && break; done'
	local pipe = io.popen(cmd, "r")
	if not pipe then
		return false
	end
	local output = pipe:read("*a") or ""
	pipe:close()
	kvantum_found = output:match("%S") ~= nil
	return kvantum_found
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

---@param dir string Dir to search in
---@return table files
local function scan_lua_files(dir)
	local files = {}
	local pipe = io.popen('ls -1 "' .. dir .. '" 2>/dev/null', "r")
	if not pipe then
		return files
	end
	for line in pipe:lines() do
		if line:match("%.lua$") then
			files[#files + 1] = line
		end
	end
	pipe:close()
	table.sort(files)
	return files
end

---Namespace a lua filename into a require-able module name
---@param file string
---@return string
local function get_module(file)
	return "modules." .. file:gsub("%.lua$", ""):gsub("/", ".")
end

---Load lua module files by relative name
---@param file string
for _, file in ipairs(scan_lua_files(MODULES_DIR)) do
	local module = get_module(file)
	local _, err = pcall(require, module)
	if err and tostring(err):find("No such file or directory", 1, true) == nil then
		print("[WARN] Unable to load " .. module .. ": " .. tostring(err))
	end
end

apply_qt_style_fallbacks()
