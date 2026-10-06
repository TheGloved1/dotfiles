#!/usr/bin/env python3
"""noctalia-panels-placement.py — set ALL Noctalia panel placements in settings.toml.

Auto-switches every panel between attached/auto (idle, bar-anchored) and
floating/center (fullscreen visible, overlay above fullscreen).

Kept filename noctalia-launcher-placement.py for backward compat with the
bash watcher, but it now handles all core + plugin panels.

Exit codes for bash compatibility:
  0 = changed and written
  1 = no change needed
  2 = error

Usage:
  noctalia-launcher-placement.py --settings ~/.local/state/noctalia/settings.toml --desired attached [--position auto] [--all] [--verbose] [--dry-run]
  noctalia-launcher-placement.py --settings ~/.local/state/noctalia/settings.toml --desired floating [--position center] [--all]

Scope (per user answers: all core + all plugins, force attached/auto, all *placement keys, include polkit):
  Core [shell.panel]: launcher, clipboard, control_center, wallpaper, session, polkit
    -> <name>_placement + <name>_position (created if missing)
  Plugins [plugin_settings.*]: any key ending in placement (case-insensitive,
    either _ or - separator) with value attached|floating
    -> set to desired; sibling <prefix>_position only if it already exists
       in settings or config (never invent new plugin position keys).
    Excluded automatically: placement_height/width (don't end in placement),
    overview-widget_position (no overview-widget_placement sibling).

Visible-away logic (scroll offscreen) lives in the bash watcher via is_focused,
not here — this file only does the atomic TOML edit.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import tomllib  # py 3.11+
except ImportError:
    import tomli as tomllib  # type: ignore

try:
    import tomli_w  # type: ignore
except ImportError:
    tomli_w = None  # type: ignore

CORE_NAMES = [
    "launcher",
    "clipboard",
    "control_center",
    "wallpaper",
    "session",
    "polkit",
]

POSITION_CHOICES = [
    "auto",
    "center",
    "top_left",
    "top_center",
    "top_right",
    "bottom_left",
    "bottom_center",
    "bottom_right",
    "center_left",
    "center_right",
]


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Set Noctalia panel placements in settings.toml (single or all)"
    )
    p.add_argument(
        "--settings",
        required=True,
        help="Path to settings.toml (e.g. ~/.local/state/noctalia/settings.toml)",
    )
    p.add_argument(
        "--config",
        default="~/.config/noctalia/config.toml",
        help="Hand-layer config for union discovery of plugin keys (default ~/.config/noctalia/config.toml)",
    )
    p.add_argument(
        "--desired",
        required=True,
        choices=["attached", "floating"],
        help="placement value to set",
    )
    p.add_argument(
        "--position",
        required=False,
        default=None,
        choices=POSITION_CHOICES,
        help="position value; default auto when attached, center when floating",
    )
    p.add_argument(
        "--all",
        action="store_true",
        help="Switch ALL core + plugin panels (default when called from watcher)",
    )
    p.add_argument(
        "--single",
        action="store_true",
        help="Legacy launcher-only mode (overrides --all)",
    )
    p.add_argument("--verbose", action="store_true", help="Print what changed")
    p.add_argument(
        "--dry-run", action="store_true", help="Report changes without writing"
    )
    p.add_argument("positional", nargs="*", help=argparse.SUPPRESS)
    return p.parse_args()


def load_toml(path: Path) -> dict:
    try:
        with open(path, "rb") as f:
            data = tomllib.load(f)
        return data if isinstance(data, dict) else {}
    except FileNotFoundError:
        return {}
    except Exception as e:
        print(f"read error {path}: {e}", file=sys.stderr)
        raise


def sibling_position_key(placement_key: str) -> str | None:
    low = placement_key.lower()
    idx = low.rfind("placement")
    if idx == -1:
        return None
    # only treat as placement key if suffix is exactly placement with _ or - separator
    prefix = placement_key[:idx]
    if prefix == "" or prefix[-1] not in ("_", "-"):
        return None
    return prefix + "position"


def is_placement_key(key: str, value: object) -> bool:
    if not key.lower().endswith("placement"):
        return False
    # require _ or - separator before placement (excludes bare "placement")
    prefix = key[: -len("placement")]
    if prefix == "" or prefix[-1] not in ("_", "-"):
        return False
    return isinstance(value, str) and value in ("attached", "floating")


def collect_plugin_placements(*datas: dict) -> dict[str, set[str]]:
    """Return {plugin_section: set(placement_keys)} union across datas."""
    out: dict[str, set[str]] = {}
    for data in datas:
        plugins = data.get("plugin_settings")
        if not isinstance(plugins, dict):
            continue
        for section, table in plugins.items():
            if not isinstance(table, dict):
                continue
            for k, v in table.items():
                if is_placement_key(k, v):
                    out.setdefault(section, set()).add(k)
    return out


def main() -> int:
    args = parse_args()

    settings_path = Path(args.settings).expanduser()
    config_path = Path(args.config).expanduser()
    desired: str = args.desired
    position: str = args.position or ("center" if desired == "floating" else "auto")

    use_all = bool(args.all) or not bool(args.single)
    # Backward compat: old watcher called without --all/--single expecting launcher-only.
    # Detect legacy caller: if neither flag given AND position explicitly passed for launcher,
    # keep old behavior? No — per user decision (all panels), default to --all unless --single.
    # The watcher will be updated to pass --all explicitly.

    if tomli_w is None:
        print("tomli_w missing (pip install tomli-w)", file=sys.stderr)
        return 2

    try:
        settings_data: dict = load_toml(settings_path)
    except Exception:
        return 2
    if not settings_data:
        # missing file -> start from skeleton; config_version matches existing files
        settings_data = {"config_version": 13}
    try:
        config_data: dict = load_toml(config_path)
    except Exception:
        config_data = {}

    if "shell" not in settings_data or not isinstance(settings_data["shell"], dict):
        settings_data["shell"] = {}
    shell = settings_data["shell"]
    if "panel" not in shell or not isinstance(shell["panel"], dict):
        shell["panel"] = {}
    panel = shell["panel"]

    changes: list[str] = []

    if use_all:
        # --- core panels: always ensure all 6 exist ---
        for name in CORE_NAMES:
            pk = f"{name}_placement"
            sk = f"{name}_position"
            old_p = panel.get(pk)
            if old_p != desired:
                # only count/write if old differs; create if missing (None != desired always true
                # except floating vs None? None != desired in both cases, so always writes missing)
                panel[pk] = desired
                changes.append(f"shell.panel.{pk}: {old_p!r} -> {desired!r}")
            old_s = panel.get(sk)
            if old_s != position:
                panel[sk] = position
                changes.append(f"shell.panel.{sk}: {old_s!r} -> {position!r}")

        # --- plugin panels: union of settings + config ---
        union = collect_plugin_placements(settings_data, config_data)
        settings_plugins = settings_data.get("plugin_settings")
        if not isinstance(settings_plugins, dict):
            settings_plugins = {}
            settings_data["plugin_settings"] = settings_plugins
        for section in sorted(union):
            table = settings_plugins.get(section)
            if not isinstance(table, dict):
                table = {}
                settings_plugins[section] = table
            for pkey in sorted(union[section]):
                old_v = table.get(pkey)
                if old_v != desired:
                    table[pkey] = desired
                    changes.append(f"plugin_settings.{section}.{pkey}: {old_v!r} -> {desired!r}")
                # sibling position only if already present in settings or config
                skey = sibling_position_key(pkey)
                if skey is None:
                    continue
                cfg_table = config_data.get("plugin_settings", {}).get(section, {})
                if not isinstance(cfg_table, dict):
                    cfg_table = {}
                if skey in table or skey in cfg_table:
                    old_s = table.get(skey)
                    if old_s != position:
                        table[skey] = position
                        changes.append(
                            f"plugin_settings.{section}.{skey}: {old_s!r} -> {position!r}"
                        )
    else:
        # legacy launcher-only
        old_placement = panel.get("launcher_placement")
        old_position = panel.get("launcher_position")
        needs = (
            old_placement != desired
            or old_position != position
            or old_placement is None
        )
        if not needs:
            if args.verbose:
                print(
                    f"no change: launcher_placement={old_placement!r} launcher_position={old_position!r}",
                    file=sys.stderr,
                )
            return 1
        panel["launcher_placement"] = desired
        panel["launcher_position"] = position
        changes.append(f"shell.panel.launcher_placement: {old_placement!r} -> {desired!r}")
        changes.append(f"shell.panel.launcher_position: {old_position!r} -> {position!r}")

    if not changes:
        if args.verbose:
            print(f"no change: all panels already {desired}/{position}", file=sys.stderr)
        return 1

    if args.verbose or args.dry_run:
        for c in changes:
            print(c, file=sys.stderr)
        print(f"total {len(changes)} change(s)", file=sys.stderr)

    if args.dry_run:
        return 0

    tmp = settings_path.with_suffix(".tmp")
    try:
        with open(tmp, "wb") as f:
            tomli_w.dump(settings_data, f)
        tmp.replace(settings_path)
    except Exception as e:
        print(f"write error: {e}", file=sys.stderr)
        try:
            tmp.unlink(missing_ok=True)
        except Exception:
            pass
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
