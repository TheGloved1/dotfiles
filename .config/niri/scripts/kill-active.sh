#!/usr/bin/env bash
# kill-active.sh — picker-scoped close + precise force-kill
# 1. niri msg --json pick-window -> id (always picker, cancel = no-op)
# 2. niri msg action close-window --id <id> (per-window, graceful)
# 3. If window still exists (stuck/crashed), force-kill the PRECISE pid:
#    XWayland -> real X PID via xdotool/xprop, never xwayland-satellite
#    Steam game -> reaper/child leaf, never the Steam client PID
#    Native Wayland -> client PID for that id (warn if shared with siblings)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=helpers.sh
source "$DIR/helpers.sh"
require_niri

CLOSE_WAIT="${KILL_ACTIVE_CLOSE_WAIT:-1.0}"
TERM_WAIT="${KILL_ACTIVE_TERM_WAIT:-1.0}"

pick_raw=$(niri msg --json pick-window 2>/dev/null || echo "")
if [[ -z "$pick_raw" || "$pick_raw" == "null" ]]; then
  exit 0
fi
if printf '%s' "$pick_raw" | grep -q '"Err"'; then
  exit 0
fi

# Unwrap Ok -> PickedWindow -> window object (handles niri version drift)
pick=$(printf '%s' "$pick_raw" | jq -c '
  .Ok // .
  | .PickedWindow // .picked_window // .FocusedWindow // .focused_window // .
' 2>/dev/null || echo "")
if [[ -z "$pick" || "$pick" == "null" || "$pick" == "{}" ]]; then
  exit 0
fi

id=$(printf '%s' "$pick" | jq -r '.id // empty' 2>/dev/null || echo "")
title=$(printf '%s' "$pick" | jq -r '.title // ""' 2>/dev/null || echo "")
app_id=$(printf '%s' "$pick" | jq -r '.app_id // ""' 2>/dev/null || echo "")
niri_pid=$(printf '%s' "$pick" | jq -r '.pid // empty' 2>/dev/null || echo "")

if [[ -z "$id" || "$id" == "null" ]]; then
  exit 0
fi
if ! [[ "$id" =~ ^[0-9]+$ ]]; then
  notify "Kill Window" "Invalid window id: $id" "critical"
  exit 1
fi
[[ -z "$title" || "$title" == "null" ]] && title="window $id"
[[ "$app_id" == "null" ]] && app_id=""

window_exists() {
  local wid="$1"
  niri msg --json windows 2>/dev/null \
    | jq -e --argjson wid "$wid" 'map(select(.id == $wid)) | length > 0' >/dev/null 2>&1
}

window_pid() {
  local wid="$1"
  niri msg --json windows 2>/dev/null \
    | jq -r --argjson wid "$wid" 'map(select(.id == $wid)) | .[0].pid // empty' 2>/dev/null || echo ""
}

sibling_titles() {
  local pid="$1" wid="$2"
  niri msg --json windows 2>/dev/null \
    | jq -r --argjson pid "$pid" --argjson wid "$wid" \
      '[.[] | select(.pid == $pid and .id != $wid) | (.title // .app_id // .id | tostring)] | .[:5] | join(", ")' 2>/dev/null || echo ""
}

sibling_count() {
  local pid="$1"
  niri msg --json windows 2>/dev/null \
    | jq -r --argjson pid "$pid" '[.[] | select(.pid == $pid)] | length' 2>/dev/null || echo "1"
}

proc_comm() {
  local pid="$1"
  ps -o comm= -p "$pid" 2>/dev/null | tr -d ' ' || echo ""
}

proc_cmdline() {
  local pid="$1"
  tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || echo ""
}

is_satellite_pid() {
  local pid="$1" sat
  sat=$(pidof xwayland-satellite 2>/dev/null || pgrep -x xwayland-satellite 2>/dev/null || echo "")
  [[ -n "$sat" ]] && printf '%s' "$sat" | tr ' ' '\n' | grep -qx "$pid"
}

kill_ladder() {
  local pid="$1" label="$2"
  if ! kill -TERM "$pid" 2>/dev/null; then
    notify "Kill Window" "Failed to TERM $label (pid $pid)" "critical"
    return 1
  fi
  notify "Kill Window" "Sent TERM to $label (pid $pid)" "low"
  sleep "$TERM_WAIT"
  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL "$pid" 2>/dev/null || true
    notify "Kill Window" "Sent KILL to $label (pid $pid)" "normal"
  fi
}

# Recursively list descendant PIDs via /proc/*/task/*/children (fallback: ps)
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

# ── Phase 1: graceful per-window close ──────────────────────────────
niri msg action close-window --id "$id" 2>/dev/null || true
sleep "$CLOSE_WAIT"
if ! window_exists "$id"; then
  notify "Kill Window" "Closed $title" "low"
  exit 0
fi

# Window is stuck; resolve a precise kill target for THIS window id.
pid=$(window_pid "$id")
[[ -z "$pid" || "$pid" == "null" ]] && pid="$niri_pid"
if [[ -z "$pid" || "$pid" == "null" || "$pid" == "0" ]]; then
  notify "Kill Window" "$title is stuck but has no PID to force-kill" "critical"
  exit 1
fi
if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
  notify "Kill Window" "Invalid PID: $pid" "critical"
  exit 1
fi

# ── Phase 2a: XWayland — real X PID, never the satellite ─────────────
# niri reports the satellite PID for all X11 windows; killing it kills
# every XWayland app (Steam + Discord + games). Resolve the true client.
if [[ -n "${DISPLAY:-}" ]] && { is_satellite_pid "$pid" || is_exec xdotool; }; then
  xid=""
  xpid=""
  # Focus-INDEPENDENT: correlate by window title (the picked/clicked window
  # is not always the active one, so getactivewindow can't be trusted).
  if is_exec xdotool; then
    read -r xid xpid <<< "$(x11_resolve_by_title "$title" "$app_id" 2>/dev/null || echo "")"
  fi
  if [[ "$xpid" =~ ^[0-9]+$ && "$xpid" != "0" ]] && ! is_satellite_pid "$xpid"; then
    # Server-side window destroy first: removes THIS X window even if the
    # client is hung, without killing any process.
    if [[ "$xid" =~ ^[0-9]+$ ]]; then
      if is_exec xdotool; then
        xdotool windowclose "$xid" 2>/dev/null || true
        sleep "$CLOSE_WAIT"
      fi
      if window_exists "$id" && is_exec wmctrl; then
        wmctrl -ic "$xid" 2>/dev/null || true
        sleep "$CLOSE_WAIT"
      fi
      if ! window_exists "$id"; then
        notify "Kill Window" "Force-closed X11 window $title" "low"
        exit 0
      fi
    fi
    kill_ladder "$xpid" "$title (X11 client)"
    sleep 0.5
    if ! window_exists "$id" && ! kill -0 "$xpid" 2>/dev/null; then
      exit 0
    fi
    if ! window_exists "$id"; then
      exit 0
    fi
    notify "Kill Window" "$title (X11 pid $xpid) still present after KILL" "critical"
    exit 1
  elif is_satellite_pid "$pid"; then
    notify "Kill Window" "$title is XWayland but its real X PID is unknown — refusing to kill xwayland-satellite (would kill all X apps)" "critical"
    exit 1
  fi
fi

# ── Phase 2b: Steam game — reaper/child leaf, never Steam client ─────
comm=$(proc_comm "$pid")
cmdline=$(proc_cmdline "$pid")
lower_app=$(printf '%s' "$app_id" | tr '[:upper:]' '[:lower:]')
if [[ "$lower_app" == *steam* || "$comm" == *steam* || "$cmdline" == *steam* ]]; then
  mapfile -t kids < <(descendants "$pid")
  mapfile -t reapers < <(pgrep -f 'reaper SteamLaunch AppId=' 2>/dev/null || echo "")
  targets=()
  for r in "${reapers[@]}"; do
    [[ -z "$r" ]] && continue
    # Only reapers under our reported pid (this game, not other games)
    if printf '%s\n' "${kids[@]}" | grep -qx "$r"; then
      targets+=("$r")
    fi
  done
  if [[ "${#targets[@]}" -eq 0 && "${#kids[@]}" -gt 0 ]]; then
    # No reaper found: use deepest leaves (game), never the steam parent.
    # Leaves = children with no children of their own.
    for k in "${kids[@]}"; do
      if ! ps --ppid "$k" -o pid= 2>/dev/null | grep -q '[0-9]'; then
        [[ "$k" != "$pid" ]] && targets+=("$k")
      fi
    done
    # Prefer game-like binaries over helpers when identifiable
    game_like=()
    for t in "${targets[@]}"; do
      cl=$(proc_cmdline "$t")
      if printf '%s' "$cl" | grep -Eqi 'proton|wine|\.exe|pressure-vessel|reaper|game'; then
        game_like+=("$t")
      fi
    done
    [[ "${#game_like[@]}" -gt 0 ]] && targets=("${game_like[@]}")
  fi
  if [[ "${#targets[@]}" -gt 0 ]]; then
    for t in "${targets[@]}"; do
      kill_ladder "$t" "$title (game process)"
    done
    sleep 0.5
    if ! window_exists "$id"; then
      notify "Kill Window" "Stopped game without touching Steam client" "low"
      exit 0
    fi
    notify "Kill Window" "Game window $title still present — Steam client left running, use Steam Stop as fallback" "critical"
    exit 1
  fi
  notify "Kill Window" "$title looks like Steam ($comm) with no isolatable game child — refusing to kill Steam client PID $pid" "critical"
  exit 1
fi

# ── Phase 2c: native Wayland client PID ──────────────────────────────
count=$(sibling_count "$pid")
if [[ "$count" =~ ^[0-9]+$ && "$count" -gt 1 ]]; then
  sibs=$(sibling_titles "$pid" "$id")
  notify "Kill Window" "$title shares pid $pid with $((count - 1)) other window(s) [$sibs] — force will close them too (single-process app, no per-window SIGKILL exists)" "normal"
fi
kill_ladder "$pid" "$title"
sleep 0.5
if ! window_exists "$id"; then
  exit 0
fi
notify "Kill Window" "$title (pid $pid) still present after KILL" "critical"
exit 1
