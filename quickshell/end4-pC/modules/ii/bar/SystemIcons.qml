import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property real realSpacing: isMaterial ? 2 : 10

    // Local override of Revealer's Behavior: use the decel "enter" curve when
    // opening and the accel "exit" curve when closing, instead of Revealer's
    // default which reuses the enter curve both ways (causes the stall-then-
    // snap on close). Declaring a Behavior on implicitWidth here replaces the
    // one declared inside Revealer.qml itself for these instances only.
    component SmoothRevealer: Revealer {
        Behavior on implicitWidth {
            enabled: !vertical
            NumberAnimation {
                duration: reveal ? Appearance.animation.elementMoveEnter.duration : Appearance.animation.elementMoveExit.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: reveal ? Appearance.animation.elementMoveEnter.bezierCurve : Appearance.animation.elementMoveExit.bezierCurve
            }
        }
        Behavior on implicitHeight {
            enabled: vertical
            NumberAnimation {
                duration: reveal ? Appearance.animation.elementMoveEnter.duration : Appearance.animation.elementMoveExit.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: reveal ? Appearance.animation.elementMoveEnter.bezierCurve : Appearance.animation.elementMoveExit.bezierCurve
            }
        }
    }

    implicitWidth: root.vertical ? 32 : row.implicitWidth + 4
    implicitHeight: root.vertical ? row.implicitHeight + 4 : 32

    MouseArea {
        anchors.fill: parent
        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }

    // Fixed-edge anchor instead of centerIn: only the leading edge should
    // move when an icon reveals/hides, not both edges at once (that dual
    // motion is what reads as "jitter"/vibration during resize).
    RowLayout {
        id: row
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: root.realSpacing
        layoutDirection: root.vertical ? Qt.LeftToRight : Qt.RightToLeft

        SmoothRevealer {
            reveal: BluetoothStatus.available
            Layout.fillHeight: true
            MaterialSymbol {
                text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                iconSize: Appearance.font.pixelSize.larger
                color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
            }
        }
        MaterialSymbol {
            text: Network.materialSymbol
            iconSize: Appearance.font.pixelSize.larger
            color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
        }
        SmoothRevealer {
            reveal: Audio.sink?.audio?.muted ?? false
            Layout.fillHeight: true
            MaterialSymbol {
                text: "volume_off"
                iconSize: Appearance.font.pixelSize.larger
                color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
            }
        }
        SmoothRevealer {
            reveal: Audio.source?.audio?.muted ?? false
            Layout.fillHeight: true
            MaterialSymbol {
                text: "mic_off"
                iconSize: Appearance.font.pixelSize.larger
                color: root.isMaterial ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
            }
        }
        SmoothRevealer {
            reveal: Notifications.silent || Notifications.unread > 0
            Layout.fillHeight: true
            NotificationUnreadCount {}
        }
    }
}
