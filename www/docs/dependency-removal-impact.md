# Dependency Removal Impact Analysis

What each component provides and what breaks if removed.

## dankmaterialshell (dms)

### Runtime — what breaks immediately
- `toggle-shell dms` fails — shell switching dead
- Shell-mode rofi picker loses the DMS entry
- `reload-shell-mode.sh` defaults to `dms` if no mode file exists → dead fallback
- `autostart` has fallback `dms run` entry → tries to launch missing binary
- `autorun-manager.sh` has `daemon:dms run` default entry
- `shell-switcher.sh` defaults to `MODE="dms"`

### OCWS tools (C source)
- `ocws-dock-mgr.c` — DMS JSON parser for pinned apps; removing it means the Dock Manager can't read/write DMS-format configs
- `ocws-welcome.c` — references DMS in the welcome splash
- `settings/settings-tabs.c` — settings card for DMS
- `ocws-pkgmgr.c` — package listing entry for DMS
- `core/utils.c` — shell-name mapping includes `"DankMaterialShell" -> "dms"`

### Config shipped (safe to delete)
- `dotfiles/DankMaterialShell/settings.json` (578 lines)
- `dotfiles/DankMaterialShell/firefox.css` (Material 3 Firefox theme)
- `dotfiles/DankMaterialShell/.firstlaunch`
- `dotfiles/DankMaterialShell/.changelog-1.4`

### Backup scripts
- `scripts/actions/dock-pin-backup.sh` — has DMS-specific backup/restore paths
- `scripts/actions/dock-backup.sh` — handles DMS `session.json` format

---

## noctalia

### ⚠️ Currently live on this system
`/home/naranyala/.config/labwc-widgets/shell-mode` contains `noctalia`. Removing it breaks the current session.

### Runtime — what breaks immediately
- `labwc-shell-wrapper` defaults to `noctalia` as primary shell — wrapper fails
- `toggle-shell noctalia` fails
- `shell-mode-picker.sh` defaults to `echo noctalia` → dead default
- `scripts/actions/maintenance.sh` tries to restart noctalia if running
- `scripts/actions/shell-mode.sh` lists `noctalia` as valid mode

### OCWS tools
- `ocws-dock-mgr.c` — TOML parser for noctalia pinned apps
- `ocws-welcome.c`, `settings/settings-tabs.c`, `core/utils.c` — references (same pattern as DMS)

### rc.xml (live config)
- `<application class="noctalia">` with `skip_taskbar`, `skip_pager` — harmless dead rule
- Present in all rc.xml copies (working, backup, historic backups)

### Config shipped
- `dotfiles/noctalia/config.toml` (473 lines) — full noctalia config
- `/home/naranyala/.config/noctalia/config.toml` — live active config
- `/home/naranyala/.config/sfwbar/noctalia.css` (433 lines) — **SFWBar theme only, no binary dependency**
- `/home/naranyala/.config/sfwbar/sfwbar-noctalia.config` — **SFWBar layout only, no binary dependency**
- `/home/naranyala/build/noctalia-src/` — source tree (already compiled)

### Desktop entry
- `/home/naranyala/build/noctalia-src/assets/dev.noctalia.Noctalia.desktop`

---

## crystal-dock

### Runtime — what breaks immediately
- Shell modes `crystal` and `both` break in `labwc-shell-wrapper` and `toggle-shell`
- `shell-mode-picker.sh` loses the "SFWBar + Crystal Dock" option
- `/home/naranyala/.config/autostart/crystal-dock.desktop` launches missing binary
- `scripts/actions/maintenance.sh` tries to restart crystal-dock
- `compose-fixes.sh` fails — tries to fix crystal-dock `appearance.conf`

### rc.xml + menu (live config)
- `<application class="crystal-dock">` — skip_taskbar/skip_pager rule
- Menu entry `Launch Crystal Dock` in `menu.xml`
- Present in all presets (`default.xml`, `super.xml`)

### shutdown
- `pkill crystal-dock` in `~/.config/labwc/shutdown` — harmless no-op

### OCWS tools
- `ocws-dock-mgr.c` — crystal-dock config parser (semicolon-delimited launcher format)
- `ocws-welcome.c`, `ocws-pkgmgr.c` — references

### Integrations
- `scripts/actions/icon-theme-picker.sh` — applies icon theme to crystal-dock + restarts it
- `scripts/ocws-icon-picker.sh` — primary shell integration is crystal-dock (partially breaks)

### Config shipped (safe to delete)
- `dotfiles/crystal-dock/panel_1.conf` (16 lines)
- `dotfiles/crystal-dock/appearance.conf` (32 lines)

---

## Shared cleanup required for any removal

All three components share the shell-mode infrastructure. Removing any one requires editing all of these files to prune it:

| File | What to change |
|---|---|
| `scripts/toggle-shell` | Remove mode from validation, kill/start cases |
| `scripts/shell-mode-picker.sh` | Remove picker option |
| `scripts/actions/shell-mode.sh` | Remove from mode validation |
| `scripts/actions/shell-mode-picker.sh` | Remove from picker and fallback |
| `scripts/actions/reload-shell-mode.sh` | Update default fallback |
| `scripts/labwc-shell-wrapper` | Remove from mode selection and launch logic |
| `scripts/actions/maintenance.sh` | Remove restart block |
| `src/gui/ocws-dock-mgr.c` | Remove the per-shell parser and auto-detection |
| `src/core/utils.c` | Remove shell-name mapping entry |
| `src/gui/ocws-welcome.c` | Remove from welcome text |
| `src/gui/settings/settings-tabs.c` | Remove settings card |
| `src/gui/ocws-pkgmgr.c` | Remove from package listing |

And for specific components:

| Component | Additional files |
|---|---|
| **dankmaterialshell** | `scripts/actions/dock-pin-backup.sh`, `scripts/actions/dock-backup.sh`, `install.sh` mode 3 |
| **noctalia** | `scripts/actions/dock-pin-backup.sh`, `scripts/actions/dock-backup.sh`, `install.sh` mode 4, `shell-switcher.sh` |
| **crystal-dock** | `scripts/actions/dock-pin-backup.sh`, `scripts/ocws-icon-picker.sh`, `scripts/actions/icon-theme-picker.sh`, `compose-fixes.sh`, `install.sh` mode 2, `~/.config/autostart/crystal-dock.desktop` |
