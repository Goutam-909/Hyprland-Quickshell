// Shared round icon button used by the control-center detail pages (Wi-Fi / Bluetooth).
import QtQuick
import qs.common

Rectangle {
    id: root

    property string icon: ""
    property int iconSize: 20
    property color iconColor: Appearance.colors.colOnSurfaceVariant
    property bool spinning: false
    property bool baseTransparent: false   // flat until hovered (for use inside inputs)
    signal clicked()

    implicitWidth: 36
    implicitHeight: 36
    radius: height / 2
    opacity: enabled ? 1 : 0.5
    color: area.pressed ? Appearance.colors.colLayer3Active
         : (area.containsMouse ? Appearance.colors.colLayer3Hover
         : (baseTransparent ? "transparent" : Appearance.colors.colLayer3))
    Behavior on color { ColorAnimation { duration: 150 } }

    MaterialSymbol {
        id: sym
        anchors.centerIn: parent
        icon: root.icon
        iconSize: root.iconSize
        color: root.iconColor
        Behavior on color { ColorAnimation { duration: 200 } }

        RotationAnimation on rotation {
            running: root.spinning
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
            onRunningChanged: if (!running) sym.rotation = 0
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
