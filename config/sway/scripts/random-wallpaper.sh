#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
if [ ! -d "$WALLPAPER_DIR" ]; then
    exit 1
fi

# Pick a random image file
WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)

if [ -n "$WALLPAPER" ] && [ -x "$HOME/.config/sway/set-wallpaper.sh" ]; then
    "$HOME/.config/sway/set-wallpaper.sh" "$WALLPAPER"
fi
