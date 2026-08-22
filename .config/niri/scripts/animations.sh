#!/usr/bin/env bash
# animations.sh — Hypr animations menu port for niri (tweak animations {} via picker)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
presets_dir="${XDG_CONFIG_HOME:-$HOME/.config}/niri/presets-animations"
mkdir -p "$presets_dir"

# Provide 3 presets mirroring Hypr curves: smooth / rubber / off
cat > "$presets_dir/smooth.kdl" <<'KDL'
animations {
    slowdown 1.0
    workspace-switch { spring damping-ratio=0.8 stiffness=900 epsilon=0.0001 }
    window-open { duration-ms 200 curve "ease-out-quad" }
    window-close { duration-ms 200 curve "ease-out-cubic" }
    window-movement { spring damping-ratio=0.85 stiffness=700 epsilon=0.0001 }
}
KDL
cat > "$presets_dir/rubber.kdl" <<'KDL'
animations {
    slowdown 1.0
    workspace-switch { spring damping-ratio=0.6 stiffness=700 epsilon=0.0001 }
    window-open { duration-ms 250 curve "ease-out-quad" }
    window-movement { spring damping-ratio=0.6 stiffness=500 epsilon=0.0001 }
}
KDL
cat > "$presets_dir/off.kdl" <<'KDL'
animations { off }
KDL

choices=$(ls -1 "$presets_dir" | sed 's/\.kdl$//')
chosen=""
if is_exec noctalia; then chosen=$(printf '%s\n' "$choices" | noctalia dmenu -p "Niri Animations" 2>/dev/null || true)
elif is_exec rofi; then chosen=$(printf '%s\n' "$choices" | rofi -dmenu -i -p "Niri Animations" 2>/dev/null || true)
else notify "Animations" "Install noctalia or rofi for picker" "low"; exit 0; fi
[[ -z "$chosen" ]] && exit 0
# Replace animations block in config.kdl with chosen preset (simple: swap file content)
# We store preset as include; easiest is to copy preset into config (replace block via python)
python3 <<PY
import pathlib, re
cfg=pathlib.Path("$CONFIG")
preset=pathlib.Path("$presets_dir/$chosen.kdl")
if cfg.exists() and preset.exists():
    text=cfg.read_text()
    new=preset.read_text().strip()
    # replace first animations { ... } block (non-greedy)
    text=re.sub(r'animations\s*\{.*?\n\}', new + "\n", text, count=1, flags=re.DOTALL)
    cfg.write_text(text)
PY
niri msg action load-config-file 2>/dev/null || true
notify "Animations" "Loaded $chosen" "low"
