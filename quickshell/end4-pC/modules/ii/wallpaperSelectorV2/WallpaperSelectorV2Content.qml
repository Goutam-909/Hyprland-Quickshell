import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

// Carousel-only: no grid style, no toggle, no visible buttons, no
// folder-name label - just the dim+blur backdrop (LauncherWindow.qml's
// Theme.surface @ Settings.dimOpacity) and the carousel itself.
// Close is still available (Escape), it just isn't a drawn button, same
// as SettingsPane.qml/WallpapersPage_other.qml never draw one either.
//
// Wallpaper logic is unchanged: everything goes through the existing
// Wallpapers service (setDirectory/select/preview/random).
MouseArea {
    id: root

    signal requestClose()

    property bool useDarkMode: Appearance.m3colors.darkmode

    // Theme.surface/dimOpacity, ported as literals - this dim backdrop
    // isn't tied to the shell's own light/dark palette.
    readonly property color dimSurface: "#0a0908"
    readonly property real dimOpacity: 0.4

    property var walls: []
    property int currentIndex: 0
    // Only true once we've tried to land on the currently-applied
    // wallpaper - after that, further folderModel updates (e.g. thumbnail
    // generation ticking `count`) must not yank the selection back.
    property bool initialSelectionDone: false

    function rebuildWalls() {
        const model = Wallpapers.folderModel;
        const out = [];
        if (model) {
            for (let i = 0; i < model.count; i++) {
                if (model.get(i, "fileIsDir")) continue;
                out.push({
                    filePath: model.get(i, "filePath"),
                    fileName: model.get(i, "fileName")
                });
            }
        }
        root.walls = out;
        root.currentIndex = Math.min(root.currentIndex, Math.max(0, out.length - 1));

        if (!root.initialSelectionDone && out.length > 0) {
            // Config.options.background.wallpaperPath is the path the
            // shell currently has applied - same source the blurred
            // backdrop below reads from - so the carousel opens centered
            // on what's actually on screen instead of always at index 0.
            const current = Config.options.background.wallpaperPath;
            if (current) {
                const idx = out.findIndex(w => w.filePath === current || w.filePath === `file://${current}`);
                if (idx >= 0)
                    root.currentIndex = idx;
            }
            root.initialSelectionDone = true;
        }
    }

    Connections {
        target: Wallpapers
        function onFolderModelChanged() { root.rebuildWalls() }
    }
    Connections {
        target: Wallpapers.folderModel
        function onCountChanged() { root.rebuildWalls() }
    }
    Component.onCompleted: {
        // Wallpapers.directory is shared with the original selector - only
        // seed a default if nothing's been picked yet, so this never
        // clobbers wherever the original selector left off.
        if (!Wallpapers.directory || Wallpapers.directory === "")
            Wallpapers.setDirectory(`${Directories.pictures}/Wallpapers`);
        root.rebuildWalls();
    }

    function confirmWallpaper(filePath) {
        if (!filePath || filePath.length === 0) return;
        if (Config.options.background.enableWallpaperPreview)
            Wallpapers.stopPreview();
        Wallpapers.select(filePath, root.useDarkMode);
        if (Config.options.wallpaperSelector.closeAfterSelection)
            root.requestClose();
    }

    function previewWallpaper(filePath) {
        if (filePath && Config.options.background.enableWallpaperPreview)
            Wallpapers.startPreview(filePath);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Wallpapers.stopPreview();
            root.requestClose();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            carousel.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            carousel.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            carousel.activateCurrent();
            event.accepted = true;
        } else if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
            Wallpapers.randomFromCurrentFolder();
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    focus: true

    // ─── "xray" backdrop: blurred current wallpaper, dimmed ───
    Image {
        id: bgSource
        anchors.fill: parent
        source: Config.options.background.wallpaperPath ? `file://${Config.options.background.wallpaperPath}` : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        cache: true
    }
    FastBlur {
        anchors.fill: parent
        source: bgSource
        radius: 64
        visible: bgSource.status === Image.Ready
    }
    Rectangle {
        anchors.fill: parent
        color: root.dimSurface
        opacity: root.dimOpacity
    }

    // ─── The ported carousel itself ───
    WallpaperCarouselV2 {
        id: carousel
        anchors.fill: parent
        walls: root.walls
        currentIndex: root.currentIndex
        onCurrentIndexChanged: root.currentIndex = currentIndex
        onWallpaperPreviewed: path => root.previewWallpaper(path)
        onWallpaperActivated: path => root.confirmWallpaper(path)
    }

    // Plain text, matching the source's own empty state exactly:
    // Theme.muted color, no card, no icon.
    StyledText {
        anchors.centerIn: parent
        visible: root.walls.length === 0
        text: Translation.tr("no wallpapers found")
        color: Qt.alpha(Appearance.colors.colOnLayer0, 0.55)
    }
}
