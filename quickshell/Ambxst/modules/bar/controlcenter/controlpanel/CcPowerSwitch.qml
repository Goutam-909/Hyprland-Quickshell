// Shared on/off switch for the control-center detail page headers.
import QtQuick
import qs.common

Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 48
    implicitHeight: 28
    radius: height / 2
    color: checked ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
    Behavior on color { ColorAnimation { duration: 200 } }

    Rectangle {
        width: 20
        height: 20
        radius: 10
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
