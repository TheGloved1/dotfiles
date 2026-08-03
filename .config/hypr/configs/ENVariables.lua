-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- Environment variables
-- See https://wiki.hyprland.org/Configuring/Environment-variables/

-- Current Version of KoolDots:
hl.env("DOTS_VERSION", "2.3.25")

-- Toolkit Backend Variables
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("GTK_CSD", "0")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")

-- XDG Specifications
hl.env("XDG_DATA_DIRS", "/usr/local/share:/usr/share:$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:/home/$USER/.local/share/flatpak/exports/share")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- QT Variables
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QUICK_CONTROLS_STYLE", "Basic")

-- xwayland apps scale fix
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")

-- Cursor
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-lavender")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "catppuccin-mocha-lavender")
hl.env("XCURSOR_SIZE", "24")

-- Firefox
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Electron >28 apps
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("GSK_RENDERER", "ngl")

-- FOR VM and POSSIBLY NVIDIA
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")
