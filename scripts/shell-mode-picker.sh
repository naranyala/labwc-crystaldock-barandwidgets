#!/bin/bash
# Uses rofi to select shell mode

declare -A MODES=(
    ["1. Dank Material Shell (Default)"]="dms"
    ["2. Noctalia (Legacy)"]="noctalia"
    ["3. SFWBar + Crystal Dock"]="crystal"
    ["4. SFWBar Dual Panel"]="both"
)

# Generate list for rofi
OPTIONS=""
for key in "${!MODES[@]}"; do
    OPTIONS+="$key\n"
done

# Run rofi
SELECTION=$(echo -e "$OPTIONS" | sort | rofi -dmenu -p "Select Shell Mode: " -theme-str 'window {width: 400px;}')

if [ -n "$SELECTION" ]; then
    MODE_ID="${MODES[$SELECTION]}"
    if [ -n "$MODE_ID" ]; then
        /home/naranyala/.local/bin/shell-switcher.sh "$MODE_ID" &
    fi
fi
