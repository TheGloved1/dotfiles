-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- Vendor defaults for layerrules
-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

-- LAYER RULES

hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0,
    animation = "slide",
})

hl.layer_rule({
    match = { namespace = "notifications" },
    blur = true,
    ignore_alpha = 0,
    animation = "slide",
})

hl.layer_rule({
    match = { namespace = "quickshell:overview" },
    blur = true,
    ignore_alpha = 0.5,
})

hl.layer_rule({
    match = { namespace = "wallpaper" },
    blur = true,
    ignore_alpha = 0,
})

-- swaync + helper overlays
hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    blur = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "com.aurora.keybinds_help" },
    blur = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "logout_dialog" },
    blur = true,
    ignore_alpha = 0,
})
