// modules/controlpanel/Volume.qml - macOS Control Center slider style
// Bold title, thin white-fill track with no knob, speaker left / speaker-with-waves
// right, and a round button at the end that opens the mixer (macOS's AirPlay spot).
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Services as Services
import qs.common
import qs.common.functions
import qs.modules.theme

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: 70

    property bool menuOpen: false

    // Opens the Volume Mixer detail page — this is now the only entry
    // point to it, since the FOCUS+SOUND row's separate Sound tile
    // (SoundToggle.qml) was removed and this button took over its job.
    signal toggleVolumeMixer()

    function clamp(n, lo, hi) { return Math.max(lo, Math.min(hi, n)) }

    function volumeIcon(vol, muted) {
        if (muted || vol === 0) return "volume_mute"
            if (vol < 50) return "volume_down"
                return "volume_up"
    }

    function adjustVolume(delta) {
        if (!Services.Audio.ready) return
            const currentVol = Services.Audio.sinkVolume * 100
            const newVol = clamp(currentVol + delta, 0, 100)
            Services.Audio.setSinkVolume(newVol / 100)
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
                text: "Sound"
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

                // Left icon — speaker, no waves
                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    icon: "volume_mute"
                    iconSize: 16
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
                        width: parent.width * (Services.Audio.ready ? Math.min(1, Services.Audio.sinkVolume) : 0.5)
                        height: 6
                        radius: 3
                        color: Appearance.colors.colPrimary

                        Behavior on width {
                            NumberAnimation { duration: handleArea.pressed ? 0 : 150 }
                        }
                    }

                    MouseArea {
                        id: handleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: function(mouse) {
                            updatePosition(mouse.x)
                        }

                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                updatePosition(mouse.x)
                            }
                        }

                        onReleased: function(mouse) {
                            updatePosition(mouse.x)
                        }

                        onWheel: function(wheel) {
                            const delta = wheel.angleDelta.y > 0 ? 5 : -5
                            root.adjustVolume(delta)
                        }

                        function updatePosition(x) {
                            if (!Services.Audio.ready) return
                                const newVal = clamp(x / width, 0, 1)
                                Services.Audio.setSinkVolume(newVal)
                        }
                    }
                }

                // Right icon — speaker with waves
                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    icon: "volume_up"
                    iconSize: 20
                    color: Appearance.colors.colOnSurface
                }

                // Round button at the end — opens the mixer (macOS's AirPlay spot)
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: arrowArea.pressed
                    ? Appearance.colors.colLayer3Active
                    : (arrowArea.containsMouse ? Appearance.colors.colLayer3Hover : Appearance.colors.colSecondaryContainer)

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        icon: "airplay"
                        iconSize: 16
                        color: Appearance.colors.colOnSecondaryContainer
                    }

                    MouseArea {
                        id: arrowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            root.toggleVolumeMixer()
                            mouse.accepted = true
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: 40
            propagateComposedEvents: true
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onPressed: function(mouse) { mouse.accepted = false }
            onWheel: function(wheel) {
                const delta = wheel.angleDelta.y > 0 ? 5 : -5
                root.adjustVolume(delta)
            }
        }
    }
}
