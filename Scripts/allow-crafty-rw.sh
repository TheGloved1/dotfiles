#!/usr/bin/env bash
set -euo pipefail

TARGET="/home/crafty"
USER="$(whoami)"

# Ensure target exists
if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET does not exist" >&2
  exit 1
fi

# Apply ACLs via pkexec for root privileges
pkexec sh -c "
  setfacl -R -m u:${USER}:rwX,m::rwx \"${TARGET}\"
  setfacl -R -d -m u:${USER}:rwX,m::rwx \"${TARGET}\"
"

echo "ACLs applied: user $USER now has read/write on $TARGET and new files inherit it."
echo "Verify with: getfacl -p \"$TARGET\""
