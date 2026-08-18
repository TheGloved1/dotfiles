#!/usr/bin/env bash
set -euo pipefail

SRC="$HOME/Scripts"
DST="$HOME/.local/bin"

mkdir -p "$DST"

for script in "$SRC"/*.sh; do
  [ -f "$script" ] || continue
  name="$(basename "$script")"
  link="$DST/$name"

  if [ -L "$link" ]; then
    rm "$link"
  elif [ -e "$link" ]; then
    echo "warning: $link exists and is not a symlink, skipping" >&2
    continue
  fi

  ln -s "$script" "$link"
  chmod +x "$script"
  echo "linked $link"
done
