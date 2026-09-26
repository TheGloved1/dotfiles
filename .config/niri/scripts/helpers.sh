#!/usr/bin/env bash
# Shared helpers for niri scripts — Hypr utils.lua port (shell_quote, is_exec, notify, json)
set -euo pipefail

is_exec() { command -v "$1" >/dev/null 2>&1; }

shell_quote() { printf "'%s'" "${1//\'/\'\\\'\'}"; }

notify() {
  local title="$1" body="${2:-}" urgency="${3:-low}" icon="${4:-}"
  if ! is_exec notify-send; then return 0; fi
  if [[ -n "$icon" ]]; then
    notify-send -u "$urgency" -i "$icon" "$title" "$body" 2>/dev/null || true
  else
    notify-send -u "$urgency" "$title" "$body" 2>/dev/null || true
  fi
}

require_niri() {
  if [[ -z "${NIRI_SOCKET:-}" ]]; then
    notify "Niri IPC" "NIRI_SOCKET not set — run inside niri" "low"
    exit 0
  fi
}

# JSON helper: prefer jq, fallback to python3
json_get() {
  local json="$1" expr="$2"
  if is_exec jq; then
    printf '%s' "$json" | jq -r "$expr" 2>/dev/null
  elif is_exec python3; then
    python3 -c "import sys,json; data=json.load(sys.stdin); print($expr)" <<< "$json" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# niri msg wrappers (handle both Ok-wrapped and direct)
niri_json() {
  local req="$1"
  local raw
  if [[ "$req" == "windows" || "$req" == "workspaces" || "$req" == "focused-window" || "$req" == "focused-output" ]]; then
    raw=$(niri msg --json "$req" 2>/dev/null || echo "")
  else
    raw=$(niri msg --json "$req" 2>/dev/null || echo "")
  fi
  # Unwrap Ok if present
  if printf '%s' "$raw" | grep -q '"Ok"'; then
    if is_exec jq; then
      printf '%s' "$raw" | jq -c '.Ok // .' 2>/dev/null || printf '%s' "$raw"
    elif is_exec python3; then
      printf '%s' "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('Ok', d)))" 2>/dev/null || printf '%s' "$raw"
    else
      printf '%s' "$raw"
    fi
  else
    printf '%s' "$raw"
  fi
}

niri_action() {
  niri msg action "$@" 2>/dev/null || notify "Niri action failed" "$*" "low"
}

# x11_resolve_by_title <niri-title> [niri-app-id]
# Prints "XID PID" of the best X11-window match, or nothing.
# Focus-INDEPENDENT: enumerates X windows and correlates by title, since the
# clicked window is not always the active one (getactivewindow lies).
# Skips windows without a real client PID. Ties across different PIDs are
# broken with the WM_CLASS vs app_id hint (e.g. native "Steam" class Steam vs
# Proton steam.exe class steam_app_1284210); unbroken ties print nothing.
x11_resolve_by_title() {
  local needle="$1" app_hint="${2:-}"
  local norm_needle norm_app
  norm_needle=$(printf '%s' "$needle" | tr '[:upper:]' '[:lower:]')
  norm_app=$(printf '%s' "$app_hint" | tr '[:upper:]' '[:lower:]')
  [[ -z "$norm_needle" ]] && return 1
  [[ "$norm_needle" == "null" ]] && return 1
  [[ "$norm_app" == "null" ]] && norm_app=""
  if ! is_exec xdotool; then return 1; fi

  # Reads XIDs on stdin, prints "XID PID" of the unambiguous best match.
  _x11_pick() {
    local wid name pid norm_name cls norm_cls score
    local best="" best_pid="" best_score=-1 ambiguous=0
    while read -r wid; do
      [[ "$wid" =~ ^[0-9]+$ ]] || continue
      name=$(xdotool getwindowname "$wid" 2>/dev/null || echo "")
      [[ -z "$name" ]] && continue
      pid=$(xdotool getwindowpid "$wid" 2>/dev/null || echo "")
      [[ ! "$pid" =~ ^[0-9]+$ || "$pid" == "0" ]] && continue
      norm_name=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
      score=-1
      if [[ "$norm_name" == "$norm_needle" ]]; then score=3
      elif [[ "$norm_name" == *"$norm_needle"* ]]; then score=2
      elif [[ "$norm_needle" == *"$norm_name"* ]]; then score=1
      fi
      [[ "$score" -lt 0 ]] && continue
      if [[ -n "$norm_app" ]]; then
        cls=$(xdotool getwindowclassname "$wid" 2>/dev/null || echo "")
        norm_cls=$(printf '%s' "$cls" | tr '[:upper:]' '[:lower:]')
        [[ "$norm_cls" == "$norm_app" ]] && score=$((score + 2))
      fi
      if [[ "$score" -gt "$best_score" ]]; then
        best_score="$score"; best="$wid"; best_pid="$pid"; ambiguous=0
      elif [[ "$score" -eq "$best_score" && "$pid" != "$best_pid" ]]; then
        ambiguous=1
      fi
    done
    if [[ "$best_score" -ge 0 && "$ambiguous" -eq 0 ]]; then
      printf '%s %s\n' "$best" "$best_pid"
      return 0
    fi
    return 1
  }

  xdotool search --onlyvisible --name ".*" 2>/dev/null | _x11_pick && return 0
  xdotool search --name ".*" 2>/dev/null | _x11_pick && return 0
  return 1
}
