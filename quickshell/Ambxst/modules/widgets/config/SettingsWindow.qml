import QtQuick
import Quickshell
import qs.modules.widgets.dashboard.controls
import qs.modules.components
import qs.modules.globals
import qs.modules.theme
import qs.config

// Settings app window — macOS "System Settings" look.
// Background = your original StyledRect "bg" variant; SettingsTab draws on top of it.
FloatingWindow {
    id: settingsWindow

    // green traffic light toggles this
    property bool zoomed: false

    title: "Settings"
    implicitWidth: zoomed ? 1400 : 1080
    implicitHeight: zoomed ? 920 : 780
    minimumSize: Qt.size(860, 580)
    visible: GlobalStates.settingsWindowVisible

    color: "transparent"

    // Original window background (theme "bg" variant)
    StyledRect {
        anchors.fill: parent
        variant: "bg"
        radius: 0

        SettingsTab {
            anchors.fill: parent
            anchors.margins: 4
            onCloseRequested: GlobalStates.settingsWindowVisible = false
            onZoomRequested: settingsWindow.zoomed = !settingsWindow.zoomed
        }
    }

    // Close on visibility change from outside
    onVisibleChanged: {
        if (!visible && GlobalStates.settingsWindowVisible) {
            GlobalStates.settingsWindowVisible = false;
        }
    }

    // Sync visibility from GlobalStates
    Connections {
        target: GlobalStates
        function onSettingsWindowVisibleChanged() {
            settingsWindow.visible = GlobalStates.settingsWindowVisible;
        }
    }
}
