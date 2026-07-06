#!/bin/bash
ACTIONS="$HOME/.local/bin/actions.sh"
opts=(
  "Open Launcher"
  "Calculator"
  "Emoji Picker"
  "Clipboard History"
  "Back"
)
choice=$(printf '%s\n' "${opts[@]}" | rofi -dmenu -p "Tools ❯ " -w 35 -l 5)
case "$choice" in
  *"Open Launcher") "$ACTIONS" launcher apps ;;
  *"Calculator") "$ACTIONS" rofi-calc ;;
  *"Emoji Picker") "$ACTIONS" rofi-emoji ;;
  *"Clipboard History") "$ACTIONS" clipboard show ;;
  *"Back") exec ~/.local/bin/actions/dotfiles-menu.sh ;;
esac
