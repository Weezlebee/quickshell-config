#!/bin/bash

STATE_FILE="$HOME/.config/appearance/theme/mode"
mkdir -p "$(dirname "$STATE_FILE")"

# Toggle state between "dark" and "light"
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "dark" ]; then
    MODE="light"
else
    MODE="dark"
fi

echo "$MODE" > "$STATE_FILE"

# Tell GTK / System apps to update
if [ "$MODE" = "dark" ]; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
else
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light" 2>/dev/null
fi

# Find current wallpaper path and run matugen with the toggled mode
THEME=$(cat ~/.config/appearance/theme/which_theme 2>/dev/null || echo "rose-pine")
CURRENT_WALL=$(swww query 2>/dev/null | grep -oP 'image: \K.*' || echo "$HOME/Pictures/wallpapers/$THEME/default.png")

if [ -f "$CURRENT_WALL" ]; then
    matugen image "$CURRENT_WALL" -m "$MODE" --source-color-index 0
fi

# Reload terminal & bar colors
pkill qs
./.config/quickshell/reload.sh