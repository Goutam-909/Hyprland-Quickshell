pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.theme
import qs.modules.components

Item {
    id: root

    // ── Instance data ─────────────────────────────────────────────────────────
    property int instanceIndex: 0

    // Bound to modelData from Desktop.qml — NEVER assign directly here or the
    // binding breaks. Use patchConfig() which emits instanceSettingsChanged and
    // lets the parent push the updated object back through modelData.
    property var instanceConfig: ({})

    // ── Signals ───────────────────────────────────────────────────────────────
    signal moved(int idx, real nx, real ny, bool fromBottom)
    signal resized(int idx, real nw, real nh)
    signal duplicateRequested(int idx)
    signal deleteRequested(int idx)
    signal instanceSettingsChanged(int idx, var settings)

    // ── Per-instance settings (fall back to global Config) ────────────────────
    readonly property real visualizerIntensity: instanceConfig.intensity   ?? Config.desktop.cavaVisualizerIntensity ?? 1.0
    readonly property int  barCount:            instanceConfig.barCount    ?? Config.desktop.cavaBarCount ?? 40
    readonly property bool showShadow:          instanceConfig.showShadow  ?? Config.desktop.cavaShowShadow ?? true
    readonly property bool useWallpaperColors:  instanceConfig.wallpaper   ?? Config.desktop.cavaWallpaperColors ?? false
    readonly property int  widgetRotation:      instanceConfig.rotation    ?? Config.desktop.cavaRotation ?? 0
    readonly property real widgetOpacity:       instanceConfig.opacity     ?? Config.desktop.cavaOpacity ?? 1.0

    readonly property color gradientStart: instanceConfig.gradientStart ?? Config.desktop.cavaGradientStart ?? "#4158D0"
    readonly property color gradientMid1:  instanceConfig.gradientMid1  ?? Config.desktop.cavaGradientMid1  ?? "#C850C0"
    readonly property color gradientMid2:  instanceConfig.gradientMid2  ?? Config.desktop.cavaGradientMid2  ?? "#FFCC70"
    readonly property color gradientEnd:   instanceConfig.gradientEnd   ?? Config.desktop.cavaGradientEnd   ?? "#ffe53b"

    // ── Patch one key and signal parent — does NOT break instanceConfig binding
    function patchConfig(key, value) {
        let c = JSON.parse(JSON.stringify(root.instanceConfig));
        c[key] = value;
        root.instanceSettingsChanged(root.instanceIndex, c);
    }

    function getGradientColor(i) {
        if (useWallpaperColors) {
            switch (i) {
                case 0: return Colors.primary
                case 1: return Colors.secondary
                case 2: return Colors.tertiary
                case 3: return Colors.primaryContainer
                default: return Colors.primary
            }
        }
        switch (i) {
            case 0: return gradientStart
            case 1: return gradientMid1
            case 2: return gradientMid2
            case 3: return gradientEnd
            default: return gradientStart
        }
    }

    // ── State ─────────────────────────────────────────────────────────────────
    property real dragDeltaX: 0
    property real dragDeltaY: 0
    property bool isDragging: false
    property real resizeStartW: 0
    property real resizeStartH: 0
    property bool showSettings: false
    property bool showControls: false

    onBarCountChanged: {
        cavaProc.running = false;
        cavaProc.running = true;
    }

    // ── Right-click toggles controls ──────────────────────────────────────────
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.showControls = !root.showControls
    }

    // ── Left-click drag anywhere on widget = MOVE ─────────────────────────────
    DragHandler {
        id: moveHandler
        target: null
        acceptedButtons: Qt.LeftButton

        onActiveChanged: {
            if (active) {
                root.isDragging = true;
                root.showControls = false;
                root.dragDeltaX = 0;
                root.dragDeltaY = 0;
            } else {
                root.isDragging = false;
                root.moved(root.instanceIndex, root.x, root.y, false);
                root.dragDeltaX = 0;
                root.dragDeltaY = 0;
            }
        }

        onTranslationChanged: {
            root.dragDeltaX = translation.x;
            root.dragDeltaY = translation.y;
        }
    }

    // ── Cava process ──────────────────────────────────────────────────────────
    Process {
        id: cavaProc
        running: root.visible

        command: ["sh", "-c",
        "cfg=$(mktemp) && cat > \"$cfg\" <<'CAVAEOF'\n" +
        "[general]\n" +
        "bars = " + root.barCount + "\n" +
        "framerate = 60\n" +
        "autosens = 1\n\n" +
        "[input]\n" +
        "method = pulse\n\n" +
        "[output]\n" +
        "method = raw\n" +
        "raw_target = /dev/stdout\n" +
        "data_format = ascii\n" +
        "ascii_max_range = 1000\n" +
        "bar_delimiter = 59\n\n" +
        "[smoothing]\n" +
        "monstercat = 1.5\n" +
        "waves = 0\n" +
        "gravity = 100\n" +
        "noise_reduction = 0.20\n\n" +
        "[eq]\n1=1\n2=1\n3=1\n4=1\n5=1\n" +
        "CAVAEOF\n" +
        "cava -p \"$cfg\"; rm -f \"$cfg\""
        ]

        stdout: SplitParser {
            onRead: data => {
                let pts = data.split(";")
                .map(p => parseFloat(p.trim()) / 1000)
                .filter(p => !isNaN(p));
                if (pts.length < 2) return;
                const sf = 0.3;
                if (canvas.cavaData.length !== pts.length) {
                    canvas.cavaData = pts;
                } else {
                    let sm = [];
                    for (let i = 0; i < pts.length; i++)
                        sm.push(canvas.cavaData[i] + (pts[i] - canvas.cavaData[i]) * sf);
                    canvas.cavaData = sm;
                }
                canvas.requestPaint();
            }
        }
    }

    // ── Canvas ────────────────────────────────────────────────────────────────
    Canvas {
        id: canvas
        anchors.fill: parent
        opacity: root.widgetOpacity
        rotation: root.widgetRotation

        property var cavaData: []

        onPaint: {
            var ctx = getContext('2d');
            ctx.clearRect(0, 0, width, height);
            if (root.showShadow) drawWave(ctx, cavaData, true);
            drawWave(ctx, cavaData, false);
        }

        function drawWave(ctx, data, isShadow) {
            if (data.length < 2) return;
            var grad = ctx.createLinearGradient(0, 0, width, 0);
            grad.addColorStop(0.0, root.getGradientColor(0));
            grad.addColorStop(0.3, root.getGradientColor(1));
            grad.addColorStop(0.6, root.getGradientColor(2));
            grad.addColorStop(1.0, root.getGradientColor(3));

            ctx.beginPath();
            if (isShadow) {
                ctx.globalAlpha = 0.3;
                ctx.save();
                ctx.translate(0, -10);
                ctx.scale(1.02, 1.05);
            } else {
                ctx.globalAlpha = 1.0;
            }
            ctx.fillStyle = grad;
            ctx.moveTo(0, height);
            ctx.lineTo(0, height - (data[0] * height * root.visualizerIntensity));

            var bw = width / (data.length - 1);
            for (var i = 0; i < data.length - 1; i++) {
                var xc = i * bw,       yc = height - (data[i]     * height * root.visualizerIntensity);
                var xn = (i + 1) * bw, yn = height - (data[i + 1] * height * root.visualizerIntensity);
                ctx.quadraticCurveTo(xc, yc, (xc + xn) / 2, (yc + yn) / 2);
            }
            ctx.lineTo((data.length - 1) * bw, height - (data[data.length - 1] * height * root.visualizerIntensity));
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fill();
            if (isShadow) ctx.restore();
        }
    }

    onGradientStartChanged: canvas.requestPaint()
    onGradientMid1Changed:  canvas.requestPaint()
    onGradientMid2Changed:  canvas.requestPaint()
    onGradientEndChanged:   canvas.requestPaint()
    Connections {
        target: Colors
        function onPrimaryChanged()          { canvas.requestPaint() }
        function onSecondaryChanged()        { canvas.requestPaint() }
        function onTertiaryChanged()         { canvas.requestPaint() }
        function onPrimaryContainerChanged() { canvas.requestPaint() }
    }

    // ── Inline slider component ───────────────────────────────────────────────
    component CavaSlider: Item {
        id: sl
        height: 20

        property real value: 0.5
        property real from: 0.0
        property real to: 1.0
        signal dragged(real v)

        readonly property real _norm: Math.max(0.0, Math.min(1.0, (value - from) / (to - from)))

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.12)

            Rectangle {
                width: parent.width * sl._norm
                height: parent.height
                radius: parent.radius
                color: Qt.rgba(1, 1, 1, 0.55)
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(-7, Math.min(parent.width - 7, parent.width * sl._norm - 7))
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.SizeHorCursor

            function calcValue(mx) {
                // mx is in MouseArea coords (has -8 margin); map back to track
                let n = Math.max(0.0, Math.min(1.0, (mx + 8) / (sl.width + 16) * (sl.width / (sl.width))))
                // simpler: just clamp direct ratio against track width
                n = Math.max(0.0, Math.min(1.0, mx / sl.width))
                return sl.from + n * (sl.to - sl.from);
            }

            onPressed:         (mouse) => sl.dragged(calcValue(mouse.x))
            onPositionChanged: (mouse) => { if (pressed) sl.dragged(calcValue(mouse.x)) }
        }
    }

    // ── Controls overlay ──────────────────────────────────────────────────────
    Item {
        id: controls
        anchors.fill: parent
        // Visible when right-clicked, or while dragging/resizing, or settings open
        visible: root.showControls || moveHandler.active || resizeHandler.active || root.showSettings
        z: 10

        // ── Top bar ────────────────────────────────────────────────────────────
        Rectangle {
            id: controlBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28
            color: Qt.rgba(0, 0, 0, 0.65)
            radius: 6

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                spacing: 6

                Text {
                    text: "⠿"
                    font.pixelSize: 14
                    color: Colors.overSurfaceVariant
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "Cava #" + (root.instanceIndex + 1)
                    font.family: Config.theme.font
                    font.pixelSize: 11
                    color: Colors.overSurfaceVariant
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "  left-drag: move   corner: resize"
                    font.pixelSize: 9
                    color: Qt.rgba(1, 1, 1, 0.28)
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 8
                spacing: 14

                // ⚙ Settings toggle
                Text {
                    text: "⚙"
                    font.pixelSize: 14
                    color: root.showSettings ? Colors.primary : Colors.overBackground
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showSettings = !root.showSettings
                    }
                }

                // ⊕ Duplicate — copies full instance config incl. per-instance settings
                Text {
                    text: "⊕"
                    font.pixelSize: 16
                    color: Colors.overBackground
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.duplicateRequested(root.instanceIndex)
                    }
                }

                // ✕ Delete
                Text {
                    text: "✕"
                    font.pixelSize: 14
                    color: Colors.overError
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.deleteRequested(root.instanceIndex)
                    }
                }
            }
        }

        // ── Per-instance settings panel ────────────────────────────────────────
        Rectangle {
            id: settingsPanel
            anchors.top: controlBar.bottom
            anchors.topMargin: 2
            anchors.left: parent.left
            anchors.right: parent.right
            readonly property real openHeight: settingsCol.implicitHeight + 20
            height: root.showSettings ? openHeight : 0
            clip: true
            visible: height > 1
            color: Qt.rgba(0, 0, 0, 0.78)
            radius: 6

            Behavior on height {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Column {
                id: settingsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                // ── Rotation ──────────────────────────────────────────────────
                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Rotation"
                        font.family: Config.theme.font
                        font.pixelSize: 10
                        color: Colors.overSurfaceVariant
                        Layout.preferredWidth: 62
                    }

                    Row {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: [0, 90, 180, 270]
                            delegate: Rectangle {
                                required property int modelData
                                width: 38
                                height: 20
                                radius: 4
                                color: root.widgetRotation === modelData
                                ? Qt.rgba(1, 1, 1, 0.28)
                                : Qt.rgba(1, 1, 1, 0.07)

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "°"
                                    font.pixelSize: 10
                                    font.family: Config.theme.font
                                    color: root.widgetRotation === modelData
                                    ? Colors.overBackground
                                    : Colors.overSurfaceVariant
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.patchConfig("rotation", modelData)
                                }
                            }
                        }
                    }
                }

                // ── Opacity ───────────────────────────────────────────────────
                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Opacity"
                        font.family: Config.theme.font
                        font.pixelSize: 10
                        color: Colors.overSurfaceVariant
                        Layout.preferredWidth: 62
                    }

                    CavaSlider {
                        Layout.fillWidth: true
                        value: root.widgetOpacity
                        from: 0.1
                        to: 1.0
                        onDragged: v => root.patchConfig("opacity", parseFloat(v.toFixed(2)))
                    }

                    Text {
                        text: Math.round(root.widgetOpacity * 100) + "%"
                        font.pixelSize: 10
                        font.family: Config.theme.font
                        color: Colors.overSurfaceVariant
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // ── Intensity ─────────────────────────────────────────────────
                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Intensity"
                        font.family: Config.theme.font
                        font.pixelSize: 10
                        color: Colors.overSurfaceVariant
                        Layout.preferredWidth: 62
                    }

                    CavaSlider {
                        Layout.fillWidth: true
                        value: root.visualizerIntensity
                        from: 0.1
                        to: 3.0
                        onDragged: v => root.patchConfig("intensity", parseFloat(v.toFixed(2)))
                    }

                    Text {
                        text: root.visualizerIntensity.toFixed(1) + "×"
                        font.pixelSize: 10
                        font.family: Config.theme.font
                        color: Colors.overSurfaceVariant
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // ── Bar count ─────────────────────────────────────────────────
                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Bars"
                        font.family: Config.theme.font
                        font.pixelSize: 10
                        color: Colors.overSurfaceVariant
                        Layout.preferredWidth: 62
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 4
                        color: Qt.rgba(1, 1, 1, 0.07)
                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            font.pixelSize: 16
                            color: Colors.overBackground
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.patchConfig("barCount", Math.max(10, root.barCount - 5))
                        }
                    }

                    Text {
                        text: root.barCount
                        font.pixelSize: 11
                        font.family: Config.theme.font
                        color: Colors.overBackground
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 4
                        color: Qt.rgba(1, 1, 1, 0.07)
                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 14
                            color: Colors.overBackground
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.patchConfig("barCount", Math.min(100, root.barCount + 5))
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // ── Wallpaper colors toggle ────────────────────────────────────
                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Wallpaper colors"
                        font.family: Config.theme.font
                        font.pixelSize: 10
                        color: Colors.overSurfaceVariant
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 34; height: 18; radius: 9
                        color: root.useWallpaperColors ? Colors.primary : Qt.rgba(1, 1, 1, 0.15)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 14; height: 14; radius: 7
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.useWallpaperColors ? parent.width - width - 2 : 2
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.patchConfig("wallpaper", !root.useWallpaperColors)
                        }
                    }
                }
            }
        }

        // ── Resize grip — left-click drag on corner = RESIZE ──────────────────
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 24
            height: 24
            color: Qt.rgba(0, 0, 0, 0.65)
            radius: 4

            HoverHandler {
                cursorShape: Qt.SizeFDiagCursor
            }

            Text {
                anchors.centerIn: parent
                text: "⌟"
                font.pixelSize: 18
                color: Colors.overBackground
            }

            DragHandler {
                id: resizeHandler
                target: null
                acceptedButtons: Qt.LeftButton
                // Takes over from the root moveHandler when dragging this corner
                grabPermissions: PointerHandler.CanTakeOverFromAnything

                onActiveChanged: {
                    if (active) {
                        root.resizeStartW = root.width;
                        root.resizeStartH = root.height;
                    } else {
                        root.resized(root.instanceIndex, root.width, root.height);
                    }
                }

                onTranslationChanged: {
                    root.width  = Math.max(200, root.resizeStartW + translation.x);
                    root.height = Math.max(80,  root.resizeStartH + translation.y);
                }
            }
        }

        // ── Border outline ─────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: (moveHandler.active || resizeHandler.active)
            ? Styling.srItem("overprimary")
            : Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
            radius: 4
        }
    }
}
