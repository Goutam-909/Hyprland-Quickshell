#!/usr/bin/env bash
# ~/.config/uchiha/scripts/wallpaper.sh
#
# Wallpaper manager — state lives in config.json "background" section.
# No symlinks. No separate state files.
#
# JSON structure written/read:
#   {
#     "background": {
#       "wallpaperPath":  "/absolute/path/to/wallpaper.png|mp4|…",
#       "thumbnailPath":  "/absolute/path/to/thumbnail.jpg"   ← only meaningful for videos
#     }
#   }
#
# USAGE:
#   wallpaper.sh --set-image  <path>          Set an image wallpaper
#   wallpaper.sh --set-video  <path>          Set a video wallpaper
#   wallpaper.sh --random-image               Pick a random image from ~/Pictures/wallpapers
#   wallpaper.sh --random-video               Pick a random video from ~/Videos/Wallpapers
#   wallpaper.sh --get-state                  Print TYPE= and PATH= from config.json
#   wallpaper.sh --apply-colors               Re-run matugen using stored wallpaper
#   wallpaper.sh --set-source-color <0-3>     Pick which extracted color matugen uses
#   wallpaper.sh --gen-thumbnails             Generate gallery thumbnails (images + videos)
#   wallpaper.sh --analyze-clock              Run clock wallpaper colour analyser
#   wallpaper.sh --help                       Show this help
#
# OPTIONAL OVERRIDES (apply to --set-image / --set-video / --random-* / --apply-colors):
#   --theme   <name|default>                  Override activeTheme  (default: read from config.json)
#   --mode    <dark|light>                    Override themeMode    (default: read from config.json)
#   --scheme  <scheme-content|…>              Override matugenScheme (default: read from config.json)

set -euo pipefail

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# ── Paths ─────────────────────────────────────────────────────────────────────
IMG_DIR="$HOME/Pictures/wallpapers"
VID_DIR="$HOME/Videos/Wallpapers"
SHOT_DIR="$HOME/.config/hypr/screenshot"
CONFIG_JSON="$HOME/.config/uchiha/music/config.json"
THEME_DIR="$HOME/.config/uchiha/Theme"
THUMB_SCRIPT="$HOME/.config/uchiha/scripts/generate-thumbnails-magick.sh"
CLOCK_SCRIPT="$HOME/.config/quickshell/music/utils/scripts/clock_wallpaper_analyzer.py"

# ── Flag overrides (populated by argument parser) ─────────────────────────────
OPT_THEME=""
OPT_MODE=""
OPT_SCHEME=""

# ── Helpers ───────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

_jq_read() {
    # _jq_read <jq-filter> <default>
    local val
    if command -v jq &>/dev/null && [ -f "$CONFIG_JSON" ]; then
        val=$(jq -r "${1} // empty" "$CONFIG_JSON" 2>/dev/null)
    fi
    echo "${val:-${2:-}}"
}

# ── config.json read helpers ──────────────────────────────────────────────────
cfg_active_theme()   { _jq_read '.appearance.activeTheme'   "default"; }
cfg_theme_mode()     { _jq_read '.appearance.themeMode'     "dark"; }
cfg_matugen_scheme() { _jq_read '.appearance.matugenScheme' "scheme-content"; }
cfg_wall_path()      { _jq_read '.background.wallpaperPath' ""; }
cfg_thumb_path()     { _jq_read '.background.thumbnailPath' ""; }

resolve_config() {
    ACTIVE_THEME="${OPT_THEME:-$(cfg_active_theme)}"
    THEME_MODE="${OPT_MODE:-$(cfg_theme_mode)}"
    MATUGEN_SCHEME="${OPT_SCHEME:-$(cfg_matugen_scheme)}"
}

# ── config.json write helper ──────────────────────────────────────────────────
# Merges/creates the "background" section without touching other sections.
write_background_json() {
    local wall="$1" thumb="$2"
    command -v jq &>/dev/null || die "jq is required but not found"
    local tmp; tmp=$(mktemp)
    if [ -f "$CONFIG_JSON" ]; then
        # Patch only wallpaperPath and thumbnailPath — sourceColors/sourceColorIndex survive
        jq --arg w "$wall" --arg t "$thumb" \
            '.background.wallpaperPath = $w | .background.thumbnailPath = $t' \
            "$CONFIG_JSON" > "$tmp"
    else
        mkdir -p "$(dirname "$CONFIG_JSON")"
        jq -n --arg w "$wall" --arg t "$thumb" \
            '{"background": {"wallpaperPath": $w, "thumbnailPath": $t}}' > "$tmp"
    fi
    mv "$tmp" "$CONFIG_JSON"
}

# ── Determine which image to feed matugen ────────────────────────────────────
# For video wallpapers: use thumbnailPath (a still frame).
# For image wallpapers: use wallpaperPath directly.
color_source_image() {
    local wall="$1" thumb="$2"
    case "${wall##*.}" in
        mp4|mkv|webm|avi|mov|flv|m4v|wmv) echo "$thumb" ;;
        *)                                  echo "$wall"  ;;
    esac
}

is_video_path() {
    case "${1##*.}" in
        mp4|mkv|webm|avi|mov|flv|m4v|wmv) return 0 ;;
        *) return 1 ;;
    esac
}

# ── matugen ───────────────────────────────────────────────────────────────────
# New matugen shows an interactive TUI picker with ~4 extracted source colors.
# We run it inside a PTY via script(1) so open("/dev/tty") succeeds, send
# arrow-down × idx then Enter to select the desired color, capture the picker
# output to extract and store the full color list as a side effect.

_matugen_pty() {
    # $1 = 0-based index to select in the picker
    # $2… = matugen arguments
    local idx="$1"; shift

    local args=""
    for a in "$@"; do args="$args $(printf '%q' "$a")"; done

    # Build keystrokes: idx × ESC[B (arrow-down), then \n (Enter)
    local keys="" i=0
    while [ "$i" -lt "$idx" ]; do
        keys="${keys}"$'\e[B'
        i=$((i + 1))
    done
    keys="${keys}"$'\n'

    # Capture PTY output so we can parse the color list afterward
    local tmp; tmp=$(mktemp)

    # Feed keystrokes after 0.5 s — enough for matugen to render the picker
    ( sleep 0.5; printf '%s' "$keys" ) | \
        script --quiet --return --command "matugen$args" "$tmp"
    local ret=$?

    # Strip ANSI escape codes + CR, extract distinct #RRGGBB hex values
    # (matugen prints them as "> #244e78" / "  #ac67e8" in the picker)
    local colors
    colors=$(sed 's/\x1b\[[0-9;]*[mGKHFABCDJsu]//g; s/\r//g' "$tmp" \
             | grep -oP '#[0-9a-fA-F]{6}' \
             | awk '!seen[$0]++' \
             | head -4)
    rm -f "$tmp"

    # Persist extracted color list + selected index into config.json
    if [ -n "$colors" ] && command -v jq &>/dev/null && [ -f "$CONFIG_JSON" ]; then
        local json_arr; json_arr=$(printf '%s\n' $colors | jq -R . | jq -s .)
        local tmp2; tmp2=$(mktemp)
        jq --argjson arr "$json_arr" --argjson i "$idx" \
            '.background.sourceColors = $arr | .background.sourceColorIndex = $i' \
            "$CONFIG_JSON" > "$tmp2" && mv "$tmp2" "$CONFIG_JSON" || rm -f "$tmp2"
    fi

    return $ret
}

apply_matugen() {
    resolve_config

    if ! command -v matugen &>/dev/null; then
        info "matugen not found, skipping colour generation"
        return 0
    fi

    local wall thumb color_img
    wall=$(cfg_wall_path)
    thumb=$(cfg_thumb_path)
    color_img=$(color_source_image "$wall" "$thumb")

    if [ -z "$color_img" ] || [ ! -f "$color_img" ]; then
        echo "WARNING: no colour-source image available (wall='$wall' thumb='$thumb')" >&2
        return 1
    fi

    info "matugen source: $color_img  (theme=$ACTIVE_THEME mode=$THEME_MODE scheme=$MATUGEN_SCHEME)"

    if [ -z "$ACTIVE_THEME" ] || [ "$ACTIVE_THEME" = "default" ]; then
        # Read stored color index (default 0 = top item in picker)
        local idx
        idx=$(jq -r '.background.sourceColorIndex // 0' "$CONFIG_JSON" 2>/dev/null || echo 0)
        _matugen_pty "$idx" image "$color_img" --mode "$THEME_MODE" --type "$MATUGEN_SCHEME"
    else
        # Named theme — uses sourceColor hex from its JSON, no interactive picker
        local json_path="$THEME_DIR/$ACTIVE_THEME/$THEME_MODE.json"
        local src_color
        src_color=$(jq -r '.sourceColor // empty' "$json_path" 2>/dev/null || true)
        if [ -z "$src_color" ]; then
            echo "WARNING: no sourceColor in $json_path, falling back to image" >&2
            local idx
            idx=$(jq -r '.background.sourceColorIndex // 0' "$CONFIG_JSON" 2>/dev/null || echo 0)
            _matugen_pty "$idx" image "$color_img" --mode "$THEME_MODE" --type "$MATUGEN_SCHEME"
        else
            local args=""
            for a in color hex "$src_color" --mode "$THEME_MODE" --type "$MATUGEN_SCHEME"; do
                args="$args $(printf '%q' "$a")"
            done
            script --quiet --return --command "matugen$args" /dev/null
        fi
    fi
}

# ── Kill helpers ──────────────────────────────────────────────────────────────
kill_mpvpaper() {
    if /usr/bin/pgrep -x mpvpaper &>/dev/null; then
        /usr/bin/pkill -TERM mpvpaper 2>/dev/null || true
        local a=0
        while /usr/bin/pgrep -x mpvpaper &>/dev/null && [ "$a" -lt 3 ]; do
            /usr/bin/pkill -9 mpvpaper 2>/dev/null || true; sleep 0.2; a=$((a+1))
        done
    fi
}

kill_swww() {
    if /usr/bin/pgrep -x awww-daemon &>/dev/null || /usr/bin/pgrep -x awww &>/dev/null; then
        /usr/bin/pkill -9 awww-daemon 2>/dev/null || true
        /usr/bin/pkill -9 awww         2>/dev/null || true
        local a=0
        while /usr/bin/pgrep -x awww-daemon &>/dev/null && [ "$a" -lt 5 ]; do
            sleep 0.2; a=$((a+1))
        done
    fi
}

ensure_swww() {
    if ! /usr/bin/pgrep -x awww-daemon &>/dev/null; then
        setsid awww-daemon & disown; sleep 1
    fi
    local a=0
    while ! awww query &>/dev/null && [ "$a" -lt 5 ]; do
        sleep 0.3; a=$((a+1))
    done
}

# ── Commands ──────────────────────────────────────────────────────────────────

cmd_set_image() {
    local img="$1"
    [ -f "$img" ] || die "Image not found: $img"
    info "Setting image wallpaper: $img"

    kill_mpvpaper
    ensure_swww

    if awww query &>/dev/null; then
        awww img "$img" \
            --transition-fps 60 \
            --transition-type any \
            --transition-duration 3 \
            --transition-bezier '0.4,0.2,0.4,1.0'
    else
        command -v swaybg &>/dev/null && setsid swaybg -i "$img" & disown || true
    fi

    # Persist to JSON — thumbnailPath empty for images
    write_background_json "$img" ""

    apply_matugen
    cmd_analyze_clock
}

cmd_set_video() {
    local video="$1"
    [ -f "$video" ] || die "Video not found: $video"
    info "Setting video wallpaper: $video"

    mkdir -p "$SHOT_DIR"
    local name
    name=$(basename "$video" | sed 's/\.[^.]*$//')
    local shot="$SHOT_DIR/$name.png"

    kill_swww
    kill_mpvpaper

    setsid /usr/bin/mpvpaper \
        -o 'no-audio --loop-file=inf --hwdec=auto' \
        '*' "$video" </dev/null &>/dev/null &
    disown

    /usr/bin/pgrep -x mpvpaper &>/dev/null || sleep 1

    # Extract still frame for colour generation
    if [ ! -f "$shot" ] || [ ! -s "$shot" ]; then
        if command -v ffmpeg &>/dev/null; then
            local dur t
            dur=$(ffprobe -v quiet \
                -show_entries format=duration \
                -of default=noprint_wrappers=1:nokey=1 \
                "$video" 2>/dev/null || echo 30)
            t=$(echo "$dur * 0.1" | bc -l 2>/dev/null || echo 3)
            [ "$(echo "$t > 30" | bc -l 2>/dev/null || echo 0)" = "1" ] && t=10
            ffmpeg -i "$video" -ss "$t" -vframes 1 -q:v 2 "$shot" -y &>/dev/null || true
            if [ ! -f "$shot" ] || [ ! -s "$shot" ]; then
                ffmpeg -i "$video" -ss 5 -vframes 1 -q:v 2 "$shot" -y &>/dev/null || true
            fi
        fi
        if [ ! -f "$shot" ] || [ ! -s "$shot" ]; then
            command -v convert &>/dev/null && \
                convert -size 1920x1080 xc:#1e1e2e "$shot" 2>/dev/null || true
        fi
    fi

    # Persist to JSON — thumbnailPath holds the still frame for colour work
    write_background_json "$video" "$shot"

    apply_matugen
    cmd_analyze_clock
}

cmd_random_image() {
    local files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$IMG_DIR" -maxdepth 1 \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
        ! -name "random.png" ! -name "videoicon.png" \
        -print0 2>/dev/null)
    [ "${#files[@]}" -gt 0 ] || die "No images found in $IMG_DIR"
    cmd_set_image "${files[RANDOM % ${#files[@]}]}"
}

cmd_random_video() {
    local files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$VID_DIR" -maxdepth 1 \
        \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" \
           -o -iname "*.mov" -o -iname "*.flv" -o -iname "*.m4v" -o -iname "*.wmv" \) \
        -print0 2>/dev/null)
    [ "${#files[@]}" -gt 0 ] || die "No videos found in $VID_DIR"
    cmd_set_video "${files[RANDOM % ${#files[@]}]}"
}

cmd_get_state() {
    local wall type
    wall=$(cfg_wall_path)
    if [ -n "$wall" ]; then
        is_video_path "$wall" && type="video" || type="image"
        echo "TYPE=$type"
        echo "PATH=$wall"
    else
        echo "TYPE="
        echo "PATH="
    fi
}

# Re-run matugen against the stored wallpaper — called by AppearancePage
# when the user switches theme/mode/scheme without changing wallpaper.
cmd_apply_colors() {
    apply_matugen
}

# Apply matugen using a specific color index from the picker.
# Stores the index in config.json so future runs remember the choice.
cmd_set_source_color() {
    local idx="$1"
    case "$idx" in ''|*[!0-9]*) die "--set-source-color requires a numeric index (0-3)" ;; esac
    resolve_config

    local wall thumb color_img
    wall=$(cfg_wall_path)
    thumb=$(cfg_thumb_path)
    color_img=$(color_source_image "$wall" "$thumb")

    [ -n "$color_img" ] && [ -f "$color_img" ] || \
        die "No wallpaper image found in config — set a wallpaper first"

    info "Selecting source color index $idx from $color_img"
    _matugen_pty "$idx" image "$color_img" --mode "$THEME_MODE" --type "$MATUGEN_SCHEME"
}

cmd_gen_thumbnails() {
    [ -f "$THUMB_SCRIPT" ] || die "Thumbnail script not found: $THUMB_SCRIPT"
    info "Generating thumbnails for images…"
    bash "$THUMB_SCRIPT" --directory "$IMG_DIR" --size large
    info "Generating thumbnails for videos…"
    bash "$THUMB_SCRIPT" --directory "$VID_DIR" --size large
    info "Done."
}

cmd_analyze_clock() {
    [ -f "$CLOCK_SCRIPT" ] || return 0

    # Determine the image to analyse from JSON (same logic as apply_matugen)
    local wall thumb img
    wall=$(cfg_wall_path)
    thumb=$(cfg_thumb_path)
    img=$(color_source_image "$wall" "$thumb")

    [ -n "$img" ] && [ -f "$img" ] || return 0

    local sw sh
    sw=$(hyprctl monitors -j 2>/dev/null \
        | python3 -c "import sys,json; m=json.load(sys.stdin)[0]; print(m['width'])" \
        2>/dev/null || echo 1920)
    sh=$(hyprctl monitors -j 2>/dev/null \
        | python3 -c "import sys,json; m=json.load(sys.stdin)[0]; print(m['height'])" \
        2>/dev/null || echo 1080)

    python3 "$CLOCK_SCRIPT" "$img" \
        --width 400 --height 300 \
        --screen-width  "$sw" \
        --screen-height "$sh" \
        --stride 8 \
        --horizontal-padding 80 \
        --vertical-padding   80 \
        --clusters 20 \
        --stops 12
}

usage() {
    grep '^#   ' "$0" | sed 's/^#   /  /'
    exit 0
}

# ── Argument parsing ──────────────────────────────────────────────────────────
ACTION=""
TARGET=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --set-image)      ACTION="set-image";      TARGET="${2:?"--set-image requires a path"}";  shift 2 ;;
        --set-video)      ACTION="set-video";      TARGET="${2:?"--set-video requires a path"}";  shift 2 ;;
        --random-image)   ACTION="random-image";   shift ;;
        --random-video)   ACTION="random-video";   shift ;;
        --get-state)        ACTION="get-state";        shift ;;
        --apply-colors)     ACTION="apply-colors";     shift ;;
        --set-source-color) ACTION="set-source-color"; TARGET="${2:?"--set-source-color requires an index (0-3)"}"; shift 2 ;;
        --gen-thumbnails) ACTION="gen-thumbnails"; shift ;;
        --analyze-clock)  ACTION="analyze-clock";  shift ;;
        --theme)          OPT_THEME="${2:?"--theme requires a value"}";   shift 2 ;;
        --mode)           OPT_MODE="${2:?"--mode requires a value"}";     shift 2 ;;
        --scheme)         OPT_SCHEME="${2:?"--scheme requires a value"}"; shift 2 ;;
        --help|-h)        usage ;;
        *)                die "Unknown argument: $1 (try --help)" ;;
    esac
done

[ -n "$ACTION" ] || usage

case "$ACTION" in
    set-image)      cmd_set_image    "$TARGET" ;;
    set-video)      cmd_set_video    "$TARGET" ;;
    random-image)   cmd_random_image ;;
    random-video)   cmd_random_video ;;
    get-state)          cmd_get_state          ;;
    apply-colors)       cmd_apply_colors       ;;
    set-source-color)   cmd_set_source_color   "$TARGET" ;;
    gen-thumbnails) cmd_gen_thumbnails ;;
    analyze-clock)  cmd_analyze_clock ;;
esac
