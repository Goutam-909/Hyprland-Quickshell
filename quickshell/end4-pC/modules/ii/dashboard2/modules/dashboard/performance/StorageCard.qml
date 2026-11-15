pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Layouts
import qs.modules.common

StyledRect {
    id: root

    readonly property color accent: Appearance.m3colors.m3secondary

    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.large

    implicitWidth: layout.implicitWidth + layout.anchors.margins * 2
    // Match NetworkCard's height so the Storage/Network/Memory row lines
    // up evenly instead of each card being only as tall as its content.
    implicitHeight: Config.options.caelestiaDashboard.dashboard.sizes.perfNetworkCardHeight

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.dashboard.padding.large
        spacing: Appearance.dashboard.spacing.large

        CircularProgress {
            fgColour: root.accent
            value: SystemUsage.storagePerc
            implicitSize: usageColumn.implicitHeight + thickness + Appearance.dashboard.padding.large * 2
            startAngle: -225
            sweepAngle: 270

            ColumnLayout {
                id: usageColumn

                anchors.centerIn: parent
                spacing: 0

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "hard_drive"
                    color: root.accent
                    font.pointSize: Appearance.dashboard.fontSize.normal
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: isNaN(SystemUsage.storagePerc) ? "…%" : Math.round(SystemUsage.storagePerc * 100) + "%"
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

        ColumnLayout {
            Layout.minimumWidth: Config.options.caelestiaDashboard.dashboard.sizes.perfStorageTextWidth
            spacing: Appearance.dashboard.spacing.small

            StyledText {
                text: qsTr("Storage")
                color: Appearance.m3colors.m3primary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            StyledText {
                color: root.accent
                font.pointSize: Appearance.dashboard.fontSize.large
                text: {
                    const totalFmt = SystemUsage.formatKib(SystemUsage.storageTotal);
                    const kibPerUnit = SystemUsage.storageTotal / totalFmt.value;
                    const usedVal = SystemUsage.storageUsed / kibPerUnit;
                    return `${usedVal.toFixed(1)} / ${totalFmt.value.toFixed(1)} ${totalFmt.unit}`;
                }
            }
        }
    }
}



