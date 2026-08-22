#!/usr/bin/env bash
# launch-terminal.sh — Hypr Utils.launch_terminal() port with fallback chain
# Uses niri msg spawn when inside niri, else bash background
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"

term="${1:-${TERMINAL:-kitty}}"
payload="${2:-}"

shell_quote() { printf "'%s'" "${1//\'/\'\\\'\'}"; }
command_bin() { printf '%s' "$1" | awk '{print $1}' | sed "s/^['\"]//;s/['\"]$//"; }

build_cmd() {
  local t="$1" p="$2"
  if [[ -z "$p" ]]; then printf '%s' "$t"; return; fi
  local bin; bin=$(command_bin "$t")
  local qp; qp=$(shell_quote "$p")
  if [[ "$bin" == "gnome-terminal" ]]; then printf '%s -- %s' "$t" "$qp"
  elif [[ "$bin" == "wezterm" ]]; then
    if [[ "$t" == *" start "* ]]; then printf '%s -- %s' "$t" "$qp"; else printf '%s start -- %s' "$t" "$qp"; fi
  else
    printf '%s -e sh -c %s' "$t" "$qp"
  fi
}

# Simple niri-aware launcher
launch_via_niri_or_bash() {
  local cmd="$1"
  # If inside niri, try niri spawn first (more reliable than & background)
  if [[ -n "${NIRI_SOCKET:-}" ]] && command -v niri >/dev/null 2>&1; then
    # Parse cmd into array respecting quotes is complex; fallback to spawn-sh
    if niri msg action spawn-sh -- "$cmd" 2>/dev/null; then
      return 0
    fi
  fi
  # Fallback: bash background
  bash -c "$cmd >/dev/null 2>&1 &" 2>/dev/null
}

candidates=()
append_unique() {
  local c; c=$(printf '%s' "$1" | xargs)
  [[ -z "$c" ]] && return
  for e in "${candidates[@]}"; do [[ "$e" == "$c" ]] && return; done
  candidates+=("$c")
}
append_unique "$term"
for c in kitty ghostty alacritty wezterm konsole gnome-terminal; do append_unique "$c"; done

for cand in "${candidates[@]}"; do
  cmd=$(build_cmd "$cand" "$payload")
  bin=$(command_bin "$cmd")
  if ! is_exec "$bin"; then continue; fi
  if launch_via_niri_or_bash "$cmd"; then
    exit 0
  fi
done
notify "Launch Terminal" "Unable to launch terminal (tried ${candidates[*]})" "critical"
# Log for debug when outside niri
echo "$(date): launch-terminal failed term=$term payload=$payload candidates=${candidates[*]}" >> /tmp/niri-launch.log
exit 1
