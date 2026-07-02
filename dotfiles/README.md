# Dotfiles for MangoWM and Zebar

This repository contains a starter configuration for `mangowm` (a Wayland compositor) and `zebar` (a taskbar/widget tool).

## Structure

- `dotfiles/mango/`: Configuration for MangoWM.
- `dotfiles/zebar/`: Widget files for Zebar.
- `dotfiles/install.sh`: Script to symlink configurations to `~/.config`.

## Installation

Run the following command to install the dotfiles:

```bash
./dotfiles/install.sh
```

## Configuration

### MangoWM

The MangoWM configuration is located at `dotfiles/mango/config.conf`. It uses an INI-like format.

Keybindings:
- `SUPER+Q`: Kill focused client
- `SUPER+Return`: Spawn terminal (foot)
- `SUPER+D`: Spawn launcher (rofi)
- `SUPER+R`: Reload config
- `SUPER+M`: Quit MangoWM

### Zebar

The Zebar widget is located at `dotfiles/zebar/main/`. It uses standard HTML, CSS, and JavaScript.

To add more widgets, create a new directory in `dotfiles/zebar/` and update your `exec-once` in `mango/config.conf` to include `zebar start-widget <name>`.
