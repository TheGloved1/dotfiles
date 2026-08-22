#!/usr/bin/env bash
# toggle-blur.sh — Hypr SUPER+ALT+O blur toggle port
# Hypr toggled decoration.blur.enabled + active/inactive opacity + blur_opaque_rule
# Niri: toggle global blur { off } in config.kdl + reload
set -euo pipefail
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"

if [[ ! -f "$CONFIG" ]]; then
  notify "Blur Toggle" "Config not found: $CONFIG" "critical"
  exit 1
fi

# Check if blur is currently off (has `blur { off` or `blur {` with off)
if grep -qE '^[[:space:]]*blur[[:space:]]*\{[[:space:]]*off' "$CONFIG"; then
  # Currently off -> enable: replace `blur { off` with `blur {`
  # We keep passes/offset/noise/saturation as before; just remove `off`
  sed -i 's/^[[:space:]]*blur[[:space:]]*{[[:space:]]*off/blur {/' "$CONFIG"
  # Ensure blur block has our defaults if missing
  if ! grep -q 'passes' "$CONFIG"; then
    sed -i '/^blur {/a \    passes 2\n    offset 3.0\n    noise 0.02\n    saturation 1.0' "$CONFIG"
  fi
  niri msg action load-config-file 2>/dev/null || true
  if command -v niri >/dev/null; then niri validate 2>/dev/null || true; fi
  notify "Blur" "Enabled (passes 2 offset 3.0)" "low"
else
  # Currently on -> disable by inserting `off` after `blur {`
  sed -i 's/^[[:space:]]*blur[[:space:]]*{/blur { off/' "$CONFIG"
  niri msg action load-config-file 2>/dev/null || true
  notify "Blur" "Disabled" "low"
fi
