#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Rofi menu for Hyprland Quick Settings (SUPER SHIFT E)
# Adapted for the pure-Lua config system (configs/*.lua)

# Detect Hyprland config directory (pure-Lua config system: configs/*.lua)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
hypr_dir="$config_home/hypr"

# Resolve defaults file used to get terminal/editor values
defaults_file="$hypr_dir/configs/defaults.lua"
term="${term:-${TERM:-kitty}}"
edit="${edit:-${EDITOR:-nano}}"
visual="${visual:-${VISUAL:-}}"

if [[ -f "$defaults_file" ]]; then
    lua_term=$(sed -n 's/^[[:space:]]*DEFAULTS\.term[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$defaults_file" | tail -n1)
    lua_edit=$(sed -n 's/^[[:space:]]*DEFAULTS\.edit[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$defaults_file" | tail -n1)
    lua_visual=$(sed -n 's/^[[:space:]]*DEFAULTS\.visual[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$defaults_file" | tail -n1)
    [[ -n "$lua_term" ]] && term="$lua_term"
    [[ -n "$lua_edit" ]] && edit="$lua_edit"
    [[ -n "$lua_visual" ]] && visual="$lua_visual"
fi
# ##################################### #

# variables
configs="$hypr_dir/configs"
rofi_theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config-edit.rasi"
msg=' ⁉️ Choose what to do ⁉️'
iDIR="${XDG_CONFIG_HOME:-$HOME/.config}/swaync/images"
scriptsDir="$hypr_dir/scripts"

# Config files (all live in configs/*.lua)
config_defaults="$configs/defaults.lua"
config_env="$configs/env.lua"
config_keybinds="$configs/keybinds.lua"
config_startup="$configs/startup.lua"
config_window_rules="$configs/window_rules.lua"
config_layer_rules="$configs/layer_rules.lua"
config_settings="$configs/settings.lua"
config_decorations="$configs/decorations.lua"
config_animations="$configs/animations.lua"
config_laptops="$configs/laptops.lua"
config_monitors="$configs/monitors.lua"
config_workspaces="$configs/workspaces.lua"

# Function to show info notification
show_info() {
    if [[ -f "$iDIR/note.png" ]]; then
        notify-send -i "$iDIR/note.png" "Info" "$1"
    elif [[ -f "$iDIR/info.png" ]]; then
        notify-send -i "$iDIR/info.png" "Info" "$1"
    else
        notify-send "Info" "$1"
    fi
}

get_context_monitor_name() {
    if ! command -v hyprctl >/dev/null 2>&1; then
        return 1
    fi
    local monitor=""
    if command -v jq >/dev/null 2>&1; then
        monitor="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.monitor // empty' | head -n1)"
        if [[ -z "$monitor" ]]; then
            monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' | head -n1)"
        fi
    else
        monitor="$(hyprctl monitors 2>/dev/null | awk '/^Monitor/{name=$2} /focused: yes/{print name; exit}')"
    fi
    printf '%s' "$monitor"
}

# Determine whether an editor command is terminal-based (TUI)
is_tui_editor() {
    local -a cmd=("$@")
    local bin base arg
    [[ ${#cmd[@]} -eq 0 ]] && return 1

    bin="${cmd[0]}"
    base="$(basename "$bin")"

    case "$base" in
        vi|vim|nvim|nano|hx|helix|kak|micro|emacs-nox)
            return 0
            ;;
        emacs|emacsclient)
            for arg in "${cmd[@]:1}"; do
                case "$arg" in
                    -nw|--no-window-system|-t|--tty)
                        return 0
                        ;;
                esac
            done
            return 1
            ;;
    esac

    return 1
}

# Function to display the menu options
menu() {
    cat <<EOF
--- CONFIG FILES ---
Edit Defaults
Edit ENV Variables
Edit Keybinds
Edit Startup Apps
Edit Window Rules
Edit Layer Rules
Edit Settings
Edit Decorations
Edit Animations
Edit Laptop Settings
Edit Monitors
Edit Workspaces
--- UTILITIES ---
Set SDDM Wallpaper
Change Starship Prompt
Choose Kitty Terminal Theme
Choose Ghostty Terminal Theme
Configure Monitors (nwg-displays)
Configure Workspace Rules (nwg-displays)
GTK Settings (nwg-look)
QT Apps Settings (qt6ct)
QT Apps Settings (qt5ct)
Set Hyprlock Wallpaper
Choose Hyprland Animations
Choose Monitor Profiles
Choose Rofi Themes
Search for Keybinds
Toggle Waybar Weather units (C/F)
Toggle Waybar Clock (12H/24H)
Toggle Game Mode
Switch Dark-Light Theme
EOF
}

# Main function to handle menu selection
main() {
    local quick_settings_monitor
    quick_settings_monitor="$(get_context_monitor_name)"
    choice=$(menu | rofi -i -dmenu -config $rofi_theme -mesg "$msg")
    
    # Map choices to corresponding files
    case "$choice" in
        "Edit Defaults") file="$config_defaults" ;;
        "Edit ENV Variables") file="$config_env" ;;
        "Edit Keybinds") file="$config_keybinds" ;;
        "Edit Startup Apps") file="$config_startup" ;;
        "Edit Window Rules") file="$config_window_rules" ;;
        "Edit Layer Rules") file="$config_layer_rules" ;;
        "Edit Settings") file="$config_settings" ;;
        "Edit Decorations") file="$config_decorations" ;;
        "Edit Animations") file="$config_animations" ;;
        "Edit Laptop Settings") file="$config_laptops" ;;
        "Edit Monitors") file="$config_monitors" ;;
        "Edit Workspaces") file="$config_workspaces" ;;
        "Set SDDM Wallpaper")
            if [[ -n "$quick_settings_monitor" ]]; then
                "$scriptsDir/sddm_wallpaper.sh" --normal "$quick_settings_monitor"
            else
                "$scriptsDir/sddm_wallpaper.sh" --normal
            fi
            ;;
        "Change Starship Prompt") $scriptsDir/ChangeStarshipPrompt.sh ;;
        "Choose Kitty Terminal Theme") $scriptsDir/Kitty_themes.sh ;;
        "Choose Ghostty Terminal Theme") $scriptsDir/Ghostty_themes.sh ;;
        "Configure Monitors (nwg-displays)") 
            if ! command -v nwg-displays &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-displays first"
                exit 1
            fi
            nwg-displays ;;
        "Configure Workspace Rules (nwg-displays)") 
            if ! command -v nwg-displays &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-displays first"
                exit 1
            fi
            nwg-displays ;;
		"GTK Settings (nwg-look)") 
            if ! command -v nwg-look &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-look first"
                exit 1
            fi
            nwg-look ;;
		"QT Apps Settings (qt6ct)") 
            if ! command -v qt6ct &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install qt6ct first"
                exit 1
            fi
            qt6ct ;;
		"QT Apps Settings (qt5ct)") 
            if ! command -v qt5ct &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install qt5ct first"
                exit 1
            fi
            qt5ct ;;
        "Set Hyprlock Wallpaper")
            if [[ -n "$quick_settings_monitor" ]]; then
                "$scriptsDir/HyprlockWallpaperSelect.sh" "$quick_settings_monitor"
            else
                "$scriptsDir/HyprlockWallpaperSelect.sh"
            fi
            ;;
        "Choose Hyprland Animations") $scriptsDir/Animations.sh ;;
        "Choose Monitor Profiles") $scriptsDir/MonitorProfiles.sh ;;
        "Choose Rofi Themes") $scriptsDir/RofiThemeSelector.sh ;;
        "Search for Keybinds") $scriptsDir/KeyBinds.sh ;;
        "Toggle Waybar Weather units (C/F)") $scriptsDir/Toggle-weather-waybar-units.sh ;;
        "Toggle Waybar Clock (12H/24H)") $scriptsDir/ToggleWaybarTime.sh ;;
        "Toggle Game Mode") $scriptsDir/GameMode.sh ;;
        "Switch Dark-Light Theme") $scriptsDir/DarkLight.sh ;;
        *) return ;;  # Do nothing for invalid choices
    esac

    # Open selected file using configured editor
    if [ -n "$file" ]; then
        local -a edit_cmd term_cmd visual_cmd selected_cmd
        read -r -a edit_cmd <<< "$edit"
        read -r -a term_cmd <<< "$term"
        [[ -n "$visual" ]] && read -r -a visual_cmd <<< "$visual"
        selected_cmd=("${edit_cmd[@]}")
        [[ ${#visual_cmd[@]} -gt 0 ]] && selected_cmd=("${visual_cmd[@]}")

        if is_tui_editor "${selected_cmd[@]}"; then
            "${term_cmd[@]}" -e "${selected_cmd[@]}" "$file"
        else
            "${selected_cmd[@]}" "$file" >/dev/null 2>&1 &
        fi
    fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

main
