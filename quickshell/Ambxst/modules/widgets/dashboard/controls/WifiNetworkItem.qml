pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

// One Wi-Fi network row (macOS list style). Click to expand → connect / password.
Item {
    id: root

    required property WifiAccessPoint network

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
            Layout.preferredHeight: 54

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

                // ✓ for the connected network (keeps names aligned)
                Item {
                    Layout.preferredWidth: 20
                    Layout.fillHeight: true
                    Text {
                        anchors.centerIn: parent
                        visible: root.network?.active ?? false
                        text: Icons.accept
                        font.family: Icons.font
                        font.pixelSize: 16
                        color: MacStyle.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: root.network?.ssid ?? "Unknown"
                        elide: Text.ElideRight
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsBody
                        color: MacStyle.label
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: (root.network?.active ?? false) || root.expanded
                        text: (root.network?.active ?? false) ? "Connected" : ((root.network?.isSecure ?? false) ? "Secured" : "Open")
                        elide: Text.ElideRight
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsSmall
                        color: MacStyle.labelSecondary
                    }
                }

                Rectangle {
                    visible: root.network?.is5GHz ?? false
                    implicitWidth: badge.implicitWidth + 10
                    implicitHeight: 20
                    radius: 5
                    color: MacStyle.segmentTrack
                    Text {
                        id: badge
                        anchors.centerIn: parent
                        text: "5G"
                        font.family: MacStyle.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: MacStyle.labelSecondary
                    }
                }

                Text {
                    visible: root.network?.isSecure ?? false
                    text: Icons.lock
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: MacStyle.labelSecondary
                }

                Text {
                    text: {
                        const strength = root.network?.strength ?? 0;
                        if (strength > 80)
                            return Icons.wifiHigh;
                        if (strength > 55)
                            return Icons.wifiMedium;
                        if (strength > 30)
                            return Icons.wifiLow;
                        return Icons.wifiNone;
                    }
                    font.family: Icons.font
                    font.pixelSize: 21
                    color: (root.network?.active ?? false) ? MacStyle.accent : MacStyle.label
                }
            }
        }

        // expanded: password + action
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: MacStyle.rowPadding + 30
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

            MacTextField {
                id: passwordInput
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                visible: root.network?.askingPassword ?? false
                placeholderText: "Password"
                password: true
                onAccepted: {
                    if (text.length > 0) {
                        NetworkService.changePassword(root.network, text);
                        text = "";
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item {
                    Layout.fillWidth: true
                }
                MacButton {
                    primary: !(root.network?.active ?? false)
                    text: (root.network?.active ?? false) ? "Disconnect" : "Connect"
                    onClicked: {
                        if (root.network?.active) {
                            NetworkService.disconnectWifiNetwork();
                        } else {
                            NetworkService.connectToWifiNetwork(root.network);
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: MacStyle.rowPadding + 26
            Layout.preferredHeight: 1
            color: MacStyle.separator
        }
    }
}
