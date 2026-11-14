#!/usr/bin/env bash

choice=$(printf "Sub\nDub" | rofi -dmenu -p "ani-cli" -mesg "Choose audio track:")

case "$choice" in
    Dub)
        ani-cli --rofi --dub
        ;;
    Sub)
        ani-cli --rofi
        ;;
    *)
        # User closed rofi / pressed Escape
        exit 0
        ;;
esac
