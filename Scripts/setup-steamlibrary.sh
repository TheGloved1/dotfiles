#!/usr/bin/env bash
# setup-steamlibrary.sh
# ------------------------------------------------------------
# Creates home-dir links for Steam libraries on any Linux system:
#   ~/SteamLibrary          -> <primary>/steamapps/common
#   ~/SteamLibraryExternal  -> /mnt/External/SteamLibrary/steamapps/common
#   ~/SteamLibraryGames     -> /mnt/Games/SteamLibrary/steamapps/common
# Extra libraries are read from libraryfolders.vdf.
# No external dependencies required.
# ------------------------------------------------------------
# Usage:
#   ./setup-steamlibrary.sh          # create/update links
#   ./setup-steamlibrary.sh --remove # remove links
# ------------------------------------------------------------

set -euo pipefail

PRIMARY_LINK="$HOME/SteamLibrary"
REMOVE=false

for arg in "$@"; do
  case "$arg" in
    --remove|-r) REMOVE=true ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--remove]"
      echo "Creates ~/SteamLibrary for the primary library plus"
      echo "~/SteamLibrary<Parent> for each extra library in libraryfolders.vdf."
      exit 0
      ;;
  esac
done

find_vdf() {
  local candidates=(
    "$HOME/.steam/steam/steamapps/libraryfolders.vdf"
    "$HOME/.local/share/Steam/steamapps/libraryfolders.vdf"
    "$HOME/snap/steam/common/.steam/steam/steamapps/libraryfolders.vdf"
    "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/libraryfolders.vdf"
  )
  local f
  for f in "${candidates[@]}"; do
    if [[ -f "$f" ]]; then
      echo "$f"
      return 0
    fi
  done
  return 1
}

find_common_fallback() {
  local candidates=(
    "$HOME/.steam/steam/steamapps/common"
    "$HOME/.local/share/Steam/steamapps/common"
    "$HOME/snap/steam/common/.steam/steam/steamapps/common"
    "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common"
  )
  local p
  for p in "${candidates[@]}"; do
    if [[ -d "$p" ]]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

# Print library paths from VDF in index order, one per line.
parse_vdf_paths() {
  sed -n 's/.*"path"[[:space:]]\+"\(.*\)".*/\1/p' "$1"
}

sanitize_suffix() {
  local lib="$1" idx="$2"
  local parent base
  parent=$(dirname "$lib")
  base=$(basename "$parent")
  base=$(printf '%s' "$base" | tr -cd '[:alnum:]')
  if [[ -z "$base" ]]; then
    base="Lib$idx"
  else
    base="$(tr '[:lower:]' '[:upper:]' <<< "${base:0:1}")${base:1}"
  fi
  echo "$base"
}

link_one() {
  local target="$1" link="$2"
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "Skipping $link: exists and is not a symlink." >&2
    return 1
  fi
  ln -sfn "$target" "$link"
  echo "Linked: $link -> $target"
}

if [[ "$REMOVE" == true ]]; then
  shopt -s nullglob
  for link in "$HOME"/SteamLibrary*; do
    if [[ -L "$link" && "$(basename "$link")" == SteamLibrary* ]]; then
      rm -f "$link"
      echo "Removed: $link"
    fi
  done
  # Also cover the primary link when nullglob found nothing.
  if [[ -L "$PRIMARY_LINK" ]]; then
    rm -f "$PRIMARY_LINK"
    echo "Removed: $PRIMARY_LINK"
  fi
  exit 0
fi

VDF=""
if VDF=$(find_vdf); then
  mapfile -t LIBS < <(parse_vdf_paths "$VDF")
else
  LIBS=()
fi

if [[ "${#LIBS[@]}" -eq 0 ]]; then
  TARGET=""
  if ! TARGET=$(find_common_fallback); then
    echo "Error: no libraries found (no libraryfolders.vdf, no steamapps/common)." >&2
    echo "Install Steam and run it once first." >&2
    exit 1
  fi
  link_one "$TARGET" "$PRIMARY_LINK"
  exit 0
fi

# Index 0 -> ~/SteamLibrary
PRIMARY_COMMON="${LIBS[0]}/steamapps/common"
if [[ -d "$PRIMARY_COMMON" ]]; then
  link_one "$PRIMARY_COMMON" "$PRIMARY_LINK"
else
  echo "Warning: primary common missing: $PRIMARY_COMMON" >&2
fi

# Index >=1 -> ~/SteamLibrary<Parent>
idx=1
while [[ "$idx" -lt "${#LIBS[@]}" ]]; do
  lib="${LIBS[$idx]}"
  common="$lib/steamapps/common"
  if [[ ! -d "$common" ]]; then
    echo "Skipping $lib: $common not found (drive not mounted?)." >&2
    idx=$((idx + 1))
    continue
  fi
  suffix=$(sanitize_suffix "$lib" "$idx")
  link="$HOME/SteamLibrary$suffix"
  # Collision fallback: same name, different target -> append index.
  if [[ -L "$link" && "$(readlink "$link")" != "$common" ]]; then
    link="$HOME/SteamLibrary$suffix$idx"
  fi
  link_one "$common" "$link" || true
  idx=$((idx + 1))
done
