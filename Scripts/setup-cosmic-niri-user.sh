#!/usr/bin/env bash
# setup-cosmic-niri-user.sh — DEPRECATED for dedicated config approach
# Previously patched core/autostart.kdl with toggle logic.
# Now: plain niri uses ~/.config/niri/config.kdl (with noctalia)
#      COSMIC on niri uses ~/.config/niri/config-cosmic.kdl (with cosmic/, no noctalia)
#      Selected via ~/.local/share/wayland-sessions/cosmic-ext-niri.desktop + NIRI_CONFIG
# This script now just ensures that setup is intact.

set -euo pipefail
NIRI_DIR="$HOME/.config/niri"
echo "==> Dedicated config setup (user wrapper, no sudo)"
echo "  Plain:  $NIRI_DIR/config.kdl  (no cosmic includes)"
echo "  COSMIC: $NIRI_DIR/config-cosmic.kdl  (core + cosmic/, no noctalia/dms)"

if [[ ! -f "$NIRI_DIR/config-cosmic.kdl" ]]; then
  echo "Creating $NIRI_DIR/config-cosmic.kdl from config.kdl..."
  cp -a "$NIRI_DIR/config.kdl" "$NIRI_DIR/config-cosmic.kdl"
  # Remove noctalia includes, add cosmic
  # (manual edit recommended — this is minimal auto-patch)
  echo "Please manually edit $NIRI_DIR/config-cosmic.kdl to swap noctalia -> cosmic"
fi

mkdir -p "$NIRI_DIR/cosmic"
[[ -f "$NIRI_DIR/cosmic/autostart.kdl" ]] || cat > "$NIRI_DIR/cosmic/autostart.kdl" <<'KDL'
// ────────────── COSMIC on niri — bridge ──────────────
spawn-at-startup "cosmic-ext-alternative-startup"
KDL
[[ -f "$NIRI_DIR/cosmic/binds.kdl" ]] || cat > "$NIRI_DIR/cosmic/binds.kdl" <<'KDL'
binds {
    Mod+T { spawn "cosmic-term"; }
    Mod+D { spawn "cosmic-launcher"; }
    Mod+Shift+D { spawn "cosmic-app-library"; }
    Mod+Alt+L { spawn "cosmic-greeter"; }
}
KDL

echo "==> Validating..."
niri validate 2>&1 | tail -n 2
niri validate --config "$NIRI_DIR/config-cosmic.kdl" 2>&1 | tail -n 2
NIRI_CONFIG="$NIRI_DIR/config-cosmic.kdl" niri validate 2>&1 | tail -n 2

echo ""
echo "Desktop override: ~/.local/share/wayland-sessions/cosmic-ext-niri.desktop"
cat ~/.local/share/wayland-sessions/cosmic-ext-niri.desktop 2>/dev/null || echo "(missing — reinstall via setup)"
echo ""
echo "Wrappers: ~/.local/bin/niri (PATH shadow) + ~/.local/bin/niri-cosmic-wrapper"
ls -l ~/.local/bin/niri* 2>/dev/null
echo ""
echo "Done. Log out -> greeter -> select 'COSMIC on niri' to test."
echo "Plain niri: tty1, COSMIC on niri: tty2 (Ctrl+Alt+F2) + exec start-cosmic-ext-niri"
