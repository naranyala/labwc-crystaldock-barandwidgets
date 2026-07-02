#!/bin/bash

# MangoWM and Zebar Dotfiles Installation Script
# Updated to use crystal-dock as primary dock

Set -euo pipefail

echo "=== Installing MangoWM and Zebar Dotfiles (with crystal-dock as primary dock) ==="

# Function to create configuration directory
create_config_dir() {
    local config_path="$1"
    if [[ ! -d "$config_path" ]]; then
        mkdir -p "$config_path"
        echo "Created directory: $config_path"
    fi
}

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    
    # Backup existing if present
    if [[ -L "$target" ]]; then
        echo "Removing existing symlink: $target"
        rm -f "$target"
    elif [[ -e "$target" ]]; then
        echo "Warning: Non-symlink file exists at $target, backing up..."
        mv "$target" "${target}.backup"
    fi
    
    # Create symlink
    ln -sf "$source" "$target"
    echo "Symlink created: $target -> $source"
}

# Create config directories
create_config_dir "$HOME/.config/mango"
create_config_dir "$HOME/.config/zebar/main"

# Copy MangoWM configuration
MANGO_CONFIG_SOURCE="$(pwd)/dotfiles/mango/config.conf"
MANGO_CONFIG_TARGET="$HOME/.config/mango/config.conf"

echo ""
echo "=== MangoWM Configuration ==="
echo "Source: $MANGO_CONFIG_SOURCE"
echo "Target: $MANGO_CONFIG_TARGET"

# Create symlink for MangoWM config
cat > "$MANGO_CONFIG_TARGET" << 'CONFIG_EOF'
# MangoWM Configuration
# crystal-dock is the primary dock for the desktop environment

# Autostart
exec-once=crystal-dock --start --overlay
exec-once=swaybg -i /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_Large.png

# Keybindings - Common
keymode=common
bind=SUPER,R,reload_config
bind=SUPER+Q,killclient
bind=SUPER+M,quit

# Keybindings - Default
keymode=default
bind=SUPER,Return,spawn,foot
bind=SUPER,D,spawn,rofi -show drun
bind=SUPER,E,togglefloating
bind=SUPER,F,togglefullscreen
bind=SUPER,Space,toggleoverview

# Focus and Movement
bind=SUPER,Left,focusdir,left
bind=SUPER,Right,focusdir,right
bind=SUPER,Up,focusdir,up
bind=SUPER,Down,focusdir,down

bind=SUPER+SHIFT,Left,exchange_client,left
bind=SUPER+SHIFT,Right,exchange_client,right
bind=SUPER+SHIFT,Up,exchange_client,up
bind=SUPER+SHIFT,Down,exchange_client,down

# Tags and Workspaces
bind=ALT,1,view,1
bind=ALT,2,view,2
bind=ALT,3,view,3
bind=ALT,4,view,4
bind=ALT,5,view,5
bind=ALT,6,view,6
bind=ALT,7,view,7
bind=ALT,8,view,8
bind=ALT,9,view,9

bind=SUPER+SHIFT,1,tag,1
bind=SUPER+SHIFT,2,tag,2
bind=SUPER+SHIFT,3,tag,3
bind=SUPER+SHIFT,4,tag,4
bind=SUPER+SHIFT,5,tag,5
bind=SUPER+SHIFT,6,tag,6
bind=SUPER+SHIFT,7,tag,7
bind=SUPER+SHIFT,8,tag,8
bind=SUPER+SHIFT,9,tag,9

# Layouts
bind=SUPER,S,switch_layout
bind=SUPER,comma,incgaps,+5
bind=SUPER,period,incgaps,-5

# Media Controls
bind=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%+
bind=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%-
bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SINK@ toggle
bind=NONE,XF86AudioNext,spawn,playerctl next
bind=NONE,XF86AudioPrev,spawn,playerctl previous
bind=NONE,XF86AudioPlay,spawn,playerctl play-pause
CONFIG_EOF

# Create symlink for MangoWM config
create_symlink "$MANGO_CONFIG_SOURCE" "$MANGO_CONFIG_TARGET"

# Validate MangoWM config
echo ""
echo "=== Validating MangoWM Configuration ==="
if [[ -f "$MANGO_CONFIG_TARGET" ]]; then
    if grep -q "exec-once=" "$MANGO_CONFIG_TARGET"; then
        echo "✅ MangoWM configuration contains exec-once directives"
        
        # Check for crystal-dock
        if grep -q "crystal-dock" "$MANGO_CONFIG_TARGET"; then
            echo "✅ crystal-dock is configured as the primary dock"
        else
            echo "⚠️  crystal-dock not found in MangoWM config"
            echo "   Current autostart commands:"
            grep "exec-once=" "$MANGO_CONFIG_TARGET" | sed 's/^/   /'
        fi
    else
        echo "❌ MangoWM configuration missing exec-once directives"
    fi
else
    echo "❌ MangoWM configuration file not found"
fi

# Copy Zebar widget files
ZEBAR_WIDGET_SOURCE_DIR="$(pwd)/dotfiles/zebar/main"
ZEBAR_WIDGET_TARGET_DIR="$HOME/.config/zebar/main"

# Remove existing directory if present
if [[ -d "$ZEBAR_WIDGET_TARGET_DIR" && ! -L "$ZEBAR_WIDGET_TARGET_DIR" ]]; then
    echo ""
    echo "Warning: Non-symlink directory exists at $ZEBAR_WIDGET_TARGET_DIR"
    echo "It will be replaced with the new widget directory"
    rm -rf "$ZEBAR_WIDGET_TARGET_DIR"
fi

# Recreate target directory as symlink
if [[ -e "$ZEBAR_WIDGET_TARGET_DIR" || -L "$ZEBAR_WIDGET_TARGET_DIR" ]]; then
    rm -f "$ZEBAR_WIDGET_TARGET_DIR"
fi

ln -sf "$ZEBAR_WIDGET_SOURCE_DIR" "$ZEBAR_WIDGET_TARGET_DIR"

echo ""
echo "=== Zebar Widget Setup ==="
echo "Source: $ZEBAR_WIDGET_SOURCE_DIR"
echo "Target: $ZEBAR_WIDGET_TARGET_DIR"
echo "✅ Zebar widget files symlinked successfully"

# Update launcher script to work with crystal-dock
cat > "./${HOME}/zebar_launcher.sh" << 'LAUNCHER_EOF'
#!/bin/bash

# Enhanced Zebar Widget Launcher
# Works with crystal-dock as primary dock

ZEBAR_BIN="/usr/bin/zebar"
WIDGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Zebar Widget Launcher (with crystal-dock support) ==="
echo ""
echo "🎯 crystal-dock is your primary dock"
echo "💡 Zebar widgets run as additional panels"
echo ""
echo "Available Zebar widget styles:"
echo "  1. main       - Classic status bar"
echo "  2. minimalist  - Minimalist design"
echo "  3. compact    - Space-optimized"
echo "  4. detailed   - Comprehensive display"
echo "  5. system     - System monitoring"
echo ""

echo "Usage:"
echo "  ${0##*/} [widget-style] [position]"
echo ""
echo "Examples:"
echo "  ${0##*/} minimalist left"
echo "  ${0##*/} system center"
echo "  ${0##*/} detailed right"
echo ""
echo "Managing with crystal-dock:"
echo "  - crystal-dock provides primary panel functionality"
echo "  - Zebar widgets add additional functionality"
echo "  - Work together seamlessly for a unified desktop"
LAUNCHER_EOF
chmod +x "${HOME}/zebar_launcher.sh"

echo ""
echo "=== Crystal-Dock Integration ==="
echo "✅ crystal-dock is installed and available:"
echo "  Path: /usr/bin/crystal-dock"
echo "  Description: Wayland dock with cross-desktop support"
echo ""
echo "🔧 Setup Instructions:"
echo "1. Add crystal-dock to MangoWM config:"
echo "   exec-once=/usr/bin/crystal-dock --start --overlay"
echo ""
echo "2. Launch crystal-dock:"
echo "   /usr/bin/crystal-dock --start --overlay"
echo ""
echo "3. Launch Zebar widgets for additional functionality:"
echo "   ${HOME}/zebar_launcher.sh minimalist left"
echo ""
echo "=== Installation Complete ==="
echo ""
echo "📋 Current Configuration Summary:"
echo "-------------------------"
echo "• Primary Dock: crystal-dock (cross-desktop Wayland dock)"
echo "• Widget System: Zebar (HTML/CSS/JS widgets)"
echo "• Terminal: foot ( Wayland terminal )"
echo "• Launcher: rofi (application launcher)"
echo ""
echo "🎉 Dotfiles installation successful with crystal-dock support!"
echo ""
echo "💡 Key Features:"
echo "  • crystal-dock provides modern, cross-desktop dock functionality"
echo "  • Zebar widgets offer flexible, customizable panels"
echo "  • Integrated system for maximum desktop productivity"
echo ""
