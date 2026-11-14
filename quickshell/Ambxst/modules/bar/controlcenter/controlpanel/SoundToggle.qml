// Widgets/controlpanel/SoundToggle.qml
// Same pill design as Inhibitor.qml
// • Click the icon circle  → mute / unmute system audio
// • Click the text area    → open VolumeMixerPopupInline
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services as Services
import qs.common

Item {
    id: root
    implicitHeight: 60
    Layout.fillWidth: true

    signal toggleVolumeMixer()

    // Derived state from Audio service
    readonly property bool isMuted: Services.Audio.ready && Services.Audio.sinkMuted
    readonly property real  volume:  Services.Audio.ready ? Services.Audio.sinkVolume : 0.5

    function volumeIcon(muted, vol) {
        if (muted || vol === 0) return "volume_off"
        if (vol < 0.34)        return "volume_mute"
        if (vol < 0.67)        return "volume_down"
        return "volume_up"
    }

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
                    icon: root.volumeIcon(root.isMuted, root.volume)
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
                        if (Services.Audio.ready)
                            Services.Audio.setSinkMuted(!Services.Audio.sinkMuted)
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
                    text: "Sound"
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

        // ── Text area click — open Volume Mixer popup ────────────────────────
        MouseArea {
            id: mainArea
            anchors.fill: parent
            anchors.leftMargin: 62   // exclude the icon circle (same pattern as Network.qml)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered:  card.hovered = true
            onExited:   card.hovered = false
            onPressed:  card.pressed = true
            onReleased: card.pressed = false
            onClicked:  root.toggleVolumeMixer()
        }
    }
}
