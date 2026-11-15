pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.theme

// ┌──────────────────────────────────────────────────────────────────────────┐
// │  DesktopClockWidget                                                       │
// │  • Left-click drag anywhere → move                                        │
// │  • Right-click              → show control bar                            │
// │  • ↻ button                 → cycle: classic → digital → pixel → pixel vertical│
// │  • ⚙ button                 → color-picker panel                         │
// │  • ✕ button                 → emit deleteRequested (disables clock)      │
// │                                                                           │
// │  Classic uses Anurati.otf + Poppins.ttf (next to this file).             │
// │  Digital and pixel use "Google Sans Flex" (installed on the system).     │
// └──────────────────────────────────────────────────────────────────────────┘

Item {
    id: root

    // Expected keys: { color: "auto" | "#rrggbb" | themeName, style: "classic" | "digital" | "pixel" }
    property var instanceConfig: ({})

    signal moved(real nx, real ny)
    signal instanceSettingsChanged(var settings)
    signal deleteRequested()

    // ── Style ─────────────────────────────────────────────────────────────────
    // "pixel" = horizontal row of digits, "pixelv" = vertical 2x2 stack
    readonly property var styles: ["classic", "digital", "pixel", "pixelv"]
    readonly property bool isPixel: style === "pixel" || style === "pixelv"
    readonly property bool pixelVertical: style === "pixelv"
    readonly property string style: styles.indexOf(instanceConfig.style) >= 0 ? instanceConfig.style : "classic"
    function nextStyle() {
        return styles[(styles.indexOf(style) + 1) % styles.length]
    }

    readonly property string flexFamily: "Google Sans Flex"

    // ── Resolved clock color ──────────────────────────────────────────────────
    readonly property string clockColorKey: instanceConfig.color ?? "auto"
    readonly property color clockColor: {
        if (clockColorKey === "auto")
            return ClockPlacement.autoColor; // primary, light/dark picked for the area behind the clock (end4 rule)
        const resolved = Config.resolveColor(clockColorKey);
        return (resolved && resolved !== "transparent") ? resolved : Colors.primary;
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }
    // digital: heavy see-through time, brighter date.
    // Lower these for a fainter clock (0 = invisible, 1 = solid). Originally 0.42 / 0.85.
    readonly property real digitalTimeOpacity: 1
    readonly property real digitalDateOpacity: 1
    readonly property color digitalTint: mix(clockColor, Colors.overSurface, 0.55)
    // pixel: outer digits are the "soft" colour, inner ones the bold colour
    readonly property color pixelSoft: clockColorKey === "auto" ? Colors.primaryContainer : Qt.darker(clockColor, 1.6)

    // ── Time state ────────────────────────────────────────────────────────────
    property date now: new Date()
    function pad2(n) { return (n < 10 ? "0" : "") + n }
    readonly property int hour12: (now.getHours() % 12) === 0 ? 12 : now.getHours() % 12
    readonly property string digitalTime: hour12 + ":" + pad2(now.getMinutes())
    readonly property string digitalDate: Qt.formatDate(now, "ddd, dd MMM").toUpperCase()
    readonly property string pixelDigits: pad2(hour12) + pad2(now.getMinutes())

    // ── Drag state ────────────────────────────────────────────────────────────
    property real dragDeltaX: 0
    property real dragDeltaY: 0
    property bool isDragging:    false
    property bool showControls:  false
    property bool showSettings:  false

    // ── Sizing per style ──────────────────────────────────────────────────────
    implicitWidth:  style === "classic" ? clockColumn.implicitWidth + 24
                  : pixelVertical ? 276 : 420
    implicitHeight: style === "classic" ? clockColumn.implicitHeight + 24
                  : style === "digital" ? 200
                  : pixelVertical ? 264 : 150

    function patchConfig(key, value) {
        let c = JSON.parse(JSON.stringify(root.instanceConfig))
        c[key] = value
        root.instanceSettingsChanged(c)
    }

    // ── Fonts (classic) ───────────────────────────────────────────────────────
    FontLoader { id: font_anurati; source: Qt.resolvedUrl("Anurati.otf") }
    FontLoader { id: font_poppins; source: Qt.resolvedUrl("Poppins.ttf") }

    // ── Clock timer ───────────────────────────────────────────────────────────
    Timer {
        interval: 1000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            var n = new Date()
            root.now = n
            display_day.text  = Qt.formatDate(n, "dddd").toUpperCase()
            display_date.text = Qt.formatDate(n, "dd MMM yyyy").toUpperCase()
            display_time.text = "- " + Qt.formatTime(n, "hh:mm AP") + " -"
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.showControls = !root.showControls
    }

    DragHandler {
        id: moveHandler
        target: null
        acceptedButtons: Qt.LeftButton

        onActiveChanged: {
            if (active) {
                root.isDragging   = true
                root.showControls = false
                root.dragDeltaX   = 0
                root.dragDeltaY   = 0
            } else {
                root.isDragging = false
                root.moved(root.x, root.y)
                root.dragDeltaX = 0
                root.dragDeltaY = 0
            }
        }

        onTranslationChanged: {
            root.dragDeltaX = translation.x
            root.dragDeltaY = translation.y
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  STYLE 1: classic (your original)
    // ═════════════════════════════════════════════════════════════════════════
    Column {
        id: clockColumn
        visible: root.style === "classic"
        anchors.centerIn: parent
        spacing: 4

        Item {
            implicitWidth:  display_day.implicitWidth
            implicitHeight: display_day.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                x: 2; y: 2
                text:  display_day.text
                font:  display_day.font
                color: "#55000000"
            }
            Text {
                id: display_day
                font.family:      font_anurati.name
                font.pixelSize:   90
                font.letterSpacing: 10
                color: root.clockColor
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        Item {
            implicitWidth:  display_date.implicitWidth
            implicitHeight: display_date.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                x: 1; y: 1
                text:  display_date.text
                font:  display_date.font
                color: "#55000000"
            }
            Text {
                id: display_date
                font.family:    font_poppins.name
                font.pixelSize: 20
                color: root.clockColor
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        Item {
            implicitWidth:  display_time.implicitWidth
            implicitHeight: display_time.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                x: 1; y: 1
                text:  display_time.text
                font:  display_time.font
                color: "#55000000"
            }
            Text {
                id: display_time
                font.family:    font_poppins.name
                font.pixelSize: 17
                color: root.clockColor
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  STYLE 2: digital — big heavy see-through time, brighter date overlapping
    //  its right end
    // ═════════════════════════════════════════════════════════════════════════
    Item {
        id: digitalFace
        visible: root.style === "digital"
        anchors.fill: parent

        readonly property real pad: width * 0.03
        readonly property real timePx: Math.min(height * 0.78, (width - 2 * pad) / 2.9)
        readonly property real timeY: height * 0.46

        Text {
            id: digTime
            text: root.digitalTime
            font.family: root.flexFamily
            font.weight: Font.Black
            font.pixelSize: digitalFace.timePx
            color: root.digitalTint
            opacity: root.digitalTimeOpacity
            x: digitalFace.pad
            y: digitalFace.timeY - height / 2
        }

        Text {
            id: digDate
            text: root.digitalDate
            font.family: root.flexFamily
            font.weight: Font.ExtraBold
            font.pixelSize: Math.max(14, Math.min(44, digitalFace.timePx * 0.27))
            color: root.digitalTint
            opacity: root.digitalDateOpacity
            x: digitalFace.width - digitalFace.pad - width
            y: digitalFace.timeY + digitalFace.timePx * 0.40 - height / 4//height / 2
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  STYLE 3: pixel — four huge overlapping digits; each one cuts a thin
    //  outline out of the ones under it (sticker look)
    // ═════════════════════════════════════════════════════════════════════════
    Canvas {
        id: pixelCanvas
        visible: root.isPixel
        anchors.fill: parent
        antialiasing: true

        property string digits: root.pixelDigits
        property color softColor: root.pixelSoft
        property color boldColor: root.clockColor
        property bool vertical: root.pixelVertical

        onVerticalChanged: requestPaint()
        onDigitsChanged: requestPaint()
        onSoftColorChanged: requestPaint()
        onBoldColorChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var nw = width, nh = height
            // horizontal: one row of four digits.  vertical: 2x2 stack (hours on top, minutes below)
            var tileW = vertical ? nw * 0.66 : nw * 0.327
            var tileH = vertical ? nh * 0.66 : nh * 0.9
            var glyph = vertical ? nh * 0.66 : nh * 0.85
            var fringe = vertical ? nw * 0.026 : nh * 0.03
            var gx = vertical ? [0, nw * 0.30, 0, nw * 0.30]
                              : [0, nw * 0.163, nw * 0.50, nw * 0.653]
            var gy = vertical ? [nh * -0.04, nh * -0.04, nh * 0.42, nh * 0.42]
                              : [nh * 0.05, nh * 0.05, nh * 0.05, nh * 0.05]

            ctx.font = "900 " + glyph + "px '" + root.flexFamily + "'"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.lineJoin = "round"

            for (var i = 0; i < 4; i++) {
                var d = digits.charAt(i)
                var cx = gx[i] + tileW / 2
                var cy = gy[i] + tileH / 2

                if (i > 0) {
                    // cut a thin outline (and the glyph itself) out of what is already there
                    ctx.globalCompositeOperation = "destination-out"
                    ctx.lineWidth = fringe * 2
                    ctx.strokeText(d, cx, cy)
                    ctx.fillText(d, cx, cy)
                }
                ctx.globalCompositeOperation = "source-over"
                ctx.fillStyle = (i === 0 || i === 3) ? softColor : boldColor
                ctx.fillText(d, cx, cy)
            }

            // the two dots between hours and minutes (horizontal layout only)
            if (!vertical) {
                var dot = nh * 0.2, gap = nh * 0.04
                var colonX = gx[1] + tileW + (gx[2] - (gx[1] + tileW)) / 2 - nw * 0.03
                var top = gy[0] + tileH / 2 - (2 * dot + gap) / 2
                ctx.fillStyle = boldColor
                for (var k = 0; k < 2; k++) {
                    ctx.beginPath()
                    ctx.arc(colonX + dot / 2, top + dot / 2 + k * (dot + gap), dot / 2, 0, 2 * Math.PI)
                    ctx.fill()
                }
            }
        }
    }

    // ── Controls overlay (shown on right-click / drag / settings open) ────────
    Item {
        id: controls
        anchors.fill: parent
        visible: root.showControls || moveHandler.active || root.showSettings
        z: 10

        Rectangle {
            id: controlBar
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: 28
            color:  Qt.rgba(0, 0, 0, 0.65)
            radius: 6

            Row {
                anchors.left:           parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin:     10
                spacing: 6

                Text {
                    text:              "⠿"
                    font.pixelSize:    14
                    color:             Colors.overSurfaceVariant
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text:              "Clock · " + (root.pixelVertical ? "pixel vertical" : root.style)
                    font.family:       Config.theme.font
                    font.pixelSize:    11
                    color:             Colors.overSurfaceVariant
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Row {
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin:    8
                spacing: 14

                // ↻ Cycle style
                Text {
                    text:              "↻"
                    font.pixelSize:    16
                    color:             Colors.overBackground
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill:    parent
                        anchors.margins: -4
                        cursorShape:     Qt.PointingHandCursor
                        onClicked:       root.patchConfig("style", root.nextStyle())
                    }
                }

                // ⚙ Settings toggle
                Text {
                    text:              "⚙"
                    font.pixelSize:    14
                    color:             root.showSettings ? Colors.primary : Colors.overBackground
                    verticalAlignment: Text.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        anchors.fill:    parent
                        anchors.margins: -4
                        cursorShape:     Qt.PointingHandCursor
                        onClicked:       root.showSettings = !root.showSettings
                    }
                }

                // ✕ Disable / delete clock
                Text {
                    text:              "✕"
                    font.pixelSize:    14
                    color:             Colors.overError
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill:    parent
                        anchors.margins: -4
                        cursorShape:     Qt.PointingHandCursor
                        onClicked:       root.deleteRequested()
                    }
                }
            }
        }

        // ── Color-picker settings panel ───────────────────────────────────────
        Rectangle {
            id: settingsPanel
            anchors.top:       controlBar.bottom
            anchors.topMargin: 2
            anchors.left:      parent.left
            anchors.right:     parent.right

            readonly property real openHeight: settingsCol.implicitHeight + 20
            height:  root.showSettings ? openHeight : 0
            clip:    true
            visible: height > 1
            color:   Qt.rgba(0, 0, 0, 0.78)
            radius:  6

            Behavior on height {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Column {
                id: settingsCol
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.top:     parent.top
                anchors.margins: 10
                spacing: 8

                Text {
                    text:           "Color"
                    font.family:    Config.theme.font
                    font.pixelSize: 10
                    color:          Colors.overSurfaceVariant
                }

                Flow {
                    width:   parent.width
                    spacing: 6

                    Rectangle {
                        width: 28; height: 28; radius: 6
                        color: Colors.primary
                        border.width: root.clockColorKey === "auto" ? 2 : 0
                        border.color: "white"
                        Behavior on border.width { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text:           "A"
                            font.pixelSize: 10
                            font.bold:      true
                            color:          "white"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.patchConfig("color", "auto")
                        }
                    }

                    Repeater {
                        model: [
                            "primary",
                            "secondary",
                            "tertiary",
                            "red",
                            "green",
                            "blue",
                            "cyan",
                            "magenta",
                            "yellow",
                            "white",
                            "primaryContainer",
                            "secondaryContainer",
                            "tertiaryContainer",
                            "surface",
                            "surfaceBright",
                            "outline",
                        ]

                        delegate: Rectangle {
                            required property string modelData
                            width: 28; height: 28; radius: 6
                            color: Colors[modelData] ?? Colors.primary
                            border.width: root.clockColorKey === modelData ? 2 : 0
                            border.color: Colors.overBackground
                            Behavior on border.width { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 300 } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked:    root.patchConfig("color", modelData)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color:        "transparent"
            border.color: moveHandler.active
            ? Styling.srItem("overprimary")
            : Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
            radius: 6
        }
    }
}


