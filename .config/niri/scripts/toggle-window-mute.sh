#!/usr/bin/env bash
# toggle-window-mute.sh — mute/unmute PipeWire playback streams of focused window
# Matches sink-inputs by focused window PID + descendants (covers Steam game
# audio living in a child process). XWayland satellite-PID guard included:
# never matches the satellite PID, resolves the real X client via xdotool.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=helpers.sh
source "$DIR/helpers.sh"
require_niri

for tool in pactl python3; do
  if ! is_exec "$tool"; then
    notify "Window Mute" "Missing required tool: $tool" "critical"
    exit 1
  fi
done

json=$(niri_json focused-window)
pid=$(printf '%s' "$json" | jq -r '.pid // .FocusedWindow.pid // .focused_window.pid // empty' 2>/dev/null || echo "")
title=$(printf '%s' "$json" | jq -r '.title // .FocusedWindow.title // .focused_window.title // ""' 2>/dev/null || echo "")
app_id=$(printf '%s' "$json" | jq -r '.app_id // .FocusedWindow.app_id // .focused_window.app_id // ""' 2>/dev/null || echo "")
[[ -z "$title" || "$title" == "null" ]] && title="focused window"
[[ "$app_id" == "null" ]] && app_id=""

descendants() {
  local root="$1"
  local -A seen=()
  local queue=("$root")
  seen["$root"]=1
  local out=()
  while [[ "${#queue[@]}" -gt 0 ]]; do
    local cur="${queue[0]}"
    queue=("${queue[@]:1}")
    local kids=""
    kids=$(cat "/proc/$cur/task/"*/children 2>/dev/null || echo "")
    if [[ -z "$kids" ]]; then
      kids=$(ps --ppid "$cur" -o pid= 2>/dev/null || echo "")
    fi
    for k in $kids; do
      [[ -n "${seen[$k]:-}" ]] && continue
      seen["$k"]=1
      out+=("$k")
      queue+=("$k")
    done
  done
  printf '%s\n' "${out[@]:-}"
}

is_satellite_pid() {
  local p="$1"
  local sat
  sat=$(pidof xwayland-satellite 2>/dev/null || pgrep -x xwayland-satellite 2>/dev/null || echo "")
  [[ -n "$sat" ]] && printf '%s' "$sat" | tr ' ' '\n' | grep -qx "$p"
}

# Build PID set (newline-separated). Never includes the satellite PID.
PIDSET=""
if [[ "$pid" =~ ^[0-9]+$ && "$pid" != "0" ]]; then
  if is_satellite_pid "$pid"; then
    # Focus-INDEPENDENT X resolution: the focused niri window is not always
    # the active X window, so correlate by title instead of getactivewindow.
    if [[ -n "${DISPLAY:-}" ]] && is_exec xdotool; then
      read -r _xid xpid <<< "$(x11_resolve_by_title "$title" "$app_id" 2>/dev/null || echo "")"
      if [[ "$xpid" =~ ^[0-9]+$ && "$xpid" != "0" ]] && ! is_satellite_pid "$xpid"; then
        PIDSET="$xpid"$'\n'"$(descendants "$xpid")"
      fi
    fi
  else
    PIDSET="$pid"$'\n'"$(descendants "$pid")"
  fi
fi
export PIDSET
export APP_ID="$app_id"

# Match sink-inputs by PID set, fallback to app-name match. Prints "idx mute".
mapfile -t MATCHES < <(pactl list sink-inputs 2>/dev/null | python3 -c "
import os, re, sys
pidset = set(x.strip() for x in os.environ.get('PIDSET','').splitlines() if x.strip())
appid = (os.environ.get('APP_ID','') or '').lower()
blocks = re.split(r'(?m)^Sink Input #', sys.stdin.read())
out = []
for b in blocks[1:]:
    m = re.match(r'(\d+)', b)
    if not m: continue
    idx = m.group(1)
    props = dict(re.findall(r'(?m)^\s+([\w.\-]+)\s*=\s*\"?([^\"]*)\"?\s*$', b))
    mute = 'yes' if re.search(r'(?m)^\s*Mute:\s*yes', b) else 'no'
    spin = (props.get('application.process.id','') or '').strip()
    if spin and spin in pidset:
        out.append(f'{idx} {mute}')
print('\n'.join(out))
")
# Python above emits pid-matches; run a second pass for app-name fallback if empty.
if [[ "${#MATCHES[@]}" -eq 0 && -n "$app_id" ]]; then
  mapfile -t MATCHES < <(pactl list sink-inputs 2>/dev/null | python3 -c "
import os, re, sys
appid = (os.environ.get('APP_ID','') or '').lower()
if not appid: raise SystemExit
blocks = re.split(r'(?m)^Sink Input #', sys.stdin.read())
for b in blocks[1:]:
    m = re.match(r'(\d+)', b)
    if not m: continue
    props = dict(re.findall(r'(?m)^\s+([\w.\-]+)\s*=\s*\"?([^\"]*)\"?\s*$', b))
    mute = 'yes' if re.search(r'(?m)^\s*Mute:\s*yes', b) else 'no'
    names = ' '.join([props.get('application.name',''), props.get('node.name',''), props.get('media.name','')]).lower()
    if appid and appid in names:
        print(f\"{m.group(1)} {mute} name\")
")
fi

if [[ "${#MATCHES[@]}" -eq 0 ]]; then
  notify "Window Mute" "No audio streams for $title" "low"
  exit 0
fi

# Deterministic toggle: if any stream unmuted -> mute all, else unmute all.
target=0
target_label="Unmuted"
for line in "${MATCHES[@]}"; do
  if [[ "$line" == *" no "* || "$line" == *" no" ]]; then
    target=1
    target_label="Muted"
    break
  fi
done

count=0
for line in "${MATCHES[@]}"; do
  idx="${line%% *}"
  if pactl set-sink-input-mute "$idx" "$target" 2>/dev/null; then
    count=$((count + 1))
  fi
done

if [[ "$count" -gt 0 ]]; then
  notify "Window Mute" "$target_label $title ($count stream(s))" "low"
else
  notify "Window Mute" "Failed to toggle mute for $title" "critical"
  exit 1
fi
