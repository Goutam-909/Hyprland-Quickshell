
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.modules.widgets.dashboard.controls
import qs.config

// NetworkPill – compact network status icon for the bar, in the same spirit
// as the island's IslandNetworkPill (icon-only, hover reveals live ↓/↑
// throughput), but driven by your real NetworkService instead of a generic
// icon source, and click opens WifiPanel in a BarPopup (same pattern
// MediaControlsPill uses for its volume mixer).
//
// Usage in BarContent.qml (drop it right next to the Workspaces Loader):
//   NetworkPill {
//       bar: root
//       startRadius: root.innerRadius
//       endRadius:   root.innerRadius
//       enableShadow: root.shadowsEnabled
//   }
Item {
    id: root

    required property var bar

    property real startRadius: Styling.radius(0)
    property real endRadius: Styling.radius(0)
    property bool enableShadow: false

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    // ── Live throughput (same /proc/net/dev diffing the island version uses) ──
    property real rxRate: 0
    property real txRate: 0
    property real lastRx: -1
    property real lastTx: -1

    function fmt(b) {
        if (b < 1024)
            return `${Math.round(b)} B/s`;
        if (b < 1048576)
            return `${(b / 1024).toFixed(1)} KB/s`;
        return `${(b / 1048576).toFixed(1)} MB/s`;
    }

    Process {
        id: netProc
        command: ["bash", "-c", "awk 'NR>2 && $1!=\"lo:\"{rx+=$2; tx+=$10} END{print rx, tx}' /proc/net/dev"]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split(/\s+/);
                if (p.length < 2)
                    return;
                const rx = parseFloat(p[0]);
                const tx = parseFloat(p[1]);
                if (root.lastRx >= 0) {
                    root.rxRate = Math.max(0, rx - root.lastRx);
                    root.txRate = Math.max(0, tx - root.lastTx);
                }
                root.lastRx = rx;
                root.lastTx = tx;
            }
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    // NetworkService now runs a single centralized poll on itself (see
    // NetworkService.qml's strengthPoll Timer) that keeps signal strength
    // fresh for every consumer — this pill no longer needs its own
    // duplicate Timer calling refreshForUI().

    // ── Status → icon/label, sourced from NetworkService ──────────────────────
    readonly property bool connected: NetworkService.ethernet || NetworkService.wifiStatus === "connected"

    // Icon opacity communicates state at a glance: full = actively connected,
    // dimmed = Wi-Fi is on but idle (or off entirely), matching how most
    // status bars distinguish "enabled" from "connected" without needing a
    // separate glyph for every state.
    readonly property real iconOpacity: {
        if (NetworkService.ethernet || NetworkService.wifiStatus === "connected")
            return 1;
        if (NetworkService.wifiConnecting)
            return 0.7;
        return 0.45;
    }

    readonly property string statusIcon: {
        if (NetworkService.ethernet)
            return Icons.ethernet;
        if (!NetworkService.wifiEnabled || NetworkService.wifiStatus === "disabled")
            return Icons.wifiOff;
        if (NetworkService.wifiConnecting)
            return Icons.wifiNone;
        if (NetworkService.wifiStatus === "connected")
            // networkStrength can briefly read 0 right after connecting
            // (before the strength poll lands) — wifiIconForStrength(0)
            // would return wifiOff, which looks like Wi-Fi is disabled while
            // you're actually connected. Assume full bars until we know
            // otherwise rather than showing the wrong glyph.
            return NetworkService.wifiIconForStrength(NetworkService.networkStrength > 0 ? NetworkService.networkStrength : 100);
        if (NetworkService.wifiStatus === "limited")
            return Icons.wifiLow;
        // Wi-Fi enabled but not connected to anything — this is a normal
        // idle state, not an error, so show a plain wifi glyph (dimmed via
        // iconOpacity) rather than the wifiX "no networks / error" icon that
        // was showing here before.
        return Icons.wifiHigh;
    }

    readonly property string statusLabel: {
        if (NetworkService.ethernet)
            return "Ethernet";
        if (!NetworkService.wifiEnabled || NetworkService.wifiStatus === "disabled")
            return "Wi-Fi off";
        if (NetworkService.wifiConnecting)
            return "Connecting…";
        if (NetworkService.wifiStatus === "connected")
            return NetworkService.networkName || "Connected";
        if (NetworkService.wifiStatus === "limited")
            return "Limited connectivity";
        return "Disconnected";
    }

    // ── Outer pill (mirrors MediaControlsPill's StyledRect conventions) ──────
    StyledRect {
        id: pill
        variant: "bg"
        anchors.fill: parent
        clip: true
        implicitWidth: content.implicitWidth + 20
        implicitHeight: 36
        radius: Styling.radius(4)
        enableBorder: true
        enableShadow: root.enableShadow

        topLeftRadius: root.startRadius
        bottomLeftRadius: root.startRadius
        topRightRadius: root.endRadius
        bottomRightRadius: root.endRadius

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: hover
        }

        // Fixed-size anchor for the popup — deliberately NOT the pill itself,
        // since the pill's width animates on hover (icon-only ↔ icon+rates).
        // BarPopup positions itself from anchorItem.width, so anchoring to the
        // pill would make the popup's position shift in lockstep with the
        // hover-expand animation. Anchoring to this fixed-width, fixed-position
        // Item instead means the popup's position is completely independent of
        // whatever the hover meter is doing.
        Item {
            id: popupAnchor
            width: root.implicitHeight
            height: root.implicitHeight
            anchors.left: pill.left
            anchors.verticalCenter: pill.verticalCenter
        }

        // Left click → open Wi-Fi panel. Right click → quick wifi on/off toggle.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    wifiPopup.toggle();
                } else if (mouse.button === Qt.RightButton) {
                    NetworkService.toggleWifi();
                }
            }
        }

        BarPopup {
            id: wifiPopup
            anchorItem: popupAnchor
            bar: root.bar
            contentWidth: 340
            contentHeight: 420
            popupPadding: 12

            WifiPanel {
                anchors.fill: parent
            }
        }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: root.statusIcon
                font.family: Icons.font
                font.pixelSize: 16
                color: Colors.primary
                opacity: root.iconOpacity

                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // Rates take their fixed slot only while hovered (compact when idle),
            // same reveal behaviour as the island version.
            Text {
                visible: hover.hovered
                opacity: hover.hovered ? 1 : 0
                Layout.preferredWidth: 68
                text: `↓${root.fmt(root.rxRate)}`
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.primary
                elide: Text.ElideRight

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Text {
                visible: hover.hovered
                opacity: hover.hovered ? 1 : 0
                Layout.preferredWidth: 68
                text: `↑${root.fmt(root.txRate)}`
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.primary
                elide: Text.ElideRight

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        StyledToolTip {
            show: hover.hovered
            tooltipText: root.statusLabel
        }
    }
}
