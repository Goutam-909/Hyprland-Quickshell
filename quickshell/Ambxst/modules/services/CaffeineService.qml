pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: StateService.get("caffeine", false)

    function toggleInhibit() {
        inhibit = !inhibit;
    }

    onInhibitChanged: {
        if (StateService.initialized) {
            StateService.set("caffeine", inhibit);
        }
    }

    Connections {
        target: StateService
        function onStateLoaded() {
            root.inhibit = StateService.get("caffeine", false);
        }
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            // Overlay layer: stays visible above fullscreen windows. The
            // compositor ignores inhibitors from surfaces that are hidden,
            // and a Top-layer panel is hidden while a window is fullscreen.
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "caffeine-inhibitor"
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            mask: Region {
                item: null
            }
        }
    }
}
