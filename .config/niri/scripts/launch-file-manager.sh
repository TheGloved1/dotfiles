#!/usr/bin/env bash
# launch-file-manager.sh — Hypr Utils.launch_file_manager() port
# Defaults to yazi to match hypr/modules/02-defaults.lua DEFAULTS.files="yazi"
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"

fm="${1:-${FILE_MANAGER:-yazi}}"
term="${2:-${TERMINAL:-kitty}}"

# Log for debug
echo "$(date): launch-file-manager fm=$fm term=$term NIRI_SOCKET=${NIRI_SOCKET:-none}" >>/tmp/niri-launch.log

terminal_fms=("yazi" "lf" "ranger" "broot" "superfile")
is_tui() {
  local bin
  bin=$(printf '%s' "$1" | awk '{print $1}')
  for t in "${terminal_fms[@]}"; do [[ "$bin" == "$t" ]] && return 0; done
  return 1
}

launch_via_niri_or_bash() {
  local cmd="$1"
  if [[ -n "${NIRI_SOCKET:-}" ]] && command -v niri >/dev/null 2>&1; then
    if niri msg action spawn-sh -- "$cmd" 2>/dev/null; then
      return 0
    fi
  fi
  bash -c "$cmd >/dev/null 2>&1 &" 2>/dev/null
}

if is_tui "$fm"; then
  bin=$(printf '%s' "$fm" | awk '{print $1}')
  if ! is_exec "$bin"; then
    notify "File Manager" "Preferred '$fm' not installed, falling back" "normal"
  else
    # For niri, simple yazi via kitty is most reliable; use full payload only if needed
    if [[ "$bin" == "yazi" ]]; then
      # Hypr's yazi --cwd-file logic is for keeping shell cwd; niri can simplify
      # Try simple first: kitty -e yazi
      # payload="yazi"
      # If you want cwd-file behavior, uncomment next line and comment above:
      payload='f=$(mktemp); yazi --cwd-file="$f"; cwd=$(cat "$f" 2>/dev/null); [ -n "$cwd" ] && cd -- "$cwd" 2>/dev/null; rm -f "$f"; exec ${SHELL:-bash}'
      if launch_via_niri_or_bash "kitty -e sh -c $(printf "'%s'" "${payload//\'/\'\\\'\'}")"; then exit 0; fi
      # Fallback via helper
      exec "$DIR/launch-terminal.sh" "$term" "$payload"
    else
      payload="$fm; exec \${SHELL:-bash}"
      exec "$DIR/launch-terminal.sh" "$term" "$payload"
    fi
  fi
fi

# GUI fallbacks
for cand in "$fm" thunar dolphin nautilus pcmanfm-qt; do
  bin=$(printf '%s' "$cand" | awk '{print $1}')
  if is_exec "$bin"; then
    if launch_via_niri_or_bash "$cand"; then exit 0; fi
  fi
done

# Final fallbacks: yazi via terminal, superfile
if is_exec yazi; then
  if launch_via_niri_or_bash "kitty -e yazi"; then exit 0; fi
  exec "$DIR/launch-terminal.sh" "$term" "yazi"
fi
if is_exec superfile; then
  exec "$DIR/launch-terminal.sh" "$term" "superfile"
fi
notify "File Manager" "Unable to launch file manager (tried yazi/thunar/dolphin)" "critical"
echo "$(date): launch-file-manager failed fm=$fm" >>/tmp/niri-launch.log
exit 1
