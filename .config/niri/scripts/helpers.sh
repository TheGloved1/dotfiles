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
