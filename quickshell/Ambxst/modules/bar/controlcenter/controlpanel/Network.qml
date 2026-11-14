// Widgets/controlpanel/Network.qml - Material 3 Themed
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Services as Services
import qs.common

Item {
    id: root
    implicitHeight: 60
    Layout.fillWidth: true

    property bool menuOpen: false
    signal toggleWifiPopup()

    readonly property bool isConnected: Services.Network.connected

    // Read directly from the singleton — no local timer or process needed.
    // Services.Network already polls nmcli every 2s and keeps this up to date.
    readonly property bool wifiEnabled: Services.Network.wifiEnabled

    function statusText() {
        if (!root.wifiEnabled) return "Off"
        if (Services.Network.connecting) {
            return Services.Network.connectingSsid !== ""
                ? "Connecting to " + Services.Network.connectingSsid + "…"
                : "Connecting…"
        }
        if (Services.Network.connected) {
            const name = Services.Network.connectedSsid || "Connected"
            return Services.Network.limited ? name + " · No internet" : name
        }
        return "Tap to connect"
    }

    function wifiIcon(enabled, connected, strength) {
        if (!enabled)       return "android_wifi_4_bar_off"
            if (!connected)     return "android_wifi_4_bar_plus"
                if (strength >= 80) return "android_wifi_4_bar"
                    if (strength >= 60) return "android_wifi_3_bar"
                        if (strength >= 40) return "wifi_2_bar"
                            return "wifi_1_bar"
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

            // Icon circle — clicking calls the singleton's toggleWifi()
            Rectangle {
                id: iconCircle
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                implicitWidth: 40
                implicitHeight: 40
                radius: 25
                color: root.wifiEnabled
                ? Appearance.colors.colPrimary
                : Appearance.colors.colSurfaceContainerHighest
                scale: iconArea.pressed ? 0.92 : 1

                MaterialSymbol {
                    anchors.centerIn: parent
                    icon: wifiIcon(root.wifiEnabled, root.isConnected, Services.Network.signalStrength)
                    iconSize: 24
                    color: root.wifiEnabled
                    ? Appearance.colors.colOnPrimary
                    : Appearance.colors.colOnSurfaceVariant
                }

                MouseArea {
                    id: iconArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        // Use the singleton's toggle — it handles the nmcli call
                        // and updates wifiEnabled reactively, no local proc needed
                        Services.Network.toggleWifi()
                        mouse.accepted = true
                    }
                }

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            // Text
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Wi-Fi"
                    color: Appearance.colors.colOnSurface
                    font.family: Appearance.font.family.main
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.statusText()
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Appearance.font.family.main
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: mainArea
            anchors.fill: parent
            anchors.leftMargin: 70
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered:  card.hovered = true
            onExited:   card.hovered = false
            onPressed:  card.pressed = true
            onReleased: card.pressed = false
            onClicked:  root.toggleWifiPopup()
        }
    }
}
