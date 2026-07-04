# OCWS: Our C-Written Shell

A batteries-included Wayland desktop shell built on sfwbar, written in C.

---

## Philosophy

OCWS exists because the Wayland desktop shell space is fragmented. Every compositor ships a different bar, a different launcher, a different notification daemon, and a different lock screen. Users stitch together 6-10 unrelated tools, each with its own config format, its own theme system, and its own update cycle. The result is fragile, inconsistent, and hard to maintain.

OCWS takes a different approach: one shell, one language, one config system, one theme engine. Everything is C. Everything is sfwbar. Everything uses the same INI-based theme profiles. The shell is not a collection of unrelated panels -- it is a single cohesive layer that wraps around the compositor.

---

## Core Principles

### 1. C-Written Only

OCWS is written in C. Not C++. Not Go. Not QML. Not Python. Not Rust.

C is the language of the Linux desktop. The kernel is C. X11 is C. Wayland is C. GTK is C. sfwbar is C. labwc is C. When you write your shell in C, you speak the same language as the rest of the stack. There are no FFI boundaries, no runtime interpreters, no garbage collectors, no build-time code generators. Just C compiled to native code.

This is not a limitation. It is a feature. C code is predictable. It has no hidden costs. It starts fast, runs fast, and stops fast. A C shell does what it says and nothing more.

### 2. sfwbar as Foundation

OCWS does not reinvent the bar. sfwbar already handles bars, taskbar, pager, tray, and widgets. It is written in C, uses GTK3 layer-shell, and has a proven widget system. OCWS builds on top of sfwbar rather than replacing it.

This means OCWS inherits sfwbar's strengths:
- Multi-monitor support via mirror
- Layer-shell integration (panels float above windows)
- Built-in taskbar with window management
- Built-in pager with workspace switching
- Built-in system tray
- Scanner system for custom data sources
- CSS styling for all surfaces

And OCWS adds what sfwbar does not provide:
- Control center (volume, brightness, network, bluetooth)
- Notification center
- Clipboard history
- System monitor
- Session menu
- Weather display
- Calendar popup

### 3. One Config System

OCWS uses sfwbar's native config format. No TOML. No YAML. No JSON. No custom DSL. Just sfwbar config with widget files.

Each widget is a self-contained .widget file with its own CSS section. Widgets are included in the main config via `widget "file.widget"` or `include("file.widget")`. This is the same pattern sfwbar uses internally -- OCWS simply extends it to cover the full shell.

### 4. One Theme Engine

OCWS uses the same INI-based theme engine as the rest of the dotfiles. A single INI profile defines colors for sfwbar, fuzzel, labwc, GTK, foot, rofi, mako, and Qt. The theme engine renders templates into config files. Change one INI file, and the entire desktop changes color.

This is how DankMaterialShell does it with matugen. This is how Noctalia does it with TOML palettes. OCWS does it with INI profiles and a shell script.

### 5. Modular by Design

Every OCWS feature is a .widget file. Want notifications? Add notifications.widget. Don't want weather? Remove weather.widget. Want a different layout? Edit shell.config.

The widget system is the plugin system. No API to learn. No ABI to maintain. No registration to manage. Just files.

---

## What OCWS Replaces

| Traditional Tool | OCWS Replacement | How |
|-----------------|------------------|-----|
| waybar / polybar | sfwbar (built-in) | bar + taskbar + pager + tray |
| rofi / wofi / fuzzel | fuzzel (external) | launcher.widget calls fuzzel |
| mako / dunst | sfwbar ncenter | notifications.widget |
| swaylock / swayidle | swaylock (external) | session.widget calls loginctl |
| clipman / cliphist | cliphist (external) | clipboard.widget calls cliphist |
| grim / slurp / flameshot | grim+slurp+satty | screenshot helper |
| brightnessctl GUI | sfwbar scale widget | brightness.widget |
| pavucontrol | sfwbar scale widget | volume.widget |
| nm-applet | sfwbar network module | network.widget |
| blueman-applet | sfwbar bluez module | bluetooth.widget |
| power menu scripts | sfwbar popup | session.widget |

---

## What OCWS Does Not Replace

OCWS is a shell, not a desktop environment. It provides the visual and service layer around the compositor. It does not manage:

- Window management (that is the compositor's job)
- File management (use thunar, nautilus, or pcmanfm)
- Package management (use apt, dnf, or pacman)
- System monitoring (use htop or btop, or use sysmon.widget)
- Display management (use wlr-randr or nwg-displays)
- Audio routing (use pavucontrol or the volume widget)

---

## Comparison with Alternatives

| | DankMaterialShell | Noctalia | OCWS |
|--|------------------|----------|------|
| **Language** | QML + Go | C++23 | C |
| **Rendering** | Qt Quick | OpenGL ES | GTK3 |
| **Dependencies** | Quickshell, Go, Qt | OpenGL, EGL, many | GTK3, sfwbar |
| **Config** | QML props | TOML | sfwbar config |
| **Theme** | matugen (wallpaper) | TOML palette | INI profiles |
| **Build time** | Minutes (Go) | Minutes (C++23) | Seconds (C) |
| **Binary size** | ~10MB (Go) | ~2MB (C++23) | ~0 (sfwbar) |
| **Memory** | ~80MB (Qt) | ~40MB (OpenGL) | ~15MB (GTK3) |
| **Startup** | ~2s (Go runtime) | ~1s (init) | ~0.3s (GTK) |
| **Plugin system** | Go plugins | C++ plugins | Widget files |
| **Compositor support** | niri, hypr, sway, labwc | All layer-shell | All layer-shell |
| **IPC** | Custom (Go) | Custom (C++) | sfwbar Exec |
| **Multi-monitor** | Yes | Yes | Yes (mirror) |

---

## Design

### Shell Surfaces

```
+==================================================================+
| OCWS TOP BAR                                                      |
|                                                                    |
| [launcher] [workspaces] [clock] [spacer] [media] [tray] [net] [bt] [vol] [bat] [session] |
|                                                                    |
+==================================================================+

+==================================================================+
| OCWS BOTTOM BAR (optional)                                        |
|                                                                    |
| [launcher] [showdesktop] [taskbar.............] [tray] [clock]  |
|                                                                    |
+==================================================================+
```

### Popup Surfaces

All popups are triggered from bar widgets and rendered as sfwbar PopUp panels:

```
Control Center (from network/volume/brightness widgets):
+----------------------------------+
| Control Center                   |
|                                  |
| WiFi: [====------] 60%          |
| Bluetooth: [On/Off]             |
| Volume: [========--] 80%        |
| Brightness: [======----] 60%    |
| Night Light: [On/Off]           |
|                                  |
+----------------------------------+

Session Menu (from session widget):
+----------------------------------+
| Session                          |
|                                  |
| [Lock Screen]                    |
| [Logout]                         |
| [Reboot]                         |
| [Shutdown]                       |
| [Suspend]                        |
|                                  |
+----------------------------------+

System Monitor (from sysmon widget):
+----------------------------------+
| System Monitor                   |
|                                  |
| CPU: [========------] 45%        |
| RAM: [======--------] 35%        |
|                                  |
+----------------------------------+
```

### Widget Architecture

Each widget is a self-contained file with three sections:

```
#Api2                    <- sfwbar API version

Exec("command")          <- Data source (scanner)
ExportTest("module")     <- Optional module test

export button "name" {   <- Bar widget
  style = "module"
  value = "icon-symbolic"
  action = PopUp("Popup")
}

PopUp("Name") {          <- Popup panel
  style = "detail_popup"
  grid { ... }
}

#CSS                     <- Widget-specific styles
button.module { ... }
```

---

## File Structure

```
ocws/
|-- OCWS.md                    # This file
|-- ocws.config                # Main config (dual-bar)
|
|-- widgets/
|   |-- launcher.widget        # fuzzel app launcher
|   |-- workspaces.widget      # workspace pager popup
|   |-- clock.widget           # clock + calendar popup
|   |-- media-player.widget    # MPRIS controls
|   |-- tray.widget            # system tray
|   |-- network.widget         # network + control center
|   |-- bluetooth.widget       # bluetooth + toggle
|   |-- volume.widget          # volume + slider popup
|   |-- brightness.widget      # brightness + slider popup
|   |-- battery.widget         # battery + power profiles
|   |-- session.widget         # lock/logout/power menu
|   |-- clipboard.widget       # clipboard history
|   |-- notifications.widget   # notification center
|   |-- sysmon.widget          # CPU/RAM monitor
|   |-- showdesktop.widget     # show desktop toggle
|   `-- weather.widget         # weather display
|
|-- sources/
|   |-- cpu.source             # CPU usage scanner
|   |-- memory.source          # memory usage scanner
|   |-- battery.source         # battery status scanner
|   |-- temperature.source     # temperature scanner
|   `-- disk.source            # disk usage scanner
|
|-- css/
|   `-- catppuccin-mocha.css   # default theme
|
|-- scripts/
|   |-- ocws-launch.sh         # launch shell
|   |-- ocws-restart.sh        # restart shell
|   `-- ocws-status.sh         # shell status
|
`-- helpers/
    |-- ocws-lock.c            # lock screen helper (C)
    |-- ocws-clip.c            # clipboard helper (C)
    `-- ocws-shot.c            # screenshot helper (C)
```

---

## Naming

**OCWS** -- Our C-Written Shell.

The name says everything:
- **Our** -- it belongs to us, not to a corporation or a foundation
- **C-Written** -- the implementation language, not C++, not Go, not QML
- **Shell** -- it is the desktop shell, the layer between the compositor and the user

Not "desktop environment." Not "window manager." Shell. The thing that makes a compositor feel like a home.

---

## Status

Phase 1 (Current): Widget-based shell using sfwbar
- All shell surfaces as .widget files
- Launch/restart/status scripts
- Theme-engine integration
- Dual-bar layout (top + bottom)

Phase 2 (Future): C helper programs
- ocws-lock.c -- lock screen wrapper
- ocws-clip.c -- clipboard history
- ocws-shot.c -- screenshot tool

Phase 3 (Future): Advanced features
- Wallpaper integration
- OSD overlays
- Desktop widgets
- Plugin API via widget files
