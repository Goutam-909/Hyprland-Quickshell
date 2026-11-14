// FillerButton.qml - Material 3 Themed (matching Inhibitor.qml pattern)
//
// Placeholder tile — no backend yet. Change `icon`/`label` when you decide
// what this becomes (e.g. Focus mode, Screen Recording, AirDrop-alike...),
// and wire onClicked up to whatever service backs it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

Item {
    id: root
    implicitHeight: 60
    Layout.fillWidth: true

    property var onActivate: function() {}

    property string icon: "add"
    property string label: "Filler"
    property string subLabel: "Soon"
    property bool active: false

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

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                implicitWidth: 45
                implicitHeight: 45
                radius: 25
                color: root.active
                ? Appearance.colors.colPrimary
                : Appearance.colors.colSurfaceContainerHighest

                MaterialSymbol {
                    anchors.centerIn: parent
                    icon: root.icon
                    iconSize: 24
                    color: root.active
                    ? Appearance.colors.colOnPrimary
                    : Appearance.colors.colOnSurfaceVariant
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: root.label
                    color: Appearance.colors.colOnSurface
                    font.family: Appearance.font.family.main
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.subLabel
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Appearance.font.family.main
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: mainArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onPressed: card.pressed = true
            onReleased: card.pressed = false
            onClicked: {
                // No backend yet — flips its own visual state only.
                root.active = !root.active
                root.onActivate()
            }
        }
    }
}
