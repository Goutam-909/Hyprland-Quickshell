// MicToggle.qml
// Same pill design as SoundToggle.qml, mirrored for the microphone (input)
// instead of speakers (output). Uses Services.Audio.source, which is your
// real Audio singleton's Pipewire default-source node.
// • Click the icon circle  → mute / unmute mic
// • Click the text area    → open MicPopupInline (mirrors Volume Mixer)
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services as Services
import qs.common

Item {
    id: root
    implicitHeight: 60
    Layout.fillWidth: true

    signal toggleMicMixer()

    // Derived state from Audio service
    readonly property bool isMuted: Services.Audio.micReady && Services.Audio.sourceMuted
    readonly property real  volume:  Services.Audio.micReady ? Services.Audio.sourceVolume : 0.5

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 35
        color: card.pressed
               ? Appearance.colors.colLayer2Active
               : (card.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colSurfaceContainerHigh)
        scale: card.pressed ? 0.80 : 1

        property bool hovered: false
        property bool pressed: false

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            // ── Icon circle — click to mute/unmute ──────────────────────────
            Rectangle {
                id: iconCircle
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                implicitWidth: 40
                implicitHeight: 40
                radius: 25
                color: root.isMuted
                       ? Appearance.colors.colSurfaceContainerHighest
                       : Appearance.colors.colPrimary
                scale: iconArea.pressed ? 0.92 : 1

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                MaterialSymbol {
                    anchors.centerIn: parent
                    icon: root.isMuted ? "mic_off" : "mic"
                    iconSize: 24
                    color: root.isMuted
                           ? Appearance.colors.colOnSurfaceVariant
                           : Appearance.colors.colOnPrimary

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // Click = toggle mute
                MouseArea {
                    id: iconArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        Services.Audio.toggleMicMute()
                        mouse.accepted = true
                    }
                }
            }

            // ── Label ───────────────────────────────────────────────────────
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Microphone"
                    color: Appearance.colors.colOnSurface
                    font.family: Appearance.font.family.main
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.isMuted
                          ? "Muted"
                          : Math.round(root.volume * 100) + "%"
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Appearance.font.family.main
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        // ── Text area click — open Mic Mixer popup ────────────────────────
        MouseArea {
            id: mainArea
            anchors.fill: parent
            anchors.leftMargin: 62   // exclude the icon circle (same pattern as SoundToggle.qml)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered:  card.hovered = true
            onExited:   card.hovered = false
            onPressed:  card.pressed = true
            onReleased: card.pressed = false
            onClicked:  root.toggleMicMixer()
        }
    }
}
