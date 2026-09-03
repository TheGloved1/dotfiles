#!/usr/bin/env bash
# setup-cosmic-niri-pkexec.sh — one-click launcher
# Runs system part via pkexec (GUI auth popup) and then user part.
# Just run: bash ~/setup-cosmic-niri-pkexec.sh
set -euo pipefail

echo "==> Running system part via pkexec (you'll get an auth popup)..."
pkexec bash /home/gloves/setup-cosmic-niri-system.sh

echo ""
echo "==> System part finished. Running user part..."
bash /home/gloves/setup-cosmic-niri-user.sh

echo ""
echo "All done! Log out and select 'COSMIC on niri' at the greeter."
