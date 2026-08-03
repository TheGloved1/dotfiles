#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"
[[ -z "$target" ]] && exit 1

exec 9>/tmp/hypr-ws-scroll.lock
flock -n 9 || exit 1

current=$(hyprctl activeworkspace -j | jq -r '.id')
[[ "$current" == "$target" ]] && exit 0

step=$(( target > current ? 1 : -1 ))
steps=$(( target - current ))
steps=${steps#-}

total_max=250
min_sleep=20
max_cap=150

max_ms=$(( 2 * total_max / (steps + 1) ))
(( max_ms > max_cap )) && max_ms=$max_cap

ws=$current
for (( i = 0; i < steps; i++ )); do
    ws=$(( ws + step ))
    sleep_ms=$(( max_ms * (steps - i) / steps ))
    (( sleep_ms < min_sleep )) && sleep_ms=$min_sleep
    sleep "$(printf '0.%03d' "$sleep_ms")"
    hyprctl dispatch "hl.dsp.focus({ workspace = $ws })" >/dev/null 2>&1 || true
done
