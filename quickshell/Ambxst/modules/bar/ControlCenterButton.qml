
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.modules.bar.controlcenter
import qs.config

Item {
    id: root

    required property var bar

    property bool vertical:     bar.orientation === "vertical"
    property bool isHovered:    false
    property bool layerEnabled: true

    property real radius:      0
    property real startRadius: radius
    property real endRadius:   radius

    property bool popupOpen: ccPopup.isOpen

    // ── Shared wifi icon — same logic as NetworkPill.statusIcon ────────────
    // Signal strength is kept fresh by a single centralized poll inside
    // NetworkService itself (see its strengthPoll Timer) rather than each
    // bar/control-center widget running its own duplicate Timer.
    readonly property string wifiIcon: {
        if (NetworkService.ethernet)
            return Icons.ethernet;
        if (!NetworkService.wifiEnabled || NetworkService.wifiStatus === "disabled")
            return Icons.wifiOff;
        if (NetworkService.wifiConnecting)
            return Icons.wifiNone;
        if (NetworkService.wifiStatus === "connected")
            // networkStrength can briefly read 0 right after connecting
            // (before the strength poll lands) — assume full bars until we
            // know otherwise rather than showing the wrong glyph.
            return NetworkService.wifiIconForStrength(NetworkService.networkStrength > 0 ? NetworkService.networkStrength : 100);
        if (NetworkService.wifiStatus === "limited")
            return Icons.wifiLow;
        // Wi-Fi enabled but not connected to anything — normal idle state.
        return Icons.wifiHigh;
    }

    // Wide enough to fit wifi + bt icons
    Layout.preferredWidth:  vertical ? -1 : 60
    Layout.preferredHeight: vertical ? 60 : -1
    Layout.fillWidth:  vertical
    Layout.fillHeight: !vertical

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: root.popupOpen ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        topLeftRadius:     root.vertical ? root.startRadius : root.startRadius
        topRightRadius:    root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius:  root.vertical ? root.endRadius   : root.startRadius
        bottomRightRadius: root.vertical ? root.endRadius   : root.endRadius

        Rectangle {
            anchors.fill: parent
            color:   Styling.srItem("overprimary")
            opacity: root.popupOpen ? 0 : (root.isHovered ? 0.25 : 0)
            radius:  parent.radius ?? 0
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration / 2 }
            }
        }

        // ── Horizontal bar: wifi · bt in a row ─────────────────────────────
        Row {
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: 7

            // Wi-Fi
            Text {
                font.family:    Icons.font
                font.pixelSize: 15
                anchors.verticalCenter: parent.verticalCenter
                text: root.wifiIcon
                color: {
                    if (root.popupOpen)                          return buttonBg.item
                        if (!NetworkService.wifiEnabled)             return Colors.outline
                            if (NetworkService.wifiStatus === "limited") return Colors.warning
                                if (NetworkService.wifi)                     return Styling.srItem("overprimary")
                                    return Colors.outline
                }
                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }
            }

            // Bluetooth
            Text {
                font.family:    Icons.font
                font.pixelSize: 15
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!BluetoothService.enabled)  return Icons.bluetoothOff
                        if (BluetoothService.connected) return Icons.bluetoothConnected
                            return Icons.bluetooth
                }
                color: {
                    if (root.popupOpen)             return buttonBg.item
                        if (!BluetoothService.enabled)  return Colors.outline
                            if (BluetoothService.connected) return Styling.srItem("overprimary")
                                return Colors.overBackground
                }
                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }
            }
        }

        // ── Vertical bar: column of two icons ──────────────────────────────
        Column {
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 7

            Text {
                font.family:    Icons.font
                font.pixelSize: 15
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.wifiIcon
                color: {
                    if (root.popupOpen)                          return buttonBg.item
                        if (!NetworkService.wifiEnabled)             return Colors.outline
                            if (NetworkService.wifiStatus === "limited") return Colors.warning
                                if (NetworkService.wifi)                     return Styling.srItem("overprimary")
                                    return Colors.outline
                }
                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }
            }

            Text {
                font.family:    Icons.font
                font.pixelSize: 15
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (!BluetoothService.enabled)  return Icons.bluetoothOff
                        if (BluetoothService.connected) return Icons.bluetoothConnected
                            return Icons.bluetooth
                }
                color: {
                    if (root.popupOpen)             return buttonBg.item
                        if (!BluetoothService.enabled)  return Colors.outline
                            if (BluetoothService.connected) return Styling.srItem("overprimary")
                                return Colors.overBackground
                }
                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            cursorShape:  Qt.PointingHandCursor
            onClicked:    ccPopup.toggle()
        }
    }

    BarPopup {
        id: ccPopup
        anchorItem:   buttonBg
        bar:          root.bar
        popupPadding: 16

        backgroundOpacityOverride: 1.0   // solid background
        showBorder: false

        // Ported content sizes itself (width follows its own internal
        // right-aligned content width, height follows its sliding pager)
        // — size the popup around it, same pattern the source design's
        // own host (Pfppanel.qml) uses.
        contentWidth:  ccContent.implicitWidth + popupPadding * 2
        contentHeight: ccContent.implicitHeight + popupPadding * 2

        ControlCenterContent {
            id: ccContent
            // popupOpen resets the Wi-Fi/Bluetooth/Volume sub-pages back to
            // the main menu on close — handled internally, no manual
            // reset-on-close wiring needed here.
            popupOpen: ccPopup.isOpen
        }
    }
}



