# Niri IPC Scripts — Hyprland Emulation Layer

These scripts use `niri msg --json` + `niri msg action` to emulate Hyprland binds that have no direct Niri keybind equivalent. Ported from `~/.config/hypr/utils.lua` and `~/.config/hypr/scripts/_archive/` (Lua → shell + niri IPC).

## Usage in `config.kdl`

```kdl
binds {
    MOD+ALT+SPACE { spawn-sh "~/.config/niri/scripts/float-all.sh"; }
}
```
All scripts are idempotent and handle `NIRI_SOCKET` missing (outside niri / nested) via `notify-send` fallback.

## Hypr → Niri mapping

| Hypr (utils.lua / keybinds.lua) | Niri script | Niri IPC used |
|---|---|---|
| `Utils.float_all_windows()` | `float-all.sh` | `windows` + `focus-window` + `toggle-window-floating` |
| `Utils.kill_active_process()` | `kill-active.sh` | `focused-window` (pid) + `kill` |
| `Utils.focus_wrap(l/r/u/d)` | `focus-wrap.sh` | `focused-window` + `windows` geometry + `focus-column-*` / `focus-workspace-*` |
| `Utils.move_wrap(l/r/u/d)` | `move-wrap.sh` | `move-column-*` / `move-to-workspace` |
| `Utils.layout_keybind_dispatch(...)` | `layout-dispatch.sh` | `focus-*` + `swap-*` (always scrolling) |
| `Utils.hyprsunset toggle` | `hyprsunset.sh` | `wlsunset` / `gammastep` via `NIRI_SOCKET` check |
| `Utils.launch_terminal` | `launch-terminal.sh` | `spawn` fallback chain kitty → ghostty → alacritty |
| `Utils.launch_file_manager` | `launch-file-manager.sh` | `thunar → dolphin → nautilus → yazi` |
| `SUPER+CTRL+O` toggle opaque | `toggle-opaque.sh` | `toggle-window-rule-opacity` |
| `SUPER+ALT+O` toggle blur | `toggle-blur.sh` | edit `config.kdl` `blur { off }` + `niri msg action load-config-file` |
| `Animations` `QuickSettings` `Refresh` | `animations.sh` `quick-settings.sh` `refresh.sh` | `noctalia msg` + picker |
| `Screenshare Block` | `screenshare-toggle.sh` | `block-out-from screencast` via window id (future) + notify |

## Requirements
- `niri >= 26.04`, `jq` or `python3` (fallback), `notify-send`, `hyprpicker`/`wl-copy` optional.
- Scripts expect `$NIRI_SOCKET` set (running inside niri). Outside niri they exit with notify.

## Testing
```sh
~/.config/niri/scripts/float-all.sh
niri validate && niri msg action load-config-file
```
