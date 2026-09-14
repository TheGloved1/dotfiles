#!/usr/bin/env bash
# set‑steamvr‑openxr.sh
# ------------------------------------------------------------
# Makes SteamVR the default OpenXR runtime on any Linux distro.
# It works whether you have root (system‑wide) or only user rights
# (per‑user).  No external dependencies required.
# ------------------------------------------------------------
# Usage:
#   ./set‑steamvr‑openxr.sh          # user‑only (no sudo)
#   sudo ./set‑steamvr‑openxr.sh    # system‑wide (requires sudo)
# ------------------------------------------------------------

set -euo pipefail

get_remove_link() {
  local result=false
  local arg
  for arg in "$@"; do
    case "$arg" in
    --remove | -r)
      result=true
      break
      ;;
    esac
  done
  printf '%s\n' "$result"
}

remove_link=""
remove_link=$(get_remove_link "$@")

# ------------------------------------------------------------
# 1️⃣  Find the SteamVR OpenXR manifest (JSON file)
# ------------------------------------------------------------
find_steamvr_manifest() {
  # Common locations – try them in order
  local candidates=(
    "$HOME/.steam/steam/steamapps/common/SteamVR/steamxr_linux64.json"
    "$HOME/.local/share/Steam/steamapps/common/SteamVR/steamxr_linux64.json"
    "/usr/share/steam/steamapps/common/SteamVR/steamxr_linux64.json"
    "/usr/lib/steam/steamapps/common/SteamVR/steamxr_linux64.json"
  )

  for path in "${candidates[@]}"; do
    if [[ -f "$path" ]]; then
      echo "$path"
      return 0
    fi
  done

  # If not found, try a broad search (slow, but still “drop‑in”)
  local found
  found=$(find "$HOME" "$HOME/.local" "/usr" -type f -name "steamxr_linux64.json" 2>/dev/null | head -n1 || true)
  if [[ -n "$found" ]]; then
    echo "$found"
    return 0
  fi

  echo "Error: SteamVR OpenXR manifest not found." >&2
  exit 1
}

# ------------------------------------------------------------
# 2️⃣  Determine where to place the active_runtime.json link
# ------------------------------------------------------------
setup_link() {
  local target_json=$1
  local mode=$2 # "user" or "system"

  if [[ $remove_link == "true" ]]; then
    if [[ $mode == "user" ]]; then
      rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/openxr/1/active_runtime.json"
      echo "🗑️  User-level OpenXR runtime removed:"
      echo "   ${XDG_CONFIG_HOME:-$HOME/.config}/openxr/1/active_runtime.json"
    else
      echo "⚠️  System‑wide configuration disabled. Run without sudo."
      # Uncomment the following lines to enable system‑wide configuration:
      # rm -f "/etc/xdg/openxr/1/active_runtime.json"
    fi
    return 0
  fi

  if [[ $mode == "user" ]]; then
    local cfg_dir="${XDG_CONFIG_HOME:-$HOME/.config}/openxr/1"
    mkdir -p "$cfg_dir"
    ln -sf "$target_json" "$cfg_dir/active_runtime.json"
    echo "✅ User‑level OpenXR runtime set to SteamVR:"
    echo "   $cfg_dir/active_runtime.json → $target_json"
  else
    echo "⚠️  System‑wide configuration disabled. Run without sudo."
    # Uncomment the following lines to enable system‑wide configuration:
    # local cfg_dir="/etc/xdg/openxr/1"
    # sudo mkdir -p "$cfg_dir"
    # sudo ln -sf "$target_json" "$cfg_dir/active_runtime.json"
    # echo "✅ System‑wide OpenXR runtime set to SteamVR:"
    # echo "   $cfg_dir/active_runtime.json → $target_json"
  fi
}

# ------------------------------------------------------------
# 3️⃣  Main
# ------------------------------------------------------------
main() {
  # Removal must work even if SteamVR is already uninstalled,
  # so skip the manifest lookup in that case.
  if [[ $remove_link == "true" ]]; then
    if [[ "$EUID" -eq 0 ]]; then
      setup_link "" "system"
    else
      setup_link "" "user"
    fi
    echo "Done."
    return 0
  fi

  local manifest
  manifest=$(find_steamvr_manifest)

  # Decide mode: if script is run with sudo (effective UID 0) → system,
  # otherwise → user.
  if [[ "$EUID" -eq 0 ]]; then
    setup_link "$manifest" "system"
  else
    setup_link "$manifest" "user"
  fi
}

main "$@"
