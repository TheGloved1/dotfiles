#!/usr/bin/env bash
# toggle-opaque.sh — Hypr SUPER+CTRL+O { set_prop opaque toggle } port
# Niri equivalent: toggle-window-rule-opacity (toggles opacity between 1.0 and window-rule opacity)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
require_niri
# This action toggles opacity defined in window-rules; if no rule, it still toggles
if niri msg action toggle-window-rule-opacity 2>/dev/null; then
  notify "Opacity" "Toggled window opacity" "low"
else
  notify "Opacity" "toggle-window-rule-opacity failed" "critical"
fi
