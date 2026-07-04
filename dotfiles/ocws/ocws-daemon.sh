#!/bin/bash
# -------------------------------------------------------------------
# OCWS State Daemon (Phase 3)
# Event-driven IPC for sfwbar - No more polling!
# -------------------------------------------------------------------

# Stop any running instances
pkill -f "ocws-daemon.sh" 2>/dev/null
sleep 0.1

update_volume() {
    RAW=$(wpctl get-volume @DEFAULT_SINK@ 2>/dev/null || echo "Volume: 0.00")
    VOL=$(echo "$RAW" | grep -oP '(?<=Volume: )[0-9.]+' || echo "0.00")
    VOL_PERCENT=$(echo "$VOL * 100 / 1" | bc 2>/dev/null || echo "0")
    
    MUTED=0
    if echo "$RAW" | grep -q "MUTED"; then MUTED=1; fi
    
    # Push to OCWS instantly using the standard Event Bus
    ~/.local/bin/ocws-emit.sh System.Volume "$VOL_PERCENT"
    ~/.local/bin/ocws-emit.sh System.VolumeMuted "$MUTED"
}

update_brightness() {
    BRIGHT=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d % || echo 100)
    ~/.local/bin/ocws-emit.sh System.Brightness "$BRIGHT"
}

# 1. Volume Listener
if command -v pactl >/dev/null 2>&1; then
    (
        # Listen for PipeWire/PulseAudio sink changes
        pactl subscribe 2>/dev/null | grep --line-buffered "Event 'change' on sink" | while read -r line; do
            update_volume
        done
    ) &
fi

# 2. Brightness Listener
if command -v inotifywait >/dev/null 2>&1; then
    (
        # Listen for backlight file changes directly from kernel
        inotifywait -m -e modify /sys/class/backlight/*/brightness 2>/dev/null | while read -r line; do
            update_brightness
        done
    ) &
fi

wait
