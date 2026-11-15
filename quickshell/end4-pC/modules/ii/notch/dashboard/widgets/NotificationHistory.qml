import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        StyledText {
            Layout.fillWidth: true
            font.weight: Font.Bold
            text: "Notifications"
        }
        RippleButtonWithIcon {
            visible: Notifications.list.length > 0
            materialIcon: "clear_all"
            implicitWidth: 24; implicitHeight: 24
            onClicked: Notifications.list = []
        }
    }

    StyledText {
        visible: Notifications.list.length === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        color: C.Appearance.colors.colSubtext
        text: "No notifications"
    }

    ListView {
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, 220)
        clip: true
        spacing: 4
        model: Notifications.list
        delegate: StyledRectangle {
            required property var modelData
            width: ListView.view.width
            implicitHeight: row.implicitHeight + 16
            contentLayer: StyledRectangle.ContentLayer.Group
            radius: C.Appearance.rounding.small

            RowLayout {
                id: row
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                CustomIcon {
                    visible: modelData.appIcon !== ""
                    source: modelData.appIcon
                    width: 22
                    height: 22
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.weight: Font.Bold
                        font.pixelSize: 12
                        text: modelData.summary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        elide: Text.ElideRight
                        font.pixelSize: 11
                        color: C.Appearance.colors.colSubtext
                        text: modelData.body
                    }
                }

                RippleButtonWithIcon {
                    materialIcon: "close"
                    implicitWidth: 22; implicitHeight: 22
                    onClicked: Notifications.discardNotification(modelData.id)
                }
            }
        }
    }
}
