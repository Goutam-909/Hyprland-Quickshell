pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Layouts
import qs.modules.common

StyledRect {
    id: root

    readonly property color accent: Appearance.m3colors.m3tertiary

    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.normal

    implicitWidth: layout.implicitWidth + Appearance.dashboard.padding.large * 2+16
    // Match NetworkCard's height so the Storage/Network/Memory row lines
    // up evenly instead of each card being only as tall as its content.
    implicitHeight: Config.options.caelestiaDashboard.dashboard.sizes.perfNetworkCardHeight

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Appearance.dashboard.spacing.small

        RowLayout {
            Layout.leftMargin: -Appearance.dashboard.padding.small
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                text: "memory_alt"
                fill: 1
                color: root.accent
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            StyledText {
                text: qsTr("Memory")
                color: Appearance.m3colors.m3primary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }
        }

        CircularProgress {
            Layout.topMargin: Appearance.dashboard.spacing.large
            Layout.alignment: Qt.AlignHCenter
            implicitSize: usageColumn.implicitHeight + thickness + Appearance.dashboard.padding.large * 2
            startAngle: -225
            sweepAngle: 270

            fgColour: root.accent
            value: SystemUsage.memPerc

            ColumnLayout {
                id: usageColumn

                anchors.centerIn: parent
                anchors.verticalCenterOffset: Appearance.dashboard.padding.small
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: isNaN(SystemUsage.memPerc) ? "…%" : Math.round(SystemUsage.memPerc * 100) + "%"
                    color: root.accent
                    font.pointSize: Appearance.dashboard.fontSize.large
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Used")
                    color: Appearance.m3colors.m3secondary
                    font.pointSize: Appearance.dashboard.fontSize.small
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Appearance.m3colors.m3secondary
            font.pointSize: Appearance.dashboard.fontSize.small
            text: {
                const totalFmt = SystemUsage.formatKib(SystemUsage.memTotal);
                const kibPerUnit = SystemUsage.memTotal / totalFmt.value;
                const usedVal = SystemUsage.memUsed / kibPerUnit;
                return `${usedVal.toFixed(1)} / ${totalFmt.value.toFixed(1)} ${totalFmt.unit}`;
            }
        }
    }
}



