#!/usr/bin/env bash
set -euo pipefail

# Hyprsunset toggle + Waybar status helper
# Phase 1: manual toggle only (no scheduling)
# Icons:
# - Off: bright sun
# - On: sunset icon if available, otherwise a blue sun
#
# Customize via env vars:
#   HYPRSUNSET_TEMP   default 4500 (K)
#   HYPRSUNSET_ICON_MODE  sunset|blue  (default: sunset)

STATE_FILE="$HOME/.cache/.hyprsunset_state"
TARGET_TEMP="${HYPRSUNSET_TEMP:-4500}"
ICON_MODE="${HYPRSUNSET_ICON_MODE:-sunset}"

ensure_state() {
  [[ -f "$STATE_FILE" ]] || echo "off" > "$STATE_FILE"
}

# Render icons using pango markup to allow colorization
icon_off() {
  # universally available sun symbol
  printf "☀"
}

icon_on() {
  case "$ICON_MODE" in
    sunset)
      # sunset emoji (falls back to tofu if no emoji font)
      printf "🌇"
      ;;
    blue)
      # no color in text; rely on CSS .on to style if desired
      printf "☀"
      ;;
    *)
      printf "☀"
      ;;
  esac
}

# Stop every hyprsunset and wait until the CTM manager is actually released.
# Hyprsunset holds Hyprland's single CTM manager exclusively; a killed
# instance can take up to ~5s to disconnect, and any new instance started
# before then is refused ("A CTM manager is already running") and exits.
# Note: SIGTERM alone can deadlock hyprsunset's teardown (its poll thread
# never re-checks the terminate flag while blocked), so escalate to SIGKILL.
stop_all() {
  pkill -x hyprsunset 2>/dev/null || true
  for _ in $(seq 1 30); do
    pgrep -x hyprsunset >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  pkill -9 -x hyprsunset 2>/dev/null || true
  for _ in $(seq 1 30); do
    pgrep -x hyprsunset >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  return 1
}

cmd_toggle() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"

  if [[ "$state" == "on" ]]; then
    # Turning OFF: killing hyprsunset reverts the screen (Hyprland resets
    # the CTM to identity when the manager disconnects).
    stop_all || true
    echo off > "$STATE_FILE"
    notify-send -u low "Hyprsunset: Disabled" || true
  else
    # Turning ON: make sure the old manager is fully gone, then start.
    if stop_all; then
      if command -v hyprsunset >/dev/null 2>&1; then
        nohup hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
        sleep 0.5
      fi
      if pgrep -x hyprsunset >/dev/null 2>&1; then
        echo on > "$STATE_FILE"
        notify-send -u low "Hyprsunset: Enabled" "${TARGET_TEMP}K" || true
      else
        notify-send -u critical "Hyprsunset: Failed to enable" "No hyprsunset process is running" || true
      fi
    else
      notify-send -u critical "Hyprsunset: Failed to enable" "A previous instance would not stop" || true
    fi
  fi
}

cmd_status() {
  ensure_state
  # Prefer live process detection; fall back to state file
  if pgrep -x hyprsunset >/dev/null 2>&1; then
    onoff="on"
  else
    onoff="$(cat "$STATE_FILE" || echo off)"
  fi

  if [[ "$onoff" == "on" ]]; then
    txt="<span size='18pt'>$(icon_on)</span>"
    cls="on"
    tip="Night light on @ ${TARGET_TEMP}K"
  else
    txt="<span size='16pt'>$(icon_off)</span>"
    cls="off"
    tip="Night light off"
  fi
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$txt" "$cls" "$tip"
}

cmd_init() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"

  if [[ "$state" == "on" ]]; then
    stop_all || true
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
      sleep 0.5
    fi
  fi
}

case "${1:-}" in
  toggle) cmd_toggle ;;
  status) cmd_status ;;
  init) cmd_init ;;
  *) echo "usage: $0 [toggle|status|init]" >&2; exit 2 ;;
 esac
