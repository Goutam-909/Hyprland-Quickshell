
// IdleInhibitor.qml - Material 3 Themed (matching Network.qml pattern)
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services as Services
import qs.common

Item {
    id: root
    implicitHeight:60
    Layout.fillWidth: true

    property var onActivate: function() {}
    readonly property bool inhibitorActive: Services.InhibitorService.active

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 35 // Large radius for pill shape
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

            // Icon circle
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                implicitWidth: 45
                implicitHeight: 45
                radius: 25
                color: root.inhibitorActive
                ? Appearance.colors.colPrimary
                : Appearance.colors.colSurfaceContainerHighest

                MaterialSymbol {
                    anchors.centerIn: parent
                    icon: root.inhibitorActive ? "bedtime" : "bedtime_off"
                    iconSize: 24
                    color: root.inhibitorActive
                    ? Appearance.colors.colOnPrimary
                    : Appearance.colors.colOnSurfaceVariant
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            // Text
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Idle"
                    color: Appearance.colors.colOnSurface
                    font.family: Appearance.font.family.main
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.inhibitorActive ? "Screen awake" : "Inactive"
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
                Services.InhibitorService.toggle()
                root.onActivate()
            }
        }
    }
}



