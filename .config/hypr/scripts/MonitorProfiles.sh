#!/usr/bin/env bash
# For applying Pre-configured Monitor Profiles

# Pure-Lua config system: profiles are copied into configs/monitors.lua

# Variables
iDIR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/images"
SCRIPTSDIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
monitor_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/Monitor_Profiles"
target="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/configs/monitors.lua"

profile_ext="lua"
msg="❗NOTE:❗ This will overwrite ${XDG_CONFIG_HOME:-$HOME/.config}/hypr/configs/monitors.lua"

# Define the list of files to ignore
ignore_files=(
  "README"
)

# list of Monitor Profiles, sorted alphabetically with numbers first
mon_profiles_list=$(find -L "$monitor_dir" -maxdepth 1 -type f -name "*.${profile_ext}" | sed 's/.*\///' | sed "s/\.${profile_ext}$//" | sort -V)

# Remove ignored files from the list
for ignored_file in "${ignore_files[@]}"; do
    mon_profiles_list=$(echo "$mon_profiles_list" | grep -v -E "^$ignored_file$")
done
if [[ -z "$mon_profiles_list" ]]; then
    notify-send -u low -i "$iDIR/ja.png" "Monitor Profiles" "No .${profile_ext} profiles found in $monitor_dir"
    exit 1
fi

# Noctalia Menu
chosen_file=$(echo "$mon_profiles_list" | noctalia dmenu -p "$msg")

if [[ -n "$chosen_file" ]]; then
    full_path="$monitor_dir/$chosen_file.$profile_ext"
    mkdir -p "$(dirname "$target")"
    cp "$full_path" "$target"
    
    notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
"${SCRIPTSDIR}/Refresh.sh" &
