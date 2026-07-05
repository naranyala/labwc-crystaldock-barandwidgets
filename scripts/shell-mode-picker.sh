#!/bin/bash
# Uses fuzzel to select shell mode

declare -A MODES=(
    ["1. Dank Material Shell (Default)"]="dms"
    ["2. Noctalia (Legacy)"]="noctalia"
    ["3. SFWBar + Crystal Dock"]="crystal"
    ["4. SFWBar Dual Panel"]="both"
)

# Generate list for fuzzel
OPTIONS=""
for key in "${!MODES[@]}"; do
    OPTIONS+="$key\n"
done

# Run fuzzel
SELECTION=$(echo -e "$OPTIONS" | sort | fuzzel -d -p "Select Shell Mode: " -l 3)

if [ -n "$SELECTION" ]; then
    MODE_ID="${MODES[$SELECTION]}"
    if [ -n "$MODE_ID" ]; then
        /home/naranyala/.local/bin/shell-switcher.sh "$MODE_ID" &
    fi
fi
