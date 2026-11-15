import QtQuick
import QtQuick.Layouts
import "calendar"
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets

ColumnLayout {
    id: root
    implicitWidth: 420
    spacing: 14

    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        StyledRectangle {
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            contentLayer: StyledRectangle.ContentLayer.Group
            radius: C.Appearance.rounding.normal
            implicitHeight: calendar.implicitHeight + 20

            Calendar {
                id: calendar
                anchors.fill: parent
                anchors.margins: 10
            }
        }

        StyledRectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentLayer: StyledRectangle.ContentLayer.Group
            radius: C.Appearance.rounding.normal
            implicitHeight: controlsCol.implicitHeight + 20

            QuickControls {
                id: controlsCol
                anchors.fill: parent
                anchors.margins: 10
            }
        }
    }

    StyledRectangle {
        Layout.fillWidth: true
        visible: MprisController.activePlayer !== null // TODO: verify against services/MprisController.qml
        contentLayer: StyledRectangle.ContentLayer.Group
        radius: C.Appearance.rounding.normal
        implicitHeight: player.implicitHeight + 20

        CompactPlayer {
            id: player
            anchors.fill: parent
            anchors.margins: 10
        }
    }

    StyledRectangle {
        Layout.fillWidth: true
        contentLayer: StyledRectangle.ContentLayer.Group
        radius: C.Appearance.rounding.normal
        implicitHeight: notifHistory.implicitHeight + 20

        NotificationHistory {
            id: notifHistory
            anchors.fill: parent
            anchors.margins: 10
        }
    }
}
