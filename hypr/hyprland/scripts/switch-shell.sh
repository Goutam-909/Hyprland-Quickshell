#!/usr/bin/env bash
#
# switch-shell.sh — switch between the end4-pC and Ambxst quickshell setups.
#
#   switch-shell.sh end4        -> end4-pC  (+ hypridle, + its keybinds)
#   switch-shell.sh ambxst      -> Ambxst   (+ loginlock.sh, + its keybinds, NO hypridle)
#   switch-shell.sh toggle      -> flip to the other one
#   switch-shell.sh rofi        -> pick from a rofi menu
#   switch-shell.sh status      -> print the active shell
#
#   switch-shell.sh boot-cleanup -> (called from execs.lua at login) kill the
#                                   OTHER shell's leftovers
#
# The choice is persistent: hyprland/shells/current is a symlink to
# shells/end4-pC or shells/ambxst. keybinds.lua / execs.lua only load the
# files behind that link, so the other shell's Lua is never executed.
#
# What a switch does:
#   1. kills every quickshell + hypridle + loginlock.sh + sleep_monitor.sh
#   2. re-points the `current` symlink at the new shell
#   3. starts the new shell + its idle/lock helper
#   4. `hyprctl reload` -> Hyprland re-runs the config with the new shell's binds

set -u

# ── Config ───────────────────────────────────────────────────────────────────
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shell-switch/logs"
DEFAULT_SHELL="end4-pC"      # used when the `current` link doesn't exist yet
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
CURRENT_LINK="$HYPR_DIR/hyprland/shells/current"

END4_NAME="end4-pC"
AMBXST_NAME="ambxst"

AMBXST_QML="$HOME/.config/quickshell/Ambxst/shell.qml"
AMBXST_LOGINLOCK="$HOME/.config/quickshell/Ambxst/scripts/loginlock.sh"
AMBXST_SLEEP_MONITOR="$HOME/.config/quickshell/Ambxst/scripts/sleep_monitor.sh"

mkdir -p "$LOG_DIR"

# ── Helpers ──────────────────────────────────────────────────────────────────
notify() { command -v notify-send >/dev/null && notify-send -a "Shell switch" "$1" "${2:-}"; }
log()    { echo "==> $*"; }

# Which shell is actually running? (empty if none)
running_shell() {
    local procs
    procs=$(ps -eo args= 2>/dev/null | grep -E '^(\S*/)?(qs|quickshell) ')
    if   grep -q 'Ambxst/shell\.qml' <<<"$procs"; then echo "$AMBXST_NAME"
    elif grep -q 'end4-pC'           <<<"$procs"; then echo "$END4_NAME"
    fi
}

# The persistent choice = where the symlink points
current_shell() {
    local t=""
    [[ -L "$CURRENT_LINK" ]] && t="$(basename "$(readlink "$CURRENT_LINK")")"
    case "$t" in
        "$END4_NAME"|"$AMBXST_NAME") echo "$t" ;;
        *) echo "$DEFAULT_SHELL" ;;
    esac
}

set_current() { ln -sfn "$1" "$CURRENT_LINK"; }   # relative link: shells/current -> <name>

# wait until the new shell shows up in the process list (max ~3s)
wait_for_shell() {
    for _ in $(seq 1 15); do
        [[ "$(running_shell)" == "$1" ]] && return 0
        sleep 0.2
    done
}

# kill by exact process name, escalate to SIGKILL if it won't die
kill_proc() {
    local name="$1"
    pgrep -x "$name" >/dev/null || return 0
    pkill -x "$name" 2>/dev/null
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        pgrep -x "$name" >/dev/null || return 0
        sleep 0.2
    done
    pkill -9 -x "$name" 2>/dev/null
}

stop_quickshell() {
    log "Stopping quickshell"
    kill_proc quickshell
    kill_proc qs
}

stop_hypridle() {
    log "Stopping hypridle"
    kill_proc hypridle
}

# kill a script by path, including its children and subshells
kill_script() {
    local path="$1" pid
    for pid in $(pgrep -f "$path" 2>/dev/null); do
        [[ "$pid" == "$$" ]] && continue
        pkill -P "$pid" 2>/dev/null     # children (dbus/gdbus monitors, sleep, ...)
        kill "$pid" 2>/dev/null
    done
    sleep 0.2
    pkill -9 -f "$path" 2>/dev/null     # anything that survived (e.g. the subshell)
}

# Ambxst helper scripts that must die together with the lock script
stop_loginlock() {
    log "Stopping loginlock.sh + sleep_monitor.sh"
    kill_script "$AMBXST_LOGINLOCK"
    kill_script "$AMBXST_SLEEP_MONITOR"
}

start_detached() {   # start_detached <logname> <cmd...>
    local logname="$1"; shift
    setsid -f "$@" >>"$LOG_DIR/$logname.log" 2>&1 </dev/null
}

start_end4() {
    log "Starting end4-pC"
    start_detached hypridle hypridle
    start_detached quickshell qs -c "$END4_NAME"
}

start_ambxst() {
    log "Starting Ambxst"
    start_detached quickshell qs -p "$AMBXST_QML"
    if [[ -x "$AMBXST_LOGINLOCK" ]]; then
        start_detached loginlock "$AMBXST_LOGINLOCK"
    else
        echo "WARNING: $AMBXST_LOGINLOCK missing or not executable" >&2
        notify "Ambxst" "loginlock.sh not found/executable — lock won't work"
    fi
}

# ── Main switch ──────────────────────────────────────────────────────────────
switch_to() {
    local target="$1"

    # don't pull the rug out from under a locked session
    if pgrep -x hyprlock >/dev/null; then
        echo "Screen is locked, refusing to switch." >&2
        exit 1
    fi

    log "Switching to: $target"

    # 1. kill everything belonging to the shells
    stop_quickshell
    stop_hypridle
    stop_loginlock

    # 2. persist the choice (survives logout / reboot)
    set_current "$target"

    # 3. start the new one
    case "$target" in
        "$END4_NAME")   start_end4   ;;
        "$AMBXST_NAME") start_ambxst ;;
    esac
    wait_for_shell "$target"

    # 4. reload Hyprland -> loads ONLY the new shell's keybinds
    hyprctl reload >/dev/null 2>&1

    notify "Shell switched" "Now running: $target"
}

# At login: remove leftovers of the shell that is NOT selected.
boot_cleanup() {
    case "$(current_shell)" in
        "$AMBXST_NAME")
            stop_hypridle
            pkill -f -- "^(\S*/)?(qs|quickshell) -c $END4_NAME" 2>/dev/null ;;
        "$END4_NAME")
            stop_loginlock
            pkill -f -- "^(\S*/)?(qs|quickshell) .*Ambxst/shell\.qml" 2>/dev/null ;;
    esac
}

pick_with_rofi() {
    local cur; cur="$(current_shell)"
    local choice
    choice=$(printf '%s\n' \
        "$([[ $cur == $END4_NAME   ]] && echo '● ')$END4_NAME" \
        "$([[ $cur == $AMBXST_NAME ]] && echo '● ')$AMBXST_NAME" \
        | rofi -dmenu -i -p "Shell" -no-custom) || exit 0
    choice="${choice#● }"
    [[ -n "$choice" ]] && switch_to "$choice"
}

case "${1:-}" in
    end4|end4-pC|"$END4_NAME")   switch_to "$END4_NAME" ;;
    ambxst|Ambxst)               switch_to "$AMBXST_NAME" ;;
    toggle)
        if [[ "$(current_shell)" == "$END4_NAME" ]]; then switch_to "$AMBXST_NAME"
        else switch_to "$END4_NAME"; fi ;;
    rofi)    pick_with_rofi ;;
    status)  current_shell ;;
    boot-cleanup) boot_cleanup ;;
    *)
        sed -n '3,16p' "$0" | sed 's/^# \{0,1\}//'
        exit 1 ;;
esac
