#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    exit 1
fi

# Determine menu tool: wmenu for GUI / Wayland, fzf if inside interactive terminal without GUI
if [ -t 0 ] && command -v fzf >/dev/null 2>&1; then
    CHOSEN=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -printf "%f\n" | sort | fzf --prompt="Select Wallpaper > ")
elif command -v wmenu >/dev/null 2>&1; then
    CHOSEN=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -printf "%f\n" | sort | wmenu -p "Wallpaper:")
fi

if [ -n "$CHOSEN" ] && [ -f "$WALLPAPER_DIR/$CHOSEN" ]; then
    "$HOME/.config/sway/set-wallpaper.sh" "$WALLPAPER_DIR/$CHOSEN"
fi
