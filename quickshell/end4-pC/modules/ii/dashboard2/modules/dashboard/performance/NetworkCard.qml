pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Layouts
import qs.modules.common

StyledRect {
    id: root

    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.large

    implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.perfNetworkCardWidth
    implicitHeight: Config.options.caelestiaDashboard.dashboard.sizes.perfNetworkCardHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.dashboard.padding.large
        anchors.bottomMargin: Appearance.dashboard.padding.normal
        spacing: 0

        RowLayout {
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                text: "swap_vert"
                color: Appearance.m3colors.m3primary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            StyledText {
                text: qsTr("Network")
                color: Appearance.m3colors.m3primary
            }
        }

        Item {
            Layout.topMargin: Appearance.dashboard.spacing.normal
            Layout.bottomMargin: Appearance.dashboard.spacing.small
            Layout.fillWidth: true
            Layout.fillHeight: true

            Sparkline {
                id: sparkline

                property real targetMax: 1024
                property real smoothMax: targetMax

                anchors.fill: parent
                line1: NetworkUsage.uploadHistory
                line1Color: Appearance.m3colors.m3secondary
                line1FillAlpha: 0.15
                line2: NetworkUsage.downloadHistory
                line2Color: Appearance.m3colors.m3tertiary
                line2FillAlpha: 0.2
                maxValue: smoothMax
                historyLength: NetworkUsage.historyLength
                sampleInterval: Config.options.caelestiaDashboard.dashboard.resourceUpdateInterval

                onLine2Changed: {
                    targetMax = Math.max(NetworkUsage.downloadBuffer.maximum, NetworkUsage.uploadBuffer.maximum, 1024);
                }

                Behavior on smoothMax {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: qsTr("Collecting data...")
                color: Appearance.m3colors.m3tertiary
                font.pointSize: Appearance.dashboard.fontSize.small
                visible: NetworkUsage.downloadBuffer.count < 2
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                text: "download"
                color: Appearance.m3colors.m3tertiary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            StyledText {
                text: qsTr("Download")
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.small
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    const fmt = NetworkUsage.formatBytes(NetworkUsage.downloadSpeed ?? 0);
                    return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                }
                color: Appearance.m3colors.m3tertiary
                font.pointSize: Appearance.dashboard.fontSize.small
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                text: "upload"
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            StyledText {
                text: qsTr("Upload")
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.small
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    const fmt = NetworkUsage.formatBytes(NetworkUsage.uploadSpeed ?? 0);
                    return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                }
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.small
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.dashboard.spacing.small

            MaterialIcon {
                text: "history"
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.normal
            }

            StyledText {
                text: qsTr("Total")
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.small
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    const down = NetworkUsage.formatBytesTotal(NetworkUsage.downloadTotal ?? 0);
                    const up = NetworkUsage.formatBytesTotal(NetworkUsage.uploadTotal ?? 0);
                    return (down && up) ? `↓${down.value.toFixed(1)}${down.unit} ↑${up.value.toFixed(1)}${up.unit}` : "↓0.0B ↑0.0B";
                }
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.small
            }
        }
    }
}



