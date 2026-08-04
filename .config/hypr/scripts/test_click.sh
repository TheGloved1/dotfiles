#!/bin/bash
notify-send "Waybar click" "Workspace $1 clicked" -t 3000
echo "Clicked $1" >> /tmp/waybar_click.log
