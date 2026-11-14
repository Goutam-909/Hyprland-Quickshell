// Widgets/controlpanel/Bluetooth.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services as Services
import qs.common

/**
 * Bluetooth Toggle Widget
 * Shows current Bluetooth status and provides quick access.
 * All state comes from Services.Bluetooth (→ BluetoothService), no local polling.
 */
Item {
    id: root
    implicitHeight: 60
    Layout.fillWidth: true

    signal toggleBluetoothPopup()

    function getBluetoothIcon() {
        if (!Services.Bluetooth.powered) {
            return "bluetooth_disabled"
        }
        if (Services.Bluetooth.connected) {
            return "bluetooth_connected"
        }
        return "bluetooth"
    }

    function getStatusText() {
        if (!Services.Bluetooth.powered) {
            return "Off"
        }
        if (Services.Bluetooth.isProcessing) {
            return (Services.Bluetooth.busyLabel || "Working") + "…"
        }
        if (Services.Bluetooth.connected) {
            const n = Services.Bluetooth.connectedCount
            const name = Services.Bluetooth.deviceName
            // Device list may not be loaded yet (only the count is polled in the background)
            if (name === "") return n > 1 ? (n + " connected") : "Connected"
            return n > 1 ? (name + " +" + (n - 1)) : name
        }
        return "Tap to connect"
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 35
        color: card.pressed
        ? Appearance.colors.colLayer2Active
        : (card.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colSurfaceContainerHigh)
        scale: card.pressed ? 0.80 : 1

        property bool hovered: false
        property bool pressed: false

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            // Icon circle - Toggle power
            Rectangle {
                id: iconCircle
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                implicitWidth: 40
                implicitHeight: 40
                radius: 25
                color: Services.Bluetooth.powered
                ? Appearance.colors.colPrimary
                : Appearance.colors.colSurfaceContainerHighest
                scale: iconArea.pressed ? 0.92 : 1

                MaterialSymbol {
                    anchors.centerIn: parent
                    icon: root.getBluetoothIcon()
                    iconSize: 24
                    color: Services.Bluetooth.powered
                    ? Appearance.colors.colOnPrimary
                    : Appearance.colors.colOnSurfaceVariant
                }

                MouseArea {
                    id: iconArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        Services.Bluetooth.togglePower()
                        mouse.accepted = true
                    }
                }

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            // Text labels
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Bluetooth"
                    color: Appearance.colors.colOnSurface
                    font.family: Appearance.font.family.main
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.getStatusText()
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Appearance.font.family.main
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        // Main clickable area - Open device list
        MouseArea {
            id: mainArea
            anchors.fill: parent
            anchors.leftMargin: 70
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onPressed: card.pressed = true
            onReleased: card.pressed = false
            onClicked: {
                root.toggleBluetoothPopup()
            }
        }
    }
}
