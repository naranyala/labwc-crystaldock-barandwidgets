#!/bin/bash
# dock-backup.sh — Backup and restore pinned dock apps for DankMaterialShell and Noctalia
# 
# Usage:
#   dock-backup.sh backup <name>    (e.g. dock-backup.sh backup work_profile)
#   dock-backup.sh restore <name>
#   dock-backup.sh list

BACKUP_DIR="$HOME/.config/ocws/dock_backups"
DMS_SESSION="$HOME/.local/state/DankMaterialShell/session.json"
NOCTALIA_CONFIG="$HOME/.config/noctalia/config.toml"

mkdir -p "$BACKUP_DIR"

usage() {
    echo "Dock Pinned Apps Backup Manager"
    echo "==============================="
    echo "Usage: dock-backup.sh <command> [name]"
    echo ""
    echo "Commands:"
    echo "  backup <name>    Backup current pinned apps to <name>"
    echo "  restore <name>   Restore pinned apps from backup <name>"
    echo "  list             List all available backups"
    echo ""
    echo "Example: dock-backup.sh backup gaming_setup"
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

COMMAND=$1
NAME=${2:-"default"}

case "$COMMAND" in
    backup)
        echo "Creating backup: $NAME"
        echo "------------------------"
        
        # Backup DMS
        if [[ -f "$DMS_SESSION" ]]; then
            if command -v jq >/dev/null 2>&1; then
                jq -c '.pinnedApps // []' "$DMS_SESSION" > "$BACKUP_DIR/${NAME}_dms.json" 2>/dev/null
                echo "✓ Backed up DankMaterialShell pinned apps"
            else
                echo "⚠ jq not found, skipping DankMaterialShell backup"
            fi
        fi
        
        # Backup Noctalia
        if [[ -f "$NOCTALIA_CONFIG" ]]; then
            awk '
            /^\[dock\]/ {in_dock=1; next}
            /^\[/ && !/^\[dock\]/ {in_dock=0}
            in_dock && /^pinned\s*=/ {
                idx = index($0, "#")
                if (idx > 0) line = substr($0, 1, idx - 1)
                else line = $0
                match(line, /\[.*\]/)
                if (RSTART) print substr(line, RSTART, RLENGTH)
            }' "$NOCTALIA_CONFIG" > "$BACKUP_DIR/${NAME}_noctalia.json"
            
            # If the file is empty (e.g. no dock section found), put an empty array
            if [[ ! -s "$BACKUP_DIR/${NAME}_noctalia.json" ]]; then
                echo "[]" > "$BACKUP_DIR/${NAME}_noctalia.json"
            fi
            
            echo "✓ Backed up Noctalia pinned apps"
        fi
        
        echo "Backup complete!"
        ;;
        
    restore)
        echo "Restoring backup: $NAME"
        echo "------------------------"
        
        # Restore DMS
        if [[ -f "$BACKUP_DIR/${NAME}_dms.json" && -f "$DMS_SESSION" ]]; then
            if command -v jq >/dev/null 2>&1; then
                TMP_FILE=$(mktemp)
                jq --argjson pins "$(< "$BACKUP_DIR/${NAME}_dms.json")" '.pinnedApps = $pins' "$DMS_SESSION" > "$TMP_FILE" && mv "$TMP_FILE" "$DMS_SESSION"
                echo "✓ Restored DankMaterialShell pinned apps"
                echo "  (Note: You may need to restart DankMaterialShell for changes to take effect)"
            fi
        elif [[ ! -f "$BACKUP_DIR/${NAME}_dms.json" && -f "$DMS_SESSION" ]]; then
            echo "⚠ No DMS backup found for '$NAME'"
        fi
        
        # Restore Noctalia
        if [[ -f "$BACKUP_DIR/${NAME}_noctalia.json" && -f "$NOCTALIA_CONFIG" ]]; then
            PINS=$(cat "$BACKUP_DIR/${NAME}_noctalia.json")
            TMP_FILE=$(mktemp)
            awk -v pins="$PINS" '
            /^\[dock\]/ {in_dock=1}
            /^\[/ && !/^\[dock\]/ {in_dock=0}
            in_dock && /^pinned\s*=/ {
                # Preserve any comments on the line
                idx = index($0, "#")
                if (idx > 0) comment = substr($0, idx)
                else comment = ""
                
                # We know the key is "pinned", replace everything between it and the comment
                print "pinned              = " pins "            " comment
                next
            }
            {print}
            ' "$NOCTALIA_CONFIG" > "$TMP_FILE" && mv "$TMP_FILE" "$NOCTALIA_CONFIG"
            echo "✓ Restored Noctalia pinned apps"
        elif [[ ! -f "$BACKUP_DIR/${NAME}_noctalia.json" && -f "$NOCTALIA_CONFIG" ]]; then
            echo "⚠ No Noctalia backup found for '$NAME'"
        fi
        
        echo "Restore complete!"
        ;;
        
    list)
        echo "Available backups in $BACKUP_DIR:"
        echo "---------------------------------"
        if [[ -d "$BACKUP_DIR" ]]; then
            # Get unique backup names
            ls -1 "$BACKUP_DIR" 2>/dev/null | sed -E 's/_(dms|noctalia)\.json$//' | sort -u | while read -r bname; do
                [[ -z "$bname" ]] && continue
                echo "• $bname"
            done
        else
            echo "No backups found."
        fi
        ;;
        
    *)
        usage
        ;;
esac
