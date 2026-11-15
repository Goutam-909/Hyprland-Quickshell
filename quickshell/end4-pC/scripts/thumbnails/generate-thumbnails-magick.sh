#!/usr/bin/env bash

# Generate thumbnails for files using ImageMagick, following Freedesktop spec
# Usage:
#   ./generate-thumbnails-magick.sh --file <path>
#   ./generate-thumbnails-magick.sh --directory <path>

set -e

# Thumbnail sizes mapping
get_thumbnail_size() {
    case "$1" in
        normal) echo 128 ;;
        large) echo 256 ;;
        x-large) echo 512 ;;
        xx-large) echo 1024 ;;
        *) echo 128 ;;
    esac
}

usage() {
    echo "Usage: $0 --file <path> | --directory <path>"
    exit 1
}

md5() {
    # Calculate md5 hash of the file's absolute path
    echo -n "$1" | md5sum | awk '{print $1}'
}

urlencode() {
    # Percent-encode a string for use in a URI, but do not encode slashes
    local str="$1"
    local encoded=""
    local c
    for ((i=0; i<${#str}; i++)); do
        c="${str:$i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]|/|'('|')'|'*') encoded+="$c" ;;
            *) printf -v hex '%%%02X' "'${c}'"; encoded+="$hex" ;;
        esac
    done
    echo "$encoded"
}

generate_thumbnail() {
    local src="$1"
    local abs_path
    abs_path="$(realpath "$src")"
    # Skip files with multiple frames (GIFs, videos, etc.)
    case "${abs_path,,}" in
        *.gif|*.mp4|*.webm|*.mkv|*.avi|*.mov)
            return
            ;;
    esac
    local encoded_path
    encoded_path="$(urlencode "$abs_path")"
    local uri
    uri="file://$encoded_path"
    local hash
    hash="$(md5 "$uri")"
    local out="$CACHE_DIR/$hash.png"
    mkdir -p "$CACHE_DIR"
    if [ -f "$out" ]; then
        return
    fi
    # Hard resource ceiling per-process: even a single huge source image
    # (e.g. an 8K photo) can otherwise balloon MagickCore's pixel cache
    # into gigabytes of RAM. This forces it to spill to disk instead of
    # eating all available memory.
    magick -limit memory 256MiB -limit map 512MiB -limit disk 1GiB \
        "$abs_path" -resize "${THUMBNAIL_SIZE}x${THUMBNAIL_SIZE}" "$out"
}

# Parse arguments
SIZE_NAME="normal"
MODE=""
TARGET=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --file|-f)
            MODE="file"
            TARGET="$2"
            shift 2
            ;;
        --directory|-d)
            MODE="dir"
            TARGET="$2"
            shift 2
            ;;
        --size|-s)
            SIZE_NAME="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
    # Only one mode allowed
    [[ -n "$MODE" ]] && break
done

THUMBNAIL_SIZE="$(get_thumbnail_size "$SIZE_NAME")"
CACHE_DIR="$HOME/.cache/thumbnails/$SIZE_NAME"

if [ -z "$MODE" ] || [ -z "$TARGET" ]; then
    usage
fi

case "$MODE" in
    file)
        if [ ! -f "$TARGET" ]; then
            echo "File not found: $TARGET"
            exit 2
        fi
        generate_thumbnail "$TARGET"
        ;;
    dir)
        if [ ! -d "$TARGET" ]; then
            echo "Directory not found: $TARGET"
            exit 2
        fi
        # Cap how many files we thumbnail in parallel. Without this, a
        # folder with hundreds of wallpapers spawns hundreds of magick
        # processes at once, each holding a full-res image in memory -
        # easily enough to exhaust RAM and crash the system.
        # Fixed at 10 concurrent conversions regardless of core count.
        # Override with THUMBGEN_MAX_JOBS=N if you want to tune it.
        max_jobs="${THUMBGEN_MAX_JOBS:-10}"
        running=0
        for f in "$TARGET"/*; do
            [ -f "$f" ] || continue
            generate_thumbnail "$f" &
            running=$((running + 1))
            if [ "$running" -ge "$max_jobs" ]; then
                wait -n || true
                running=$((running - 1))
            fi
        done
        wait || true
        ;;
    *)
        usage
        ;;
esac

