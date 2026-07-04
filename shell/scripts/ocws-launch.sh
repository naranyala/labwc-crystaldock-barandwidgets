#!/bin/bash
#
# ocws-launch.sh -- Launch the OCWS desktop shell
#
# OCWS: Our C-Written Shell
# A batteries-included Wayland desktop shell built on sfwbar
#
# Usage:
#   ocws-launch.sh              Launch full shell
#   ocws-launch.sh --top        Top bar only
#   ocws-launch.sh --bottom     Bottom bar only
#   ocws-launch.sh --restart    Restart shell
#   ocws-launch.sh --stop       Stop shell
#   ocws-launch.sh --status     Show shell status
#
# Usage:
#   shell-launch.sh              Launch full shell
#   shell-launch.sh --top        Top bar only
#   shell-launch.sh --bottom     Bottom bar only
#   shell-launch.sh --restart    Restart shell
#   shell-launch.sh --stop       Stop shell
#   shell-launch.sh --status     Show shell status
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SFWBAR_DIR="$HOME/.config/sfwbar"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}-->${NC} $*"; }
pass()  { echo -e "${GREEN}  ✓${NC} $*"; }
warn()  { echo -e "${YELLOW}  !${NC} $*"; }
fail()  { echo -e "${RED}  ✗${NC} $*"; exit 1; }

# --- Copy shell files to sfwbar config dir ---
install_shell() {
  info "Installing shell widgets..."

  mkdir -p "$SFWBAR_DIR"

  # Copy main config
  if [ -f "$SHELL_DIR/shell.config" ]; then
    cp "$SHELL_DIR/shell.config" "$SFWBAR_DIR/sfwbar.config"
    pass "shell.config -> sfwbar.config"
  fi

  # Copy widgets
  for f in "$SHELL_DIR"/widgets/*.widget; do
    [ -f "$f" ] && cp "$f" "$SFWBAR_DIR/" && pass "$(basename "$f")"
  done

  # Copy sources
  for f in "$SHELL_DIR"/sources/*.source; do
    [ -f "$f" ] && cp "$f" "$SFWBAR_DIR/" && pass "$(basename "$f")"
  done

  # Copy CSS (if not already present)
  for f in "$SHELL_DIR"/css/*.css; do
    if [ -f "$f" ] && [ ! -f "$SFWBAR_DIR/$(basename "$f")" ]; then
      cp "$f" "$SFWBAR_DIR/"
      pass "$(basename "$f")"
    fi
  done

  pass "Shell installed to $SFWBAR_DIR"
}

# --- Stop shell ---
stop_shell() {
  info "Stopping shell..."
  if pgrep -x sfwbar >/dev/null 2>&1; then
    pkill -9 -x sfwbar 2>/dev/null || true
    sleep 0.3
    pass "sfwbar stopped"
  else
    info "sfwbar not running"
  fi
}

# --- Start shell ---
start_shell() {
  local config="${1:-sfwbar.config}"
  local css="catppuccin-mocha.css"

  info "Starting shell ($config)..."

  # Find CSS file
  for f in catppuccin-mocha.css noctalia.css theme.css; do
    if [ -f "$SFWBAR_DIR/$f" ]; then
      css="$f"
      break
    fi
  done

  local CSS_ARG=""
  local CONFIG_ARG=""
  [ -f "$SFWBAR_DIR/$css" ] && CSS_ARG="-c $SFWBAR_DIR/$css"
  [ -f "$SFWBAR_DIR/$config" ] && CONFIG_ARG="-f $SFWBAR_DIR/$config"

  if [ -z "$CONFIG_ARG" ]; then
    fail "Config not found: $SFWBAR_DIR/$config"
  fi

  nohup sfwbar $CONFIG_ARG $CSS_ARG > /dev/null 2>&1 &
  sleep 1

  if pgrep -x sfwbar >/dev/null 2>&1; then
    pass "Shell started (PID: $(pgrep -x sfwbar | tr '\n' ' '))"
  else
    fail "Shell failed to start"
  fi
}

# --- Status ---
show_status() {
  echo ""
  echo -e "${BOLD}Shell Status${NC}"
  echo ""

  if pgrep -x sfwbar >/dev/null 2>&1; then
    pass "sfwbar: running (PID: $(pgrep -x sfwbar | tr '\n' ' '))"

    for pid in $(pgrep -x sfwbar); do
      local cmd
      cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || echo "unknown")
      info "  $pid: $cmd"
    done
  else
    warn "sfwbar: not running"
  fi

  echo ""

  # Check config files
  if [ -f "$SFWBAR_DIR/sfwbar.config" ]; then
    pass "Config: sfwbar.config"
  else
    warn "Config: sfwbar.config missing"
  fi

  if [ -f "$SFWBAR_DIR/catppuccin-mocha.css" ]; then
    pass "CSS: catppuccin-mocha.css"
  else
    warn "CSS: no theme found"
  fi

  # Count widgets
  local count=0
  for f in "$SFWBAR_DIR"/*.widget; do
    [ -f "$f" ] && ((count++))
  done 2>/dev/null
  info "Widgets: $count files"
}

# --- Main ---
case "${1:-}" in
  --install)
    install_shell
    ;;
  --stop)
    stop_shell
    ;;
  --restart)
    stop_shell
    sleep 0.5
    install_shell
    start_shell
    ;;
  --status)
    show_status
    ;;
  --top)
    install_shell
    stop_shell
    start_shell "sfwbar.config"
    ;;
  --help|-h)
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  (none)       Install + launch full shell"
    echo "  --install    Install shell files to ~/.config/sfwbar/"
    echo "  --stop       Stop sfwbar"
    echo "  --restart    Stop + install + start"
    echo "  --status     Show shell status"
    echo "  --top        Launch top bar only"
    echo "  --help       Show this help"
    echo ""
    ;;
  *)
    install_shell
    start_shell
    ;;
esac
