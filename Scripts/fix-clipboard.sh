#!/usr/bin/env bash
# fix-clipboard.sh — quick fix for Noctalia v5 "configured encrypted storage key is missing"
# Clipboard resets on reboot when Noctalia starts before gnome-keyring secrets is ready.
# This script ensures Secret Service is up, unlocked, then restarts Noctalia
# so it reloads ~/.local/state/noctalia/clipboard/index.enc (encrypted history).
#
# Usage: ~/Scripts/fix-clipboard.sh  (or bind to a key in niri)
# After running, verify: Settings → Shell → Clipboard should show no error,
# and `noctalia msg clipboard-text` should retain history across reboots.

set -euo pipefail

echo "=== Noctalia Clipboard Fix (v5) ==="
echo ""

# 1) Ensure gnome-keyring secrets component is running
echo "[1/4] Ensuring gnome-keyring secrets..."
if ! busctl --user status org.freedesktop.secrets >/dev/null 2>&1; then
    echo "  Starting gnome-keyring-daemon --components=secrets..."
    gnome-keyring-daemon --start --components=secrets >/dev/null 2>&1 & disown || true
    sleep 0.5
fi
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true

# Wait up to 5s for Secret Service to appear (socket-activated)
echo "  Waiting for org.freedesktop.secrets..."
for i in {1..10}; do
    if busctl --user status org.freedesktop.secrets >/dev/null 2>&1; then
        echo "  ✓ Secret Service ready (PID $(busctl --user status org.freedesktop.secrets 2>&1 | grep -m1 PID= | cut -d= -f2))"
        break
    fi
    sleep 0.5
    if [[ $i -eq 10 ]]; then
        echo "  ✗ Secret Service not ready — install gnome-keyring? (sudo pacman -S gnome-keyring libsecret)"
        exit 1
    fi
done

# 2) Check if default collection is locked (common after reboot if PAM didn't unlock)
echo ""
echo "[2/4] Checking keyring unlock..."
LOCKED=$(busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/aliases/default org.freedesktop.Secret.Collection Locked 2>&1 || echo "b true")
if echo "$LOCKED" | grep -q "true"; then
    echo "  Keyring is LOCKED — prompting unlock..."
    echo "  (a dialog should appear; enter your login password)"
    # Trigger unlock by searching for Noctalia's key
    secret-tool search --unlock application noctalia >/dev/null 2>&1 || true
    sleep 1
    LOCKED2=$(busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/aliases/default org.freedesktop.Secret.Collection Locked 2>&1 || echo "b true")
    if echo "$LOCKED2" | grep -q "true"; then
        echo "  ✗ Still locked — unlock in seahorse or log out/in"
    else
        echo "  ✓ Unlocked"
    fi
else
    echo "  ✓ Keyring unlocked"
fi

# Verify master key exists
echo "  Checking Noctalia master key..."
if secret-tool search --all application noctalia 2>&1 | grep -q "Noctalia encrypted storage key"; then
    echo "  ✓ Master key found"
else
    echo "  ! Master key not found — Noctalia will create it on next write"
    echo "    (if you previously clicked 'Recover Private Storage', old history is gone)"
fi

# 3) Restart Noctalia so it reloads encrypted store
# Noctalia v5 auto-reopens when org.freedesktop.secrets appears, but a restart
# forces immediate reload and clears the "key is missing" UI error.
echo ""
echo "[3/4] Restarting Noctalia..."
if pgrep -x noctalia >/dev/null 2>&1; then
    echo "  Stopping noctalia..."
    pkill -x noctalia || true
    # Wait for exit
    for i in {1..10}; do
        pgrep -x noctalia >/dev/null 2>&1 || break
        sleep 0.3
    done
fi
echo "  Starting noctalia --daemon..."
noctalia --daemon >/dev/null 2>&1 & disown
sleep 1.5
if pgrep -x noctalia >/dev/null 2>&1; then
    echo "  ✓ Noctalia running (PID $(pgrep -x noctalia))"
else
    echo "  ✗ Failed to start — try: noctalia --daemon"
    exit 1
fi

# 4) Verify persistence
echo ""
echo "[4/4] Verifying..."
if [[ -f ~/.local/state/noctalia/clipboard/index.enc ]]; then
    SIZE=$(stat -c%s ~/.local/state/noctalia/clipboard/index.enc 2>/dev/null || stat -f%z ~/.local/state/noctalia/clipboard/index.enc 2>/dev/null)
    ENTRIES=$(ls ~/.local/state/noctalia/clipboard/entries/*.enc 2>/dev/null | wc -l)
    echo "  ✓ Store: ~/.local/state/noctalia/clipboard/index.enc (${SIZE} bytes, $ENTRIES entries)"
    ls -lh ~/.local/state/noctalia/clipboard/index.enc | awk '{print "    " $0}'
else
    echo "  ! No store yet — copy something to create it"
fi

CLIP=$(noctalia msg clipboard-text 2>&1 || true)
if [[ -n "$CLIP" && "$CLIP" != "(empty)" ]]; then
    echo "  Clipboard now: \"${CLIP:0:80}\""
else
    echo "  Clipboard empty — try: echo 'test-persist' | wl-copy; noctalia msg clipboard-text"
fi

echo ""
echo "=== Done ==="
echo "Next: open Settings → Shell → Clipboard"
echo "  • Error should be gone. If it still says 'key is missing', click 'Retry' once."
echo "  • Test: echo \"hello-\$(date +%s)\" | wl-copy  → reboot → check panel still shows it"
echo ""
echo "Tip: this race is already mitigated in ~/.config/niri/noctalia/autostart.kdl"
echo "     (gnome-keyring starts before noctalia). Run this script only when it still resets."
echo ""
echo "Note: ~/.cache/cliphist/db (79MB) is separate — Noctalia v5 ignores it."
echo "      cliphist persists via -db-path, but does NOT feed Noctalia's encrypted history."
