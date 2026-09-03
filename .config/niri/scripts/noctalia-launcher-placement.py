#!/usr/bin/env python3
"""noctalia-launcher-placement.py — set launcher_placement / launcher_position in settings.toml

Extracted from noctalia-launcher-auto-placement.sh:43-127 for reuse and testability.
Keeps exit codes for bash compatibility:
  0 = changed and written
  1 = no change needed
  2 = error

Usage:
  noctalia-launcher-placement.py --settings ~/.local/state/noctalia/settings.toml --desired attached --position auto
  noctalia-launcher-placement.py --settings ~/.local/state/noctalia/settings.toml --desired floating --position center

Visible-away logic (scroll offscreen) is handled in the bash watcher via is_focused,
not here — this file only does atomic TOML edit.

Future niri PRs: is_fullscreen (PR #2836) and Workspace.scrolling_view_pos (PR #4147)
will replace tile_size heuristic in the shell; this file stays unchanged.
"""

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


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Set Noctalia launcher placement in settings.toml"
    )
    p.add_argument(
        "--settings",
        required=True,
        help="Path to settings.toml (e.g. ~/.local/state/noctalia/settings.toml)",
    )
    p.add_argument(
        "--desired",
        required=True,
        choices=["attached", "floating"],
        help="launcher_placement value",
    )
    p.add_argument(
        "--position",
        required=True,
        choices=[
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
        ],
        help="launcher_position value (auto when attached, center when floating)",
    )
    p.add_argument("--verbose", action="store_true", help="Print what changed")
    # Back-compat positional args used by old bash heredoc: settings desired position
    p.add_argument("positional", nargs="*", help=argparse.SUPPRESS)
    return p.parse_args()


def main() -> int:
    args = parse_args()

    # Support old positional invocation: python3 - settings desired position
    # If --settings not matching file and positionals present, fallback
    settings_path = Path(args.settings).expanduser()
    desired = args.desired
    position = args.position

    # If called with positional args only (e.g., from old bash: python3 - "$SETTINGS" "$desired" "$position")
    # argparse already handled named, but handle case where user passed positional without flags
    if args.positional:
        # positional[0]=settings, [1]=desired, [2]=position
        if len(args.positional) >= 3:
            # override if flags were defaults? Keep flag values if explicitly set
            pass
        elif len(args.positional) == 3 and args.settings == args.positional[0]:
            pass

    if tomli_w is None:
        print("tomli_w missing (pip install tomli-w)", file=sys.stderr)
        return 2

    # Read existing
    try:
        data: dict = tomllib.load(open(settings_path, "rb"))  # type: ignore[no-redef]
    except FileNotFoundError:
        data = {"config_version": 13}  # type: ignore[assignment]
    except Exception as e:
        print(f"read error: {e}", file=sys.stderr)
        return 2

    if "shell" not in data or not isinstance(data["shell"], dict):  # type: ignore[operator]
        data["shell"] = {}  # type: ignore[assignment]
    if "panel" not in data["shell"] or not isinstance(data["shell"]["panel"], dict):  # type: ignore[operator, index]
        data["shell"]["panel"] = {}  # type: ignore[assignment, index]

    panel = data["shell"]["panel"]  # type: ignore[index, assignment]
    old_placement = panel.get("launcher_placement")  # type: ignore[attr-defined]
    old_position = panel.get("launcher_position")  # type: ignore[attr-defined]

    needs = False
    if old_placement != desired:
        needs = True
    if old_position != position:
        needs = True
    if old_placement is None:
        needs = True

    if not needs:
        if args.verbose:
            print(
                f"no change: launcher_placement={old_placement!r} launcher_position={old_position!r}",
                file=sys.stderr,
            )
        return 1

    panel["launcher_placement"] = desired
    panel["launcher_position"] = position

    # Atomic write
    tmp = settings_path.with_suffix(".tmp")
    try:
        with open(tmp, "wb") as f:
            tomli_w.dump(data, f)
        tmp.replace(settings_path)
    except Exception as e:
        print(f"write error: {e}", file=sys.stderr)
        try:
            tmp.unlink(missing_ok=True)
        except Exception:
            pass
        return 2

    if args.verbose:
        print(
            f"switched {old_placement!r}/{old_position!r} -> {desired!r}/{position!r} in {settings_path}",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
