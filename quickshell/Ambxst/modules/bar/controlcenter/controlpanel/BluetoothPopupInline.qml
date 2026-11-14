// Widgets/controlpanel/BluetoothPopupInline.qml
import QtQuick
import QtQuick.Layouts
import qs.Services as Services
import qs.common
import qs.modules.theme

/**
 * Bluetooth Device List Page
 * Header (title / power / scan) · scrollable device list · footer (settings / done).
 * Every action goes through Services.Bluetooth → BluetoothService/BluetoothDevice.
 */
Item {
    id: root

    property bool open: false
    signal requestClose()

    // Kept here (not on the delegate) so it survives ListView model resets.
    property string expandedAddress: ""

    onOpenChanged: {
        if (open) {
            Services.Bluetooth.refreshForUI()
            // If Bluetooth is off this is remembered and runs once it's powered on.
            Services.Bluetooth.startDiscovery()
        } else {
            Services.Bluetooth.stopDiscovery()
            expandedAddress = ""
        }
    }

    // ── Page ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Styling.radius(8)  // matches the outer BarPopup's own radius
        color: "transparent"//Appearance.colors.colSurfaceContainerHigh
        clip: true
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0//12
            spacing: 8

            // Header: title · scan · power switch
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: "Bluetooth"
                    font.family: Appearance.font.family.main
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                }

                CcCircleButton {
                    icon: "autorenew"
                    enabled: Services.Bluetooth.powered
                    spinning: Services.Bluetooth.discovering
                    iconColor: Services.Bluetooth.discovering
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colOnSurfaceVariant
                    onClicked: {
                        if (Services.Bluetooth.discovering) Services.Bluetooth.stopDiscovery()
                        else Services.Bluetooth.startDiscovery()
                    }
                }

                CcPowerSwitch {
                    checked: Services.Bluetooth.powered
                    onToggled: Services.Bluetooth.togglePower()
                }
            }

            // Device list + empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: deviceList
                    anchors.fill: parent
                    spacing: 4
                    clip: true
                    cacheBuffer: 200
                    reuseItems: false
                    boundsBehavior: Flickable.StopAtBounds

                    model: Services.Bluetooth.devices

                    delegate: Rectangle {
                        id: deviceItem
                        required property var modelData

                        readonly property string address: modelData?.address ?? ""
                        readonly property bool isConnected: modelData?.connected ?? false
                        readonly property bool isPaired: modelData?.paired ?? false
                        readonly property bool isBusy: modelData?.busy ?? false
                        readonly property bool expanded: address !== ""
                            && root.expandedAddress === address
                            && (isPaired || isConnected)

                        width: deviceList.width
                        height: deviceColumn.implicitHeight + 24
                        radius: Appearance.rounding.large
                        color: itemArea.pressed
                            ? Appearance.colors.colLayer2Active
                            : (itemArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colSurfaceContainerHigh)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        // Main item click area (under the buttons)
                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (deviceItem.isBusy) return
                                if (deviceItem.isPaired || deviceItem.isConnected) {
                                    root.expandedAddress = deviceItem.expanded ? "" : deviceItem.address
                                } else {
                                    // Unpaired: pair + trust + connect in one go
                                    Services.Bluetooth.pairDevice(deviceItem.modelData)
                                }
                            }
                        }

                        Column {
                            id: deviceColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            // Device info row
                            RowLayout {
                                width: parent.width
                                spacing: 12

                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    radius: 20
                                    color: deviceItem.isConnected
                                        ? Appearance.colors.colPrimaryContainer
                                        : Appearance.colors.colSurfaceContainerHighest

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        icon: Services.Bluetooth.getDeviceIcon(deviceItem.modelData)
                                        iconSize: 20
                                        color: deviceItem.isConnected
                                            ? Appearance.colors.colOnPrimaryContainer
                                            : Appearance.colors.colOnSurfaceVariant
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: deviceItem.modelData?.name ?? "Unknown Device"
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnSurface
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: {
                                            const d = deviceItem.modelData
                                            if (deviceItem.isBusy) return (d?.busyLabel || "Working") + "…"
                                            if (!deviceItem.isConnected && (d?.lastError ?? "") !== "") return "Failed · tap to retry"
                                            if (deviceItem.isConnected)
                                                return (d?.batteryAvailable ?? false) ? ("Connected · " + d.battery + "%") : "Connected"
                                            if (deviceItem.isPaired) return "Paired"
                                            return "Available"
                                        }
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: 11
                                        color: deviceItem.isConnected
                                            ? Appearance.colors.colPrimary
                                            : ((deviceItem.modelData?.lastError ?? "") !== ""
                                                ? Appearance.colors.colError
                                                : Appearance.colors.colOnSurfaceVariant)
                                        elide: Text.ElideRight
                                    }
                                }

                                // Spinner / chevron
                                Item {
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: 20
                                    implicitHeight: 20

                                    Rectangle {
                                        visible: deviceItem.isBusy
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: "transparent"
                                        border.width: 2
                                        border.color: Appearance.colors.colPrimary

                                        Rectangle {
                                            width: 4
                                            height: 4
                                            radius: 2
                                            color: Appearance.colors.colPrimary
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: 2
                                        }

                                        RotationAnimation on rotation {
                                            running: deviceItem.isBusy
                                            from: 0
                                            to: 360
                                            duration: 1000
                                            loops: Animation.Infinite
                                        }
                                    }

                                    MaterialSymbol {
                                        visible: !deviceItem.isBusy && (deviceItem.isPaired || deviceItem.isConnected)
                                        anchors.centerIn: parent
                                        icon: "chevron_right"
                                        iconSize: 20
                                        color: Appearance.colors.colOnSurfaceVariant
                                        rotation: deviceItem.expanded ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }

                            // Action buttons (expanded state)
                            RowLayout {
                                visible: deviceItem.expanded
                                width: parent.width
                                spacing: 8

                                CcPillButton {
                                    visible: !deviceItem.isConnected && deviceItem.isPaired
                                    label: "Connect"
                                    labelColor: Appearance.colors.colOnPrimary
                                    baseColor: Appearance.colors.colPrimary
                                    hoverColor: Appearance.colors.colPrimaryHover
                                    activeColor: Appearance.colors.colPrimaryActive
                                    enabled: !deviceItem.isBusy
                                    onClicked: {
                                        Services.Bluetooth.connectDevice(deviceItem.modelData)
                                        root.expandedAddress = ""
                                    }
                                }

                                CcPillButton {
                                    visible: deviceItem.isConnected
                                    label: "Disconnect"
                                    enabled: !deviceItem.isBusy
                                    onClicked: {
                                        Services.Bluetooth.disconnectDevice(deviceItem.modelData)
                                        root.expandedAddress = ""
                                    }
                                }

                                CcPillButton {
                                    visible: deviceItem.isPaired
                                    label: "Forget"
                                    labelColor: Appearance.colors.colError
                                    enabled: !deviceItem.isBusy
                                    onClicked: {
                                        Services.Bluetooth.forgetDevice(deviceItem.modelData)
                                        root.expandedAddress = ""
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: deviceList.count === 0
                    spacing: 10

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        icon: Services.Bluetooth.powered ? "bluetooth_searching" : "bluetooth_disabled"
                        iconSize: 48
                        color: Appearance.colors.colOnSurfaceVariant
                        opacity: 0.4
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !Services.Bluetooth.powered ? "Bluetooth is off"
                            : (Services.Bluetooth.discovering ? "Searching for devices…" : "No devices found")
                        font.family: Appearance.font.family.main
                        font.pixelSize: 13
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }

            // Footer: settings · done
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: 8

                CcCircleButton {
                    icon: "open_in_new"
                    onClicked: Services.Bluetooth.openSettings()
                }

                Item { Layout.fillWidth: true }

                CcPillButton {
                    icon: "done"
                    label: "Done"
                    labelColor: Appearance.colors.colOnSurfaceVariant
                    onClicked: root.requestClose()
                }
            }
        }
    }
}
