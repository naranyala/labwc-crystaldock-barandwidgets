# OCWS Ecosystem Integration: Fuzzel $\leftrightarrow$ SFWBAR

This document outlines the roadmap for transforming `fuzzel` and `sfwbar` from independent tools into a unified, cohesive desktop shell experience.

## 🎯 The Goal
To achieve "Visual and Functional Fluidity": The launcher should feel like an extension of the bar, sharing its colors, shapes, and intelligence.

---

## 🟦 Phase 1: Visual Unity (The "Look")
*Goal: Eliminate the "uncanny valley" where two tools feel slightly different.*

- [ ] **Theme Synchronization Patch**
    - [ ] Implement a listener in `fuzzel` that reacts to `ocws` theme changes (Accent color, Background transparency).
    - [ ] Patch `fuzzel` to use `sfwbar`-compatible CSS variables (e.g., `--accent-color`, `--border-radius`).
- [ ] **Motion Sync**
    - [ ] Match the `cubic-bezier` transition curves in `fuzzel`'s window appearance/disappearance with `sfwbar`'s animations.
- [ ] **Shape Matching**
    - [ ] Ensure the `border-radius` of the `fuzzel` window matches the "Pill" aesthetic of the `sfwbar` panels.

## 🚀 Phase 2: Interactive Flow (The "Feel")
*Goal: Allow the bar to control the launcher and vice versa.*

- [ ] **The "Search Trigger" Bridge**
    - [ ] Create an `sfwbar` widget (e.g., a search icon/bar) that invokes `fuzzel` with a pre-filled query via `--search`.
- [ ] **Contextual Focus**
    - [ ] When `fuzzel` is active, `sfwbar` should dim or "recede" (lower opacity) to emphasize the launcher.
    - [ ] When `fuzzel` loses focus, `sfwbar` should "pop" back to full prominence.
- [ ] **Taskbar Handshake**
    - [ ] Ensure that selecting an app in `fuzzel` triggers the immediate appearance/highlighting of the corresponding icon in the `sfwbar` taskbar via the `ocws` state.

## 🧠 Phase 3: Semantic Intelligence (The "Brain")
*Goal: Use the shared `ocws` state to make the launcher "smart".*

- [ ] **The "Pinned & Recent" Injection**
    - [ ] Implement the `ocws_bridge` in `fuzzel` to inject `ocws`-managed "Pinned Apps" and "Recent Applications" into the top of the search results.
- [ ] **Workspace-Aware Search**
    - [ ] Allow `fuzzel` to show workspace-specific commands/apps (e.g., if on Workspace 2, show apps primarily used there) by querying `ocws` workspace state.
- [ ] **The "Dynamic Island" Mode**
    - [ ] [ADVANCED] Develop a mode where `fuzzel` doesn's appear as a centered window, but as a floating "pill" that physically expands from the `sfwbar` search widget.

---

## 🛠️ Development Strategy
- **Methodology:** Always use the `patches/` and `new_files/` workflow.
- **Testing:** Every patch must be validated by the `tests/chaos/` suite to ensure shell stability.
- **Golden Rule:** If a feature can be achieved via a simple `sfwbar` config change or a `fuzzel` flag, **do not** write a C patch. (YAGNI)

## 🧪 Specific C-Patches to Develop (The Roadmap)

### Fuzzel Patches
- [x] **fuzzel-01-grid-layout.patch**: `render.c` & `config.c` - Implemented the `grid-columns` config primitive for a macOS Launchpad style grid.
- [ ] **fuzzel-02-grid-navigation.patch**: `key-binding.c` - Rewrite up/down/left/right arrow key logic to move through the 2D grid instead of a 1D vertical list.
- [ ] **fuzzel-03-sfwbar-ipc.patch**: `main.c` - Implement a lightweight unix socket that broadcasts `FuzzelSelectionChanged` events. `sfwbar` will listen to this to show dynamic metadata.
- [ ] **fuzzel-04-custom-layer-anchor.patch**: `wayland.c` - Add support for custom `margin-top` overrides during runtime to perfectly align Fuzzel directly below the sfwbar dynamic island.

### Sfwbar Patches
- [x] **sfwbar-01-dynamic-island-canvas.patch**: `bar.c` - Enforces a full-width transparent window for fluid animations.
- [x] **sfwbar-02-spring-animations.patch**: `popup.c` - Injects cubic-bezier transitions for popup menus.
- [ ] **sfwbar-03-wayland-blur.patch**: `wayland.c` - Implement native `ext-session-lock` or `layer-shell` blur protocol for premium frosted glass.
- [ ] **sfwbar-04-fuzzel-embed.patch**: `widget.c` - Allow `sfwbar` to embed `fuzzel` directly inside its widget tree as a child layer surface, enabling true Apple-style Dynamic Island morphing.
