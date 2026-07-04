# OCWS: Our C-Written Shell

A batteries-included Wayland desktop shell built on sfwbar, inspired by DankMaterialShell and Noctalia.

## Architecture

### Design Principles

1. **C-written only**: All helpers written in C, no Go/QML/Python
2. **sfwbar as foundation**: Use sfwbar's GTK3 widget system for all shell surfaces
3. **Wayland-native**: Leverage sfwbar's wlr-layer-shell integration
4. **Modular widgets**: Each feature is a self-contained .widget file
5. **Theme-engine integrated**: All colors from INI profiles via template engine

### What sfwbar Provides Natively

| Feature | sfwbar Widget/Module |
|---------|---------------------|
| Top panel | bar "topbar:top" |
| Bottom panel | bar "bottombar:bottom" |
| Taskbar | taskbar { } |
| Workspace pager | pager { } |
| System tray | tray { } |
| Launcher | launcher.widget (fuzzel scanner) |
| Clock | clock.widget (Exec scanner) |
| Network status | network module |
| Bluetooth status | bluez module |
| Audio volume | pulsectl/pipewire module |
| Battery | battery.source (File scanner) |
| CPU/Memory | cpu.source, memory.source (Exec scanner) |
| Media player | mpd module or media-player.widget (playerctl) |
| Popups | PopUp("name") { } |

### What Needs C Helpers

| Feature | Helper | Purpose |
|---------|--------|---------|
| Lock screen | labwc-lock | Wrapper for swaylock/swayidle |
| Clipboard history | labwc-clip | cliphist integration |
| Screenshot tool | labwc-shot | grim+slurp+satty integration |
| Color picker | labwc-color | Wayland color picker |
| Window menu | labwc-winops | Window operations menu |

### Shell Surfaces

```
+------------------------------------------------------------------+
| TOP BAR                                                          |
| [launcher] [workspaces] [clock] [spacer] [media] [tray] [net] [bt] [vol] [bat] [session] |
+------------------------------------------------------------------+

+------------------------------------------------------------------+
| BOTTOM BAR (optional)                                            |
| [launcher] [showdesktop] [taskbar.............] [tray] [clock]  |
+------------------------------------------------------------------+

Popups (triggered from bar widgets):
  - Control Center: network, bluetooth, audio, brightness, nightlight
  - Notification Center: notification history + do-not-disturb
  - Clipboard History: recent clipboard entries
  - Calendar: month view with agenda
  - System Monitor: CPU, memory, disk, temperature
  - Session Menu: lock, logout, reboot, shutdown, suspend
  - Media Player: MPRIS controls with album art
```

### File Structure

```
shell/
|-- shell.config              # Main sfwbar config (dual-bar)
|-- shell-top.config          # Top bar only config
|-- shell-full.config         # Full-featured single bar
|
|-- widgets/
|   |-- launcher.widget       # App launcher (fuzzel)
|   |-- workspaces.widget     # Workspace pager
|   |-- clock.widget          # Clock with calendar popup
|   |-- media-player.widget   # MPRIS media controls
|   |-- tray.widget           # System tray
|   |-- network.widget        # Network status + control center
|   |-- bluetooth.widget      # Bluetooth status + toggle
|   |-- volume.widget         # Volume control + slider
|   |-- brightness.widget     # Brightness control + slider
|   |-- battery.widget        # Battery status + details
|   |-- session.widget        # Session menu (lock/logout/power)
|   |-- clipboard.widget      # Clipboard history
|   |-- notifications.widget  # Notification center
|   |-- sysmon.widget         # System monitor (CPU/RAM/disk)
|   |-- weather.widget        # Weather display
|   |-- showdesktop.widget    # Show desktop toggle
|   `-- quick-settings.widget # Quick settings panel
|
|-- sources/
|   |-- cpu.source            # CPU usage scanner
|   |-- memory.source         # Memory usage scanner
|   |-- battery.source        # Battery status scanner
|   |-- temperature.source    # Temperature scanner
|   `-- disk.source           # Disk usage scanner
|
|-- css/
|   |-- catppuccin-mocha.css  # Default theme
|   |-- nord.css              # Nord theme
|   `-- tokyo-night.css       # Tokyo Night theme
|
|-- scripts/
|   |-- shell-launch.sh       # Launch shell (start all components)
|   |-- shell-restart.sh      # Restart shell
|   `-- shell-status.sh       # Shell status
|
`-- helpers/
    |-- labwc-lock.c          # Lock screen helper
    |-- labwc-clip.c          # Clipboard history helper
    `-- labwc-shot.c          # Screenshot helper
```

## Comparison with Reference Projects

| Feature | DankMaterialShell | Noctalia | OCWS |
|---------|------------------|----------|------|
| Framework | Quickshell (QML) | Custom C++23+OpenGL | sfwbar (GTK3) |
| Language | QML + Go | C++23 | C + shell scripts |
| Config format | QML props | TOML | sfwbar config + INI |
| Theme system | matugen (wallpaper) | TOML palette | INI theme engine |
| Bar widgets | QML components | C++ widgets | sfwbar widgets |
| Taskbar | Yes | Yes | Yes (built-in) |
| Pager | Yes | Yes | Yes (built-in) |
| Tray | Yes | Yes | Yes (built-in) |
| Launcher | Custom | Custom | fuzzel (external) |
| Notifications | Custom | Custom | sfwbar ncenter module |
| Lock screen | Custom | Custom | swaylock (external) |
| Control center | Custom | Custom | sfwbar popup |
| Clipboard | Custom | Custom | cliphist+fuzzel |
| Screenshot | Custom | Custom | grim+slurp+satty |
| System monitor | Custom | Custom | sfwbar chart/scale |
| OSD | Custom | Custom | sfwbar popup |
| Multi-monitor | Yes | Yes | Yes (sfwbar mirror) |
| Plugin system | Yes | Yes | Widget files (modular) |
| Dependencies | Quickshell, Go | OpenGL, EGL, many | GTK3, sfwbar |
