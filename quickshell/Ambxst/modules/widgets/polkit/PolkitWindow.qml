pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.services

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow
            required property var modelData
            screen: modelData

            // What the service wants right now
            readonly property bool requestVisible: PolkitService.active

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            WlrLayershell.namespace: "quickshell:polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: requestVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            // Stay mapped a little longer than requestVisible so the close
            // animation (fade + scale down) actually gets to play out instead
            // of the window disappearing instantly.
            visible: requestVisible || closeTimer.running

            mask: Region {
                item: requestVisible ? fullMask : emptyMask
            }
            Item {
                id: fullMask
                anchors.fill: parent
            }
            Item {
                id: emptyMask
                width: 0
                height: 0
            }

            Timer {
                id: closeTimer
                interval: 420
                repeat: false
            }

            onRequestVisibleChanged: {
                if (requestVisible) {
                    closeTimer.stop();
                } else {
                    closeTimer.restart();
                }
            }

            PolkitContent {
                anchors.fill: parent
                shown: panelWindow.requestVisible
            }
        }
    }
}
