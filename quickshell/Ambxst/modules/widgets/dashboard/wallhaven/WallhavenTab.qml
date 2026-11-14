import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

FocusScope {
    id: root

    // ── Core state ──────────────────────────────────────────────────────────
    property string searchQuery:    ""
    property string activeCategory: "toplist"
    property int    currentPage:    1
    property int    selectedIndex:  -1
    property string downloadingId:  ""   // ID being previewed right now
    property string savingId:       ""   // ID being permanently downloaded
    property string downloadError:  ""

    // currentPreview = { id, url, ext, slot } of the active slot.
    // Persisted in JSON so it survives tab close/reopen.
    property var    currentPreview: null

    // { "<id>": true } — IDs that have been permanently downloaded
    property var    savedIds: ({})

    // Which slot (1 or 2) holds the current wallpaper. 0 = nothing set yet.
    // We alternate slots on every new preview so the path always changes,
    // forcing quickshell to actually reload the wallpaper display.
    property int    activeSlot: 0

    readonly property int    gridColumns: 4
    readonly property string saveDir:     "/home/goutam/Pictures/Wallpapers/Wallheaven"

    // JSON next to this QML file — stores preview + activeSlot + saved set
    readonly property string configDir:  Qt.resolvedUrl(".").toString().replace("file://", "")
    readonly property string savedJson:  configDir + "wallhaven_saved.json"

    // ── Toast ────────────────────────────────────────────────────────────────
    property string toastMessage: ""
    property bool   toastVisible: false

    function showToast(msg) {
        toastMessage = msg;
        toastVisible = true;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer; interval: 4000; repeat: false
        onTriggered: root.toastVisible = false
    }

    // ── Focus ────────────────────────────────────────────────────────────────
    function focusSearchInput() { searchInput.focusInput(); }

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => searchInput.focusInput());
            if (Wallhaven.wallpapers.length === 0 && !Wallhaven.loading)
                Wallhaven.fetchWallpapers("toplist", "", 1);
        }
    }

    Component.onCompleted: {
        loadJson();   // populates currentPreview + savedIds from disk
        if (Wallhaven.wallpapers.length === 0 && !Wallhaven.loading)
            Wallhaven.fetchWallpapers("toplist", "", 1);
    }

    // ── JSON ─────────────────────────────────────────────────────────────────
    // Schema: { "activeSlot": 0|1|2, "preview": {id,url,ext,slot}|null,
    //           "saved": ["id1","id2",...] }

    function loadJson() {
        const p = loadJsonProc.createObject(root);
        p.running = true;
    }

    function writeJson() {
        const preview = root.currentPreview
        ? JSON.stringify(root.currentPreview)
        : "null";
        const saved = JSON.stringify(Object.keys(root.savedIds));
        const json  = '{"activeSlot":' + root.activeSlot +
        ',"preview":' + preview +
        ',"saved":' + saved + '}';
        const esc  = json.replace(/\\/g, "\\\\").replace(/'/g, "'\"'\"'");
        const out  = root.savedJson.replace(/'/g, "'\"'\"'");
        const dir  = root.configDir.replace(/'/g, "'\"'\"'");
        const p = writeJsonProc.createObject(root, {
            "command": ["bash", "-c",
            "mkdir -p '" + dir + "' && printf '%s' '" + esc + "' > '" + out + "'"]
        });
        p.running = true;
    }

    Component {
        id: loadJsonProc
        Process {
            running: false
            command: ["bash", "-c",
            "[ -f '" + root.savedJson + "' ] && cat '" + root.savedJson + "' || echo '{}'"]
            stdout: StdioCollector {
                id: lc
                onStreamFinished: {
                    try {
                        const obj = JSON.parse(lc.text.trim() || "{}");
                        // Restore slot counter
                        const slot = parseInt(obj.activeSlot) || 0;
                        root.activeSlot = (slot === 1 || slot === 2) ? slot : 0;
                        // Restore currentPreview
                        root.currentPreview = obj.preview || null;
                        // Restore savedIds
                        const map = {};
                        (obj.saved || []).forEach(id => { map[id] = true; });
                        root.savedIds = map;
                        console.log("[WallhavenTab] JSON loaded — slot:", root.activeSlot,
                                    "preview:", root.currentPreview ? root.currentPreview.id : "none",
                                    "saved:", Object.keys(map).length);
                    } catch(e) {
                        console.warn("[WallhavenTab] JSON load error:", e);
                    }
                }
            }
            onExited: destroy()
        }
    }

    Component {
        id: writeJsonProc
        Process { running: false; onExited: destroy() }
    }

    Component {
        id: deleteProc
        Process { running: false; onExited: destroy() }
    }

    Timer { id: errorTimer; interval: 4000; repeat: false; onTriggered: root.downloadError = "" }

    // ── Preview download (alternates wallpaper1.<ext> / wallpaper2.<ext>) ────
    Component {
        id: previewProc
        Process {
            property string destPath:    ""
            property int    nextSlot:    1
            property var    previewInfo: null
            running: false

            onExited: (code, _) => {
                if (code === 0 && previewInfo) {
                    root.activeSlot = nextSlot;
                    if (GlobalStates.wallpaperManager) {
                        const mgr   = GlobalStates.wallpaperManager;
                        // Inject path so setWallpaper finds it immediately
                        // without waiting for the next directory rescan.
                        const paths = mgr.wallpaperPaths.slice();
                        if (paths.indexOf(destPath) === -1) {
                            paths.push(destPath);
                            mgr.wallpaperPaths = paths;
                        }
                        mgr.setWallpaper(destPath);
                    }
                    root.currentPreview = previewInfo;
                    writeJson();
                } else if (code !== 0) {
                    root.downloadError = "Preview failed (curl exit " + code + ")";
                    errorTimer.restart();
                }
                root.downloadingId = "";
                destroy();
            }
        }
    }

    // ── Permanent download (wallhaven-<id>.<ext>) ────────────────────────────
    Component {
        id: permanentProc
        Process {
            property string wallId: ""
            running: false
            onExited: (code, _) => {
                if (code === 0) {
                    const map = Object.assign({}, root.savedIds);
                    map[wallId] = true;
                    root.savedIds = map;
                    writeJson();
                    showToast("Saved permanently ✓");
                } else {
                    root.downloadError = "Download failed (exit " + code + ")";
                    errorTimer.restart();
                }
                root.savingId = "";
                destroy();
            }
        }
    }

    // ── Main functions ───────────────────────────────────────────────────────

    // Click on a thumbnail → download to the INACTIVE slot so the path always
    // changes, guaranteeing quickshell reloads the wallpaper display.
    //
    // Slot cycling:   active=0 → next=1 → active=1 → next=2 → active=2 → next=1 …
    // File naming:    wallpaper1.<ext>  /  wallpaper2.<ext>
    // Before the mv we delete all wallpaperN.* for that slot (format-agnostic).
    function downloadAndSet(wallpaper) {
        if (root.downloadingId !== "" || root.savingId !== "") return;

        // Already permanently saved → apply that file directly
        if (root.savedIds[wallpaper.id]) {
            const ext  = wallpaper.path.split('.').pop().toLowerCase() || "jpg";
            const perm = root.saveDir + "/wallhaven-" + wallpaper.id + "." + ext;
            if (GlobalStates.wallpaperManager) {
                const mgr   = GlobalStates.wallpaperManager;
                const paths = mgr.wallpaperPaths.slice();
                if (paths.indexOf(perm) === -1) {
                    paths.push(perm);
                    mgr.wallpaperPaths = paths;
                }
                mgr.setWallpaper(perm);
            }
            return;
        }

        const ext      = wallpaper.path.split('.').pop().toLowerCase() || "jpg";
        // Determine which slot to write into next (the one NOT currently active)
        const nextSlot = (root.activeSlot === 1) ? 2 : 1;
        const dest     = root.saveDir + "/wallpaper" + nextSlot + "." + ext;
        const tmp      = "/tmp/wallhaven_preview_" + wallpaper.id + "." + ext;

        root.downloadingId = wallpaper.id;
        root.downloadError = "";

        const info = { id: wallpaper.id, url: wallpaper.path, ext: ext, slot: nextSlot };

        const p = previewProc.createObject(root, {
            "destPath":    dest,
            "nextSlot":    nextSlot,
            "previewInfo": info,
            "command": ["bash", "-c",
            // 1. Ensure save dir exists
            "mkdir -p '" + root.saveDir + "'" +
            // 2. Download to /tmp — current wallpaper stays untouched during flight
            " && curl -L -s -o '" + tmp + "' '" + wallpaper.path + "'" +
            // 3. After curl succeeds: wipe the target slot (any format) then move in
            " && find '" + root.saveDir + "' -maxdepth 1 -name 'wallpaper" + nextSlot + ".*' -delete" +
            " && mv '" + tmp + "' '" + dest + "'"]
        });
        p.running = true;
    }

    // Download button → permanently save full-res using the URL stored in JSON
    function downloadPermanent() {
        if (!root.currentPreview) return;
        if (root.savingId !== "" || root.downloadingId !== "") return;

        const info = root.currentPreview;
        if (root.savedIds[info.id]) { showToast("Already saved permanently"); return; }

        const dest = root.saveDir + "/wallhaven-" + info.id + "." + info.ext;
        const tmp  = "/tmp/wallhaven_perm_" + info.id + "." + info.ext;
        root.savingId = info.id;

        const p = permanentProc.createObject(root, {
            "wallId":  info.id,
            "command": ["bash", "-c",
            "mkdir -p '" + root.saveDir + "'" +
            " && curl -L -s -o '" + tmp + "' '" + info.url + "'" +
            " && mv '" + tmp + "' '" + dest + "'"]
        });
        p.running = true;
    }

    // ════════════════════════════════════════════════════════════════════════
    // UI
    // ════════════════════════════════════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // ── TOOLBAR ──────────────────────────────────────────────────────────
        // Layout: [←] [page#] [→]  [search]  [Top][Latest][Random]  [↺]  [Download]
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 4
            z: 100

            // ── Prev page ─────────────────────────────────────────────────
            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 36
                StyledRect {
                    anchors.fill: parent
                    radius: Styling.radius(4)
                    variant: "pane"
                    opacity: root.currentPage > 1 ? 1.0 : 0.35
                    Text {
                        anchors.centerIn: parent
                        text: Icons.arrowLeft || ""
                        font.family: Icons.font
                        font.pixelSize: 13
                        color: Colors.overSurface
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.currentPage > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: root.currentPage > 1 && !Wallhaven.loading
                        onClicked: {
                            root.currentPage--;
                            root.selectedIndex = -1;
                            const cat = root.activeCategory;
                            Wallhaven.fetchWallpapers(cat, cat === "search" ? root.searchQuery : "", root.currentPage);
                            wallpaperGrid.positionViewAtBeginning();
                        }
                    }
                }
            }

            // ── Page number ────────────────────────────────────────────────
            Text {
                text: root.currentPage
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                color: Colors.outline
                horizontalAlignment: Text.AlignHCenter
                // Fixed width so the arrows don't jump around
                Layout.preferredWidth: 28
            }

            // ── Next page / loading spinner ────────────────────────────────
            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 36
                StyledRect {
                    anchors.fill: parent
                    radius: Styling.radius(4)
                    variant: "pane"

                    Text {
                        anchors.centerIn: parent
                        text: Icons.arrowRight || ""
                        font.family: Icons.font
                        font.pixelSize: 13
                        color: Colors.overSurface
                        visible: !Wallhaven.loading
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Icons.circleNotch || ""
                        font.family: Icons.font
                        font.pixelSize: 13
                        color: Colors.outline
                        visible: Wallhaven.loading
                        NumberAnimation on rotation {
                            from: 0; to: 360; duration: 700
                            loops: Animation.Infinite; running: Wallhaven.loading
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !Wallhaven.loading
                        onClicked: {
                            root.currentPage++;
                            root.selectedIndex = -1;
                            const cat = root.activeCategory;
                            Wallhaven.fetchWallpapers(cat, cat === "search" ? root.searchQuery : "", root.currentPage);
                            wallpaperGrid.positionViewAtBeginning();
                        }
                    }
                }
            }

            // ── Search ────────────────────────────────────────────────────
            SearchInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                placeholderText: "Search Wallhaven..."
                iconText: ""
                clearOnEscape: false
                radius: Styling.radius(4)
                onSearchTextChanged: text => { root.searchQuery = text; }
                onAccepted: {
                    if (root.searchQuery.trim().length > 0) {
                        root.activeCategory = "search";
                        root.currentPage    = 1;
                        Wallhaven.fetchWallpapers("search", root.searchQuery, 1);
                    }
                }
                onEscapePressed: Visibilities.setActiveModule("");
            }

            // ── Category chips ────────────────────────────────────────────
            Repeater {
                model: [
                    { id: "toplist", label: "Top",    icon: Icons.trophy  || "" },
                    { id: "latest",  label: "Latest", icon: Icons.clock   || "" },
                    { id: "random",  label: "Random", icon: Icons.shuffle || "" }
                ]

                delegate: Item {
                    required property var  modelData
                    required property int  index
                    readonly property bool isActive: root.activeCategory === modelData.id

                    Layout.preferredWidth:  chipRow.implicitWidth + 16
                    Layout.preferredHeight: 36

                    Behavior on Layout.preferredWidth {
                        NumberAnimation { duration: Config.animDuration / 3; easing.type: Easing.OutCubic }
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: Styling.radius(isActive ? 2 : 4)
                        variant: isActive ? "primary" : "pane"

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: modelData.icon
                                font.family: Icons.font
                                font.pixelSize: 12
                                color: parent.parent.isActive
                                ? Styling.srItem("overprimary")
                                : Colors.overSurfaceVariant
                                visible: modelData.icon !== ""
                                Behavior on color { ColorAnimation { duration: Config.animDuration / 3 } }
                            }
                            Text {
                                text: modelData.label
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                color: parent.parent.isActive
                                ? Styling.srItem("overprimary")
                                : Colors.overSurface
                                Behavior on color { ColorAnimation { duration: Config.animDuration / 3 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeCategory = modelData.id;
                                root.currentPage    = 1;
                                root.selectedIndex  = -1;
                                Wallhaven.fetchWallpapers(modelData.id, "", 1);
                            }
                        }
                    }
                }
            }

            // ── Refresh ───────────────────────────────────────────────────
            Item {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                StyledRect {
                    anchors.fill: parent
                    radius: Styling.radius(4)
                    variant: "pane"

                    Text {
                        anchors.centerIn: parent
                        text: Icons.circleNotch || ""
                        font.family: Icons.font
                        font.pixelSize: 15
                        color: Wallhaven.loading ? Colors.outline : Colors.overSurface
                        NumberAnimation on rotation {
                            from: 0; to: 360; duration: 900
                            loops: Animation.Infinite; running: Wallhaven.loading
                        }
                        Behavior on color { ColorAnimation { duration: Config.animDuration / 2 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (root.activeCategory === "search" && root.searchQuery.trim().length > 0)
                                Wallhaven.fetchWallpapers("search", root.searchQuery, root.currentPage);
                            else
                                Wallhaven.fetchWallpapers(root.activeCategory, "", root.currentPage);
                        }
                    }
                }
            }

            // ── Download button ───────────────────────────────────────────
            // Always visible on the toolbar. Reads currentPreview from JSON (loaded
            // on startup) so it works even after the tab was closed and reopened.
            // Disabled and dimmed when there is no currentPreview yet.
            Item {
                Layout.preferredWidth: dlRow.implicitWidth + 20
                Layout.preferredHeight: 36

                StyledRect {
                    anchors.fill: parent
                    radius: Styling.radius(4)

                    // primary = already saved, pane = available, dim pane = nothing to save
                    variant: {
                        if (root.currentPreview && root.savedIds[root.currentPreview.id])
                            return "primary";
                        return "pane";
                    }

                    opacity: root.currentPreview ? 1.0 : 0.35

                    RowLayout {
                        id: dlRow
                        anchors.centerIn: parent
                        spacing: 6

                        // Spinner while saving
                        Text {
                            text: Icons.circleNotch || ""
                            font.family: Icons.font
                            font.pixelSize: 13
                            color: Colors.outline
                            visible: root.savingId !== ""
                            NumberAnimation on rotation {
                                from: 0; to: 360; duration: 700
                                loops: Animation.Infinite; running: root.savingId !== ""
                            }
                        }

                        Text {
                            text: Icons.arrowDown || ""
                            font.family: Icons.font
                            font.pixelSize: 13
                            visible: root.savingId === ""
                            color: (root.currentPreview && root.savedIds[root.currentPreview.id])
                            ? Styling.srItem("overprimary") : Colors.overSurface
                        }

                        Text {
                            text: (root.currentPreview && root.savedIds[root.currentPreview.id])
                            ? "Saved" : "Download"
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize
                            visible: root.savingId === ""
                            color: (root.currentPreview && root.savedIds[root.currentPreview.id])
                            ? Styling.srItem("overprimary") : Colors.overSurface
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.currentPreview ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: root.currentPreview !== null
                        && root.savingId === ""
                        && root.downloadingId === ""
                        && !(root.currentPreview && root.savedIds[root.currentPreview.id])
                        onClicked: root.downloadPermanent()
                    }
                }
            }
        }

        // ── Error banner ──────────────────────────────────────────────────────
        StyledRect {
            Layout.fillWidth: true
            variant: "pane"
            radius: Styling.radius(2)
            clip: true
            readonly property bool hasError: root.downloadError !== "" || Wallhaven.errorMessage !== ""
            Layout.preferredHeight: hasError ? 32 : 0
            visible: Layout.preferredHeight > 0
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
            }
            RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 6
                Text {
                    text: Icons.warning || ""
                    font.family: Icons.font; font.pixelSize: 13; color: Colors.error
                }
                Text {
                    Layout.fillWidth: true
                    text: root.downloadError !== "" ? root.downloadError : Wallhaven.errorMessage
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    color: Colors.error; elide: Text.ElideRight
                }
            }
        }

        // ── Grid ──────────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading spinner (first load)
            ColumnLayout {
                anchors.centerIn: parent; spacing: 12
                visible: Wallhaven.loading && Wallhaven.wallpapers.length === 0
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Config.animDuration / 2 } }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Icons.circleNotch || ""
                    font.family: Icons.font; font.pixelSize: 32; color: Colors.overSurfaceVariant
                    NumberAnimation on rotation {
                        from: 0; to: 360; duration: 900
                        loops: Animation.Infinite; running: parent.visible
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Fetching wallpapers…"
                    font.family: Config.theme.font; font.pixelSize: Config.theme.fontSize
                    color: Colors.outline
                }
            }

            GridView {
                id: wallpaperGrid
                anchors.fill: parent
                visible: Wallhaven.wallpapers.length > 0
                clip: true

                cellWidth:  Math.floor(width / root.gridColumns)
                cellHeight: Math.floor(cellWidth * 9 / 16)

                model: Wallhaven.wallpapers
                cacheBuffer: cellHeight * 3

                property bool isScrolling: false
                onMovementStarted: isScrolling = true
                onMovementEnded:   isScrolling = false

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        color: Styling.srItem("overprimary"); radius: Styling.radius(0)
                    }
                    background: Rectangle { color: "transparent" }
                }

                delegate: Rectangle {
                    id: cell
                    width: wallpaperGrid.cellWidth; height: wallpaperGrid.cellHeight
                    color: "transparent"

                    required property var  modelData
                    required property int  index

                    readonly property bool isDownloading:    root.downloadingId === modelData.id
                    readonly property bool isSaved:          root.savedIds[modelData.id] === true
                    readonly property bool isCurrentPreview: root.currentPreview !== null
                    && root.currentPreview.id === modelData.id
                    readonly property bool isSelected:       root.selectedIndex === index
                    property bool          isHovered:        false

                    Item {
                        anchors.fill: parent; anchors.margins: 2

                        ClippingRectangle {
                            anchors.fill: parent
                            color: Colors.surface; radius: Styling.radius(3)

                            Image {
                                id: thumbImage
                                anchors.fill: parent
                                source: modelData.thumbs.large || modelData.thumbs.original || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true; smooth: true; mipmap: true; cache: true

                                Rectangle {
                                    id: placeholder
                                    anchors.fill: parent; color: Colors.surface
                                    visible: thumbImage.status !== Image.Ready
                                    Text {
                                        anchors.centerIn: parent
                                        text: Icons.circleNotch || ""
                                        font.family: Icons.font; font.pixelSize: 18
                                        color: Colors.overSurfaceVariant
                                        NumberAnimation on rotation {
                                            from: 0; to: 360; duration: 900
                                            loops: Animation.Infinite; running: placeholder.visible
                                        }
                                    }
                                }
                            }

                            // Hover / selection ring
                            Rectangle {
                                anchors.fill: parent; color: "transparent"
                                radius: Styling.radius(3)
                                border.width: cell.isSelected ? 2 : (cell.isHovered ? 1 : 0)
                                border.color: cell.isSelected
                                ? Styling.srItem("overprimary")
                                : Qt.rgba(1, 1, 1, 0.35)
                                Behavior on border.width {
                                    NumberAnimation { duration: Config.animDuration / 4 }
                                }
                            }

                            // Active-preview ring (primary colour, 2px)
                            Rectangle {
                                anchors.fill: parent; color: "transparent"
                                radius: Styling.radius(3)
                                border.width: cell.isCurrentPreview ? 2 : 0
                                border.color: Colors.primary
                                visible: cell.isCurrentPreview
                            }

                            // Permanently saved badge (top-right)
                            Rectangle {
                                anchors.top: parent.top; anchors.right: parent.right
                                anchors.margins: 4
                                width: 20; height: 20; radius: 10
                                color: Qt.rgba(0, 0, 0, 0.6)
                                visible: cell.isSaved
                                Text {
                                    anchors.centerIn: parent
                                    text: Icons.check || ""
                                    font.family: Icons.font; font.pixelSize: 10
                                    color: Styling.srItem("overprimary")
                                }
                            }

                            // Downloading overlay
                            Rectangle {
                                anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.55)
                                visible: cell.isDownloading; radius: Styling.radius(3)
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 6
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Icons.circleNotch || ""
                                        font.family: Icons.font; font.pixelSize: 22; color: "white"
                                        NumberAnimation on rotation {
                                            from: 0; to: 360; duration: 700
                                            loops: Animation.Infinite; running: cell.isDownloading
                                        }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter; text: "Setting…"
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2); color: "white"
                                    }
                                }
                            }

                            // Bottom info bar (hover/selected)
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 28
                                color: Qt.rgba(0, 0, 0, 0.62); radius: Styling.radius(3)
                                opacity: cell.isHovered || cell.isSelected ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity {
                                    NumberAnimation { duration: Config.animDuration / 3 }
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 6
                                    Text {
                                        text: modelData.resolution || ""
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-2)
                                        color: "white"; opacity: 0.85
                                    }
                                    Item { Layout.fillWidth: true }
                                    RowLayout {
                                        spacing: 3; visible: modelData.favorites > 0
                                        Text {
                                            text: Icons.heart || ""
                                            font.family: Icons.font; font.pixelSize: 10
                                            color: "white"; opacity: 0.75
                                        }
                                        Text {
                                            text: modelData.favorites > 999
                                            ? (Math.floor(modelData.favorites / 1000) + "k")
                                            : modelData.favorites
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(-2)
                                            color: "white"; opacity: 0.85
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Behavior on scale {
                        NumberAnimation { duration: Config.animDuration / 4; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: !wallpaperGrid.isScrolling
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (!wallpaperGrid.isScrolling) {
                                cell.isHovered = true; root.selectedIndex = index;
                            }
                        }
                        onExited:   { cell.isHovered = false; }
                        onPressed:  { if (!wallpaperGrid.isScrolling) cell.scale = 0.93; }
                        onReleased: { cell.scale = 1.0; }
                        onClicked: {
                            if (wallpaperGrid.isScrolling || root.downloadingId !== "") return;
                            root.downloadAndSet(modelData);
                        }
                    }
                }
            }
        }
        // (no bottom page indicator — page number is now between the arrows in the toolbar)
    }

    // ── Toast ─────────────────────────────────────────────────────────────────
    Item {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 10
        width: toastCard.width; height: toastCard.height; z: 999

        opacity: root.toastVisible ? 1 : 0
        visible: opacity > 0

        transform: Translate {
            y: root.toastVisible ? 0 : 14
            Behavior on y {
                NumberAnimation { duration: Config.animDuration * 0.6; easing.type: Easing.OutCubic }
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: Config.animDuration * 0.5; easing.type: Easing.OutCubic }
        }

        StyledRect {
            id: toastCard
            variant: "pane"; radius: Styling.radius(4); height: 36
            width: toastRow.implicitWidth + 28

            RowLayout {
                id: toastRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8

                Text {
                    text: Icons.eye || ""; font.family: Icons.font
                    font.pixelSize: 12; color: Colors.outline
                }
                Text {
                    text: root.toastMessage; font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1); color: Colors.outline
                }
                Text {
                    text: Icons.xmark || Icons.close || "×"
                    font.family: Icons.font; font.pixelSize: 11; color: Colors.overSurfaceVariant
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.toastVisible = false; toastTimer.stop(); }
                    }
                }
            }

            Rectangle {
                id: toastProgressBg
                anchors.bottom: parent.bottom; anchors.left: parent.left
                anchors.right: parent.right; anchors.margins: 2
                height: 2; radius: 1; color: Colors.surface

                Rectangle {
                    id: toastProgress
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    radius: 1; color: Styling.srItem("overprimary"); width: toastProgressBg.width
                    NumberAnimation on width {
                        id: progressShrink; running: false; to: 0
                        duration: toastTimer.interval; easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    onToastVisibleChanged: {
        if (toastVisible) {
            toastProgress.width = toastProgressBg.width;
            progressShrink.from = toastProgressBg.width;
            progressShrink.restart();
        } else {
            progressShrink.stop();
        }
    }
}
