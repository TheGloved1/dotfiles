#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${NOCTALIA_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/noctalia"
CONFIG_FILE="$CONFIG_DIR/config.toml"
TMP_FILE="$(mktemp "$CONFIG_DIR/config.toml.XXXXXX")"

noctalia config export >"$TMP_FILE"
mv "$TMP_FILE" "$CONFIG_FILE"

echo "Exported merged config to $CONFIG_FILE"
