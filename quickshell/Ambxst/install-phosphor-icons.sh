#!/usr/bin/env bash
#
# Install Phosphor Icons fonts (ttf-phosphor-icons) into ~/.local/share/fonts
# without touching /usr and without needing root or makepkg.
#
# Usage:
#   ./install-phosphor-icons.sh              # install
#   ./install-phosphor-icons.sh --uninstall  # remove
#
set -euo pipefail

FONT_NAME="phosphor-icons"
VERSION="2.1.2"
URL="https://github.com/phosphor-icons/web/archive/refs/tags/v${VERSION}.zip"
SHA256="166c6aa03a64692ed8401c40e51e3b66925d6ea6cbd4ae447699e88dc7c00e60"

# Respect XDG_DATA_HOME if set, otherwise ~/.local/share
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DEST="${DATA_HOME}/fonts/${FONT_NAME}"

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

refresh_cache() {
    if command -v fc-cache >/dev/null 2>&1; then
        info "Refreshing font cache"
        fc-cache -f "${DATA_HOME}/fonts" >/dev/null
    else
        info "fc-cache not found; log out/in or install fontconfig to refresh the cache"
    fi
}

# --- Safety: this script is meant for a normal user, not root -----------------
if [[ ${EUID} -eq 0 ]]; then
    die "Don't run this as root; it installs into your own home directory."
fi

# --- Uninstall ----------------------------------------------------------------
if [[ "${1:-}" == "--uninstall" ]]; then
    if [[ -d "$DEST" ]]; then
        info "Removing $DEST"
        rm -rf -- "$DEST"
        refresh_cache
        info "Uninstalled."
    else
        info "Nothing to remove ($DEST does not exist)."
    fi
    exit 0
fi

[[ $# -eq 0 ]] || die "Unknown argument: $1 (only --uninstall is supported)"

# --- Dependency checks --------------------------------------------------------
for cmd in curl unzip sha256sum install; do
    command -v "$cmd" >/dev/null 2>&1 || die "Missing required command: $cmd"
done

# --- Download to a temp dir that is always cleaned up -------------------------
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

ARCHIVE="${TMP}/${FONT_NAME}-${VERSION}.zip"

info "Downloading Phosphor Icons v${VERSION}"
curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
     --output "$ARCHIVE" "$URL"

# --- Verify integrity (same checksum the AUR PKGBUILD pins) -------------------
info "Verifying SHA-256 checksum"
echo "${SHA256}  ${ARCHIVE}" | sha256sum --check --status \
    || die "Checksum mismatch! Refusing to install. The download may be corrupted or tampered with."

# --- Extract only the files we need -------------------------------------------
info "Extracting fonts and license"
unzip -q "$ARCHIVE" \
    "web-${VERSION}/src/*/*.ttf" \
    "web-${VERSION}/LICENSE" \
    -d "${TMP}/extract"

SRC="${TMP}/extract/web-${VERSION}"

shopt -s nullglob
fonts=( "${SRC}"/src/*/*.ttf )
shopt -u nullglob
(( ${#fonts[@]} > 0 )) || die "No .ttf files found in the archive."

# --- Install into ~/.local/share/fonts/phosphor-icons -------------------------
info "Installing ${#fonts[@]} font files to ${DEST}"
install -Dm644 "${fonts[@]}" -t "$DEST"
install -Dm644 "${SRC}/LICENSE" "${DEST}/LICENSE"

refresh_cache

info "Done. Installed:"
ls -1 "$DEST" | sed 's/^/     /'
