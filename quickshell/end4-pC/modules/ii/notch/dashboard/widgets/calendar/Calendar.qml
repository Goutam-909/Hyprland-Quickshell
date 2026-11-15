import QtQuick
import QtQuick.Layouts
import "calendar_layout.js" as CalendarLayout
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets

ColumnLayout {
    id: root
    spacing: 6

    property var shownDate: new Date()
    readonly property var todayDate: new Date()
    readonly property var layoutResult: CalendarLayout.getCalendarLayout(shownDate, true)

    RowLayout {
        Layout.fillWidth: true

        RippleButtonWithIcon {
            materialIcon: "chevron_left"
            implicitWidth: 28; implicitHeight: 28
            onClicked: root.shownDate = new Date(root.shownDate.getFullYear(), root.shownDate.getMonth() - 1, 1)
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.weight: Font.Bold
            text: Qt.formatDate(root.shownDate, "MMMM yyyy")
        }

        RippleButtonWithIcon {
            materialIcon: "chevron_right"
            implicitWidth: 28; implicitHeight: 28
            onClicked: root.shownDate = new Date(root.shownDate.getFullYear(), root.shownDate.getMonth() + 1, 1)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: CalendarLayout.weekDays
            delegate: StyledText {
                required property var modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 11
                color: C.Appearance.colors.colSubtext
                text: modelData.day
            }
        }
    }

    Repeater {
        model: root.layoutResult.calendar
        delegate: RowLayout {
            required property var modelData
            required property int index
            Layout.fillWidth: true
            Repeater {
                model: modelData
                delegate: CalendarDayButton {
                    required property var modelData
                    Layout.fillWidth: true
                    dayNumber: modelData.day
                    isToday: modelData.today === 1
                    isOtherMonth: modelData.today === -1
                }
            }
        }
    }
}
