pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.theme

// ┌──────────────────────────────────────────────────────────────────────────┐
// │  DesktopClockWidget                                                       │
// │  • Left-click drag anywhere → move (same behaviour as cava widget)       │
// │  • Right-click              → show control bar                            │
// │  • ⚙ button in control bar  → open color-picker panel                   │
// │  • ✕ button                 → emit deleteRequested (disables clock)      │
// │                                                                           │
// │  Fonts: place Anurati.otf and Poppins.ttf in the SAME directory as this  │
// │  file (next to Desktop.qml / DesktopCavaWidget.qml).                     │
// └──────────────────────────────────────────────────────────────────────────┘

Item {
    id: root

    // ── Config object (fed from Desktop.qml) ─────────────────────────────────
    // Expected keys: { color: "auto" | "#rrggbb" }
    property var instanceConfig: ({})

    // ── Signals (same pattern as DesktopCavaWidget) ───────────────────────────
    signal moved(real nx, real ny)
    signal instanceSettingsChanged(var settings)
    signal deleteRequested()

    // ── Resolved clock color ──────────────────────────────────────────────────
    // instanceConfig.color can be:
    //   "auto"        → follow theme primary
    //   "#rrggbb"     → raw hex
    //   "primary" etc → named theme color (Colors.availableColorNames)
    readonly property string clockColorKey: instanceConfig.color ?? "auto"
    readonly property color  clockColor: {
        if (clockColorKey === "auto")
            return Colors.primary;
        const resolved = Config.resolveColor(clockColorKey);
        return (resolved && resolved !== "transparent") ? resolved : Colors.primary;
    }

    // ── Drag state (mirrored from parent via DragHandler below) ───────────────
    property real dragDeltaX: 0
    property real dragDeltaY: 0
    property bool isDragging:    false
    property bool showControls:  false
    property bool showSettings:  false

    // ── Implicit sizing from content ──────────────────────────────────────────
    implicitWidth:  clockColumn.implicitWidth  + 24
    implicitHeight: clockColumn.implicitHeight + 24

    // ── Patch helper (same pattern as cava) ──────────────────────────────────
    function patchConfig(key, value) {
        let c = JSON.parse(JSON.stringify(root.instanceConfig))
        c[key] = value
        root.instanceSettingsChanged(c)
    }

    // ── Fonts ─────────────────────────────────────────────────────────────────
    FontLoader {
        id: font_anurati
        // Put Anurati.otf alongside this QML file
        source: Qt.resolvedUrl("Anurati.otf")
    }
    FontLoader {
        id: font_poppins
        // Put Poppins.ttf alongside this QML file
        source: Qt.resolvedUrl("Poppins.ttf")
    }

    // ── Clock timer ───────────────────────────────────────────────────────────
    Timer {
        interval: 1000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            display_day.text  = Qt.formatDate(now, "dddd").toUpperCase()
            display_date.text = Qt.formatDate(now, "dd MMM yyyy").toUpperCase()
            display_time.text = "- " + Qt.formatTime(now, "hh:mm AP") + " -"
        }
    }

    // ── Right-click → toggle controls ─────────────────────────────────────────
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.showControls = !root.showControls
    }

    // ── Left-click drag → MOVE (identical to DesktopCavaWidget) ──────────────
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
                // root.x already equals baseX + final delta at this point
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

    // ── Clock display ─────────────────────────────────────────────────────────
    Column {
        id: clockColumn
        anchors.centerIn: parent
        spacing: 4

        // ── Day of week (large Anurati) ───────────────────────────────────────
        Item {
            implicitWidth:  display_day.implicitWidth
            implicitHeight: display_day.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            // drop shadow
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

        // ── Date ─────────────────────────────────────────────────────────────
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

        // ── Time ─────────────────────────────────────────────────────────────
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

    // ── Controls overlay (shown on right-click / drag / settings open) ────────
    Item {
        id: controls
        anchors.fill: parent
        visible: root.showControls || moveHandler.active || root.showSettings
        z: 10

        // ── Top control bar ───────────────────────────────────────────────────
        Rectangle {
            id: controlBar
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: 28
            color:  Qt.rgba(0, 0, 0, 0.65)
            radius: 6

            // Left side: label + hint
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
                    text:              "Clock"
                    font.family:       Config.theme.font
                    font.pixelSize:    11
                    color:             Colors.overSurfaceVariant
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text:              "  left-drag: move"
                    font.pixelSize:    9
                    color:             Qt.rgba(1, 1, 1, 0.28)
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Right side: ⚙ settings  ✕ delete
            Row {
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin:    8
                spacing: 14

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

                // ── Swatch row ────────────────────────────────────────────────
                Flow {
                    width:   parent.width
                    spacing: 6

                    // "Auto" swatch — always reflects current theme primary
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

                    // Theme color swatches — pulled live from Colors singleton
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
                                id: swatchArea
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

        // ── Outline border (highlights while dragging) ────────────────────────
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
