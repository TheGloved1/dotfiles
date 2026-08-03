-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- Monitor Configuration
-- See Hyprland wiki for more details
-- https://wiki.hyprland.org/Configuring/Monitors/
-- Configure your Display resolution, offset, scale and Monitors here,
-- use `hyprctl monitors` to get the info.

-- Monitors
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = "1",
})

hl.monitor({
    output = "HEADLESS-1",
    mode = "2080x1080@60",
    position = "1920x0",
    scale = "1",
})

-- High Refresh Rate
hl.monitor({
    output = "",
    mode = "highrr",
    position = "auto",
    scale = "1",
})

-- High Resolution
hl.monitor({
    output = "",
    mode = "highres",
    position = "auto",
    scale = "1",
})

-- QEMU-KVM, virtual box or vmware
hl.monitor({
    output = "Virtual-1",
    mode = "1920x1080@60",
    position = "auto",
    scale = "1",
})
