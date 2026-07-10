#!/bin/bash
set -euo pipefail
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper dir $WALLPAPER_DIR not found" >&2
    exit 1
fi
img=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
if [ -z "$img" ]; then
    echo "No wallpaper images found in $WALLPAPER_DIR" >&2
    exit 1
fi
exec swaybg -i "$img" -m fill
