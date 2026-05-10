#!/bin/bash

# Hyprland Autostart Script
# Place this in your hyprland.conf as: exec-once = ~/.config/hypr/scripts/autostart.sh

CACHE_DIR="$HOME/.cache/hyprland"
STATE_FILE="$CACHE_DIR/config_state"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Check if state file exists and read the state
if [ -f "$STATE_FILE" ]; then
    STATE=$(cat "$STATE_FILE")
    echo "Found previous state: $STATE"
    else
        # Default to services if no state file exists
        STATE="services"
        echo "No state file found, defaulting to: $STATE"
        fi

        # Start services based on state
        case "$STATE" in
        quickshell)
        echo "Starting quickshell configuration..."
        qs -c ii &
        ;;
        services)
        echo "Starting full services configuration..."
        waybar &
        sleep 0.2
        swww-daemon &
        sleep 0.2
        nm-applet --indicator &
        sleep 0.2
        # Add any other services here
        ;;
        *)
        echo "Unknown state, starting default services..."
        waybar &
        sleep 0.2
        swww-daemon &
        sleep 0.2
        nm-applet --indicator &
        ;;
        esac
