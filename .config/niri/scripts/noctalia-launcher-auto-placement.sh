#!/usr/bin/env bash
# noctalia-launcher-auto-placement.sh — auto-switch launcher between attached (idle) and floating centered (fullscreen)
# Why: Niri fullscreen (Mod+Shift+F) covers top layer-shell (bar) — attached launcher is behind bar and invisible.
# Floating launcher with floating_layer="overlay" stays above fullscreen (niri-wm.github.io/niri/Fullscreen-and-Maximize.html).
# Docs: docs.noctalia.dev/noctalia/configuration/shell/  (launcher_placement = attached|floating, launcher_position = center|auto)
# Niri IPC: no is_fullscreen field in stable 26.4.0 (PR #2836/#2270 pending) — heuristic tile_size ≈ output logical.
# User choices: focused workspace only, true fullscreen (Mod+Shift+F) only, settings.toml override, ignore centered.
# Visible check: fullscreen is considered onscreen only when is_focused==true (tile_pos_in_workspace_view is null for tiled in niri 26.4; see niri/issues/2381). Scrolling away unfocuses it → attached.
set -euo pipefail

SETTINGS="$HOME/.local/state/noctalia/settings.toml"
STATE_DIR="$(dirname "$SETTINGS")"
LOG="$STATE_DIR/launcher-watcher.log"
LOCK="$STATE_DIR/launcher-watcher.lock"

mkdir -p "$STATE_DIR"

# tolerance for size compare (gaps 8 + borders): normal 1904x1032 vs fullscreen 1920x1080
TOL=4
DEBOUNCE=0.35

log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*" | tee -a "$LOG" 2>/dev/null || echo "[$ts] $*"
}

# Ensure settings.toml exists with minimal skeleton if noctalia hasn't created it yet
ensure_settings_exists() {
  if [[ ! -f "$SETTINGS" ]]; then
    mkdir -p "$(dirname "$SETTINGS")"
    cat > "$SETTINGS" <<'EOF'
config_version = 13
[shell.panel]
launcher_placement = "attached"
launcher_position = "auto"
EOF
    log "created $SETTINGS skeleton"
  fi
}

# Python helper to atomically set launcher_placement (+ launcher_position when floating)
# Returns 0 if changed, 1 if no change, 2 on error
set_placement() {
  local desired="$1"  # attached|floating
  local position="auto"
  if [[ "$desired" == "floating" ]]; then
    position="center"
  fi

  python3 - "$SETTINGS" "$desired" "$position" <<'PY'
import sys
from pathlib import Path
try:
    import tomllib
except ImportError:
    import tomli as tomllib
try:
    import tomli_w
except ImportError:
    tomli_w = None

settings_path = Path(sys.argv[1])
desired = sys.argv[2]
position = sys.argv[3]

# read existing
try:
    data = tomllib.load(open(settings_path, "rb"))
except FileNotFoundError:
    data = {"config_version": 13}
except Exception as e:
    print(f"read error: {e}", file=sys.stderr)
    sys.exit(2)

if "shell" not in data or not isinstance(data["shell"], dict):
    data["shell"] = {}
if "panel" not in data["shell"] or not isinstance(data["shell"]["panel"], dict):
    data["shell"]["panel"] = {}

panel = data["shell"]["panel"]
old_placement = panel.get("launcher_placement")
old_position = panel.get("launcher_position")

# If old_placement is None, fallback is from config.toml (floating). We still treat None as needs update if desired != "floating" ?
# For idempotence, we track last applied in state file to avoid reload loops when config.toml provides default.
# Simple: if old matches desired and (floating check position), no change.

needs = False
if old_placement != desired:
    needs = True
if old_position != position:
    # position matters for next floating; ensure it matches desired state's position
    needs = True
# Also handle None defaults (config.toml provides floating/center, settings may be missing)
if old_placement is None:
    needs = True

if not needs:
    sys.exit(1)

panel["launcher_placement"] = desired
panel["launcher_position"] = position
# keep floating_offset etc untouched
# preserve floating_layer if missing? config provides overlay, but settings may override — leave as is.

# atomic write
if tomli_w is None:
    print("tomli_w missing", file=sys.stderr)
    sys.exit(2)

tmp = settings_path.with_suffix(".tmp")
with open(tmp, "wb") as f:
    tomli_w.dump(data, f)
tmp.replace(settings_path)
# success changed
sys.exit(0)
PY
  ret=$?
  if [[ $ret -eq 0 ]]; then
    return 0  # changed
  elif [[ $ret -eq 1 ]]; then
    return 1  # no change
  else
    log "ERROR: python set_placement failed code $ret for $desired"
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
  if [[ -z "$width" || "$width" == "null" ]]; then
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

evaluate_and_apply() {
  local logical wsid windows_json has_fs desired
  logical="$(get_logical || true)"
  if [[ -z "$logical" ]]; then
    log "warn: could not get logical output, skipping"
    return
  fi
  wsid="$(get_focused_ws || true)"
  if [[ -z "$wsid" ]]; then
    log "warn: could not get focused workspace, skipping"
    return
  fi
  windows_json="$(niri msg --json windows 2>/dev/null || echo "[]")"

  if has_fullscreen "$logical" "$wsid" "$windows_json"; then
    has_fs=1
    desired="floating"
  else
    has_fs=0
    desired="attached"
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
    # small delay to let niri update layout before next evaluate (avoid race where we evaluate too early after toggle)
    sleep 0.1
    # hot-reload via inotify is automatic, but explicit reload ensures immediate
    if command -v noctalia >/dev/null 2>&1; then
      noctalia msg config-reload 2>&1 | head -n 20 | tee -a "$LOG" 2>/dev/null || log "config-reload failed (maybe noctalia not running)"
      # optional validate
      noctalia config validate 2>&1 | head -n 50 | tee -a "$LOG" 2>/dev/null || true
    fi
    # verify effective
    local eff
    eff="$(grep -E 'launcher_placement|launcher_position' "$SETTINGS" 2>/dev/null | tr '\n' ' ' || true)"
    log "effective settings: $eff"
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
  evaluate_and_apply
  exit 0
fi

log "=== noctalia-launcher-auto-placement starting (TOL=$TOL, DEBOUNCE=$DEBOUNCE) ==="
log "SETTINGS=$SETTINGS"
ensure_settings_exists
# initial evaluate
evaluate_and_apply

# debounce state
LAST_EVAL=0
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
    evaluate_and_apply
  done
  exit 0
fi

# Use coprocess-style: niri event-stream piped to while
# Filter relevant events to reduce churn, but evaluate on any to stay safe
# Use process substitution to avoid subshell variable loss
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  case "$line" in
    *WindowsChanged*|*WindowOpenedOrChanged*|*WindowClosed*|*WindowFocusChanged*|*WorkspaceActivated*|*WindowLayoutsChanged*|*WorkspacesChanged*|*ConfigLoaded*)
      ;;
    *KeyboardLayoutsChanged*|*OverviewOpenedOrClosed*|*CastsChanged*)
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
      *WindowsChanged*|*WindowOpenedOrChanged*|*WindowClosed*|*WindowFocusChanged*|*WorkspaceActivated*|*WindowLayoutsChanged*|*WorkspacesChanged*|*ConfigLoaded*) continue ;;
      *) continue ;;
    esac
  done || true

  evaluate_and_apply
done < <(niri msg --json event-stream 2>/dev/null)

# If event-stream exits (niri restart), loop with backoff polling
log "event-stream ended, entering poll fallback"
while true; do
  sleep 2
  evaluate_and_apply
  # try to re-attach to event-stream if available
  if niri msg --json workspaces >/dev/null 2>&1; then
    log "re-attaching to event-stream"
    exec "$0" "$@"
  fi
done
