# OCWS Configuration Reference

This document serves as the complete reference for configuring and extending the OCWS (Our C-Written Shell) Wayland platform.

---

## The OCWS Event Bus

OCWS operates on a strict IPC (Inter-Process Communication) event bus. Background scripts and system events communicate with the UI exclusively through the `ocws-emit` command.

### Standard Namespaces
You can inject state changes into the shell from any terminal or bash script:

```bash
# Audio Subsystem
ocws-emit System.Volume 75
ocws-emit System.VolumeMuted 0

# Display Subsystem
ocws-emit System.Brightness 100

# Power Subsystem
ocws-emit System.Battery 80
ocws-emit System.BatteryState "Charging"

# Hardware Subsystems
ocws-emit System.Cpu 15
ocws-emit System.Memory 45
ocws-emit System.Disk 60

# Media Subsystem
ocws-emit Media.Title "Song Name"
ocws-emit Media.Artist "Artist Name"
ocws-emit Media.Status "Playing"

# Network Subsystem
ocws-emit Network.WiFi "Connected"
ocws-emit Network.Bluetooth "Disconnected"

# Notification Subsystem
ocws-emit System.DND 1  # Enable Do Not Disturb
```

If you are developing a custom module (e.g., a Spotify listener), you do not need to learn sfwbar. You simply loop and call `ocws-emit Media.Title "..."`.

---

## The Plugin Autoloader

OCWS supports a drag-and-drop extension model without requiring manual edits to the core layout file.

### Adding a Plugin
1. Create a widget file, for example, `my-weather.widget`.
2. Place it in `~/.config/ocws/plugins/`.
3. Reload the shell (or let it load naturally on next boot).

The `ocws-plugin-loader` script runs dynamically at startup, scanning the `plugins/` directory and auto-generating the `plugins.config` manifest which is securely injected into the main `ocws.config`.

---

## Visual Configuration (Glassmorphism)

OCWS uses standard GTK3 CSS to render its heavily translucent aesthetics.

### Modifying the Glass Engine
The primary styling tokens are located inside `~/.config/ocws/ocws.config` in the `#CSS` block.

To adjust the translucency or blur:
1. Open `~/.config/ocws/ocws.config`.
2. Locate `window#sfwbar`.
3. Adjust `background-color: rgba(30, 30, 46, 0.65);` to change panel opacity.
4. Adjust `box-shadow` to alter the depth perception.

---

## Window Management (labwc)

Window management, keybindings, and compositor rules are handled by `labwc` in `~/.config/labwc/rc.xml`.

### Essential Keybindings

| Keybinding | Action |
|------------|--------|
| Super + Enter | Launch terminal (foot) |
| Super + D | Launch application menu (fuzzel) |
| Super + Q | Close focused window |
| Super + V | Open clipboard history |
| Super + F | Toggle fullscreen |
| Super + 1-9 | Switch to workspace 1-9 |
| Super + Shift + 1-9 | Move window to workspace 1-9 |
| Alt + Tab | Cycle through active windows |

### System Keybindings

| Keybinding | Action |
|------------|--------|
| Volume Up/Down | Adjust volume (triggers ocws-emit) |
| Mute Key | Toggle mute |
| Brightness Up/Down | Adjust screen backlight |
| Print Screen | Capture area screenshot |
| Super + Print Screen | Capture full screenshot |

### Window Rules

OCWS automatically excludes itself from the taskbar and pager using labwc rules:
```xml
<applications>
  <application class="sfwbar">
    <skip_taskbar>yes</skip_taskbar>
    <skip_pager>yes</skip_pager>
  </application>
</applications>
```
Do not remove this rule, or the OCWS UI panels will behave like standard movable windows.
