# MangoWM and Zebar Configuration Guide

## MangoWM Configuration

### Configuration File Location

- **System Path**: `/etc/mango/config.conf` (system-wide)
- **User Path**: `~/.config/mango/config.conf` (user-specific)

### Configuration Structure

MangoWM uses an INI-like configuration format:

```ini
# Section: Autostart
exec-once=<command>

# Section: Keybindings
keymode=<common|default|layout_specific>
bind=<key_combination>,<action>,[<parameter>,...]

# Section: Layout Configuration
layout=<layout_name>
gaps=<size>
```

### Key Configuration Categories

#### Autostart Commands
```ini
# Primary dock with crystal-dock
exec-once=/usr/bin/crystal-dock --start --overlay

# Background image
exec-once=swaybg -i /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_Large.png
```

#### Keybindings
```ini
# Common keybindings (basic navigation)
keymode=common
bind=SUPER,R,reload_config
bind=SUPER,Q,killclient
bind=SUPER,M,quit

# Default keybindings (application management)
keymode=default
bind=SUPER,Return,spawn,foot
bind=SUPER,D,spawn,rofi -show drun
bind=SUPER,E,togglefloating
bind=SUPER,F,togglefullscreen
bind=SUPER,Space,toggleoverview
```

#### Layout Configuration
```ini
# Layout settings
layout=scroller
gaps=10

# Focus and movement
bind=SUPER,Left,focusdir,left
bind=SUPER,Right,focusdir,right
bind=SUPER,Up,focusdir,up
bind=SUPER,Down,focusdir,down
```

### Advanced Configuration Examples

#### Custom Media Controls
```ini
bind=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%+
bind=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%-
bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SINK@ toggle
```

#### Tag and Workspace Management
```ini
# Alphabet key bindings for workspaces
bind=ALT,1,view,1
bind=ALT,2,view,2
bind=ALT,3,view,3
bind=ALT,4,view,4
bind=ALT,5,view,5
bind=ALT,6,view,6
bind=ALT,7,view,7
bind=ALT,8,view,8
bind=ALT,9,view,9

# Super key bindings for tagging
bind=SUPER+SHIFT,1,tag,1
bind=SUPER+SHIFT,2,tag,2
bind=SUPER+SHIFT,3,tag,3
bind=SUPER+SHIFT,4,tag,4
bind=SUPER+SHIFT,5,tag,5
bind=SUPER+SHIFT,6,tag,6
bind=SUPER+SHIFT,7,tag,7
bind=SUPER+SHIFT,8,tag,8
bind=SUPER+SHIFT,9,tag,9
```

#### Layout Customization
```ini
# Switch between layouts
bind=SUPER,S,switch_layout

# Adjust gaps
bind=SUPER,comma,incgaps,+5
bind=SUPER,period,incgaps,-5

# Layout-specific keybindings
keymode=layout_specific
# Layout-specific bindings here...
```

## Zebar Widget Configuration

### Widget Directory Structure

```
~/.config/zebar/
├── main/                    # Main status widget
│   ├── index.html         # Widget HTML
│   ├── style.css           # Widget styles
│   └── widget.js           # Widget JavaScript
├── widgets/                # Additional widget categories
│   ├── minimalist/         # Minimalist widget
│   │   ├── index.html
│   │   ├── style.css
│   │   └── widget.js
│   ├── compact/            # Compact widget
│   │   ├── index.html
│   │   ├── style.css
│   │   └── widget.js
│   ├── detailed/           # Detailed widget
│   │   ├── index.html
│   │   ├── style.css
│   │   └── widget.js
│   └── system/             # System widget
│       ├── index.html
│       ├── style.css
│       └── widget.js
```

### Widget Configuration Files

#### Index.html (Core Structure)
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Widget Name</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        /* Widget-specific styles */
    </style>
</head>
<body>
    <!-- Widget HTML structure -->
</body>
</html>
```

#### Style.css (Widget Styling)
```css
/* Widget container */
.widget-container {
    background: rgba(0, 0, 0, 0.8);
    border-radius: 8px;
    padding: 12px;
    backdrop-filter: blur(10px);
}

/* Status items */
.status-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    border-radius: 4px;
    transition: all 0.2s ease;
}

.status-item:hover {
    background: rgba(255, 255, 255, 0.1);
}
```

#### Widget.js (Widget Logic)
```javascript
class Widget {
    constructor() {
        this.data = {};
        this.elements = {};
        this.interval = null;
    }

    async update() {
        try {
            const response = await fetch('http://localhost:8080/api/system');
            this.data = await response.json();
            this.render();
        } catch (error) {
            console.error('Failed to update widget data:', error);
            this.renderError();
        }
    }

    render() {
        // Update DOM elements with data
    }

    destroy() {
        if (this.interval) {
            clearInterval(this.interval);
        }
    }
}

// Initialize widget
const widget = new Widget();
widget.update();
widget.interval = setInterval(() => widget.update(), 2000);
```

## Configuration Validation

### MangoWM Configuration Test

```bash
# Test configuration syntax
mango -p

# Validate configuration with specific options
mango -c ~/.config/mango/config.conf -p

# Validate and show potential issues
mango -p -v
```

### Zebar Widget Validation

```bash
# Check Zebar installation
/usr/bin/zebar --version

# List installed widgets
/usr/bin/zebar list

# Test widget loading
/usr/bin/zebar test widget/main
```

### Configuration Backup

```bash
# Create configuration backup
mkdir -p ~/.config/mango/backups
cp ~/.config/mango/config.conf ~/.config/mango/backups/config.conf.$(date +%Y%m%d%H%M%S)

# Create comprehensive backup
mango dump > mango-backup-$(date +%Y%m%d%H%M%S).mango
```

## Configuration Templates

### Base Template

```ini
# Base configuration template for MangoWM
# Customizations should be applied as needed

# Autostart
exec-once=/usr/bin/crystal-dock --start --overlay
exec-once=swaybg -i /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_Large.png

# Keybindings (common)
keymode=common
bind=SUPER,R,reload_config
bind=SUPER+Q,killclient
bind=SUPER+M,quit

# Keybindings (default)
keymode=default
bind=SUPER,Return,spawn,foot
bind=SUPER,D,spawn,rofi -show drun
bind=SUPER,E,togglefloating
bind=SUPER,F,togglefullscreen
bind=SUPER,Space,toggleoverview

# Focus and movement
bind=SUPER,Left,focusdir,left
bind=SUPER,Right,focusdir,right
bind=SUPER,Up,focusdir,up
bind=SUPER,Down,focusdir,down

# Tags and workspaces
bind=ALT,1,view,1
bind=ALT,2,view,2
bind=ALT,3,view,3
bind=ALT,4,view,4
bind=ALT,5,view,5
bind=ALT,6,view,6
bind=ALT,7,view,7
bind=ALT,8,view,8
bind=ALT,9,view,9

# Layouts
bind=SUPER,S,switch_layout
bind=SUPER,comma,incgaps,+5
bind=SUPER,period,incgaps,-5

# Media controls
bind=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%+
bind=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%-
bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SINK@ toggle
bind=NONE,XF86AudioNext,spawn,playerctl next
bind=NONE,XF86AudioPrev,spawn,playerctl previous
bind=NONE,XF86AudioPlay,spawn,playerctl play-pause
```

### Custom Layout Configuration

```ini
# Scroller layout with custom gaps
layout=scroller
gaps=12

# Master-stack layout with custom master width
layout=master-stack
master_width=400
stack_spacing=20
```

## Environment-Specific Configuration

### Development Environment

```ini
# Development settings
log_level=debug
debug_mode=enabled
animation_duration=300

# Development keybindings
keymode=common
bind=SUPER,F12,reload_config,development
```

### Production Environment

```ini
# Production settings
log_level=info
debug_mode=disabled
animation_duration=200

# Production keybindings
keymode=default
bind=SUPER,F12,reload_config,production
```

### Mobile Environment

```ini
# Mobile-optimized settings
log_level=warning
debug_mode=disabled
animation_duration=150
gaps=8

# Mobile keybindings
keymode=common
bind=SUPER,Space,toggleoverview,mobile
```

## Troubleshooting Configuration

### Common Configuration Issues

#### 1. Invalid Keybindings
```ini
# ❌ Incorrect syntax
bind=SUPER,R,reload,config

# ✅ Correct syntax
bind=SUPER,R,reload_config
```

#### 2. Missing Autostart Commands
```ini
# ❌ Missing necessary services
exec-once=swaybg

# ✅ Including all required services
exec-once=/usr/bin/crystal-dock --start --overlay
exec-once=swaybg -i /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_Large.png
exec-once=/usr/bin/zebar startup
```

#### 3. Incorrect Layout Settings
```ini
# ❌ Invalid layout name
layout=invalid_layout

# ✅ Valid layout names
scroll master-stack monocle dwindle grid
```

### Configuration Debugging Tools

#### Syntax Validation
```bash
# Check for configuration errors
mango -p

# Validate configuration with specific file
mango -c ~/.config/mango/config.conf -p

# Validate configuration and save debug output
mango -p > mango-debug.log 2>&1
```

#### Configuration Diff
```bash
# Compare current and backup configurations
diff ~/.config/mango/config.conf ~/.config/mango/config.conf.backup

# Show configuration changes
diff -u ~/.config/mango/config.conf.backup ~/.config/mango/config.conf
```

#### Log Analysis
```bash
# Check MangoWM logs
journalctl -u mango -f

# Check system logs
journalctl --since "1 hour ago" --grep="mango"
```

## Configuration Migration

### From Old Structure to New Structure

#### Step 1: Backup Current Configuration
```bash
# Create backup
mkdir -p ~/.config/mango/backups
cp ~/.config/mango/config.conf ~/.config/mango/backups/config.conf.backup
```

#### Step 2: Migrate Keybindings

```ini
# Old format (from old config file)
bind=super+r,reload_config

# New format
bind=SUPER,R,reload_config
```

#### Step 3: Migrate Autostart Commands

```ini
# Old format
exec-once=zebar startup

# New format  
exec-once=/usr/bin/zebar startup
```

#### Step 4: Update Layout Settings

```ini
# Old format (if present)
layout=scroller

# New format
layout=scroller
gaps=10
```

## Configuration Best Practices

### 1. File Organization
- Place all configuration in `~/.config/`
- Use `.conf`, `.ini`, or `.yaml` extensions
- Keep system and user configurations separate

### 2. Keybinding Structure
- Use consistent keybinding patterns
- Document keybindings for team collaboration
- Use modifier keys appropriately

### 3. Autostart Management
- List autostart commands in logical order
- Include error handling for critical services
- Provide fallback mechanisms

### 4. Environment-Specific Configurations
- Use environment variables for sensitive data
- Separate development and production configurations
- Implement configuration validation

### 5. Documentation
- Document configuration changes
- Include examples for complex settings
- Provide troubleshooting guides

## Configuration Management

### Automated Configuration Testing

```bash
#!/bin/bash
# validate_config.sh - Configuration validation script

set -euo pipefail

CONFIG_PATH="~/.config/mango/config.conf"
BACKUP_DIR="~/.config/mango/backups"

# Function to test MangoWM configuration
test_mango_config() {
    echo "Testing MangoWM configuration..."
    if mango -c "$CONFIG_PATH" -p; then
        echo "✅ MangoWM configuration is valid"
        return 0
    else
        echo "❌ MangoWM configuration has errors"
        return 1
    fi
}

# Function to validate Zebar widgets
validate_zebar_widgets() {
    echo "Validating Zebar widgets..."
    local widget_dir="$HOME/.config/zebar"
    
    if [[ ! -d "$widget_dir" ]]; then
        echo "❌ Zebar directory not found"
        return 1
    fi
    
    for widget in "$widget_dir"/*/; do
        if [[ -f "${widget}index.html" ]]; then
            echo "✅ Widget found: $(basename "$widget")"
        else
            echo "⚠️  Widget directory incomplete: $(basename "$widget")"
        fi
    done
}

# Function to create backup
create_backup() {
    local backup_path="$BACKUP_DIR/config-$(date +%Y%m%d%H%M%S).conf"
    cp "$CONFIG_PATH" "$backup_path"
    echo "Backup created: $backup_path"
}

# Main validation routine
main() {
    echo "=== Configuration Validation ==="
    
    # Test configuration
    test_mango_config
    validate_zebar_widgets
    
    # Create backup if validation passes
    if [[ $? -eq 0 ]]; then
        create_backup
        echo "✅ Configuration validation successful"
        exit 0
    else
        echo "❌ Configuration validation failed"
        exit 1
    fi
}

main "$@"
```

### Configuration Monitoring

```bash
#!/bin/bash
# monitor_config.sh - Configuration monitoring script

set -euo pipefail

CONFIG_PATH="~/.config/mango/config.conf"
LOG_FILE="~/.config/mango/config.log"

# Monitor configuration changes
monitor_config_changes() {
    inotifywait -m "$CONFIG_PATH" --format '%e %w%f' | while read event file; do
        echo "$(date): Configuration changed - $event" >> "$LOG_FILE"
        
        # Validate configuration on change
        if mango -c "$CONFIG_PATH" -p; then
            echo "$(date): Configuration validated successfully" >> "$LOG_FILE"
        else
            echo "$(date): Configuration validation failed" >> "$LOG_FILE"
            # Notify user or take action
        fi
    done
}

# Monitor for changes
monitor_config_changes
```

## Configuration Security

### Sensitive Data Protection

```ini
# ❌ Do not include sensitive data in configuration files
bind=SUPER,P,spawn,echo 'secret_password'

# ✅ Use environment variables for sensitive data
bind=SUPER,P,spawn,echo ${SECRET_PASSWORD}
```

### File Permissions

```bash
# Set appropriate file permissions
chmod 600 ~/.config/mango/config.conf
chmod 700 ~/.config/mango/
chmod 755 ~/.config/zebar/

# Set directory permissions
chmod 755 ~/.config/
```

### Shell Integration

```bash
# Add configuration aliases to shell

# MangoWM configuration management
shopt attach () {
    echo "Reloading MangoWM configuration..."
    mango -c ~/.config/mango/config.conf -p && \
    pkill -HUP mango
}

# Zebar widget management
zebar-restart () {
    echo "Restarting Zebar..."
    pkill zebar
    /usr/bin/zebar startup
}

# Configuration backup
cbackup () {
    local backup_dir="~/.config/mango/backups"
    mkdir -p "$backup_dir"
    local backup_path="$backup_dir/config-$(date +%Y%m%d%H%M%S).conf"
    cp ~/.config/mango/config.conf "$backup_path"
    echo "Configuration backed up: $backup_path"
}

# Validate configuration
vconfig () {
    echo "Validating configuration..."
    if mango -c ~/.config/mango/config.conf -p; then
        echo "✅ Configuration is valid"
        return 0
    else
        echo "❌ Configuration has errors"
        return 1
    fi
}
```

## Configuration Documentation

### Configuration Documentation Template

```markdown
# Configuration Section

## Purpose
[Brief description of the section]

## Settings
| Setting | Description | Default | Example |
|---------|-------------|---------|---------|
| `keymode` | Keybinding mode | `default` | `common`, `default` |
| `layout` | Window layout | `scroller` | `scroller`, `master-stack` |
| `gaps` | Window gaps | `10` | `5`, `15` |

## Examples
### Example 1: Common Keybindings
```ini
keymode=common
bind=SUPER,R,reload_config
bind=SUPER+Q,killclient
bind=SUPER+M,quit
```

### Example 2: Default Layout
```ini
keymode=default
bind=SUPER,Return,spawn,foot
bind=SUPER,D,spawn,rofi -show drun
bind=SUPER,E,togglefloating
```

## References

- [MangoWM Documentation](https://mangowm.github.io/)
- [Zebar GitHub](https://github.com/zebar)
- [Wayland Documentation](https://wayland.freedesktop.org/)
- [Keyboard Shortcuts Guide](https://github.com/mangowm/mango/wiki/Keyboard-Shortcuts)
```
