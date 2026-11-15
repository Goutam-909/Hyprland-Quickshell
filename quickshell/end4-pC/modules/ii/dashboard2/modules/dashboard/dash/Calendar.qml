pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Controls
import qs.modules.common

Column {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    padding: Appearance.dashboard.padding.large
    spacing: Appearance.dashboard.spacing.small

    DayOfWeekRow {
        id: days

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding

        delegate: StyledText {
            required property var model

            horizontalAlignment: Text.AlignHCenter
            text: model.shortName
            font.family: Appearance.font.family.main
            font.weight: 500
        }
    }

    MonthGrid {
        id: grid

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding

        spacing: 3

        delegate: Item {
            id: day

            required property var model

            implicitWidth: implicitHeight
            implicitHeight: text.implicitHeight + Appearance.dashboard.padding.small * 2

            StyledRect {
                anchors.centerIn: parent

                implicitWidth: parent.implicitHeight
                implicitHeight: parent.implicitHeight

                radius: Appearance.rounding.full
                color: model.today ? Appearance.m3colors.m3primary : "transparent"

                StyledText {
                    id: text

                    anchors.centerIn: parent

                    horizontalAlignment: Text.AlignHCenter
                    text: grid.locale.toString(day.model.date, "d")
                    color: day.model.today ? Appearance.m3colors.m3surface : day.model.month === grid.month ? Appearance.m3colors.m3secondary : Appearance.m3colors.m3tertiary
                }
            }
        }
    }
}



