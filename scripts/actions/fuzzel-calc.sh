#!/bin/bash
# Simple calculator using rofi and bc

res=$(rofi -dmenu -p "Calc: " -l 0 </dev/null)

if [ -n "$res" ]; then
    ans=$(echo "$res" | bc -l 2>&1)
    if [ $? -eq 0 ]; then
        echo "$ans" | wl-copy
        notify-send "Calculator" "$res = $ans\n\n(Copied to clipboard)" -i "accessories-calculator"
    else
        notify-send "Calculator Error" "$ans" -i "dialog-error"
    fi
fi
