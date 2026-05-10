import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.config

Item {
    id: root
    property int maxContentWidth: 480

    // The process handle — kept alive while the panel is visible
    property var gccProcess: null

    Process {
        id: gccLauncher
        command: ["bash", "-c", "export XDG_CURRENT_DESKTOP=GNOME; export NO_AT_BRIDGE=1; /usr/lib/gsd-rfkill & /usr/lib/gsd-power & gnome-control-center; kill %1 %2"]
        running: false

        onExited: (exitCode, exitStatus) => {
            statusLabel.text = "GNOME Control Center closed (exit " + exitCode + ")";
            launchButton.enabled = true;
        }
    }

    // Kill gnome-control-center when this panel is unloaded/hidden
    Component.onDestruction: {
        if (gccLauncher.running) {
            gccLauncher.running = false;
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(root.width, root.maxContentWidth)
        spacing: 20

        // Icon
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Icons.gear
            font.family: Icons.font
            font.pixelSize: 48
            color: Styling.srItem("overprimary")
        }

        // Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "GNOME Control Center"
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(2)
            font.weight: Font.Bold
            color: Styling.srItem("common")
        }

        // Description
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Opens the GNOME system settings in a separate window.\nClosing this panel will also terminate the settings app."
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-1)
            color: Styling.srItem("common")
            opacity: 1
        }

        // Launch button
        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 200
            implicitHeight: 44
            radius: Config.theme.roundness
            variant: "primary"

            MouseArea {
                id: launchButton
                anchors.fill: parent
                enabled: !gccLauncher.running
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    statusLabel.text = "Launching…";
                    gccLauncher.running = true;
                    launchButton.enabled = false;
                }

                Text {
                    anchors.centerIn: parent
                    text: gccLauncher.running ? "Running…" : "Open GNOME Settings"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    font.weight: Font.Medium
                    color: Colors.onPrimary
                }
            }
        }

        // Status text
        Text {
            id: statusLabel
            Layout.alignment: Qt.AlignHCenter
            text: ""
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-2)
            color: Styling.srItem("common")
            opacity: 1
        }
    }
}
