#!/bin/bash
# -------------------------------------------------------------------
# fix-touchpad-tap.sh — Fix touchpad tap-to-click on fresh Linux
#
# Enables: tap-to-click, tap-and-drag, natural scrolling (optional),
# and disable-while-typing for libinput-based touchpads.
#
# Works with:
#   - labwc (patches rc.xml with <libinput> section)
#   - System-wide libinput conf (/etc/X11/xorg.conf.d/ fallback)
#   - gsettings (GNOME/GTK desktops)
# -------------------------------------------------------------------

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "\n${CYAN}==>${NC} $*"; }
pass()  { echo -e "  ${GREEN}✓${NC} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $*"; }
fail()  { echo -e "  ${RED}✗${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================
# 1. Patch labwc rc.xml — add <libinput> touchpad config
# ============================================================

patch_labwc_rc() {
    local rc_file="$1"

    if [ ! -f "$rc_file" ]; then
        warn "labwc rc.xml not found at $rc_file — skipping"
        return 1
    fi

    # Check if <libinput> already exists
    if grep -q '<libinput>' "$rc_file"; then
        warn "labwc rc.xml already has a <libinput> section"
        # Update existing values in-place
        if grep -q 'tapToClick' "$rc_file" 2>/dev/null; then
            pass "tapToClick already configured in rc.xml"
        else
            warn "libinput section exists but tapToClick missing — manual review recommended"
        fi
        return 0
    fi

    # Insert <libinput> block before </labwc_config>
    local libinput_block
    libinput_block=$(cat << 'XMLEOF'

  <!-- Touchpad / Pointer configuration (libinput) -->
  <libinput>
    <!-- Touchpad: enable tap-to-click, drag, dwt -->
    <device category="touchpad">
      <tap>yes</tap>
      <tapButtonMap>lmr</tapButtonMap>
      <tapAndDrag>yes</tapAndDrag>
      <dragLock>yes</dragLock>
      <naturalScroll>no</naturalScroll>
      <disableWhileTyping>yes</disableWhileTyping>
      <middleEmulation>yes</middleEmulation>
      <scrollMethod>twofinger</scrollMethod>
      <clickMethod>clickfinger</clickMethod>
      <sendEventsMode>yes</sendEventsMode>
      <accelProfile>flat</accelProfile>
      <pointerSpeed>0.0</pointerSpeed>
    </device>
    <!-- Default pointer (mouse) -->
    <device category="default">
      <naturalScroll>no</naturalScroll>
      <accelProfile>flat</accelProfile>
      <pointerSpeed>0.0</pointerSpeed>
    </device>
  </libinput>
XMLEOF
)

    # Backup before patching
    cp "$rc_file" "${rc_file}.bak.$(date +%s)"
    pass "Backup created: ${rc_file}.bak.*"

    # Insert before closing </labwc_config>
    sed -i "/<\/labwc_config>/i\\${libinput_block}" "$rc_file"
    pass "Patched labwc rc.xml with touchpad tap-to-click config"
}

# ============================================================
# 2. Create system-wide libinput conf (fallback for non-labwc)
# ============================================================

create_libinput_conf() {
    local conf_dir="/etc/X11/xorg.conf.d"
    local conf_file="$conf_dir/40-touchpad-tap.conf"

    if [ -f "$conf_file" ]; then
        warn "System libinput conf already exists at $conf_file"
        return 0
    fi

    local conf_content='Section "InputClass"
    Identifier "touchpad-tap-to-click"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lmr"
    Option "TappingDrag" "on"
    Option "TappingDragLock" "on"
    Option "NaturalScrolling" "off"
    Option "DisableWhileTyping" "on"
    Option "MiddleEmulation" "on"
    Option "ScrollMethod" "twofinger"
    Option "ClickMethod" "clickfinger"
    Option "AccelProfile" "flat"
EndSection'

    if [ -d "$conf_dir" ]; then
        echo "$conf_content" | pkexec tee "$conf_file" > /dev/null
        pass "Created system libinput conf: $conf_file"
    else
        warn "$conf_dir does not exist — creating via pkexec"
        pkexec mkdir -p "$conf_dir"
        echo "$conf_content" | pkexec tee "$conf_file" > /dev/null
        pass "Created system libinput conf: $conf_file"
    fi
}

# ============================================================
# 3. Apply gsettings for GNOME-based / GTK environments
# ============================================================

apply_gsettings() {
    if ! command -v gsettings &>/dev/null; then
        warn "gsettings not found — skipping GTK touchpad settings"
        return 0
    fi

    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null && \
        pass "gsettings: tap-to-click = true" || \
        warn "gsettings: could not set tap-to-click (schema may not exist)"

    gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true 2>/dev/null && \
        pass "gsettings: tap-and-drag = true" || true

    gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true 2>/dev/null && \
        pass "gsettings: disable-while-typing = true" || true

    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null && \
        pass "gsettings: two-finger-scrolling = true" || true
}

# ============================================================
# 4. Verify libinput runtime state
# ============================================================

verify_libinput() {
    if ! command -v libinput &>/dev/null; then
        warn "libinput CLI not found — cannot verify runtime state"
        return 0
    fi

    info "Detected touchpad devices:"
    libinput list-devices 2>/dev/null | awk '
        /^Device:/ { name=$0; sub(/^Device:[[:space:]]*/, "", name) }
        /Tap-to-click:/ {
            status=$0; sub(/.*Tap-to-click:[[:space:]]*/, "", status)
            printf "  %-40s  Tap: %s\n", name, status
        }
    ' || warn "Could not query libinput devices (may need root)"
}

# ============================================================
# Main
# ============================================================

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║${NC}  ${CYAN}Fix Touchpad Tap-to-Click${NC}                              ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  ${DIM}Enables tap, drag, and dwt for libinput touchpads${NC}      ${BOLD}║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"

# --- labwc rc.xml ---
info "Step 1: Patching labwc rc.xml..."

# Check both OCWS dotfiles and live config
LABWC_LIVE="$HOME/.config/labwc/rc.xml"
LABWC_DOTFILES="$SCRIPT_DIR/dotfiles/labwc/rc.xml"

if [ -f "$LABWC_LIVE" ]; then
    patch_labwc_rc "$LABWC_LIVE"
else
    warn "Live labwc config not found at $LABWC_LIVE"
fi

if [ -f "$LABWC_DOTFILES" ]; then
    patch_labwc_rc "$LABWC_DOTFILES"
else
    warn "OCWS dotfiles rc.xml not found at $LABWC_DOTFILES"
fi

# --- System libinput conf ---
info "Step 2: Creating system-wide libinput conf (xorg fallback)..."
create_libinput_conf

# --- gsettings ---
info "Step 3: Applying gsettings for GTK desktop..."
apply_gsettings

# --- Verify ---
info "Step 4: Verifying libinput device state..."
verify_libinput

# --- Reconfigure labwc if running ---
info "Step 5: Reconfiguring labwc (if running)..."
if pgrep -x labwc > /dev/null 2>&1; then
    killall -SIGHUP labwc 2>/dev/null && pass "Sent SIGHUP to labwc — config reloaded" || \
        warn "Could not send SIGHUP to labwc"
else
    warn "labwc is not running — changes will apply on next session start"
fi

echo ""
echo -e "${GREEN}${BOLD}Done!${NC} Touchpad tap-to-click should now be enabled."
echo -e "${DIM}If tap still doesn't work, log out and back in to your Wayland session.${NC}"
echo ""
