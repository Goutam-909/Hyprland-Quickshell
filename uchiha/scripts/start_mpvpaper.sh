#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  start_mpvpaper.sh
#  Location: /home/goutam/.config/uchiha/scripts/start_mpvpaper.sh
#
#  Called by Hyprland exec-once (or your session start) to restore a video
#  wallpaper from the previous session.
#
#  Logic:
#    1. Read background.wallpaperPath from the quickshell JSON config.
#    2. If the path is a video file → kill any stale mpvpaper, start fresh.
#    3. If it is an image (or empty) → kill mpvpaper and do nothing else;
#       Background.qml will display the image natively.
#
#  Add to hyprland.conf:
#    exec-once = /home/goutam/.config/uchiha/scripts/start_mpvpaper.sh
# ──────────────────────────────────────────────────────────────────────────────

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

CONFIG_JSON="/home/goutam/.config/uchiha/music/config.json"
VIDEO_EXTS="mp4 mkv webm avi mov flv m4v wmv"

# ── Helper: is a path a video? ────────────────────────────────────────────────
is_video() {
    local path="${1,,}"   # lowercase
    for ext in $VIDEO_EXTS; do
        [[ "$path" == *".$ext" ]] && return 0
    done
    return 1
}

# ── Read wallpaperPath from JSON ──────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
    echo "[start_mpvpaper] jq not found — cannot read config" >&2
    exit 1
fi

WALLPAPER_PATH=""
if [[ -f "$CONFIG_JSON" ]]; then
    WALLPAPER_PATH=$(jq -r '.background.wallpaperPath // empty' "$CONFIG_JSON" 2>/dev/null)
fi

# ── Kill any existing mpvpaper first (always) ─────────────────────────────────
if pgrep -x mpvpaper >/dev/null 2>&1; then
    pkill -TERM mpvpaper 2>/dev/null
    for _i in 1 2 3; do
        pgrep -x mpvpaper >/dev/null 2>&1 || break
        pkill -9 mpvpaper 2>/dev/null
        sleep 0.2
    done
fi

# ── Nothing saved yet, or it is an image → Background.qml handles it ─────────
if [[ -z "$WALLPAPER_PATH" ]]; then
    echo "[start_mpvpaper] No wallpaper saved in config — nothing to do"
    exit 0
fi

if ! is_video "$WALLPAPER_PATH"; then
    echo "[start_mpvpaper] Wallpaper is an image — Background.qml will render it"
    exit 0
fi

# ── Video: verify the file still exists ──────────────────────────────────────
if [[ ! -f "$WALLPAPER_PATH" ]]; then
    echo "[start_mpvpaper] Video not found: $WALLPAPER_PATH" >&2
    exit 1
fi

# ── Start mpvpaper ────────────────────────────────────────────────────────────
echo "[start_mpvpaper] Starting mpvpaper for: $WALLPAPER_PATH"
setsid /usr/bin/mpvpaper \
    -o 'no-audio --loop-file=inf --hwdec=auto' \
    '*' \
    "$WALLPAPER_PATH" \
    </dev/null >/dev/null 2>&1 &
disown

# Brief wait to confirm it launched
sleep 0.8
if pgrep -x mpvpaper >/dev/null 2>&1; then
    echo "[start_mpvpaper] mpvpaper running OK"
else
    echo "[start_mpvpaper] WARNING: mpvpaper did not start" >&2
    exit 1
fi

exit 0
