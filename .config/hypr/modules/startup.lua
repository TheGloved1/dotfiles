-- DBus / systemd environment
Utils.once("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
Utils.once("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
Utils.once("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'")
Utils.once("gsettings set org.gnome.desktop.interface cursor-theme 'Nordzy-cursors'")
Utils.once("gsettings set org.gnome.desktop.interface cursor-size 24")

-- Core services
Utils.once("systemctl --user enable --now hyprpolkitagent.service")
Utils.once("sh -c 'sleep 0.3; $HOME/.config/hypr/scripts/Polkit.sh'")
Utils.once("nm-applet")

-- Portals and theme
Utils.once("$HOME/.config/hypr/scripts/PortalHyprland.sh")

-- Cursor refresh
Utils.once('sh -c \'sleep 0.3; hyprctl setcursor "${HYPRCURSOR_THEME:-Nordzy-hyprcursors}" "${HYPRCURSOR_SIZE:-24}"\'')

-- Noctalia shell
Utils.once("noctalia --daemon")

-- Idle manager
-- Utils.once("hypridle")

-- Hypr plugins
Utils.once("hyprpm reload")

-- Vicinae
Utils.once("vicinae server")

-- Hyprsunset
Utils.hyprsunset("init")

-- Drop terminal
-- Utils.dropterminal("--startup", "kitty")

-- Clipboard manager
Utils.once("wl-paste --type text --watch cliphist store")
Utils.once("wl-paste --type image --watch cliphist store")

-- Bluetooth
Utils.once("blueman-applet")

-- pm2
Utils.once("pm2 resurrect")
