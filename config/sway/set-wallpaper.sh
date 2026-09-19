#!/bin/sh
if [ -z "$1" ] || [ ! -f "$1" ]; then
    exit 1
fi

WALLPAPER="$(realpath "$1")"
ln -sf "$WALLPAPER" /home/joji/.config/sway/current_wallpaper
swaymsg output '*' bg "$WALLPAPER" fill
if command -v notify-send >/dev/null 2>&1; then
    notify-send -i "$WALLPAPER" "Wallpaper Updated" "$(basename "$WALLPAPER")"
fi
