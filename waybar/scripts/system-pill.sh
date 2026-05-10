#!/bin/bash

# ════════════════════════════════════════════════════════════
# WiFi Status
# ════════════════════════════════════════════════════════════

wifi_enabled=$(nmcli radio wifi 2>/dev/null)
if nmcli -t -f STATE,CONNECTIVITY g 2>/dev/null | grep -q "connected:full"; then
    wifi_status="connected"
else
    wifi_status="disconnected"
fi

# Determine WiFi icon based on status
if [ "$wifi_enabled" = "disabled" ]; then
    wifi_icon="󰖪"
elif [ "$wifi_status" = "connected" ]; then
    # Get signal strength
    signal=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep "^\*" | cut -d':' -f2)
    if [ -n "$signal" ]; then
        wifi_icon="󰖩"
    else
        wifi_icon="󰖩"
    fi
else
    wifi_icon="󰖪"
fi

# ════════════════════════════════════════════════════════════
# Bluetooth Status (using busctl)
# ════════════════════════════════════════════════════════════

# Check if Bluetooth is powered using busctl
bt_powered_output=$(busctl get-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Powered 2>/dev/null)
# Output format: "b true" or "b false"
if echo "$bt_powered_output" | grep -q "true"; then
    bt_powered="yes"
else
    bt_powered="no"
fi

bt_text=""

if [ "$bt_powered" = "yes" ]; then
    # Get list of paired devices
    devices=$(busctl tree org.bluez 2>/dev/null | grep -o '/org/bluez/hci0/dev_[A-F0-9_]*')

    bt_connected=false
    bt_battery=""

    # Check each device for connection status and battery
    for device_path in $devices; do
        # Check if device is connected
        connected=$(busctl get-property org.bluez "$device_path" org.bluez.Device1 Connected 2>/dev/null)

        if echo "$connected" | grep -q "true"; then
            bt_connected=true

            # Try to get battery percentage
            battery=$(busctl get-property org.bluez "$device_path" org.bluez.Battery1 Percentage 2>/dev/null)

            if [ -n "$battery" ]; then
                # Extract the percentage value (format: "y 85" where y is byte type)
                battery_value=$(echo "$battery" | awk '{print $2}')
                bt_battery="${battery_value}%"
            fi

            # Only show first connected device's battery
            break
        fi
    done

    # Set icon and text based on connection status
    if [ "$bt_connected" = true ]; then
        if [ -n "$bt_battery" ]; then
            bt_icon="󰂱"
            bt_text="$bt_icon $bt_battery"
        else
            bt_icon="󰂱"
            bt_text="$bt_icon"
        fi
    else
        bt_icon="󰂯"
        bt_text="$bt_icon"
    fi
else
    bt_icon="󰂲"
    bt_text="$bt_icon"
fi

# ════════════════════════════════════════════════════════════
# Profile Icon
# ════════════════════════════════════════════════════════════

profile_placeholder="󰀄"

# ════════════════════════════════════════════════════════════
# Output JSON for Waybar
# ════════════════════════════════════════════════════════════

echo "{\"text\":\"$wifi_icon  $bt_text  $profile_placeholder\",\"class\":\"system-pill\"}"
