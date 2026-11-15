pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Layouts
import qs.modules.common

StyledRect {
    id: root

    required property string icon
    required property string label
    required property real percentage // 0..1
    required property string usageText
    required property color accent

    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.large

    implicitWidth: layout.implicitWidth + Appearance.dashboard.padding.large * 2
    implicitHeight: layout.implicitHeight + Appearance.dashboard.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Appearance.dashboard.spacing.small

        CircularProgress {
            id: ring

            Layout.alignment: Qt.AlignHCenter

            fgColour: root.accent
            startAngle: -225
            sweepAngle: 270
            strokeWidth: Appearance.dashboard.padding.small
            implicitSize: usageColumn.implicitHeight + thickness + Appearance.dashboard.padding.large * 2
            value: root.percentage

            ColumnLayout {
                id: usageColumn

                anchors.centerIn: parent
                spacing: 0

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.icon
                    color: root.accent
                    fill: 1
                    font.pointSize: Appearance.dashboard.fontSize.normal
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: isNaN(root.percentage) ? "…" : Math.round(root.percentage * 100) + "%"
                    color: root.accent
                    font.pointSize: Appearance.dashboard.fontSize.large
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.label
                    color: Appearance.m3colors.m3secondary
                    font.pointSize: Appearance.dashboard.fontSize.small
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.usageText
            color: Appearance.m3colors.m3secondary
            font.pointSize: Appearance.dashboard.fontSize.smaller
        }
    }
}



