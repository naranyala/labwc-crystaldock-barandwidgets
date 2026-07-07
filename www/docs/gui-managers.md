# OCWS GUI Managers

OCWS provides a suite of native C/GTK3 desktop applications (compiled via Zig) to easily configure, manage, and debug the ecosystem without forcing you to edit config files by hand.

## Dock Manager (`ocws-dock-mgr`)

The Dock Manager lets you pin and unpin applications to your Sfwbar dock via a simple UI.

- **Hot-reloading:** Whenever you click "Save" in the Dock Manager, it updates `dotfiles/ocws/sfwbar-dock.json` and immediately hot-reloads `sfwbar`, applying your changes instantly without restarting the shell.
- **App Discovery:** Automatically pulls icon definitions and categories from `.desktop` files.

## Desktop Manager (`ocws-dotdesktop-mgr`)

Provides an easy interface to create or edit `.desktop` application entries. 
This is incredibly useful if you download a portable AppImage or a binary script (like `dms` or a custom python script) and want it to appear in `fuzzel` and `ocws-dock-mgr`.

## Settings Panel (`ocws-settings`)

The master configuration hub for the OCWS visual style.
- Adjust themes, colors, and layout modes (Single-Bar vs Double-Panel).
- Triggers dynamic `.css` token generation, immediately transforming the aesthetics of the entire desktop.
