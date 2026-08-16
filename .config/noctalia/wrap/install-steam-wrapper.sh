#!/bin/sh
# Installs the Steam launch wrapper to /usr/local/bin/steam with a DISPLAY
# fallback so Steam's X11-based update UI can initialize even when launched
# from a sanitized environment (e.g. Noctalia). Run with sudo:
#
#   sudo sh ~/.config/noctalia/wrap/install-steam-wrapper.sh

set -e

TARGET=/usr/local/bin/steam

install -m 755 /dev/stdin "$TARGET" <<'EOF'
#!/bin/sh
export DISPLAY="${DISPLAY:-:0}"
exec /usr/bin/steam --pipewire --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
EOF

echo "Installed $TARGET:"
cat "$TARGET"
echo "Verify with: which steam"