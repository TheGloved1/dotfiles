#!/usr/bin/env bash
# noctalia-launcher-auto-placement.sh — auto-switch ALL Noctalia panels between attached (idle) and floating centered (fullscreen)
# Why: Niri fullscreen (Mod+Shift+F) covers top layer-shell (bar) — attached panels are behind bar and invisible.
# Floating panels with floating_layer="overlay" stay above fullscreen (niri-wm.github.io/niri/Fullscreen-and-Maximize.html).
# Docs: docs.noctalia.dev/noctalia/configuration/shell/  (all *_placement = attached|floating, *_position = center|auto)
# Niri IPC: no is_fullscreen field in stable 26.4.0 (PR #2836/#2270 pending) — heuristic tile_size ≈ output logical.
# Visible check: fullscreen is considered onscreen only when is_focused==true (tile_pos_in_workspace_view is null for tiled in niri 26.4; see niri/issues/2381). Scrolling away unfocuses it → attached.
# Scope: all core [shell.panel] (launcher, clipboard, control_center, wallpaper, session, polkit incl.) + all plugin_settings.* *placement keys; force attached/auto idle.
set -euo pipefail

SETTINGS="$HOME/.local/state/noctalia/settings.toml"
STATE_DIR="$(dirname "$SETTINGS")"
LOG="$STATE_DIR/launcher-watcher.log"
LOCK="$STATE_DIR/launcher-watcher.lock"

mkdir -p "$STATE_DIR"

# tolerance for size compare (gaps 8 + borders): normal 1904x1032 vs fullscreen 1920x1080
TOL=4
# Timing philosophy (sub-second decisions): the panel-open guard in
# confirm_attached is the primary protection and costs no sleep — an open
# panel means HOLD immediately. The sleeps below only damp sub-second focus
# bounce (debounce) and post-rebuild sampling churn (cooldown/confirm), so
# they stay small. Worst case a spurious write costs one extra ~1s Noctalia
# rebuild with no panel to kill; the floats/attaches themselves self-correct
# on the next event.
DEBOUNCE=0.1
# Hysteresis: switching back to attached REWRITES settings.toml and makes
# Noctalia rebuild every plugin (killing any open panel). niri emits transient
# focus states (e.g. is_focused=false blips when an exclusive-focus panel opens
# or focus bounces between workspaces), so a single has_fs=0 must NOT switch.
# The attached direction therefore waits ATTACHED_CONFIRM_DELAY and re-checks
# fresh state before writing. The floating direction stays immediate (needed for
# visibility over fullscreen).
ATTACHED_CONFIRM_DELAY=0.25
# Cooldown: after any successful switch, wait COOLDOWN seconds before allowing
# the next write. Each settings.toml rewrite makes Noctalia rebuild every
# plugin (~1s of layer-surface/focus churn in niri); sampling niri state during
# that churn reports phantom has_fs flips, which caused write->rebuild->flip
# feedback loops (see launcher-watcher.log 08:18 flapping). Spacing writes lets
# each rebuild settle before the next sample. Kept small (rebuilds measure
# ~1s) so toggling still feels responsive; the attached confirm below adds
# its own settle time on top for the dangerous direction.
COOLDOWN=2
LAST_SWITCH_FILE="$STATE_DIR/.last_switch"

log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*" | tee -a "$LOG" 2>/dev/null || echo "[$ts] $*"
}

# Ensure settings.toml exists with minimal skeleton if noctalia hasn't created it yet
ensure_settings_exists() {
  if [[ ! -f "$SETTINGS" ]]; then
    mkdir -p "$(dirname "$SETTINGS")"
    cat >"$SETTINGS" <<'EOF'
config_version = 13
[shell.panel]
launcher_placement = "attached"
launcher_position = "auto"
EOF
    log "created $SETTINGS skeleton"
  fi
}

# Delegates to standalone Python helper (all core + plugin panels)
# Returns 0 if changed, 1 if no change, 2 on error
set_placement() {
  local desired="$1" # attached|floating
  local position="auto"
  if [[ "$desired" == "floating" ]]; then
    position="center"
  fi
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local helper="$script_dir/noctalia-launcher-placement.py"
  if [[ ! -x "$helper" ]]; then
    log "ERROR: helper not found at $helper"
    return 2
  fi
  "$helper" --settings "$SETTINGS" --desired "$desired" --position "$position" --all --verbose 2>>"$LOG"
  local ret=$?
  if [[ $ret -eq 0 ]]; then
    return 0
  elif [[ $ret -eq 1 ]]; then
    return 1
  else
    log "ERROR: python helper failed code $ret for $desired/$position"
    return 2
  fi
}

# Get logical output size for focused output (fallback to outputs map)
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

# Returns 0 if has fullscreen on focused workspace AND visible (onscreen), 1 if not
# Visible = is_focused==true (niri guarantees focused fullscreen is in viewport; tile_pos_in_workspace_view is null for tiled in 26.4, so can't use it)
# When you scroll away, fullscreen becomes unfocused → has_fullscreen returns 1 → attached
has_fullscreen() {
  local logical="$1"
  local wsid="$2"
  local windows_json="$3"
  local width height
  width="$(echo "$logical" | jq -r '.width' 2>/dev/null)"
  height="$(echo "$logical" | jq -r '.height' 2>/dev/null)"
  if [[ -z "$width" || "$width" == "null" || -z "$height" || "$height" == "null" ]]; then
    return 1
  fi
  # heuristic: tile_size within TOL of logical, is_floating==false, workspace==focused, is_focused==true (visible)
  # future-proof: if is_fullscreen field exists, require it; if tile_pos_in_workspace_view becomes usable, prefer it; PR #4147 will add Workspace.scrolling_view_pos
  local count
  count="$(echo "$windows_json" | jq --argjson logical "$logical" --arg wsid "$wsid" --argjson tol "$TOL" '
    [ .[]
      | select(.workspace_id | tostring == $wsid)
      | select(.is_floating == false)
      | select(.is_focused == true)
      | select((.layout.tile_size[0] - $logical.width | fabs) < $tol and (.layout.tile_size[1] - $logical.height | fabs) < $tol)
      | if has("is_fullscreen") then select(.is_fullscreen == true) else . end
    ] | length
  ' 2>/dev/null || echo 0)"
  if [[ "$count" -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

# detect_desired sets globals: logical, wsid, windows_json, has_fs, desired.
detect_desired() {
  logical="$(get_logical || true)"
  if [[ -z "$logical" ]]; then
    log "warn: could not get logical output, skipping"
    return 0
  fi
  wsid="$(get_focused_ws || true)"
  if [[ -z "$wsid" ]]; then
    log "warn: could not get focused workspace, skipping"
    return 0
  fi
  windows_json="$(niri msg --json windows 2>/dev/null || echo "[]")"

  if has_fullscreen "$logical" "$wsid" "$windows_json"; then
    has_fs=1
    desired="floating"
  else
    has_fs=0
    desired="attached"
  fi
  return 0
}

# confirm_attached guards the destructive direction (settings rewrite +
# full plugin rebuild). Returns 0 to proceed, 1 to skip.
# Fail-safe: ANY doubt (status IPC failure, panel open) means SKIP. A missed
# genuine attached switch self-heals on the next niri event; a wrong write
# kills the user's open panel.
confirm_attached() {
  # Early check: if a panel is already open (or status is unreadable),
  # skip without even sleeping.
  local panel_open
  panel_open="$(noctalia msg status 2>/dev/null | jq -r 'if has("panelOpen") then (.panelOpen|tostring) else "unknown" end' 2>/dev/null || echo "unknown")"
  if [[ "$panel_open" != "false" ]]; then
    log "evaluate: ws=$wsid has_fs=0 but panel state is '${panel_open}' (open/unknown), staying floating (no write)"
    return 1
  fi
  # Re-query fresh state after a delay: transient has_fs=0 (focus blip,
  # workspace bounce, animation, rebuild churn) must not rewrite settings.
  sleep "$ATTACHED_CONFIRM_DELAY"
  detect_desired || return 0
  if [[ "$desired" == "floating" ]]; then
    log "evaluate: ws=$wsid transient has_fs=0 cleared, staying floating (no write)"
    return 1
  fi
  # Late check: the panel may have opened during the confirm sleep, and the
  # status IPC may fail mid-rebuild — both mean SKIP.
  panel_open="$(noctalia msg status 2>/dev/null | jq -r 'if has("panelOpen") then (.panelOpen|tostring) else "unknown" end' 2>/dev/null || echo "unknown")"
  if [[ "$panel_open" != "false" ]]; then
    log "evaluate: ws=$wsid has_fs=0 but panel state is '${panel_open}' (open/unknown), staying floating (no write)"
    return 1
  fi
  return 0
}

evaluate_and_apply() {
  local skip_cooldown="${1:-0}"
  detect_desired || return
  # Cooldown: if we switched recently, wait out the remainder then re-sample
  # fresh so we never sample niri state mid-rebuild. --once bypasses this.
  if [[ "$skip_cooldown" != "1" ]]; then
    local now last wait
    now="$(date +%s)"
    last="$(cat "$LAST_SWITCH_FILE" 2>/dev/null || echo 0)"
    [[ "$last" =~ ^[0-9]+$ ]] || last=0
    if ((now - last < COOLDOWN)); then
      wait=$((COOLDOWN - (now - last)))
      log "evaluate: cooldown active (${wait}s left, desired=$desired), waiting for settle"
      sleep "$wait"
      detect_desired || return
    fi
  fi
  if [[ "$desired" == "attached" ]]; then
    confirm_attached || return 0
  fi

  # debug details
  local reason
  reason="ws=$wsid logical=$(echo "$logical" | jq -c '. | "\(.width)x\(.height)"' -r 2>/dev/null) has_fs=$has_fs"
  log "evaluate: $reason desired=$desired (windows: $(echo "$windows_json" | jq -c '[.[] | select(.workspace_id | tostring == $wsid) | {id, tile: .layout.tile_size}]' 2>/dev/null | head -c 200))"

  # flock to avoid racing with Noctalia GUI Settings writes
  exec 9>"$LOCK"
  if ! flock -n 9; then
    log "skip: lock held, coalescing"
    return
  fi

  ensure_settings_exists
  if set_placement "$desired"; then
    log "switch -> $desired ($reason) — writing $SETTINGS and reloading"
    date +%s >"$LAST_SWITCH_FILE" 2>/dev/null || true
    # small delay to let niri update layout before next evaluate (avoid race where we evaluate too early after toggle)
    sleep 0.1
    # hot-reload via inotify is automatic, but explicit reload ensures immediate
    if command -v noctalia >/dev/null 2>&1; then
      noctalia msg config-reload 2>&1 | head -n 20 | tee -a "$LOG" 2>/dev/null || log "config-reload failed (maybe noctalia not running)"
      # optional validate
      noctalia config validate 2>&1 | head -n 50 | tee -a "$LOG" 2>/dev/null || true
    fi
    # verify effective (all placements)
    local eff
    eff="$(grep -cE '_placement = "attached"|_placement = "floating"|-placement = "attached"|-placement = "floating"' "$SETTINGS" 2>/dev/null || true)"
    log "effective placement keys: $eff (desired=$desired)"
  else
    rc=$?
    if [[ $rc -eq 1 ]]; then
      # no change — debug every 10th to avoid spam, but log first time
      :
    else
      log "set_placement error rc=$rc for $desired ($reason)"
    fi
  fi
  flock -u 9
  exec 9>&-
}

# --- main ---
# handle --once after all functions defined
if [[ "${1:-}" == "--once" ]]; then
  log "=== once evaluate ==="
  ensure_settings_exists
  evaluate_and_apply 1 || true
  exit 0
fi

log "=== noctalia-launcher-auto-placement starting (TOL=$TOL, DEBOUNCE=$DEBOUNCE) ==="
log "SETTINGS=$SETTINGS"
ensure_settings_exists
# initial evaluate (never fatal under set -e)
evaluate_and_apply || true

# debounce state (kept for external inspection, used implicitly via sleep/drain)
# shellcheck disable=SC2034
LAST_EVAL=0
# shellcheck disable=SC2034
PENDING=0

# trap cleanup
cleanup() {
  log "watcher exiting"
  exit 0
}
trap cleanup INT TERM

# stream JSON events; on any window/workspace/layout change, debounce evaluate
# niri msg --json event-stream emits JSON per line; we read with while
if ! command -v jq >/dev/null 2>&1; then
  log "ERROR: jq not found, falling back to polling every 2s"
  while true; do
    sleep 2
    evaluate_and_apply || true
  done
  exit 0
fi

# Use coprocess-style: niri event-stream piped to while
# Filter relevant events to reduce churn, but evaluate on any to stay safe
# Use process substitution to avoid subshell variable loss
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  case "$line" in
  *WindowsChanged* | *WindowOpenedOrChanged* | *WindowClosed* | *WindowFocusChanged* | *WorkspaceActivated* | *WindowLayoutsChanged* | *WorkspacesChanged* | *ConfigLoaded*)
    ;;
  *KeyboardLayoutsChanged* | *OverviewOpenedOrClosed* | *CastsChanged*)
    continue
    ;;
  *)
    continue
    ;;
  esac

  # synchronous debounce — sleep briefly to coalesce bursts (WindowLayoutsChanged fires rapidly)
  sleep "$DEBOUNCE"
  # drain any extra pending lines that arrived during sleep (non-blocking read)
  while IFS= read -t 0.05 -r _extra 2>/dev/null; do
    # if extra is relevant, keep draining
    case "$_extra" in
    *WindowsChanged* | *WindowOpenedOrChanged* | *WindowClosed* | *WindowFocusChanged* | *WorkspaceActivated* | *WindowLayoutsChanged* | *WorkspacesChanged* | *ConfigLoaded*) continue ;;
    *) continue ;;
    esac
  done || true

  evaluate_and_apply || true
done < <(niri msg --json event-stream 2>/dev/null)

# If event-stream exits (niri restart), loop with backoff polling
log "event-stream ended, entering poll fallback"
while true; do
  sleep 2
  evaluate_and_apply || true
  # try to re-attach to event-stream if available
  if niri msg --json workspaces >/dev/null 2>&1; then
    log "re-attaching to event-stream"
    exec "$0" "$@"
  fi
done
