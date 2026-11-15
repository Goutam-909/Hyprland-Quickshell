import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Second wallpaper selector: fullscreen, chromeless, matching
// LauncherWindow.qml's actual surface (a dim rectangle over the whole
// output, no card) rather than a small anchored dropdown. Independent of
// the original WallpaperSelector.qml - own `open` state, own IpcHandler
// ("wallpaperSelectorV2"), own shortcut names - so nothing about the
// original selector's window, keybinds, or IPC changes.
//
// Still just opens a panel and reads/writes wallpapers through the
// existing Wallpapers service; no code from the ported source is
// executed, only its layout/timing numbers are reproduced in QML here.
Scope {
    id: root

    property bool open: false
    property bool reallyOpen: false

    onOpenChanged: {
        if (root.open) {
            closeAnimTimer.stop();
            root.reallyOpen = true;
        } else {
            closeAnimTimer.restart();
        }
    }

    Timer {
        id: closeAnimTimer
        interval: 260
        onTriggered: root.reallyOpen = false
    }

    Loader {
        id: wallpaperSelectorV2Loader
        active: root.reallyOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property var monitor: WM.monitorFor(panelWindow.screen)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:wallpaperSelectorV2"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            // Fullscreen, like LauncherWindow.qml, not anchored-top like
            // the original small dropdown selector.
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
                content.reveal();
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    root.open = false;
                }
            }

            WallpaperSelectorV2Content {
                id: content
                anchors.fill: parent

                onRequestClose: root.open = false

                // "grow-top-left" in the source is a circular reveal mask
                // driven by a whole launcher state machine; reproduced
                // here as the nearest equivalent that doesn't need that
                // machinery: a fade + scale-from-the-corner it grows from.
                opacity: 0
                scale: 0.94
                transformOrigin: Item.TopLeft

                function reveal() {
                    content.opacity = 0;
                    content.scale = 0.94;
                    Qt.callLater(() => {
                        content.opacity = 1;
                        content.scale = 1;
                    });
                }

                Connections {
                    target: root
                    function onOpenChanged() {
                        if (!root.open) {
                            content.opacity = 0;
                            content.scale = 0.94;
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.open ? 260 : 220
                        easing.type: root.open ? Easing.OutCubic : Easing.InCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: root.open ? 320 : 220
                        easing.type: root.open ? Easing.OutBack : Easing.InCubic
                        easing.overshoot: root.open ? 1.4 : 0
                    }
                }
            }
        }
    }

    function toggle() {
        root.open = !root.open;
    }

    IpcHandler {
        target: "wallpaperSelectorV2"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open = true;
        }

        function close(): void {
            root.open = false;
        }

        function random(): void {
            Wallpapers.randomFromCurrentFolder();
        }
    }

    CompositorGlobalShortcut {
        name: "wallpaperSelectorV2Toggle"
        description: "Toggle wallpaper selector (new design)"
        onPressed: {
            root.toggle();
        }
    }

    CompositorGlobalShortcut {
        name: "wallpaperSelectorV2Random"
        description: "Select random wallpaper in current folder (new design selector)"
        onPressed: {
            Wallpapers.randomFromCurrentFolder();
        }
    }
}
