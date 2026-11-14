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
        spacing: 14

        MacIconTile {
            Layout.alignment: Qt.AlignHCenter
            size: 88
            glyph: Icons.gear
            tint: MacStyle.tileTeal
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "GNOME Control Center"
            font.family: MacStyle.fontFamily
            font.pixelSize: MacStyle.fsLarge
            font.weight: Font.DemiBold
            color: MacStyle.label
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Opens the GNOME system settings in a separate window.\nClosing this page will also quit that app."
            font.family: MacStyle.fontFamily
            font.pixelSize: MacStyle.fsBody
            color: MacStyle.labelSecondary
        }

        MacButton {
            id: launchButton
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            implicitHeight: 36
            implicitWidth: 230
            primary: true
            enabled: !gccLauncher.running
            text: gccLauncher.running ? "Running…" : "Open GNOME Settings"

            onClicked: {
                statusLabel.text = "Launching…";
                gccLauncher.running = true;
            }
        }

        Text {
            id: statusLabel
            Layout.alignment: Qt.AlignHCenter
            text: ""
            font.family: MacStyle.fontFamily
            font.pixelSize: MacStyle.fsSmall
            color: MacStyle.labelSecondary
        }
    }
}
