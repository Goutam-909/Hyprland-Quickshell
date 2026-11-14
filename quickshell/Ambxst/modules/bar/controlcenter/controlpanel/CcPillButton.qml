// Shared pill button (optional leading icon) used by the control-center detail pages.
import QtQuick
import qs.common

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property color labelColor: Appearance.colors.colOnSurface
    property color baseColor: Appearance.colors.colLayer3
    property color hoverColor: Appearance.colors.colLayer3Hover
    property color activeColor: Appearance.colors.colLayer3Active
    signal clicked()

    implicitHeight: 36
    implicitWidth: row.implicitWidth + 28
    radius: height / 2
    opacity: enabled ? 1 : 0.5
    scale: area.pressed ? 0.95 : 1
    color: area.pressed ? activeColor : (area.containsMouse ? hoverColor : baseColor)
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            iconSize: 18
            color: root.labelColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.family: Appearance.font.family.main
            font.pixelSize: 12
            font.weight: Font.Medium
            color: root.labelColor
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
