pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.modules.wallpaper.items
import Quickshell
import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.services

Item {
    id: root

    required property PersistentProperties visibilities

    // ── Tune size here ──────────────────────────────────────────────
    readonly property int thumbWidth: 320
    readonly property int thumbHeight: Math.round(thumbWidth / 16 * 9)
    // Caelestia's exact formula: item spacing along the path is only 0.8x
    // the actual thumbnail width, not the full width + padding - that's
    // what makes neighbouring cards overlap into a fanned deck instead of
    // sitting in a plain, evenly-gapped row.
    readonly property int itemSpacing: Math.round(thumbWidth * 0.8) + Appearance.dashboard.padding.normal * 2
    readonly property int itemHeight: thumbHeight + Appearance.dashboard.padding.large + Appearance.dashboard.spacing.small + Appearance.dashboard.padding.normal + 32
    readonly property int numItems: 5
    readonly property int panelWidth: itemSpacing * numItems
    // ─────────────────────────────────────────────────────────────────

    readonly property int count: pathView.count
    readonly property Item currentItem: pathView.currentItem

    property string filterText: ""
    property var allEntries: []

    readonly property var entries: {
        const needle = root.filterText.trim().toLowerCase();
        if (needle.length === 0)
            return root.allEntries;
        return root.allEntries.filter(path => path.split("/").pop().toLowerCase().includes(needle));
    }

    function refresh(): void {
        const arr = [];
        for (let i = 0; i < Wallpapers.folderModel.count; i++) {
            if (Wallpapers.folderModel.get(i, "fileIsDir"))
                continue;
            const path = Wallpapers.folderModel.get(i, "filePath");
            if (path && path.length > 0)
                arr.push(path);
        }
        root.allEntries = arr;
    }

    onFilterTextChanged: pathView.currentIndex = 0

    function positionAtCurrentWallpaper(): void {
        const idx = root.entries.indexOf(Config.options.background.wallpaperPath);
        pathView.currentIndex = idx >= 0 ? idx : 0;
    }

    function applyCurrent(): void {
        root.applyPath(root.entries[pathView.currentIndex]);
    }

    function applyPath(path: string): void {
        if (!path || path.length === 0)
            return;
        if (Config.options.background.enableWallpaperPreview)
            Wallpapers.stopPreview();
        Wallpapers.select(path);
        root.visibilities.wallpaper = false;
    }

    function decrementCurrentIndex(): void {
        pathView.decrementCurrentIndex();
    }

    function incrementCurrentIndex(): void {
        pathView.incrementCurrentIndex();
    }

    Connections {
        function onCountChanged(): void {
            root.refresh();
        }

        target: Wallpapers.folderModel
    }

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
        width: root.itemSpacing * root.numItems
        height: root.itemHeight

        model: root.entries
        pathItemCount: root.numItems
        cacheItemCount: 5

        snapMode: PathView.SnapToItem
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange

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
