import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets

Item {
    id: button

    required property int dayNumber
    required property bool isToday
    property bool isOtherMonth: false

    Layout.preferredWidth: 28
    Layout.preferredHeight: 28

    StyledRectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        radius: width / 2
        contentLayer: isToday ? StyledRectangle.ContentLayer.Control : StyledRectangle.ContentLayer.Background
        color: isToday ? C.Appearance.m3colors.m3primary : "transparent"

        Behavior on color {
            enabled: C.Config.options.notch.animDuration > 0
            ColorAnimation { duration: 150 }
        }

        StyledText {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Bold
            font.pixelSize: 11
            text: button.dayNumber
            color: {
                if (button.isToday) return C.Appearance.m3colors.m3onPrimary;
                if (button.isOtherMonth) return C.Appearance.colors.colSubtext;
                return C.Appearance.colors.colOnLayer1;
            }
        }
    }
}
