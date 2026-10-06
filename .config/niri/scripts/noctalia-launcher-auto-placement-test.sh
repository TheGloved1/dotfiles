#!/usr/bin/env bash
# noctalia-launcher-auto-placement-test.sh — DRY-RUN test rig for the
# "track last fullscreen + hold while a panel owns focus" idea.
#
# DIFFERENCES FROM PRODUCTION (noctalia-launcher-auto-placement.sh):
#   - NEVER writes settings.toml, NEVER runs config-reload/validate.
#     Decisions are only logged as TEST lines. Zero interference with the
#     running watcher and Noctalia (no rebuilds triggered by this script).
#   - Separate log/state files (launcher-watcher-test.log,
#     .last_fullscreen_test, .last_switch_test) so production is untouched.
#   - Adds the HOLD check under test: when detection says attached, but the
#     last-seen fullscreen window still exists fullscreen-sized AND a panel
#     takeover is corroborated (layer surface / panelOpen / active_window_id),
#     log TEST HOLD instead of TEST would-switch.
#   - --once only (no daemon mode): run manually at each scenario step.
#
# Usage:
#   ./noctalia-launcher-auto-placement-test.sh --once
# Scenario script (user drives, this only observes):
#   1. idle tiled workspace          -> expect: attached, no hold
#   2. Mod+Shift+F fullscreen        -> expect: floating (records id)
#   3. open history panel, run again -> expect: TEST HOLD (key validation)
#   4. close panel, run again        -> expect: floating (focus back)
#   5. scroll to neighbor column     -> expect: attached (active moved, no panel)
#   6. exit fullscreen               -> expect: attached
set -euo pipefail

SETTINGS="$HOME/.local/state/noctalia/settings.toml"
STATE_DIR="$(dirname "$SETTINGS")"
LOG="$STATE_DIR/launcher-watcher-test.log"
LAST_FS_FILE="$STATE_DIR/.last_fullscreen_test"
LAST_SWITCH_FILE="$STATE_DIR/.last_switch_test"

mkdir -p "$STATE_DIR"

TOL=4
ATTACHED_CONFIRM_DELAY=1.5

log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] TEST $*" | tee -a "$LOG" 2>/dev/null || echo "[$ts] TEST $*"
}

get_logical() {
  local lj
  lj="$(niri msg --json focused-output 2>/dev/null | jq -c '.logical' 2>/dev/null || true)"
  if [[ -z "$lj" || "$lj" == "null" ]]; then
    lj="$(niri msg --json outputs 2>/dev/null | jq -c 'to_entries[0].value.logical' 2>/dev/null || true)"
  fi
  if [[ -z "$lj" || "$lj" == "null" ]]; then
    echo ""
    return 1
  fi
  echo "$lj"
}

get_focused_ws() {
  local ws
  ws="$(niri msg --json workspaces 2>/dev/null | jq -r '.[] | select(.is_focused) | .id' 2>/dev/null | head -n1 || true)"
  if [[ -z "$ws" || "$ws" == "null" ]]; then
    ws="$(niri msg --json workspaces 2>/dev/null | jq -r '.[] | select(.is_active) | .id' 2>/dev/null | head -n1 || true)"
  fi
  echo "$ws"
}

# Same detector as production: focused + fullscreen-sized on focused workspace.
# On success sets FS_ID to the matching window id.
has_fullscreen() {
  local logical="$1"
  local wsid="$2"
  local windows_json="$3"
  FS_ID=""
  local width height
  width="$(echo "$logical" | jq -r '.width' 2>/dev/null)"
  height="$(echo "$logical" | jq -r '.height' 2>/dev/null)"
  if [[ -z "$width" || "$width" == "null" || -z "$height" || "$height" == "null" ]]; then
    return 1
  fi
  local hit
  hit="$(echo "$windows_json" | jq -r --argjson logical "$logical" --arg wsid "$wsid" --argjson tol "$TOL" '
    [ .[]
      | select(.workspace_id | tostring == $wsid)
      | select(.is_floating == false)
      | select(.is_focused == true)
      | select((.layout.tile_size[0] - $logical.width | fabs) < $tol and (.layout.tile_size[1] - $logical.height | fabs) < $tol)
      | if has("is_fullscreen") then select(.is_fullscreen == true) else . end
      | .id
    ] | first // empty
  ' 2>/dev/null || true)"
  if [[ -n "$hit" && "$hit" != "null" ]]; then
    FS_ID="$hit"
    return 0
  fi
  return 1
}

# still_fullscreen <windows_json> <logical> <winid>: 0 if winid exists and is
# still fullscreen-sized (regardless of focus). Persistence check that panels
# cannot disturb (panels are layer-shell, never in this list).
still_fullscreen() {
  local windows_json="$1" logical="$2" winid="$3"
  [[ -n "$winid" ]] || return 1
  local n
  n="$(echo "$windows_json" | jq --argjson logical "$logical" --arg winid "$winid" --argjson tol "$TOL" '
    [ .[]
      | select(.id | tostring == $winid)
      | select(.is_floating == false)
      | select((.layout.tile_size[0] - $logical.width | fabs) < $tol and (.layout.tile_size[1] - $logical.height | fabs) < $tol)
    ] | length
  ' 2>/dev/null || echo 0)"
  [[ "$n" -gt 0 ]]
}

# panel_surface_present: 0 if any noctalia panel layer-shell surface exists
# (compositor-side truth, works even mid-Noctalia-rebuild).
panel_surface_present() {
  niri msg layers 2>/dev/null | grep -qE "noctalia-panel|noctalia-attached-panel" || return 1
  return 0
}

panel_open_status() {
  noctalia msg status 2>/dev/null | jq -r 'if has("panelOpen") then (.panelOpen|tostring) else "unknown" end' 2>/dev/null || echo "unknown"
}

# workspace_active_id <workspaces_json> <wsid>: prints active_window_id or empty.
workspace_active_id() {
  echo "$1" | jq -r --arg wsid "$2" '.[] | select(.id | tostring == $wsid) | .active_window_id // empty' 2>/dev/null | head -n1 || true
}

evaluate_once() {
  local logical wsid windows_json workspaces_json has_fs desired
  logical="$(get_logical || true)"
  [[ -n "$logical" ]] || { log "no logical output, abort"; return 0; }
  wsid="$(get_focused_ws || true)"
  [[ -n "$wsid" ]] || { log "no focused workspace, abort"; return 0; }
  windows_json="$(niri msg --json windows 2>/dev/null || echo "[]")"
  workspaces_json="$(niri msg --json workspaces 2>/dev/null || echo "[]")"

  local eff
  eff="$(grep -oE 'launcher_placement = "[a-z]+"' "$SETTINGS" 2>/dev/null | head -n1 || echo "effective=?)")"

  if has_fullscreen "$logical" "$wsid" "$windows_json"; then
    has_fs=1
    desired="floating"
    echo "$FS_ID" >"$LAST_FS_FILE" 2>/dev/null || true
    log "ws=$wsid has_fs=1 desired=floating fs_id=$FS_ID ($eff) -> TEST would-switch floating"
    return 0
  fi

  has_fs=0
  desired="attached"
  local recorded
  recorded="$(cat "$LAST_FS_FILE" 2>/dev/null || echo "")"
  log "ws=$wsid has_fs=0 last_fs_id='${recorded}' ($eff)"

  # ---- HOLD check under test ----
  if [[ -n "$recorded" ]] && still_fullscreen "$windows_json" "$logical" "$recorded"; then
    local rec_ws
    rec_ws="$(echo "$windows_json" | jq -r --arg winid "$recorded" '.[] | select(.id | tostring == $winid) | .workspace_id' 2>/dev/null | head -n1 || true)"
    local surf="absent" pstat="unknown" awid=""
    panel_surface_present && surf="present"
    pstat="$(panel_open_status)"
    awid="$(workspace_active_id "$workspaces_json" "$wsid")"
    log "hold-check: id=$recorded still-big=yes ws=$rec_ws layer_surface=$surf panelOpen=$pstat active_win=$awid"
    if [[ "$surf" == "present" || "$pstat" == "true" || "$awid" == "$recorded" ]]; then
      log "ws=$wsid has_fs=0 BUT id=$recorded persists + takeover corroborated -> TEST HOLD (no write)"
      return 0
    fi
    log "hold-check: persists but NO takeover corroboration -> fall through to attached path"
  else
    log "hold-check: recorded id '${recorded}' gone or not fullscreen-sized -> no hold"
  fi

  # ---- normal attached path (dry-run: confirm, then report, never write) ----
  sleep "$ATTACHED_CONFIRM_DELAY"
  logical="$(get_logical || true)"
  wsid="$(get_focused_ws || true)"
  windows_json="$(niri msg --json windows 2>/dev/null || echo "[]")"
  if has_fullscreen "$logical" "$wsid" "$windows_json"; then
    echo "$FS_ID" >"$LAST_FS_FILE" 2>/dev/null || true
    log "confirm: transient cleared, fs_id=$FS_ID -> TEST would-switch floating"
    return 0
  fi
  log "ws=$wsid has_fs=0 confirmed -> TEST would-switch attached (dry-run, no write)"
  return 0
}

if [[ "${1:-}" == "--once" ]]; then
  evaluate_once || true
  exit 0
fi

echo "test rig is --once only: $0 --once" >&2
exit 2
