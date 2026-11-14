pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    Component.onDestruction: {
        BluetoothService.stopDiscovery();
    }

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
                title: "Bluetooth"
                showToggle: true
                toggleChecked: BluetoothService.enabled

                actions: [
                    {
                        icon: Icons.popOpen,
                        tooltip: "Bluetooth settings",
                        onClicked: function () {
                            BluetoothService.openBluetoothSettings();
                        }
                    },
                    {
                        icon: Icons.sync,
                        tooltip: "Scan for devices",
                        enabled: BluetoothService.enabled,
                        loading: BluetoothService.discovering || BluetoothService.isUpdating,
                        onClicked: function () {
                            BluetoothService.startDiscovery();
                        }
                    }
                ]

                onToggleChanged: checked => {
                    BluetoothService.setEnabled(checked);
                    if (checked) {
                        BluetoothService.startDiscovery();
                    }
                }
            }

            MacHeader {
                text: "Devices"
                visible: deviceRepeater.count > 0
            }

            MacGroup {
                Repeater {
                    id: deviceRepeater
                    model: BluetoothService.friendlyDeviceList

                    delegate: BluetoothDeviceItem {
                        required property var modelData
                        device: modelData
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 48
                visible: deviceRepeater.count === 0 && !BluetoothService.discovering
                text: BluetoothService.enabled ? "No devices found" : "Bluetooth is disabled"
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsBody
                color: MacStyle.labelSecondary
            }
        }
    }
}
