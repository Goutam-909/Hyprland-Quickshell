
// modules/controlpanel/Brightness.qml - macOS Control Center slider style
// Bold title, thin white-fill track with no knob, small sun left / large sun right.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.Services as Services
import qs.common
import qs.common.functions
import qs.modules.theme

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: 70

    property int uiValue: 0
    property bool dragging: false

    function clamp(n, lo, hi) { return Math.max(lo, Math.min(hi, n)) }
    function brightToUi(b) { return clamp(Math.round(clamp(b, 0.0, 1.0) * 100), 0, 100) }
    function uiToBright(u) { return clamp(u, 0, 100) / 100.0 }

    function currentMonitor() {
        const name = Hyprland.focusedMonitor?.name
        if (!name) return null
            for (let i = 0; i < Services.Brightness.monitors.length; i++) {
                const m = Services.Brightness.monitors[i]
                if (m?.screen?.name === name) return m
            }
            return null
    }

    function syncFromService() {
        if (dragging) return
            const m = currentMonitor()
            if (!m || !m.ready) return
                uiValue = brightToUi(m.brightness)
    }

    function adjustBrightness(delta) {
        const newVal = clamp(uiValue + delta, 0, 100)
        uiValue = newVal
        const m = currentMonitor()
        if (m && m.ready) m.setBrightness(uiToBright(newVal))
    }

    Connections {
        target: Services.Brightness
        function onBrightnessChanged() {
            root.syncFromService()
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.syncFromService()
    }

    Timer {
        id: releaseTimer
        interval: 150
        repeat: false
        onTriggered: root.dragging = false
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Styling.radius(10)
        color: card.hovered
        ? Appearance.colors.colLayer2Hover
        : Appearance.colors.colSurfaceContainerHigh

        property bool hovered: false

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            // Title
            Text {
                text: "Display"
                font.family: Appearance.font.family.main
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSurface
            }

            // Slider row
            RowLayout {
                width: parent.width
                height: 24
                spacing: 10

                // Left icon — small sun
                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    icon: "light_mode"
                    iconSize: 14
                    color: Appearance.colors.colOnSurface
                    opacity: 0.85
                }

                // Thin track, white fill, no knob (macOS style)
                Item {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    height: 24

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Appearance.colors.colSurfaceContainerHighest
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * (root.uiValue / 100)
                        height: 6
                        radius: 3
                        color: Appearance.colors.colPrimary

                        Behavior on width {
                            NumberAnimation { duration: root.dragging ? 0 : 150 }
                        }
                    }

                    MouseArea {
                        id: handleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: function(mouse) {
                            root.dragging = true
                            updatePosition(mouse.x)
                        }

                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                updatePosition(mouse.x)
                            }
                        }

                        onReleased: function(mouse) {
                            updatePosition(mouse.x)
                            releaseTimer.restart()
                        }

                        onWheel: function(wheel) {
                            const delta = wheel.angleDelta.y > 0 ? 5 : -5
                            root.adjustBrightness(delta)
                        }

                        function updatePosition(x) {
                            const newVal = clamp(Math.round((x / width) * 100), 0, 100)
                            root.uiValue = newVal
                            const m = root.currentMonitor()
                            if (m && m.ready) m.setBrightness(root.uiToBright(newVal))
                        }
                    }
                }

                // Right icon — large sun
                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    icon: "light_mode"
                    iconSize: 20
                    color: Appearance.colors.colOnSurface
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onPressed: function(mouse) { mouse.accepted = false }
            onWheel: function(wheel) {
                const delta = wheel.angleDelta.y > 0 ? 5 : -5
                root.adjustBrightness(delta)
            }
        }
    }
}
