# Getting Started with MangoWM and Zebar

## Overview

This guide provides comprehensive setup instructions for MangoWM and Zebar widget integration, with crystal-dock as the primary dock.

## Prerequisites

- Wayland compositor (MangoWM)
- Zebar widget framework
- crystal-dock installation (/usr/bin/crystal-dock)
- Wayland terminal (foot)
- Application launcher (rofi)

## Installation

### Step 1: Automated Installation

Run the enhanced installation script:

```bash
./dotfiles/install.sh
```

This script will:
- Create necessary configuration directories
- Symlink MangoWM configuration to ~/.config/mango/config.conf
- Set up Zebar widget system
- Configure crystal-dock integration
- Validate all configurations

### Step 2: Manual Configuration

If you prefer manual setup, create the following directories:

```bash
mkdir -p ~/.config/mango
mkdir -p ~/.config/zebar/main
```

### Step 3: Apply Configurations

Copy the configuration files:

```bash
cp dotfiles/mango/config.conf ~/.config/mango/config.conf
cp -r dotfiles/zebar/main ~/.config/zebar/
```

## Configuration Details

### MangoWM Configuration

The MangoWM configuration includes:

- **Primary Dock**: crystal-dock (`exec-once=/usr/bin/crystal-dock --start --overlay`)
- **Terminal**: foot (`bind=SUPER,Return,spawn,foot`)
- **Launcher**: rofi (`bind=SUPER,D,spawn,rofi -show drun`)
- **Window Management**: Full keyboard navigation support
- **Media Controls**: Volume and playback controls

### Zebar Widget System

The Zebar widget system includes:

- **Main Widget**: Classic status bar with clock, CPU, memory, network, battery
- **Additional Widgets**: Minimalist, compact, detailed, system monitoring
- **Responsive Design**: Optimized for different screen sizes
- **Real-time Updates**: Live system statistics

## Quick Start

1. **Install dotfiles** (`./dotfiles/install.sh`)
2. **Restart MangoWM** or reload configuration
3. **Launch crystal-dock** as primary dock
4. **Start Zebar widgets** for additional functionality

## Configuration Validation

Validate your setup with:

```bash
mango -p  # Test MangoWM configuration syntax
./dotfiles/install.sh --validate  # Validate all configurations
```

## Troubleshooting

Common issues and solutions:

### MangoWM Won't Start
```bash
# Check configuration syntax
mango -p

# View logs
journalctl -u mango
```

### Zebar Widgets Not Displaying
```bash
# Check Zebar installation
/usr/bin/zebar --help

# Verify widget paths
ls ~/.config/zebar/main/
```

### crystal-dock Issues
```bash
# Start crystal-dock manually
/usr/bin/crystal-dock --start --overlay

# Check crystal-dock status
pgrep crystal-dock
```

## Advanced Configuration

### Custom Keybindings

Edit `~/.config/mango/config.conf` and add:

```ini
bind=SUPER,F12,reload_config
bind=SUPER+F11,toggleoverview
```

### Additional Widgets

Launch additional Zebar widgets:

```bash
./dotfiles/zebar/launcher.sh minimalist left
./dotfiles/zebar/launcher.sh system center
```

### Widget Customization

Customize widget appearance in:
- `~/.config/zebar/main/style.css` - Main styles
- `~/.config/zebar/widgets/*/style.css` - Widget-specific styles

## Support

For support, visit:
- [MangoWM Documentation](https://mangowm.github.io/)
- [Zebar GitHub](https://github.com/zebar)
- [crystal-dock Documentation](https://github.com/crystal-project/crystal-dock)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. Document your changes

## License

This configuration is provided under the terms specified in the LICENSE file.

---

*Last Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')*
*Version: $(git describe --tags --abbrev=0 2>/dev/null || echo 'dev')*
