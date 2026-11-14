
// Widgets/controlpanel/PowerBar.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.common.functions
import qs.modules.services as Backend

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: 70

    // Gives the lockscreen a moment to appear before suspending.
    Process {
        id: suspendDelay
        command: ["bash", "-c", "sleep 0.5 && systemctl suspend"]
    }

    // Card background — same as Volume/Brightness
    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.colors.colSurfaceContainerHigh

        Behavior on color { ColorAnimation { duration: 200 } }

        Row {
            anchors.centerIn: parent
            width: parent.width - 24
            spacing: 0

            PowerButton {
                width:  parent.width / 5
                icon:   "power_settings_new"
                accent: "#e05c5c"
                onTriggered: {
                    // Shutdown
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            }

            PowerButton {
                width:  parent.width / 5
                icon:   "lock"
                accent: Appearance.colors.colPrimary
                onTriggered: {
                    // Calls your own LockscreenService in-process instead of
                    // shelling out through another config's IPC name.
                    Backend.LockscreenService.lock();
                }
            }

            PowerButton {
                width:  parent.width / 5
                icon:   "bedtime"
                accent: "#7b8fb7"
                onTriggered: {
                    // Lock first, then suspend once the lockscreen is up.
                    Backend.LockscreenService.lock();
                    suspendDelay.running = true;
                }
            }

            PowerButton {
                width:  parent.width / 5
                icon:   "logout"
                accent: "#e09a3a"
                onTriggered: {
                    // Logout from Hyprland
                    Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                }
            }

            PowerButton {
                width:  parent.width / 5
                icon:   "restart_alt"
                accent: "#5cb87a"
                onTriggered: {
                    // Reboot
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            }
        }
    }

    // ── Sub-component ────────────────────────────────────────────────────────
    component PowerButton: Item {
        id: btn

        property string icon:   ""
        property color  accent: Appearance.colors.colPrimary

        signal triggered()

        implicitHeight: 70

        property bool hoveredState: false
        property bool pressedState: false

        // Enhanced hover bubble with smooth pop-out animation
        Rectangle {
            id: bubble
            anchors.centerIn: parent
            width:  42
            height: 42
            radius: 14
            border.width: 0

            color: btn.pressedState
            ? Qt.rgba(btn.accent.r, btn.accent.g, btn.accent.b, 0.30)
            : btn.hoveredState
            ? Qt.rgba(btn.accent.r, btn.accent.g, btn.accent.b, 0.16)
            : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            // Smooth pop-out animation with spring-like easing
            scale: btn.pressedState ? 0.88 : btn.hoveredState ? 1.25 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: btn.hoveredState ? 350 : 200
                    easing.type: btn.hoveredState ? Easing.OutBack : Easing.OutCubic
                    easing.overshoot: 1.5
                }
            }

            // Subtle rotation on hover for extra life
            rotation: btn.hoveredState ? 5 : 0
            Behavior on rotation {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Icon with smooth color transition
        MaterialSymbol {
            anchors.centerIn: parent
            icon:     btn.icon
            iconSize: 20
            color:    btn.hoveredState ? btn.accent : Appearance.colors.colOnSurface

            Behavior on color { ColorAnimation { duration: 150 } }

            // Icon also scales slightly on hover
            scale: btn.hoveredState ? 1.15 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.3
                }
            }
        }

        MouseArea {
            anchors.fill:  parent
            hoverEnabled:  true
            cursorShape:   Qt.PointingHandCursor
            onEntered:     btn.hoveredState = true
            onExited:      { btn.hoveredState = false; btn.pressedState = false }
            onPressed:     btn.pressedState = true
            onReleased:    btn.pressedState = false
            onClicked:     btn.triggered()
        }
    }
}



