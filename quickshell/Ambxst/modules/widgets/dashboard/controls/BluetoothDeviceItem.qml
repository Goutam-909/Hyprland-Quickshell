pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

// One Bluetooth device row. Click to expand → Connect / Disconnect / Forget.
Item {
    id: root

    required property BluetoothDevice device

    property bool expanded: false

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    Behavior on implicitHeight {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: MacStyle.medium
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 58

            Rectangle {
                anchors.fill: parent
                color: area.containsMouse ? MacStyle.cardHover : "transparent"
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: MacStyle.rowPadding
                anchors.rightMargin: MacStyle.rowPadding
                spacing: 10

                MacIconTile {
                    tint: (root.device?.connected ?? false) ? MacStyle.tileBlue : MacStyle.tileGray
                    glyph: {
                        const icon = root.device?.icon ?? "bluetooth";
                        if (icon.includes("audio-headset") || icon.includes("headphone"))
                            return Icons.headphones;
                        if (icon.includes("input-keyboard"))
                            return Icons.keyboard;
                        if (icon.includes("input-mouse"))
                            return Icons.mouse;
                        if (icon.includes("phone"))
                            return Icons.phone;
                        if (icon.includes("watch"))
                            return Icons.watch;
                        if (icon.includes("input-gaming") || icon.includes("gamepad"))
                            return Icons.gamepad;
                        if (icon.includes("printer"))
                            return Icons.printer;
                        if (icon.includes("camera"))
                            return Icons.camera;
                        if (icon.includes("audio-speakers") || icon.includes("speaker"))
                            return Icons.speaker;
                        return Icons.bluetooth;
                    }
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: root.device?.name ?? "Unknown device"
                        elide: Text.ElideRight
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsBody
                        color: MacStyle.label
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: (root.device?.connected ?? false) || (root.device?.paired ?? false) || root.expanded
                        text: {
                            let status = "";
                            if (root.device?.connected) {
                                status = "Connected";
                            } else if (root.device?.paired) {
                                status = "Not Connected";
                            } else {
                                status = "Not paired";
                            }
                            if (root.device?.batteryAvailable) {
                                status += ` · ${root.device.battery}%`;
                            }
                            return status;
                        }
                        elide: Text.ElideRight
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsSmall
                        color: MacStyle.labelSecondary
                    }
                }

                Text {
                    visible: root.device?.batteryAvailable ?? false
                    text: {
                        const battery = root.device?.battery ?? 0;
                        if (battery > 80)
                            return Icons.batteryFull;
                        if (battery > 60)
                            return Icons.batteryHigh;
                        if (battery > 40)
                            return Icons.batteryMedium;
                        if (battery > 20)
                            return Icons.batteryLow;
                        return Icons.batteryEmpty;
                    }
                    font.family: Icons.font
                    font.pixelSize: 22
                    color: {
                        const battery = root.device?.battery ?? 0;
                        if (battery > 40)
                            return MacStyle.success;
                        if (battery > 20)
                            return MacStyle.warning;
                        return MacStyle.destructive;
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: MacStyle.rowPadding + 44
            Layout.rightMargin: MacStyle.rowPadding
            Layout.bottomMargin: 12
            spacing: 8
            visible: root.expanded
            opacity: root.expanded ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: MacStyle.fast
                }
            }

            MacButton {
                visible: root.device?.paired ?? false
                text: "Forget"
                destructive: true
                onClicked: root.device?.forget()
            }

            Item {
                Layout.fillWidth: true
            }

            MacButton {
                primary: !(root.device?.connected ?? false)
                text: (root.device?.connected ?? false) ? "Disconnect" : "Connect"
                onClicked: {
                    if (root.device?.connected) {
                        root.device.disconnect();
                    } else {
                        root.device.connect();
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: MacStyle.rowPadding + MacStyle.tileSize + 12
            Layout.preferredHeight: 1
            color: MacStyle.separator
        }
    }
}
