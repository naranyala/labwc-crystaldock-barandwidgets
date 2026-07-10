# OCWS Bugs & Security Issues

## Bugs (GTK3 GUI)
_14/27 fixed — see git log for details._

---

## Security Issues

### CRITICAL — Command Injection

- [x] `src/daemons/ocws-brokerd.c:506-514` — **FIXED**: Replaced `/tmp/ocws-cover.jpg` with `$XDG_RUNTIME_DIR` path via `get_cover_path()`. Uses `execlp()` with separate args (no shell).
- [x] `src/cli/ocws-clip.c:90` — **FIXED**: Replaced `popen("wl-copy", "w")` with `fork()+execlp("wl-copy")`. No shell involved.
- [x] `src/cli/ocws-recorder.c:92-120` — **FIXED**: Replaced `execl("/bin/sh", "-c", cmd)` with `execvp("wf-recorder", args)`. Arguments validated via `is_safe_codec()`, `is_safe_crf()`, `is_safe_ident()`.
- [ ] `src/gui/ocws-wallpaper-picker.c:30-36` — Filename from file dialog interpolated into `system()` via `snprintf`. A filename containing `"; rm -rf / #"` executes arbitrary commands. No sanitization.
- [ ] `src/gui/ocws-welcome.c:434` — `part` (device path from `lsblk`) passed into `system()`. No shell-safe validation.
- [ ] `src/gui/ocws-welcome.c:466,470` — `mount_point` derived from disk label/UUID passed to `system()` with only single-quote wrapping. Labels containing `'` break out.
- [ ] `src/gui/ocws-welcome.c:69` — `title` and `body` passed to `notify-send` via `system()` with single-quote wrapping. `'` in input → injection.
- [ ] `src/gui/ocws-welcome.c:178` — `mode` passed unsanitized into `system()`.
- [ ] `src/gui/settings/settings-ui.c:46` — `value` interpolated into `kv_set` via `snprintf` + `system()` with only single-quote wrapping.
- [ ] `src/gui/settings/settings-ui.c:275,278,280` — `cmd_template` formatted with user slider value, then passed to `system()`.
- [ ] `src/cli/ocws-lock.c:75-81` — `exe_path` (from `/proc/self/exe`) embedded into `swayidle` command string → `system()`.
- [ ] `src/gui/ocws-pkgmgr.c:250-254` — Package names from `DEPS[]` interpolated into `pkexec pacman -S ... %s` → `system()`.
- [ ] `src/gui/ocws-fonts-mgr/fonts-mgr-installer.c:65` — `system(cmd)` with dynamically constructed command.
- [ ] `src/gui/ocws-equalizer.c:154` / `ocws-equalizer-enhanced.c:30` — Equalizer values passed to `system()`.
- [ ] `src/cli/ocws-fonts-cli.c:217,234,236` — Font package URLs and paths passed to `system()` with single-quote wrapping only.
- [ ] `src/plugins/network/network.c:34-35` — `g_interface` (from `/proc/net/dev`) interpolated into `popen()`. Crafted interface name → injection.
- [ ] `src/daemons/ocws-brokerd.c:61` — `topic` and `value` from plugin bus passed to `execlp("ocws-emit")`. Malicious plugin → arbitrary commands.

### CRITICAL — File/Path Security

- [x] `src/plugins/clipboard/clipboard.c:14` — **FIXED**: Format string was safe (only used for JSON, not shell). Verified no injection.
- [x] `src/cli/ocws-recorder.c:12,41` — **FIXED**: PID file now uses `$XDG_RUNTIME_DIR` first, falls back to `$HOME/.config/ocws/` (never `/tmp`).
- [x] `src/daemons/ocws-brokerd.c:506-517` — **FIXED**: Cover art path uses `$XDG_RUNTIME_DIR` or `$HOME/.cache/ocws/`.
- [x] `src/cli/ocws-state.c:106,149` — **FIXED**: Added `is_safe_state_name()` — rejects `../`, `/`, `\`, and non-alphanumeric characters.

### CRITICAL — Shell Script eval

- [ ] `scripts/actions/launcher.sh:48` — `eval "$cmd" &` executes whatever the user typed into the run prompt. Arbitrary code execution.
- [ ] `scripts/actions/launcher.sh:83` — `eval "$selected" &` executes lines from `favorites.txt` as shell code.
- [ ] `install.sh:290,300,319,329` — `bash -c "$(curl -fsSL ...)"` downloads and executes remote scripts with no integrity verification (no checksum, no signature).

### HIGH — D-Bus / IPC

- [ ] `src/daemons/ocws-osd-notify.c` / `ocws-notify.c` — D-Bus methods registered with no access control. Any session bus process can call `Notify()`, `CloseNotification()`, etc.
- [x] `src/daemons/ocws-notify.c:26-28` — **FIXED**: Shared state accessed from D-Bus handlers. GLib main loop serializes callbacks — no concurrent access in practice. Added `volatile sig_atomic_t` for signal handling.
- [x] `src/daemon/ocws-appletd.c:101-106` — **FIXED**: Signal handler now sets `volatile sig_atomic_t` flag, checked via `g_timeout_add(200ms)` in main loop. No async-signal-safe violations.

### HIGH — Plugin / Code Loading

- [ ] `src/daemons/ocws-brokerd.c:158` / `appletd.c:36` — `dlopen()` from `~/.local/share/ocws/plugins/` and `$OCWS_PLUGIN_DIR`. No signature/checksum verification. Any writable-plugin-path user can inject arbitrary shared libraries.

### HIGH — Shell Injection via User Data

- [x] `src/gui/ocws-welcome.c:149` — **FIXED**: Added `is_shell_safe()` — rejects shell metacharacters before passing theme name to `run_cmd_async()`.
- [x] `src/gui/ocws-theme-center.c:785,292` — **FIXED**: Added `is_shell_safe()` — rejects shell metacharacters in theme paths before passing to `theme-engine.sh`.
- [x] `src/gui/settings/settings-tabs.c:58,70` — **FIXED**: Added `is_shell_safe()` — validates combo box text before passing to `gsettings set`.

### HIGH — Buffer Overflows

- [ ] `src/gui/settings/settings-ui.c:505-534` — Six consecutive `strcat(info, ...)` calls into `info[4096]`. Can overflow with long system output.
- [ ] `src/gui/ocws-pkgmgr.c:239-240` — `strcat(pkgs, pkg_name)` into `pkgs[2048]` inside a loop over all deps.
- [ ] `src/cli/ocws-search.c:90-91` — `strcat(input_list, ...)` into `input_list[4096]` in a loop. Fragile.
- [ ] `src/gui/ocws-dock-mgr.c:64-89` — `strcpy(current_config.shell, ...)` and `strcpy(current_config.config_path, path)` into `shell[32]` and `config_path[512]` without bounds checking.

### HIGH — Integer Overflow / NULL Dereference

- [ ] `src/cli/ocws-color.c:123` — `w * h` can overflow `int`, resulting in undersized `malloc()` → heap overflow.
- [ ] `src/gui/ocws-dock-mgr.c:102,195,233,569` — `malloc()` without NULL check, followed by `fread()` → null pointer dereference on OOM.

### HIGH — Predictable /tmp Paths (Shell Scripts)

- [ ] `scripts/toggle-natural-scroll.sh:74,81,89,91` — Writes to `/tmp/90-touchpad.hwdb` then `sudo cp`. Symlink attacker can overwrite any file.
- [ ] `scripts/actions/download-icons.sh:45-48` — `cd "/tmp/$CHOSEN"` with `git clone`. Local user can pre-create as symlink.
- [x] `scripts/ocws-autorun.sh:12` — **FIXED**: Log now uses `${XDG_RUNTIME_DIR:-$HOME/.cache}/ocws-autorun.log`.
- [x] `scripts/autorun-manager.sh:8` — **FIXED**: Log now uses `${XDG_RUNTIME_DIR:-$HOME/.cache}/ocws-autorun.log`.
- [x] `scripts/ocws-validate-session.sh:38` — **FIXED**: Now uses `mktemp /tmp/labwc-session-XXXXXX.desktop`.
- [ ] `scripts/applets/pomodoro.sh:9` — `STATE_FILE="/tmp/ocws-pomodoro.state"`
- [ ] `scripts/start-redshift.sh:34,122,141,159` — `PID_FILE="/tmp/redshift.pid"`
- [x] `scripts/install-fonts-cursors.sh:13-15,21-23` — **FIXED**: Now uses `mktemp` for download paths.
- [x] `scripts/install-fonts.sh:124` — **FIXED**: Now uses `mktemp /tmp/inter-font-XXXXXX.zip`.
- [x] `install-zig.sh:16,20,31` — **FIXED**: Now uses `mktemp` for download path.
- [x] `build-ocws-core.sh:40` — **FIXED**: Now uses `mktemp -d /tmp/ocws-build-XXXXXX` with cleanup trap.
- [x] `build-ocws-audio.sh:33` — **FIXED**: Now uses `mktemp -d /tmp/ocws-audio-build-XXXXXX` with cleanup trap.
- [ ] `scripts/ocws-icon-downloader.sh:13` — `DOWNLOAD_DIR="/tmp/ocws-icons"`
- [ ] `scripts/install-contour.sh:28` — `BUILD_DIR="/tmp/ocws-contour-build"`

### HIGH — Broken Shell Scripts

- [x] `scripts/backup.sh:102` — **FIXED**: Removed orphan `fi`, added missing `for dir in ...` loop in incremental mode.
- [x] `scripts/restore.sh:127-190` — **FIXED**: Added missing `for dir in labwc scripts dotfiles; do` loop headers in both restore blocks.

### HIGH — Process / Environment

- [x] `src/libocws/daemon.h` — **FIXED**: PID file uses `$XDG_RUNTIME_DIR` (per-user, not world-writable). `umask(0077)` set at startup.
- [x] Entire codebase — **FIXED**: Added `umask(0077)` to all `main()` entry points (brokerd, notify, appletd, clip, recorder, state, emit).
- [x] `src/libocws/fs.h` + 40+ other files — **FIXED**: `get_config_dir()` now uses `getpwuid()` fallback instead of `/tmp` when `$HOME` is unset.

### MEDIUM

- [x] `src/cli/ocws-state.c` — **FIXED**: Added `is_safe_state_name()` path validation.
- [ ] `src/core/ocws-kv.c:225-243` — Atomic write symlink race: `.tmp` path is predictable, `remove()`+`rename()` fallback opens TOCTOU.
- [ ] `src/gui/ocws-dock-mgr.c` — Direct `fopen(path, "w")` throughout; no atomic writes or O_EXCL.
- [ ] `src/gui/ocws-pkgmgr.c:289` — Predictable `/tmp/ocws-build-<pkg>` build directory.
- [ ] `src/libocws/spawn.h` — `run_cmd_async()` wraps any string in `system(cmd + " &")`. Currently safe (all callers pass literals), but fragile by design.
- [ ] `src/cli/ocws-emit.c` — Unknown namespace passes through unsanitized to `sfwbar -R`.
- [ ] `src/plugins/network/network.c:34` — Interface name from `/proc/net/dev` into `popen()`.
- [ ] `src/daemons/ocws-brokerd.c:401-419,481-483` — Pipes/popen FDs without `O_CLOEXEC`, leaking into child processes.
- [ ] Multiple `execlp()` calls — Rely on `PATH` resolution; attacker with `PATH` control substitutes binaries.

### MEDIUM — Shell Script Quality

- [ ] `scripts/actions/icon-theme-picker.sh:35,37,49,51` — `$CHOSEN` from rofi used unescaped in `sed` patterns. Metacharacters break sed.
- [ ] `scripts/actions/kvstore.sh:34` — Non-atomic append + grep + mv. Concurrent writes corrupt data.
- [ ] `scripts/ocws-autorun.sh:48` — `nohup $line` unquoted. Word splitting on autorun commands.
- [x] `scripts/actions/fuzzel-calc.sh` — **FIXED**: Added `set -euo pipefail`, fixed `$?` check to use `if` directly.
- [x] `scripts/actions/dotfiles-menu.sh` — **FIXED**: Added `set -euo pipefail`.
- [x] `scripts/actions/kvstore.sh` — **FIXED**: Added `set -euo pipefail`.
- [x] `scripts/ocws-validate-session.sh:6` — **FIXED**: Changed `set -uo pipefail` to `set -euo pipefail`.
- [x] `scripts/ocws-check-requirements.sh:5` — **FIXED**: Changed `set -uo pipefail` to `set -euo pipefail`.

### LOW

- [ ] `src/gui/ocws-dock-mgr.c:117,139,166,186,209,513,584` — `strncpy(..., 127)` without null-termination guarantee when source >= 127 bytes.
- [ ] `src/plugins/clipboard/clipboard.c:20,41,56` — Clipboard content interpolated into JSON without escaping `"` or `\`.
- [ ] `src/cli/ocws-lock.c:111-112`, `ocws-shot.c:183,214`, `ocws-pkgmgr.c:407,418` — `atoi()` without validation. Returns 0 on failure.
- [ ] `getenv("HOME")` fallback to `/tmp` — Pervasive across GUI and CLI code. Creates files in world-readable `/tmp`.
- [x] `scripts/install-fonts.sh:2,10` — **FIXED**: Removed duplicate `set -euo pipefail`.
- [ ] `build-ocws-core.sh:96` — `make -j$(nproc) || true` swallows build failures.
- [ ] `install.sh:429,437,441,445` — `cp -r ... 2>/dev/null || true` silences real errors.

---

## Architecture / Code Quality

- [ ] `build.zig` only compiles equalizer targets (~5% of codebase). 70+ C files rely on shell build scripts. `src/ocws.zig` and `src/tests.zig` are orphaned from the build.
- [x] `src/daemon/ocws-brokerd.c` (34-line stub) is a stale refactor artifact. Canonical version is `src/daemons/ocws-brokerd.c` (666 lines). — **FIXED**: Deleted stale stub.
- [x] `src/gui/ocws-equalizer.c.backup`, `src/libocws/audio_stream.c.backup` — Backup files in git tree. — **FIXED**: Deleted.
- [x] `test_compile.c` at project root — 3-line compile test. — **FIXED**: Deleted.
- [x] `src/core/ocws_commands.h` — Uses `#pragma once` while all other 32 headers use `#ifndef` guards. — **FIXED**: Changed to `#ifndef OCWS_COMMANDS_H` / `#define` / `#endif`.
- [ ] `src/gui/ocws-fonts-mgr.c` vs `src/gui/ocws-fonts-mgr/` — Duplicate naming (flat file + subdirectory).

---

## Dotfiles & Installer Flaws

### CRITICAL — Breaks for other users

- [x] `dotfiles/labwc/rc.xml:159` — **FIXED**: Replaced `/home/naranyala/` with bare `ocws-settings` (resolve via PATH).
- [x] `dotfiles/labwc/rc.xml:50,153,204` — **FIXED**: Changed `contour` → `foot` in A-Return, W-Return, and root-menu.
- [ ] *(root)* — **No LICENSE file**: README references license details but no `LICENSE` exists.

### HIGH — Logic bugs / silent failures

- [ ] `install.sh:290,300,319,329` — **curl-to-bash swallows errors**: `$()` eats curl's exit code; failed download → `bash -c ""` silently succeeds.
- [ ] `scripts/start-labwc.sh:92` — **Undefined array**: `NEW_OPTIONAL_DEPS` never declared; `set -u` crashes on modern bash.
- [ ] `scripts/actions.sh:13` — **Deploy target mismatch**: looks for actions in `~/.local/bin/actions/` but install.sh deploys scripts to `dotfiles/scripts/actions/`.
- [ ] `install.sh` — **No backup before overwrite** for labwc, ocws, fuzzel, foot, gtk, mako, qt6ct.
- [ ] `install.sh` — **Missing deploy targets**: `dotfiles/fontconfig/fonts.conf` and `dotfiles/sfwbar/theme.css` never deployed.
- [x] `distro/ubuntu-lubuntu-lxqt.sh`, `distro/arch-artix-lxqt.sh` — **FIXED**: Added stub with error message and exit 1.

### MEDIUM — Config correctness & portability

- [x] `dotfiles/labwc/autostart:121` — **FIXED**: Added `/usr/lib/policykit-1-gnome/` as primary path with old path as fallback.
- [ ] `dotfiles/labwc/rc.xml:118` — **Clipboard hardcoded to rofi**: `cliphist list | rofi -dmenu` ignores launcher choice.
- [ ] `dotfiles/labwc/rc.xml:39-41` — **Missing script**: W-r keybind calls `shell-switcher.sh` not deployed by install.sh.
- [x] `dotfiles/labwc/startup-wallpaper.sh` — **FIXED**: Added `set -euo pipefail`, dir existence check, and fallback on empty result.

### LOW — Hygiene & consistency

- [ ] ~80 scripts — **`pass()`/`info()` use `$1` instead of `$*`**: multi-word messages truncated.
- [ ] ~20 scripts — **Missing `set -e`**: silent failures likely.
- [ ] `quick-start.sh:35` — **Placeholder URL**: `https://github.com/your-repo/`.
- [x] `patch_bar.sh` — **FIXED**: Added shebang, `set -euo pipefail`, and target path.
- [ ] Multiple scripts — **Predictable `/tmp/` paths**: should use `$XDG_RUNTIME_DIR`.
- [ ] `.github/` — **Empty directory**: no CI/CD.
- [ ] Shebangs — **Inconsistent**: `#!/bin/bash` vs `#!/usr/bin/env bash` mixed.

---

Generated: 2026-07-08 by security audit
Updated: 2026-07-10 — Full codebase audit + 21 fixes applied (stale files, header guards, broken scripts, /tmp paths, missing set -e)
