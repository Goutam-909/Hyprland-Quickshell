pragma ComponentBehavior: Bound

import "performance"
import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root

    readonly property bool showBattery: (UPower.displayDevice?.isLaptopBattery ?? false) && Config.options.caelestiaDashboard.dashboard.performance.showBattery
    readonly property bool anyEnabled: Config.options.caelestiaDashboard.dashboard.performance.showCpu || Config.options.caelestiaDashboard.dashboard.performance.showGpu || Config.options.caelestiaDashboard.dashboard.performance.showMemory || Config.options.caelestiaDashboard.dashboard.performance.showStorage || Config.options.caelestiaDashboard.dashboard.performance.showNetwork || root.showBattery

    implicitWidth: placeholder.active ? Config.options.caelestiaDashboard.dashboard.sizes.perfPlaceholderWidth : content.implicitWidth
    implicitHeight: placeholder.active ? placeholder.implicitHeight + Appearance.dashboard.padding.large * 2 : content.implicitHeight

    Component.onCompleted: {
        SystemUsage.active = true;
        NetworkUsage.active = true;
    }
    Component.onDestruction: {
        SystemUsage.active = false;
        NetworkUsage.active = false;
    }

    Loader {
        id: placeholder

        anchors.centerIn: parent
        active: !root.anyEnabled
        asynchronous: true

        sourceComponent: ColumnLayout {
            spacing: Appearance.dashboard.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "tune"
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.extraLarge
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No widgets enabled")
                color: Appearance.m3colors.m3primary
                font.pointSize: Appearance.dashboard.fontSize.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Enable widgets in Config.options.caelestiaDashboard.dashboard.performance")
                color: Appearance.m3colors.m3secondary
                font.pointSize: Appearance.dashboard.fontSize.small
            }
        }
    }

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.dashboard.spacing.normal
        visible: !placeholder.active

        ColumnLayout {
            id: mainColumn

            Layout.fillWidth: true
            spacing: Appearance.dashboard.spacing.normal

            RowLayout {
                spacing: Appearance.dashboard.spacing.normal
                visible: Config.options.caelestiaDashboard.dashboard.performance.showCpu || Config.options.caelestiaDashboard.dashboard.performance.showGpu

                HeroCard {
                    Layout.fillWidth: true
                    visible: Config.options.caelestiaDashboard.dashboard.performance.showCpu

                    icon: "memory"
                    label: qsTr("CPU")
                    subLabel: SystemUsage.cpuName
                    usage: SystemUsage.cpuPerc
                    temperature: SystemUsage.cpuTemp
                    accent: Appearance.m3colors.m3primary
                }

                HeroCard {
                    Layout.fillWidth: true
                    visible: Config.options.caelestiaDashboard.dashboard.performance.showGpu

                    icon: "desktop_windows"
                    label: qsTr("GPU")
                    subLabel: SystemUsage.gpuName
                    usage: SystemUsage.gpuPerc
                    temperature: SystemUsage.gpuTemp
                    accent: Appearance.m3colors.m3secondary
                }
            }

            RowLayout {
                spacing: Appearance.dashboard.spacing.normal
                visible: Config.options.caelestiaDashboard.dashboard.performance.showStorage || Config.options.caelestiaDashboard.dashboard.performance.showMemory

                StorageCard {
                    visible: Config.options.caelestiaDashboard.dashboard.performance.showStorage
                }

                NetworkCard {
                    Layout.fillWidth: true
                    visible: Config.options.caelestiaDashboard.dashboard.performance.showNetwork
                }

                MemoryCard {
                    visible: Config.options.caelestiaDashboard.dashboard.performance.showMemory
                }
            }
        }

        BatteryTank {
            Layout.fillHeight: true
        }
    }
}
