#!/usr/bin/env bash
# steam-ctl.sh — custom Steam move/uninstall that NEVER deletes compatdata unless --purge
# Hybrid TUI: gum menus + fzf fuzzy picker (like pac autoremove) + Home/External aliases
set -euo pipefail

VERSION="1.1.0"
STEAM_ROOT="/home/gloves/.local/share/Steam"
LIBRARY_VDF="$STEAM_ROOT/steamapps/libraryfolders.vdf"
STEAM_PID_FILE="/home/gloves/.steam/steam.pid"
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

# ---------- UI layout (consistent columns + ellipsis) ----------
# Fixed column widths for table and picker — keeps rows aligned, names truncated with …
COL_APPID=8
COL_SIZE=9
COL_PREFIX=10
COL_SHADER=8
COL_LIB=12
COL_NAME=34
COL_INSTALL=20

# Truncate/pad with display-width awareness (handles ✓, ®, …) via python
ui_trunc() {
  local str="$1" max="$2"
  python3 - "$str" "$max" <<'PY'
import sys
s=sys.argv[1]
m=int(sys.argv[2])
# use wcwidth-like: count each char as 1 (good for our chars: ✓, ®, … are 1)
# Python len counts codepoints correctly (bash ${#} also but python is consistent)
if len(s) > m:
    if m <= 1:
        print("…")
    else:
        print(s[:m-1] + "…")
else:
    print(s)
PY
}
ui_pad() {
  local str="$1" width="$2"
  python3 - "$str" "$width" <<'PY'
import sys
s=sys.argv[1]
w=int(sys.argv[2])
pad = w - len(s)
if pad < 0: pad = 0
print(s + " " * pad)
PY
}
ui_pad_right() {
  local str="$1" width="$2"
  python3 - "$str" "$width" <<'PY'
import sys
s=sys.argv[1]
w=int(sys.argv[2])
pad = w - len(s)
if pad < 0: pad = 0
print(" " * pad + s)
PY
}
draw_sep() {
  local w=$1 char=${2:--}
  python3 - "$w" "$char" <<'PY'
import sys
w=int(sys.argv[1])
c=sys.argv[2]
print(c * w)
PY
}

DRY_RUN=false
STOP_STEAM=false
KEEP_COMPDATA=true
KEEP_SHADERCACHE=true
PURGE_COMPDATA=false
PURGE_SHADERCACHE=false
FORCE=false
NO_TUI=false

log() { echo -e "${CYAN}[steam-ctl]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*" >&2; }
err() { echo -e "${RED}[error]${NC} $*" >&2; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }
dry() { echo -e "${YELLOW}[dry-run]${NC} $*"; }

usage() {
  cat <<EOF
${BOLD}steam-ctl v$VERSION${NC} — Steam move/uninstall without compatdata wipe (TUI)

${BOLD}USAGE:${NC}
  $(basename "$0") [command] [options] [args]
  $(basename "$0")                              Launch TUI (interactive)
  $(basename "$0") move [appid] [target]       Move between libraries (fzf picker if no appid)
  $(basename "$0") uninstall [appid]           Uninstall keep prefix (fzf picker if no appid)
  $(basename "$0") list                         List games + prefix status
  $(basename "$0") fix-libraries               Prune stale /run/media entry

${BOLD}ALIASES:${NC}
  Home, Internal, Main  → $STEAM_ROOT
  External, Ext, Mnt    → /mnt/External/SteamLibrary (auto-discovers, prefers /mnt over /run/media)
  You can also use full paths: /mnt/External/SteamLibrary, /home/gloves/.local/share/Steam

${BOLD}OPTIONS:${NC}
  --dry-run            Show actions without executing
  --stop-steam         Auto shutdown Steam before operation
  --keep-compatdata    Keep Proton prefix (default)
  --keep-shadercache   Keep shadercache (default)
  --purge-compatdata   Actually delete compatdata on uninstall
  --purge-shadercache  Actually delete shadercache
  --no-tui             Disable interactive TUI, require explicit args
  -f, --force          Skip confirmations
  -h, --help           Show this help

${BOLD}EXAMPLES:${NC}
  $(basename "$0")                              # TUI: pick action → fzf → confirm
  $(basename "$0") move                         # fzf pick game → pick target (Home/External)
  $(basename "$0") move 230410 Home             # shorthand, no full path needed
  $(basename "$0") move 230410 External --dry-run
  $(basename "$0") uninstall                    # fzf pick (multi TAB) → uninstall keep prefix
  $(basename "$0") uninstall 230410 --purge-compatdata

${BOLD}TUI:${NC}
  • Main menu via gum choose (Move/Uninstall/List/Fix/Quit)
  • Game picker via fzf --multi like pac autoremove (80-pacman.zsh:80) with preview
  • TAB multi-select, Ctrl-A select all, Enter confirm
EOF
}

# ---------- library discovery ----------

get_libraries() {
  if [[ -f "$LIBRARY_VDF" ]]; then
    grep -oP '"path"\s+"\K[^"]+' "$LIBRARY_VDF" || true
  fi
  if [[ ! -f "$LIBRARY_VDF" ]] || ! grep -q "$STEAM_ROOT" "$LIBRARY_VDF" 2>/dev/null; then
    echo "$STEAM_ROOT"
  fi
}

resolve_external() {
  local cand="/mnt/External/SteamLibrary"
  if [[ -d "$cand/steamapps" ]]; then echo "$cand"; return 0; fi
  local lib
  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    if [[ "$lib" != "$STEAM_ROOT" && -d "$lib/steamapps" ]]; then echo "$lib"; return 0; fi
  done < <(get_libraries | grep -v "^$STEAM_ROOT$" || true)
  local found
  found=$(find /mnt /run/media -maxdepth 4 -type d -name "SteamLibrary" 2>/dev/null | head -n1 || true)
  if [[ -n "$found" ]]; then echo "$found"; return 0; fi
  echo "$cand"
}

resolve_library_alias() {
  local input="$1"
  local lower
  lower=$(echo "$input" | tr '[:upper:]' '[:lower:]' | xargs 2>/dev/null || echo "$input")
  case "$lower" in
    home|internal|main|home~|steam|~/.local/share/steam) echo "$STEAM_ROOT"; return 0 ;;
    external|ext|mnt|mntexternal|external~|ext~|"") resolve_external; return 0 ;;
    *)
      if [[ "$input" == *"/"* ]]; then
        local p; p=$(realpath -m "$input" 2>/dev/null || echo "$input")
        echo "$p"; return 0
      fi
      # try exact path without slash alias
      if [[ -d "$input/steamapps" ]]; then echo "$(realpath -m "$input")"; return 0; fi
      echo "$input"; return 1
      ;;
  esac
}

find_source_lib() {
  local appid="$1"
  local lib manifest
  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    manifest="$lib/steamapps/appmanifest_${appid}.acf"
    if [[ -f "$manifest" ]]; then echo "$lib"; return 0; fi
  done < <(get_libraries)
  return 1
}

parse_manifest_field() {
  local manifest="$1" field="$2"
  grep -oP "\"$field\"\s+\"\K[^\"]+" "$manifest" 2>/dev/null | head -n1 || echo ""
}

is_steam_running() {
  if [[ -f "$STEAM_PID_FILE" ]]; then
    local pid; pid=$(cat "$STEAM_PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then return 0; fi
  fi
  pgrep -x steam >/dev/null 2>&1
}

stop_steam_if_needed() {
  if is_steam_running; then
    if [[ "$STOP_STEAM" == true ]]; then
      log "Shutting down Steam..."
      if command -v steam >/dev/null 2>&1; then steam -shutdown 2>/dev/null || true; fi
      for _ in {1..15}; do if ! is_steam_running; then break; fi; sleep 1; done
      if is_steam_running; then warn "Steam still running after 15s."; [[ "$FORCE" == true ]] || return 1; else success "Steam stopped."; fi
    else
      err "Steam is running. Close Steam or use --stop-steam."
      echo "  Hint: Steam > Exit, or: steam -shutdown"
      return 1
    fi
  fi
}

compatdata_realpath() {
  local appid="$1"
  local p1="$STEAM_ROOT/steamapps/compatdata/$appid"
  if [[ -e "$p1" ]]; then readlink -f "$p1" 2>/dev/null || echo "$p1"; else echo "$p1"; fi
}

shadercache_path() { echo "$1/steamapps/shadercache/$2"; }

is_interactive() {
  [[ "$NO_TUI" == true ]] && return 1
  [[ -t 0 && -t 1 ]] && return 0 || return 1
}

confirm() {
  local msg="$1"
  if [[ "$FORCE" == true ]] || [[ "$DRY_RUN" == true ]]; then return 0; fi
  if is_interactive && command -v gum >/dev/null 2>&1; then
    gum confirm "$msg" && return 0 || return 1
  fi
  echo -e "${YELLOW}$msg [y/N]${NC} "
  read -r ans; [[ "$ans" == "y" || "$ans" == "Y" ]]
}

# ---------- preview helper (avoids nested quoting hell) ----------
__preview_app() {
  local appid="${1:-}"; appid="${appid%% *}"; appid="$(echo -n "$appid" | tr -d '[:space:]')"
  [[ -z "$appid" ]] && { echo "no appid"; return 0; }
  local manifest
  manifest=$(find "$STEAM_ROOT/steamapps" "/mnt/External/SteamLibrary/steamapps" "/run/media/gloves/External/SteamLibrary/steamapps" -name "appmanifest_${appid}.acf" 2>/dev/null | head -n1 || true)
  echo "=== $appid ==="
  if [[ -n "$manifest" && -f "$manifest" ]]; then
    echo "manifest: $manifest"
    grep -E '"(name|installdir|SizeOnDisk|buildid|StateFlags)"' "$manifest" 2>/dev/null | head -n 10 || true
    echo ""
    echo "--- compatdata ---"
    local cdir="$STEAM_ROOT/steamapps/compatdata/$appid"
    if [[ -d "$cdir" ]]; then
      du -sh "$cdir" 2>&1 | head -n 3 || true
      local eecfg; eecfg=$(find "$cdir" -name "EE.cfg" 2>/dev/null | head -n1 || true)
      if [[ -n "$eecfg" ]]; then ls -lh "$eecfg" 2>&1 | head -n 5 || true; else echo "prefix: keep (${cdir})"; fi
    else
      echo "prefix: none"
    fi
    echo "--- shadercache ---"
    local sdir="$STEAM_ROOT/steamapps/shadercache/$appid"
    local sdir2="/mnt/External/SteamLibrary/steamapps/shadercache/$appid"
    if [[ -d "$sdir" ]]; then ls -lh "$sdir" 2>&1 | head -n 5 || true
    elif [[ -d "$sdir2" ]]; then ls -lh "$sdir2" 2>&1 | head -n 5 || true; echo "(external: $sdir2)"
    else echo "none"; fi
  else
    echo "manifest not found for $appid"
    echo "searched: $STEAM_ROOT/steamapps, /mnt/External/SteamLibrary/steamapps"
  fi
}

# ---------- fzf list helpers (like pac autoremove) ----------

list_apps_for_fzf() {
  local libs; libs=$(get_libraries)
  declare -A seen
  local lib
  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    for manifest in "$lib"/steamapps/appmanifest_*.acf; do
      [[ -f "$manifest" ]] || continue
      local appid name size installdir hsize shortlib
      appid=$(basename "$manifest" | grep -oP '\d+' || echo "?")
      [[ -n "${seen[$appid]:-}" ]] && continue
      seen[$appid]=1
      name=$(parse_manifest_field "$manifest" "name")
      installdir=$(parse_manifest_field "$manifest" "installdir")
      size=$(parse_manifest_field "$manifest" "SizeOnDisk")
      if [[ -n "$size" && "$size" =~ ^[0-9]+$ && "$size" != "0" ]]; then hsize=$(numfmt --to=iec "$size" 2>/dev/null || echo "$size"); else hsize="—"; fi
      shortlib="?"
      if [[ "$lib" == "$STEAM_ROOT" ]]; then shortlib="Home"
      elif [[ "$lib" == "/mnt/External/SteamLibrary" ]]; then shortlib="External"
      elif [[ "$lib" == "/run/media/gloves/External/SteamLibrary" ]]; then shortlib="External(run)"
      else shortlib=$(basename "$lib"); fi
      # skip staging zero? keep
      printf "%s\t%s\t%s\t%s\t%s\n" "$appid" "${name:-$installdir}" "$hsize" "$shortlib" "$installdir"
    done
  done < <(echo "$libs")
}

tui_pick_apps() {
  local mode="${1:-select}"
  local prompt header
  if [[ "$mode" == "move" ]]; then prompt="Select game to move > "; header="TAB multi, Ctrl-A all, Enter confirm — move (prefix preserved)"; else prompt="Select game to uninstall > "; header="TAB multi, Ctrl-A all — uninstall keeps prefix unless --purge"; fi
  local list; list=$(list_apps_for_fzf)
  if [[ -z "$list" ]]; then err "No games found"; return 1; fi
  # Build fixed-width display with ellipsis — each row same width, no overflow
  local display=""
  while IFS=$'\t' read -r appid name hsize shortlib installdir; do
    local d_appid d_name d_size d_lib d_install
    d_appid=$(ui_pad "$(ui_trunc "$appid" $COL_APPID)" $COL_APPID)
    d_name=$(ui_pad "$(ui_trunc "$name" $COL_NAME)" $COL_NAME)
    d_size=$(ui_pad_right "$(ui_trunc "$hsize" $COL_SIZE)" $COL_SIZE)
    d_lib=$(ui_pad "$(ui_trunc "[$shortlib]" $((COL_LIB+2)))" $((COL_LIB+2)))
    d_install=$(ui_pad "$(ui_trunc "$installdir" $COL_INSTALL)" $COL_INSTALL)
    display+="${d_appid}  ${d_name}  ${d_size}  ${d_lib}  ${d_install}"$'\n'
  done <<< "$list"
  display=${display%$'\n'}
  # Use helper via script re-invocation to avoid nested quoting (no awk {print} collision)
  local preview_cmd="bash /home/gloves/Scripts/steam-ctl.sh __preview {1}"
  local selected=""
  if command -v fzf >/dev/null 2>&1; then
    selected=$(echo "$display" | fzf --multi --prompt="$prompt" --header="$header" --bind='ctrl-a:select-all,ctrl-d:deselect-all' --preview="$preview_cmd" --preview-window=down:60%:wrap --height=80% --reverse --ansi || true)
  elif command -v gum >/dev/null 2>&1; then
    # gum filter with no-limit for multi via fzf-like
    selected=$(echo "$display" | gum filter --no-limit --prompt="$prompt" --header="$header" --height=20 || true)
  else
    echo "$display" | cat -n; read -rp "Enter APPIDs (space separated): " sel; selected="$sel"
  fi
  if [[ -z "$selected" ]]; then return 1; fi
  # extract appids (first column)
  echo "$selected" | awk '{print $1}' | tr '\n' ' ' | sed 's/ *$//'
}

tui_pick_library() {
  local exclude="${1:-}"
  local opts=() lib
  local libs; libs=$(get_libraries)
  # Build friendly list, dedup by realpath
  declare -A seen_path
  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    local rp; rp=$(realpath -m "$lib" 2>/dev/null || echo "$lib")
    [[ -n "${seen_path[$rp]:-}" ]] && continue
    seen_path[$rp]=1
    if [[ -n "$exclude" && "$(realpath -m "$exclude" 2>/dev/null)" == "$rp" ]]; then continue; fi
    local label
    if [[ "$rp" == "$(realpath -m "$STEAM_ROOT")" ]]; then label="Home          ($rp)"
    elif [[ "$rp" == "$(realpath -m "/mnt/External/SteamLibrary")" ]]; then label="External      ($rp)"
    else label="$(basename "$rp") ($rp)"; fi
    opts+=("$label")
  done < <(echo "$libs")
  # ensure Home/External present
  local rp_home; rp_home=$(realpath -m "$STEAM_ROOT")
  if [[ -z "${seen_path[$rp_home]:-}" && -d "$STEAM_ROOT/steamapps" ]]; then
    opts=("Home          ($rp_home)" "${opts[@]}"); seen_path[$rp_home]=1
  fi
  local ext; ext=$(resolve_external 2>/dev/null || echo "/mnt/External/SteamLibrary")
  local rp_ext; rp_ext=$(realpath -m "$ext" 2>/dev/null || echo "$ext")
  if [[ -z "${seen_path[$rp_ext]:-}" && -d "$ext/steamapps" ]]; then opts+=("External      ($rp_ext)"); fi

  local choice=""
  if command -v gum >/dev/null 2>&1; then
    choice=$(printf '%s\n' "${opts[@]}" | gum choose --header="Select target library" --height=10 || true)
  elif command -v fzf >/dev/null 2>&1; then
    choice=$(printf '%s\n' "${opts[@]}" | fzf --prompt="Target > " --header="Select target library" --height=10 || true)
  else
    printf '%s\n' "${opts[@]}" | cat -n; read -rp "Enter number: " num; choice=$(printf '%s\n' "${opts[@]}" | sed -n "${num}p")
  fi
  [[ -z "$choice" ]] && return 1
  local path; path=$(echo "$choice" | grep -oP '\(\K[^)]+' 2>/dev/null || echo "$choice")
  echo "$path"
}

tui_main() {
  while true; do
    local choice=""
    if command -v gum >/dev/null 2>&1; then
      choice=$(gum choose --header="steam-ctl — keep prefix (Home/External) — choose action" "Move game" "Uninstall game" "List games" "Fix libraries" "Quit" --height=10 || true)
    elif command -v fzf >/dev/null 2>&1; then
      choice=$(printf '%s\n' "Move game" "Uninstall game" "List games" "Fix libraries" "Quit" | fzf --prompt="steam-ctl > " --header="Choose action" --height=10 || true)
    else
      echo "1) Move game  2) Uninstall game  3) List games  4) Fix libraries  5) Quit"
      read -rp "Choice: " c
      case "$c" in 1) choice="Move game";; 2) choice="Uninstall game";; 3) choice="List games";; 4) choice="Fix libraries";; *) choice="Quit";; esac
    fi
    case "$choice" in
      "Move game")
        local picks; picks=$(tui_pick_apps move) || { warn "Nothing selected"; continue; }
        [[ -z "$picks" ]] && continue
        # Determine common target: pick once for batch, but exclude source of first if single
        local first_appid; first_appid=$(echo "$picks" | awk '{print $1}')
        local src; src=$(find_source_lib "$first_appid" 2>/dev/null || echo "")
        local target; target=$(tui_pick_library "$src") || { warn "No target selected"; continue; }
        [[ -z "$target" ]] && continue
        # Allow alias typed? tui already returns path, but resolve alias just in case
        target=$(resolve_library_alias "$target" 2>/dev/null || echo "$target")
        local count; count=$(echo "$picks" | wc -w)
        if is_interactive; then
          if ! gum confirm "Move $count game(s) [$picks] → $(basename "$target") ?"; then log "Aborted."; continue; fi
        fi
        for appid in $picks; do
          cmd_move "$appid" "$target" || warn "Failed move $appid"
        done
        ;;
      "Uninstall game")
        local picks; picks=$(tui_pick_apps uninstall) || { warn "Nothing selected"; continue; }
        [[ -z "$picks" ]] && continue
        local count; count=$(echo "$picks" | wc -w)
        local purge_msg=""; [[ "$PURGE_COMPDATA" == true ]] && purge_msg=" (PURGE prefix!)"
        if is_interactive; then
          if ! gum confirm "Uninstall $count game(s) [$picks]? Prefix kept$purge_msg"; then log "Aborted."; continue; fi
        fi
        for appid in $picks; do
          cmd_uninstall "$appid" || warn "Failed uninstall $appid"
        done
        ;;
      "List games")
        if command -v gum >/dev/null 2>&1; then cmd_list | gum pager || cmd_list; else cmd_list; fi
        read -rp "Press Enter to continue..." _
        ;;
      "Fix libraries") cmd_fix_libraries; read -rp "Press Enter..." _ ;;
      "Quit"|"") break ;;
      *) break ;;
    esac
  done
}

# ---------- commands ----------

cmd_list() {
  log "Scanning libraries..."
  local libs; libs=$(get_libraries)
  echo ""
  # Header — pad to fixed widths, same as rows (ellipsis not needed in header)
  local h_appid h_size h_prefix h_shader h_lib h_name
  h_appid=$(ui_pad "APPID" $COL_APPID)
  h_size=$(printf "%${COL_SIZE}s" "SIZE")
  h_prefix=$(ui_pad "PREFIX" $COL_PREFIX)
  h_shader=$(ui_pad "SHADER" $COL_SHADER)
  h_lib=$(ui_pad "LIBRARY" $COL_LIB)
  h_name=$(ui_pad "NAME" $COL_NAME)
  printf "${BOLD}%s %s %s %s %s %s${NC}\n" "$h_appid" "$h_size" "$h_prefix" "$h_shader" "$h_lib" "$h_name"
  # Separator — consistent row width
  printf "%s %s %s %s %s %s\n" "$(draw_sep $COL_APPID)" "$(draw_sep $COL_SIZE)" "$(draw_sep $COL_PREFIX)" "$(draw_sep $COL_SHADER)" "$(draw_sep $COL_LIB)" "$(draw_sep $COL_NAME)"
  local lib
  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    for manifest in "$lib"/steamapps/appmanifest_*.acf; do
      [[ -f "$manifest" ]] || continue
      local appid name size installdir
      appid=$(basename "$manifest" | grep -oP '\d+')
      name=$(parse_manifest_field "$manifest" "name")
      installdir=$(parse_manifest_field "$manifest" "installdir")
      size=$(parse_manifest_field "$manifest" "SizeOnDisk")
      local hsize="?"; if [[ -n "$size" && "$size" =~ ^[0-9]+$ ]]; then hsize=$(numfmt --to=iec "$size" 2>/dev/null || echo "$size"); else hsize="—"; fi
      # Fixed-width, truncated fields — prevents overflow
      local disp_appid disp_size disp_lib disp_name
      disp_appid=$(ui_pad "$(ui_trunc "$appid" $COL_APPID)" $COL_APPID)
      disp_size=$(printf "%${COL_SIZE}s" "$(ui_trunc "$hsize" $COL_SIZE)")
      local prefix_plain shader_plain shortlib
      local cpath; cpath=$(compatdata_realpath "$appid")
      if [[ -d "$cpath" ]]; then prefix_plain="keep ✓"; else prefix_plain="none"; fi
      local sp; sp="$lib/steamapps/shadercache/$appid"
      if [[ -d "$sp" ]] || [[ -d "$STEAM_ROOT/steamapps/shadercache/$appid" ]]; then shader_plain="keep"; else shader_plain="none"; fi
      shortlib=$(basename "$lib")
      if [[ "$lib" == "$STEAM_ROOT" ]]; then shortlib="Home"; elif [[ "$lib" == "/mnt/External/SteamLibrary" ]]; then shortlib="External"; elif [[ "$lib" == "/run/media/gloves/External/SteamLibrary" ]]; then shortlib="External(run)"; fi
      # Color AFTER padding so ANSI doesn't break column width
      local prefix_disp shader_disp
      prefix_disp=$(ui_pad "$prefix_plain" $COL_PREFIX)
      shader_disp=$(ui_pad "$shader_plain" $COL_SHADER)
      if [[ "$prefix_plain" == "keep ✓" ]]; then prefix_disp="${GREEN}${prefix_disp}${NC}"; else prefix_disp="${RED}${prefix_disp}${NC}"; fi
      if [[ "$shader_plain" == "keep" ]]; then shader_disp="${GREEN}${shader_disp}${NC}"; else shader_disp="${DIM}${shader_disp}${NC}"; fi
      disp_lib=$(ui_pad "$(ui_trunc "$shortlib" $COL_LIB)" $COL_LIB)
      disp_name=$(ui_pad "$(ui_trunc "${name:-$installdir}" $COL_NAME)" $COL_NAME)
      printf "%s %s %s %s %s %s\n" "$disp_appid" "$disp_size" "$prefix_disp" "$shader_disp" "$disp_lib" "$disp_name"
    done
  done < <(echo "$libs")
  echo ""
  log "Compatdata realpath: $(readlink -f "$STEAM_ROOT/steamapps/compatdata" 2>/dev/null || echo "$STEAM_ROOT/steamapps/compatdata")"
  log "Symlink check: /mnt/External/.../compatdata -> $(readlink /mnt/External/SteamLibrary/steamapps/compatdata 2>/dev/null || echo "no symlink")"
  echo ""
  warn "Use '$(basename "$0") fix-libraries --dry-run' to review stale /run/media prune."
}

cmd_fix_libraries() {
  log "Checking $LIBRARY_VDF for duplicates..."
  if [[ ! -f "$LIBRARY_VDF" ]]; then err "No $LIBRARY_VDF found"; return 1; fi
  cat "$LIBRARY_VDF"; echo ""
  local dup_ids; dup_ids=$(grep -oP '"contentid"\s+"\K[^"]+' "$LIBRARY_VDF" | sort | uniq -d || true)
  if [[ -z "$dup_ids" ]]; then success "No duplicate contentid found."; else warn "Duplicate contentid(s): $dup_ids"; warn "This matches your /run/media vs /mntExternal dup (contentid 5417633093559943861)."; fi
  if grep -q "/run/media/gloves/External/SteamLibrary" "$LIBRARY_VDF"; then
    warn "Found stale entry: /run/media/gloves/External/SteamLibrary"
    if [[ -d "/run/media/gloves/External/SteamLibrary" ]]; then warn "But directory exists. Skipping auto-prune."; else
      echo ""
      if [[ "$DRY_RUN" == true ]]; then dry "Would remove stale block \"1\" {/run/media/...} and reindex 2 -> 1"; dry "Backup to: $LIBRARY_VDF.bak.\$(date +%s)"; else
        if confirm "Remove stale /run/media block and reindex?"; then
          local bak="$LIBRARY_VDF.bak.$(date +%s)"; cp "$LIBRARY_VDF" "$bak"; log "Backup created: $bak"
          python3 << 'PYEOF'
import re, pathlib
vdf_path = pathlib.Path("/home/gloves/.local/share/Steam/steamapps/libraryfolders.vdf")
text = vdf_path.read_text()
pattern = re.compile(r'(\n\t)"(\d+)"\n\t\{\n(.*?)\n\t\}', re.DOTALL)
matches = list(pattern.finditer(text))
kept=[]
for m in matches:
    prefix, num, body = m.group(1), m.group(2), m.group(3)
    if "/run/media/gloves/External/SteamLibrary" in body: print(f"Removing block {num}"); continue
    kept.append((num, body))
new_blocks=""
for i, (old_num, body) in enumerate(kept): new_blocks += f'\n\t"{i}"\n\t{{\n{body}\n\t}}'
if matches:
    start, end = matches[0].start(), matches[-1].end()
    vdf_path.write_text(text[:start] + new_blocks + text[end:])
    print("Reindexed libraries")
else: print("No blocks found")
PYEOF
          success "Pruned stale entry. New $LIBRARY_VDF:"; cat "$LIBRARY_VDF"; success "Restore with: cp $bak $LIBRARY_VDF"
        else log "Aborted."; fi
      fi
    fi
  else success "No stale /run/media entry — already clean."; fi
}

cmd_move() {
  local appid="$1" target_input="$2"
  if [[ ! "$appid" =~ ^[0-9]+$ ]]; then err "Invalid appid: $appid"; return 1; fi
  local target; target=$(resolve_library_alias "$target_input" 2>/dev/null || echo "$target_input")
  target=$(realpath -m "$target" 2>/dev/null || echo "$target")
  if [[ ! -d "$target/steamapps" ]]; then err "Target not a Steam library: $target_input → $target (expected $target/steamapps)"; echo "  Create via Steam > Settings > Storage > Add Library or use Home/External"; return 1; fi
  local source; if ! source=$(find_source_lib "$appid"); then err "App $appid not found. Try '$(basename "$0") list'"; return 1; fi
  source=$(realpath -m "$source" 2>/dev/null || echo "$source")
  target=$(realpath -m "$target" 2>/dev/null || echo "$target")
  if [[ "$source" == "$target" ]]; then err "Source and target are same: $source"; return 1; fi
  local manifest="$source/steamapps/appmanifest_${appid}.acf"
  local installdir name size; installdir=$(parse_manifest_field "$manifest" "installdir"); name=$(parse_manifest_field "$manifest" "name"); size=$(parse_manifest_field "$manifest" "SizeOnDisk")
  local hsize; hsize=$(numfmt --to=iec "$size" 2>/dev/null || echo "$size bytes")
  log "Move ${BOLD}$name ($appid)${NC} — $installdir ($hsize)"
  echo "  Source: $source/steamapps/common/$installdir"; echo "  Target: $target/steamapps/common/$installdir"; echo "  Manifest: appmanifest_${appid}.acf"
  local cpath; cpath=$(compatdata_realpath "$appid")
  if [[ -d "$cpath" ]]; then echo -e "  Prefix: ${GREEN}PRESERVE${NC} $cpath (never deleted)"; if [[ "$appid" == "230410" ]]; then local eecfg="$cpath/pfx/drive_c/users/steamuser/AppData/Local/Warframe/EE.cfg"; if [[ -f "$eecfg" ]]; then echo "    Warframe EE.cfg: $eecfg ($(stat -c %y "$eecfg" 2>/dev/null | cut -d. -f1))"; fi; fi; else echo -e "  Prefix: ${YELLOW}none${NC}"; fi
  local src_common="$source/steamapps/common/$installdir"
  local dst_common="$target/steamapps/common/$installdir"
  local src_manifest="$source/steamapps/appmanifest_${appid}.acf"
  local dst_manifest="$target/steamapps/appmanifest_${appid}.acf"
  if [[ "$DRY_RUN" == true ]]; then
    if is_steam_running; then warn "Steam is running — live run would require --stop-steam, but dry-run continues."; fi
    dry "Would rsync -aH --info=progress2 \"$src_common/\" -> \"$dst_common/\""; dry "Would mv \"$src_manifest\" -> \"$dst_manifest\""; dry "Would PRESERVE compatdata: $cpath"
    return 0
  fi
  stop_steam_if_needed || return 1
  if [[ ! -d "$src_common" ]]; then warn "Source common missing: $src_common"; fi
  if [[ -e "$dst_common" ]]; then err "Target already has $dst_common — abort"; return 1; fi
  if [[ -e "$dst_manifest" ]]; then err "Target already has manifest $dst_manifest"; return 1; fi
  if ! confirm "Proceed with move?"; then log "Aborted."; return 0; fi
  mkdir -p "$target/steamapps/common"
  if [[ -d "$src_common" ]]; then
    log "Copying $installdir -> $target (rsync)..."
    if command -v rsync >/dev/null 2>&1; then
      rsync -aH --info=progress2 "$src_common/" "$dst_common/" || { err "rsync failed"; return 1; }
      local s1 s2; s1=$(du -sb "$src_common" 2>/dev/null | cut -f1 || echo 0); s2=$(du -sb "$dst_common" 2>/dev/null | cut -f1 || echo 0)
      if [[ "$s1" != "$s2" ]]; then warn "Size mismatch: source $s1 != dest $s2"; else success "Copy verified ($hsize)"; fi
      log "Removing source: $src_common"; rm -rf "$src_common"
    else log "rsync not found, using mv..."; mv "$src_common" "$dst_common" || { err "mv failed"; return 1; }; fi
  fi
  log "Moving manifest..."; mv "$src_manifest" "$dst_manifest" || { err "Failed to move manifest"; return 1; }
  success "Move complete. Compatdata preserved: $cpath"
  if [[ -d "$STEAM_ROOT/steamapps/shadercache/$appid" ]]; then success "Shadercache preserved: $STEAM_ROOT/steamapps/shadercache/$appid"; fi
  log "Reopen Steam — game will appear in new library."
}

cmd_uninstall() {
  local appid="$1"
  if [[ ! "$appid" =~ ^[0-9]+$ ]]; then err "Invalid appid: $appid"; return 1; fi
  local source; if ! source=$(find_source_lib "$appid"); then err "App $appid not found. Try list."; return 1; fi
  local manifest="$source/steamapps/appmanifest_${appid}.acf"
  local installdir name size; installdir=$(parse_manifest_field "$manifest" "installdir"); name=$(parse_manifest_field "$manifest" "name"); size=$(parse_manifest_field "$manifest" "SizeOnDisk")
  local hsize; hsize=$(numfmt --to=iec "$size" 2>/dev/null || echo "$size")
  log "Uninstall ${BOLD}$name ($appid)${NC} — $installdir ($hsize)"
  echo "  Library: $source"; echo "  To delete: $source/steamapps/common/$installdir"; echo "  To delete: $manifest"
  local cpath shader; cpath=$(compatdata_realpath "$appid"); shader="$STEAM_ROOT/steamapps/shadercache/$appid"; local shader2="$source/steamapps/shadercache/$appid"
  if [[ -d "$cpath" ]]; then if [[ "$PURGE_COMPDATA" == true ]]; then echo -e "  Prefix: ${RED}DELETE${NC} $cpath (--purge-compatdata)"; else echo -e "  Prefix: ${GREEN}PRESERVE ✓${NC} $cpath (use --purge-compatdata to wipe)"; if [[ "$appid" == "230410" ]]; then local eecfg="$cpath/pfx/drive_c/users/steamuser/AppData/Local/Warframe/EE.cfg"; if [[ -f "$eecfg" ]]; then echo "    Warframe EE.cfg will be KEPT: $eecfg"; fi; fi; fi; else echo "  Prefix: none"; fi
  if [[ -d "$shader" || -d "$shader2" ]]; then if [[ "$PURGE_SHADERCACHE" == true ]]; then echo -e "  Shadercache: ${RED}DELETE${NC} $shader"; else echo -e "  Shadercache: ${GREEN}PRESERVE${NC} (use --purge-shadercache to wipe)"; fi; else echo "  Shadercache: none"; fi
  if [[ "$DRY_RUN" == true ]]; then
    if is_steam_running; then warn "Steam is running — live run would require --stop-steam, but dry-run continues."; fi
    dry "Would rm -rf \"$source/steamapps/common/$installdir\""; dry "Would rm \"$manifest\""; if [[ "$PURGE_COMPDATA" == true ]]; then dry "Would rm -rf \"$cpath\""; else dry "Would PRESERVE \"$cpath\""; fi
    if [[ -d "$shader" || -d "$shader2" ]]; then if [[ "$PURGE_SHADERCACHE" == true ]]; then dry "Would rm -rf $shader*"; else dry "Would PRESERVE shadercache"; fi; fi
    return 0
  fi
  stop_steam_if_needed || return 1
  if ! confirm "Proceed with uninstall (game files deleted, prefix kept)?"; then log "Aborted."; return 0; fi
  if [[ -d "$source/steamapps/common/$installdir" ]]; then log "Deleting $source/steamapps/common/$installdir ..."; rm -rf "$source/steamapps/common/$installdir"; success "Deleted common/$installdir"; else warn "Common not found: $source/steamapps/common/$installdir"; fi
  if [[ -f "$manifest" ]]; then rm -f "$manifest"; success "Deleted appmanifest_${appid}.acf"; fi
  if [[ "$PURGE_COMPDATA" == true && -d "$cpath" ]]; then log "Purging compatdata $cpath ..."; rm -rf "$cpath"; success "Purged compatdata"; else if [[ -d "$cpath" ]]; then success "Preserved compatdata: $cpath — reinstall will reuse settings"; fi; fi
  if [[ "$PURGE_SHADERCACHE" == true ]]; then if [[ -d "$shader" ]]; then rm -rf "$shader" && success "Purged $shader"; fi; if [[ -d "$shader2" && "$shader2" != "$shader" ]]; then rm -rf "$shader2" && success "Purged $shader2"; fi; else if [[ -d "$shader" || -d "$shader2" ]]; then success "Preserved shadercache"; fi; fi
  success "Uninstall complete. Reinstall via Steam UI later to reuse preserved prefix."
}

# ---------- arg parsing ----------
if [[ $# -eq 0 ]]; then
  if is_interactive; then tui_main; exit 0; else usage; exit 1; fi
fi

CMD=""; POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    move|uninstall|list|fix-libraries|__preview) CMD="$1"; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --stop-steam) STOP_STEAM=true; shift ;;
    --keep-compatdata) KEEP_COMPDATA=true; PURGE_COMPDATA=false; shift ;;
    --keep-shadercache) KEEP_SHADERCACHE=true; PURGE_SHADERCACHE=false; shift ;;
    --purge-compatdata) PURGE_COMPDATA=true; KEEP_COMPDATA=false; shift ;;
    --purge-shadercache) PURGE_SHADERCACHE=true; KEEP_SHADERCACHE=false; shift ;;
    --no-tui) NO_TUI=true; shift ;;
    -f|--force) FORCE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) err "Unknown option: $1"; usage; exit 1 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [[ -z "$CMD" && ${#POSITIONAL[@]} -gt 0 ]]; then
  case "${POSITIONAL[0]}" in move|uninstall|list|fix-libraries|__preview) CMD="${POSITIONAL[0]}"; POSITIONAL=("${POSITIONAL[@]:1}");; esac
  set -- "${POSITIONAL[@]}"
fi

# Handle subcmd defaults with TUI when missing id
case "$CMD" in
  __preview) __preview_app "${1:-}" ;;
  list) cmd_list ;;
  fix-libraries) cmd_fix_libraries ;;
  move)
    if [[ $# -eq 0 ]]; then
      if is_interactive; then
        picks=$(tui_pick_apps move) || { log "No selection"; exit 0; }
        [[ -z "$picks" ]] && exit 0
        first=$(echo "$picks" | awk '{print $1}'); src=$(find_source_lib "$first" 2>/dev/null || echo "")
        target=$(tui_pick_library "$src") || { log "No target"; exit 0; }
        target=$(resolve_library_alias "$target" 2>/dev/null || echo "$target")
        count=$(echo "$picks" | wc -w)
        if ! confirm "Move $count game(s) [$picks] → $(basename "$target") ?"; then log "Aborted."; exit 0; fi
        for a in $picks; do cmd_move "$a" "$target" || warn "Failed $a"; done
      else err "move requires <appid> <target_library>"; echo "  Example: $(basename "$0") move 230410 Home"; exit 1; fi
    elif [[ $# -eq 1 ]]; then
      if is_interactive; then
        appid="$1"; src=$(find_source_lib "$appid" 2>/dev/null || echo "")
        target=$(tui_pick_library "$src") || { log "No target"; exit 0; }
        target=$(resolve_library_alias "$target" 2>/dev/null || echo "$target")
        cmd_move "$appid" "$target"
      else err "move requires <target_library>"; echo "  Example: $(basename "$0") move $1 Home"; exit 1; fi
    else
      cmd_move "$1" "$2"
    fi
    ;;
  uninstall)
    if [[ $# -eq 0 ]]; then
      if is_interactive; then
        picks=$(tui_pick_apps uninstall) || { log "No selection"; exit 0; }
        [[ -z "$picks" ]] && exit 0
        count=$(echo "$picks" | wc -w)
        if ! confirm "Uninstall $count game(s) [$picks]? Prefix kept unless --purge"; then log "Aborted."; exit 0; fi
        for a in $picks; do cmd_uninstall "$a" || warn "Failed $a"; done
      else err "uninstall requires <appid>"; exit 1; fi
    else
      # support multi uninstall: uninstall 230410 392160 ...
      for a in "$@"; do cmd_uninstall "$a" || warn "Failed $a"; done
    fi
    ;;
  "") err "No command given."; usage; exit 1 ;;
  *) err "Unknown command: $CMD"; usage; exit 1 ;;
esac
