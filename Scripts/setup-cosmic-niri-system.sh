#!/usr/bin/env bash
# setup-cosmic-niri-system.sh — SYSTEM PART (requires sudo)
# Installs the COSMIC-on-niri session files so it appears as an
# additional login option in greetd/gdm. Does NOT change your default.
# Safe to re-run. Arch/CachyOS only.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo: sudo bash $0"
  exit 1
fi

echo "==> Checking dependencies..."
pacman -Q cosmic-session niri >/dev/null || { echo "ERROR: cosmic-session or niri not installed"; exit 1; }

echo "==> Ensuring build deps (just, rust) are installed..."
pacman -S --needed --noconfirm just rust git 2>&1 | tail -n 20

# Detect AUR helper
AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then AUR_HELPER="paru"
fi

if [[ -z "$AUR_HELPER" ]]; then
  echo "ERROR: No AUR helper (yay/paru) found. Install yay first:"
  echo "  sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si"
  exit 1
fi

echo "==> Installing cosmic-ext-extra-sessions-niri-git via $AUR_HELPER..."
# Run as the original user if sudo was used (yay/paru must not run as root)
REAL_USER="${SUDO_USER:-gloves}"
if [[ "$REAL_USER" == "root" ]]; then
  # fallback: try to find non-root user
  REAL_USER=$(logname 2>/dev/null || echo "gloves")
fi

# Use sudo -u to run AUR helper as user
sudo -u "$REAL_USER" "$AUR_HELPER" -S --needed --noconfirm cosmic-ext-extra-sessions-niri-git

echo "==> Verifying install..."
ls -l /usr/bin/cosmic-ext-alternative-startup /usr/bin/start-cosmic-ext-niri /usr/share/wayland-sessions/cosmic-ext-niri.desktop
echo ""
cat /usr/share/wayland-sessions/cosmic-ext-niri.desktop
echo ""
echo "==> Cleaning up stale /usr/local install if present..."
if [[ -f /usr/local/bin/start-cosmic-ext-niri ]]; then
  echo "Removing orphan /usr/local/bin/start-cosmic-ext-niri (package now uses /usr/bin)"
  rm -f /usr/local/bin/start-cosmic-ext-niri
fi
# Ensure desktop Exec points to correct path (/usr/bin after PKGBUILD patch)
if grep -q "/usr/local/bin" /usr/share/wayland-sessions/cosmic-ext-niri.desktop; then
  echo "Patching desktop Exec to /usr/bin..."
  sed -i 's|/usr/local/bin|/usr/bin|g' /usr/share/wayland-sessions/cosmic-ext-niri.desktop
fi

echo ""
echo "==> System part done!"
echo "Files installed:"
pacman -Ql cosmic-ext-extra-sessions-niri-git 2>/dev/null || ls -l /usr/bin/cosmic-ext-alternative-startup /usr/bin/start-cosmic-ext-niri
echo ""
echo "Next: run the USER script (no sudo):"
echo "  bash ~/setup-cosmic-niri-user.sh"
echo ""
echo "Then log out and at the greeter select 'COSMIC on niri' from the session menu."
echo "Your default remains 'niri' (greeter default). This is additive only."
