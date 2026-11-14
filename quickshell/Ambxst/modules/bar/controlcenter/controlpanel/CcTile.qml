// controlpanel/CcTile.qml
// Big rounded tile: round icon + title + subtitle. Used for Wi-Fi, Bluetooth,
// Updates and Wallpaper.
//   clicked()      – body click (open a page / run an action)
//   iconClicked()  – click on the round icon (quick toggle, e.g. Wi-Fi on/off)
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.modules.theme

Rectangle {
    id: root

    property string icon: ""          // a glyph, e.g. Icons.wifiHigh
    property string title: ""
    property string subtitle: ""
    property bool active: false       // round icon turns accent colored
    property bool dimmed: false
    property int circleSize: 48
    property int iconPixelSize: 22

    signal clicked()
    signal iconClicked()
    signal rightClicked()

    implicitHeight: 88
    radius: 24
    opacity: dimmed ? 0.55 : 1
    color: bodyArea.containsMouse
           ? Appearance.colors.colLayer3Hover
           : Appearance.colors.colSurfaceContainerHigh

    Behavior on color   { ColorAnimation  { duration: 150 } }
    Behavior on opacity { NumberAnimation { duration: 150 } }

    MouseArea {
        id: bodyArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => { if (m.button === Qt.RightButton) root.rightClicked(); else root.clicked() }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 12

        Rectangle {
            id: circle
            Layout.preferredWidth: root.circleSize
            Layout.preferredHeight: root.circleSize
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: root.active
                   ? Appearance.colors.colPrimary
                   : Appearance.colors.colSurfaceContainerHighest
            scale: iconArea.pressed ? 0.92 : 1.0

            Behavior on color { ColorAnimation  { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            Text {
                anchors.centerIn: parent
                font.family: Icons.font
                font.pixelSize: root.iconPixelSize
                text: root.icon
                color: root.active ? Appearance.colors.colOnPrimary
                                   : Appearance.colors.colOnSurface
            }

            MouseArea {
                id: iconArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.family: Appearance.font.family.main
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Appearance.colors.colOnSurface
            }
            Text {
                Layout.fillWidth: true
                text: root.subtitle
                elide: Text.ElideRight
                font.family: Appearance.font.family.main
                font.pixelSize: 12
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
