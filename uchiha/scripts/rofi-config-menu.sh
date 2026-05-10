#!/bin/bash

# Rofi Config Switcher Menu
# Shows current state and allows switching

CACHE_DIR="$HOME/.cache/hyprland"
STATE_FILE="$CACHE_DIR/config_state"
SWITCHER_SCRIPT="$HOME/.config/uchiha/scripts/switch-config.sh"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Get current state
if [ -f "$STATE_FILE" ]; then
    CURRENT=$(cat "$STATE_FILE")
else
    CURRENT="none"
fi

# Set the status indicator
if [ "$CURRENT" = "quickshell" ]; then
    STATUS="󰣇 Current: Quickshell"
elif [ "$CURRENT" = "services" ]; then
    STATUS=" Current: Full Services"
else
    STATUS=" Current: Unknown"
fi

# Define menu options with icons
OPTIONS=" Quickshell Mode\n Full Services Mode\n Toggle Configuration"

# Show rofi menu
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Config Switcher" \
    -mesg "$STATUS" \
    -theme ~/.config/rofi/config-switcher.rasi)

# Execute based on choice
case "$CHOICE" in
    *"Quickshell Mode")
        $SWITCHER_SCRIPT quickshell
        ;;
    *"Full Services Mode")
        $SWITCHER_SCRIPT services
        ;;
    *"Toggle Configuration")
        $SWITCHER_SCRIPT toggle
        ;;
esac
