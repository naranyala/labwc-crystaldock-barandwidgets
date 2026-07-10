#!/bin/bash
# Simple calculator using rofi and bc
set -euo pipefail

res=$(rofi -dmenu -p "Calc: " -l 0 </dev/null) || true

if [ -n "$res" ]; then
    if ans=$(echo "$res" | bc -l 2>&1); then
        echo "$ans" | wl-copy
        notify-send "Calculator" "$res = $ans\n\n(Copied to clipboard)" -i "accessories-calculator"
    else
        notify-send "Calculator Error" "$ans" -i "dialog-error"
    fi
fi
