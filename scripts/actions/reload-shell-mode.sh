#!/bin/bash
# reload-shell-mode.sh — Reload the currently active shell mode
# Keybinding: Super+R

set -euo pipefail

CFG="$HOME/.config/ocws/mode"

# Get current mode
CURRENT="$(cat "$CFG" 2>/dev/null || echo "dms")"

# Path to toggle-shell
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOGGLE_SHELL="$SCRIPT_DIR/../toggle-shell"

if [ -x "$TOGGLE_SHELL" ]; then
    "$TOGGLE_SHELL" "$CURRENT"
    notify-send -u low "Shell Mode" "Reloaded: $CURRENT" 2>/dev/null || true
else
    notify-send -u critical "Shell Mode" "Error: toggle-shell not found" 2>/dev/null || true
    exit 1
fi
