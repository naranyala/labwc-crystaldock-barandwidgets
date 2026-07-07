#!/bin/bash
# sfwbar-dock-test.sh — Test sfwbar in different modes
# Usage: sfwbar-dock-test.sh [start|stop|restart|status|mode]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ocws"
PID_FILE="/tmp/sfwbar-test.pid"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}→${NC} $1"; }
pass()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
err()   { echo -e "${RED}✗${NC} $1"; }

# Available modes
MODES=("doublepanel" "crystaldock" "standalone-dock")

show_modes() {
    echo -e "${BOLD}Available Modes:${NC}"
    echo ""
    echo "  doublepanel    Dual-panel layout (top status bar + bottom dock/taskbar)"
    echo "  crystaldock    Single status bar + external crystal-dock"
    echo "  standalone-dock  Standalone dock bar at bottom"
    echo ""
    echo "Config files:"
    echo "  doublepanel    → ocws.config"
    echo "  crystaldock    → sfwbar-full.config"
    echo "  standalone-dock → sfwbar-dock.config"
}

start_sfwbar() {
    local mode="$1"
    local config_file=""

    case "$mode" in
        doublepanel)
            config_file="$CONFIG_DIR/ocws.config"
            if [[ ! -f "$config_file" ]]; then
                config_file="$SCRIPT_DIR/../dotfiles/ocws/ocws.config"
            fi
            ;;
        crystaldock)
            config_file="$CONFIG_DIR/sfwbar-full.config"
            if [[ ! -f "$config_file" ]]; then
                config_file="$SCRIPT_DIR/../dotfiles/ocws/sfwbar-full.config"
            fi
            ;;
        standalone-dock)
            config_file="$CONFIG_DIR/sfwbar-dock.config"
            if [[ ! -f "$config_file" ]]; then
                # Copy from project if not in config dir
                mkdir -p "$CONFIG_DIR"
                cp "$SCRIPT_DIR/../dotfiles/ocws/sfwbar-dock.config" "$config_file"
                cp "$SCRIPT_DIR/../dotfiles/ocws/dock-exp.widget" "$CONFIG_DIR/"
                cp "$SCRIPT_DIR/../dotfiles/ocws/dock-exp.css" "$CONFIG_DIR/"
            fi
            ;;
        *)
            err "Unknown mode: $mode"
            show_modes
            return 1
            ;;
    esac

    if [[ ! -f "$config_file" ]]; then
        err "Config not found: $config_file"
        return 1
    fi

    # Kill existing sfwbar
    if pgrep -x sfwbar >/dev/null 2>&1; then
        info "Stopping existing sfwbar..."
        pkill -x sfwbar
        sleep 0.3
    fi

    info "Starting sfwbar in $mode mode..."
    info "Config: $config_file"
    
    sfwbar -c "$config_file" &
    echo $! > "$PID_FILE"
    pass "sfwbar started (PID: $!)"
    
    if [[ "$mode" == "standalone-dock" ]]; then
        info "The dock appears at the bottom of the screen"
    elif [[ "$mode" == "crystaldock" ]]; then
        info "Crystal-dock should be started separately"
    fi
}

stop_sfwbar() {
    if pgrep -x sfwbar >/dev/null 2>&1; then
        pkill -x sfwbar
        rm -f "$PID_FILE"
        pass "sfwbar stopped"
    else
        warn "sfwbar not running"
    fi
}

status_sfwbar() {
    if pgrep -x sfwbar >/dev/null 2>&1; then
        local pid=$(pgrep -x sfwbar)
        pass "sfwbar running (PID: $pid)"
        
        # Show which config is being used
        local cmdline=$(ps -p "$pid" -o args= 2>/dev/null || true)
        if [[ -n "$cmdline" ]]; then
            info "Command: $cmdline"
        fi
    else
        info "sfwbar not running"
    fi
}

show_help() {
    echo -e "${BOLD}SFWBar Mode Tester${NC}"
    echo ""
    echo "Usage: $(basename "$0") [command] [mode]"
    echo ""
    echo "Commands:"
    echo "  start <mode>   Start sfwbar in specified mode"
    echo "  stop           Stop sfwbar"
    echo "  restart <mode> Restart sfwbar in specified mode"
    echo "  status         Check if sfwbar is running"
    echo "  modes          Show available modes"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") start doublepanel"
    echo "  $(basename "$0") start crystaldock"
    echo "  $(basename "$0") start standalone-dock"
    echo "  $(basename "$0") stop"
    echo "  $(basename "$0") status"
    echo ""
    show_modes
}

case "${1:-help}" in
    start)
        if [[ -z "${2:-}" ]]; then
            err "Please specify a mode"
            show_modes
            exit 1
        fi
        start_sfwbar "$2"
        ;;
    stop)
        stop_sfwbar
        ;;
    restart)
        if [[ -z "${2:-}" ]]; then
            err "Please specify a mode"
            show_modes
            exit 1
        fi
        stop_sfwbar
        sleep 0.5
        start_sfwbar "$2"
        ;;
    status)
        status_sfwbar
        ;;
    modes)
        show_modes
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        warn "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
