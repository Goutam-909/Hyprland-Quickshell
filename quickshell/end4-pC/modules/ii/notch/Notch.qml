import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common as C

// One instance per visible monitor. IllogicalImpulseFamily wires this in via
// PanelLoader { extraCondition: Config.options.notch.enable; component: Notch {} }
Scope {
    id: root

    Variants {
        model: Quickshell.screens.filter(s => {
            const list = C.Config.options.notch.screenList;
            return list.length === 0 || list.includes(s.name);
        })

        PanelWindow {
            id: notchPanel
            required property var modelData
            screen: modelData

            anchors {
                top: C.Config.options.notch.position !== "bottom"
                bottom: C.Config.options.notch.position === "bottom"
                left: true
                right: true
            }

            color: "transparent"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore

            readonly property alias notchOpen: content.notchOpen

            HyprlandFocusGrab {
                id: focusGrab
                windows: [notchPanel]
                active: notchPanel.notchOpen
                onCleared: GlobalStates.notchOpen = false
            }

            mask: Region {
                item: content.notchHitbox
            }

            NotchContent {
                id: content
                anchors.fill: parent
                screen: notchPanel.screen
            }
        }
    }
}
