#!/bin/bash
# Hyprland Configuration Switcher
# Switches between quickshell and full services setup

CACHE_DIR="$HOME/.cache/hyprland"
STATE_FILE="$CACHE_DIR/config_state"
CONFIG_FILE="$HOME/.config/uchiha/quickshell/config.json"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to get current state
get_current_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "none"
    fi
}

# Function to set wallpaper from config.json
set_wallpaper() {
    echo "Setting wallpaper..."

    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found: $CONFIG_FILE"
        notify-send "Wallpaper Error" "Config file not found" -t 3000
        return 1
    fi

    # Read wallpaper path from config.json
    WALLPAPER_PATH=$(jq -r '.background.wallpaperPath' "$CONFIG_FILE")

    if [ -z "$WALLPAPER_PATH" ] || [ "$WALLPAPER_PATH" = "null" ]; then
        echo "No wallpaper path found in config"
        return 1
    fi

    # Expand ~ to home directory if present
    WALLPAPER_PATH="${WALLPAPER_PATH/#\~/$HOME}"

    # Check if file exists
    if [ ! -f "$WALLPAPER_PATH" ]; then
        echo "Wallpaper file not found: $WALLPAPER_PATH"
        notify-send "Wallpaper Error" "File not found: $WALLPAPER_PATH" -t 3000
        return 1
    fi

    # Check if wallpaper is a video (.mp4)
    if [[ "$WALLPAPER_PATH" == *.mp4 ]]; then
        echo "Video wallpaper detected, killing swww-daemon..."
        pkill -x swww-daemon
        sleep 0.5

        # You can add mpvpaper or other video wallpaper tool here
        # Example: mpvpaper -o "no-audio loop" '*' "$WALLPAPER_PATH" &
        notify-send "Wallpaper" "Video wallpaper detected - swww-daemon stopped" -t 3000
    else
        echo "Image wallpaper detected, applying with swww..."
        # Ensure swww-daemon is running
        if ! pgrep -x swww-daemon > /dev/null; then
            swww-daemon &
            sleep 1
        fi

        # Apply wallpaper with swww
        swww img "$WALLPAPER_PATH" --transition-type fade --transition-duration 2
        notify-send "Wallpaper" "Applied: $(basename "$WALLPAPER_PATH")" -t 3000
    fi
}

# Function to kill all services
kill_services() {
    echo "Stopping all services..."
    pkill -x waybar
    pkill -x swww-daemon
    pkill -x nm-applet
    pkill -x swaync
    pkill -x qs
    # Add any other services you want to kill here
    sleep 0.5
}

# Function to start quickshell
start_quickshell() {
    echo "Starting quickshell..."
    qs -c ii &
    sleep 0.5
    echo "quickshell" > "$STATE_FILE"
    notify-send "Hyprland Config" "Switched to Quickshell mode" -t 3000
}

# Function to start full services
start_services() {
    echo "Starting full services..."
    waybar &
    sleep 0.2
    swww-daemon &
    sleep 0.5
    set_wallpaper
    sleep 0.2
    nm-applet --indicator &
    sleep 0.2
    swaync &
    sleep 0.2
    # Add any other services here
    echo "services" > "$STATE_FILE"
    notify-send "Hyprland Config" "Switched to Full Services mode" -t 3000
}

# Main logic
case "$1" in
    quickshell)
        kill_services
        start_quickshell
        ;;
    services)
        kill_services
        start_services
        ;;
    toggle)
        # Read current state
        CURRENT=$(get_current_state)

        # Toggle between states
        if [ "$CURRENT" = "quickshell" ]; then
            kill_services
            start_services
        else
            kill_services
            start_quickshell
        fi
        ;;
    wallpaper)
        # Auto-detect current state and only apply wallpaper if in services mode
        CURRENT=$(get_current_state)

        if [ "$CURRENT" = "services" ]; then
            echo "Current mode: services - Applying wallpaper..."
            set_wallpaper
        else
            echo "Current mode: $CURRENT - Wallpaper command only works in services mode"
            notify-send "Wallpaper" "Only available in services mode (current: $CURRENT)" -t 3000
        fi
        ;;
    status)
        # Show current state
        CURRENT=$(get_current_state)
        echo "Current configuration mode: $CURRENT"
        notify-send "Hyprland Config" "Current mode: $CURRENT" -t 3000
        ;;
    *)
        echo "Usage: $0 {quickshell|services|toggle|wallpaper|status}"
        echo "  quickshell - Switch to quickshell mode"
        echo "  services   - Switch to full services mode"
        echo "  toggle     - Toggle between modes"
        echo "  wallpaper  - Apply wallpaper from config.json (only in services mode)"
        echo "  status     - Show current configuration mode"
        exit 1
        ;;
esac
