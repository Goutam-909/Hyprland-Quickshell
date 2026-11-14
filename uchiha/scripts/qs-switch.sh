#!/usr/bin/env bash
#
# qs-switch.sh — switch between Quickshell configs (Ambxst / Caelestia / Uchiha / Music) via rofi
#
# Requires: rofi, pgrep, pkill, notify-send (optional but recommended)

set -u

HOME_DIR="$HOME"
UCHIHA_BASE="$HOME_DIR/.config/uchiha/config"

AMBXST_QML="/home/goutam/.config/quickshell/Ambxst/shell.qml"
AMBXST_CHECK_CMD="qs -p $AMBXST_QML"
CAELESTIA_CHECK_CMD="qs -c caelestia -n -d"
UCHIHA_CHECK_CMD="qs -c ii"
MUSIC_CHECK_CMD="qs -c music"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send "Quickshell Switcher" "$1"
    echo "$1"
}

# ---------------------------------------------------------------------------
# Detect which config (if any) is currently running
# ---------------------------------------------------------------------------
get_current() {
    if pgrep -f "$AMBXST_CHECK_CMD" >/dev/null 2>&1; then
        echo "Ambxst"
    elif pgrep -f "$CAELESTIA_CHECK_CMD" >/dev/null 2>&1; then
        echo "Caelestia"
    elif pgrep -f "$UCHIHA_CHECK_CMD" >/dev/null 2>&1; then
        echo "Uchiha"
    elif pgrep -f "$MUSIC_CHECK_CMD" >/dev/null 2>&1; then
        echo "Music"
    else
        echo "None"
    fi
}

# ---------------------------------------------------------------------------
# Kill every qs / quickshell related process
# ---------------------------------------------------------------------------
kill_qs() {
    pkill -9 -f "$AMBXST_CHECK_CMD"      2>/dev/null
    pkill -9 -f "$CAELESTIA_CHECK_CMD"   2>/dev/null
    pkill -9 -f "caelestia shell -d"     2>/dev/null
    pkill -9 -f "$UCHIHA_CHECK_CMD"      2>/dev/null
    pkill -9 -f "$MUSIC_CHECK_CMD"       2>/dev/null
    pkill -9 -x qs                       2>/dev/null
    sleep 0.3
}

# ---------------------------------------------------------------------------
# Sync hypr / fish configs from the uchiha stash, and clear gtk.css
# ---------------------------------------------------------------------------
sync_config() {
    local name="$1"
    local src="$UCHIHA_BASE/$name"

    if [ ! -d "$src" ]; then
        notify "Error: no config folder found at $src"
        return 1
    fi

    # hypr
    if [ -d "$src/hypr" ]; then
        rm -rf "$HOME_DIR/.config/hypr"
        cp -r "$src/hypr" "$HOME_DIR/.config/hypr"
    else
        notify "Warning: $src/hypr not found, skipping hypr sync"
    fi

    # fish
    if [ -d "$src/fish" ]; then
        rm -rf "$HOME_DIR/.config/fish"
        cp -r "$src/fish" "$HOME_DIR/.config/fish"
    else
        notify "Warning: $src/fish not found, skipping fish sync"
    fi

    # gtk-3.0 / gtk-4.0 — only remove gtk.css, keep everything else
    rm -f "$HOME_DIR/.config/gtk-3.0/gtk.css"
    rm -f "$HOME_DIR/.config/gtk-4.0/gtk.css"

    return 0
}

# ---------------------------------------------------------------------------
# Launchers
# ---------------------------------------------------------------------------
launch_ambxst() {
    nohup qs -p "$AMBXST_QML" >/dev/null 2>&1 &
    disown
}

launch_caelestia() {
    nohup caelestia shell -d >/dev/null 2>&1 &
    disown
}

launch_uchiha() {
    nohup qs -c ii >/dev/null 2>&1 &
    disown
}

launch_music() {
    nohup qs -c music >/dev/null 2>&1 &
    disown
}

# ---------------------------------------------------------------------------
# Build rofi menu
# ---------------------------------------------------------------------------
current="$(get_current)"

ambxst_label="Ambxst"
caelestia_label="Caelestia"
uchiha_label="Uchiha"
music_label="Music"

case "$current" in
    Ambxst)    ambxst_label="Ambxst (running)" ;;
    Caelestia) caelestia_label="Caelestia (running)" ;;
    Uchiha)    uchiha_label="Uchiha (running)" ;;
    Music)     music_label="Music (running)" ;;
esac

selection="$(printf '%s\n%s\n%s\n%s\n' "$ambxst_label" "$caelestia_label" "$uchiha_label" "$music_label" \
    | rofi -dmenu -i -p "Quickshell Config")"

# Nothing selected (Esc pressed etc.)
[ -z "$selection" ] && exit 0

case "$selection" in
    Ambxst*)    chosen="Ambxst" ;;
    Caelestia*) chosen="Caelestia" ;;
    Uchiha*)    chosen="Uchiha" ;;
    Music*)     chosen="Music" ;;
    *) exit 0 ;;
esac

# ---------------------------------------------------------------------------
# Act on selection
# ---------------------------------------------------------------------------
if [ "$chosen" = "$current" ]; then
    notify "$chosen is already running — doing nothing."
    exit 0
fi

kill_qs

if ! sync_config "$chosen"; then
    notify "Config sync failed for $chosen, aborting launch."
    exit 1
fi

case "$chosen" in
    Ambxst)    launch_ambxst ;;
    Caelestia) launch_caelestia ;;
    Uchiha)    launch_uchiha ;;
    Music)     launch_music ;;
esac

command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1

notify "Switched to $chosen"
