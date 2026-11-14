pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: root.contentWidth
            x: root.sideMargin
            spacing: 10

            PanelTitlebar {
                id: titlebar
                Layout.fillWidth: true
                title: "Wi-Fi"
                statusText: NetworkService.wifiConnecting ? "Connecting..." : (NetworkService.wifiStatus === "limited" ? "Limited" : "")
                statusColor: NetworkService.wifiStatus === "limited" ? MacStyle.warning : MacStyle.accent
                showToggle: true
                toggleChecked: NetworkService.wifiStatus !== "disabled"

                actions: [
                    {
                        icon: Icons.globe,
                        tooltip: "Open captive portal",
                        enabled: NetworkService.wifiStatus === "limited",
                        onClicked: function () {
                            NetworkService.openPublicWifiPortal();
                        }
                    },
                    {
                        icon: Icons.popOpen,
                        tooltip: "Network settings",
                        onClicked: function () {
                            NetworkService.openNetworkSettings();
                        }
                    },
                    {
                        icon: Icons.sync,
                        tooltip: "Rescan networks",
                        enabled: NetworkService.wifiEnabled,
                        loading: NetworkService.wifiScanning || NetworkService.isUpdating,
                        onClicked: function () {
                            NetworkService.rescanWifi();
                        }
                    }
                ]

                onToggleChanged: checked => {
                    NetworkService.enableWifi(checked);
                    if (checked) {
                        NetworkService.rescanWifi();
                    }
                }
            }

            MacHeader {
                text: "Networks"
                visible: networkRepeater.count > 0
            }

            MacGroup {
                Repeater {
                    id: networkRepeater
                    model: NetworkService.friendlyWifiNetworks

                    delegate: WifiNetworkItem {
                        required property var modelData
                        network: modelData
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 48
                visible: networkRepeater.count === 0 && !NetworkService.wifiScanning
                text: NetworkService.wifiEnabled ? "No networks found" : "Wi-Fi is disabled"
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsBody
                color: MacStyle.labelSecondary
            }
        }
    }
}
