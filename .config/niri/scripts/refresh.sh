#!/usr/bin/env bash
# refresh.sh — Hypr Utils.refresh() port: reload noctalia + niri
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/helpers.sh"
niri msg action load-config-file 2>/dev/null || true
if is_exec noctalia; then noctalia msg config-reload >/dev/null 2>&1 || true; fi
notify "Refresh" "Niri + Noctalia reloaded" "low"
