// controlpanel/CcToggle.qml
// Round toggle button for the 2-column toggle card (caffeine, night light, ...).
//   clicked()       – left click
//   rightClicked()  – right click (optional secondary action)
import QtQuick
import qs.common
import qs.modules.theme

Item {
    id: root

    property string icon: ""     // a glyph, e.g. Icons.caffeine
    property bool active: false
    property int size: 60

    signal clicked()
    signal rightClicked()

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: circle
        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: width / 2
        scale: area.pressed ? 0.92 : 1.0
        color: root.active
               ? Appearance.colors.colPrimary
               : (area.containsMouse ? Appearance.colors.colLayer3Hover
                                     : Appearance.colors.colSurfaceContainerHighest)

        Behavior on color { ColorAnimation  { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            font.family: Icons.font
            font.pixelSize: 22
            text: root.icon
            color: root.active ? Appearance.colors.colOnPrimary
                               : Appearance.colors.colOnSurface
        }
    }

    MouseArea {
        id: area
        anchors.fill: circle
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            if (m.button === Qt.RightButton) root.rightClicked()
            else root.clicked()
        }
    }
}
