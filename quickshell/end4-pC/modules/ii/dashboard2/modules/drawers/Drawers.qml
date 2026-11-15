pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import qs.modules.ii.dashboard2.modules.bar
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import qs.modules.common
// Wallpapers is the root-level wallpaper singleton (services/Wallpapers.qml).
import qs.services

Variants {
    model: [Quickshell.screens[0]] // show only on main monitor
    // if you want to display on all monitors use this instead:
    // model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        StyledWindow {
            id: win

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.clipboard || visibilities.wallpaper || visibilities.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: Region {
                x: Config.options.caelestiaDashboard.border.thickness
                y: Config.options.caelestiaDashboard.border.thickness
                width: win.width - Config.options.caelestiaDashboard.border.thickness * 2
                height: win.height - Config.options.caelestiaDashboard.border.thickness * 2
                intersection: Intersection.Xor

                regions: regions.instances
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    x: modelData.x + Config.options.caelestiaDashboard.border.thickness
                    y: modelData.y + Config.options.caelestiaDashboard.border.thickness
                    width: modelData.width
                    height: modelData.height
                    intersection: Intersection.Subtract
                }
            }

            HyprlandFocusGrab {
                active: visibilities.launcher || visibilities.clipboard || visibilities.wallpaper || visibilities.session
                windows: [win]
                onCleared: {
                    visibilities.launcher = false;
                    visibilities.clipboard = false;
                    visibilities.wallpaper = false;
                    visibilities.session = false;
                }
            }

            StyledRect {
                anchors.fill: parent
                opacity: visibilities.session ? 0.5 : 0
                color: Appearance.m3colors.m3shadow

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.dashboard.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                }
            }

            Item {
                id: background

                anchors.fill: parent
                visible: false

                Backgrounds {
                    panels: panels
                }
            }

            MultiEffect {
                anchors.fill: source
                source: background
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Appearance.m3colors.m3shadow, 0.7)
            }

            PersistentProperties {
                id: visibilities

               // property bool osd
                property bool session
                property bool launcher
                property bool clipboard
                property bool wallpaper
                property bool dashboard
                    property int dashboardTab: 0

                Component.onCompleted: Visibilities.screens[scope.modelData] = this
            }

            // qmllint disable unresolved-type
            CustomShortcut {
                // qmllint enable unresolved-type
                name: "launcher"
                description: "Toggle the app launcher"
                onPressed: {
                    visibilities.launcher = !visibilities.launcher;
                    visibilities.clipboard = false;
                    visibilities.wallpaper = false;
                    visibilities.session = false;
                }
            }

            // qmllint disable unresolved-type
            CustomShortcut {
                // qmllint enable unresolved-type
                name: "clipboard"
                description: "Toggle the clipboard history"
                onPressed: {
                    visibilities.clipboard = !visibilities.clipboard;
                    visibilities.launcher = false;
                    visibilities.wallpaper = false;
                    visibilities.session = false;
                }
            }

            // qmllint disable unresolved-type
            CustomShortcut {
                // qmllint enable unresolved-type
                name: "wallpaperDrawer"
                description: "Toggle the wallpaper carousel"
                onPressed: {
                    visibilities.wallpaper = !visibilities.wallpaper;
                    visibilities.launcher = false;
                    visibilities.clipboard = false;
                    visibilities.session = false;
                }
            }

            // qmllint disable unresolved-type
            CustomShortcut {
                // qmllint enable unresolved-type
                name: "session"
                description: "Toggle the session menu"
                onPressed: {
                    visibilities.session = !visibilities.session;
                    visibilities.launcher = false;
                    visibilities.clipboard = false;
                    visibilities.wallpaper = false;
                }
            }

            // Opens the app drawer
            IpcHandler {
                function toggle(): void {
                    visibilities.launcher = !visibilities.launcher;
                    visibilities.clipboard = false;
                    visibilities.wallpaper = false;
                    visibilities.session = false;
                }

                function show(): void {
                    visibilities.launcher = true;
                    visibilities.clipboard = false;
                    visibilities.wallpaper = false;
                    visibilities.session = false;
                }

                function close(): void {
                    visibilities.launcher = false;
                }

                target: "launcher"
            }

            // Opens clipboard history in the same panel
            IpcHandler {
                function toggle(): void {
                    visibilities.clipboard = !visibilities.clipboard;
                    visibilities.launcher = false;
                    visibilities.wallpaper = false;
                    visibilities.session = false;
                }

                function show(): void {
                    visibilities.clipboard = true;
                    visibilities.launcher = false;
                    visibilities.wallpaper = false;
                    visibilities.session = false;
                }

                function close(): void {
                    visibilities.clipboard = false;
                }

                target: "clipboard"
            }

            // Opens the wallpaper carousel in the same panel
            IpcHandler {
                function toggle(): void {
                    visibilities.wallpaper = !visibilities.wallpaper;
                    visibilities.launcher = false;
                    visibilities.clipboard = false;
                    visibilities.session = false;
                }

                function show(): void {
                    visibilities.wallpaper = true;
                    visibilities.launcher = false;
                    visibilities.clipboard = false;
                    visibilities.session = false;
                }

                function close(): void {
                    visibilities.wallpaper = false;
                }

                // Jumps straight to a random wallpaper in the current
                // folder and applies it - same as the old WallpaperSelector's
                // "random" IPC call. Doesn't need the drawer open at all.
                function random(): void {
                    Wallpapers.randomFromCurrentFolder();
                }

                // Steps to the next/previous wallpaper file in the current
                // folder and applies it directly - handy for binding to
                // media/volume-style keys without opening the drawer.
                function stepWallpaper(direction: int): void {
                    if (Wallpapers.folderModel.count === 0)
                        return;

                    const files = [];
                    for (let i = 0; i < Wallpapers.folderModel.count; i++) {
                        if (Wallpapers.folderModel.get(i, "fileIsDir"))
                            continue;
                        const path = Wallpapers.folderModel.get(i, "filePath");
                        if (path)
                            files.push(path);
                    }
                    if (files.length === 0)
                        return;

                    const currentIdx = files.indexOf(Config.options.background.wallpaperPath);
                    const nextIdx = currentIdx === -1 ? 0 : (currentIdx + direction + files.length) % files.length;
                    Wallpapers.select(files[nextIdx]);
                }

                function next(): void {
                    stepWallpaper(1);
                }

                function prev(): void {
                    stepWallpaper(-1);
                }

                target: "wallpaperDrawer"
            }

            // Opens the session (power) menu in its own right-docked panel
            IpcHandler {
                function toggle(): void {
                    visibilities.session = !visibilities.session;
                    visibilities.launcher = false;
                    visibilities.clipboard = false;
                    visibilities.wallpaper = false;
                }

                function show(): void {
                    visibilities.session = true;
                    visibilities.launcher = false;
                    visibilities.clipboard = false;
                    visibilities.wallpaper = false;
                }

                function close(): void {
                    visibilities.session = false;
                }

                target: "sessionmenu"
            }

            Interactions {
                screen: scope.modelData
                visibilities: visibilities
                panels: panels

                Panels {
                    id: panels

                    screen: scope.modelData
                    visibilities: visibilities
                }
            }
        }
    }
}
