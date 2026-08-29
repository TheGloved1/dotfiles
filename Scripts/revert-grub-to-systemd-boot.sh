#!/usr/bin/env bash
set -euo pipefail

# revert-grub-to-systemd-boot.sh - Revert GRUB + HyperFluent, restore systemd-boot
# - Removes GRUB EFI entry, /boot/grub, restores /etc/default/grub from backup
# - Restores systemd-boot as default BootOrder (keeps fallback)
# - Safe to run even if GRUB not fully installed

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*" >&2; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }

BACKUP_BASE="/root/.grub-install-backup"
EEP="/boot"
AUTO_YES=false
for arg in "$@"; do case "$arg" in
  --yes|-y) AUTO_YES=true ;;
  --help|-h) echo "Usage: $0 [--yes] [--backup DIR]"; echo "Restores newest backup in $BACKUP_BASE-* if --backup not given"; exit 0 ;;
  --backup) shift; BACKUP_DIR="$2" ;;
esac; done

if [[ $EUID -ne 0 ]]; then err "Run as root: sudo $0"; exit 1; fi

confirm() {
  $AUTO_YES && return 0
  read -rp "$1 [y/N]: " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

# find latest backup if not specified
if [[ -z "${BACKUP_DIR:-}" ]]; then
  BACKUP_DIR=$(ls -1d ${BACKUP_BASE}-* 2>/dev/null | sort | tail -1 || true)
fi

log "Backup dir: ${BACKUP_DIR:-none found} (will proceed even if missing)"
echo ""
efibootmgr -v | head -n 30 || true
echo ""
if [[ -f /etc/default/grub ]]; then
  log "/etc/default/grub exists:"
  cat /etc/default/grub
  echo ""
fi
if [[ -d /boot/grub ]]; then log "/boot/grub exists: $(du -sh /boot/grub 2>&1 | head)"; else log "/boot/grub not found"; fi
if [[ -d /boot/EFI/GRUB ]]; then log "/boot/EFI/GRUB exists"; else log "/boot/EFI/GRUB not found"; fi

if ! confirm "Revert GRUB -> systemd-boot? This will remove GRUB entries and theme"; then
  log "Aborted"; exit 0
fi

# --- backup current state before revert ---
REVERT_BACKUP="/root/.grub-revert-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REVERT_BACKUP"
efibootmgr -v > "$REVERT_BACKUP/efibootmgr.before-revert" 2>&1 || true
if [[ -f /etc/default/grub ]]; then cp -a /etc/default/grub "$REVERT_BACKUP/" || true; fi
log "Pre-revert backup at $REVERT_BACKUP"

# --- remove GRUB EFI entries ---
log "Scanning EFI vars for GRUB"
GRUB_IDS=$(efibootmgr -v 2>&1 | grep -i "grub" | grep -oE "Boot[0-9A-Fa-f]{4}" | sed 's/Boot//' || true)
if [[ -n "$GRUB_IDS" ]]; then
  for id in $GRUB_IDS; do
    log "Removing Boot$id (GRUB)"
    efibootmgr -b "$id" -B || warn "failed to delete Boot$id"
  done
else
  log "No GRUB Boot entry found by label"
  # also check /boot/EFI/GRUB existence implies entry 000? maybe not in vars if install failed
fi

# --- remove GRUB files ---
if [[ -d /boot/EFI/GRUB ]]; then
  log "Removing /boot/EFI/GRUB"
  rm -rf /boot/EFI/GRUB
  ok "Removed /boot/EFI/GRUB"
fi
if [[ -d /boot/grub ]]; then
  log "Removing /boot/grub (themes, grub.cfg)"
  rm -rf /boot/grub
  ok "Removed /boot/grub"
fi
# also check grub2 path (Fedora)
if [[ -d /boot/grub2 ]]; then
  warn "Found /boot/grub2 - removing"
  rm -rf /boot/grub2
fi

# --- restore /etc/default/grub ---
if [[ -n "${BACKUP_DIR:-}" && -f "$BACKUP_DIR/grub.before" ]]; then
  log "Restoring /etc/default/grub from $BACKUP_DIR/grub.before"
  cp -a "$BACKUP_DIR/grub.before" /etc/default/grub
  ok "Restored /etc/default/grub"
elif [[ -n "${BACKUP_DIR:-}" && ! -f "$BACKUP_DIR/grub.before" && ! -f /etc/default/grub.bak ]]; then
  # original system had no /etc/default/grub (systemd-boot) - remove file to clean
  if [[ -f /etc/default/grub ]]; then
    warn "Original had no /etc/default/grub - removing current file (systemd-boot doesn't need it)"
    if confirm "Remove /etc/default/grub?"; then
      rm -f /etc/default/grub
      ok "Removed /etc/default/grub"
    else
      log "Kept /etc/default/grub - you can manually rm it"
    fi
  fi
else
  warn "No backup grub.before found - leaving /etc/default/grub as is"
fi

# --- ensure systemd-boot is present and up to date ---
log "Ensuring systemd-boot is installed"
if command -v bootctl &>/dev/null; then
  # reinstall systemd-boot to ESP
  if bootctl is-installed &>/dev/null; then
    log "systemd-boot already installed - updating"
    bootctl update || warn "bootctl update failed"
  else
    log "Installing systemd-boot to $EEP"
    bootctl install --esp-path="$EEP" || warn "bootctl install failed - try manually"
  fi
  bootctl status 2>&1 | head -n 40 || true
else
  warn "bootctl not found - install systemd package"
fi

# --- restore BootOrder to systemd-boot fallback ---
log "Setting BootOrder to keep Linux Boot Manager first"
# Find systemd-boot IDs
SYSTEMD_IDS=$(efibootmgr -v 2>&1 | grep -i "Linux Boot Manager" | grep -oE "Boot[0-9A-Fa-f]{4}" | sed 's/Boot//' || true)
FALLBACK_ID=$(efibootmgr -v 2>&1 | grep -i "Fallback.*Linux" | grep -oE "Boot[0-9A-Fa-f]{4}" | sed 's/Boot//' | head -1 || true)
if [[ -n "$SYSTEMD_IDS" ]]; then
  PRIMARY=$(echo "$SYSTEMD_IDS" | head -1)
  log "Primary systemd-boot: Boot$PRIMARY"
  if [[ -n "$FALLBACK_ID" ]]; then
    efibootmgr -o "${PRIMARY},${FALLBACK_ID}" 2>&1 | head || warn "efibootmgr -o failed"
  else
    efibootmgr -o "$PRIMARY" 2>&1 | head || warn "efibootmgr -o failed"
  fi
  ok "BootOrder set"
else
  warn "No Linux Boot Manager entry found - you may need to recreate via bootctl"
fi

# --- restore loader entries if backup exists ---
if [[ -n "${BACKUP_DIR:-}" && -d "$BACKUP_DIR/entries" ]]; then
  log "Entries backup exists at $BACKUP_DIR/entries (systemd-boot entries were kept anyway)"
fi

# --- cleanup grub env ---
if command -v grub-editenv &>/dev/null; then
  grub-editenv - unset theme 2>/dev/null || true
  grub-editenv - unset config_file 2>/dev/null || true
fi

echo ""
ok "Revert complete!"
log "Current efibootmgr:"
efibootmgr -v | head -n 20
echo ""
log "systemd-boot status:"
bootctl status 2>&1 | head -n 20 || true
echo ""
log "Pre-revert backup at: $REVERT_BACKUP"
if [[ -n "${BACKUP_DIR:-}" ]]; then log "Original install backup at: $BACKUP_DIR"; fi
log "Reboot and select 'Linux Boot Manager' in BIOS if needed - should boot cachy kernel"
log "To reinstall: sudo ~/Scripts/install-hyperfluent-grub.sh"
