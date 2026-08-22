#!/usr/bin/env bash
# hyprsunset.sh — Hypr Utils.hyprsunset() port for niri (wlsunset/gammastep)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
STATE_FILE="$HOME/.cache/.hyprsunset_state"
TARGET_TEMP="${HYPRSUNSET_TEMP:-4500}"

ensure_state() { [[ -f "$STATE_FILE" ]] || echo "off" > "$STATE_FILE"; }
is_exec_wlsunset() { is_exec wlsunset; }
is_exec_gammastep() { is_exec gammastep; }

stop_all() {
  pkill -9 -x wlsunset 2>/dev/null || true
  pkill -9 -x gammastep 2>/dev/null || true
  pkill -9 -x hyprsunset 2>/dev/null || true
  for _ in {1..30}; do
    if ! pgrep -x wlsunset >/dev/null 2>&1 && ! pgrep -x gammastep >/dev/null 2>&1; then return 0; fi
    sleep 0.05
  done
  return 1
}

start() {
  if is_exec_wlsunset; then
    wlsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
    return 0
  elif is_exec_gammastep; then
    gammastep -t 6500:"$TARGET_TEMP" >/dev/null 2>&1 &
    return 0
  elif is_exec hyprsunset; then
    hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
    return 0
  else
    notify "Night Light" "No wlsunset/gammastep/hyprsunset found" "critical"
    return 1
  fi
}

mode="${1:-toggle}"
case "$mode" in
  toggle)
    ensure_state
    state=$(tr -d '[:space:]' < "$STATE_FILE" 2>/dev/null || echo "off")
    if [[ "$state" == "on" ]]; then
      stop_all
      echo "off" > "$STATE_FILE"
      notify "Night Light" "Disabled" "low"
    else
      if stop_all; then
        if start; then
          sleep 0.3
          if pgrep -x wlsunset >/dev/null 2>&1 || pgrep -x gammastep >/dev/null 2>&1 || pgrep -x hyprsunset >/dev/null 2>&1; then
            echo "on" > "$STATE_FILE"
            notify "Night Light" "Enabled ${TARGET_TEMP}K" "low"
          else
            notify "Night Light" "Failed to start" "critical"
          fi
        fi
      fi
    fi
    ;;
  status)
    ensure_state
    if pgrep -x wlsunset >/dev/null 2>&1 || pgrep -x gammastep >/dev/null 2>&1 || pgrep -x hyprsunset >/dev/null 2>&1; then echo "on"; else tr -d '[:space:]' < "$STATE_FILE" 2>/dev/null || echo "off"; fi
    ;;
  init)
    ensure_state
    state=$(tr -d '[:space:]' < "$STATE_FILE" 2>/dev/null || echo "off")
    if [[ "$state" == "on" ]]; then stop_all; start >/dev/null 2>&1 || true; fi
    ;;
  *) echo "Usage: $0 [toggle|status|init]" >&2; exit 1;;
esac
