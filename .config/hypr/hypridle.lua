-- Hypridle
-- Original config submitted by https://github.com/SherLock707

local iDIR = os.getenv("HOME") .. "/.config/swaync/images/ja.png"

hl.config({
	general = {
		lock_cmd = "pidof hyprlock || hyprlock",
		before_sleep_cmd = "loginctl lock-session",
		after_sleep_cmd = "hyprctl dispatch dpms on",
		ignore_dbus_inhibit = false,
	},
})

-- turn off screen faster if session is already locked
-- (disabled by default)
-- hl.listener({
--     timeout = 30,
--     on_timeout = "pidof hyprlock && hyprctl dispatch dpms off",
--     on_resume = "pidof hyprlock && hyprctl dispatch dpms on",
-- })

-- Warn
hl.listener({
	timeout = 540,
	on_timeout = "notify-send -i " .. iDIR .. " ' You are idle!'",
	on_resume = "notify-send -i " .. iDIR .. " ' Oh! you're Back' ' Hello !!!'",
})

-- Screenlock
hl.listener({
	timeout = 600,
	on_timeout = "loginctl lock-session",
})

-- Turn off screen
hl.listener({
	timeout = 720,
	on_timeout = "hyprctl dispatch dpms off",
	on_resume = "hyprctl dispatch dpms on",
})

-- Suspend # disabled by default
-- hl.listener({
--     timeout = 1200,
--     on_timeout = "systemctl suspend",
--     on_resume = "notify-send -i " .. iDIR .. " ' Oh! you're back' 'Hello !!!'",
-- })
