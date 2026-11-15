pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.modules.launcher.items
import Quickshell
import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.services

// "Wallpaper" action mode for the launcher (triggered by typing
// ">wallpaper" or picking the "Wallpaper" entry in ">" action mode -
// see AppList.qml).
//
// Styled after caelestia's launcher WallpaperList.qml / WallpaperItem.qml:
// a curved PathView carousel where the centred item is the "selected"
// one. Sliding left/right live-previews the wallpaper under the centred
// item (via Wallpapers.startPreview), exactly like caelestia does with
// Wallpapers.preview(). Unlike caelestia though - which commits the
// wallpaper on every single slide - nothing is actually applied here
// until you press Enter or click a thumbnail directly (see applyPath()).
//
// This talks to this project's own Wallpapers service
// (services/Wallpapers.qml), not caelestia's - the API differs
// (startPreview/stopPreview/select instead of preview/setWallpaper), so
// this is a fresh implementation of caelestia's *look* on top of our own
// existing wallpaper logic (the same logic LocalWallpaperGrid.qml uses).
Item {
    id: root

    required property PersistentProperties visibilities

    // ── Tune size here ──────────────────────────────────────────────
    // Sized to actually read as a carousel of wallpapers (like
    // caelestia's), not a row of tiny thumbnails - panelWidth derives
    // from these instead of being pinned to AppList/ClipboardList's 480,
    // so the whole launcher panel widens to fit while this mode is open
    // (Content.qml already sizes itself off currentList.panelWidth).
    readonly property int thumbWidth: 240
    readonly property int thumbHeight: Math.round(thumbWidth / 16 * 9)
    readonly property int itemWidth: thumbWidth + Appearance.dashboard.padding.normal * 2
    // Thumbnail + top offset + label + breathing room below.
    readonly property int itemHeight: thumbHeight + Appearance.dashboard.padding.large + Appearance.dashboard.spacing.small + Appearance.dashboard.padding.normal + 32
    // How many wallpapers are visible across the carousel at once - keep
    // this odd so one is always dead-centre.
    readonly property int numItems: 5
    readonly property int panelWidth: itemWidth * numItems
    // ─────────────────────────────────────────────────────────────────

    readonly property int count: pathView.count
    readonly property Item currentItem: pathView.currentItem

    // Flat list of image file paths in the wallpapers folder - kept in
    // sync with Wallpapers.folderModel, filtering out subdirectories
    // (this is a quick carousel, not a file browser - use the full
    // wallpaper selector for that).
    property var entries: []

    function refresh(): void {
        const arr = [];
        for (let i = 0; i < Wallpapers.folderModel.count; i++) {
            if (Wallpapers.folderModel.get(i, "fileIsDir"))
                continue;
            const path = Wallpapers.folderModel.get(i, "filePath");
            if (path && path.length > 0)
                arr.push(path);
        }
        root.entries = arr;
    }

    function positionAtCurrentWallpaper(): void {
        const idx = root.entries.indexOf(Config.options.background.wallpaperPath);
        pathView.currentIndex = idx >= 0 ? idx : 0;
    }

    // Applies whatever's currently centred - used when Enter is pressed.
    function applyCurrent(): void {
        root.applyPath(root.entries[pathView.currentIndex]);
    }

    // Applies a specific wallpaper - used when a thumbnail is clicked
    // directly, which may not be the one currently centred.
    function applyPath(path: string): void {
        if (!path || path.length === 0)
            return;
        // Stop preview FIRST so wallpaperPath reverts to the old
        // wallpaper, then select() sets confirmedPath to the new one -
        // same trick WallpaperSelectorContent.qml uses so the real
        // transition animation actually plays instead of being skipped
        // because the path "didn't change" (it was already showing as
        // the live preview).
        if (Config.options.background.enableWallpaperPreview)
            Wallpapers.stopPreview();
        Wallpapers.select(path);
        root.visibilities.wallpaper = false;
    }

    // Mirrors ListView's API so Content.qml can drive this exactly like
    // AppList/ClipboardList without needing to care which mode is active.
    function decrementCurrentIndex(): void {
        pathView.decrementCurrentIndex();
    }

    function incrementCurrentIndex(): void {
        pathView.incrementCurrentIndex();
    }

    // Refresh the entry list whenever the folder's contents actually
    // change...
    Connections {
        function onCountChanged(): void {
            root.refresh();
        }

        target: Wallpapers.folderModel
    }

    // ...and reset back to the default wallpapers folder + jump to
    // whatever's currently applied every time this mode is opened, so it
    // never opens up wherever the full grid selector last left off.
    Connections {
        function onWallpaperChanged(): void {
            if (root.visibilities.wallpaper) {
                Wallpapers.setDirectory(`${Directories.pictures}/Wallpapers`);
                root.refresh();
                root.positionAtCurrentWallpaper();
            } else {
                Wallpapers.stopPreview();
            }
        }

        target: root.visibilities
    }

    Component.onCompleted: root.refresh()
    Component.onDestruction: Wallpapers.stopPreview()

    implicitWidth: root.panelWidth
    implicitHeight: root.itemHeight

    PathView {
        id: pathView

        anchors.horizontalCenter: parent.horizontalCenter
        width: root.itemWidth * root.numItems
        height: root.itemHeight

        model: root.entries
        pathItemCount: root.numItems
        cacheItemCount: 5

        snapMode: PathView.SnapToItem
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange

        // This is the "auto preview while sliding" behaviour, copied
        // straight from caelestia's WallpaperList.qml (onCurrentItemChanged
        // -> Wallpapers.preview(...)). Nothing is committed here - just a
        // live preview of whatever's now centred.
        onCurrentIndexChanged: {
            const path = root.entries[currentIndex];
            if (path && Config.options.background.enableWallpaperPreview)
                Wallpapers.startPreview(path);
        }

        delegate: WallpaperItem {
            carousel: root
        }

        path: Path {
            startY: pathView.height / 2

            PathAttribute {
                name: "z"
                value: 0
            }
            PathLine {
                x: pathView.width / 2
                relativeY: 0
            }
            PathAttribute {
                name: "z"
                value: 1
            }
            PathLine {
                x: pathView.width
                relativeY: 0
            }
        }
    }
}
